# The Noise Filter: Full Triage of All 31 Findings

Categories: **AC** = Actionable Critical (24–48h) · **AS** = Actionable Standard (7–30 days) · **I** = Informational (document/monitor) · **FP** = False Positive (document/dismiss)

This deliberately does *not* just mirror the scan report's own severity labels — several findings get moved up or down from their scanner-assigned tier based on everything established in Tasks 0–15 (exploit maturity, chained findings, asset criticality, confirmed false positives).


Finding 001 | CVSS 9.8 | billing-srv-01 | Category: AC | Reason: Unauthenticated RCE with an EDB-verified public PoC, chains directly into Finding 002 for full root compromise.

Finding 002 | CVSS 7.8 | billing-srv-01 | Category: AC | Reason: KEV-listed privilege-escalation half of the same proven chain as Finding 001 — root compromise, not a standalone Medium.

Finding 003 | Critical (no CVE) | ehr-db-01 | Category: AC | Reason: Direct network path to the entire PHI database from anywhere on the flat network with zero exploit development required.

Finding 004 | CVSS 8.1/9.8/10.0 (3 CVEs) | WS-RAD-01 | Category: AC | Reason: Three independent, fully weaponized, KEV-listed RCEs on a patient-safety-critical, un-replaceable-this-quarter device.

Finding 005 | CVSS 7.5 | web-srv-01 | Category: AS | Reason: Real weak-TLS exposure on the one internet-facing host, but requires an on-path attacker rather than being trivially remotely triggerable.

Finding 006 | High (no CVE) | billing-srv-01 | Category: AS | Reason: Same misconfiguration pattern as Finding 003 but on financial data rather than PHI — real, schedulable network-binding fix.

Finding 007 | High (no CVE) | ad-dc-01 | Category: AC | Reason: Tool-automated NTLM-relay-to-LDAP technique on the domain controller — the single highest-blast-radius asset in the environment.

Finding 008 | CVSS 8.8 | print-srv-01 | Category: AS | Reason: Weaponized PrintNightmare exists, but this is the lowest-criticality server among the EOL hosts (Task 12) and the asset itself is unverified as still in service.

Finding 009 | High (no CVE) | billing-srv-01 | Category: AS | Reason: Real brute-force exposure with no lockout, but requires sustained attacker effort rather than one-shot exploitation.

Finding 010 | High (CVE + default creds) | Medical IoT (BD Alaris) | Category: AC | Reason: The default-credential half is real, verified, and trivially exploitable on a life-safety device — the CVE attribution itself is likely a false positive per Task 15's vendor-bulletin research, but that doesn't reduce the urgency of the credential issue.

Finding 011 | High (EOL, no CVE) | billing-srv-01 | Category: AS | Reason: The single cheapest fix in the entire report (Ubuntu Pro/ESM enrollment) and the root cause enabling Findings 001, 002, and 026 to remain unpatched.

Finding 012 | Medium (no CVE) | web-srv-01 | Category: AS | Reason: Missing security headers on the internet-facing host — low-cost, high-value defense-in-depth fix.

Finding 013 | Medium (no CVE) | web-srv-01 | Category: I | Reason: A time-bound operational reminder (renew before expiry), not an exploitable weakness in itself — track the deadline rather than "remediate."

Finding 014 | Medium (no CVE) | Westside router | Category: AS | Reason: Restricting the admin interface's reachability is a fast, concrete fix; replacing the underlying consumer-grade hardware is a longer-term capital item worth escalating separately.

Finding 015 | Medium (no CVE) | NAS-01 | Category: AC | Reason: Reachable from the entire network and protects the organization's sole, untested, offline-free backup copy — the stakes outrank the scanner's own Medium label.

Finding 016 | Medium (no CVE) | Philips monitors | Category: AC | Reason: Zero authentication on a life-safety device fleet reachable from anywhere on the flat network — a patient-safety issue, not a data issue.

Finding 017 | Medium (no CVE) | ehr-srv-01 | Category: AS | Reason: Already did its job by leading directly to Finding 031's discovery — remaining action is simply suppressing the default error page.

Finding 018 | Medium (no CVE) | ad-dc-01/02 | Category: AS | Reason: Real Kerberoasting-relevant weakness; disabling DES/RC4 is a straightforward, schedulable domain policy change.

Finding 019 | Medium (no CVE) | Multiple (5 hosts) | Category: I | Reason: NLA is already enabled and provides meaningful mitigation; document exposed hosts and monitor rather than treat as an open vulnerability.

Finding 020 | Medium/CVSS 9.8 | backup-srv-01 | Category: FP | Reason: SecurePoint's own note plus Task 4/11 research confirm the exploitation precondition (agent forwarding to an attacker-controlled host) doesn't match this server's operational role, and no public exploit exists.

Finding 021 | Medium (no CVE) | web-srv-01 | Category: AS | Reason: HTTP TRACE is low-impact without a companion XSS to chain with, but disabling it is a one-line config change worth doing on the internet-facing host regardless.

Finding 022 | Low (no CVE) | ehr-srv-01 | Category: FP | Reason: 47 seconds of clock skew sits far inside Kerberos's 300-second default tolerance and has no measurable effect on certificate validation — confirmed in Task 11.

