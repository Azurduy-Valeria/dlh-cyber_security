# The Data Classification Matrix

## Part 1: Data Type Inventory

| Data | Regulated (PHI) | PII | Financial | IP | Legal | Operational |
|---|---|---|---|---|---|---|
| Patient medical records (EHR) | ✓ | ✓ | | | | |
| Medical images (DICOM) | ✓ | ✓ | | | | |
| Billing/claims records | ✓ *(billing reveals treatment)* | ✓ | ✓ | | | |
| Employee HR records | | ✓ | | | ✓ | |
| Vendor contracts (MedTech Solutions, SecurePoint, ClearView) | | | ✓ | | ✓ | ✓ |
| Network diagrams, firewall configs, asset inventory | | | | | | ✓ |
| Custom billing application code (mod_lua scripts) | | | | ✓ | | ✓ |
| Encryption keys, credentials, access control secrets | | | | | | ✓ *(but always Restricted — see Part 2)* |
| Incident response records, investigation notes | | | | | ✓ | ✓ |
| Security policies, risk register, audit evidence | | | | | ✓ | ✓ |
| Physician credentialing/licensing records | | ✓ | | | ✓ | |
| Public-facing hospital info (address, hours, visiting policy) | | | | | | ✓ |

Most sensitive data at MedDefense belongs to **multiple** types at once — billing records are simultaneously Financial, PII, and (because they reveal what treatment occurred) Regulated PHI, which is exactly why classification has to be driven by the most sensitive type present, not an average of all of them.

---

## Part 2: Classification Levels

| Level | Who Can Access | Encryption Required | If Exposed |
|---|---|---|---|
| **Public** | Anyone, no authentication | None required at rest (content is already public); TLS still used in transit for integrity/anti-tampering, not secrecy | No meaningful harm — it's already public information |
| **Internal** | All authenticated employees, not the general public | Not required at rest for low-sensitivity shares, but must sit behind authentication; TLS in transit recommended as defense-in-depth given the flat network | Minor reputational/competitive inconvenience — generally not legally consequential, but could reveal operational detail useful to an attacker |
| **Confidential** | Specific roles/departments with documented need (Finance sees financial reports, Legal sees contracts) | Required at rest (AES-256) and in transit (TLS 1.2+/VPN) | Real business harm — competitive disadvantage, vendor contract leverage lost, possible breach-of-contract exposure |
| **Restricted** | Named individuals only, strict need-to-know, MFA-gated | Required at rest with the strongest available protection (AES-256 + HSM/KMS-backed key management, Task 14) and TLS 1.2+/1.3 in transit | Severe — HIPAA breach notification obligations, regulatory fines, patient-safety risk, and (for keys/credentials specifically) potential cascading exposure of everything else those keys protect |

---

## Part 3: The Classification Decision Tree

```
Is it patient data (PHI)?
├── YES → RESTRICTED
└── NO → Does it contain financial account numbers, SSNs, or payment card data?
          ├── YES → CONFIDENTIAL (or RESTRICTED if it's also linked to a specific
          │         patient's identity — re-check the PHI question above)
          └── NO → Is it an encryption key, credential, or other access-control secret?
                    ├── YES → RESTRICTED (always — regardless of what it protects)
                    └── NO → Is it legal/contractual (contracts, litigation records,
                              compliance audit evidence)?
                              ├── YES → CONFIDENTIAL
                              └── NO → Is it internal operational data not meant for
                                        public view (schedules, memos, asset inventories,
                                        network diagrams)?
                                        ├── YES → INTERNAL
                                        └── NO → Is it explicitly intended for public
                                                  consumption (marketing material, public
                                                  website content, published hours/address)?
                                                  ├── YES → PUBLIC
                                                  └── NO → Default to INTERNAL and escalate
                                                            to the Data Owner for a final call
```

---

## Part 4: Sovereignty and Geolocation

Data sovereignty matters for healthcare because HIPAA's control, audit, and breach-notification obligations are tied to *where* data physically resides and *which* legal jurisdiction has authority over it — moving backups to an AWS region in a different state can expose that data to that state's own breach-notification laws (which may carry different timelines or thresholds than the state MedDefense operates in), and a different *country* entirely could subject the data to that nation's own government-access or surveillance laws, reaching PHI that should never have left US jurisdiction for a HIPAA-covered entity. **Encryption does not fully mitigate this concern** — it protects confidentiality if the data is accessed unlawfully, but it doesn't change whose courts have jurisdiction over the storage location, doesn't remove a legal compulsion order's ability to reach the cloud provider (unless MedDefense holds the only decryption key itself, exactly why Task 14 recommended a customer-managed key rather than the provider's default), and doesn't eliminate the underlying obligation to know and disclose exactly where PHI physically lives regardless of its encryption state.
