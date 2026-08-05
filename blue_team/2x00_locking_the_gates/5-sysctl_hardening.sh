#!/bin/bash
#
# 5-sysctl_hardening.sh
#
# Hardens the kernel network stack and memory protections. In the
# Crimson Tide attack chain (Phase 3), the attacker moved laterally
# across a flat network - a compromised Linux box with IP forwarding on
# becomes a router for that traffic, accepted ICMP redirects let an
# attacker reroute it, and disabled ASLR makes memory-corruption exploits
# trivially reliable. These are default-off settings that should never
# be on in production.
#
# Usage: sudo ./5-sysctl_hardening.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: this script must be run as root (sudo)." >&2
    exit 1
fi

SYSCTL_CONF="/etc/sysctl.conf"
BACKUP="/etc/sysctl.conf.bak"

if [[ ! -f "$SYSCTL_CONF" ]]; then
    echo "Error: $SYSCTL_CONF not found." >&2
    exit 1
fi

echo "[*] Backing up $SYSCTL_CONF"
cp -p "$SYSCTL_CONF" "$BACKUP"

# Ordered "key=value" pairs - order matters for the printed report, so a
# plain indexed array is used instead of an associative array.
PARAMS=(
    "net.ipv4.ip_forward=0"
    "net.ipv4.conf.all.accept_redirects=0"
    "net.ipv4.conf.default.accept_redirects=0"
    "net.ipv4.conf.all.send_redirects=0"
    "net.ipv4.conf.all.accept_source_route=0"
    "net.ipv4.conf.all.log_martians=1"
    "net.ipv4.tcp_syncookies=1"
    "net.ipv4.icmp_echo_ignore_broadcasts=1"
    "net.ipv6.conf.all.disable_ipv6=1"
    "net.ipv6.conf.default.disable_ipv6=1"
    "kernel.randomize_va_space=2"
    "fs.suid_dumpable=0"
    "kernel.dmesg_restrict=1"
    "kernel.kptr_restrict=2"
)

# Replaces (or adds) a single "key = value" line, commented or not, so
# re-running the script stays idempotent instead of stacking duplicates.
set_sysctl() {
    local key="$1" value="$2" esc_key
    esc_key=$(printf '%s' "$key" | sed 's/\./\\./g')
    sed -i -E "/^[[:space:]]*#?[[:space:]]*${esc_key}[[:space:]]*=/d" "$SYSCTL_CONF"
    echo "$key = $value" >> "$SYSCTL_CONF"
}

echo "[*] Applying kernel hardening parameters..."
for entry in "${PARAMS[@]}"; do
    set_sysctl "${entry%%=*}" "${entry#*=}"
done

sysctl -p "$SYSCTL_CONF" >/dev/null 2>&1 || true

PASS_COUNT=0
FAIL_COUNT=0
for entry in "${PARAMS[@]}"; do
    key="${entry%%=*}"
    expected="${entry#*=}"
    proc_path="/proc/sys/${key//./\/}"
    actual=$(cat "$proc_path" 2>/dev/null || echo "N/A")

    if [[ "$actual" == "$expected" ]]; then
        status="PASS"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        status="FAIL"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    printf "%-44s[%s]\n" "$key = $expected" "$status"
done

echo "Parameters applied: ${#PARAMS[@]}"
echo "Verified PASS: $PASS_COUNT"
echo "Verified FAIL: $FAIL_COUNT"
