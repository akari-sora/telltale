# AA-08 runner evidence boundary

The Android Automotive runner treats VHAL dumps as input-delivery evidence.
They do not prove that Telltale consumed the sample, changed its motion state,
blocked DTC access, or auto-popped a screen. Those acceptance checks require
externally observed app UI or app-specific logs and fail closed when observation
is missing or ambiguous. An installed package is reported only as installed,
not as a connected or observed app.

The DHU runner uses freshness and non-black checks as capture preconditions.
A live acceptance run also requires a semantic observer receipt. For a single
scenario, pass `--semantic-evidence receipt.json`; for a matrix, pass
`--semantic-evidence-dir receipts`. Matrix receipts are named
`<profile>__<script>.json` and use this shape:

```json
{
  "scenario_id": "p2-720p__baseline",
  "screenshots": {
    "aa06-baseline-home.png": {
      "sha256": "<sha256 of the fresh screenshot>",
      "observed_state": "Telltale home telemetry screen is visible",
      "observer": "manual-review"
    }
  }
}
```

Every expected screenshot must have a non-empty observation and observer, and
its digest must match the exact captured bytes. Missing, stale, wrong-scenario,
or unrelated-image receipts fail acceptance.

When a live run first captures screenshots without a receipt, it fails closed
but retains the run directory. Review those exact images, create the receipt,
then complete the bounded post-review with
`--review-run-dir <run-dir> --semantic-evidence <receipt.json>`. The post-review
rechecks capture freshness, pixel preconditions, and every bound digest before
writing `semantic-review.json`.

Dry runs validate configuration, commands, parsers, and scheduling only. Their
summary is always `Executed=0, Passed=0`; they never establish live acceptance.
