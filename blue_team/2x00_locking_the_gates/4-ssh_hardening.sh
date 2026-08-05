#!/bin/bash
#
# 4-ssh_hardening.sh
#
# Hardens sshd_config to close the exact gap named in 1x02 Finding 009:
# "SSH on billing-srv-01 allows password-based authentication. Combined
# with no account lockout policy, this permits brute-force attacks." The
# Crimson Tide advisory confirmed that in 3 of 5 hospital breaches, the
# attacker used harvested credentials for SSH lateral movement (Phase 3).
#
# Safe by construction: the live config is backed up first, every change
# is validated with `sshd -t` before anything is restarted, and any
# validation failure restores the pre-change backup untouched.
#
# Usage: sudo ./4-ssh_hardening.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: this script must be run as root (sudo)." >&2
    exit 1
fi

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.bak"
BANNER="/etc/issue.net"

if ! command -v sshd >/dev/null 2>&1; then
    echo "Error: sshd not found - is openssh-server installed?" >&2
    exit 1
fi

if [[ ! -f "$SSHD_CONFIG" ]]; then
    echo "Error: $SSHD_CONFIG not found." >&2
    exit 1
fi

echo "[*] Backing up $SSHD_CONFIG"
cp -p "$SSHD_CONFIG" "$BACKUP"

# Replaces (or adds) a single directive, commented or not, so re-running
# this script stays idempotent instead of stacking duplicate lines.
set_directive() {
    local key="$1" value="$2" reason="$3"
    sed -i -E "/^[[:space:]]*#?[[:space:]]*${key}[[:space:]]/Id" "$SSHD_CONFIG"
    {
        echo ""
        echo "# $reason"
        echo "$key $value"
    } >> "$SSHD_CONFIG"
    echo "    $key $value"
}

echo "[*] Applying SSH hardening settings..."
set_directive "PermitRootLogin" "no" \
    "1x02 Finding 009 / Crimson Tide Phase 3 - blocks root-capable SSH lateral movement"
set_directive "PasswordAuthentication" "no" \
    "1x02 Finding 009 - password auth is what enables brute-force / harvested-credential login"
set_directive "PermitEmptyPasswords" "no" \
    "Removes the trivial no-credential login vector"
set_directive "X11Forwarding" "no" \
    "Reduces attack surface; X11 forwarding is not required for MedDefense operations"
set_directive "MaxAuthTries" "3" \
    "Limits brute-force authentication attempts per connection"
set_directive "ClientAliveInterval" "300" \
    "Idle timeout (10 min with ClientAliveCountMax 2) closes abandoned, hijackable sessions"
set_directive "ClientAliveCountMax" "2" \
    "Paired with ClientAliveInterval for a 10-minute idle timeout"
set_directive "AllowUsers" "medadmin sysadmin" \
    "Restricts SSH to explicitly authorized MedDefense operators only"
set_directive "Protocol" "2" \
    "Disables legacy SSHv1, which has known cryptographic weaknesses"
set_directive "LoginGraceTime" "60" \
    "Limits how long an unauthenticated connection can hold a slot open"
set_directive "Banner" "$BANNER" \
    "Displays the required legal notice before authentication"
SETTINGS_APPLIED=11

echo "[*] Creating $BANNER"
cat > "$BANNER" <<'EOF'
********************************************************************
* This system is the property of MedDefense. Unauthorized access   *
* or use is strictly prohibited and may be subject to civil and    *
* criminal penalties. All activity is monitored and logged.        *
********************************************************************
EOF

# Validates the config; if the only problem is an OpenSSH version that
# has dropped the legacy "Protocol" keyword, drop that one line and
# re-test once rather than discarding all 11 hardening settings over it.
validate_config() {
    local err
    err=$(mktemp)
    if sshd -t 2>"$err"; then
        echo "    sshd -t: OK"
        rm -f "$err"
        return 0
    fi

    if grep -qi "protocol" "$err"; then
        echo "    sshd -t: 'Protocol' directive unsupported on this OpenSSH version - removing and re-testing"
        sed -i -E '/^[[:space:]]*Protocol[[:space:]]/Id' "$SSHD_CONFIG"
        if sshd -t 2>"$err"; then
            echo "    sshd -t: OK"
            rm -f "$err"
            return 0
        fi
    fi

    echo "    sshd -t: FAILED"
    cat "$err" >&2
    rm -f "$err"
    return 1
}

echo "[*] Validating SSH configuration..."
if ! validate_config; then
    echo "[!] Restoring backup: $BACKUP -> $SSHD_CONFIG"
    cp -p "$BACKUP" "$SSHD_CONFIG"
    exit 1
fi

echo "[*] Restarting SSH service..."
SSH_SERVICE="ssh.service"
systemctl list-unit-files 2>/dev/null | grep -q '^sshd\.service' && SSH_SERVICE="sshd.service"

if systemctl restart "$SSH_SERVICE"; then
    STATE=$(systemctl is-active "$SSH_SERVICE")
    SUBSTATE=$(systemctl show -p SubState --value "$SSH_SERVICE")
    echo "    $SSH_SERVICE: $STATE ($SUBSTATE)"
else
    echo "[!] SSH restart failed - restoring backup: $BACKUP -> $SSHD_CONFIG" >&2
    cp -p "$BACKUP" "$SSHD_CONFIG"
    systemctl restart "$SSH_SERVICE" || true
    exit 1
fi

echo "Settings applied: $SETTINGS_APPLIED"
