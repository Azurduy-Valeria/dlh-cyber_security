#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Privilege check ---------------------------------------------------------
IS_ROOT=false
if [ "$(id -u)" -eq 0 ]; then
    IS_ROOT=true
else
    echo "Warning: not running as root - some data (full SUID/world-writable" >&2
    echo "sweep, listening-socket process owners, sshd effective config) will" >&2
    echo "be incomplete. Re-run with: sudo ./0-baseline_snapshot.sh" >&2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/results"
mkdir -p "$RESULTS_DIR"

HOSTNAME_VAL="$(hostname)"
OUTPUT_FILE="${RESULTS_DIR}/baseline_snapshot_${HOSTNAME_VAL}.json"

# --- JSON helpers ------------------------------------------------------------

json_escape() {
    # Escapes backslashes, double quotes and control characters for safe
    # embedding of arbitrary filesystem/process strings inside a JSON string.
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\r'/}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

array_from_lines() {
    # Reads newline-delimited items on stdin, emits a JSON array of strings.
    local first=true
    printf '['
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        if $first; then first=false; else printf ','; fi
        printf '"%s"' "$(json_escape "$line")"
    done
    printf ']'
}

object_from_kv_lines() {
    # Reads tab-separated "key<TAB>value" lines on stdin, emits a JSON object.
    local first=true
    printf '{'
    while IFS=$'\t' read -r k v; do
        [ -z "$k" ] && continue
        if $first; then first=false; else printf ','; fi
        printf '"%s":"%s"' "$(json_escape "$k")" "$(json_escape "$v")"
    done
    printf '}'
}

count_nonempty() {
    # Counts non-blank lines on stdin. Always exits 0 - including on zero
    # matches - so it never trips `set -e`/pipefail the way `grep -c .`
    # would (grep -c exits 1 when the count is 0, which is a legitimate,
    # expected result here, not a failure).
    awk 'NF{c++} END{print c+0}'
}

# --- 1. System identification -------------------------------------------------
OS_PRETTY="$(grep -oP '(?<=^PRETTY_NAME=).*' /etc/os-release 2>/dev/null | tr -d '"')" || OS_PRETTY=""
[ -z "$OS_PRETTY" ] && OS_PRETTY="unknown"
KERNEL_VER="$(uname -r)"
UPTIME_HUMAN="$(uptime -p 2>/dev/null)" || UPTIME_HUMAN="unknown"
UPTIME_SECONDS="$(awk '{print int($1)}' /proc/uptime 2>/dev/null)" || UPTIME_SECONDS=0
[ -z "$UPTIME_SECONDS" ] && UPTIME_SECONDS=0

# --- 2. Running services -------------------------------------------------------
SERVICES_LIST="$(systemctl list-units --type=service --state=running --no-legend --plain 2>/dev/null | awk '{print $1}')" || SERVICES_LIST=""
SERVICES_COUNT="$(printf '%s\n' "$SERVICES_LIST" | count_nonempty)"

# --- 3. Open ports / listening sockets ------------------------------------------
SOCKETS_LIST="$(ss -Htulnp 2>/dev/null)" || SOCKETS_LIST=""
OPEN_PORTS_COUNT="$(printf '%s\n' "$SOCKETS_LIST" | count_nonempty)"

# --- 4. SUID / SGID binaries ------------------------------------------------------
SUID_LIST="$(find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o -type f -perm -4000 -print 2>/dev/null)" || true
SUID_COUNT="$(printf '%s\n' "$SUID_LIST" | count_nonempty)"

SGID_LIST="$(find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o -type f -perm -2000 -print 2>/dev/null)" || true
SGID_COUNT="$(printf '%s\n' "$SGID_LIST" | count_nonempty)"

# --- 5. World-writable files ------------------------------------------------------
WORLD_WRITABLE_LIST="$(find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o -type f -perm -0002 -print 2>/dev/null)" || true
WORLD_WRITABLE_COUNT="$(printf '%s\n' "$WORLD_WRITABLE_LIST" | count_nonempty)"

# --- 6. Security-relevant sysctl parameters ---------------------------------------
SYSCTL_PARAMS=(
    net.ipv4.tcp_syncookies
    net.ipv4.ip_forward
    net.ipv4.conf.all.accept_redirects
    net.ipv4.conf.default.accept_redirects
    net.ipv4.conf.all.send_redirects
    net.ipv4.conf.all.accept_source_route
    net.ipv4.conf.all.rp_filter
    net.ipv4.icmp_echo_ignore_broadcasts
    net.ipv6.conf.all.accept_redirects
    net.ipv6.conf.all.forwarding
    kernel.randomize_va_space
    fs.suid_dumpable
    kernel.dmesg_restrict
    kernel.kptr_restrict
    kernel.yama.ptrace_scope
)
SYSCTL_KV=""
for p in "${SYSCTL_PARAMS[@]}"; do
    v="$(sysctl -n "$p" 2>/dev/null)" || v=""
    [ -z "$v" ] && v="unavailable"
    SYSCTL_KV="${SYSCTL_KV}${p}"$'\t'"${v}"$'\n'
done

# --- 7. SSH configuration ----------------------------------------------------------
SSHD_T_OUTPUT="$(sshd -T 2>/dev/null)" || SSHD_T_OUTPUT=""
ssh_param() {
    local name="$1" lc value
    lc="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
    if [ -n "$SSHD_T_OUTPUT" ]; then
        value="$(printf '%s\n' "$SSHD_T_OUTPUT" | awk -v k="$lc" 'tolower($1)==k {$1=""; sub(/^ /,""); print; exit}')" || value=""
    else
        value="$(grep -iE "^[[:space:]]*${name}[[:space:]]" /etc/ssh/sshd_config 2>/dev/null \
            | grep -v '^[[:space:]]*#' | awk '{$1=""; sub(/^ /,""); print; exit}')" || value=""
    fi
    printf '%s' "$value"
}
SSH_PARAMS=(PermitRootLogin PasswordAuthentication PermitEmptyPasswords PubkeyAuthentication
            X11Forwarding MaxAuthTries ClientAliveInterval ClientAliveCountMax LoginGraceTime
            AllowUsers Protocol)
SSH_KV=""
for p in "${SSH_PARAMS[@]}"; do
    v="$(ssh_param "$p")"
    [ -z "$v" ] && v="not set (default)"
    SSH_KV="${SSH_KV}${p}"$'\t'"${v}"$'\n'
done

# --- 8. User accounts and sudo membership -----------------------------------------
# Which accounts can log in and which of those can become root is the blast
# radius if any single credential is phished or brute-forced.
ACTIVE_USERS_LIST="$(awk -F: '$7 !~ /(nologin|false)$/ {print $1":"$3":"$7}' /etc/passwd)"
ACTIVE_USERS_COUNT="$(printf '%s\n' "$ACTIVE_USERS_LIST" | count_nonempty)"

SUDO_MEMBERS="$(getent group sudo 2>/dev/null | awk -F: '{print $4}' | tr ',' '\n')" || SUDO_MEMBERS=""
ADMIN_MEMBERS="$(getent group admin 2>/dev/null | awk -F: '{print $4}' | tr ',' '\n')" || ADMIN_MEMBERS=""
SUDO_GROUP_LIST="$(printf '%s\n%s\n' "$SUDO_MEMBERS" "$ADMIN_MEMBERS" | sed '/^$/d' | sort -u)"
SUDO_GROUP_COUNT="$(printf '%s\n' "$SUDO_GROUP_LIST" | count_nonempty)"

# --- Assemble JSON -----------------------------------------------------------------
{
    printf '{\n'
    printf '  "timestamp": "%s",\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)"
    printf '  "hostname": "%s",\n' "$(json_escape "$HOSTNAME_VAL")"
    printf '  "ran_as_root": %s,\n' "$IS_ROOT"
    printf '  "os": "%s",\n' "$(json_escape "$OS_PRETTY")"
    printf '  "kernel": "%s",\n' "$(json_escape "$KERNEL_VER")"
    printf '  "uptime_human": "%s",\n' "$(json_escape "$UPTIME_HUMAN")"
    printf '  "uptime_seconds": %s,\n' "${UPTIME_SECONDS:-0}"
    printf '  "services": {\n'
    printf '    "count": %d,\n' "$SERVICES_COUNT"
    printf '    "running": %s\n' "$(printf '%s\n' "$SERVICES_LIST" | array_from_lines)"
    printf '  },\n'
    printf '  "network": {\n'
    printf '    "open_ports_count": %d,\n' "$OPEN_PORTS_COUNT"
    printf '    "listening_sockets": %s\n' "$(printf '%s\n' "$SOCKETS_LIST" | array_from_lines)"
    printf '  },\n'
    printf '  "suid_binaries": {\n'
    printf '    "count": %d,\n' "$SUID_COUNT"
    printf '    "paths": %s\n' "$(printf '%s\n' "$SUID_LIST" | array_from_lines)"
    printf '  },\n'
    printf '  "sgid_binaries": {\n'
    printf '    "count": %d,\n' "$SGID_COUNT"
    printf '    "paths": %s\n' "$(printf '%s\n' "$SGID_LIST" | array_from_lines)"
    printf '  },\n'
    printf '  "world_writable_files": {\n'
    printf '    "count": %d,\n' "$WORLD_WRITABLE_COUNT"
    printf '    "paths": %s\n' "$(printf '%s\n' "$WORLD_WRITABLE_LIST" | array_from_lines)"
    printf '  },\n'
    printf '  "sysctl_security_params": %s,\n' "$(printf '%s' "$SYSCTL_KV" | object_from_kv_lines)"
    printf '  "ssh_config": %s,\n' "$(printf '%s' "$SSH_KV" | object_from_kv_lines)"
    printf '  "users": {\n'
    printf '    "active_accounts_count": %d,\n' "$ACTIVE_USERS_COUNT"
    printf '    "active_accounts": %s,\n' "$(printf '%s\n' "$ACTIVE_USERS_LIST" | array_from_lines)"
    printf '    "sudo_group_members_count": %d,\n' "$SUDO_GROUP_COUNT"
    printf '    "sudo_group_members": %s\n' "$(printf '%s\n' "$SUDO_GROUP_LIST" | array_from_lines)"
    printf '  }\n'
    printf '}\n'
} > "$OUTPUT_FILE"

# --- Human-readable summary (stdout) ------------------------------------------------
echo "Hostname: ${HOSTNAME_VAL}"
echo "OS: ${OS_PRETTY}"
echo "Running services: ${SERVICES_COUNT}"
echo "Open ports: ${OPEN_PORTS_COUNT}"
echo "SUID binaries: ${SUID_COUNT}"
echo "SGID binaries: ${SGID_COUNT}"
echo "World-writable files: ${WORLD_WRITABLE_COUNT}"
echo "Baseline JSON written to: ${OUTPUT_FILE}"
