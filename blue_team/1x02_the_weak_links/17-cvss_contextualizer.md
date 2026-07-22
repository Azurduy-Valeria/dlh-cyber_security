## Finding 001/002 — CVE-2021-44790 / CVE-2019-0211 (billing-srv-01)

**CVSS Base Score**: 9.8 / 7.8

**Factor 1 — Asset Criticality**
- Asset: billing-srv-01, billing/claims processing
- CIA Rating: C-High, I-High, A-Medium
- Impact on Priority: Raises it — real financial/legal exposure, and this exact host already suffered a real compromise once.

**Factor 2 — Kill Chain Position**
- Appears in: KC-2 (Financial Server to Domain Takeover)
- Role: **Initial access point** — the first domino in a chain that ends at the domain controller.
- Impact on Priority: Raises it — this isn't an isolated bug, it's the entry step of the most dangerous chain in the report.

**Factor 3 — Exploitability**
- Exploitability Score: 4 (both CVEs — EDB-verified PoCs)
- CISA KEV: F001 No / F002 Yes (since 2021-11-03)
- Impact on Priority: Raises it — public, documented exploit code exists for both steps.

**Factor 4 — Compensating Controls**
- Existing Controls: None specific to this host. The control inventory shows no antivirus on Linux servers (Gap G-004) and no SSH key-only hardening here (that only exists on ehr-srv-01). Only generic firewall logging and nightly backup apply.
- Impact on Priority: Doesn't lower it — this host is essentially unprotected beyond the network perimeter.

