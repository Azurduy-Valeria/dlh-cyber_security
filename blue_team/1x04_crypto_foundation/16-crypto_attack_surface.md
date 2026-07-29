# The Cryptographic Attack Surface

## Attack: TLS Downgrade

**Mechanism**: An on-path attacker interferes with the TLS handshake's protocol negotiation, blocking or corrupting the client's advertisement of newer protocol support, forcing both sides to fall back to the weakest protocol version they're still mutually willing to accept.
**MedDefense Vulnerability**: The patient portal (web-srv-01) supports TLS 1.0 alongside TLS 1.2 — the presence of the weak option is what makes a forced fallback possible at all.
**Evidence**: 1x02 Finding 005.
**Viable Today**: **Yes** — the vulnerable protocol is confirmed enabled, and MedDefense's flat network (Task 14, 1x02) makes achieving an on-path position from any compromised host realistic.
**Mitigation**: Disable TLS 1.0/1.1 entirely (Task 11's hardened config) — there's no partial fix; a downgrade attack can only force a fallback to a protocol the server still speaks.

---

## Attack: Collision Attack (MD5/MD4 family)

**Mechanism**: A collision attack finds two *different* inputs that produce the identical hash output. MD5's internal structure has been broken badly enough that constructing such colliding pairs is now computationally cheap and has been demonstrated practically outside the lab — most famously, the 2012 Flame malware used an MD5 chosen-prefix collision to forge a certificate that appeared validly signed by Microsoft.
**MedDefense Vulnerability**: AD's NTHash (built on MD4, a structurally similar predecessor to MD5) and Kerberos's RC4 encryption type, which relies on MD4/MD5-family hashing internally.
**Evidence**: 1x02 Finding 018; Sarah's crypto audit notes confirming NTHash/MD4 as AD's default.
**Viable Today**: **Partially** — generic collision attacks (find *any* two colliding inputs) are cheap and practical today; forging a collision against one *specific, already-existing* hash (a preimage-style attack) remains harder, even for MD4/MD5. The honest answer is: dangerous wherever MD5/MD4 is used for integrity or signing, less immediately catastrophic for directly reverse-engineering one specific stored NTLM hash.
**Mitigation**: Eliminate MD5/MD4 usage anywhere it still exists — for AD specifically, disable NTLM in favor of Kerberos with AES-256 only (same fix as Task 6's gap analysis), and audit for any other legacy MD5 usage in internal tooling or certificates.

---

## Attack: Birthday Attack (Theoretical)

**Mechanism**: The birthday paradox means finding *any* collision in an n-bit hash only requires roughly √(2ⁿ) attempts, not the full 2ⁿ — a dramatically smaller search space than intuition suggests. For MD5 (128-bit), that's about 2⁶⁴ operations (≈1.8×10¹⁹) — large, but reachable with modern hardware, and practically demonstrated. For SHA-256 (256-bit), the bound is 2¹²⁸ operations — a number so large it stays out of reach of any realistic computing power (Task 3's own math).
**MedDefense Vulnerability**: Anywhere MD5 or a similarly short hash is still relied upon for integrity — directly relevant to AD's MD4-based NTHash and RC4 Kerberos tickets, both confirmed present.
**Evidence**: Task 3's own collision-space calculations; 1x02 Finding 018.
**Viable Today**: **Yes**, specifically wherever a short/broken hash is still in use — this is precisely why the recommendation throughout this project has been to migrate everything to SHA-256 or better, which pushes the birthday bound back out to computationally infeasible territory.
**Mitigation**: Use hash functions with output length large enough that the birthday-bound search space stays infeasible — SHA-256 minimum, consistent with Task 6's Algorithm Reference Table.

---

## Attack: Kerberoasting

**Mechanism**: An attacker requests a Kerberos service ticket for any service account, which returns a ticket encrypted with that account's password-derived key; if RC4 encryption is available, the attacker takes that ticket offline and brute-forces it with commodity hardware, since RC4's key derivation (MD4-based) is fast enough to test millions of guesses per second with no further contact with the domain controller.
**MedDefense Vulnerability**: RC4 and DES are both still enabled as supported Kerberos encryption types on ad-dc-01/ad-dc-02, alongside AES-256/128.
**Evidence**: 1x02 Finding 018 (confirmed directly by the scan).
**Viable Today**: **Yes, unambiguously** — this is one of the most well-worn, tool-automated techniques in modern offensive security, and the exact precondition (RC4 enabled) is confirmed present.
**Mitigation**: Disable RC4 and DES as supported Kerberos encryption types, leaving only AES-256/AES-128 — a single Group Policy change (already scoped in 1x03's remediation plan).

---

## Attack: On-Path/MITM on Unencrypted Channels

**Mechanism**: An attacker positioned anywhere on the network path between two communicating systems can passively read, or actively modify, any traffic that isn't encrypted and authenticated — no cryptographic barrier exists to detect or prevent the interception at all.
**MedDefense Vulnerability**: DICOM imaging traffic between the MRI workstation, radiology workstations, and pacs-srv-01 (transmitted entirely in cleartext), and PostgreSQL connections that `pg_hba.conf`'s `hostnossl` lines still permit unencrypted.
**Evidence**: 1x02 Finding 024; Task 0's own audit finding on `hostnossl`/`hostssl` coexistence (CRYPTO-002).
**Viable Today**: **Yes** — and made dramatically easier by the completely flat `10.10.0.0/16` network (Task 14, 1x02), which means an attacker only needs to compromise *any* host to gain a viable on-path position against these flows, not a specific chokepoint.
**Mitigation**: Enable DICOM TLS (PS3.15) for imaging traffic, enforce `hostssl`-only for all PostgreSQL connections, and — as the force-multiplying fix — implement network segmentation so achieving an on-path position requires compromising something specifically positioned on the relevant segment, not just anything at all.

---

## Attack: Key Recovery from Memory

**Mechanism**: Any process actively performing encryption or decryption must hold the working key in plaintext in RAM at the moment it's used — there's no way around this, since the math simply cannot happen otherwise. An attacker with root/kernel-level access can dump process memory and search it for high-entropy patterns matching known key lengths, or use memory-forensics techniques (the same category of technique tools like Mimikatz use to pull Windows credentials from LSASS memory) to recover the live key directly, sidestepping the encryption algorithm's mathematical strength entirely — AES-256 is unbreakable by brute force, but that's irrelevant if the key itself is just sitting in memory waiting to be read.
**MedDefense Vulnerability**: billing-srv-01 already has a **confirmed, demonstrated** root-access path (the CVE-2021-44790 → CVE-2019-0211 chain, Findings 001/002). If database encryption (Task 13/15's recommendation) is deployed on this exact host, an attacker who achieves root via that same already-proven chain could potentially extract the live working key from the database engine's process memory while a connection is active — even with the master key correctly isolated in an HSM/KMS (Task 14), a *derived* session key must still exist transiently in memory during actual query processing.
**Evidence**: 1x02 Findings 001/002 (the confirmed RCE→root chain on this exact host).
**Viable Today**: **Yes, if root is achieved** — which, on this specific host, is not a hypothetical; it's a documented, exploitable capability today.
**Mitigation**: This is the honest limit of what key management alone can solve — isolating the master key (Task 14) helps, but doesn't fully close this gap, because a working key must still exist somewhere during active use. The real, primary defense is **preventing root compromise in the first place** — patching Findings 001/002, the actual RCE chain — since no purely cryptographic control fully protects key material on a host an attacker already owns at the root level. Where the threat model genuinely requires protection even against a compromised host, the answer is architectural (secure enclaves/confidential computing, Task 14 Part 1), not just better key storage.
