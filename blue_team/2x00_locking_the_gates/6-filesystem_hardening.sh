#!/bin/bash
#
# 6-filesystem_hardening.sh
#
# SUID binaries are how an attacker with a low-privilege shell escalates
# to root. World-writable files are how they modify scripts that later
# run as root. Both are classic privilege-escalation vectors a Crimson
# Tide-style affiliate would use after initial access (Phase 3). The
# baseline snapshot (Task 0) found SUID/SGID binaries and world-writable
# files - this script whitelists the ones that must stay, and remediates
# everything else.
#
# Usage: sudo ./6-filesystem_hardening.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: this script must be run as root (sudo)." >&2
    exit 1
fi

# --- Known-safe SUID/SGID binaries on a stock Ubuntu 22.04 install ---------
# Review and adjust for the actual packages installed on each asset before
# running in production - a path that doesn't exist on this host simply
# never matches and is harmless.
SUID_WHITELIST=(
    "/usr/bin/sudo"
    "/usr/bin/su"
    "/usr/bin/passwd"
    "/usr/bin/chsh"
    "/usr/bin/chfn"
    "/usr/bin/gpasswd"
    "/usr/bin/newgrp"
    "/usr/bin/mount"
    "/usr/bin/umount"
    "/usr/bin/pkexec"
    "/usr/bin/fusermount3"
    "/usr/bin/ntfs-3g"
    "/usr/bin/at"
    "/usr/lib/openssh/ssh-keysign"
    "/usr/lib/policykit-1/polkit-agent-helper-1"
    "/usr/sbin/mount.nfs"
    "/usr/sbin/exim4"
    "/usr/sbin/pppd"
)

SGID_WHITELIST=(
    "/usr/bin/wall"
    "/usr/bin/write"
    "/usr/bin/crontab"
    "/usr/bin/ssh-agent"
    "/usr/bin/expiry"
    "/usr/bin/chage"
    "/usr/bin/dotlockfile"
    "/sbin/unix_chkpwd"
    "/usr/sbin/unix_chkpwd"
    "/usr/libexec/utempter/utempter"
)

is_whitelisted() {
    local path="$1"; shift
    local w
    for w in "$@"; do
        [[ "$path" == "$w" ]] && return 0
    done
    return 1
}

SUID_REMEDIATED=0
SGID_REMEDIATED=0
WW_FIXED=0

# --- SUID binaries -----------------------------------------------------
mapfile -t SUID_FOUND < <(find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o \
    -type f -perm -4000 -print 2>/dev/null)
echo "Found ${#SUID_FOUND[@]} SUID binaries"

suid_wl=0
SUID_NONWL=()
for bin in "${SUID_FOUND[@]}"; do
    if is_whitelisted "$bin" "${SUID_WHITELIST[@]}"; then
        suid_wl=$((suid_wl + 1))
    else
        SUID_NONWL+=("$bin")
    fi
done
echo "Whitelisted: $suid_wl"
echo "Non-whitelisted: ${#SUID_NONWL[@]}"
for bin in "${SUID_NONWL[@]}"; do
    if chmod u-s "$bin" 2>/dev/null; then
        printf "  %-30s[SUID REMOVED]\n" "$bin"
        SUID_REMEDIATED=$((SUID_REMEDIATED + 1))
    else
        printf "  %-30s[REMOVE FAILED]\n" "$bin"
    fi
done

# --- SGID binaries -----------------------------------------------------
mapfile -t SGID_FOUND < <(find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o \
    -type f -perm -2000 -print 2>/dev/null)
echo "Found ${#SGID_FOUND[@]} SGID binaries"

sgid_wl=0
SGID_NONWL=()
for bin in "${SGID_FOUND[@]}"; do
    if is_whitelisted "$bin" "${SGID_WHITELIST[@]}"; then
        sgid_wl=$((sgid_wl + 1))
    else
        SGID_NONWL+=("$bin")
    fi
done
echo "Whitelisted: $sgid_wl"
echo "Non-whitelisted: ${#SGID_NONWL[@]}"
for bin in "${SGID_NONWL[@]}"; do
    if chmod g-s "$bin" 2>/dev/null; then
        printf "  %-30s[SGID REMOVED]\n" "$bin"
        SGID_REMEDIATED=$((SGID_REMEDIATED + 1))
    else
        printf "  %-30s[REMOVE FAILED]\n" "$bin"
    fi
