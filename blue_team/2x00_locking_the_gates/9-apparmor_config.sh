#!/bin/bash
#
# 9-apparmor_config.sh
#
# When the crypto-miner compromised billing-srv-01 through Apache (1x00
# incident), it had full filesystem access as www-data. AppArmor is the
# difference between "the attacker got a shell on our web server" and
# "the attacker got a shell that can only access /var/www." This script
# enforces AppArmor on the network-exposed services and adds a custom
# profile for the MedDefense billing application so a zero-day in the
# app cannot reach patient data directories.
#
# Usage: sudo ./9-apparmor_config.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: this script must be run as root (sudo)." >&2
    exit 1
fi

if ! command -v aa-status >/dev/null 2>&1; then
    echo "Error: AppArmor userspace tools not found (aa-status missing)." >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed." >&2
    exit 1
fi

echo "[*] Checking AppArmor status..."
MODULE_STATE=$(cat /sys/module/apparmor/parameters/enabled 2>/dev/null || echo "N")
if [[ "$MODULE_STATE" == "Y" ]]; then
    echo "    AppArmor module: loaded"
else
    echo "    AppArmor module: not loaded" >&2
    exit 1
fi

SERVICE_STATE=$(systemctl is-active apparmor 2>/dev/null || echo "inactive")
echo "    AppArmor service: $SERVICE_STATE"

STATUS_JSON=$(aa-status --json)

# Services that must run in enforce mode. A couple of path aliases are
# checked per label since package names differ across distros
# (apache2/httpd, mysqld/mariadbd).
declare -A ENFORCE_TARGETS=(
    ["Apache"]="/usr/sbin/apache2 /usr/sbin/httpd"
    ["MySQL"]="/usr/sbin/mysqld /usr/sbin/mariadbd"
    ["SSH"]="/usr/sbin/sshd"
)
ENFORCE_ORDER=("Apache" "MySQL" "SSH")

echo "[*] Profile enforcement:"
for label in "${ENFORCE_ORDER[@]}"; do
    profile_path=""
    mode=""
    for candidate in ${ENFORCE_TARGETS[$label]}; do
        m=$(echo "$STATUS_JSON" | jq -r --arg p "$candidate" '.profiles[$p] // empty')
        if [[ -n "$m" ]]; then
            profile_path="$candidate"
            mode="$m"
            break
        fi
    done

    if [[ -z "$profile_path" ]]; then
        printf "    %-25s[NO PROFILE FOUND]\n" "$label"
        continue
    fi

    if [[ "$mode" == "enforce" ]]; then
        printf "    %-25s%-21s[OK]\n" "$profile_path" "enforce"
    else
        aa-enforce "$profile_path" >/dev/null 2>&1 || true
        printf "    %-25s%-21s[ENFORCED]\n" "$profile_path" "$mode -> enforce"
        STATUS_JSON=$(aa-status --json)
    fi
done

# --- Custom MedDefense billing application profile ----------------------
BILLING_APP_BIN="/opt/meddefense/billing-app"
PROFILE_PATH="/etc/apparmor.d/opt.meddefense.billing-app"

echo "[*] Custom profile: $BILLING_APP_BIN"
cat > "$PROFILE_PATH" <<EOF
# MedDefense custom AppArmor profile - restricts the billing application
# to only the directories it needs. Addresses the 1x00 incident finding
# that a compromised web process had unrestricted filesystem access.
#include <tunables/global>

$BILLING_APP_BIN {
  #include <abstractions/base>

  $BILLING_APP_BIN mr,
  /opt/meddefense/data/    r,
  /opt/meddefense/data/**  rw,
  /opt/meddefense/logs/    r,
  /opt/meddefense/logs/**  rw,
  /etc/meddefense/**       r,

  deny /home/**          rwklx,
  deny /root/**          rwklx,
  deny /var/lib/mysql/** rwklx,
}
EOF

if apparmor_parser -r "$PROFILE_PATH" 2>/dev/null; then
    aa-enforce "$BILLING_APP_BIN" >/dev/null 2>&1 || true
    echo "    $BILLING_APP_BIN   [CREATED] [ENFORCED]"
    STATUS_JSON=$(aa-status --json)
else
    echo "    $BILLING_APP_BIN   [CREATED] [PARSE FAILED - check $PROFILE_PATH]" >&2
fi

# --- Unconfined network-exposed processes --------------------------------
# ss reports the short process name; the full exe path (resolved from the
# pid) is what AppArmor keys profiles on, so that's what gets checked.
echo "[*] Unconfined network-exposed processes:"
mapfile -t LISTEN_PIDS < <(ss -tulpen 2>/dev/null | grep -oP 'pid=\K[0-9]+' | sort -u)

declare -A SEEN_EXE=()
UNCONFINED_COUNT=0
for pid in "${LISTEN_PIDS[@]}"; do
    exe=$(readlink -f "/proc/$pid/exe" 2>/dev/null || echo "")
    [[ -z "$exe" || -n "${SEEN_EXE[$exe]:-}" ]] && continue
    SEEN_EXE[$exe]=1

    has_profile=$(echo "$STATUS_JSON" | jq -r --arg e "$exe" '.profiles[$e] // empty')
    if [[ -z "$has_profile" ]]; then
        printf "    %-25s[UNCONFINED - Profile recommended]\n" "$exe"
        UNCONFINED_COUNT=$((UNCONFINED_COUNT + 1))
    fi
done
[[ "$UNCONFINED_COUNT" -eq 0 ]] && echo "    (none)"

ENFORCE_COUNT=$(echo "$STATUS_JSON" | jq '[.profiles[] | select(. == "enforce")] | length')
COMPLAIN_COUNT=$(echo "$STATUS_JSON" | jq '[.profiles[] | select(. == "complain")] | length')

echo "Profiles in enforce: $ENFORCE_COUNT | Complain: $COMPLAIN_COUNT | Unconfined: $UNCONFINED_COUNT"
