#!/bin/bash
#
# 7-service_minimization.sh
#
# Every running service is a potential entry point. A billing server does
# not need avahi-daemon, cups or rpcbind. The 1x02 scan found
# billing-srv-01 with unnecessary services exposed network-wide (Finding
# 006: MySQL on 0.0.0.0), and the baseline snapshot (Task 0) counted 24
# enabled services on a host that needs fewer than 10.
#
# Usage: sudo ./7-service_minimization.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: this script must be run as root (sudo)." >&2
    exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "Error: systemctl not found - this script requires systemd." >&2
    exit 1
fi

# The only services MedDefense operations require on this fleet, and why.
WHITELIST_ORDER=(
    "ssh.service"
    "apache2.service"
    "mysql.service"
    "ufw.service"
    "auditd.service"
    "apparmor.service"
    "cron.service"
    "rsyslog.service"
    "systemd-timesyncd.service"
)
declare -A WHITELIST_REASON=(
    ["ssh.service"]="remote administration access, hardened in Task 4"
    ["apache2.service"]="hosts the MedDefense billing web application"
    ["mysql.service"]="backend database for the billing application"
    ["ufw.service"]="host firewall, deny-by-default (Task 11)"
    ["auditd.service"]="kernel audit logging (Task 10)"
    ["apparmor.service"]="mandatory access control (Task 9)"
    ["cron.service"]="scheduled maintenance and backup jobs"
    ["rsyslog.service"]="system logging, feeds the log-srv-01 aggregator"
    ["systemd-timesyncd.service"]="accurate timestamps for audit logs and TLS validation"
)

is_whitelisted() {
    local svc="$1" w
    for w in "${WHITELIST_ORDER[@]}"; do
        [[ "$svc" == "$w" ]] && return 0
    done
    return 1
}

echo "[*] Scanning enabled services..."
mapfile -t ENABLED < <(systemctl list-unit-files --type=service --state=enabled --no-legend 2>/dev/null | awk '{print $1}')
BEFORE=${#ENABLED[@]}
echo "    Enabled services found: $BEFORE"

echo "[*] Comparing against MedDefense whitelist (${#WHITELIST_ORDER[@]} required services)..."
DISABLED=0
for svc in "${ENABLED[@]}"; do
    if ! is_whitelisted "$svc"; then
        systemctl stop "$svc" 2>/dev/null || true
        systemctl disable "$svc" 2>/dev/null || true
        printf "  %-25s[STOPPED] [DISABLED]\n" "$svc"
        DISABLED=$((DISABLED + 1))
    fi
done

echo "[*] Verifying required services are running..."
AFTER=0
for svc in "${WHITELIST_ORDER[@]}"; do
    if ! systemctl list-unit-files --type=service --no-legend 2>/dev/null | awk '{print $1}' | grep -qx "$svc"; then
        printf "  %-25s[NOT INSTALLED - %s]\n" "$svc" "${WHITELIST_REASON[$svc]}"
        continue
    fi

    if ! systemctl is-active --quiet "$svc" 2>/dev/null; then
        systemctl enable "$svc" 2>/dev/null || true
        systemctl start "$svc" 2>/dev/null || true
    fi

    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        printf "  %-25s[ACTIVE]\n" "$svc"
        AFTER=$((AFTER + 1))
    else
        printf "  %-25s[INACTIVE - failed to start]\n" "$svc"
    fi
done

echo "Before: $BEFORE | After: $AFTER | Disabled: $DISABLED"
