# First Impressions Summary: MedDefense Vulnerability Scan

## 1. Scan Metadata

- **Scanner**: OpenVAS 22.x (Greenbone Community Edition)
- **Target**: `10.10.0.0/16` - all internal subnets
- **Scan policy**: Full and Deep, authenticated where credentials were available
- **Requested by**: James Chen, Deputy CISO
- **Executed by**: SecurePoint Consulting (third-party)
- **Scan window**: Off-peak, 02:00–06:00, to minimize clinical impact
- **Hosts scanned**: 47 responsive hosts (out of an environment that, per the 1x00 asset registry, includes ~485 workstations, ~25 iPads, ~200 medical IoT devices, and roughly a dozen servers across three sites - so 47 is a small, mostly server/device-weighted slice, not the whole estate)

**Authentication coverage matters here.** Per the methodology notes:
- Linux servers (SSH) and Windows systems (domain creds) were scanned **authenticated**.
- Medical devices were scanned **unauthenticated** - no credentials were available for them.

That's not a minor footnote. It means the findings on billing-srv-01, ehr-srv-01, ad-dc-01, etc. reflect a deep, credentialed look (installed packages, config files, running services). The findings on the BD Alaris pumps and Philips monitors reflect only what's visible from the outside. **The medical device section of this report is very likely the tip of the iceberg, not the full picture.**

**What was explicitly NOT scanned** (from the methodology notes):
- Cloud services (O365)
- Mobile devices (iPads)
- Any asset offline during the scan window (unknown how many - could include the "possible second server" at Westside flagged as unverified back in 1x00)
- No active exploitation was attempted anywhere - every finding is based on version/config/banner detection, not a confirmed working exploit in this environment
- SecurePoint also flags a **5–10% expected false-positive rate** for OpenVAS in this configuration, and explicitly calls out Finding 020 as a likely false positive. So "31 findings" doesn't mean 31 confirmed problems - it means 31 things worth checking, at least one of which the vendor itself doubts.

## 2. Finding Distribution

| Severity | Count | % of total |
|---|---|---|
| Critical | 4 | 13% |
| High | 7 | 23% |
| Medium | 11 | 35% |
| Low | 5 | 16% |
| Informational | 4 | 13% |
| **Total** | **31** | 100% |

**Medium has the most findings (11), not Critical.** This matters for how I read the report: the "4 Critical" headline is the least representative number in the summary. Most of what's here is configuration hygiene (missing headers, weak encryption types, exposed management interfaces) rather than headline-grabbing RCEs. That doesn't mean the Mediums are unimportant - several of them (Kerberos weak encryption, DNS zone transfer, exposed NAS management interface) are exactly the kind of "boring" finding that becomes the pivot point in an actual intrusion.



## 3. Asset Heat Map

