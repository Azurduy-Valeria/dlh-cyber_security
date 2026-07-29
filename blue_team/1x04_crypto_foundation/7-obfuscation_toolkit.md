# The Obfuscation Toolkit

## Part 1: Technique Comparison

| Technique | What it does to the data | Can the original be recovered? | Healthcare use case |
|---|---|---|---|
| **Encryption** | Transforms data into ciphertext using a reversible mathematical algorithm and a key | **Yes** — by anyone holding the correct key | Protecting the EHR database at rest, so a stolen drive or root compromise doesn't expose plaintext patient records |
| **Hashing** | Transforms data into a fixed-size, one-way digest | **No** — by design, not reversible (only checkable: does a given input produce this same output?) | Storing password hashes in Active Directory (ideally with modern KDFs) so the actual password is never stored anywhere |
| **Tokenization** | Replaces sensitive data with a non-sensitive placeholder ("token") that has no mathematical relationship to the original | **Yes, but only via a separate lookup vault** — the token itself reveals nothing and can't be reversed mathematically | Billing systems processing credit card payments without storing the real card number anywhere in the application database |
| **Data Masking** | Partially or fully obscures data while preserving its format, based on who's viewing it | **Depends on masking level** — often irreversible in the view itself, but the full data still exists in the underlying system for authorized users | Displaying `XXX-XX-4321` instead of a full SSN to front-desk staff who only need to confirm identity, not process billing |
| **Steganography** | Hides an entire secret payload inside another, innocent-looking file | **Yes, but only by whoever knows a payload is hidden there and how to extract it** | Rarely a *protection* mechanism in healthcare — more relevant as a threat (Part 4) than a defense |

The key distinction the exam (and real design decisions) hinge on: **encryption and tokenization are both reversible, but only to someone with the right credential** (a key, or vault access) — **hashing is never reversible at all** — and **masking is a display-layer technique, not a storage-layer one** (the real data still exists somewhere; masking just controls what a given viewer sees).

---

## Part 2: MedDefense Tokenization Design (Billing/Credit Cards)

**What's tokenized**: The full 16-digit credit card number (PAN). The **token format** preserves the original's shape for compatibility with existing billing software — e.g., a token like `4111-XXXX-XXXX-9821` isn't quite right (that's masking, not tokenization); a true token looks like a random, unrelated 16-digit string in the same format, e.g. `8347-2910-6654-1183`, with no mathematical relationship to the real card number at all. The last 4 digits are sometimes preserved in the token for receipt/support purposes, since the last 4 alone aren't considered sensitive under PCI-DSS.

**Where the vault lives**: A dedicated, isolated token vault — **not** on billing-srv-01 itself, and specifically not in the same database as the tokens are used in day-to-day billing operations. Given MedDefense's existing infrastructure gaps (Task 0/1x02), this should be a separate, hardened system: encrypted at rest with AES-256, access-controlled via a short allow-list of service accounts (not general billing staff accounts), network-segmented so only the specific billing application component that needs to detokenize can reach it, and logged for every single lookup (a real audit trail, unlike most of what currently exists at MedDefense per Task 3/1x03's Detect-function gaps).

**If the vault is compromised**: real cardholder data is exposed — this is still a serious incident — but critically, **the tokens circulating everywhere else in MedDefense's systems (billing database, reports, logs, backups) remain meaningless** without also breaching the vault specifically. This contains the blast radius dramatically compared to the alternative.

**Tokenization vs. simply encrypting the card numbers**:
- **Advantage of tokenization**: the token itself carries *zero* information that can be reversed mathematically — even a full compromise of the billing database (exactly what happened in the January cryptominer incident) exposes only meaningless tokens, not real card data, without a *second*, separate breach of the vault. Encrypted data, by contrast, is still mathematically reversible by anyone who also gets the key — and keys have a way of ending up stored near the data they protect if a program isn't disciplined about it.
- **Advantage of encryption**: simpler to implement (no separate vault system to build, secure, and maintain) and doesn't require redesigning how the application handles card data end-to-end.
- **For MedDefense's specific situation** (a small IT team, PCI-DSS scope reduction being a real cost driver, and a documented history of at least one server-level compromise already reaching the database layer), **tokenization is the stronger choice** — it also meaningfully shrinks the scope of systems that fall under PCI-DSS compliance requirements, since tokenized data isn't considered cardholder data by the standard.

---

## Part 3: Data Masking Examples

| Data Field | Full Value | Nurse (clinical) | Billing Clerk | Reception |
|---|---|---|---|---|
| SSN | 987-65-4321 | `[Not displayed]` | `XXX-XX-4321` | `XXX-XX-4321` |
| Patient Name | Maria Gonzalez | `Maria Gonzalez` | `Maria Gonzalez` | `Maria Gonzalez` |
| Diagnosis | Type 2 Diabetes | `Type 2 Diabetes` | `E11.9` (ICD-10 code only) | `[Not displayed]` |

**Justifications:**
- **SSN / Nurse**: clinical care doesn't require an SSN at all — a nurse identifies and treats a patient by name, MRN, and DOB, so there's no clinical need-to-know here at any level.
- **SSN / Billing & Reception**: both need enough to confirm identity or process insurance/payment matching, but only the last 4 digits — the standard practice for identity verification without exposing the full number to staff who don't need it for a regulatory/financial filing purpose.
- **Patient Name**: this isn't sensitive in the same category as SSN or diagnosis — every role listed has a legitimate, immediate need to know who the patient is, so no masking is appropriate here.
- **Diagnosis / Nurse**: full clinical detail is required to provide correct care — this is the core need-to-know case for clinical staff.
- **Diagnosis / Billing Clerk**: billing operates on standardized codes (ICD-10), not narrative diagnoses — showing `E11.9` gives exactly what's needed to process a claim without exposing the clinical detail in plain language to non-clinical staff.
- **Diagnosis / Reception**: front-desk scheduling and check-in has no legitimate need to know a patient's diagnosis at all — full suppression is appropriate.

---

## Part 4: Steganography as a Threat Vector

DICOM medical images are large, routinely-transferred binary files with plenty of unused or low-significance bit space (e.g., pixel data's least-significant bits, or padding in the file structure) — exactly the kind of carrier steganography techniques are built to exploit. A malicious insider with legitimate access to the PACS server could embed exfiltrated patient records, credentials, or other sensitive data inside the pixel data of an otherwise-legitimate MRI or CT image, then transfer that image through completely normal, expected channels (referring the "study" to an external radiologist, a research collaboration, or a cloud backup) — traffic that looks identical to routine medical image sharing. This is harder to detect than traditional exfiltration because the carrier file's size, format, and destination are all completely unremarkable — a DLP tool watching for unusually large data transfers or suspicious file types would see nothing but a normal-sized DICOM image going to a normal-looking destination, with no indication that a second, hidden payload rides along inside it. The control from the 1x03 strategy most relevant here is the **SIEM/centralized logging and monitoring** (Task 7 of 1x03) — not because it can detect the steganographic payload itself (it generally can't), but because behavioral monitoring of *who* accesses *how many* studies and *how often* they're exported to external destinations can flag an insider's unusual access pattern well before anyone would ever inspect an individual image's hidden bit-level content.
