# The Cost-Benefit Analysis

## Control 1: Network Segmentation

CIS Control Reference: 12
Annual Cost: $60,000 (hardware/licensing $20,000 + labor $40,000)
Risk(s) Addressed: Ransomware (Risk 1), Backup destruction (Risk 3), Medical device incident (Risk 5) — all amplified by the flat network
ALE Reduction: $200,000 (blast-radius containment across the three risks)
Net Value: $200,000 − $60,000 = **$140,000**
Verdict: Justified
Recommendation: Implement — the single highest-value control available, since it reduces multiple risks at once.

## Control 2: MFA on VPN and Administrative Accounts

CIS Control Reference: 6
Annual Cost: $5,000 (labor only — licenses already included in existing O365 E3)
Risk(s) Addressed: Ransomware (Risk 1) — credential-based domain compromise
ALE Reduction: $80,000
Net Value: $80,000 − $5,000 = **$75,000**
Verdict: Justified
Recommendation: Implement — cheapest control on this list relative to its impact.

## Control 3: SIEM Deployment (Wazuh)

CIS Control Reference: 8, 13
Annual Cost: $15,000 (labor only — open-source, no license fee)
Risk(s) Addressed: Billing server recurrence (Risk 4); faster detection reduces impact across all risks
ALE Reduction: $90,000
Net Value: $90,000 − $15,000 = **$75,000**
Verdict: Justified
Recommendation: Implement — directly closes the detection gap that let the January cryptominer run for two weeks.

## Control 4: Offsite Backup Replication

CIS Control Reference: 11
Annual Cost: $8,000 (cloud storage + setup)
Risk(s) Addressed: Backup destruction (Risk 3)
ALE Reduction: $85,000
Net Value: $85,000 − $8,000 = **$77,000**
Verdict: Justified
Recommendation: Implement — one of the best returns on this entire list, and closes a single point of failure the organization currently has zero protection against.

## Control 5: EDR Upgrade (Sophos Intercept X, All Endpoints)

CIS Control Reference: 10
Annual Cost: $40,000 (full-fleet licensing — workstations + servers)
Risk(s) Addressed: Billing server recurrence (Risk 4); general malware defense
ALE Reduction: $70,000
Net Value: $70,000 − $40,000 = **$30,000**
Verdict: Justified, but the least efficient of the clearly-justified controls
Recommendation: Implement, but consider scoping to servers only first (workstations already have baseline Sophos) — a cheaper partial version could capture most of this value for a fraction of the cost.

## Control 6: Dedicated Firewall for Westside Clinic

CIS Control Reference: 12
Annual Cost: $5,000 (hardware)
Risk(s) Addressed: Ransomware (Risk 1) — closes one VPN-pivot path
ALE Reduction: $15,000
Net Value: $15,000 − $5,000 = **$10,000**
Verdict: Marginal
Recommendation: Implement — small in scale, but cheap and still cost-positive.

## Control 7: 24/7 Outsourced SOC

CIS Control Reference: 13, 17
Annual Cost: $100,000 (managed service contract)
Risk(s) Addressed: Broad detection/response improvement across all 5 risks
ALE Reduction: $70,000 — most of this value is already captured more cheaply by Controls 3 and 5
Net Value: $70,000 − $100,000 = **−$30,000**
Verdict: **Not Justified**
Recommendation: Reject. This is the control that costs more than the risk it reduces — a textbook case of a good-sounding control that isn't worth it once cheaper alternatives (in-house SIEM + EDR) are already in place.

## Control 8: Full Medical Device Network Isolation with Dedicated Monitoring

CIS Control Reference: 12, 4
Annual Cost: $30,000
Risk(s) Addressed: Medical device incident (Risk 5)
ALE Reduction: $33,000 (most of Risk 5's value is already captured by Control 1's general segmentation — this is the *incremental* value on top of that)
Net Value: $33,000 − $30,000 = **$3,000**
Verdict: Marginal
Recommendation: Implement only after Control 1 is in place — depends entirely on segmentation existing first, and its standalone value is thin.

---

## Cost-Benefit Summary Table (Ranked by Net Value)

| Rank | Control | Cost | ALE Reduction | Net Value | Verdict |
|---|---|---|---|---|---|
| 1 | Network segmentation | $60,000 | $200,000 | **$140,000** | Justified |
| 2 | Offsite backup replication | $8,000 | $85,000 | **$77,000** | Justified |
| 3 | SIEM (Wazuh) | $15,000 | $90,000 | **$75,000** | Justified |
| 3 | MFA | $5,000 | $80,000 | **$75,000** | Justified |
| 5 | EDR upgrade (full fleet) | $40,000 | $70,000 | **$30,000** | Justified |
| 6 | Westside firewall | $5,000 | $15,000 | **$10,000** | Marginal |
| 7 | Medical device isolation | $30,000 | $33,000 | **$3,000** | Marginal |
| 8 | 24/7 outsourced SOC | $100,000 | $70,000 | **−$30,000** | Not Justified |

**Fitting within the $120,000 annual budget**: Segmentation + backup + SIEM + MFA together cost $88,000 and capture the four largest net-value wins ($367,000 combined). Adding the EDR upgrade ($40,000) would push total spend to $128,000 — over budget. This exact tension is what Task 8 resolves.
