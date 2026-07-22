# CIS Controls v8 — MedDefense Audit

| # | Control | Score | Evidence |
|---|---|---|---|
| 1 | Inventory and Control of Enterprise Assets | Partial | 1x00 built the first real asset inventory, but 1x02 found unauthorized/unregistered devices still on the server subnet and at Westside (Findings 028, 029) |
| 2 | Inventory and Control of Software Assets | Not Implemented | No software inventory process anywhere; EOL software (Windows XP, Server 2012 R2, Ubuntu 18.04) has been running with no tracked support status |
| 3 | Data Protection | Not Implemented | PostgreSQL wide open to the whole network (Finding 003), DICOM transmitted in cleartext (Finding 024), no disk encryption confirmed via the Lynis self-audit |
| 4 | Secure Configuration | Partial | SSH key-only auth exists on ehr-srv-01 (C-005/006), but LDAP signing is off (Finding 007) and password auth is still enabled elsewhere (Finding 009) |
| 5 | Account Management | Partial | A password policy exists (C-016), but a shared login (`raduser`/`radiology1`) is used department-wide in Radiology per Marcus's notes |
| 6 | Access Control Management | Not Implemented | MFA exists on exactly one personal account (James's) in the entire organization |
| 7 | Continuous Vulnerability Management | Not Implemented | No formal vulnerability assessment had ever been performed before the 1x02 scan |
| 8 | Audit Log Management | Partial | Logging exists per-host (syslog, AD events, Apache logs) but nothing is centralized or retained to a standard (Gap G-001) |
| 9 | Email and Web Browser Protections | Not Implemented | No DNS filtering or browser/email hardening evidenced anywhere in the environment documentation |
| 10 | Malware Defenses | Partial | Sophos covers Windows workstations, but 15 agents are inactive (Finding 027) and zero coverage exists on any Linux or Windows server (Gap G-004) |
| 11 | Data Recovery | Partial | Nightly Veeam backups exist (C-010), but the NAS sits in the same rack as production with no offsite copy and no tested recovery |
| 12 | Network Infrastructure Management | Not Implemented | Fully flat `10.10.0.0/16` network with no VLANs at all, plus a consumer-grade router at Westside (Finding 014) |
| 13 | Network Monitoring and Defense | Not Implemented | Marcus's notes confirm zero monitoring capability; no IDS/IPS anywhere in the environment |
| 14 | Security Awareness and Skills Training | Partial | "CyberSafe Basics" training exists (C-017) but completion is uneven (94%/71%/58% by site) with no healthcare-specific content |
| 15 | Service Provider Management | Not Implemented | No inventory or management policy exists for third parties (MedTech Solutions, SecurePoint, ClearView Security) despite their system access |
| 16 | Application Software Security | Not Implemented | No secure development process evidenced for the custom billing app/mod_lua scripts that turned out to carry the RCE in Finding 001 |
| 17 | Incident Response Management | Not Implemented | No formal incident response plan exists; the January incident was handled by ad hoc improvisation over four days |
| 18 | Penetration Testing | Not Implemented | The 1x02 engagement was a vulnerability scan, not a penetration test, and no recurring testing program exists |

## Scorecard Summary

| Score | Count |
|---|---|
| Implemented | 0 |
| Partial | 7 |
| Not Implemented | 11 |

Zero controls are fully implemented — consistent with everything the rest of this project has already found about MedDefense's maturity: the basics exist in fragments, nothing is complete or consistently applied.

## Top 5 Priority Controls

1. **Control 6 — Access Control Management (MFA)**: Cheapest, fastest fix available (existing O365 licenses), and directly closes the credential-based path behind the domain-relay finding (1x02 Finding 007).
2. **Control 12 — Network Infrastructure Management (segmentation)**: The single biggest risk amplifier in the entire environment — nearly every other finding in the vulnerability assessment is worse because this control doesn't exist.
3. **Control 7 — Continuous Vulnerability Management**: MedDefense had never run a vulnerability assessment before this project; formalizing the process prevents this from being a one-time snapshot instead of an ongoing practice.
4. **Control 10 — Malware Defenses**: Directly closes Gap G-004 — the exact missing coverage that let the cryptominer run undetected on billing-srv-01 for two weeks.
5. **Control 17 — Incident Response Management**: Cheap and fast to build, and directly prevents a repeat of the four-day ad hoc scramble that followed the January incident.
