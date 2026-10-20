# ELM session pipeline

Parent issue: [#110](https://gitlab.com/aa22396584/telltale/-/issues/110).
This is a design note for the in-app ASCII ELM327 client, not adapter or
on-vehicle validation.

The ELM327 is half-duplex ASCII. One command is in flight. The adapter
ends a healthy reply with `>` (`0x3E`) **after its response window
closes**. That prompt is the primary completion signal. Completing
without it is the exception, not the default.

## Why the previous shape failed

`_onBytes` treated a reply as complete only at `>`. A v1.5 clone
(`ATI` = ELM327 v1.5, `AT@1` = ICSolution, `ATDPN` = A6) on functional
`7DF` with two responders (`7E8`, `7E9`) returned a fully reassembled
ISO-TP pair for `010C0D04110B10` and omitted the prompt. The client sat
on `commandTimeout` (5 s), marked the stream out of sync, waited
`resyncTimeout` (3 s) for a `>` that never arrived, and dropped the
link. `_resync` sent nothing: a bare `\r` is “repeat last command” on
this chip, and repeating the batch would have made the pile-up worse.

A first redesign quiet-completed every conclusive OBD buffer after
100 ms. That is inside the adapter's ATST window. The #110 log shows
data then `>` ~412–423 ms later on healthy replies (3192→3615,
3750→4169, 1673→2085). Closing early, holding 120 ms, and writing the
next command aborted the adapter with `STOPPED`, which was then read as
the next command's answer.

AT commands, `SEARCHING...`, `7F xx 78`, genuine-adapter transcripts,
single-ECU physical `7E0`, and the GT86 numbered CAF1 batch of six PIDs
already work. Those paths stay on the prompt.

## State machine

```
        write command
              |
              v
     collect bytes into _buffer
              |
     +--------|-------------------------------+
     |                                        |
     |  `>` arrives                           |  command timeout, or
     |                                        |  (this session already saw a
     |                                        |   missing prompt AND idle >
     |                                        |   adapter response window)
     v                                        v
 parse frame                         parse buffer; conclusive?
     |                                        |
     |                           yes (OBD only)     no
     |                                |              |
     v                                v              v
 complete pending              complete pending   keep waiting
                               (promptless)       until `>`,
                               hold next write    SEARCHING/pending
                               until late `>`     extension, or
                               or window over     command timeout
```

On **command timeout**:

1. If the command is non-AT and the buffer already parses as a
   conclusive OBD reply or adapter error (`NO DATA`, `CAN ERROR`, …),
   complete it as promptless. That is the first allowed promptless
   complete in a session.
2. Otherwise fail the pending command and mark the stream out of sync.
3. The next `send` runs `_resync`.
   - Empty buffer (true silence): wait passively for `>` up to 3 s, then
     drop the session. A silent adapter is gone; probing would not
     change that.
   - Partial/incomplete bytes: write `ATI` (never a bare `\r`) while the
     drain is armed. The probe's `>` is consumed by the drain and not
     parsed as PID data. If it arrives, the stream is in step and the
     next command proceeds. If it does not, drop as today.

After a promptless complete, the next write waits until a late `>`
arrives or the remainder of the adapter response window (ATST66 ≈
408 ms; profile value 450 ms) has elapsed. `STOPPED` or any non-blank
leftover in that window is discarded, not parsed as the next command.

`SEARCHING...` and `7F xx 78` still extend the outstanding deadline.
They are not conclusive replies. `dataError` (truncated ISO-TP, odd
nibbles) is not conclusive either. An unheadered payload with no CR/LF
is a mid-line chunk, not a reply — issue 106's M106-04.

AT commands (`ATZ`, `ATH1`, `ATSH`, …) still complete only on `>`.

## Clone vs genuine

`AdapterIdentity` still answers only “does this banner contradict
itself?”, never “are these readings true”. `firmwareNeverReleased`
(`v1.5`, `v1.4a`) is a capability hint for **pacing and batch size**,
not a fidelity claim.

| Session | Batch cap | Notes |
|---|---|---|
| Genuine / self-consistent, or clone on physical `7E0` (one ECU) | 6 | GT86 and the batching-gate fixture stay here |
| Clone (`firmwareNeverReleased`) **and** functional `7DF` fallback with more than one responder | 3 | Smaller ISO-TP replies; the #110 six-PID envelope is what lost the prompt |
| After one promptless complete | 3, or 1 if already 3 | Adaptive demotion, not `fastMode` off |
| After two promptless completes | 1 | Single-PID fallback |

`PriorityScheduler.maxBatchSize` remains 6 (the hardware ceiling).
`batchSizeCap` is the live limit. `handleCorruptionEvent` still disables
fast mode for `BUFFER FULL` / short batches — that path is unchanged.

After a promptless complete, inter-command delay becomes the adapter
response window (450 ms) so the next write is not issued while the
adapter is still in its ATST window.

## Multi-ECU and ISO-TP

Functional `7DF` keeps `ATH1` so each line carries a response id.
`_parseHeaderedCan` still groups by source and reassembles per
controller; `sendOnHeader` still keeps the engine (`7E8`) for Mode 01
gauges. Quiet-complete (after a missing prompt has been observed) uses
that same parser, and also refuses to fire while fewer distinct sources
are present than `lastResponderCount`.

With headers off, source ids are absent, so the same guard counts
finished lines instead of CAN ids. `lastResponderCount` is derived from
those unheadered hex payload lines on successful replies (CAF1
total-length lines and ISO-TP `1:`/`2:` continuations are not extra
ECUs). A late second-ECU line still joins the same command. Command
timeout will accept a conclusive buffer even if a previously-seen ECU
stayed silent, so a missing sibling cannot drop the link.

## Timeouts

| Timer | Duration | Role |
|---|---|---|
| Command | 5 s | Outstanding OBD/AT reply |
| Write | 2 s | Transport flush |
| Watchdog | 5 s (or the command’s own budget + 1 s) | Wedged link |
| `SEARCHING...` | 25 s | First-query protocol hunt |
| `7F xx 78` | 7 s global reads | ECU still working |
| Resync drain | 3 s | Wait for an owed `>` |
| Adapter response window | 450 ms | ATST66 ≈ 408 ms plus margin; data-to-`>` on healthy replies |
| Quiet-complete | 550 ms | Only after a missing prompt has been observed this session |
| Promptless write hold | remainder of 450 ms | Wait for a late `>` before the next write |

## Reconnect

There is no automatic transport reconnect. In-session recovery is the
timeout-complete / ATI-resync path above. If the adapter is truly silent,
`onConnectionLost` still fails the session and the user reconnects by
hand. A new `Elm327Client` does not keep `#109`’s `7DF` fallback; that
is rediscovered on the next handshake, same as today.

## `NO DATA`

Three consecutive single-PID `NO DATA` replies mark the PID `noAnswer`
with a 60 s backoff. That is not a capability claim: the adapter timed
out. The longer `unsupported` / five-minute recheck is only for `015E`,
and only when this session has already completed a reply without a
prompt or the adapter is a clone (`firmwareNeverReleased`). The `#110`
log retries fuel rate in a hot loop; that PID is absent from the
vehicle’s `0140` mask. Every other PID, including an intermittent
sensor on a working car, keeps the 60 s `noAnswer` rest. A later real
answer still wins on recheck.

## What this is not

- Not a timeout bump.
- Not a special case for one clone banner.
- Not vehicle validation. The `#110` excerpt is a sanitized user-exported
  session replay.
