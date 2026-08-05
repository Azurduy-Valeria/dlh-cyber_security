#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must be run as root (use: sudo ./0-baseline_snapshot.sh)" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/results"
mkdir -p "$RESULTS_DIR"

HOSTNAME_VAL="$(hostname)"
OUTPUT_FILE="${RESULTS_DIR}/baseline_snapshot_${HOSTNAME_VAL}.json"


json_escape() {
    # Escapes backslashes, double quotes and control characters for safe
    # embedding of arbitrary filesystem/process strings inside a JSON string
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

# 1. System identification 
OS_PRETTY="$(grep -oP '(?<=^PRETTY_NAME=).*' /etc/os-release 2>/dev/null | tr -d '"')"
[ -z "$OS_PRETTY" ] && OS_PRETTY="unknown"
KERNEL_VER="$(uname -r)"
UPTIME_HUMAN="$(uptime -p 2>/dev/null)"
UPTIME_SECONDS="$(awk '{print int($1)}' /proc/uptime 2>/dev/null)"


# 2. Running services 
SERVICES_LIST="$(systemctl list-units --type=service --state=running --no-legend --plain 2>/dev/null | awk '{print $1}')"
SERVICES_COUNT="$(printf '%s\n' "$SERVICES_LIST" | grep -c .)"
[ -z "$SERVICES_LIST" ] && SERVICES_COUNT=0

# 3. Open ports / listening sockets
SOCKETS_LIST="$(ss -Htulnp 2>/dev/null)"
OPEN_PORTS_COUNT="$(printf '%s\n' "$SOCKETS_LIST" | grep -c .)"
[ -z "$SOCKETS_LIST" ] && OPEN_PORTS_COUNT=0

# 4. SUID / SGID binaries 
SUID_LIST="$(find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o -type f -perm -4000 -print 2>/dev/null)"
SUID_COUNT="$(printf '%s\n' "$SUID_LIST" | grep -c .)"
[ -z "$SUID_LIST" ] && SUID_COUNT=0

SGID_LIST="$(find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o -type f -perm -2000 -print 2>/dev/null)"
SGID_COUNT="$(printf '%s\n' "$SGID_LIST" | grep -c .)"
[ -z "$SGID_LIST" ] && SGID_COUNT=0

# 5. World-writable files
WORLD_WRITABLE_LIST="$(find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o -type f -perm -0002 -print 2>/dev/null)"
WORLD_WRITABLE_COUNT="$(printf '%s\n' "$WORLD_WRITABLE_LIST" | grep -c .)"
[ -z "$WORLD_WRITABLE_LIST" ] && WORLD_WRITABLE_COUNT=0

#  6. Security-relevant sysctl parameters
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
    v="$(sysctl -n "$p" 2>/dev/null)"
    [ -z "$v" ] && v="unavailable"
    SYSCTL_KV="${SYSCTL_KV}${p}"$'\t'"${v}"$'\n'
done

# 7. SSH configuration 
# Direct baseline for Finding 009 (SSH password authentication enabled).
# Prefer sshd's own effective configuration (-T) over the raw file since it
# reflects included files and compiled-in defaults; fall back to the raw
# config file if sshd is not installed or the config does not yet validate.
SSHD_T_OUTPUT="$(sshd -T 2>/dev/null)"
ssh_param() {
    local name="$1" lc
    lc="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
    if [ -n "$SSHD_T_OUTPUT" ]; then
        printf '%s\n' "$SSHD_T_OUTPUT" | awk -v k="$lc" 'tolower($1)==k {$1=""; sub(/^ /,""); print; exit}'
    else
        grep -iE "^[[:space:]]*${name}[[:space:]]" /etc/ssh/sshd_config 2>/dev/null \
            | grep -v '^[[:space:]]*#' | awk '{$1=""; sub(/^ /,""); print; exit}'
    fi
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

# 8. User accounts and sudo membership 
ACTIVE_USERS_LIST="$(awk -F: '$7 !~ /(nologin|false)$/ {print $1":"$3":"$7}' /etc/passwd)"
ACTIVE_USERS_COUNT="$(printf '%s\n' "$ACTIVE_USERS_LIST" | grep -c .)"
[ -z "$ACTIVE_USERS_LIST" ] && ACTIVE_USERS_COUNT=0

SUDO_MEMBERS="$(getent group sudo 2>/dev/null | awk -F: '{print $4}' | tr ',' '\n')"
ADMIN_MEMBERS="$(getent group admin 2>/dev/null | awk -F: '{print $4}' | tr ',' '\n')"
SUDO_GROUP_LIST="$(printf '%s\n%s\n' "$SUDO_MEMBERS" "$ADMIN_MEMBERS" | sed '/^$/d' | sort -u)"
SUDO_GROUP_COUNT="$(printf '%s\n' "$SUDO_GROUP_LIST" | grep -c .)"
[ -z "$SUDO_GROUP_LIST" ] && SUDO_GROUP_COUNT=0

#  JSON 
{
    printf '{\n'
    printf '  "timestamp": "%s",\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)"
    printf '  "hostname": "%s",\n' "$(json_escape "$HOSTNAME_VAL")"
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

#  Human-readable summary (stdout) 
echo "Hostname: ${HOSTNAME_VAL}"
echo "OS: ${OS_PRETTY}"
echo "Running services: ${SERVICES_COUNT}"
echo "Open ports: ${OPEN_PORTS_COUNT}"
echo "SUID binaries: ${SUID_COUNT}"
echo "SGID binaries: ${SGID_COUNT}"
echo "World-writable files: ${WORLD_WRITABLE_COUNT}"
echo "Baseline JSON written to: ${OUTPUT_FILE}"
