# Hardware Security and Key Management

## Part 1: Technology Comparison

| Technology | What It Is | What It Protects | Typical Cost | Typical Deployment |
|---|---|---|---|---|
| **TPM** | A dedicated chip (or firmware equivalent, fTPM) built into most modern motherboards, designed to generate/store keys and measure boot integrity | Disk-encryption keys (BitLocker), platform boot attestation, device-bound credentials | Effectively free — bundled into nearly every modern PC/server already | Laptops and workstations (full-disk encryption unlock), server secure boot |
| **HSM** | A dedicated, tamper-resistant device (physical appliance or cloud service) where key material never leaves in plaintext — all crypto operations happen inside it | High-value keys: database master keys, CA signing keys, payment keys — things where compromise is catastrophic | Dedicated physical/cloud-dedicated HSMs: $1,000+/month; **shared/multi-tenant cloud KMS with HSM-backed keys: ~$1–2/key/month** | Regulated industries, CAs, and any org protecting a small number of its highest-value keys |
| **Secure Enclave** | An isolated execution environment inside the CPU/SoC itself, cryptographically separated even from the device's own OS/kernel | Biometric data, device unlock keys, app secrets — protected even from a fully compromised OS | Built into the chip already, no separate purchase | Mobile devices (phones), increasingly used in cloud "confidential computing" offerings |
| **KMS (Software)** | A centralized key management service (HashiCorp Vault, cloud-native key vaults) for storage, access control, rotation, and audit logging — not necessarily backed by dedicated hardware, though many cloud offerings are | Application secrets, API keys, database encryption keys — replaces scattered config-file secrets with one audited, access-controlled system | Low — often bundled with a cloud subscription, or open-source with just infrastructure cost | Cloud-native applications, any org centralizing secrets without buying dedicated hardware |

---

## Part 2: MedDefense Key Management Plan

| Key | Where Stored | Who Has Access | Rotation | If Compromised | If Lost |
|---|---|---|---|---|---|
| **Patient DB master key** (ehr-db-01, T13) | Cloud KMS/HSM-backed vault — never on ehr-db-01 or ehr-srv-01 | IT Director (Sarah) + Database Administrator (custodian); Security Analyst has audit-only visibility | Annually, or immediately on suspected compromise — via key "re-wrapping" (rotate the wrapping key, not a full data re-encrypt) | Rotate/re-wrap immediately, audit all access logs for the key's exposure window, assess whether decryption actually occurred to scope breach notification | **Catastrophic without escrow** — the entire database becomes unrecoverable; mandatory key escrow, split across ≥2 custodians, before this control goes live |
| **Backup volume key** (NAS-01, T12) | Separate key vault, NOT on NAS-01 (per Task 12's own reasoning) | IT Director (Sarah) + System Administrator; Security Analyst has audit visibility | Annually, or via issuing a new encrypted volume for future backups rather than re-encrypting in place | Assume all data on that volume is exposed; rotate for future backups immediately | Catastrophic without escrow — same reasoning as the DB key |
| **Portal TLS private key** (web-srv-01, T10) | On web-srv-01 itself (normal for a TLS server — it needs local access to complete handshakes), strict file permissions, TPM-backed if the hardware supports it | IT Sysadmin (installs); Security Analyst (audit) | Every 90 days, naturally, as a side effect of ACME/Let's Encrypt renewal (Task 10/17) | Follow Task 9 Part 3's sequence: new key, CA revocation, new CSR, install, verify, notify | Low impact — just generate a new key/CSR; nothing stored is lost, since this key protects traffic in motion, not data at rest |
| **VPN tunnel keys** (site-to-site IPSec, FortiGate) | On the FortiGate device at each site — inherent to how IPSec/IKEv2 gateways operate | IT Network team configures; Security Analyst reviews periodically | Annually at minimum, immediately if either endpoint's security is in question (especially the Westside consumer router, given its unknown patch history) | Rotate the PSK/certificate on both tunnel ends immediately, audit VPN traffic logs for the exposure window | Reconfigure with a new key on both ends — a brief connectivity gap, not a data-loss event |

---

## Part 3: The HSM Decision

**Estimated cost**: MedDefense would need HSM-backed protection for a small number of keys initially — the DB master key, the backup volume key, and 1–2 others — call it **5 keys**. At $1–2/key/month, that's **$5–10/month, or $60–120/year**, using a shared/multi-tenant cloud KMS tier (not a dedicated single-tenant HSM appliance, which would run $1,000+/month and isn't proportionate to MedDefense's scale or budget).

**Relevant risk**: **RISK-002** from the 1x03 Risk Register (patient database breach via exposed PostgreSQL) — ALE of **$216,000/year** before remediation, dropping to an estimated **$36,000/year** after the network-level access restriction already recommended in 1x03. That residual $36,000 matters here specifically: **encryption alone doesn't close this risk if the key sits next to the data it protects.** If MedDefense implements database TDE (Task 13) but stores the master key in a config file on ehr-db-01 or ehr-srv-01, an attacker who reaches either host the same way Finding 003 already demonstrated is possible finds the key sitting right there — the encryption becomes a speed bump, not a barrier, exactly the failure mode this task's own context warns about.

**Is the investment justified?** Overwhelmingly yes, and it isn't close. $60–120/year against a residual risk still measured in the tens of thousands of dollars is one of the most lopsided cost-benefit ratios in this entire project — cheaper than a single monthly software subscription, for a control that determines whether the database encryption MedDefense is about to build actually means anything under a real compromise. This is the rare case where the math doesn't require careful judgment calls to reach a clear answer.
