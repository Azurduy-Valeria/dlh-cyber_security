#!/bin/bash
#
# 8-pam_hardening.sh
#
# The Crimson Tide advisory documented that in 3 of 5 breaches, the
# attacker used harvested credentials (Phase 2) and Kerberoasting (Phase
# 3) to move laterally. Weak passwords are the root cause, and PAM is
# where Linux enforces password policy. MedDefense currently has no
# password complexity requirement, no account lockout and no password
# history enforcement on its Linux servers - this script sets all three.
#
# Usage: sudo ./8-pam_hardening.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: this script must be run as root (sudo)." >&2
    exit 1
fi

PWQUALITY_CONF="/etc/security/pwquality.conf"
FAILLOCK_CONF="/etc/security/faillock.conf"
COMMON_AUTH="/etc/pam.d/common-auth"
COMMON_ACCOUNT="/etc/pam.d/common-account"
COMMON_PASSWORD="/etc/pam.d/common-password"

for f in "$COMMON_AUTH" "$COMMON_ACCOUNT" "$COMMON_PASSWORD"; do
    if [[ -f "$f" && ! -f "${f}.bak" ]]; then
        cp -p "$f" "${f}.bak"
    fi
done

echo "[*] Checking libpam-pwquality..."
if dpkg -s libpam-pwquality >/dev/null 2>&1; then
    VERSION=$(dpkg-query -W -f='${Version}' libpam-pwquality)
    echo "    Already installed: libpam-pwquality $VERSION"
else
    echo "    Not found - installing..."
    apt-get update -qq
    apt-get install -y libpam-pwquality
    VERSION=$(dpkg-query -W -f='${Version}' libpam-pwquality)
    echo "    Installed: libpam-pwquality $VERSION"
fi

[[ -f "$PWQUALITY_CONF" ]] || touch "$PWQUALITY_CONF"
[[ -f "$FAILLOCK_CONF" ]] || touch "$FAILLOCK_CONF"

# Replaces (or adds) a "key = value" line, commented or not.
set_kv() {
    local file="$1" key="$2" value="$3"
    if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
        sed -i -E "s|^[[:space:]]*${key}[[:space:]]*=.*|${key} = ${value}|" "$file"
    else
        sed -i -E "/^[[:space:]]*#[[:space:]]*${key}[[:space:]]*=/d" "$file"
        echo "${key} = ${value}" >> "$file"
    fi
    printf "    %-33s[SET]\n" "$key = $value"
}

# Replaces (or adds) a bare boolean directive, e.g. "reject_username".
set_flag() {
    local file="$1" key="$2"
    if ! grep -qxE "[[:space:]]*${key}[[:space:]]*" "$file"; then
        sed -i -E "/^[[:space:]]*#[[:space:]]*${key}[[:space:]]*\$/d" "$file"
        echo "$key" >> "$file"
    fi
    printf "    %-33s[SET]\n" "$key"
}

echo "[*] Configuring password quality ($PWQUALITY_CONF)..."
set_kv "$PWQUALITY_CONF" "minlen" "14"
set_kv "$PWQUALITY_CONF" "dcredit" "-1"
set_kv "$PWQUALITY_CONF" "ucredit" "-1"
set_kv "$PWQUALITY_CONF" "lcredit" "-1"
set_kv "$PWQUALITY_CONF" "ocredit" "-1"
set_kv "$PWQUALITY_CONF" "maxrepeat" "3"
set_flag "$PWQUALITY_CONF" "reject_username"

echo "[*] Configuring account lockout (pam_faillock)..."
set_kv "$FAILLOCK_CONF" "deny" "5"
set_kv "$FAILLOCK_CONF" "unlock_time" "900"
set_kv "$FAILLOCK_CONF" "fail_interval" "900"

# Wire pam_faillock into the auth/account stacks if it isn't already there.
# Idempotent - skipped entirely on a re-run once pam_faillock is present,
# so this never duplicates or reorders lines on repeated executions.
if [[ -f "$COMMON_AUTH" ]] && ! grep -q "pam_faillock.so" "$COMMON_AUTH"; then
    sed -i "/pam_unix\.so/i auth\trequired\t\t\tpam_faillock.so preauth" "$COMMON_AUTH"
    sed -i "/pam_unix\.so/a auth\t[default=die]\t\tpam_faillock.so authfail" "$COMMON_AUTH"
fi
if [[ -f "$COMMON_ACCOUNT" ]] && ! grep -q "pam_faillock.so" "$COMMON_ACCOUNT"; then
    sed -i "/pam_unix\.so/a account\trequired\t\tpam_faillock.so" "$COMMON_ACCOUNT"
fi

echo "[*] Configuring password history..."
if [[ -f "$COMMON_PASSWORD" ]]; then
    if grep -q "remember=" "$COMMON_PASSWORD"; then
        sed -i -E "s/remember=[0-9]+/remember=12/" "$COMMON_PASSWORD"
    else
        sed -i -E "/pam_unix\.so/ s/\$/ remember=12/" "$COMMON_PASSWORD"
    fi
fi
printf "    %-33s[SET]\n" "remember = 12"

echo "Password minimum length: 14 | Lockout: 5 attempts / 15 min | History: 12"
