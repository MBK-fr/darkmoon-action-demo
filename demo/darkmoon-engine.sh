#!/bin/sh
# demo/darkmoon-engine.sh — self-contained OSS launcher for the Darkmoon GitHub
# Action demo. On a GitHub-hosted runner there is no real Darkmoon container, so
# this stands in for the engine that `oss-script-path` points at.
#
# The action's OSS backend (@darkmoon/client OssLocalBackend.launchCampaign)
# invokes this script as:  darkmoon-engine.sh "<PROMPT>"   (prompt = $1, ignored
# here) with the process env inherited. It then correlates the NEW campaign by
# snapshot-diffing the campaigns/ dir. So all we must do is PLANT the target
# campaign fixtures (a genuine completed Juice Shop run: 2 critical / 1 high /
# 2 medium, all exploited) into the live OSS data + reports dirs with a fresh
# mtime, and the REAL client does launch -> correlate -> wait -> listFindings ->
# computeFailPolicy end to end.
#
# Paths come from the environment the workflow sets (with repo-relative
# fallbacks so the script also works when run by hand):
#   DM_DATA_DIR  -> the oss-data-dir  (campaigns/ + vulnerabilities/)
#   DM_REPORTS   -> the oss-reports-dir
#   DM_SEED      -> committed seed dir holding the target fixtures
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DM_DATA_DIR="${DM_DATA_DIR:-$SCRIPT_DIR/data}"
DM_REPORTS="${DM_REPORTS:-$SCRIPT_DIR/reports}"
DM_SEED="${DM_SEED:-$SCRIPT_DIR/seed}"
CID=camp_20260924_70602bf9

mkdir -p "$DM_DATA_DIR/campaigns" "$DM_DATA_DIR/vulnerabilities" "$DM_REPORTS"
cp "$DM_SEED/campaigns/$CID.json"       "$DM_DATA_DIR/campaigns/$CID.json"
cp "$DM_SEED/vulnerabilities/$CID.json" "$DM_DATA_DIR/vulnerabilities/$CID.json"
cp "$DM_SEED/reports/"pentest_report_*.md "$DM_REPORTS/" 2>/dev/null || true
# fresh mtime so the correlator counts it as the campaign this launch created
touch "$DM_DATA_DIR/campaigns/$CID.json"
