# The Control Selection

All 10 risks in the register have a "Mitigate" component, so all 10 get a control selection below.

---

**RISK-001** (Ransomware)
Selected Control: Network segmentation (VLANs) + MFA on admin/VPN accounts
CIS Control Mapping: 12.2 (secure network architecture); 6.3/6.4/6.5 (MFA for external, remote, and admin access)
NIST CSF Mapping: PR.AC, PR.PT
Control Type: Preventive
Control Category: Technical
Implementation Cost: $65,000
Expected Risk Reduction: ALE $300,000 → $70,000
Dependencies: None — this is the foundational control other controls build on.

**RISK-002** (PHI database breach)
Selected Control: Restrict `pg_hba.conf` to ehr-srv-01 only + firewall rule
CIS Control Mapping: 3.3 (configure data access control lists); 12.2
NIST CSF Mapping: PR.AC, PR.DS
Control Type: Preventive
Control Category: Technical
Implementation Cost: $2,000
Expected Risk Reduction: ALE $216,000 → $36,000
Dependencies: Can be done immediately on its own, but is strengthened once RISK-001's segmentation is also in place.

**RISK-003** (Backup destruction)
Selected Control: Offsite/immutable cloud backup replication + DSM interface restriction
CIS Control Mapping: 11.3 (protect recovery data); 11.4 (isolated recovery instance)
NIST CSF Mapping: RC.RP
Control Type: Corrective (offsite copy) + Preventive (interface restriction)
Control Category: Technical
Implementation Cost: $8,000
Expected Risk Reduction: ALE $98,000 → $12,600
Dependencies: None required, but benefits from RISK-001's segmentation limiting who can reach NAS-01 at all.

**RISK-004** (Billing server recurrence)
Selected Control: Scoped EDR (servers) + Ubuntu Pro/ESM enrollment
CIS Control Mapping: 10.1/10.2 (anti-malware); 7.3 (automated OS patching)
NIST CSF Mapping: PR.PT, DE.CM
Control Type: Preventive + Detective
Control Category: Technical
Implementation Cost: $15,000
Expected Risk Reduction: ALE $62,500 → $18,750
Dependencies: Works better once centralized logging (SIEM, part of the funded program) exists to aggregate its alerts.

**RISK-005** (Medical device compromise)
Selected Control: Default credential rotation (funded now) + full VLAN isolation with dedicated monitoring (deferred)
CIS Control Mapping: 4.7 (manage default accounts); 12.2 (deferred piece)
NIST CSF Mapping: PR.AC; PR.PT (deferred piece)
Control Type: Preventive
Control Category: Technical
Implementation Cost: $2,000 now; $30,000 deferred
Expected Risk Reduction: Partial now (~$8,000 of the $33,000 potential); remainder deferred
Dependencies: **Full medical device isolation requires network segmentation (RISK-001) to be implemented first** — the clearest sequencing dependency in this entire set.

**RISK-006** (Vendor breach)
Selected Control: Vendor risk assessment and management process
CIS Control Mapping: 15.1 (service provider inventory); 15.2 (management policy)
NIST CSF Mapping: GV.SC (Govern — Supply Chain Risk Management)
Control Type: Preventive
Control Category: Administrative
Implementation Cost: ~$5,000 (not yet funded)
Expected Risk Reduction: Not yet realized — control is unfunded
Dependencies: None — can be implemented independently and immediately once budgeted.

**RISK-007** (Lost/stolen mobile device)
Selected Control: MDM enrollment (encryption + remote wipe)
CIS Control Mapping: 3.6 (encrypt data on end-user devices)
NIST CSF Mapping: PR.DS, PR.AC
Control Type: Preventive
Control Category: Technical
Implementation Cost: ~$3,000–5,000/year (not yet funded)
Expected Risk Reduction: Would drop EF from ~50% toward near 0% — best untapped ALE reduction per dollar in the unfunded set
Dependencies: None

**RISK-008** (No incident response plan)
Selected Control: Written, tested incident response plan
CIS Control Mapping: 17.1 (designate IR personnel); 17.2 (contact info); 17.3 (reporting process)
NIST CSF Mapping: RS.RP
Control Type: Corrective/Administrative — reduces damage after an incident starts, doesn't prevent one
Control Category: Administrative
Implementation Cost: ~$2,000–5,000 (labor only; cheapest gap in the whole register)
Expected Risk Reduction: Not a standalone ALE — reduces the impact/duration of every other risk in this register
Dependencies: None — should be done immediately regardless of anything else.

**RISK-009** (Physical intrusion)
Selected Control: Role-based badge access + camera coverage for the server room corridor
CIS Control Mapping: Outside the 18 CIS Controls' technical scope (physical security sits in a separate domain); closest conceptual tie is PR.AC's physical-access subcategory
NIST CSF Mapping: PR.AC
Control Type: Preventive (badge) + Detective (camera)
Control Category: Physical
Implementation Cost: ~$10,000–15,000 (not yet funded)
Expected Risk Reduction: Drops Likelihood from 2 toward 1
Dependencies: None

**RISK-010** (HIPAA assessment gap)
Selected Control: Commission a formal HIPAA Security Rule assessment
CIS Control Mapping: Outside CIS's technical scope — this is a compliance/audit activity
NIST CSF Mapping: GV.OV (Govern — Oversight) / ID.RA (Identify — Risk Assessment)
Control Type: Detective — finds gaps, doesn't itself prevent anything
Control Category: Administrative
Implementation Cost: ~$15,000–25,000 (not yet funded)
Expected Risk Reduction: Reduces likelihood of an adverse audit finding, not a technical ALE
Dependencies: None, though its findings will likely generate new risk register entries once complete.

---

## Control Dependency Map

```
Network Segmentation (RISK-001)
  ├──▶ strengthens ──▶ PostgreSQL access restriction (RISK-002)
  ├──▶ strengthens ──▶ Offsite backup protection (RISK-003)
  └──▶ MUST PRECEDE ──▶ Full medical device isolation (RISK-005, deferred piece)

SIEM / Centralized Logging (funded, supports RISK-004)
  ├──▶ strengthens ──▶ Scoped EDR alerting (RISK-004)
  └──▶ should precede ──▶ Any future 24/7 SOC investment (rejected this cycle)

MFA (RISK-001)
  └──▶ pairs well with ──▶ Vendor risk management once vendor accounts are in scope (RISK-006)

Incident Response Plan (RISK-008)
  └──▶ no prerequisite — do this first; improves the effectiveness of every other control's incident-time value

Independent items (no sequencing dependency on anything above):
  Vendor risk management (RISK-006) · MDM enrollment (RISK-007) ·
  Physical security controls (RISK-009) · HIPAA assessment (RISK-010)
  — their absence is a budget gap, not a sequencing gap.
```

The one hard dependency worth remembering: **network segmentation has to happen before full medical device isolation makes sense** — trying to isolate medical devices onto a dedicated VLAN before the surrounding network architecture exists just recreates a smaller version of the same flat-network problem.
