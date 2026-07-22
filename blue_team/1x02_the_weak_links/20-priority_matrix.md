## Immediate (24–48 hours)

*Weaponized exploit + critical asset + active threat*

| Finding | Description | Remediation Action | Owner | Cost |
|---|---|---|---|---|
| 001/002 | Apache RCE → root chain, billing-srv-01 | Patch Apache (needs ESM first) | IT/Security | $5K |
| 003 | PostgreSQL open to entire network, ehr-db-01 | Restrict `pg_hba.conf` + firewall rule | IT (DBA) | $0.5K |
| 031/017 | Ghostcat, ehr-srv-01 | Disable/restrict AJP connector | IT/Security | $0.5K |
| 028 | Unidentified device, server subnet | Investigate and isolate/remove | Security | $1K |
| 029 | Grafana path traversal, Westside (weaponized, KEV) | Patch/decommission device, add to inventory | IT | $1K |
| 010 | BD Alaris default credentials | Change all pump credentials | Clinical Engineering | $0.5K |
| 015 | NAS-01 DSM reachable network-wide | Firewall-restrict DSM interface | IT | $0.5K |

**Immediate subtotal: ≈ $9K**

---

## Short-term (7 days)

*Critical/High CVE with PoC + important asset*

| Finding | Description | Remediation Action | Owner | Cost |
|---|---|---|---|---|
| 007 | LDAP signing not required, ad-dc-01 | Enable signing + disable SMBv1 | IT/Security | $0.75K |
| 004 | Windows XP MRI workstation | VLAN-isolate to PACS only | IT/Network + Clinical Eng. | $5K |
| 011/026 | Ubuntu 18.04 no ESM + outdated kernel | Enroll Ubuntu Pro/ESM fleet-wide | IT | $3K |
| 006 | MySQL bound to 0.0.0.0, billing-srv-01 | Restrict bind address/firewall | IT | $0.5K |
| 025 | DNS zone transfer enabled, ad-dc-01 | Restrict AXFR to named secondaries | IT | $0.2K |
| 027 | Sophos agents down, 15 workstations | Re-deploy/troubleshoot agents | IT | $1K |

**Short-term subtotal: ≈ $10.5K**

---

## Medium-term (30 days)

*High/Medium CVE or significant misconfiguration*

| Finding | Description | Remediation Action | Owner | Cost |
|---|---|---|---|---|
| 005 | Weak TLS, web-srv-01 | Disable TLS 1.0/1.1 | IT | $0.5K |
| 008 | PrintNightmare, print-srv-01 | Patch/disable Print Spooler | IT | $1K |
| 009 | SSH password auth, billing-srv-01 | Enforce key-only auth | IT | $0.5K |
| 012 | Missing security headers, web-srv-01 | Add CSP/XFO/HSTS headers | IT | $0.5K |
| 014 | Consumer router admin page, Westside | Restrict admin interface via ACL | IT/Network | $0.5K |
| 017 | Tomcat info disclosure, ehr-srv-01 | Suppress default error pages | IT | $0.2K |
| 018 | Weak Kerberos encryption, ad-dc-01/02 | Disable DES/RC4 | IT/Security | $0.5K |
| 021 | HTTP TRACE enabled, web-srv-01 | Disable TRACE method | IT | $0.2K |
| 023 | USB restriction missing, ~280 workstations | Roll out GPO restriction | IT | $3K |
| 010/016 | Medical device network exposure (pumps + monitors) | Dedicated medical-device VLAN project | IT/Network + Clinical Eng. | $25K |
| 015 | NAS-01 version/encryption | Confirm/patch DSM build + enable encryption | IT | $1K |

**Medium-term subtotal: ≈ $32.9K**

---

## Long-term (90 days)

*Architecture changes, EOL migrations, systemic fixes*

| Item | Description | Remediation Action | Owner | Cost |
|---|---|---|---|---|
| Billing server migration | Full OS migration off Ubuntu 18.04 (permanent fix beyond the Short-term ESM patch) | Migrate to a currently-supported LTS release | IT | $20K |
| Print server replacement | Windows Server 2012 R2 EOL (Finding 008's root cause) | Verify still needed, then replace/decommission | IT | $15K |
| MRI vendor engagement | Windows XP can't be patched or migrated without Siemens | Initiate vendor recertification process (not complete — vendor/FDA-gated) | IT/Clinical Eng./Vendor | $20K |
| **Network segmentation** | The root cause underneath nearly every finding in this report (Task 14) | Design and implement VLANs separating servers, clinical workstations, medical devices, and guest Wi-Fi | IT/Network | $60K |
| Westside router replacement | Consumer-grade device carrying the site-to-site VPN (Finding 014) | Replace with enterprise firewall/router | IT/Network | $5K |
| NAS-01 offsite backup | No offsite copy exists at all (1x00 control gap) | Stand up offsite/cloud backup target | IT | $20K |

**Long-term subtotal: ≈ $140K**

---

## Budget Summary

| Horizon | Cost |
|---|---|
| Immediate | $9K |
| Short-term | $10.5K |
| Medium-term | $32.9K |
| Long-term | $140K |
| **Total** | **≈ $192.4K** |

**Compared to the $120,000 annual security budget, this remediation plan runs about $72K over — roughly 60% above what's available.** The good news: everything in Immediate, Short-term, and Medium-term (≈ $52.4K combined) fits comfortably inside the budget with room to spare. The overrun is entirely in the Long-term bucket, where six large architecture-level projects add up fast.

**What must be deferred, and why**: With roughly $67.6K left after funding everything through Medium-term, there isn't enough to do all six Long-term items this year. I'd fund **network segmentation ($60K) first and defer the rest** — billing server migration, print server replacement, the MRI vendor engagement, the Westside router replacement, and the NAS offsite backup project all get pushed to next fiscal year or a supplemental budget request. This isn't an arbitrary cut: Task 14 already established that segmentation caps the blast radius of *every* other vulnerability in this report at once, current and future. A dollar spent on segmentation protects the billing server, the MRI, the print server, and the NAS all simultaneously — the other five projects each protect exactly one asset. If the budget can only fully fund one big architecture change this year, it should be the one that makes every other future finding smaller by default.
