#!/bin/bash
#
# 10-auditd_config.sh
#
# Marcus Webb's notes from the 1x00 incident: "No SIEM or IDS was
# deployed. Attacker moved undetected for 5 days." auditd is the Linux
# kernel audit framework - it records syscalls, file access and
# authentication events at the kernel level. The rules deployed here
# become the primary Linux data source for the analyst work in Module 3,
# so they determine what the SOC can actually see.
#
# Usage: sudo ./10-auditd_config.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: this script must be run as root (sudo)." >&2
    exit 1
fi

echo "[*] Enabling auditd service..."
if ! dpkg -s auditd >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y auditd
fi
systemctl enable --now auditd >/dev/null 2>&1 || true
STATE=$(systemctl is-active auditd 2>/dev/null || echo "inactive")
SUBSTATE=$(systemctl show -p SubState --value auditd 2>/dev/null || echo "dead")
echo "    auditd.service: $STATE ($SUBSTATE)"

RULES_FILE="/etc/audit/rules.d/meddefense.rules"
mkdir -p "$(dirname "$RULES_FILE")"

# identity files, privilege escalation, suspicious tool execution and
# MedDefense-specific file integrity, in that order.
RULES=(
    "-w /etc/passwd -p wa -k identity"
    "-w /etc/shadow -p wa -k identity"
    "-w /etc/group -p wa -k identity"
    "-w /etc/pam.d/ -p wa -k pam_config"
    "-w /etc/ssh/sshd_config -p wa -k sshd_config"
    "-w /usr/bin/sudo -p x -k priv_esc"
    "-w /usr/bin/su -p x -k priv_esc"
    "-w /etc/sudoers -p wa -k sudoers"
    "-w /usr/bin/wget -p x -k suspicious_download"
    "-w /usr/bin/curl -p x -k suspicious_download"
    "-w /usr/bin/nc -p x -k suspicious_netcat"
    "-w /var/lib/mysql/ -p wa -k meddefense_db"
    "-w /etc/apache2/ -p wa -k meddefense_web"
    "-w /etc/init.d/ -p wa -k startup_scripts"
)

echo "[*] Deploying MedDefense audit rules..."
: > "$RULES_FILE"
for rule in "${RULES[@]}"; do
    echo "$rule" >> "$RULES_FILE"
    printf "    %-46s[ADDED]\n" "$rule"
done
chmod 640 "$RULES_FILE"

echo "[*] Loading rules..."
LOAD_OUT=$(mktemp)
if augenrules --load >"$LOAD_OUT" 2>&1; then
    echo "    augenrules --load: OK"
else
    echo "    augenrules --load: FAILED"
    cat "$LOAD_OUT" >&2
fi
rm -f "$LOAD_OUT"

LOADED=$(auditctl -l 2>/dev/null | wc -l)
echo "[*] Verifying..."
echo "    auditctl -l: $LOADED rules loaded"

echo "[*] Test: reading /etc/shadow..."
cat /etc/shadow >/dev/null 2>&1 || true
sleep 1
EVENTS=$(ausearch -i -ts recent -k identity 2>/dev/null | grep -c '^time->' || true)
if [[ "$EVENTS" -gt 0 ]]; then
    echo "    ausearch -ts recent -k identity: $EVENTS event(s) found [PASS]"
else
    echo "    ausearch -ts recent -k identity: 0 events found [FAIL]"
fi
