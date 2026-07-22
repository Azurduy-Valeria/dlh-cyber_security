# MedDefense Risk Register

**Scales used**: Likelihood 1=Rare(10+yr) · 2=Unlikely(5–10yr) · 3=Possible(2–5yr) · 4=Likely(1–2yr) · 5=Almost Certain(<1yr)
Impact 1=Negligible · 2=Minor · 3=Moderate · 4=Major · 5=Severe/Catastrophic

---

**RISK-001**
Risk Description: Ransomware encrypts EHR/domain-wide systems via the flat network and LDAP relay.
Risk Category: Operational
Threat Source: Ransomware affiliate (financially motivated)
Vulnerability: Findings 001, 002, 007
Affected Asset(s): ad-dc-01, ehr-srv-01, billing-srv-01, file-srv-01
Likelihood: 3 (Possible)
Impact: 5 (Severe)
Inherent Risk Score: 15
ALE: $300,000
Risk Owner: Deputy CISO (James Chen)
Treatment Decision: Mitigate
Treatment Justification: Highest ALE in the register and a proven, documented exploit chain — clearly worth the cost to reduce.
Planned Control(s): Network segmentation + MFA
Residual Risk: Likelihood 1, Impact 5 → Score 5
KRI: Count of unpatched critical CVEs on domain-facing hosts; failed-login spikes on ad-dc-01
Review Date: 2026-10-22

---

**RISK-002**
Risk Description: Patient database breach via PostgreSQL reachable from the entire network.
Risk Category: Compliance
Threat Source: Ransomware/extortion actor; insider
Vulnerability: Finding 003
Affected Asset(s): ehr-db-01
Likelihood: 3 (Possible)
Impact: 4 (Major)
Inherent Risk Score: 12
ALE: $216,000
Risk Owner: IT Director (Sarah Park)
Treatment Decision: Mitigate
Treatment Justification: Near-zero exploit barrier on the organization's most sensitive data store; fix is cheap (config change).
Planned Control(s): Database access restriction (pg_hba.conf) + network segmentation
Residual Risk: Likelihood 1, Impact 4 → Score 4
KRI: Number of hosts able to reach port 5432 (target: 1)
Review Date: 2026-10-22

---

**RISK-003**
Risk Description: Sole backup copy destroyed via exposed NAS-01, removing all recovery options.
Risk Category: Operational
Threat Source: Ransomware affiliate
Vulnerability: Finding 015
Affected Asset(s): NAS-01
Likelihood: 3 (Possible)
Impact: 4 (Major)
Inherent Risk Score: 12
ALE: $98,000
Risk Owner: IT Director (Sarah Park)
Treatment Decision: Mitigate
Treatment Justification: Cheapest fix on the list relative to how catastrophic losing the only backup would be.
Planned Control(s): Offsite/immutable backup replication + DSM interface restriction
Residual Risk: Likelihood 1, Impact 4 → Score 4
KRI: Days since last verified offsite replication/restore test
Review Date: 2026-10-22

---

**RISK-004**
Risk Description: Billing server compromise recurs (same class of incident as the January cryptominer).
Risk Category: Financial
Threat Source: Opportunistic/commodity attacker
Vulnerability: Findings 001, 002, 006, 009, 011, 026
Affected Asset(s): billing-srv-01
Likelihood: 4 (Likely)
Impact: 3 (Moderate)
Inherent Risk Score: 12
ALE: $62,500
Risk Owner: IT Director (Sarah Park)
Treatment Decision: Mitigate
Treatment Justification: This exact host has already been compromised once — recurrence risk is demonstrated, not theoretical.
Planned Control(s): Scoped EDR (servers) + Ubuntu Pro/ESM enrollment
Residual Risk: Likelihood 2, Impact 3 → Score 6
KRI: EDR alert count and CPU utilization anomalies on billing-srv-01
Review Date: 2026-10-22

---

**RISK-005**
Risk Description: Medical device compromise (MRI, infusion pumps, monitors) causes patient harm or care disruption.
Risk Category: Operational
Threat Source: Opportunistic worm; extortion-leverage actor
Vulnerability: Findings 004, 010, 016
Affected Asset(s): WS-RAD-01, BD Alaris pumps, Philips monitors
Likelihood: 2 (Unlikely)
Impact: 5 (Severe — patient safety)
Inherent Risk Score: 10
ALE: $48,000
Risk Owner: Clinical Engineering + Deputy CISO
Treatment Decision: Mitigate
Treatment Justification: Impact severity (patient safety) justifies action even though frequency is lower than other risks.
Planned Control(s): Default credential rotation (funded); full VLAN isolation (deferred to next cycle)
Residual Risk: Likelihood 1, Impact 5 → Score 5 (partial — full isolation not yet funded)
KRI: Number of medical devices still on factory-default credentials
Review Date: 2026-10-22

---

**RISK-006**
Risk Description: Third-party vendor (MedTech Solutions) breach exposes standing EHR maintenance access.
Risk Category: Compliance
Threat Source: Supply-chain/vendor-targeted attacker
Vulnerability: No specific 1x02 finding — process gap (no vendor risk management exists, CIS Control 15)
Affected Asset(s): ehr-srv-01, ehr-db-01 (via vendor access path)
Likelihood: 2 (Unlikely)
Impact: 4 (Major)
Inherent Risk Score: 8
ALE: $33,000
Risk Owner: Deputy CISO (James Chen)
Treatment Decision: Mitigate + Transfer (contractual risk allocation via Business Associate Agreement terms)
Treatment Justification: Some risk can be shifted contractually, but MedDefense still needs to know what access it granted.
Planned Control(s): Vendor risk assessment process (CIS Control 15) — **not yet funded in the current $110,000 program**
Residual Risk: Unchanged — control not yet implemented
KRI: Number of third-party vendors without a signed BAA/security assessment on file
Review Date: 2026-08-22 (sooner — needs budget planning attention)