Finding 023 | Low (no CVE) | ~280 workstations | Category: AS | Reason: Real, broad-scope data-exfiltration vector; a GPO rollout is a standard, schedulable remediation.

Finding 024 | Low (no CVE) | pacs-srv-01 | Category: I | Reason: Cleartext DICOM is an industry-common pattern with no confirmed active exploitation path identified anywhere else in this report; document as a longer-term infrastructure item.

Finding 025 | Low (no CVE) | ad-dc-01 | Category: AS | Reason: A one-line DNS configuration fix (restrict AXFR to designated secondaries) despite its Low severity label — cheap, easy, worth doing on schedule.

Finding 026 | Low (no CVE) | billing-srv-01 | Category: AS | Reason: Directly resolved by the same ESM enrollment that fixes Finding 011 — bundle the remediation.

Finding 027 | Informational (no CVE) | 15 workstations | Category: AS | Reason: Independently cross-referenced against Sophos Central data, not a scanner guess — these 15 specific machines need their agents actually restored, not just documented.

Finding 028 | Informational (no CVE) | Unidentified host, server subnet | Category: AC | Reason: An unauthorized device on the *server* subnet with an unusual Jupyter/Cockpit combination could represent an active compromise or unmanaged shadow IT — the uncertainty itself demands immediate investigation, not scheduled documentation.

Finding 029 | Informational/CVSS 7.5 | Unidentified host, Westside | Category: AC | Reason: A real, weaponized, KEV-listed CVE (confirmed Task 4/9) on an unmanaged device — the scanner's "Informational" label reflects the device's unknown-inventory status, not the vulnerability's actual severity.

Finding 030 | Informational (no CVE) | ehr-srv-01 | Category: FP | Reason: The scan report explicitly states this is "not a security vulnerability" — the plainest self-identified false positive in the entire document.

Finding 031 | High/CVSS 9.8 | ehr-srv-01 | Category: AC | Reason: Weaponized, genuinely KEV-listed (contrary to the finding's own outdated claim), and forms a complete documented path to the PHI database via Finding 003.


## Triage Summary

| Category | Count |
|---|---|
| Actionable Critical (AC) | 11 |
| Actionable Standard (AS) | 14 |
| Informational (I) | 3 |
| False Positive (FP) | 3 |
| **Total** | **31** |

---

## Actionable Findings List

### Actionable Critical — ordered by priority (24–48h remediation window)

1. **Finding 031** (Ghostcat, ehr-srv-01) — weaponized, KEV-listed, direct documented path to the PHI database via Finding 003.
2. **Finding 003** (PostgreSQL exposure, ehr-db-01) — the terminal objective nearly every other finding on this list is one step from reaching.
3. **Finding 001 / 002** (Apache RCE→root chain, billing-srv-01) — proven exploit chain on a host with a *documented prior compromise*.
4. **Finding 007** (LDAP relay, ad-dc-01) — the single highest-blast-radius target; compromises every account's trust simultaneously.
5. **Finding 004** (Windows XP MRI workstation) — highest CVSS in the report, wormable, direct patient-safety consequence.
6. **Finding 016** (Philips monitor interfaces exposed) — zero-authentication access to a life-safety device fleet.
7. **Finding 010** (BD Alaris default credentials) — trivially exploitable, life-safety impact, no exploit development needed at all.
8. **Finding 015** (NAS-01 DSM exposed) — threatens the organization's sole, untested backup copy.
9. **Finding 029** (Grafana path traversal, Westside) — real weaponized CVE, but on a lower-value, non-PHI target than 1–8.
10. **Finding 028** (Unidentified host, server subnet) — urgent specifically because its nature and intent are still unknown.

### Actionable Standard — ordered by priority (7–30 day remediation window)

1. **Finding 011 / 026** (Ubuntu 18.04 ESM enrollment + outdated kernel, billing-srv-01) — cheapest single fix in the report; closes two findings and stops new CVEs from accumulating further on the already-compromised-once host.
2. **Finding 006 / 009** (MySQL binding + SSH password auth, billing-srv-01) — same host as the AC-tier chain; fix alongside it rather than separately.
3. **Finding 018** (Kerberos weak encryption, ad-dc-01/02) — same host as the AC-tier LDAP finding; bundle the domain-hardening work.
4. **Finding 005 / 012 / 021** (TLS, missing headers, TRACE method — web-srv-01) — the only internet-facing host; low-cost hardening with outsized value given its exposure.
5. **Finding 008** (PrintNightmare, print-srv-01) — real and weaponized, but the lowest-criticality EOL host per Task 12's asset-criticality comparison.
6. **Finding 014** (Westside router admin interface) — fast ACL fix now; flag hardware replacement as a separate capital request.
7. **Finding 017** (Tomcat info disclosure, ehr-srv-01) — low remaining effort; already delivered its main value by leading to Finding 031.
8. **Finding 023** (USB restriction GPO, ~280 workstations) — broad scope, standard policy rollout.
9. **Finding 025** (DNS zone transfer, ad-dc-01) — trivial one-line config fix, no reason to delay despite Low severity.
10. **Finding 027** (Sophos agents down, 15 workstations) — independently verified, concrete list of machines to fix.