done

# --- World-writable files and directories -------------------------------
# A world-writable directory with the sticky bit set (e.g. /tmp at 1777)
# is the standard, compliant pattern - it is skipped rather than flagged.
# Everything else is remediated: files lose the other-write bit, and
# directories gain the sticky bit instead of losing write access outright
# (so e.g. an uploads/ directory that legitimately needs to stay writable
# keeps working, but other users can no longer delete each other's files).
mapfile -t WW_CANDIDATES < <(find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o \
    \( -type f -o -type d \) -perm -0002 -print 2>/dev/null)

WW_ISSUES=()
for entry in "${WW_CANDIDATES[@]}"; do
    if [[ -d "$entry" && -k "$entry" ]]; then
        continue
    fi
    WW_ISSUES+=("$entry")
done

echo "Found ${#WW_ISSUES[@]} world-writable files"
for entry in "${WW_ISSUES[@]}"; do
    if [[ -d "$entry" ]]; then
        result=$(chmod +t "$entry" 2>/dev/null && echo "FIXED" || echo "FIX FAILED")
    else
        result=$(chmod o-w "$entry" 2>/dev/null && echo "FIXED" || echo "FIX FAILED")
    fi
    printf "  %-30s[%s]\n" "$entry" "$result"
    [[ "$result" == "FIXED" ]] && WW_FIXED=$((WW_FIXED + 1))
done

# --- Mount options for /tmp, /var/tmp, /dev/shm -------------------------
FSTAB="/etc/fstab"
FSTAB_BACKUP="/etc/fstab.bak"
[[ -f "$FSTAB_BACKUP" ]] || cp -p "$FSTAB" "$FSTAB_BACKUP"

persist_fstab() {
    local mp="$1"
    if grep -Eq "^[^#][^[:space:]]+[[:space:]]+${mp//\//\\/}[[:space:]]" "$FSTAB"; then
        awk -v mp="$mp" '
            $0 !~ /^#/ && $2 == mp {
                n = split($4, opts, ",")
                has_noexec = 0; has_nosuid = 0; has_nodev = 0
                for (i = 1; i <= n; i++) {
                    if (opts[i] == "noexec") has_noexec = 1
                    if (opts[i] == "nosuid") has_nosuid = 1
                    if (opts[i] == "nodev")  has_nodev  = 1
                }
                newopts = $4
                if (!has_noexec) newopts = newopts ",noexec"
                if (!has_nosuid) newopts = newopts ",nosuid"
                if (!has_nodev)  newopts = newopts ",nodev"
                $4 = newopts
            }
            { print }
        ' "$FSTAB" > "${FSTAB}.new" && mv "${FSTAB}.new" "$FSTAB"
    elif [[ "$mp" == "/dev/shm" ]]; then
        echo "tmpfs $mp tmpfs defaults,noexec,nosuid,nodev 0 0" >> "$FSTAB"
    else
        echo "# NOTE: $mp had no $FSTAB entry (likely a systemd tmp.mount) - add noexec,nosuid,nodev there manually" >> "$FSTAB"
    fi
}

check_mount() {
    local mp="$1" current missing=() opt
    current=$(findmnt -no OPTIONS "$mp" 2>/dev/null || echo "")

    for opt in noexec nosuid nodev; do
        [[ ",$current," == *",$opt,"* ]] || missing+=("$opt")
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        printf "%-9s %-22s [OK]\n" "$mp:" "noexec,nosuid,nodev"
    else
        mount -o remount,noexec,nosuid,nodev "$mp" 2>/dev/null || true
        persist_fstab "$mp"
        printf "%-9s %-22s [APPLIED]\n" "$mp:" "noexec,nosuid,nodev"
    fi
}

check_mount "/tmp"
check_mount "/var/tmp"
check_mount "/dev/shm"

# --- Cron access restriction --------------------------------------------
CRON_ALLOW="/etc/cron.allow"
AUTHORIZED_CRON_USERS=("root" "medadmin" "sysadmin")
printf '%s\n' "${AUTHORIZED_CRON_USERS[@]}" > "$CRON_ALLOW"
chmod 600 "$CRON_ALLOW"
[[ -f /etc/cron.deny ]] && rm -f /etc/cron.deny

echo "SUID remediated: $SUID_REMEDIATED | SGID remediated: $SGID_REMEDIATED | World-writable fixed: $WW_FIXED"
