# The Gap-to-Framework Bridge

*(Note: 1x01 doesn't exist as a project folder in this repo, so "Threat Context" below uses the same small threat-actor/kill-chain model built in 1x02 — TA-1 Ransomware affiliate, TA-2 Opportunistic/worm attacker — rather than citing a file that isn't there.)*

## Gap 1

Gap Reference: G-006 (1x00) — no compensating control for the flat network
Description: `10.10.0.0/16` has zero segmentation; any compromised host can reach any other asset.
Vulnerability Evidence: Findings 001, 003, 004, 007, 015, 016 (1x02)
Threat Context: TA-1 Ransomware affiliate — Kill Chain "Financial Server to Domain Takeover"
NIST CSF Function: Protect
CIS Control: 12 — Network Infrastructure Management
Recommended Action: Design and implement VLANs separating servers, workstations, medical devices, and guest Wi-Fi.

## Gap 2

Gap Reference: Derived from 1x02 Finding 007 + control gap analysis
Description: MFA exists on exactly one personal account in the entire organization.
Vulnerability Evidence: Finding 007 (LDAP relay), Finding 009 (SSH password auth)
Threat Context: TA-1 Ransomware affiliate — credential-based lateral movement
NIST CSF Function: Protect
CIS Control: 6 — Access Control Management
Recommended Action: Enforce MFA on VPN and all administrative accounts using existing O365 E3 licenses.

## Gap 3

Gap Reference: G-004 (1x00) — no antivirus/EDR coverage on servers
Description: Windows workstations have Sophos; every Linux and Windows server has zero malware defense.
Vulnerability Evidence: Findings 001/002 (billing-srv-01 RCE chain); prior cryptominer incident
Threat Context: TA-2 Opportunistic/commodity attacker
NIST CSF Function: Protect / Detect
CIS Control: 10 — Malware Defenses
Recommended Action: Deploy EDR to all servers, prioritizing the Linux fleet first.

## Gap 4

Gap Reference: G-001 (1x00) — no centralized logging or alerting
Description: Logs exist per-host; nothing is centralized, correlated, or alerted on.
Vulnerability Evidence: The 2-week undetected cryptominer run is itself the evidence
Threat Context: Applies equally to any actor — this is a universal detection gap
NIST CSF Function: Detect
CIS Control: 8 — Audit Log Management (and 13 — Network Monitoring and Defense)
Recommended Action: Deploy a SIEM (e.g., Wazuh) with basic correlation rules and alerting.

## Gap 5

Gap Reference: Flaw in Control C-010 (1x00) — backup has no offsite copy
Description: The sole backup copy sits in the same rack as production, untested for full recovery.
Vulnerability Evidence: Finding 015 (NAS-01 DSM exposed network-wide)
Threat Context: TA-1 Ransomware affiliate — Kill Chain "Backup Destruction Endgame"
NIST CSF Function: Recover
CIS Control: 11 — Data Recovery
Recommended Action: Replicate backups to an offsite, immutable cloud target.

## Gap 6

Gap Reference: G-003 (1x00) — no formal incident response plan
Description: The January incident was handled by four days of ad hoc improvisation, with no documented plan.
Vulnerability Evidence: N/A (organizational/process gap, not a scan finding)
Threat Context: Applies to any actor — response speed determines damage regardless of entry vector
NIST CSF Function: Respond
CIS Control: 17 — Incident Response Management
Recommended Action: Write and test a basic incident response plan with named roles and an escalation path.

## Gap 7

Gap Reference: G-006 (1x00), medical-device half — no compensating control for unpatchable devices
Description: The MRI workstation and medical IoT devices can never be patched and have no isolation or hardening.
Vulnerability Evidence: Finding 004 (Windows XP MRI), Finding 010 (BD Alaris default credentials), Finding 016 (Philips monitors)
Threat Context: TA-2 Opportunistic worm (Finding 004); extortion-leverage actor (Findings 010/016)
NIST CSF Function: Protect
CIS Control: 12 (segmentation, dependent on Gap 1) + 4 — Secure Configuration (default credentials)
Recommended Action: Isolate medical devices on a dedicated VLAN and change every default credential.

## Gap 8

Gap Reference: 1x00 Known Unknowns — "no formal vulnerability assessment has ever been done"
Description: The 1x02 scan was the first vulnerability assessment MedDefense has ever performed.
Vulnerability Evidence: The entire 1x02 project is the evidence; specifically Findings 011/026 (unpatched, unenrolled EOL system)
Threat Context: Applies to any actor — stale patching is a universal enabler
NIST CSF Function: Identify / Protect
CIS Control: 7 — Continuous Vulnerability Management
Recommended Action: Establish a recurring (monthly) scan-and-remediate cycle instead of one-time assessments.

---

## Traceability Summary Table

| Gap | Vulnerability | Threat | CSF Function | CIS Control | Action |
|---|---|---|---|---|---|
| G-006 flat network | 001,003,004,007,015,016 | TA-1, KC-2/KC-4 | Protect | 12 | Segment the network |
| No MFA | 007, 009 | TA-1 | Protect | 6 | Enforce MFA (VPN + admin) |
| G-004 no server AV | 001/002 | TA-2 | Protect/Detect | 10 | Deploy EDR to servers |
| G-001 no logging | (cryptominer incident) | Any | Detect | 8, 13 | Deploy SIEM |
| Backup not offsite | 015 | TA-1, KC-4 | Recover | 11 | Offsite backup replication |
| No IR plan | G-003 | Any | Respond | 17 | Write/test IR plan |
| No medical IoT control | 004, 010, 016 | TA-2 / extortion actor | Protect | 12, 4 | Isolate + change default creds |
| No vuln mgmt process | Entire 1x02 project | Any | Identify/Protect | 7 | Recurring scan cadence |
