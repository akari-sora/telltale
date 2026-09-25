/// Application transaction engine for ISO 14229-1 UDS read requests.
///
/// Ref: Issue #13 ([WS-09][P1]), ISO 14229-1:2020, ISO 14229-2:2013.
///
/// SAFETY CONTRACT:
/// - Operates exclusively on bounded Service 0x22 and bounded Service 0x19 read requests.
/// - Consumes complete ApplicationPdu messages; strictly no ISO-TP transport framing logic.
/// - NRC 0x21 (busyRepeatRequest) performs bounded resend under strict retry budget and delay.
/// - NRC 0x78 (responsePending) awaits continuation without resending, bounded by P2* and total deadline.
/// - Cancellation, generation retirement, and timeout dominance are checked at every state transition.
/// - Completed transactions are immutable; duplicate or late responses are ignored.
library;

import 'dart:async';

import '../diagnostic_link.dart';
import 'uds_dtc_codec.dart';
import 'uds_dtc_types.dart';
import 'uds_nrc.dart';
import 'uds_read_codec.dart';
import 'uds_read_types.dart';
import 'uds_diagnostic_link_channel.dart'
    show DiagnosticLinkContinuationUnavailableException;
import 'uds_transaction_policy.dart';
import 'uds_transaction_types.dart';

/// Application-level transaction engine coordinating UDS requests, timeouts, and retries.
final class UdsTransactionEngine {
  const UdsTransactionEngine({
    this.policy = UdsTransactionPolicy.standard,
    this.clock,
  });

  /// The active timing and retry policy.
  final UdsTransactionPolicy policy;

  /// Injected clock for monotonic timing (defaults to [SystemUdsClock]).
  final UdsClock? clock;

