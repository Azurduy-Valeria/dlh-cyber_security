# The ALE Workshop

The 5 highest-priority real MedDefense risks, combining gaps, vulnerabilities, and threats identified across all prior projects.

---

## Risk 1: Ransomware Encrypts EHR/Domain-Wide Systems

**Source**: Gap G-006 (flat network) + Finding 007 (LDAP relay) + Finding 001/002 (billing RCE chain) — TA-1 Ransomware affiliate

**Asset**: Domain-wide systems (ad-dc-01, ehr-srv-01, billing-srv-01, file-srv-01)
**Asset Value (AV)**: $2,000,000
- Replacement/recovery cost: $200,000
- Revenue loss during downtime: $50,000/day × 10 days = $500,000
- Regulatory penalties: $500,000
- Reputation/patient trust impact: $800,000

**Exposure Factor (EF)**: 60% — reasoning: a domain-wide ransomware event doesn't destroy every asset completely, but it disables most operations and exposes most data for the duration of the incident.

**SLE** = $2,000,000 × 0.60 = **$1,200,000**

**ARO**: 0.25 (once every 4 years) — reasoning: healthcare is a heavily-targeted sector industry-wide, and MedDefense's flat network plus the already-demonstrated billing-server compromise make this a realistic, not rare, event.

**ALE** = $1,200,000 × 0.25 = **$300,000**

**Proposed Control**: Network segmentation + MFA on admin/VPN accounts
**Control Annual Cost**: $65,000
**Estimated ALE After Control**: EF drops to 35% (contained blast radius) and ARO drops to 0.10 (relay/lateral movement much harder) → New SLE = $700,000 → New ALE = **$70,000**
**Net Benefit** = $300,000 − $70,000 − $65,000 = **$165,000**

---

## Risk 2: Patient Database Breach via Exposed PostgreSQL

**Source**: Finding 003 (PostgreSQL open to `10.10.0.0/16`) — TA-1 Ransomware/extortion actor, TA-3 Insider

**Asset**: ehr-db-01 (EHR/PostgreSQL database)
**Asset Value (AV)**: $900,000
- Replacement/recovery cost: $150,000
- Revenue loss during downtime: $50,000
- Regulatory penalties: $400,000
- Reputation/patient trust impact: $300,000

**Exposure Factor (EF)**: 80% — reasoning: this exposure has essentially no barrier beyond a credential, so if reached, most or all patient records are exposed.

**SLE** = $900,000 × 0.80 = **$720,000**

**ARO**: 0.3 (once every ~3.3 years) — reasoning: this is one of the most trivially exploitable findings in the entire assessment — no exploit development needed, just reachability.

**ALE** = $720,000 × 0.30 = **$216,000**

**Proposed Control**: Restrict `pg_hba.conf` to ehr-srv-01 only (segmentation cost already counted under Risk 1)
**Control Annual Cost**: $2,000 (labor only)
**Estimated ALE After Control**: ARO drops to 0.05 (now requires compromising ehr-srv-01 first, a much higher bar) → New ALE = $720,000 × 0.05 = **$36,000**
**Net Benefit** = $216,000 − $36,000 − $2,000 = **$178,000**

---

## Risk 3: Backup Destruction via Exposed NAS-01

**Source**: Finding 015 (NAS-01 DSM exposed network-wide) + 1x00 control gap (no offsite copy) — TA-1 Ransomware affiliate, Kill Chain "Backup Destruction Endgame"

**Asset**: NAS-01 (sole backup copy of 6 critical VMs)
**Asset Value (AV)**: $700,000
- Replacement/recovery cost: $150,000
- Revenue loss (extended downtime with no recovery path): $300,000
- Regulatory penalties: $100,000
- Reputation/patient trust impact: $150,000

**Exposure Factor (EF)**: 70% — reasoning: if reached, backups are thoroughly destroyed or encrypted alongside production.

