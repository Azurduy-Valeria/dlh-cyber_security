## 1. FortiGate FortiOS

### Primary finding: CVE-2024-21762

**Source**: NVD — https://nvd.nist.gov/vuln/detail/CVE-2024-21762

**CVE**: CVE-2024-21762

**Affected Product**: The MedDefense FortiGate 100F firewall (per the 1x00 environment summary, this device terminates both the perimeter and the site-to-site VPN tunnels to Westside and HQ). The vulnerability affects FortiOS 6.0.0–6.0.17, 6.2.0–6.2.15, 6.4.0–6.4.14, 7.0.0–7.0.13, 7.2.0–7.2.6, and 7.4.0–7.4.2 (and equivalent FortiProxy versions) — essentially every FortiOS release line in active use before early 2024.

**Why the Scan Missed It**: The FortiGate never appears as a scanned asset anywhere in the 31 findings — the report's target was `10.10.0.0/16`, the internal subnets, not the perimeter device managing them. OpenVAS also had no credentials for it (the methodology notes only mention SSH/domain credentials for servers and workstations); firmware version fingerprinting on a firewall's SSL-VPN portal typically requires either authenticated access to the device or a plugin written specifically to probe that portal externally — neither was in scope here.

**CVSS / Severity**: 9.8 (Critical) — `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`. CWE-787 (Out-of-bounds Write — the same weakness class as Finding 001 in the main scan). Published February 9, 2024; added to CISA's KEV catalog the same week with a 7-day remediation deadline for federal agencies — one of the fastest KEV turnarounds in the catalog's history, reflecting how immediately this was weaponized in the wild.

**MedDefense Impact**: This is a pre-authentication remote code execution vulnerability in the SSL-VPN component. If MedDefense's FortiGate 100F has SSL-VPN enabled (a very common default for remote-access or as a public-facing management surface) and is running an unpatched firmware version, an attacker on the internet could gain code execution directly on the device that sits at the top of the entire network — the same firewall that terminates the Westside and HQ VPN tunnels and fronts the DMZ web server. Given everything downstream is on one flat `10.10.0.0/16` broadcast domain with no segmentation, compromising this single device would be strictly worse than any finding in the entire 31-item scan report — it's the one asset positioned to see and touch all the others.

### Bonus finding, given how current it is: CVE-2025-59718 / CVE-2025-59719

**Source**: CISA KEV catalog + Rapid7/The Hacker News reporting, December 2025–January 2026

**CVE**: CVE-2025-59718 (and companion CVE-2025-59719)

**Why worth flagging separately**: this one is barely seven months old relative to today. It's a SAML signature-verification bypass (CWE-347) affecting FortiOS, FortiProxy, FortiSwitchManager, and FortiWeb — an attacker sends a forged SAML response to `/remote/saml/login`, the device fails to verify the signature, and logs the attacker in as an administrator with no valid credentials at all. Fortinet patched it December 9, 2025; CISA confirmed active exploitation and added it to KEV one week later (December 16, 2025) with a 7-day deadline. Rapid7 observed attackers authenticating as admin and immediately downloading the device's full configuration file — which typically contains hashed credentials for every local account on the box.

**CVSS / Severity**: 9.8 (Critical).

**MedDefense Impact**: Same reasoning as above, but sharper — this isn't a code-execution bug requiring exploit development, it's an authentication bypass that hands over the admin panel directly, and it's currently being exploited against internet-facing FortiGate management/SSO interfaces right now, as of this writing.

**Recommendation (both findings)**: Confirm the FortiGate 100F's current firmware version and patch to a release beyond both vulnerable ranges immediately — this is a higher-priority action than anything in the original 31-finding scan, since a compromise here has a blast radius covering the entire environment. Disable the SSL-VPN portal and FortiCloud SSO login entirely if remote access isn't actually required through them; if it is, restrict access to specific source IPs rather than leaving it open to the whole internet. This device should also be added to whatever authenticated scanning scope MedDefense builds going forward — it was invisible to this entire assessment.


## 2. Microsoft 365 / Entra ID

### Primary finding: CVE-2025-55241 (Entra ID Cross-Tenant Impersonation via Actor Tokens)

**Source**: Multiple vendor/security research writeups (SentinelOne, Hive Pro, CyberMaxx), cross-referenced against Microsoft's own advisory — https://www.sentinelone.com/vulnerability-database/cve-2025-55241/

**CVE**: CVE-2025-55241

