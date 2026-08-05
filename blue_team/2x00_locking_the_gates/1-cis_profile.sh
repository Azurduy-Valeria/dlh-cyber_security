#!/bin/bash
#
# 1-cis_profile.sh
#
# Generates cis_profile.json: a focused, threat-driven CIS control profile
# for MedDefense's Linux fleet (billing-srv-01, web-srv-01, log-srv-01).
#
# Unlike a generic CIS benchmark dump, every control here is tied to a
# concrete risk from this project: SSH lateral movement, weak
# authentication, unnecessary services, missing audit visibility, exposed
# database services and insufficient kernel hardening. Later scripts
# (4-13) read this file as their source of truth for what to remediate
# and why.
#
# Usage: ./1-cis_profile.sh

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed." >&2
    exit 1
fi

OUTFILE="cis_profile.json"

# The profile is a static knowledge artifact (not live system state), so
# it is authored directly as JSON and then validated/summarized with jq.
CONTROLS_JSON=$(cat <<'EOF'
[
  {
    "control_id": "MD-CIS-01",
    "title": "Disable SSH root login and password authentication",
    "cis_section": "5 - Access, Authentication and Authorization",
    "severity": "critical",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "1x02 Finding 009 - SSH permits password authentication with no account lockout policy; Crimson Tide Phase 3 - in 3 of 5 hospital breaches the attacker used harvested credentials for SSH lateral movement",
    "implementation_task": "4-ssh_hardening.sh",
    "verification_method": "sshd -T | grep -Ei '^(permitrootlogin|passwordauthentication)' returns 'no' for both",
    "justification": "Password-based, root-capable SSH is the single highest-value credential-reuse target; disabling it removes the primary lateral-movement path used in the majority of documented breaches."
  },
  {
    "control_id": "MD-CIS-02",
    "title": "Harden SSH session controls: auth attempts, idle timeout, grace time, banner, user allow-list",
    "cis_section": "5 - Access, Authentication and Authorization",
    "severity": "high",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "1x02 Finding 009 companion control - unbounded auth attempts and stale sessions widen the same Phase 3 lateral-movement window",
    "implementation_task": "4-ssh_hardening.sh",
    "verification_method": "sshd -T | grep -Ei '^(maxauthtries|clientaliveinterval|clientalivecountmax|logingracetime|allowusers|banner)' matches hardened values",
    "justification": "Even with password auth disabled, unbounded auth attempts, indefinite idle sessions and an unrestricted user list needlessly widen the SSH attack surface."
  },
  {
    "control_id": "MD-CIS-03",
    "title": "Enforce account lockout and password history via PAM (pam_faillock)",
    "cis_section": "5 - Access, Authentication and Authorization",
    "severity": "critical",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "Crimson Tide Phase 2/3 - harvested credentials and Kerberoasting relied on the absence of lockout and password-history controls",
    "implementation_task": "8-pam_hardening.sh",
    "verification_method": "grep -E 'deny|unlock_time|fail_interval' pam_faillock config and 'remember' in /etc/pam.d/common-password",
    "justification": "No lockout policy is the exact gap the Crimson Tide advisory names as the reason harvested credentials stayed usable indefinitely; this is the direct root-cause fix."
  },
  {
    "control_id": "MD-CIS-04",
    "title": "Enforce password quality requirements (pwquality)",
    "cis_section": "5 - Access, Authentication and Authorization",
    "severity": "high",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "Weak/reused passwords enable the credential-harvesting stage (Phase 2) that precedes lateral movement",
    "implementation_task": "8-pam_hardening.sh",
    "verification_method": "grep -E 'minlen|dcredit|ucredit|lcredit|ocredit|reject_username' /etc/security/pwquality.conf",
    "justification": "Complements lockout enforcement: a 14-character complex minimum makes offline cracking of any harvested hash impractical within a realistic incident window."
  },
  {
    "control_id": "MD-CIS-05",
    "title": "Disable IP forwarding and enable anti-spoofing kernel parameters",
    "cis_section": "3 - Network Configuration and Firewalls",
    "severity": "critical",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "Crimson Tide Phase 3 - a compromised host with ip_forward enabled and ICMP redirects accepted becomes a router/pivot across a flat network",
    "implementation_task": "5-sysctl_hardening.sh",
    "verification_method": "sysctl net.ipv4.ip_forward net.ipv4.conf.all.accept_redirects net.ipv4.conf.all.rp_filter",
    "justification": "These are default-off settings that should never be enabled on a production server; leaving them on turns one compromised host into a network-wide pivot point."
  },
  {
    "control_id": "MD-CIS-06",
    "title": "Enable ASLR and kernel information-leak protections",
    "cis_section": "3 - Network Configuration and Firewalls",
    "severity": "high",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "Disabled ASLR makes memory-corruption exploits reliable; exposed kernel pointers/dmesg aid post-compromise exploit development",
    "implementation_task": "5-sysctl_hardening.sh",
    "verification_method": "sysctl kernel.randomize_va_space kernel.kptr_restrict kernel.dmesg_restrict fs.suid_dumpable",
    "justification": "These memory protections are free, default-available mitigations that raise the cost of exploiting any future memory-corruption bug."
  },
  {
    "control_id": "MD-CIS-07",
    "title": "Deploy default-deny host firewall, allow only required ports",
    "cis_section": "3 - Network Configuration and Firewalls",
    "severity": "high",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "1x02 Finding 006 - MySQL bound to 0.0.0.0; unrestricted network exposure of internal services",
    "implementation_task": "11-firewall_hardening.sh",
    "verification_method": "ufw status verbose (or iptables -L) confirms default deny incoming plus an explicit allow list",
    "justification": "A host firewall is the last line of defense when a service is misconfigured to listen on all interfaces; default-deny bounds the blast radius of any future misconfiguration."
  },
  {
    "control_id": "MD-CIS-08",
    "title": "Disable and remove unnecessary network-facing services",
    "cis_section": "2 - Services",
    "severity": "high",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "Baseline snapshot (Task 0) counted 24 enabled services; every extra listener is an additional entry point",
    "implementation_task": "7-service_minimization.sh",
    "verification_method": "systemctl list-units --type=service --state=running compared against the MedDefense whitelist",
    "justification": "A billing server has no legitimate need for avahi-daemon, cups, rpcbind, ModemManager or bluetooth; each is attack surface with no operational upside."
  },
  {
    "control_id": "MD-CIS-09",
    "title": "Restrict the database service to localhost/authorized subnet only",
    "cis_section": "2 - Services",
    "severity": "critical",
    "asset_scope": ["billing-srv-01"],
    "threat_mapping": "1x02 Finding 006 - MySQL on billing-srv-01 exposed on 0.0.0.0:3306 with no network restriction",
    "implementation_task": "7-service_minimization.sh",
    "verification_method": "ss -tulpen | grep 3306 shows a bind address of 127.0.0.1 or the internal management subnet only",
    "justification": "A database engine reachable from any interface is a direct path to billing/patient data; binding to loopback or a management VLAN removes that exposure entirely."
  },
  {
    "control_id": "MD-CIS-10",
    "title": "Remove SUID/SGID bits from non-whitelisted binaries",
    "cis_section": "6 - System Maintenance",
    "severity": "high",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "Crimson Tide Phase 3 - SUID binaries are the standard low-privilege-to-root escalation path after initial access",
    "implementation_task": "6-filesystem_hardening.sh",
    "verification_method": "find / -perm -4000 -o -perm -2000, diffed against the Ubuntu 22.04 whitelist, shows zero unexpected entries",
    "justification": "Baseline (Task 0) found dozens of SUID/SGID binaries; every one not on the known-safe whitelist is unreviewed privilege-escalation surface."
  },
  {
    "control_id": "MD-CIS-11",
    "title": "Remediate world-writable files and enforce noexec,nosuid,nodev on /tmp, /var/tmp, /dev/shm",
    "cis_section": "6 - System Maintenance",
    "severity": "medium",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "World-writable files let an attacker with low-privilege access modify scripts that later run as root",
    "implementation_task": "6-filesystem_hardening.sh",
    "verification_method": "find / -perm -0002 -type f returns none outside expected paths; mount output shows noexec,nosuid,nodev on the three mounts",
    "justification": "Combined with restrictive mount options, this closes the classic writable-and-executable temp directory privilege-escalation and persistence vector."
  },
  {
    "control_id": "MD-CIS-12",
    "title": "Enforce AppArmor mandatory access control on network-exposed services",
    "cis_section": "6 - System Maintenance",
    "severity": "high",
    "asset_scope": ["billing-srv-01", "web-srv-01"],
    "threat_mapping": "1x00 incident - the crypto-miner that compromised billing-srv-01 via Apache had unrestricted filesystem access as www-data",
    "implementation_task": "9-apparmor_config.sh",
    "verification_method": "aa-status shows the apache2 and mysqld profiles loaded in enforce mode, plus the custom MedDefense billing-app profile",
    "justification": "Mandatory access control is the difference between a compromised web process and a compromised server; it directly addresses the failure mode from the 1x00 incident."
  },
  {
    "control_id": "MD-CIS-13",
    "title": "Deploy auditd rules for identity, privilege escalation and suspicious tool execution",
    "cis_section": "4 - Logging and Auditing",
    "severity": "critical",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "1x00 incident notes - no SIEM or IDS was deployed, and the attacker moved undetected for 5 days",
    "implementation_task": "10-auditd_config.sh",
    "verification_method": "auditctl -l lists the identity/priv_esc/suspicious_download rules; ausearch -k identity returns events on a test access",
    "justification": "This is the single biggest gap from the 1x00 incident; without kernel-level audit visibility, none of the later SOC/telemetry work in Module 3 has data to analyze."
  },
  {
    "control_id": "MD-CIS-14",
    "title": "Configure retention and rotation for security-relevant logs",
    "cis_section": "4 - Logging and Auditing",
    "severity": "medium",
    "asset_scope": ["log-srv-01"],
    "threat_mapping": "The undetected 5-day dwell time (1x00) is compounded if logs are not guaranteed to still exist during incident response",
    "implementation_task": "12-log_retention.sh",
    "verification_method": "logrotate -d against the deployed configs confirms retention of at least 90 days for auth, audit and application logs",
    "justification": "Audit rules only matter if the resulting logs survive long enough to be reviewed; retention policy is what makes the audit trail useful during a real investigation."
  },
  {
    "control_id": "MD-CIS-15",
    "title": "Continuous CIS compliance validation for MedDefense-specific controls",
    "cis_section": "4 - Logging and Auditing",
    "severity": "medium",
    "asset_scope": ["billing-srv-01", "web-srv-01", "log-srv-01"],
    "threat_mapping": "Generic scanners (including Lynis) do not know about MedDefense-internal applications or asset-specific policy, so drift here is invisible to standard tooling",
    "implementation_task": "13-compliance_validation.sh",
    "verification_method": "Manual review: re-run this control profile against the live system periodically and diff against the previous gap_analysis.json",
    "justification": "Intentionally left for manual/periodic validation rather than tool-based verification - no automated scanner covers MedDefense's custom controls, so Task 3 is expected to flag this one not_assessed."
  }
]
EOF
)

echo "$CONTROLS_JSON" | jq '.' > "$OUTFILE"

# Self-verify: every printed number below is computed from the file just
# written, not hardcoded, so the summary always matches cis_profile.json.
TOTAL=$(jq 'length' "$OUTFILE")
CRITICAL=$(jq '[.[] | select(.severity == "critical")] | length' "$OUTFILE")
HIGH=$(jq '[.[] | select(.severity == "high")] | length' "$OUTFILE")
MEDIUM=$(jq '[.[] | select(.severity == "medium")] | length' "$OUTFILE")
SECTIONS=$(jq '[.[].cis_section] | unique | length' "$OUTFILE")
TASKS=$(jq '[.[].implementation_task] | unique | length' "$OUTFILE")

echo "Controls selected: $TOTAL"
echo "Critical: $CRITICAL"
echo "High: $HIGH"
echo "Medium: $MEDIUM"
echo "CIS sections covered: $SECTIONS"
echo "Mapped implementation tasks: $TASKS"
echo "Report saved to: $OUTFILE"
