# The Algorithm Landscape

## Symmetric

| Algorithm | Key Size | Primary Use Case | Status | Why Deprecated/Broken | MedDefense Usage |
|---|---|---|---|---|---|
| AES-128 | 128 bits | General-purpose bulk encryption | Current | — | Acceptable minimum; not currently used for PHI at rest |
| AES-192 | 192 bits | Rarely used middle tier | Current | — | Not used anywhere; no reason to adopt over 256 |
| AES-256 | 256 bits | Bulk encryption of regulated/sensitive data | Current | — | **Should be** the standard for EHR/billing DB, backups, DICOM at rest — currently used nowhere except the VPN tunnels |
| DES | 56 bits | Legacy — none appropriate today | **Broken** | 56-bit keyspace is brute-forceable in hours on commodity hardware | **Confirmed still enabled** for Kerberos on ad-dc-01/02 (1x02 Finding 018) |
| 3DES | 112 bits effective | Legacy transition algorithm | Deprecated | NIST deprecated in 2023; vulnerable to the Sweet32 birthday attack on 64-bit block size | Not confirmed in use, but should be explicitly disabled wherever it might still be negotiable |
| ChaCha20-Poly1305 | 256 bits | AEAD bulk encryption, especially on hardware without AES-NI | Current | — | Not used; viable alternative to AES-GCM for constrained medical devices |
| RC4 | 40–2048 bits | Legacy — none appropriate today | **Broken** | Keystream has statistical biases; practically exploitable to recover plaintext | **Confirmed still enabled** for Kerberos on ad-dc-01/02 (1x02 Finding 018) |
| Blowfish | 32–448 bits | Legacy block cipher; lives on inside bcrypt | Deprecated (as a general cipher) | 64-bit block size is vulnerable to birthday attacks on large data volumes | Not used directly, but its structure underpins bcrypt (see KDF section) |

## Asymmetric

| Algorithm | Key Size | Primary Use Case | Status | Why Deprecated/Broken | MedDefense Usage |
|---|---|---|---|---|---|
| RSA-2048 | 2048 bits | Key exchange, digital signatures, certificates | Current (floor) | NIST guidance suggests transitioning away by ~2030 | Used for the patient portal's certificate key today |
| RSA-4096 | 4096 bits | Higher-assurance signing/encryption | Current | — | Not used; ECC is a better choice at similar security with less overhead |
| ECC P-256 | 256 bits | TLS key exchange, signatures, constrained devices | Current | — | **Recommended** for the portal's next certificate and any new medical device crypto |
| ECC P-384 | 384 bits | Higher-assurance TLS/signing | Current | — | Good fit for internal CA root keys if MedDefense stands up its own PKI |
| Diffie-Hellman (finite-field) | 2048+ bits | Key exchange | Current, but largely superseded | Static/ephemeral DH without forward secrecy is weaker than ECDHE; slower | Used in the site-to-site VPN's IKEv2 (DH Group 14) |
| ECDHE | 256–384 bits (curve-based) | Key exchange with forward secrecy | **Current — preferred** | — | **Should be** the key exchange method for the patient portal's TLS config (Task 11) |

## Hash

| Algorithm | Output Size | Primary Use Case | Status | Why Deprecated/Broken | MedDefense Usage |
|---|---|---|---|---|---|
| MD5 | 128 bits | Legacy checksums only | **Broken** | Practical collisions demonstrated since 2004; unsuitable for any security purpose | Underlies NTHash (MD4-family) used by AD for NTLM — confirmed in the crypto audit notes |
| SHA-1 | 160 bits | Legacy — none appropriate today | **Broken** | Practical collision demonstrated (SHAttered, 2017) | Not confirmed in use; should be actively searched for and removed if found in any legacy config |
| SHA-256 | 256 bits | General-purpose hashing, integrity, signatures | Current | — | Used throughout this project's own hash/signature work; should be the default everywhere |
| SHA-512 | 512 bits | Higher-margin hashing, performance-favorable on 64-bit systems | Current | — | Not currently used; fine alternative to SHA-256 |
| SHA-3 | 224–512 bits (variable) | General-purpose hashing, different internal design than SHA-2 | Current | — | Not used; good defense-in-depth choice if diversifying away from the SHA-2 family matters |

## Key Derivation

| Algorithm | Output Size | Primary Use Case | Status | Why Deprecated/Broken | MedDefense Usage |
|---|---|---|---|---|---|
| PBKDF2 | Configurable (commonly 256 bits) | Password hashing, NIST/FIPS-approved contexts | Current | — | Not confirmed in use by any MedDefense application; good compliance-friendly option |
| bcrypt | Configurable (Blowfish-based) | Password hashing | Current | — | Not confirmed in use; solid, well-tested default |
| Argon2 | Configurable (memory-hard) | Password hashing, current best practice | **Current — preferred** | — | **Recommended** for any MedDefense application password storage (billing portal, internal tools) |
| scrypt | Configurable (memory-hard) | Password hashing, cryptocurrency wallets | Current | — | Not used; Argon2 is generally preferred today but scrypt is an acceptable alternative |

---

## MedDefense Crypto Gap Analysis

Comparing what MedDefense actually uses (per Task 0's Data Protection Map and 1x02 findings) against what it should use, at least 4 confirmed cases of deprecated/broken algorithms in active use:

1. **DES enabled for Kerberos authentication (ad-dc-01/02, 1x02 Finding 018)** — DES is flatly broken (56-bit keyspace). **Replacement: disable DES as a supported Kerberos encryption type entirely**, leaving only AES-256/AES-128, which are already supported alongside it.

2. **RC4 enabled for Kerberos authentication (same finding)** — RC4's biased keystream makes Kerberoasting practical against any account using it. **Replacement: disable RC4 as a supported Kerberos encryption type**, same action as above — both weak types should be turned off in the same Group Policy change (Task 3's Gap 007/Task 19 already scoped this exact fix).

3. **NTHash (MD4-family) as AD's default password storage** — confirmed directly in Sarah's audit notes. MD4 is unsalted and fast, making stolen hashes trivial to crack or replay (pass-the-hash). **Replacement**: this can't be fully swapped out without breaking NTLM compatibility for legacy systems, but MedDefense should (a) disable NTLM authentication everywhere Kerberos can be used instead, forcing AES-based Kerberos tickets as the actual authentication path, and (b) inventory exactly which legacy systems genuinely still require NTLM, rather than leaving it universally enabled "just in case," as the audit notes already flag as an undocumented assumption.

4. **TLS 1.0 supported on the patient portal (1x02 Finding 005)** — TLS 1.0 itself is a deprecated protocol (vulnerable to BEAST, POODLE, Lucky Thirteen), and supporting it forces the server to also keep older, weaker cipher suites negotiable alongside modern ones. **Replacement: disable TLS 1.0 and 1.1 entirely, support only TLS 1.2 and 1.3**, with a cipher suite restricted to AES-GCM/ChaCha20-Poly1305 and ECDHE key exchange — the exact hardened configuration built out in Task 11.

The common thread across all four: none of these are missing controls MedDefense never built — they're **legacy options left enabled "just in case," alongside a modern option that already exists.** In every case, the fix isn't "add new capability," it's "turn off the old one now that the new one is already there."