**Environmental CVSS (recalculated)**
- Metrics applied: CR:High, IR:High, AR:Medium (from Factor 1); Exploit Code Maturity = Functional (from Factor 3, since PoCs exist but aren't confirmed weaponized-in-the-wild)
- Adjusted Score: **~9.5**. Interesting result: the base score already assumes full Confidentiality/Integrity/Availability impact, so criticality weighting can't push it any higher — CVSS caps the impact term at 0.915 specifically to stop scores running away. The number barely moves; what actually matters here is Factors 2 and 4.

**Final Priority**: **Critical**
**Justification**: The number alone (9.5) undersells this one. What makes it Critical is everything CVSS can't score: it's the first step of the most damaging attack path in the report (Factor 2), public exploit code exists for both steps (Factor 3), and there's essentially nothing standing in the way (Factor 4). Combined with the fact that this exact host has already been compromised once, this is as close to "certain to be re-exploited" as anything in this assessment.

---

## Finding 003 — PostgreSQL Unrestricted Access (ehr-db-01)

**CVSS Base Score**: None (misconfiguration). For this recalculation I built a reasonable stand-in vector — `AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:L` — giving an illustrative base of **~8.3**.

**Factor 1 — Asset Criticality**
- Asset: ehr-db-01, the PHI database itself
- CIA Rating: C-Critical, I-High, A-High
- Impact on Priority: Raises it sharply — this is the single most confidentiality-sensitive asset in the environment.

**Factor 2 — Kill Chain Position**
- Appears in: KC-1 and KC-2 (both chains end here)
- Role: **Final target** — the terminal objective almost every other finding in this report is one step from reaching.
- Impact on Priority: Raises it — being the destination of multiple chains matters more than being the entry point of one.

**Factor 3 — Exploitability**
- Exploitability Score: Not CVE-based, but functionally equivalent to a 5 — no exploit development needed at all, just reachability plus a credential.
- CISA KEV: N/A
- Impact on Priority: Raises it — arguably more reliable than a weaponized CVE, since there's no exploit code to fail or get detected.

**Factor 4 — Compensating Controls**
- Existing Controls: None specific. Gap G-006 in the control inventory names this exact exposure as the flagship example of a missing compensating control.
- Impact on Priority: Doesn't lower it at all.

**Environmental CVSS (recalculated)**
- Metrics applied: CR:High, IR:High, AR:High; Exploit Code Maturity = High (trivial reliability)
- Adjusted Score: **~8.7**, up from the illustrative 8.3 base — asset criticality genuinely pushes this one higher since it wasn't already maxed out.

**Final Priority**: **Critical**
**Justification**: No CVSS number exists for this at all, but every contextual factor points the same direction — it's the terminal target of multiple attack chains, on the most sensitive asset in the environment, with zero exploit barrier and zero compensating control. This is exactly the kind of finding a CVE-only dashboard would miss entirely.

---

## Finding 007 — LDAP Signing Not Required (ad-dc-01)

**CVSS Base Score**: None (misconfiguration). Stand-in vector `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N`, illustrative base **~9.1**.

**Factor 1 — Asset Criticality**
- Asset: ad-dc-01, primary domain controller
- CIA Rating: C-Critical, I-Critical, A-Critical
- Impact on Priority: Raises it to the maximum — this is the one asset whose compromise affects every other host's trust simultaneously.

**Factor 2 — Kill Chain Position**
- Appears in: KC-2 (Financial Server to Domain Takeover)
- Role: **Lateral movement enabler / privilege escalation step** — the technique that turns one compromised endpoint into domain-wide control.
- Impact on Priority: Raises it — this is a force-multiplier step, not a standalone bug.

**Factor 3 — Exploitability**
- Exploitability Score: Functionally a 5 — NTLM-relay-to-LDAP is executed with free, mature, widely-used tooling (`ntlmrelayx` and equivalents), no custom exploit development required.
- CISA KEV: N/A (not a CVE), but the technique class is a named step in real-world ransomware playbooks.
- Impact on Priority: Raises it.

**Factor 4 — Compensating Controls**
- Existing Controls: C-008 (AD password/lockout policy) and C-015 (AD event logging) exist, but neither one detects or blocks an NTLM relay attack — they cover a completely different attack vector.
- Impact on Priority: Doesn't lower it — the existing controls simply don't apply to this specific technique.

**Environmental CVSS (recalculated)**
- Metrics applied: CR:High, IR:High, AR:High; Exploit Code Maturity = High
- Adjusted Score: **~9.8**, up from the illustrative 9.1 base.

**Final Priority**: **Critical** (upgraded from the report's own "High," consistent with Task 6/10)
**Justification**: Universal-blast-radius asset, automated attack technique, and existing controls that don't address this specific vector at all. This is the one finding where "compensating controls exist" doesn't provide any real comfort, because none of them were built for this attack.

---

## Finding 031 — Ghostcat (ehr-srv-01)

**CVSS Base Score**: 9.8

**Factor 1 — Asset Criticality**
- Asset: ehr-srv-01, the EHR application server
- CIA Rating: C-Critical, I-Critical, A-Critical
- Impact on Priority: Raises it to the maximum.

**Factor 2 — Kill Chain Position**
- Appears in: KC-1 (Web Front Door to PHI Database)
- Role: **Lateral movement enabler** — the middle link connecting Finding 017's info disclosure to Finding 003's database exposure.
- Impact on Priority: Raises it — this is the pivot point of the single most complete, documented chain in the entire report.

**Factor 3 — Exploitability**
- Exploitability Score: 5 — verified, weaponized Metasploit module
- CISA KEV: Yes, since March 2022 (contrary to the finding's own outdated claim)
- Impact on Priority: Raises it.

**Factor 4 — Compensating Controls**
- Existing Controls: This is actually the *best*-controlled Linux host in the inventory — SSH key-only auth (C-005/006) and verbose auth logging (C-007) are both present here, unlike billing-srv-01.
- Impact on Priority: Doesn't lower it — none of those controls touch the web/AJP layer where this vulnerability actually lives. Good SSH hardening doesn't stop a Tomcat connector bug.

**Environmental CVSS (recalculated)**
- Metrics applied: CR:High, IR:High, AR:High; Exploit Code Maturity = High
- Adjusted Score: **9.8**, unchanged — already at the ceiling on both impact and exploit maturity.

**Final Priority**: **Critical**
**Justification**: Already maxed on every CVSS input, and Factor 4 shows why that matters — even a genuinely well-hardened host (by SSH standards) is fully exposed here because the existing controls were built for the wrong layer. This is the sharpest example in the set of why "some controls exist" doesn't mean "this asset is protected."

---

## Finding 004 — Windows XP End-of-Life (WS-RAD-01)

**CVSS Base Score**: up to 10.0 (MS08-067)

**Factor 1 — Asset Criticality**
- Asset: WS-RAD-01, MRI scanner control workstation
- CIA Rating: C-Medium, I-Critical, A-Critical (patient-safety driven, not data-driven)
- Impact on Priority: Raises it — the only asset in this set of 8 where physical harm, not data loss, is the dominant concern.

**Factor 2 — Kill Chain Position**
- Appears in: KC-3 (Legacy OS Wormable Cascade)
- Role: **Initial access AND self-propagation vector** — unusually, this vulnerability class can act as its own delivery mechanism with no attacker follow-through required.
- Impact on Priority: Raises it sharply — this is the only finding where Delivery and Exploitation nearly collapse into one automated step.

**Factor 3 — Exploitability**
- Exploitability Score: 5 for all three bundled CVEs
- CISA KEV: Yes for all three — and MS08-067 was re-added on 2026-05-20, roughly two months before this scan
- Impact on Priority: Raises it — a fresh, active-exploitation signal on an 18-year-old bug.

**Factor 4 — Compensating Controls**
- Existing Controls: **None.** Control gap G-006 names this exact device as the example of a known-unpatchable asset with zero compensating control.
- Impact on Priority: Doesn't lower it at all — there is nothing standing between this vulnerability and exploitation except luck.

**Environmental CVSS (recalculated)**
- Metrics applied: CR:Medium, IR:High, AR:High; Exploit Code Maturity = High
- Adjusted Score: **~9.8–10.0**, effectively unchanged — already at the ceiling.

**Final Priority**: **Critical**
**Justification**: The recalculated number can't go any higher, so the real priority signal here is entirely in Factors 2 and 4 — a wormable vulnerability class with zero compensating controls on a device that can't be patched, ever. This is the finding where the *absence* of any mitigating factor is itself the loudest signal.

---

## Finding 010 — BD Alaris Infusion Pumps

**CVSS Base Score**: 6.5 for the cited CVE (and per Task 15's research, the cited firmware version may already be patched — likely a false-positive attribution). Modeling the **default-credential issue** separately as its own illustrative vector (`AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`, since default admin access effectively grants full device control): illustrative base **~9.8**.

**Factor 1 — Asset Criticality**
- Asset: BD Alaris infusion pumps
- CIA Rating: C-Medium, I-Critical, A-Critical (dosage delivery = direct patient-safety impact)
- Impact on Priority: Raises it sharply.

**Factor 2 — Kill Chain Position**
- Appears in: standalone — doesn't currently chain into another finding, but sits at **Actions on Objectives** for an attacker who values patient-safety disruption over data theft.
- Impact on Priority: Raises it on its own merits, even without a documented chain.

**Factor 3 — Exploitability**
- Exploitability Score: The CVE itself is weak/disputed (see Task 15), but the default-credential path needs literally no exploit at all — the lowest possible skill bar in this entire report.
- CISA KEV: No
- Impact on Priority: Raises it — "no exploit needed" is not a mitigating factor, it's the opposite.

**Factor 4 — Compensating Controls**
- Existing Controls: **None** — same G-006 gap as the MRI workstation.
- Impact on Priority: Doesn't lower it.

**Environmental CVSS (recalculated)**
- Metrics applied (on the default-credential vector): CR:Medium, IR:High, AR:High; Exploit Code Maturity = High
- Adjusted Score: **~9.5**

**Final Priority**: **Critical**
**Justification**: Regardless of whether the cited CVE actually applies (Task 15 casts real doubt on it), the default-credential issue alone is enough to justify Critical — zero skill required, direct dosage-delivery impact, and no compensating control of any kind.

---

## Finding 016 — Philips IntelliVue Monitors Exposed

**CVSS Base Score**: None. Illustrative vector `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` (zero authentication = effectively full access), illustrative base **~9.8**.

**Factor 1 — Asset Criticality**
- Asset: Philips IntelliVue patient monitors
- CIA Rating: C-High (PHI-tagged vitals via HL7), I-Critical, A-Critical
- Impact on Priority: Raises it sharply.

**Factor 2 — Kill Chain Position**
- Appears in: standalone, but positioned at **Actions on Objectives** for both data theft (HL7/PHI interception) and patient-safety disruption (alarm/display tampering).
- Impact on Priority: Raises it — this is a rare finding that serves two different attacker objectives equally well.

**Factor 3 — Exploitability**
- Exploitability Score: Functionally 5 — zero authentication means there's nothing to defeat.
- CISA KEV: N/A
- Impact on Priority: Raises it.

**Factor 4 — Compensating Controls**
- Existing Controls: None (same G-006 gap).
- Impact on Priority: Doesn't lower it.

**Environmental CVSS (recalculated)**
- Metrics applied: CR:High, IR:High, AR:High; Exploit Code Maturity = High
- Adjusted Score: **~9.8**

**Final Priority**: **Critical**
**Justification**: Same pattern as the other medical IoT findings — no CVE, no compensating control, no authentication barrier, and dual-purpose value to an attacker (data theft or patient harm). The scanner's Medium label reflects only the "missing headers"-style framing it was built for; it has nothing to say about the patient-safety dimension.

---

## Finding 015 — NAS-01 DSM Exposed

**CVSS Base Score**: None cited in the scan, but Task 9's OSINT research connects this exposure to CVE-2024-10441 (unauthenticated RCE, CVSS 9.8, `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`).

**Factor 1 — Asset Criticality**
- Asset: NAS-01, the organization's sole backup copy
- CIA Rating: C-High, I-High, A-Critical (no offsite copy, no tested recovery)
- Impact on Priority: Raises it — this isn't just another server, it's the recovery plan for six other critical VMs.

**Factor 2 — Kill Chain Position**
- Appears in: KC-4 (Backup Destruction Endgame)
- Role: **Final target**, but for a different objective than Finding 003 — this is where an attacker goes to remove MedDefense's ability to recover, typically right before or during ransomware deployment.
- Impact on Priority: Raises it — the "recovery denial" objective is uniquely severe because it doesn't just cause a breach, it removes the safety net for every other incident too.

**Factor 3 — Exploitability**
- Exploitability Score: The exposure itself needs no exploit (reachable interface); if the DSM build is unpatched, CVE-2024-10441 adds unauthenticated RCE on top. I'd rate this Functional (0.97-equivalent) given the CVE is real but the exact build version wasn't confirmed by this scan.
- CISA KEV: Not confirmed for this specific CVE.
- Impact on Priority: Raises it.

**Factor 4 — Compensating Controls**
- Existing Controls: C-010 (Veeam backup) technically "exists" as a corrective control, but its own documentation admits the NAS sits in the same rack as production with no offsite copy — the control is real but structurally undermined by its own single point of failure.
- Impact on Priority: Doesn't meaningfully lower it — a backup control that can be destroyed alongside what it protects isn't much of a mitigating factor.

**Environmental CVSS (recalculated)**
- Metrics applied: CR:High, IR:High, AR:High; Exploit Code Maturity = Functional
- Adjusted Score: **~9.5**

**Final Priority**: **Critical**
**Justification**: The one finding on this list where the *documented* compensating control (C-010) actually makes things look better on paper than they are in practice — once you know the backup and production share a rack, "we have backups" stops being reassuring at all.

---

## Priority Comparison Table

| Finding | CVSS Base | Adjusted Priority | Change Direction |
|---|---|---|---|
| 001/002 | 9.8 / 7.8 | Critical | Same (already maxed — Factors 2/4 confirm rather than move it) |
| 003 | None | Critical | **Higher** (no CVSS number at all → Critical purely from context) |
| 007 | None | Critical | **Higher** (report labeled this High; context pushes it to Critical) |
| 031 | 9.8 | Critical | Same (already maxed, but Factor 4 shows *why* existing controls don't help) |
| 004 | up to 10.0 | Critical | Same (already maxed) |
| 010 | 6.5 (disputed) | Critical | **Higher** — despite a mediocre or possibly false-positive CVSS score, the default-credential issue independently justifies Critical |
| 016 | None | Critical | **Higher** (scanner said Medium; context says Critical) |
| 015 | None cited | Critical | **Higher** (scanner said Medium; context says Critical) |