---

**RISK-007**
Risk Description: Lost or stolen unmanaged physician iPad exposes cached patient data.
Risk Category: Compliance
Threat Source: Opportunistic theft/loss (not a targeted actor)
Vulnerability: No 1x02 finding — mobile devices were out of scan scope; 1x00 flagged management status as unclear
Affected Asset(s): ~25 physician iPads
Likelihood: 4 (Likely)
Impact: 3 (Moderate)
Inherent Risk Score: 12
ALE: $34,200
Risk Owner: IT Director (Sarah Park) + Department Heads
Treatment Decision: Mitigate
Treatment Justification: Low-cost fix (MDM enrollment) for a fleet-wide gap that's currently completely unaddressed.
Planned Control(s): MDM enrollment (encryption + remote wipe) — **not yet funded in the current $110,000 program**
Residual Risk: Unchanged — control not yet implemented
KRI: Number of mobile devices not enrolled in MDM
Review Date: 2026-08-22

---

**RISK-008**
Risk Description: A security incident takes longer to contain and costs more because no formal incident response plan exists.
Risk Category: Strategic
Threat Source: Applies to any actor — this is a response-capability gap, not an attack vector
Vulnerability: Organizational gap (G-003, 1x00) — not a scan finding
Affected Asset(s): Entire organization
Likelihood: 3 (Possible)
Impact: 4 (Major — amplifies the impact of every other risk in this register)
Inherent Risk Score: 12
ALE: Not separately quantified — this gap multiplies the ALE of Risks 001–007 above rather than standing alone
Risk Owner: Deputy CISO (James Chen)
Treatment Decision: Mitigate
Treatment Justification: Very cheap to fix (a documented plan) relative to how much it reduces the damage of every other incident.
Planned Control(s): Write and test a formal incident response plan (CIS Control 17) — **not yet funded in the current $110,000 program, but low-cost enough to fold in as a labor-only item**
Residual Risk: Unchanged until the plan is written and tested
KRI: Time-to-containment on the next tabletop exercise or real incident (currently untested/undefined)
Review Date: 2026-08-22

---

**RISK-009**
Risk Description: Physical intrusion or tampering via the unrestricted, unmonitored server room.
Risk Category: Operational
Threat Source: Insider or opportunistic physical intruder/tailgater
Vulnerability: 1x00 Physical Assessment, Observation 1 — not a 1x02 scan finding
Affected Asset(s): Server room (ad-dc-01, ehr-srv-01, ehr-db-01, NAS-01, and others)
Likelihood: 2 (Unlikely)
Impact: 4 (Major)
Inherent Risk Score: 8
ALE: $25,800
Risk Owner: IT Director (Sarah Park) + Facilities/ClearView Security
Treatment Decision: Mitigate
Treatment Justification: 1x00 already rated this Critical on its own; low-cost physical fixes (badge restriction, cameras) exist.
Planned Control(s): Role-based badge access + camera coverage for the server room corridor — **not in the current $110,000 technical program; needs a separate physical security budget line**
Residual Risk: Unchanged — control not yet implemented
KRI: Number of server room access events with no logged visitor/badge record
Review Date: 2026-08-22

---

**RISK-010**
Risk Description: Regulatory exposure from never having completed a formal HIPAA Security Rule assessment.
Risk Category: Compliance
Threat Source: N/A — regulatory/audit exposure, not an attack scenario
Vulnerability: 1x00 Known Unknowns — "no formal HIPAA Security Rule assessment has ever been performed"
Affected Asset(s): Entire organization (legal/regulatory standing)
Likelihood: 4 (Likely — this gap exists with certainty today; the question is when it's tested by an audit or incident)
Impact: 3 (Moderate — a compliance finding itself, before any breach, mainly drives remediation cost and legal exposure)
Inherent Risk Score: 12
ALE: Not separately quantified — this is the precondition that could turn Risks 002/006/007 into larger regulatory events than currently estimated
Risk Owner: Deputy CISO (James Chen) + General Counsel (David Park)
Treatment Decision: Mitigate
Treatment Justification: Relatively low one-time cost (an external assessment) for a foundational compliance gap Legal has claimed is closed with no evidence.
Planned Control(s): Commission a formal HIPAA Security Rule assessment — **not in the current $110,000 program; recommend a separate compliance budget line**
Residual Risk: Unchanged — assessment not yet performed
KRI: Days since last formal HIPAA Security Rule assessment (currently: never)
Review Date: 2026-08-22

---

## Risk Register Governance Note

This register is maintained by the Deputy CISO (James Chen), with the Security Analyst responsible for keeping individual entries current between formal reviews. It's reviewed in full monthly, with any risk whose KRI crosses its threshold (e.g., a mobile device found outside MDM, a new host reaching port 5432) triggering an immediate out-of-cycle review rather than waiting for the next scheduled date. An out-of-cycle review is also mandatory after any actual security incident, any new critical CVE affecting a listed asset (per the CISA KEV monitoring established in 1x02), or any change to the funded control set. When a KRI threshold is breached, the affected risk is escalated to James immediately, its Likelihood/Impact scores are reassessed on the spot rather than waiting for the monthly cycle, and — if the score materially increases — it's flagged for the next Board update regardless of where it falls in the normal review calendar.
