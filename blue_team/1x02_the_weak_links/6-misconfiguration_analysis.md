## 1. Finding 003 - PostgreSQL Unrestricted Network Access

**Host**: ehr-db-01 (10.10.2.11)

**Misconfiguration**: `pg_hba.conf` contains `host all all 10.10.0.0/16 md5` and `listen_addresses = '*'` - PostgreSQL accepts connections from any of the ~65,000 addresses on the internal network, with no firewall or ACL layered on top to narrow that down.

**Why No CVE**: PostgreSQL is doing exactly what it was told to do. `pg_hba.conf` is a supported, documented, admin-editable trust configuration file - there's no code defect being triggered, no input the software mishandles. A new PostgreSQL release wouldn't "fix" this, because there's nothing broken in the software; a person configured it to trust the entire subnet. CVEs get assigned to flaws in code or design, and there's no code flaw here to assign one to.

**Severity Assessment**: **Critical** (agreeing with the scanner). This is the organization's actual PHI database, directly reachable - no exploit required - from any of the 47+ hosts on the flat network, including the unpatched Windows XP MRI workstation and the medical IoT devices. The only thing standing between "any compromised host" and "the patient database" is a password.

**Cross-Reference 1x00**: This is a direct, word-for-word match to Marcus Webb's own raw notes (`content/report.md`, Document 3): *"ehr-db-01: PostgreSQL is accessible from the entire 10.10.0.0/16 range. Should be restricted to ehr-srv-01 only."* It's also explicitly named in the Task 5 control gap analysis, **G-006**, as the flagship example of a missing Technical Compensating control - segmentation that's been "on the roadmap" for four-plus months. The scan didn't discover this; it confirmed something already known and already unaddressed for months.

**Comparable CVE Risk**: **CVE-2020-1938 (Ghostcat, Finding 031, CVSS 9.8)**. Ghostcat lets an attacker read arbitrary files off ehr-srv-01 - including config files that might contain database credentials - as a *means* of eventually reaching this same PHI data. Finding 003 skips that entire chain. It doesn't require a vulnerable AJP connector, a specific Tomcat version, or any exploit code at all - just network reachability and a valid (or guessable, or reused, or leaked) password. A misconfiguration that hands over the destination directly is at least as dangerous as a CVE that provides one possible route to it.


## 2. Finding 007 - LDAP Signing Not Required (+ SMBv1 Enabled)

**Host**: ad-dc-01 (10.10.2.20)

**Misconfiguration**: The primary domain controller doesn't require LDAP signing, and SMBv1 is still enabled. Without signing, an attacker positioned on the network can relay captured NTLM authentication attempts to LDAP and use them to read or modify directory objects - no password cracking needed, just relaying traffic that's already flowing.

**Why No CVE**: LDAP signing is an optional setting Microsoft ships and lets administrators toggle - it's not a bug in how signing works, it's a choice to leave it off. That's exactly why the scanner tags this as "Misconfiguration -- Microsoft Security Advisory" rather than a CVE: Microsoft published guidance recommending you turn on a feature they already built and support. There's no flawed code for a CNA to assign an ID to.

**Severity Assessment**: I'm rating this **Critical**, one step above the scanner's "High." NTLM-relay-to-LDAP is not a theoretical attack - it's a well-worn, tool-automated technique (`ntlmrelayx` and equivalents) that turns "attacker has any foothold on the network" into "attacker controls directory objects" in minutes, not days. Given the flat, unsegmented `10.10.0.0/16` network, *any* of the other 30 findings in this report that yields a foothold - the billing server RCE, the exposed medical device, the MRI workstation - becomes a direct on-ramp to attacking the domain controller itself.

**Cross-Reference 1x00**: Ties directly to **Task 3, Observation 2** (Network Closet) - the unlocked closet with a laminated sheet of switch credentials taped to the wall. That observation's own writeup notes the flat network gives a compromise "a direct path to servers, EHR systems, and medical devices org-wide"; unsigned LDAP is precisely the mechanism that turns "attacker is now on the network" into "attacker can manipulate Active Directory." It also reflects the same theme as **G-006** (no compensating controls) - there's nothing standing between network access and directory-level tampering.

**Comparable CVE Risk**: **CVE-2019-0211 (Apache privilege escalation, Finding 002, CVSS 7.8)**. Both are "already-have-a-foothold, now escalate" primitives. CVE-2019-0211 turns a low-privilege web shell into root - but only on that one billing server. Unsigned LDAP turns any network foothold into a path toward the domain controller that authenticates *every* account and *every* server in the organization. The blast radius of the misconfiguration is arguably larger than the CVE it's being compared to, despite carrying no CVSS number at all.


## 3. Finding 009 - SSH Password Authentication Enabled

**Host**: billing-srv-01 (10.10.2.15), and explicitly noted as true for all Linux servers except ehr-srv-01