Counting individual findings per named host (not counting "Multiple" device-class findings, which I've called out separately below):

| Rank | Host | IP | Findings | Severities | Role (per 1x00 asset registry) |
|---|---|---|---|---|---|
| 1 | **billing-srv-01** | 10.10.2.15 | 6 | 2 Critical, 3 High, 1 Low | Billing/claims processing server (Ubuntu 18.04) |
| 2 | **ehr-srv-01** | 10.10.2.10 | 4 | 1 High, 1 Medium, 1 Low, 1 Info | EHR application server (Ubuntu 20.04) |
| 3 | **web-srv-01** | 10.10.2.50 | 4 | 1 High, 3 Medium | Public website + patient portal, DMZ (Ubuntu 20.04) |
| 4 | **ad-dc-01** | 10.10.2.20 | 3 | 1 High, 1 Medium, 1 Low | Primary domain controller (Windows Server 2019) |
| 5 | **ehr-db-01** | 10.10.2.11 | 1 | 1 Critical | EHR/PostgreSQL database - holds the actual PHI |

Honorable mentions that don't crack the top 5 by *count* but matter by *content*: **WS-RAD-01** (10.10.1.70, the MRI workstation) has only one finding, but it's a Critical EOL finding carrying three weaponized CVEs at once (EternalBlue, BlueKeep, MS08-067). **NAS-01** (backup storage) has one Medium finding, but it's the single point of failure for every backup in the organization.

Cross-referencing against the 1x00 environment summary confirms every host name resolves to a known asset - nothing here is a mystery host *except* two Informational findings (028, 029) on completely unregistered devices, discussed below.

**Observation**: billing-srv-01 isn't just "the most findings" - it's carrying nearly a fifth of all 31 findings by itself, and it's the same server that generated the January cryptomining incident referenced in the 1x00 root cause analysis. This is not a new problem; it's a server with a track record.


## 4. First Observations

**Critical findings are spread across three systems, not one - but two of them chain together on the same host.**
Findings 001 and 002 are both on billing-srv-01 and the report says so explicitly: an unauthenticated remote code execution (mod_lua buffer overflow, CVSS 9.8) followed by a local privilege escalation (CVSS 7.8) that the scanner notes turns a web shell into root. That's a complete, documented compromise path on one box, out of the box, in the report itself - I don't need to go do CVE research to see that this is the most urgent finding, I just need to read carefully.

**A second chain exists, quieter, on ehr-srv-01.**
Finding 017 (Medium) flags that Tomcat's default error page leaks version info and mentions the scanner "was unable to confirm" whether the AJP connector (port 8009, associated with Ghostcat/CVE-2020-1938) was active. Finding 031 is SecurePoint manually following up on exactly that and confirming: yes, AJP is active, Ghostcat is exploitable, and it's rated High. **This is the same severity-escalation pattern as the billing-srv-01 chain, just split across a Medium and a manually-added High instead of two Criticals** - a good reminder that the scanner's own severity label isn't the whole story, and that a "confirmed unable to verify" note is an invitation to keep looking, not a dead end.

**The most sensitive data store in the whole environment - the PHI database - has only one finding, and it's about as bad as a misconfiguration gets.**
ehr-db-01 (Finding 003) accepts PostgreSQL connections from the entire `10.10.0.0/16` range with no compensating network control. This isn't new information in isolation - the 1x00 control gap analysis (G-006) already flagged this exact exposure as evidence of a missing compensating control, since network segmentation has been "on the roadmap" for four-plus months with no progress. The scan doesn't reveal a new problem here so much as it puts a CVSS-adjacent number on a problem that was already known and already unaddressed.

**The flat network is the thread tying almost everything together.**
MySQL wide open on billing-srv-01 (006), the NAS management interface reachable org-wide (015), medical device web interfaces with no auth beyond the network layer (016), the domain controller reachable from any host (007) - none of these would be nearly as dangerous on a segmented network. The scan report keeps independently rediscovering the same root cause the 1x00 assessment already named.

**Medical devices show a pattern of "secure by omission," not by design.**
Four separate findings touch medical/clinical equipment: the MRI workstation (004, Windows XP with three weaponized RCEs), the infusion pumps (010, known vuln *plus* 7-for-7 unchanged default admin credentials), the patient monitors (016, unauthenticated web + HL7 interfaces exposed), and the PACS server's DICOM traffic (024, unencrypted, carrying patient identifiers). None of these were found because someone configured them insecurely on purpose - they were found because nothing was ever configured (or isolated) at all. Combined with the unauthenticated-only scan coverage on these devices, I'd treat this section of the report as a floor, not a ceiling.

**Two completely unregistered hosts turned up (028, 029).**
An unidentified Linux box on the server subnet running Jupyter and Cockpit, and an unidentified Linux box at Westside running a vulnerable Grafana instance - neither is in any IT inventory. This is exactly the "suspected shadow IT, not documented" gap the 1x00 Known Unknowns section flagged before this scan ever ran. It's a little unsettling to see the theoretical gap turn into two literal, un-owned IP addresses with open ports.

**SecurePoint editorialized inside the report, and that's worth noticing.**
Finding 020 is flagged by the vendor itself as a probable false positive given the operational context, and Finding 031 was added manually after a scanner limitation on Finding 017. That means this report already has a first pass of human judgment baked into it - it is not a raw tool dump. That's useful, but it's also a reason not to take every plugin hit at face value, and not to assume everything *without* such a caveat has been double-checked.

**Nothing in the report surprised me about *what* is broken - the 1x00 walk-through already named flat network, EOL systems, and unmanaged medical IoT as risks. What the scan adds is specificity: CVE numbers, CVSS scores, and confirmation that the theoretical risks are live, version-confirmed, and in several cases weaponized.**



## 5. Scan Limitations

What this report does **not** tell me:

- **No cloud coverage.** O365 - used by HQ staff per the 1x00 summary - is completely outside this scan's scope. Any HQ-side email/identity risk is invisible here.
- **No mobile device coverage.** The ~25 iPads used for physician rounds, whose management status was already an open question in 1x00, are not assessed at all.
- **No coverage of anything offline during the 02:00–06:00 window.** I don't know what that excludes - it could include the unverified "possible second server" at Westside, or devices that are only powered on during clinic hours.
- **Only 47 of an estate that's an order of magnitude larger were even responsive.** This scan covers servers, some medical devices, and a handful of named workstations - it is not a census of ~485 workstations, ~200 medical IoT devices, or three sites' worth of network gear.
- **No exploitation was attempted.** Every finding is inferred from version banners, config files, and authenticated checks - not from a working proof-of-concept run against this environment. "Vulnerable version detected" is not the same claim as "confirmed exploitable here," which is exactly why SecurePoint recommends manual verification before committing remediation resources.
- **No application-layer testing.** This is an infrastructure/configuration vulnerability scan. There's no indication anyone tested the EHR or billing application's own code for business-logic flaws, injection points, or access-control bugs - that would need a separate web app assessment.
- **No social engineering or phishing testing.** The human layer isn't covered by this instrument at all; that's a different kind of assessment.
- **Medical devices were scanned unauthenticated.** As noted above, this almost certainly understates what's actually present on those devices compared to the authenticated depth given to Linux/Windows servers.
- **Physical security is out of scope by definition** - this is a network vulnerability scan, not a facilities assessment (that ground was already covered separately in 1x00).

**Bottom line going in**: this is a partial, config/version-based snapshot of the server and known-device layer, taken once, without exploitation, with a vendor-acknowledged error rate - useful and clearly actionable, but not a complete picture of MedDefense's actual attack surface.
