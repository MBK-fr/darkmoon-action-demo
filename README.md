# Darkmoon GitHub Action — demo repository

This repo is a **runnable demo** of the official Darkmoon Pentest GitHub Action.
It is self-contained: it runs on a normal GitHub-hosted runner (`ubuntu-latest`),
with no real Darkmoon deployment, and still exercises the **real** action bundle
and the **real** `@darkmoon/client` OSS launch → correlate → wait → findings →
fail-policy → SARIF path.

## The `uses:` line

```yaml
- uses: ASCIT31/darkmoon-action@v1
```

(Pin a release instead with `uses: ASCIT31/darkmoon-action@v0.1.0`.)

## What the workflow does

`.github/workflows/darkmoon.yml`:

```yaml
- uses: ASCIT31/darkmoon-action@v1
  id: darkmoon
  env:
    DM_DATA_DIR: ${{ github.workspace }}/demo/data
    DM_REPORTS:  ${{ github.workspace }}/demo/reports
    DM_SEED:     ${{ github.workspace }}/demo/seed
  with:
    mode: oss
    oss-data-dir:    ${{ github.workspace }}/demo/data
    oss-reports-dir: ${{ github.workspace }}/demo/reports
    oss-script-path: ${{ github.workspace }}/demo/darkmoon-engine.sh
    target: http://juice-shop.local:3000
    focus: sqli,idor
    fail-on: critical,high
    report-format: sarif
    poll-interval-ms: '1000'
    timeout-ms: '60000'

- uses: github/codeql-action/upload-sarif@v3
  if: ${{ always() && steps.darkmoon.outputs.report-path != '' }}
  with:
    sarif_file: ${{ steps.darkmoon.outputs.report-path }}
```

`permissions: security-events: write` is set at the top of the workflow so the
`upload-sarif` step can push alerts to **Security → Code scanning**.

## How the demo engine works

- `demo/data/` holds **baseline** campaigns (every fixture campaign EXCEPT the
  target) — `campaigns/` + `vulnerabilities/`. This is the OSS bind-mount the
  action reads (`oss-data-dir`).
- `demo/seed/` holds the **target** campaign fixtures
  (`camp_20260924_70602bf9`: 2 critical / 1 high / 2 medium, all exploited).
- `demo/darkmoon-engine.sh` is what `oss-script-path` points at. The action's
  OSS backend launches it (`darkmoon-engine.sh "<PROMPT>"`), then correlates the
  new campaign by snapshot-diffing `campaigns/`. The launcher plants the target
  fixtures from `demo/seed/` into `demo/data/` + `demo/reports/` with a fresh
  mtime, so exactly one *new* campaign appears and the client attributes the run
  to it.

## Expected result

The job **fails** (exit 1) because `fail-on: critical,high` trips on the
findings (2 critical, 1 high). The verdict comes from the **findings**, never
from the engine's exit code (the OSS engine exits 0). Outputs:
`campaign-id=camp_20260924_70602bf9`, `edition=oss`, `overall-risk=critical`,
`total-findings=5`, `critical=2`, `high=1`, `medium=2`, `low=0`, `info=0`,
`exploited=5`, `policy-failed=true`. The `report-path` output points at the
synthesized `.sarif`, uploaded to code scanning.

To make the gate **non-blocking**, set `fail-on:` to empty (or `none`); to gate
only on criticals, `fail-on: critical`.