**Misconfiguration**: SSH allows password-based login instead of requiring key-based authentication, and there's no account lockout policy on the Linux systems - so an attacker can attempt unlimited password guesses against a live SSH service.

**Why No CVE**: `PasswordAuthentication yes` is a standard, fully-supported OpenSSH configuration directive, working exactly as documented. Nothing is being exploited or triggered incorrectly - it's a deployment decision about which authentication method to permit. No code defect exists, so there's nothing for a CVE to describe.

**Severity Assessment**: **High** (agreeing with the scanner). It's a real, currently-exploitable path with commodity brute-force tooling, but I'm keeping it below Critical because it requires sustained guessing effort against an unknown password, rather than an instant, deterministic technique like the LDAP relay above.

**Cross-Reference 1x00**: Another direct, literal match to Marcus's raw notes: *"SSH: password auth is still enabled on all Linux servers. Should be key-only. I started migrating but only got to ehr-srv-01 before... well, before I ran out of time."* This is also visible in the Task 4 control inventory: **C-005/C-006** document SSH key-only hardening as present on ehr-srv-01 specifically - meaning the control's own documentation already scopes it to one host out of several, confirming the gap in writing before this scan ever ran.

**Comparable CVE Risk**: **CVE-2023-38408 (OpenSSH ssh-agent RCE, Finding 020, CVSS 9.8)** - on a sibling host (backup-srv-01) running the same software family. The Exploit Hunt research (Task 4) showed CVE-2023-38408 has zero public exploits anywhere on Exploit-DB, isn't in CISA KEV, and needs a narrow precondition (agent forwarding to an attacker-controlled host) that SecurePoint itself doubts applies here. Finding 009, by contrast, is exploitable *today* with off-the-shelf tools (Hydra, Medusa) against multiple live hosts, with no lockout to slow it down. A misconfiguration with no CVSS score is, in this case, more practically dangerous right now than the CVE carrying a 9.8.


## 4. Finding 016 - Medical Device HTTP Interface Accessible

**Host**: Multiple - 13 Philips IntelliVue patient monitors (10.10.3.10–32)

**Misconfiguration**: The monitors' web management interfaces (and the HL7 port, 2575, used for patient data exchange) are reachable from the entire internal network, with no authentication beyond whatever the network layer provides - which, on a flat network, is none.

**Why No CVE**: The web interface is an intentional, vendor-designed feature - these devices are *meant* to expose a management interface so clinical engineering can configure them. There's no software flaw being triggered; the devices work exactly as built. The failure is architectural - deploying them with no network-layer access control - not a defect in the monitors' code.

**Severity Assessment**: I'm rating this **Critical**, above the scanner's "Medium." A CVSS-style score would normally treat "unauthenticated management interface" as a moderate confidentiality/integrity issue, but that framework is built for IT systems, not devices strapped to a patient. This is a life-safety system, reachable by anyone on the network, with zero authentication standing between an attacker and a live vital-signs feed or its configuration.

**Cross-Reference 1x00**: This is essentially a network-wide version of **Task 3, Observation 4** (Medical IoT), which examined one such monitor directly and concluded: *"an unpatched medical device reachable from anywhere on the network due to the lack of segmentation... This is the observation where a cybersecurity gap becomes a life-safety issue."* Finding 016 confirms via network scan that this isn't an isolated device - it's all 13 monitors, plus (per Finding 010) 7 infusion pumps with unchanged default credentials, exhibiting the same exposure pattern.

**Comparable CVE Risk**: **CVE-2020-25165 (BD Alaris infusion pump vulnerability, Finding 010, CVSS 7.5)** - the closest possible comparison, since it's the *other* medical IoT finding in this same report. CVE-2020-25165 at least requires triggering a specific firmware-level session-handling flaw to cause a denial of service. Finding 016 requires nothing but network reachability - no firmware version dependency, no exploit, just an open connection to a device that should never have been reachable in the first place. The misconfiguration has a lower bar to abuse than the CVE it sits next to in the same report.

## 5. Finding 015 - Synology DSM Web Interface Accessible

**Host**: NAS-01 (10.10.2.41), backup storage

**Misconfiguration**: The Synology DSM management interface (ports 5000/5001) is reachable from the entire internal network rather than being restricted to administrative IPs, and backup data on the device is stored unencrypted.

**Why No CVE**: DSM's web interface is meant to be reachable so administrators can manage the NAS remotely - that's the product working as designed. The problem is the absence of any restriction on *who* can reach it (no firewall rule, no IP allow-list), which is a deployment choice, not a bug in Synology's code.

