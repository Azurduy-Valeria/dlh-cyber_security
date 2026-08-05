#!/bin/bash
#
# 3-remediation_queue.sh
#
# Cross-references cis_profile.json (Task 1) against lynis_findings.json
# (Task 2) to produce:
#   - gap_analysis.json      : every control's compliance status + evidence
#   - remediation_queue.json : the non-compliant/partially-compliant subset,
#                              enriched and sorted by priority score
#
# This is the decision engine behind Tasks 4-13: it explains, with
# evidence, why each later hardening script runs and in what order.
#
# Matching a control to Lynis evidence is keyword-based: each control has
# a small set of terms (Lynis test-ID prefixes and topic words) that are
# checked case-insensitively against every finding's test_id + message.
#   - no matching finding at all           -> compliant
#   - matches include a "warning[]" entry  -> non_compliant
#   - matches are suggestion/manual_check  -> partially_compliant
#   - control has no keyword set defined   -> not_assessed
#     (MedDefense-internal controls no generic scanner can see)
#
# Usage: ./3-remediation_queue.sh

set -euo pipefail

CIS_PROFILE="cis_profile.json"
LYNIS_FINDINGS="lynis_findings.json"
GAP_FILE="gap_analysis.json"
QUEUE_FILE="remediation_queue.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed." >&2
    exit 1
fi

if [[ ! -f "$CIS_PROFILE" ]]; then
    echo "Error: '$CIS_PROFILE' not found - run 1-cis_profile.sh first." >&2
    exit 1
fi

if [[ ! -f "$LYNIS_FINDINGS" ]]; then
    echo "Error: '$LYNIS_FINDINGS' not found - run 2-lynis_parse.sh first." >&2
    exit 1
fi

# Keyword set per control_id, used to pull matching Lynis evidence.
# MD-CIS-15 is intentionally left empty: it is a MedDefense-internal
# control with no generic-scanner coverage, so it is always not_assessed.
declare -A KEYWORDS=(
    [MD-CIS-01]="ssh permitrootlogin passwordauthentication SSH-"
    [MD-CIS-02]="ssh maxauthtries clientalive logingracetime allowusers banner SSH-"
    [MD-CIS-03]="faillock lockout AUTH- account.?lock"
    [MD-CIS-04]="pwquality password.?quality minlen AUTH-"
    [MD-CIS-05]="ip_forward forwarding redirect rp_filter spoof KRNL-"
    [MD-CIS-06]="aslr randomize_va_space kptr dmesg suid_dumpable KRNL-"
    [MD-CIS-07]="firewall ufw iptables nftables FIRE-"
    [MD-CIS-08]="avahi cups rpcbind bluetooth modemmanager service daemon"
    [MD-CIS-09]="mysql mariadb database 3306 bind-address DBS-"
    [MD-CIS-10]="suid FILE-"
    [MD-CIS-11]="world.?writable sticky.?bit tmp noexec nosuid nodev STRG- FILE-"
    [MD-CIS-12]="apparmor selinux MAC MACF-"
    [MD-CIS-13]="audit auditd ACCT- USER- syslog"
    [MD-CIS-14]="log.?rotat retention logrotate LOGG-"
    [MD-CIS-15]=""
)

gap_entries=()

for control_id in $(jq -r '.[].control_id' "$CIS_PROFILE"); do
    control=$(jq --arg id "$control_id" '.[] | select(.control_id == $id)' "$CIS_PROFILE")
    keywords="${KEYWORDS[$control_id]:-}"

    if [[ -z "$keywords" ]]; then
        matches="[]"
        status="not_assessed"
    else
        # Turn the space-separated keyword list into a single alternation
        # regex and pull every Lynis finding whose test_id or message
        # matches it, case-insensitively.
        pattern=$(echo "$keywords" | tr ' ' '|')
        matches=$(jq --arg pat "$pattern" \
            '[.findings[] | select(((.test_id + " " + .message) | test($pat; "i")))]' \
            "$LYNIS_FINDINGS")

        match_count=$(echo "$matches" | jq 'length')
        warning_count=$(echo "$matches" | jq '[.[] | select(.severity == "warning")] | length')

        if [[ "$match_count" -eq 0 ]]; then
            status="compliant"
        elif [[ "$warning_count" -gt 0 ]]; then
            status="non_compliant"
        else
            status="partially_compliant"
        fi
    fi

    gap_entries+=("$(jq -n --argjson control "$control" --argjson matches "$matches" --arg status "$status" \
        '{control_id: $control.control_id, title: $control.title, severity: $control.severity,
          asset_scope: $control.asset_scope, implementation_task: $control.implementation_task,
          verification_method: $control.verification_method, status: $status,
          matched_findings: $matches}')")
done

printf '%s\n' "${gap_entries[@]}" | jq -s '.' > "$GAP_FILE"

# --- Build the prioritized remediation queue from the gaps ------------------
# priority_score (1-100) = severity weight + status weight + evidence weight
#   severity: critical=40 high=25 medium=10
#   status:   non_compliant=40  partially_compliant=20
#   evidence: min(matched_findings * 5, 20)
QUEUE_JSON=$(jq '
    def sev_weight: {"critical": 40, "high": 25, "medium": 10}[.severity];
    def status_weight: {"non_compliant": 40, "partially_compliant": 20}[.status];

    [.[] | select(.status == "non_compliant" or .status == "partially_compliant")
     | . + {
         priority_score: ( sev_weight + status_weight
                            + ([(.matched_findings | length) * 5, 20] | min) ),
         affected_asset: .asset_scope,
         remediation_script: .implementation_task,
         operational_risk: (
             if .status == "non_compliant" then
                 "Unresolved: Lynis confirms an active " + .severity + "-severity gap for \"" + .title + "\" - leaves the documented threat path open on " + (.asset_scope | join(", "))
             else
                 "Partially addressed: Lynis flags related weaknesses for \"" + .title + "\" that have not been fully remediated on " + (.asset_scope | join(", "))
             end
         ),
         expected_validation_check: .verification_method
       }
    ]
    | sort_by(-.priority_score)
' "$GAP_FILE")

echo "$QUEUE_JSON" > "$QUEUE_FILE"

# --- Summary -----------------------------------------------------------
TOTAL=$(jq 'length' "$GAP_FILE")
COMPLIANT=$(jq '[.[] | select(.status == "compliant")] | length' "$GAP_FILE")
NON_COMPLIANT=$(jq '[.[] | select(.status == "non_compliant")] | length' "$GAP_FILE")
PARTIAL=$(jq '[.[] | select(.status == "partially_compliant")] | length' "$GAP_FILE")
NOT_ASSESSED=$(jq '[.[] | select(.status == "not_assessed")] | length' "$GAP_FILE")
QUEUED=$(jq 'length' "$QUEUE_FILE")

echo "Controls assessed: $TOTAL"
echo "Compliant: $COMPLIANT"
echo "Non-compliant: $NON_COMPLIANT"
echo "Partially compliant: $PARTIAL"
echo "Not assessed: $NOT_ASSESSED"
echo "Remediation actions queued: $QUEUED"
echo "Report saved to: $GAP_FILE"
echo "Queue saved to: $QUEUE_FILE"
