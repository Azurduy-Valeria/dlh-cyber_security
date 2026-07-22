## Host: web-srv-01 (10.10.2.50) — Public Website / Patient Portal

**Exposure**: **Internet-facing.** Per the 1x00 control inventory (C-002), this is the *only* host in the entire environment sitting in the DMZ with direct inbound internet access — every other host on this list requires some prior foothold inside `10.10.0.0/16` first.

**Findings**: 005 (TLS 1.0 supported alongside 1.2 — BEAST/POODLE, CVSS 7.5), 012 (missing security headers — CSP, X-Frame-Options, HSTS, X-Content-Type-Options, X-XSS-Protection), 013 (SSL certificate expiring in 23 days), 021 (HTTP TRACE method enabled)

**Combined Risk**: None of these four is an RCE-class bug on its own, but stacked together on the *one* host reachable by literally anyone on the internet, they compound into a real problem: weak TLS lets an on-path attacker (public Wi-Fi, a hostile router, a compromised ISP hop) attempt to downgrade and partially decrypt session traffic; the total absence of CSP/X-Frame-Options/X-Content-Type-Options means there is zero defense-in-depth if any injection-class bug is ever introduced to this application in the future (not present in this scan, but the *surface area for a future issue* is unusually large here); TRACE plus any future XSS enables classic Cross-Site Tracing credential theft; and the expiring certificate means the portal is 23 days from throwing browser warnings at patients, risking exactly the kind of "click through the warning" habit that makes people ignore a *real* warning later. This is the only host where the aggregate risk includes the general public, not just an internal attacker.

**Attack Scenario**: An attacker positioned on a shared or hostile network (public Wi-Fi, a compromised residential router, a malicious exit node) forces a protocol downgrade to TLS 1.0 and attempts BEAST/POODLE-class decryption of a patient's session cookie. Separately, if any minor injection bug is ever introduced to the portal, the complete absence of CSP/XFO means it's immediately exploitable for session theft or clickjacking with no backstop. In kill-chain terms this cluster sits almost entirely at **Reconnaissance → Exploitation**, and it's the only host in the whole report where an external, unauthenticated attacker doesn't need *any* foothold on MedDefense's internal network first — they're already "positioned" the moment a patient visits the portal from an untrusted network.

**Priority**: **Highest among the web hosts.** Every finding here removes the "attacker needs internal access first" precondition that every other host on this list still requires — that alone puts it on par with the internal Critical chains from Task 10, despite none of these four individually being CVSS-Critical.

---

## Host: ehr-srv-01 (10.10.2.10) — EHR Application Server

**Exposure**: **Internal only — but flat-network accessible**, meaning reachable from any of the ~47 scanned hosts, including unmanaged medical devices, with no segmentation narrowing it down.