**SLE** = $700,000 × 0.70 = **$490,000**

**ARO**: 0.2 (once every 5 years) — reasoning: closely tied to the ransomware risk above, since backup destruction is typically a companion action, not an independent event.

**ALE** = $490,000 × 0.20 = **$98,000**

**Proposed Control**: Offsite/immutable cloud backup replication + DSM interface restriction
**Control Annual Cost**: $8,000
**Estimated ALE After Control**: EF drops to 15% (offsite copy survives even if the local NAS is destroyed) and ARO drops to 0.12 (interface restriction reduces reachability) → New SLE = $105,000 → New ALE = **$12,600**
**Net Benefit** = $98,000 − $12,600 − $8,000 = **$77,400**

---

## Risk 4: Billing Server Compromise Recurrence

**Source**: Findings 001/002/006/009/011/026 (EOL, misconfig cluster on billing-srv-01) — TA-2 Opportunistic/commodity attacker

**Asset**: billing-srv-01
**Asset Value (AV)**: $250,000
- Replacement/recovery cost: $50,000
- Revenue loss during downtime: $100,000
- Regulatory penalties: $50,000
- Reputation/patient trust impact: $50,000

**Exposure Factor (EF)**: 50%

**SLE** = $250,000 × 0.50 = **$125,000**

**ARO**: 0.5 (once every 2 years) — reasoning: this exact host has already been compromised once (the January cryptominer), so recurrence risk is rated higher than a first-time event elsewhere.

**ALE** = $125,000 × 0.50 = **$62,500**

**Proposed Control**: EDR on Linux servers + Ubuntu Pro/ESM patching
**Control Annual Cost**: $15,000
**Estimated ALE After Control**: ARO drops to 0.15 (patched + monitored) → New ALE = $125,000 × 0.15 = **$18,750**
**Net Benefit** = $62,500 − $18,750 − $15,000 = **$28,750**

---

## Risk 5: Medical Device Patient-Safety Incident

**Source**: Findings 004 (Windows XP MRI), 010 (BD Alaris default creds), 016 (Philips monitors exposed) — TA-2 Opportunistic worm, extortion-leverage actor

**Asset**: WS-RAD-01, BD Alaris pumps, Philips monitors
**Asset Value (AV)**: $1,200,000
- Replacement/recovery cost: $100,000
- Regulatory penalties (FDA/state reporting): $200,000
- Reputation/patient trust impact: $400,000
- Liability exposure (patient harm): $500,000

**Exposure Factor (EF)**: 40%

**SLE** = $1,200,000 × 0.40 = **$480,000**

**ARO**: 0.1 (once every 10 years) — reasoning: exposure is constant, but an incident that actually causes harm (not just reachability) is rarer than the underlying vulnerability itself.

**ALE** = $480,000 × 0.10 = **$48,000**

**Proposed Control**: Medical device VLAN isolation + default credential rotation
**Control Annual Cost**: $30,000
**Estimated ALE After Control**: EF drops to 25%, ARO drops to 0.05 → New SLE = $300,000 → New ALE = **$15,000**
**Net Benefit** = $48,000 − $15,000 − $30,000 = **$3,000**

---

## Risk Prioritization by ALE

| Rank | Risk | ALE |
|---|---|---|
| 1 | Ransomware (domain-wide) | $300,000 |
| 2 | Patient database breach (PostgreSQL) | $216,000 |
| 3 | Backup destruction (NAS-01) | $98,000 |
| 4 | Billing server recurrence | $62,500 |
| 5 | Medical device incident | $48,000 |

Notably, ranking by **Net Benefit** tells a different story than ranking by raw ALE: the PostgreSQL fix ($178,000 net benefit) and the backup fix ($77,400 net benefit) are actually the *most efficient* dollars to spend, even though ransomware has the highest raw ALE — because they're far cheaper to fix relative to the risk they close. This is exactly the tension Task 7 and Task 8 pick up next.
