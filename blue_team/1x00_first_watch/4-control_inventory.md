# Control Landscape: Existing Security Control Inventory

Control ID: C-001

Control Name: Default-Deny Firewall Policy

Description: The FortiGate's final policy rule ("Deny-All", rule 5) matches any source/destination/interface not already permitted by an earlier rule and drops it, with logging enabled. This establishes a fail-closed posture at the network perimeter rather than a fail-open one.

Category: Technical

Function: Preventive

Asset(s) Protected: Internal network and server subnet (blocks unsolicited/unmatched inbound and cross-zone traffic)

Source: Artifact 1 — Firewall Configuration Extract (policy rule 5, "Deny-All")

---

Control ID: C-002

Control Name: DMZ Web Server Isolation Rule

Description: Policy rule 1 ("Allow-Web-Inbound") permits HTTP/HTTPS from the internet only to `web-srv-01` in the DMZ interface, rather than opening inbound access to the internal server subnet directly. This confines the organization's public-facing attack surface to a single, isolated host.

Category: Technical

Function: Preventive

Asset(s) Protected: Internal server subnet (EHR, billing, AD, file, PACS servers — shielded from direct internet exposure)

Source: Artifact 1 — Firewall Configuration Extract (policy rule 1, "Allow-Web-Inbound")

---

Control ID: C-003

Control Name: Site-to-Site VPN Tunnels (Westside & HQ)

Description: Policy rules 2 and 3 route traffic through dedicated `vpn-westside` and `vpn-hq` interfaces into the internal server subnet, indicating encrypted tunnel connectivity between Central and each remote site rather than raw internet transit.

Category: Technical

Function: Preventive

Asset(s) Protected: Data in transit between Westside Clinic, Corporate HQ, and Central's server subnet

Source: Artifact 1 — Firewall Configuration Extract (policy rules 2 and 3, "Allow-VPN-Westside" / "Allow-VPN-HQ")

---

Control ID: C-004

Control Name: Firewall Traffic Logging

Description: Every firewall policy rule has `logtraffic` enabled (`all` on rules 1 and 5, `utm` on rules 2–4), recording allowed and denied traffic crossing the perimeter for later review.

Category: Technical

Function: Detective

Asset(s) Protected: Network perimeter and internal server subnet (supports post-hoc traffic review; note per Artifact 8 that logs are retained locally for only 30 days and are not forwarded to any central system)

Source: Artifact 1 — Firewall Configuration Extract (all policy rules)

---

Control ID: C-005

Control Name: SSH Public-Key Authentication (ehr-srv-01)

Description: `sshd_config` on ehr-srv-01 sets `PasswordAuthentication no`, `PubkeyAuthentication yes`, and `PermitEmptyPasswords no`, requiring cryptographic key possession for shell access instead of a guessable or brute-forceable password.

Category: Technical

Function: Preventive

Asset(s) Protected: ehr-srv-01 (EHR application server) administrative/shell access

Source: Artifact 2 — SSH Configuration (`/etc/ssh/sshd_config`, ehr-srv-01)

---

Control ID: C-006

Control Name: SSH Access Hardening Configuration (ehr-srv-01)

Description: The same configuration disables root login (`PermitRootLogin no`), limits authentication attempts (`MaxAuthTries 3`), bounds the unauthenticated connection window (`LoginGraceTime 60`), terminates idle sessions (`ClientAliveInterval 300` / `ClientAliveCountMax 2`), and disables X11/TCP forwarding — reducing the range of techniques available to an attacker who reaches the SSH service.

Category: Technical

Function: Preventive

Asset(s) Protected: ehr-srv-01 (EHR application server) administrative/shell access

Source: Artifact 2 — SSH Configuration (`/etc/ssh/sshd_config`, ehr-srv-01)

---

Control ID: C-007

Control Name: SSH Authentication Logging (ehr-srv-01)

Description: `SyslogFacility AUTH` with `LogLevel VERBOSE` records detailed authentication events — successful and failed — to the system log, providing a record of who accessed the server and when.

Category: Technical

Function: Detective

Asset(s) Protected: ehr-srv-01 (EHR application server) — enables after-the-fact detection of unauthorized access attempts (note per Artifact 8 that no centralized alerting exists on this log source)

Source: Artifact 2 — SSH Configuration (`/etc/ssh/sshd_config`, ehr-srv-01)

