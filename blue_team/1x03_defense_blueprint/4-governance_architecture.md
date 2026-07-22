# The Governance Architecture

## Part 1: RACI Matrix

R = Responsible (does the work) · A = Accountable (answers for the outcome) · C = Consulted · I = Informed

| Activity | CEO | Deputy CISO (James) | IT Director (Sarah) | Dept Heads | Security Analyst (You) |
|---|---|---|---|---|---|
| Security budget approval | A | R | C | I | C |
| Vulnerability remediation | I | A | R | C | R |
| Incident response execution | I | A | R | C | R |
| Security policy approval | A | R | C | C | C |
| Risk acceptance decisions | A | R | C | C | C |
| Security awareness training | I | A | C | R | R |
| Vendor risk assessment | I | A | C | C | R |
| Audit coordination | I | A | C | I | R |

Notes on the reasoning:
- **CEO is Accountable only where the whole organization is bound** (budget, policy, risk acceptance) — everything else, James is Accountable as the acting security lead, since that's the entire point of giving him the role.
- **Sarah is Responsible for remediation/incident execution**, not James or the Security Analyst, because IT actually holds the keys to the systems — security sets priority, IT executes changes.
- **Dept Heads are Responsible for training completion** in their own teams, since that's the one activity where compliance genuinely depends on department-level enforcement, not central IT.

## Part 2: Role Definitions

**Data Owner** — Department Heads / Clinical Directors, for their respective clinical data domains (e.g., the Cardiology director owns cardiology patient data). They decide who legitimately needs access and why, because they understand the clinical necessity — security and IT shouldn't be making that call.

**Data Controller** — MedDefense Health Systems as the legal entity, represented operationally by the CEO (Dr. Patricia Morales). Under HIPAA, MedDefense is the "Covered Entity" — the organization that determines the purpose and means of processing patient data. This sits at the top regardless of who's Deputy CISO or IT Director.

**Data Processor** — Third-party vendors who handle patient data on MedDefense's behalf under contract, most clearly **MedTech Solutions** (the EHR maintenance vendor). They process data because MedDefense instructs them to, not on their own authority — which is exactly why Control 15 (Service Provider Management) matters and currently doesn't exist.

**Data Custodian/Steward** — Sarah Park's IT team (system administrators, the database administrator). They implement the technical safeguards day to day — backups, access provisioning, patching — without making policy decisions about who *should* have access. That decision belongs to the Data Owner.

## Part 3: The CISO Question

**Consequences of the vacancy**: exactly what James already described — no single point of accountability, so Sarah, James, and department heads each informally claim overlapping ownership with no tiebreaker. Security priorities compete against IT operational priorities with no executive weight behind them, and the Board has no single trusted advisor to answer "are we secure?" credibly.

**Recommendation: a virtual/fractional CISO (vCISO), not a full-time hire.** A full-time healthcare CISO typically costs $150,000–$250,000+ in salary alone — more than the entire $120,000 annual security budget this whole project has been built around. Hiring one would consume the budget meant for actual controls (segmentation, MFA, backups) before a single dollar reaches implementation. A vCISO arrangement (roughly $36,000–$60,000/year for part-time strategic engagement) provides the executive-level accountability, Board reporting credibility, and compliance expertise MedDefense currently lacks, while leaving most of the budget for the technical work. James stays as the operational day-to-day security lead; the vCISO provides governance, signs off on the risk register periodically, and gives the Board someone with the title and experience to actually answer for the program — at a fraction of the cost of a full-time seat MedDefense can't yet justify or afford.
