#!/bin/bash


set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Warning: not running as root - some checks (SUID scan, sshd -T," >&2
    echo "         full sysctl list) may be incomplete. Re-run with sudo." >&2
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTDIR="./baseline_snapshot_${TIMESTAMP}"
mkdir -p "$OUTDIR"

echo "=== Baseline snapshot - $(date) ==="
echo "Report directory: $OUTDIR"
echo ""

# --- 1. System identification -----------------------------------------
HOSTNAME_VAL=$(hostname)
OS_VAL=$(grep -oP '(?<=^PRETTY_NAME=").*(?="$)' /etc/os-release 2>/dev/null || echo "unknown")
KERNEL_VAL=$(uname -r)
UPTIME_VAL=$(uptime -p 2>/dev/null || uptime)

{
    echo "Hostname: $HOSTNAME_VAL"
    echo "OS: $OS_VAL"
    echo "Kernel: $KERNEL_VAL"
    echo "Uptime: $UPTIME_VAL"
} > "$OUTDIR/system_id.txt"

# --- 2. Running services -------------------------------------------------
if command -v systemctl >/dev/null 2>&1; then
    systemctl list-units --type=service --state=running --no-legend \
        > "$OUTDIR/services_running.txt" 2>/dev/null || true
else
    service --status-all > "$OUTDIR/services_running.txt" 2>/dev/null || true
fi
SERVICES_COUNT=$(wc -l < "$OUTDIR/services_running.txt" | tr -d ' ')

# --- 3. Open ports / listening sockets -----------------------------------
if command -v ss >/dev/null 2>&1; then
    ss -tulpen > "$OUTDIR/open_ports.txt" 2>/dev/null || true
else
    netstat -tulpen > "$OUTDIR/open_ports.txt" 2>/dev/null || true
fi
PORTS_COUNT=$(grep -c "LISTEN\|UNCONN" "$OUTDIR/open_ports.txt" 2>/dev/null || echo 0)

# --- 4. SUID / SGID binaries ----------------------------------------------
find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o \
    -type f -perm -4000 -print 2>/dev/null > "$OUTDIR/suid_binaries.txt" || true
SUID_COUNT=$(wc -l < "$OUTDIR/suid_binaries.txt" | tr -d ' ')

find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o \
    -type f -perm -2000 -print 2>/dev/null > "$OUTDIR/sgid_binaries.txt" || true
SGID_COUNT=$(wc -l < "$OUTDIR/sgid_binaries.txt" | tr -d ' ')

# --- 5. World-writable files (excluding /proc, /sys, /dev) ---------------
find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o \
    -type f -perm -0002 -print 2>/dev/null > "$OUTDIR/world_writable.txt" || true
WORLD_WRITABLE_COUNT=$(wc -l < "$OUTDIR/world_writable.txt" | tr -d ' ')

# --- 6. Security-relevant sysctl parameters --------------------------------
SYSCTL_KEYS=(
    net.ipv4.ip_forward
    net.ipv4.conf.all.accept_redirects
    net.ipv4.conf.all.send_redirects
    net.ipv4.conf.all.rp_filter
    net.ipv4.icmp_echo_ignore_broadcasts
    net.ipv4.tcp_syncookies
    kernel.randomize_va_space
    kernel.dmesg_restrict
    kernel.kptr_restrict
    fs.suid_dumpable
)
: > "$OUTDIR/sysctl_security.txt"
for key in "${SYSCTL_KEYS[@]}"; do
    sysctl "$key" >> "$OUTDIR/sysctl_security.txt" 2>/dev/null || \
        echo "$key = <not available>" >> "$OUTDIR/sysctl_security.txt"
done

# --- 7. SSH configuration ---------------------------------------------------
if command -v sshd >/dev/null 2>&1 && [[ $EUID -eq 0 ]]; then
    sshd -T > "$OUTDIR/ssh_config.txt" 2>/dev/null || true
fi
if [[ -f /etc/ssh/sshd_config ]]; then
    grep -Ev '^\s*(#|$)' /etc/ssh/sshd_config >> "$OUTDIR/ssh_config.txt" 2>/dev/null || true
fi

# --- 8. User accounts and sudo group membership -----------------------------
{
    echo "-- All accounts (/etc/passwd) --"
    cut -d: -f1,3,7 /etc/passwd
    echo ""
    echo "-- Interactive accounts (UID >= 1000) --"
    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1, $3, $7}' /etc/passwd
    echo ""
    echo "-- sudo/wheel group members --"
    getent group sudo 2>/dev/null
    getent group wheel 2>/dev/null
} > "$OUTDIR/accounts_sudo.txt" || true

# --- Summary ----------------------------------------------------------------
echo "Hostname: $HOSTNAME_VAL"
echo "OS: $OS_VAL"
echo "Running services: $SERVICES_COUNT"
echo "Open ports: $PORTS_COUNT"
echo "SUID binaries: $SUID_COUNT"
echo "SGID binaries: $SGID_COUNT"
echo "World-writable files: $WORLD_WRITABLE_COUNT"
echo ""
echo "Full baseline data saved under: $OUTDIR"