---

Control ID: C-008

Control Name: AD-Enforced Password & Account Lockout Policy

Description: The password policy's technical requirements — 8-character minimum, complexity, 90-day rotation, 5-password history, and lockout after 5 failed attempts for 30 minutes — are enforced automatically through Active Directory Group Policy for Windows systems (per policy Section 5). This is the technical enforcement mechanism for the administrative policy documented separately as C-016.

Category: Technical

Function: Preventive

Asset(s) Protected: Windows domain user accounts organization-wide (does not cover Linux systems, which per the same section are "configured individually")

Source: Artifact 3 — Password Policy (Section 5, "Enforcement")

---

Control ID: C-009

Control Name: Sophos Endpoint Protection (Antivirus)

Description: Signature-based endpoint protection deployed to 372 Windows 10/11 workstations (88.1% with current signatures), with demonstrated real-world detections and actions in the last 30 days — Adware quarantined, a cryptomining PUA blocked, a phishing URL blocked, and a trojan quarantined.

Category: Technical

Function: Preventive

Asset(s) Protected: Windows 10/11 workstations (372 devices) — explicitly does not cover Windows servers (15, unlicensed), Linux servers (0, unsupported tier), macOS, mobile devices, or physician iPads

Source: Artifact 4 — Sophos Antivirus Status Report

---

Control ID: C-010

Control Name: Veeam Nightly Backup Job

Description: The "Nightly-Full" Veeam job performs a full backup of six named VMs (ehr-srv-01, ehr-db-01, billing-srv-01, ad-dc-01, file-srv-01, web-srv-01) daily at 02:00 to NAS-01, retained for 14 days, enabling restoration after data loss or corruption.

Category: Technical

Function: Corrective

