#!/bin/bash
#
# 2-lynis_parse.sh
#
# Parses a Lynis "lynis-report.dat" key-value report file into structured
# JSON: the hardening index plus every warning[], suggestion[] and
# manual_check[] finding, each broken into severity/test_id/message.
#
# Report line format (as written by Lynis):
#   warning[]=TEST-ID|Message text|extra|extra|
#   suggestion[]=TEST-ID|Message text|extra|extra|
#   manual_check[]=TEST-ID|Message text|extra|extra|
#   hardening_index=NN
#
# Usage: ./2-lynis_parse.sh /var/log/lynis-report.dat

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <lynis-report.dat>" >&2
    exit 1
fi

REPORT="$1"

if [[ ! -f "$REPORT" ]]; then
    echo "Error: file '$REPORT' not found." >&2
    exit 1
fi

if [[ ! -r "$REPORT" ]]; then
    echo "Error: '$REPORT' is not readable (try running with sudo)." >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed." >&2
    exit 1
fi

# hardening_index=NN (sometimes NN|max in older versions) - take the
# leading integer, default to 0 if the key is missing.
HARDENING_INDEX=$(grep -m1 '^hardening_index=' "$REPORT" | cut -d= -f2 | cut -d'|' -f1)
HARDENING_INDEX=${HARDENING_INDEX:-0}
[[ "$HARDENING_INDEX" =~ ^[0-9]+$ ]] || HARDENING_INDEX=0

# Single pass, in file order, over every warning[]/suggestion[]/manual_check[]
# line so findings come out in the same order Lynis recorded them.
grep -E '^(warning|suggestion|manual_check)\[\]=' "$REPORT" | while IFS= read -r line; do
    severity="${line%%\[\]=*}"
    rest="${line#*\[\]=}"
    test_id="${rest%%|*}"
    remainder="${rest#*|}"
    message="${remainder%%|*}"

    jq -n --arg sev "$severity" --arg id "$test_id" --arg msg "$message" \
        '{severity: $sev, test_id: $id, message: $msg}'
done | jq -s --argjson hi "$HARDENING_INDEX" '{hardening_index: $hi, findings: .}'
