# NIST CSF 2.0 — MedDefense Current Profile

*(Note: `nist-csf-reference.txt` wasn't actually in the project folder, so this uses the standard public NIST CSF 2.0 structure — 6 functions — from general knowledge.)*

---

### Function: Govern

**Current Level**: Partial
**Evidence**: A Deputy CISO (James, acting) and a documented password policy (1x00 control C-016) exist, but the CISO seat itself is vacant, there's no formal risk management process, and no HIPAA Security Rule assessment has ever been performed despite Legal claiming compliance with no evidence.
**Key Gaps**: No one has clear, exclusive authority over security decisions — James, Sarah, and department heads all informally claim overlapping ownership.
**Target Level (6 months)**: Managed — achievable by formally defining roles (Task 4's RACI), adopting CSF/CIS as the documented strategy, and either hiring or contracting CISO-level oversight.

---

### Function: Identify

**Current Level**: Partial
**Evidence**: Before this project, IT had only a partial, self-described-incomplete asset list in ServiceDesk with items marked `[UNVERIFIED]` for over a year. The 1x00 project built the first real asset inventory and criticality assessment MedDefense has ever had.
**Key Gaps**: No ongoing *process* to keep the inventory current — it was a one-time snapshot, not a maintained system of record.
**Target Level (6 months)**: Managed — the hard part (building the first inventory) is done; turning it into a maintained, repeatable process is realistic in 6 months.

---

### Function: Protect

**Current Level**: Partial
**Evidence**: The 1x02 scan found 42% of all findings were misconfigurations (Task 7) — no MFA anywhere except one personal account, no antivirus on any Linux server (Gap G-004), default credentials on medical devices, and zero network segmentation. Some protections exist (a firewall, Sophos AV on Windows workstations, a password policy) but coverage is inconsistent and full of gaps.
**Key Gaps**: No network segmentation at all — the single amplifier behind nearly every other finding in the vulnerability assessment.
**Target Level (6 months)**: Managed — realistic if the Task 8 budget priorities (MFA, segmentation, EDR) are actually funded and implemented.

---

### Function: Detect

**Current Level**: Not Implemented
**Evidence**: Marcus's own notes describe zero real monitoring capability — logs exist locally per host but nothing is centralized, nothing is alerted on, and the January cryptominer ran for two weeks generating three tickets that were each closed as a hardware issue before anyone identified it as malware.
**Key Gaps**: No centralized logging or alerting exists at all — detection currently depends entirely on a human noticing something is wrong, after the fact.
**Target Level (6 months)**: Partial — deploying a SIEM (Task 7) is realistic in 6 months for a 2-person team, but reaching a fully Managed, tuned detection capability in that window is not.

---

### Function: Respond

**Current Level**: Not Implemented
**Evidence**: No formal incident response plan exists anywhere in the organization. The January incident was handled ad hoc — James, Sarah, and Marcus improvised for four days with no documented playbook.
**Key Gaps**: No designated incident response process or communication plan — the outcome of the next incident depends entirely on who happens to be available.
**Target Level (6 months)**: Managed — writing and testing a basic IR plan (CIS Control 17, already IG1) is low-cost and fast; this is one of the most achievable gains in the whole roadmap.

---

### Function: Recover

**Current Level**: Partial
**Evidence**: Nightly Veeam backups exist for six critical VMs, but the NAS sits in the same server room/rack as production with no offsite copy, and a full recovery has never been tested (1x00 control C-010).
**Key Gaps**: No offsite/isolated backup copy — a single incident (fire, flood, ransomware) can take out production and its only backup simultaneously.
**Target Level (6 months)**: Managed — offsite cloud backup replication (Task 7) is a funded, achievable fix within 6 months.