**Findings**: 017 (Tomcat 9.0.31 default error page discloses version + stack traces), 031 (Ghostcat — CVE-2020-1938, CVSS 9.8, weaponized, confirmed active via SecurePoint's manual follow-up)

**Combined Risk**: This pairing is the textbook example of a "Medium" finding directly enabling a "Critical" one. 017 alone tells an attacker exactly which Tomcat version is running — enough to know Ghostcat is likely exploitable before even attempting it. 031 then delivers actual file-read capability, almost certainly including `web.xml`/`context.xml`/config files containing the exact PostgreSQL credentials ehr-srv-01 uses to reach ehr-db-01. Combined, this is a complete, two-step path from a low-severity fingerprinting bug to full PHI database compromise.

**Attack Scenario**: An attacker anywhere on the flat network probes port 8080, sees the default Tomcat error page (017), and immediately knows the version. Version 9.0.31 falls in Ghostcat's vulnerable range, so the attacker moves straight to the AJP connector on port 8009 (031), reads configuration files off disk, extracts the PostgreSQL credentials, and connects directly to the exposed ehr-db-01 (Finding 003) using those harvested credentials. Kill chain: **Reconnaissance (017) → Exploitation (031) → Actions on Objectives (003)** — the same 017→031→003 chain built out in full in Task 10's deep-dive.

**Priority**: **Highest of all hosts on this list, internet-facing included** — this is the one host with a complete, proven, weaponized path directly to the crown-jewel database, not just a theoretical or partial one.


## Host: NAS-01 (10.10.2.41) — Synology Backup NAS

**Exposure**: **Internal only**, but per the finding's own text, reachable from "the entire internal network," not restricted to administrative IPs.

**Findings**: 015 (DSM management interface reachable network-wide, unencrypted backup data)

**Combined Risk**: Scanner-rated Medium in isolation, but the combined risk has to account for *what this device is*: per the 1x00 control inventory (C-010), NAS-01 is the **sole backup copy** of six critical VMs, with no offsite copy and no tested full recovery. "Someone can reach the admin panel" reads very differently once you know reaching it is a plausible path to destroying the organization's only recovery option — this is the same reasoning already developed in Task 6 (bumped to High) and reinforced in Task 9, where OSINT research turned up CVE-2024-10441, an unauthenticated RCE in DSM builds this scan never version-checked.

**Attack Scenario**: An attacker with any foothold on the flat network reaches DSM on ports 5000/5001 and either uses weak/default/reused admin credentials, or — if the DSM build predates the fix — exploits CVE-2024-10441 for unauthenticated code execution. Either path leads to destroying or exfiltrating backup data, a standard "hit the backups first" step in ransomware operations, executed here with zero additional lateral movement required since the interface is already reachable from anywhere. Kill chain: **Lateral Movement (reaching DSM from wherever the attacker first landed) → Actions on Objectives (destroy/steal the only backup copy)** — typically a *late-stage* objective in a real intrusion, right before or during ransomware deployment.

**Priority**: **High**, but not first — it requires a prior foothold elsewhere, unlike web-srv-01 or ehr-srv-01. Its priority comes from how catastrophic reaching it would be, not from how easy reaching it is.

## Host: Unidentified Linux device at Westside (10.10.10.200) — Grafana

**Exposure**: **Internal (Westside site)**, reachable via the site-to-site VPN riding on the consumer router — and notably, this device isn't in *any* IT inventory at all.

**Findings**: 029 (CVE-2021-43798, Grafana 8.2.0 path traversal, CVSS 7.5, trivial public exploit, in CISA KEV)

**Combined Risk**: Combines two separate problems: a real, trivially exploitable, publicly documented web vulnerability, *and* a completely unmanaged device nobody at MedDefense knows exists. Nobody is watching this box, so exploitation here would likely go unnoticed indefinitely — the same detection gap that let the billing-srv-01 cryptominer run for two weeks in the 1x00 incident.

**Attack Scenario**: An attacker discovers the exposed Grafana login — either via internet-wide scanning if Westside's consumer router happens to forward this port, or after gaining any foothold inside Westside's network — and exploits the trivial path-traversal to read arbitrary files off the host, potentially harvesting credentials that pivot further into Westside's network, and from there through the site-to-site VPN into Central's server subnet, since that same VPN rides on this same consumer router. Kill chain: **Reconnaissance/Delivery → Exploitation → Lateral Movement (toward Central via the VPN).**

**Priority**: **Medium-High.** The exploit is trivial and public, but Westside itself is a lower-criticality site (no MRI, PACS, or inpatient care), and there's no confirmed sensitive data on this specific box. It's urgent primarily *because* it's unmanaged shadow IT that nobody is tracking, not because of what it directly holds.

## Host: Philips IntelliVue monitors (10.10.3.10–32) — Web/HL7 Interfaces

**Exposure**: **Internal, flat network**, no authentication beyond the network layer.

**Findings**: 016

**Combined Risk / Attack Scenario**: The deeper analysis here belongs to Task 15 (Medical IoT), since the dominant risk dimension is patient safety rather than classic web-application compromise. As a pure web finding: these are exposed management interfaces with zero access control, reachable by anyone on the flat network, no chaining with other findings required.

**Priority**: **High** from the patient-safety lens developed in Task 15, but lower than 017/031 as a *web-attack-surface* item specifically, since there's no confirmed chain here comparable to the EHR path.


## Host: Westside Netgear Router (10.10.10.1) — Admin Interface

**Exposure**: **Internal (Westside)** — but this device also terminates the site-to-site VPN to Central, meaning "internal to Westside" still yields a path into Central's server subnet.

**Findings**: 014

**Combined Risk**: A consumer-grade device with an internally-reachable admin page, simultaneously serving as the sole piece of infrastructure protecting and routing the Central–Westside VPN, with none of the logging, IDS, or hardening enterprise gear would provide.

**Attack Scenario**: An attacker with Westside network access reaches the admin page — plausibly via default or never-audited credentials, given this is consumer hardware Marcus's own notes flagged as unacceptable for a medical facility — and from there controls routing/VPN configuration, either intercepting traffic or pivoting directly into Central's server subnet through the tunnel. Kill chain: **Lateral Movement via a compromised trust relationship** (the VPN itself), rather than a direct exploit of anything at Central.

**Priority**: **Medium-High** — similar logic to the NAS: not usually the first thing an attacker reaches, but a high-value pivot point once reached, since the entire Westside–Central trust relationship depends on this one under-hardened box.