**Affected Product**: Microsoft Entra ID (the identity backbone underneath MedDefense's O365 E3 subscription, which the 1x00 control inventory confirms is used org-wide, $432,000/year).

**Why the Scan Missed It**: The scan's methodology notes explicitly exclude cloud services — O365 is named directly as out of scope. Beyond that, this class of vulnerability couldn't have been found by *any* network vulnerability scanner even if O365 had been in scope: it's a server-side flaw in Microsoft's own identity backend (an undocumented internal "Actor token" mechanism accepted by a legacy Azure AD Graph API without properly validating which tenant issued it), not something exposed on MedDefense's network or detectable by fingerprinting a service version. This is exactly the "logical vulnerability that requires context, not a portscan" category the assignment context describes.

**CVSS / Severity**: 9.8–10.0 depending on source (Microsoft's own advisory rated it 10.0), `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`. CWE-287 (Improper Authentication). Discovered/reported July 14, 2025, fixed by Microsoft September 4, 2025 — already patched tenant-side by the time of writing, but worth understanding regardless (see below).

**MedDefense Impact**: This vulnerability let an attacker impersonate *any user in any Entra ID tenant worldwide*, including Global Administrators, while bypassing MFA and Conditional Access policies and leaving minimal audit trail. Since Microsoft fixed this server-side (no customer patch was possible or required), MedDefense's actual exposure window was determined entirely by Microsoft's own timeline, not anything MedDefense controlled — a sobering illustration of the shared-responsibility model: for a flaw like this, the "patch" isn't something MedDefense's IT team could have applied even if they'd known about it. Given James Chen's dual-hatted role and the complete absence of any documented cloud-service inventory or monitoring (per the 1x00 Known Unknowns list), there's no indication anyone would have checked Entra ID sign-in logs for anomalous cross-tenant activity during the exposure window even if it had been exploited.

**Recommendation**: The direct fix required nothing from MedDefense (Microsoft-side), but the incident is a strong argument for two things this organization currently lacks per the 1x00 assessment: a documented cloud service inventory (only O365 is confirmed; other departmental cloud use is suspected but undocumented) and any process for reviewing Entra ID/Azure AD sign-in and audit logs for anomalies. Retroactively reviewing Entra ID sign-in logs for the exposure window (July–September 2025) for any cross-tenant or unexplained Global Administrator activity would be a reasonable, low-cost verification step.

### Complementary finding: OAuth Device Code Phishing (attack technique, not a CVE)

**Source**: Cloud Security Alliance research note, March 2026 — https://labs.cloudsecurityalliance.org/research/csa-research-note-oauth-device-code-phishing-m365-20260325-c/

**Why included**: the assignment explicitly allows "a vulnerability or attack technique," and this one is worth flagging precisely *because* it isn't a patchable bug — it's abuse of a legitimate OAuth feature (RFC 8628 device code flow), meaning no vendor fix will ever make it go away. As of this campaign, it had hit 340+ Microsoft 365 organizations, harvesting access tokens by having the victim complete a real Microsoft sign-in (including their own MFA challenge) on the attacker's behalf. The resulting refresh tokens persist even through a password reset.

**MedDefense Impact**: Given the 1x00 assessment already documents that MFA exists on exactly one account org-wide (James Chen's personal setup) and phishing/security awareness training completion is uneven (94% HQ, 71% Central, 58% Westside, with no healthcare-specific content), MedDefense is in a materially worse position against this technique than an org with phishing-resistant MFA and consistent training. MFA wouldn't even be the backstop here — the victim completes it themselves.

**Recommendation**: Because this can't be "patched," the mitigation is policy-level: block or tightly restrict the OAuth device code flow via Conditional Access unless there's a specific business need for it, and add device-code-phishing recognition to security awareness training given the existing training gaps already identified.


## 3. Synology DSM 7

**Source**: NVD — https://nvd.nist.gov/vuln/detail/CVE-2024-10441, corroborated by Synology's own advisory Synology-SA-24:20

**CVE**: CVE-2024-10441

**Affected Product**: NAS-01, the Synology backup device (Finding 015 confirms it's running DSM, reachable on ports 5000/5001).

**Why the Scan Missed It**: Finding 015 only checked whether the DSM *management interface was reachable* — it never fingerprinted the actual DSM build/patch version running behind that interface. That's a meaningful difference: OpenVAS flagging "the door is open" isn't the same as checking "which version of the software is on the other side of the door," and the latter would require either authenticated access to the NAS (not listed as available in the methodology notes) or a plugin specifically built to version-fingerprint DSM's system plugin daemon externally.

**CVSS / Severity**: 9.8 (Critical), `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`. CWE-116 (Improper Encoding or Escaping of Output) in DSM's system plugin daemon — allows unauthenticated remote code execution. Affects DSM before 7.1.1-42962-7, 7.2-64570-4, 7.2.1-69057-6, and 7.2.2-72806-1. Originally disclosed at Pwn2Own 2024, with Synology's advisory first published November 5, 2024 and full technical details released March 19, 2025 (Synology deliberately delayed public details to give customers time to patch).

**MedDefense Impact**: This is the same NAS the 1x00 control inventory already flags as a single point of failure — the sole backup copy of six critical VMs (ehr-srv-01, ehr-db-01, billing-srv-01, ad-dc-01, file-srv-01, web-srv-01), co-located with production in the same server room, with no offsite copy and no tested full recovery (C-010). Finding 015 already established that the DSM interface is reachable from the entire internal network. If NAS-01 is also running a pre-patch DSM build, an attacker doesn't even need the interface's login credentials — CVE-2024-10441 is unauthenticated RCE. Combined, this is the single most severe realistic path to destroying MedDefense's only backup copy in the entire environment, and it wouldn't require breaching anything else first.

**Recommendation**: Confirm NAS-01's exact DSM build number immediately and patch to 7.2.2-72806-1 or later (or the equivalent fixed build for whatever major version is installed) as a same-priority action alongside restricting network access to the DSM interface (Finding 015's own recommendation). Given this device's role as the organization's sole backup, patching it and verifying its actual version should not wait for a routine patch cycle.

