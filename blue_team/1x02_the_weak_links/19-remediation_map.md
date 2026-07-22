
## Finding 001/002 — Apache mod_lua RCE + Privilege Escalation (billing-srv-01)

**Response Type**: Patch

- **Patch Source**: Apache 2.4.52+ (fixes CVE-2021-44790) and 2.4.39+ (fixes CVE-2019-0211) — but this server is on Ubuntu 18.04 without ESM (Finding 011), so the patched Apache version isn't in the standard repos yet. **Enrolling in Ubuntu Pro/ESM is a prerequisite**, not an alternative.
- **Prerequisites**: Enroll in Ubuntu Pro/ESM first; test the billing application against the patched Apache in a staging copy (custom Lua scripts may depend on current behavior); take a full Veeam snapshot immediately before patching; schedule a maintenance window.
- **Rollback Plan**: Restore the pre-patch Veeam snapshot if the billing application breaks.
- **Operational Risk**: Billing/claims processing outage during the window; possible app incompatibility with the patched mod_lua behavior; restarting Apache could also surface unrelated issues given this host's undetermined prior compromise.

**Timeline**: Immediate (24–48h)
**Owner**: IT (Sysadmin) + Security (validation)
**Cost Estimate**: $1–10K (ESM licensing for the Linux fleet + testing/labor)

---

## Finding 003 — PostgreSQL Unrestricted Access (ehr-db-01)

**Response Type**: Configuration Change

- **Change Description**: Restrict `pg_hba.conf` to accept connections only from ehr-srv-01 (10.10.2.10); add a host firewall rule dropping all other inbound traffic to port 5432.
- **Impact Assessment**: No legitimate service besides ehr-srv-01 needs direct DB access — expected impact is zero for normal operations. DBAs who currently connect directly from their own workstations would need to go through ehr-srv-01 or a jump host instead.

**Timeline**: Immediate (24–48h)
**Owner**: IT (Database Administrator)
**Cost Estimate**: $0–1K

---

## Finding 007 — LDAP Signing Not Required (ad-dc-01)

**Response Type**: Configuration Change

- **Change Description**: Enable "Require signing" for LDAP server signing via Group Policy; disable SMBv1 (`Remove-WindowsFeature FS-SMB1` or equivalent GPO).
- **Impact Assessment**: Any legacy device or application that only supports unsigned LDAP or SMBv1 could break — needs a quick compatibility check first (print-srv-01 and any older equipment are the likely risk points).

**Timeline**: 7 days — short delay only to confirm nothing legacy depends on the old behavior; not a same-day change given the domain-wide blast radius if something breaks.
**Owner**: IT (Systems Administrator) + Security (policy validation)
**Cost Estimate**: $0–1K

---

## Finding 031/017 — Ghostcat (ehr-srv-01)

**Response Type**: Configuration Change (immediate mitigation), followed by Patch (permanent fix)

- **Change Description**: Disable the AJP connector in `server.xml` if nothing uses it, or restrict it to localhost with a required `secret` per Apache's own official Ghostcat mitigation — this is faster than waiting on a full version upgrade.
- **Impact Assessment**: If AJP isn't actually used by anything (the common case), zero impact. Follow up within 30 days with a full Tomcat upgrade to 9.0.31+ as the permanent fix.

**Timeline**: Immediate (24–48h) for the config change; 30 days for the full patch
**Owner**: IT (Sysadmin) + Security
**Cost Estimate**: $0–1K

---

## Finding 004 — Windows XP End-of-Life (WS-RAD-01, MRI Workstation)

**Response Type**: Compensating Control (full remediation isn't feasible this quarter — see Task 12)

- **Control Description**: VLAN-isolate this workstation so it can only reach the PACS server; disable SMB/RDP at the host firewall if not clinically required; add network-level monitoring on this segment since the host can't run modern endpoint tooling.
- **Residual Risk**: The underlying vulnerabilities remain permanently unpatched — this control only limits blast radius. If another device on the same VLAN is later compromised, lateral movement within that VLAN is still possible.

**Timeline**: 7 days for the VLAN isolation (achievable quickly via existing firewall/switch capability)
**Owner**: IT (Network team) + Clinical Engineering (coordination for any scanner downtime)
**Cost Estimate**: $1–10K

---

## Finding 010 — BD Alaris Infusion Pumps (Default Credentials)

**Response Type**: Configuration Change (credentials) + Compensating Control (network isolation)

- **Change Description**: Change the default `admin`/`admin` credential on all 7 scanned pumps (and the rest of the ~120-pump fleet) to unique, managed credentials; follow BD's own bulletin recommendation to isolate infusion pumps on a dedicated VLAN restricted to clinical workstations and PACS.
- **Impact Assessment**: Credential change has zero clinical impact — just needs to be documented in biomedical engineering's password process. VLAN isolation needs brief per-device reconnection, best rotated through the fleet rather than done all at once.

**Timeline**: Immediate (24–48h) for credentials; 30 days for fleet-wide VLAN isolation
**Owner**: Clinical Engineering (credentials) + IT/Network (segmentation)
**Cost Estimate**: $0–1K for credentials; $10–50K for the full medical-device segmentation project

---

## Finding 016 — Philips IntelliVue Monitors Exposed

**Response Type**: Compensating Control

- **Control Description**: Same medical-device VLAN segmentation project as Finding 010 — bundle both device classes into one network project since they share the same root cause.
- **Residual Risk**: Vulnerabilities remain; the isolation has to preserve whatever legitimate path monitors need to report to a central nursing station, so the segment can't be fully sealed off, only tightly scoped.

**Timeline**: 30 days (bundled with the infusion pump project)
**Owner**: IT/Network + Clinical Engineering
**Cost Estimate**: Bundled with Finding 010's $10–50K project

---

## Finding 015 — NAS-01 DSM Exposed

**Response Type**: Configuration Change

- **Change Description**: Restrict the DSM web interface (ports 5000/5001) to a specific backup-admin workstation via firewall/ACL; confirm and patch the DSM build to at least 7.2.2-72806-1 (fixing CVE-2024-10441, per Task 9); enable at-rest encryption for backup data.
- **Impact Assessment**: No impact on the Veeam backup job itself; only affects admins who currently manage the NAS from arbitrary workstations.

**Timeline**: Immediate (24–48h) for the firewall restriction; 30 days for the version confirmation/patch and enabling encryption
**Owner**: IT (Systems/Backup Administrator)
**Cost Estimate**: $0–1K for this remediation. **Separately** (not part of this fix): the deeper architectural problem — no offsite backup copy at all — needs its own $10–50K+ project for offsite/cloud backup infrastructure, tracked as a longer-term item rather than folded into this quick fix.
