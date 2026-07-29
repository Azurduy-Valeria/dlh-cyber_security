# The Crypto Posture Audit

Every cell from Task 0's Data Protection Map marked Weak or Absent — 16 findings total (10 Absent + 6 Weak, of 18 assessable cells).

| ID | Data Category | State | Current Protection | Vuln. Ref (1x02) | Risk Ref (1x03) | Algorithm Assessment (T6) | Recommended Protection | Level (T13) | Key Mgmt (T14) | Priority |
|---|---|---|---|---|---|---|---|---|---|---|
| CRYPTO-001 | Patient records (EHR) | At Rest | None | Finding 003 | RISK-002 | N/A — no algorithm in use at all | AES-256-GCM (TDE) | Database | DB master key entry | **Immediate** |
| CRYPTO-002 | Patient records (EHR) | In Transit | Partial (SSL available, `hostnossl` still permitted) | Finding 003 | RISK-002 | SSL/TLS config itself not confirmed current — treat as inadequate until verified | Enforce `hostssl` only, TLS 1.2+ | N/A (transport config, not a data-at-rest level) | N/A | **Immediate** |
| CRYPTO-003 | Patient records (EHR) | In Use | None | — (organizational/process gap) | RISK-002 | N/A | Session timeout enforcement + screen lock (compensating control, not encryption per se) | N/A | N/A | Phase 1 |
| CRYPTO-004 | Financial/billing data | At Rest | None | Finding 001/002/006 | RISK-004 | N/A — no algorithm in use | AES-256-GCM (TDE) | Database | DB master key entry (same pattern as EHR) | **Immediate** |
| CRYPTO-005 | Financial/billing data | In Transit | None enforced | Finding 006 | RISK-004 | N/A | Enforce TLS for MySQL connections, restrict bind address | N/A (transport config) | N/A | **Immediate** |
| CRYPTO-006 | Financial/billing data | In Use | None (inferred) | — | RISK-004 | N/A | Session timeout enforcement (compensating control) | N/A | N/A | Phase 2 |
| CRYPTO-007 | Medical images (DICOM) | At Rest | None | Finding 024 | *No dedicated RISK-ID in the top-10 register — a gap worth flagging on its own* | N/A | AES-256-GCM | File | New key vault entry needed (not yet in T14 plan — add PACS key) | Phase 1 |
| CRYPTO-008 | Medical images (DICOM) | In Transit | None | Finding 024 | *Same gap as above* | N/A — DICOM TLS exists as a standard but isn't configured | Enable DICOM TLS (PS3.15) | N/A (transport config) | N/A | Phase 1 |
| CRYPTO-009 | Medical images (DICOM) | In Use | None (inferred) | — | *Same gap as above* | N/A | Access-control/session hardening on radiology workstations (compensating control) | N/A | N/A | Phase 2 |
| CRYPTO-010 | Credentials (AD) | At Rest | Weak (NTHash/MD4) | Finding 018 | RISK-001 | **Broken** — MD4-family, unsalted, no stretching (Task 6) | Disable NTLM where possible; Kerberos AES-256 only | N/A (authentication mechanism, not a storage level) | N/A | **Immediate** |
| CRYPTO-011 | Credentials (AD) | In Transit | Weak (LDAP unsigned) | Finding 007 | RISK-001 | N/A — not an algorithm weakness, a missing integrity control | Require LDAP signing | N/A | N/A | **Immediate** |
| CRYPTO-012 | Credentials (AD) | In Use | None | — (no Credential Guard or equivalent documented) | RISK-001 | N/A | Evaluate Credential Guard / ticket memory protection | N/A | N/A | Phase 2 |
| CRYPTO-013 | Backup data (NAS-01) | At Rest | None (available, unused) | Finding 015 | RISK-003 | N/A — Synology's own AES-256-CBC feature exists but isn't enabled | Enable native AES-256 shared-folder encryption, or LUKS-equivalent | Volume | Backup volume key entry | **Immediate** |
| CRYPTO-014 | Backup data (NAS-01) | In Transit | None (inferred) | Finding 015 | RISK-003 | N/A | TLS for replication traffic to/from the NAS | N/A (transport config) | N/A | Phase 1 |
| CRYPTO-015 | Email | In Use (message content) | None | — (out of 1x02 scan scope; identified via this project's own Task 0 audit) | *No 1x02/1x03 reference — cloud service, scan never looked here* | N/A | S/MIME or Microsoft Purview Message Encryption for messages containing PHI | Message-level (file-equivalent) | New key/certificate management needed (not yet in T14 plan) | Phase 2 |
| CRYPTO-016 | VPN traffic | In Transit | Weak (strong algorithm, untrusted endpoint) | Finding 014 | *No dedicated RISK-ID in the top-10 register* | AES-256/SHA-256/IKEv2 itself is Current per T6 — the algorithm isn't the problem | Replace the Westside consumer router (already recommended in 1x03's remediation roadmap) | N/A (endpoint hardware issue, not an encryption-level issue) | VPN tunnel key entry | Phase 1 |

---

## Posture Score

**16 of 18 assessable data-flow cells (89%) now have a clear, specific remediation path** — a documented recommended algorithm/control, an encryption level, and (where applicable) a key management plan — up from Task 0's baseline where those same 16 cells had nothing beyond "this is a gap." The remaining 2 cells (Email At Rest/In Transit) were already rated Adequate in Task 0 and need no remediation.

Worth flagging honestly: **CRYPTO-007, 008, 009, 015, and 016 have no corresponding entry in the 1x03 Risk Register's top 10** — meaning the risk-quantification work done in 1x03 didn't cover DICOM, email, or VPN-endpoint risk with a dedicated ALE calculation. That's a real gap in the *prior* project, not something this audit can retroactively fill in without fabricating numbers — it's flagged here as follow-up work for the risk register rather than papered over.

---

## Top 3 Crypto Risks (Ranked)

1. **CRYPTO-001 (Patient records at rest, ehr-db-01) + CRYPTO-002 (in transit)** — tied to RISK-002's $216,000 ALE, the single largest quantified risk in the entire 1x03 register, and the data category with the most severe regulatory/reputational consequence if breached.
2. **CRYPTO-010 / CRYPTO-011 (AD credentials at rest and in transit)** — tied to RISK-001 (the domain-compromise ransomware scenario, $300,000 ALE), and structurally the most dangerous because a credential compromise doesn't just expose one data category, it potentially unlocks every other one at once.
3. **CRYPTO-013 (Backup data at rest, NAS-01)** — tied to RISK-003 ($98,000 ALE), and uniquely severe because it's the failure mode that removes the *recovery option* for every other risk on this list simultaneously — the point Task 12's own design work was built around.