  /// Executes an immutable UDS transaction through the provided [channel].
  Future<UdsTransactionResult> execute({
    required UdsTransactionRequest request,
    required UdsTransactionChannel channel,
    DiagnosticTarget? target,
    DiagnosticSourceAddress? expectedResponder,
    int connectionGeneration = 1,
    int Function()? currentConnectionGeneration,
    DateTime? outerDeadline,
    DiagnosticCancellation cancellation = DiagnosticCancellation.none,
    void Function(UdsTransactionState state)? onStateChange,
    String correlationId = 'uds-tx',
  }) async {
    final activeClock = clock ?? SystemUdsClock();
    final DiagnosticSourceAddress? effectiveExpectedResponder;
    if (target is PhysicalCanDiagnosticTarget) {
      final targetExpected =
          DiagnosticSourceAddress(target.expectedResponderIdentifier.value);
      if (expectedResponder != null && expectedResponder != targetExpected) {
        throw ArgumentError(
          'Conflicting expected responder addressing: explicit expectedResponder ($expectedResponder) '
          'does not match target.expectedResponderIdentifier ($targetExpected)',
        );
      }
      effectiveExpectedResponder = targetExpected;
    } else {
      effectiveExpectedResponder = expectedResponder;
    }
    var state = UdsTransactionState.created;
    onStateChange?.call(state);

    var attempts = 0;
    var retries = 0;
    var responsePendingCount = 0;
    var isRetry = false;
    var nextRequestId = 1;

    // Helper: Check cancellation
    UdsTransactionCancelled? checkCancellation() {
      if (cancellation.isCancelled) {
        state = UdsTransactionState.completed;
        onStateChange?.call(state);
        return UdsTransactionCancelled(
          request: request,
          attempts: attempts,
          retries: retries,
          responsePendingCount: responsePendingCount,
          elapsed: activeClock.elapsed,
        );
      }
      return null;
    }

    // Helper: Check generation retirement
    UdsTransactionRetired? checkGeneration() {
      if (currentConnectionGeneration != null) {
        final currentGen = currentConnectionGeneration();
        if (currentGen != connectionGeneration) {
          state = UdsTransactionState.completed;
          onStateChange?.call(state);
          return UdsTransactionRetired(
            request: request,
            attempts: attempts,
            retries: retries,
            responsePendingCount: responsePendingCount,
            elapsed: activeClock.elapsed,
            expectedGeneration: connectionGeneration,
            actualGeneration: currentGen,
          );
        }
      }
      return null;
    }

    // Helper: Check total deadline
    UdsTransactionTimedOut? checkTotalDeadline() {
      if (activeClock.elapsed >= policy.totalTimeout) {
        state = UdsTransactionState.completed;
        onStateChange?.call(state);
        return UdsTransactionTimedOut(
          request: request,
          attempts: attempts,
          retries: retries,
          responsePendingCount: responsePendingCount,
          elapsed: activeClock.elapsed,
          timeoutType: UdsTimeoutType.total,
        );
      }
      return null;
    }

    // Helper: Check outer deadline (A6 / A7)
    UdsTransactionTimedOut? checkOuterDeadline() {
      if (outerDeadline != null && !DateTime.now().isBefore(outerDeadline)) {
        state = UdsTransactionState.completed;
        onStateChange?.call(state);
        return UdsTransactionTimedOut(
          request: request,
          attempts: attempts,
          retries: retries,
          responsePendingCount: responsePendingCount,
          elapsed: activeClock.elapsed,
          timeoutType: UdsTimeoutType.total,
        );
      }
      return null;
    }

    // Initial pre-send checks
    final initCancel = checkCancellation();
    if (initCancel != null) return initCancel;

    final initGen = checkGeneration();
    if (initGen != null) return initGen;

    final initDeadline = checkTotalDeadline();
    if (initDeadline != null) return initDeadline;

    final initOuter = checkOuterDeadline();
    if (initOuter != null) return initOuter;

    // Main transaction exchange loop (handles retries)
    while (true) {
      final loopCancel = checkCancellation();
      if (loopCancel != null) return loopCancel;

      final loopGen = checkGeneration();
      if (loopGen != null) return loopGen;

      final loopDeadline = checkTotalDeadline();
      if (loopDeadline != null) return loopDeadline;

      final loopOuter = checkOuterDeadline();
      if (loopOuter != null) return loopOuter;

      // Handle NRC 0x21 busy repeat delay if this is a retry attempt
      if (isRetry) {
        if (retries >= policy.maxBusyRepeatRetries) {
          state = UdsTransactionState.completed;
          onStateChange?.call(state);
          return UdsTransactionBusyRetryExhausted(
            request: request,
            attempts: attempts,
            retries: retries,
            responsePendingCount: responsePendingCount,
            elapsed: activeClock.elapsed,
            maxRetries: policy.maxBusyRepeatRetries,
          );
        }

        final remainingTotal = policy.totalTimeout - activeClock.elapsed;
        if (remainingTotal <= Duration.zero) {
          state = UdsTransactionState.completed;
          onStateChange?.call(state);
          return UdsTransactionTimedOut(
            request: request,
            attempts: attempts,
            retries: retries,
            responsePendingCount: responsePendingCount,
            elapsed: activeClock.elapsed,
            timeoutType: UdsTimeoutType.total,
          );
        }

        // Outer deadline check before busy repeat delay (A6 / B3)
        if (outerDeadline != null) {
          final now = DateTime.now();
          if (!now.isBefore(outerDeadline)) {
            state = UdsTransactionState.completed;
            onStateChange?.call(state);
            return UdsTransactionTimedOut(
              request: request,
              attempts: attempts,
              retries: retries,
              responsePendingCount: responsePendingCount,
              elapsed: activeClock.elapsed,
              timeoutType: UdsTimeoutType.total,
            );
          }
          final remainingOuter = outerDeadline.difference(now);
          if (policy.busyRepeatDelay >= remainingOuter) {
            state = UdsTransactionState.completed;
            onStateChange?.call(state);
            return UdsTransactionTimedOut(
              request: request,
              attempts: attempts,
              retries: retries,
              responsePendingCount: responsePendingCount,
              elapsed: activeClock.elapsed,
              timeoutType: UdsTimeoutType.total,
            );
          }
        }

        state = UdsTransactionState.busyRepeatDelay;
        onStateChange?.call(state);

        final delayTime = policy.busyRepeatDelay < remainingTotal
            ? policy.busyRepeatDelay
            : remainingTotal;
        await activeClock.delay(delayTime);

        final afterDelayCancel = checkCancellation();
        if (afterDelayCancel != null) return afterDelayCancel;

        final afterDelayGen = checkGeneration();
        if (afterDelayGen != null) return afterDelayGen;

        final afterDelayOuter = checkOuterDeadline();
        if (afterDelayOuter != null) return afterDelayOuter;

        if (activeClock.elapsed >= policy.totalTimeout) {
          state = UdsTransactionState.completed;
          onStateChange?.call(state);
          return UdsTransactionTimedOut(
            request: request,
            attempts: attempts,
            retries: retries,
            responsePendingCount: responsePendingCount,
            elapsed: activeClock.elapsed,
            timeoutType: UdsTimeoutType.total,
          );
        }

        retries++;
        state = UdsTransactionState.sendingRetry;
        onStateChange?.call(state);
      } else {
        state = UdsTransactionState.sendingInitial;
        onStateChange?.call(state);
      }

      // Calculate time budget for this send (capped by phase, total remaining, and outer remaining)
      final remainingBeforeSend = policy.totalTimeout - activeClock.elapsed;
      if (remainingBeforeSend <= Duration.zero) {
        state = UdsTransactionState.completed;
        onStateChange?.call(state);
        return UdsTransactionTimedOut(
          request: request,
          attempts: attempts,
          retries: retries,
          responsePendingCount: responsePendingCount,
          elapsed: activeClock.elapsed,
          timeoutType: UdsTimeoutType.total,
        );
      }

      var remainingEffective = remainingBeforeSend;
      if (outerDeadline != null) {
        final now = DateTime.now();
        if (!now.isBefore(outerDeadline)) {
          state = UdsTransactionState.completed;
          onStateChange?.call(state);
          return UdsTransactionTimedOut(
            request: request,
            attempts: attempts,
            retries: retries,
            responsePendingCount: responsePendingCount,
            elapsed: activeClock.elapsed,
            timeoutType: UdsTimeoutType.total,
          );
        }
        final remainingOuter = outerDeadline.difference(now);
        if (remainingOuter < remainingEffective) {
          remainingEffective = remainingOuter;
        }
      }

      final sendTimeout = policy.p2Timeout < remainingEffective
          ? policy.p2Timeout
          : remainingEffective;

      attempts++;
      final reqId = DiagnosticRequestId('$correlationId-$nextRequestId');
      nextRequestId++;

      DiagnosticMessage msg;
      try {
        msg = await channel.send(reqId, request.toPdu(), sendTimeout);
      } on TimeoutException {
        final cancelErr = checkCancellation();
        if (cancelErr != null) return cancelErr;
        final genErr = checkGeneration();
        if (genErr != null) return genErr;

        state = UdsTransactionState.completed;
        onStateChange?.call(state);
        final isTotal = activeClock.elapsed >= policy.totalTimeout ||
            (outerDeadline != null && !DateTime.now().isBefore(outerDeadline));
        return UdsTransactionTimedOut(
          request: request,
          attempts: attempts,
          retries: retries,
          responsePendingCount: responsePendingCount,
          elapsed: activeClock.elapsed,
          timeoutType: isTotal ? UdsTimeoutType.total : UdsTimeoutType.p2,
        );
      } catch (_) {
        final cancelErr = checkCancellation();
        if (cancelErr != null) return cancelErr;
        final genErr = checkGeneration();
        if (genErr != null) return genErr;
        state = UdsTransactionState.completed;
        onStateChange?.call(state);
        rethrow;
      }

      state = UdsTransactionState.awaitingP2;
      onStateChange?.call(state);

      // Inner loop for processing response and NRC 0x78 continuation phases
      var innerLoopFinished = false;
      while (!innerLoopFinished) {
        final msgCancel = checkCancellation();
        if (msgCancel != null) return msgCancel;

        final msgGen = checkGeneration();
        if (msgGen != null) return msgGen;

        final msgDeadline = checkTotalDeadline();
        if (msgDeadline != null) return msgDeadline;

        final msgOuter = checkOuterDeadline();
        if (msgOuter != null) return msgOuter;

        // Source address validation
        if (effectiveExpectedResponder != null &&
            msg.sourceAddress != effectiveExpectedResponder) {
          state = UdsTransactionState.completed;
          onStateChange?.call(state);
          return UdsTransactionSourceMismatch(
            request: request,
            attempts: attempts,
            retries: retries,
            responsePendingCount: responsePendingCount,
            elapsed: activeClock.elapsed,
            expectedSource: effectiveExpectedResponder,
            actualSource: msg.sourceAddress,
          );
        }

        final pdu = msg.pdu;
        if (pdu.length < 1) {
          state = UdsTransactionState.completed;
          onStateChange?.call(state);
          return UdsTransactionMalformed(
            request: request,
            attempts: attempts,
            retries: retries,
            responsePendingCount: responsePendingCount,
            elapsed: activeClock.elapsed,
            message: 'Empty response PDU received',
            rawBytes: pdu.bytes,
          );
        }

        final sid = pdu[0];

        // ---------------------------------------------------------------------
        // Negative Response Handling (SID 0x7F)
        // ---------------------------------------------------------------------
        if (sid == 0x7F) {
          if (pdu.length < 3) {
            state = UdsTransactionState.completed;
            onStateChange?.call(state);
            return UdsTransactionMalformed(
              request: request,
              attempts: attempts,
              retries: retries,
              responsePendingCount: responsePendingCount,
              elapsed: activeClock.elapsed,
              message: 'Negative response truncated: ${pdu.bytes}',
              rawBytes: pdu.bytes,
            );
          }

          final origSid = pdu[1];
          if (origSid != request.serviceId) {
            state = UdsTransactionState.completed;
            onStateChange?.call(state);
            return UdsTransactionMalformed(
              request: request,
              attempts: attempts,
              retries: retries,
              responsePendingCount: responsePendingCount,
              elapsed: activeClock.elapsed,
              message:
                  'Negative response original SID mismatch: expected 0x${request.serviceId.toRadixString(16).toUpperCase()}, got 0x${origSid.toRadixString(16).toUpperCase()}',
              rawBytes: pdu.bytes,
            );
          }

          final nrc = UdsNrc.fromCode(pdu[2]);

          // NRC 0x21: busyRepeatRequest -> Retry after delay
          if (nrc.isBusyRepeatRequest) {
            if (retries >= policy.maxBusyRepeatRetries) {
              state = UdsTransactionState.completed;
              onStateChange?.call(state);
              return UdsTransactionBusyRetryExhausted(
                request: request,
                attempts: attempts,
                retries: retries,
                responsePendingCount: responsePendingCount,
                elapsed: activeClock.elapsed,
                maxRetries: policy.maxBusyRepeatRetries,
              );
            }
            isRetry = true;
            innerLoopFinished = true;
            break; // Break inner loop to execute retry delay in outer loop
          }

          // NRC 0x78: responsePending -> Await continuation without resending
          if (nrc.isResponsePending) {
            responsePendingCount++;
            if (responsePendingCount > policy.maxResponsePendingCount) {
              state = UdsTransactionState.completed;
              onStateChange?.call(state);
              return UdsTransactionResponsePendingExhausted(
                request: request,
                attempts: attempts,
                retries: retries,
                responsePendingCount: responsePendingCount,
                elapsed: activeClock.elapsed,
                maxPending: policy.maxResponsePendingCount,
              );
            }

            state = UdsTransactionState.awaitingP2Star;
            onStateChange?.call(state);

            var remainingAfterPending =
                policy.totalTimeout - activeClock.elapsed;
            if (remainingAfterPending <= Duration.zero) {
              state = UdsTransactionState.completed;
              onStateChange?.call(state);
              return UdsTransactionTimedOut(
                request: request,
                attempts: attempts,
                retries: retries,
                responsePendingCount: responsePendingCount,
                elapsed: activeClock.elapsed,
                timeoutType: UdsTimeoutType.total,
              );
            }

            if (outerDeadline != null) {
              final now = DateTime.now();
              if (!now.isBefore(outerDeadline)) {
                state = UdsTransactionState.completed;
                onStateChange?.call(state);
                return UdsTransactionTimedOut(
                  request: request,
                  attempts: attempts,
                  retries: retries,
                  responsePendingCount: responsePendingCount,
                  elapsed: activeClock.elapsed,
                  timeoutType: UdsTimeoutType.total,
                );
              }
              final remainingOuter = outerDeadline.difference(now);
              if (remainingOuter < remainingAfterPending) {
                remainingAfterPending = remainingOuter;
              }
            }

            final p2StarTimeout = policy.p2StarTimeout < remainingAfterPending
                ? policy.p2StarTimeout
                : remainingAfterPending;

            try {
              msg = await channel.receiveContinuation(p2StarTimeout);
            } on DiagnosticLinkContinuationUnavailableException catch (e) {
              final cancelErr = checkCancellation();
              if (cancelErr != null) return cancelErr;
              final genErr = checkGeneration();
              if (genErr != null) return genErr;
              final outerErr = checkOuterDeadline();
              if (outerErr != null) return outerErr;
              final totalErr = checkTotalDeadline();
              if (totalErr != null) return totalErr;

              state = UdsTransactionState.completed;
              onStateChange?.call(state);
              return UdsTransactionTransportFailure(
                request: request,
                attempts: attempts,
                retries: retries,
                responsePendingCount: responsePendingCount,
                elapsed: activeClock.elapsed,
                message: e.message,
              );
            } on TimeoutException {
              final cancelErr = checkCancellation();
              if (cancelErr != null) return cancelErr;
              final genErr = checkGeneration();
              if (genErr != null) return genErr;

              state = UdsTransactionState.completed;
              onStateChange?.call(state);
              final isTotal = activeClock.elapsed >= policy.totalTimeout ||
                  (outerDeadline != null && !DateTime.now().isBefore(outerDeadline));
              return UdsTransactionTimedOut(
                request: request,
                attempts: attempts,
                retries: retries,
                responsePendingCount: responsePendingCount,
                elapsed: activeClock.elapsed,
                timeoutType: isTotal ? UdsTimeoutType.total : UdsTimeoutType.p2Star,
              );
            } catch (_) {
              final continuationCancel = checkCancellation();
              if (continuationCancel != null) return continuationCancel;
              final continuationGen = checkGeneration();
              if (continuationGen != null) return continuationGen;
              state = UdsTransactionState.completed;
              onStateChange?.call(state);
              rethrow;
            }

            // Continue inner while loop with newly received message
            continue;
          }

          // Terminal Negative Response Code
          state = UdsTransactionState.completed;
          onStateChange?.call(state);
          return UdsTransactionTerminalNegative(
            request: request,
            attempts: attempts,
            retries: retries,
            responsePendingCount: responsePendingCount,
            elapsed: activeClock.elapsed,
            nrc: nrc,
            originalSid: origSid,
          );
        }

        // Check outer deadline before publishing success (A6 / B3)
        final postSendOuter = checkOuterDeadline();
        if (postSendOuter != null) return postSendOuter;

        // ---------------------------------------------------------------------
        // Non-Negative Response Handling
        // ---------------------------------------------------------------------
        if (request.serviceId == 0x22) {
          final readReq =
              (request as UdsReadDataByIdentifierTransactionRequest).request;
          final parsed = UdsReadCodec.parseResponseBytes(
            requestedDid: readReq.did,
            responseBytes: pdu.bytes,
          );
          state = UdsTransactionState.completed;
          onStateChange?.call(state);

          return switch (parsed) {
            final UdsReadSuccess s => UdsTransactionSuccess(
                request: request,
                attempts: attempts,
                retries: retries,
                responsePendingCount: responsePendingCount,
                elapsed: activeClock.elapsed,
                responsePdu: pdu,
                sourceAddress: msg.sourceAddress,
                readResult: s,
              ),
            final UdsReadNegative n => UdsTransactionTerminalNegative(
                request: request,
                attempts: attempts,
                retries: retries,
                responsePendingCount: responsePendingCount,
                elapsed: activeClock.elapsed,
                nrc: n.nrc,
                originalSid: n.originalSid,
              ),
            final UdsReadMalformed m => UdsTransactionMalformed(
                request: request,
                attempts: attempts,
                retries: retries,
                responsePendingCount: responsePendingCount,
                elapsed: activeClock.elapsed,
                message: m.message,
                rawBytes: pdu.bytes,
              ),
          };
        }

        if (request.serviceId == 0x19) {
          state = UdsTransactionState.completed;
          onStateChange?.call(state);

          if (request is UdsReportDtcByStatusMaskTransactionRequest) {
            final parsed = UdsDtcCodec.parseResponseBytes(
              requestedSubfunction: 0x02,
              responseBytes: pdu.bytes,
              requestedMask: request.mask,
            );
            return switch (parsed) {
              final UdsDtcSuccess s => UdsTransactionSuccess(
                  request: request,
                  attempts: attempts,
                  retries: retries,
                  responsePendingCount: responsePendingCount,
                  elapsed: activeClock.elapsed,
                  responsePdu: pdu,
                  sourceAddress: msg.sourceAddress,
                  dtcResult: s,
                ),
              final UdsDtcNegative n => UdsTransactionTerminalNegative(
                  request: request,
                  attempts: attempts,
                  retries: retries,
                  responsePendingCount: responsePendingCount,
                  elapsed: activeClock.elapsed,
                  nrc: n.nrc,
                  originalSid: n.originalSid,
                ),
              final UdsDtcMalformed m => UdsTransactionMalformed(
                  request: request,
                  attempts: attempts,
                  retries: retries,
                  responsePendingCount: responsePendingCount,
                  elapsed: activeClock.elapsed,
                  message: m.message,
                  rawBytes: pdu.bytes,
                ),
            };
          } else if (request is UdsReportSupportedDtcTransactionRequest) {
            final parsed = UdsDtcCodec.parseResponseBytes(
              requestedSubfunction: 0x0A,
              responseBytes: pdu.bytes,
            );
            return switch (parsed) {
              final UdsDtcSuccess s => UdsTransactionSuccess(
                  request: request,
                  attempts: attempts,
                  retries: retries,
                  responsePendingCount: responsePendingCount,
                  elapsed: activeClock.elapsed,
                  responsePdu: pdu,
                  sourceAddress: msg.sourceAddress,
                  dtcResult: s,
                ),
              final UdsDtcNegative n => UdsTransactionTerminalNegative(
                  request: request,
                  attempts: attempts,
                  retries: retries,
                  responsePendingCount: responsePendingCount,
                  elapsed: activeClock.elapsed,
                  nrc: n.nrc,
                  originalSid: n.originalSid,
                ),
              final UdsDtcMalformed m => UdsTransactionMalformed(
                  request: request,
                  attempts: attempts,
                  retries: retries,
                  responsePendingCount: responsePendingCount,
                  elapsed: activeClock.elapsed,
                  message: m.message,
                  rawBytes: pdu.bytes,
                ),
            };
          }
        }

        // Unrecognized service ID
        state = UdsTransactionState.completed;
        onStateChange?.call(state);
        return UdsTransactionMalformed(
          request: request,
          attempts: attempts,
          retries: retries,
          responsePendingCount: responsePendingCount,
          elapsed: activeClock.elapsed,
          message:
              'Unexpected response SID: 0x${sid.toRadixString(16).padLeft(2, '0').toUpperCase()}',
          rawBytes: pdu.bytes,
        );
      }
    }
  }
}