Asset(s) Protected: EHR application and database, billing system, primary domain controller, file shares, public website/patient portal (does not cover PACS, secondary DC, print server, Westside's server, medical device configs, or O365 data; NAS-01 is co-located with production in the same server room, and full DR recovery has never been tested)

Source: Artifact 5 — Backup Configuration

---

Control ID: C-011

Control Name: Windows Server Event Logging

Description: Windows servers write events to the local Event Viewer, which staff check manually when an issue is reported or suspected.

Category: Technical

Function: Detective

Asset(s) Protected: Windows servers (ad-dc-01/02, pacs-srv-01, file-srv-01, print-srv-01) — reactive, manual review only, no proactive alerting

Source: Artifact 8 — Log Management (verbal summary, Tom Reeves)

---

Control ID: C-012

Control Name: Linux Syslog Logging

Description: Linux servers write standard syslog output to `/var/log`, with no centralization or forwarding to a collection point.

Category: Technical

Function: Detective

Asset(s) Protected: Linux servers (ehr-srv-01, ehr-db-01, billing-srv-01, backup-srv-01, web-srv-01)

Source: Artifact 8 — Log Management (verbal summary, Tom Reeves)

---

Control ID: C-013

Control Name: Apache Web/Application Log Rotation

Description: Apache access and error logs on web-srv-01 and billing-srv-01 rotate weekly via logrotate, with 4 weeks retained.

Category: Technical

Function: Detective

Asset(s) Protected: Public website/patient portal (web-srv-01) and billing/claims processing (billing-srv-01)

Source: Artifact 8 — Log Management (verbal summary, Tom Reeves)

---

Control ID: C-014

Control Name: EHR Application Audit Log

Description: The EHR application maintains its own vendor-managed audit log of user activity within the system; exports can be requested but take up to 48 hours to receive.

Category: Technical

Function: Detective

Asset(s) Protected: PHI access records within the EHR application (supports HIPAA accountability and after-the-fact audit review)

Source: Artifact 8 — Log Management (verbal summary, Tom Reeves)

---

Control ID: C-015

Control Name: Active Directory Critical Event Logging

Description: Active Directory logs critical events (e.g., authentication, directory changes), though no alerting is configured — logs are only reviewed reactively, after something has already broken.

Category: Technical

Function: Detective

Asset(s) Protected: Domain-wide authentication and directory-change visibility

Source: Artifact 8 — Log Management (verbal summary, Tom Reeves)

---

Control ID: C-016

Control Name: Password Policy Document

Description: A formal, IT-authored and Sarah-Park-approved policy defines minimum length, complexity, 90-day rotation, 5-password history, lockout thresholds, and rules for shared-account password changes on staff departure. This is the administrative source document that C-008 technically enforces on Windows systems.

Category: Administrative

Function: Preventive

Asset(s) Protected: All user accounts and systems requiring authentication, organization-wide

Source: Artifact 3 — Password Policy (Internal Document)

---

Control ID: C-017

Control Name: Security Awareness Training Program ("CyberSafe Basics")

Description: A mandatory annual 45-minute third-party training module covering password hygiene, phishing recognition, physical security awareness (tailgating, clean desk), and reporting suspicious activity, tracked by HR with per-site completion rates.

Category: Administrative

Function: Preventive

Asset(s) Protected: Staff/human element organization-wide (reduces susceptibility to phishing and social engineering; note completion is uneven — 94% HQ, 71% Central, 58% Westside — and contains no PHI-handling or healthcare-specific content)

Source: Artifact 7 — Training Records

---

Control ID: C-018

Control Name: Onsite Security Guard — Access Control & Incident Reporting

Description: A uniformed ClearView guard staffs the main entrance lobby Monday–Friday, 07:00–19:00, performing visitor registration and badge verification before allowing entry, and reporting incidents observed at the desk.

Category: Physical

Function: Preventive

Asset(s) Protected: Central's main entrance / front-of-house physical access (does not cover floors, restricted areas, parking, nights, weekends, Westside, or HQ)

Source: Artifact 6 — Physical Security Contract (ClearView Security)

---

Control ID: C-019

Control Name: CCTV / Camera Surveillance System

Description: Four analog cameras at Central (main entrance x2, ER entrance, parking garage entrance) record to a standalone DVR with 30-day retention before being overwritten; one camera at Westside's front entrance records to a local SD card with roughly 48 hours of capacity. Footage is self-monitored by whoever staffs the security desk rather than actively watched.

Category: Physical

Function: Detective

Asset(s) Protected: Main entrance, ER entrance, and parking garage entrance at Central; front entrance at Westside (no coverage of server room, network closets, or the administrative wing; no MedDefense access to HQ's building-managed footage)

Source: Artifact 6 — Physical Security Contract (ClearView Security), camera system notes (Tom Reeves)

---

## Control Summary Matrix

| Category       | Preventive                                    | Detective                                    | Corrective | Compensating | Deterrent |
|-----------------|------------------------------------------------|-----------------------------------------------|------------|---------------|-----------|
| **Technical**       | C-001, C-002, C-003, C-005, C-006, C-008, C-009 | C-004, C-007, C-011, C-012, C-013, C-014, C-015 | C-010      |               |           |
| **Administrative**  | C-016, C-017                                    |                                                |            |               |           |
| **Physical**        | C-018                                           | C-019                                          |            |               |           |

---

## Gaps Identified

The empty cells are as informative as the filled ones:

- **Corrective controls are almost entirely absent outside backups.** C-010 is the only corrective control in the entire inventory, and it is undermined by its own single point of failure — the backup NAS sits in the same room as what it's backing up, with no offsite copy and no tested full recovery. There is no evidenced corrective control for a physical incident, a compromised account, or a malware infection beyond AV quarantine.
- **No Compensating controls are evidenced anywhere.** Known unpatchable or high-risk assets (e.g., the Windows XP MRI scanner referenced elsewhere in the environment documentation) have no documented alternative control substituted in these artifacts — segmentation, isolation, or monitoring that would compensate for what can't be fixed directly.
- **No Deterrent controls are evidenced.** The guard (C-018) and cameras (C-019) were classified by their actual documented function — access verification and recorded detection — rather than assumed deterrent value, since no artifact describes signage, visible warnings, or anything designed primarily to discourage an attempt rather than stop or record one.
- **Administrative and Physical detective/corrective capability is thin.** There is no administrative control evidenced for detecting policy violations (e.g., an audit or review cycle) or correcting them (e.g., a disciplinary or remediation procedure) — only the preventive policy and training exist on paper. Physically, there is no corrective control at all (no documented re-entry, lockdown, or restoration procedure).

This mirrors what the walk-through independently surfaced: the organization's investment is concentrated in preventive technical controls, while detection is largely manual/reactive and correction is nearly untested.