**Severity Assessment**: I'm rating this **High**, above the scanner's "Medium." The reason isn't the exposure alone - it's what this specific box represents: per the Task 4 control inventory (**C-010**), NAS-01 holds the *only* backup copy of six critical VMs (ehr-srv-01, ehr-db-01, billing-srv-01, ad-dc-01, file-srv-01, web-srv-01), with no offsite copy and no tested full recovery. Ransomware operators routinely go after backup infrastructure first, specifically to remove the recovery option before encrypting production. An exposed, unencrypted, reachable-from-anywhere admin panel on the org's sole backup device is a single point of failure for the entire recovery plan.

**Cross-Reference 1x00**: Matches Marcus's raw notes precisely: *"backup-srv-01: Veeam runs nightly backups to a local NAS. The NAS is in the same server room, on the same network, same rack. If we get ransomware, we lose both. I mentioned offsite/cloud backup to James. Budget was denied."* It also lines up with **G-001** from the Task 5 control gap analysis - every detective control in the environment is a local, unforwarded log with no real-time alerting, meaning if someone did reach this exposed admin interface, nothing would notice while it was happening.

**Comparable CVE Risk**: **CVE-2021-44790 (mod_lua RCE, Finding 001, CVSS 9.8)** - the single highest-scored finding in the report. That CVE threatens billing-srv-01, one application server. Finding 015 threatens the one thing every other recovery plan in the organization depends on. A misconfiguration that endangers the ability to recover from *any* incident - including the one caused by the report's own top CVE - deserves to be weighed on the same scale, even without a CVSS number attached.


## 6. Finding 025 - DNS Zone Transfer Enabled

**Host**: ad-dc-01 (10.10.2.20)

**Misconfiguration**: The DNS server permits zone transfers (AXFR) to any requester, not just its designated secondary DNS servers, allowing anyone to pull a complete dump of internal hostnames, IP addresses, and inferred network structure in a single unauthenticated query.

**Why No CVE**: Zone transfer is a legitimate, standard DNS protocol feature - every DNS server supports it, because it's how secondary servers legitimately replicate zone data from a primary. The software isn't malfunctioning; the server is simply configured to answer that request from anyone instead of a restricted list of secondary servers. That's an access-control configuration choice, not a flaw in the DNS server software.

**Severity Assessment**: **Low** (agreeing with the scanner) - on its own, this doesn't compromise anything directly. But it punches above its weight as a force-multiplier: it hands an attacker a free, accurate map of the entire internal network in one query.

**Cross-Reference 1x00**: This connects to the network-topology material Marcus captured in his draft network diagram (`content/report.md`, Document 5) - the flat `10.10.0.0/16` layout with no VLANs that this finding effectively hands to any outsider for free. It also reflects **G-002** from Task 5 (no administrative detective control) - nothing would flag a full zone dump as anomalous activity, since there's no monitoring layer positioned to notice it.

**Comparable CVE Risk**: **CVE-2021-43798 (Grafana path traversal, Finding 029, CVSS 7.5)**. Both are reconnaissance/disclosure findings that set up a later attack rather than compromising anything by themselves. But zone transfer arguably gives more per query: Grafana's path traversal still requires the attacker to guess or know which file to request; a zone transfer hands over every internal hostname and IP in the environment - including, almost certainly, hostnames that reveal which boxes are domain controllers, database servers, and medical device controllers - with zero guessing required.


## Why "Our CVE Scan Shows Nothing Critical, We Are Secure" Is Dangerous False Assurance

A CVE-based scan report is fundamentally a count of *known, catalogued software defects* - and every automated tool built around it (dashboards, ticket auto-prioritization, executive summaries) inherits that same blind spot, because they sort and filter by CVSS score, and a finding with no CVE has no CVSS score to sort by. That's exactly how this scan could show "only 4 Critical" while simultaneously containing an unauthenticated path from any compromised host directly to the organization's PHI database (Finding 003), a well-worn, tool-automated technique for relaying network access into full domain compromise (Finding 007), a life-safety medical device fleet reachable with zero authentication (Finding 016), and an exposed, unencrypted admin panel on the *only* backup copy the organization has (Finding 015) - none of which register as "Critical" on a CVE-counting dashboard, precisely because none of them have a CVE to be counted under. This isn't hypothetical: the assignment's own examples make the point better than any scan could - 28,000 MongoDB databases ransomed in 2017 and 100 million records exposed at Capital One in 2019 both happened with a clean CVE scan, because both were pure configuration decisions, not software bugs. A CVE count measures how many patches a vendor needs to ship; it says nothing about how a system was actually deployed, and misconfigurations are frequently *cheaper and faster to fix* than any CVE on this same report - no vendor patch cycle, no downtime, sometimes a single config-file line - yet they get systematically deprioritized because they don't feed the same automated pipelines that CVEs do. Treating "no Critical CVEs" as "we are secure" hands an organization's actual risk picture over to whichever findings happened to get an ID number assigned to them, and ignores everything else standing wide open.
