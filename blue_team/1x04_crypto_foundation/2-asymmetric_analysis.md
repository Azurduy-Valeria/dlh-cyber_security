# The Asymmetric Engine

All commands below were actually run.

## Part 1: RSA Key Generation and Encryption

```
$ openssl genrsa -out rsa_private.pem 2048
$ openssl rsa -in rsa_private.pem -pubout -out rsa_public.pem
```

Encrypt the patient record (85 bytes) with the public key, decrypt with the private key:
```
$ openssl pkeyutl -encrypt -pubin -inkey rsa_public.pem -in patient_record.txt -out patient_record_rsa.enc
$ openssl pkeyutl -decrypt -inkey rsa_private.pem -in patient_record_rsa.enc -out patient_record_rsa_dec.txt
$ cat patient_record_rsa_dec.txt
Patient: Jane Doe | DOB: 1985-03-14 | MRN: MED-50421 | Diagnosis: Atrial Fibrillation
```
Round-trip worked cleanly — output ciphertext is exactly 256 bytes (2048 bits / 8), regardless of the small input size, which is itself a hint about what's coming next.

**Now the 100MB file:**
```
$ openssl pkeyutl -encrypt -pubin -inkey rsa_public.pem -in testfile -out testfile_rsa.enc
Public Key operation error
40D7CB537B730000:error:0200006E:rsa routines:ossl_rsa_padding_add_PKCS1_type_2_ex:data too large for key size
```

**Why this happens**: RSA doesn't encrypt a stream of data the way AES does — it performs one mathematical operation (modular exponentiation) on a single block that has to fit inside the key size, minus padding overhead. For RSA-2048 with PKCS#1 v1.5 padding, that ceiling is `2048/8 - 11 = 245 bytes` — confirmed by the math above, and by the fact that the 85-byte patient record encrypted fine while the 100MB file didn't even come close. **This is exactly why RSA is never used to encrypt bulk data directly in real systems** — it's only ever used to encrypt something small (a symmetric key, typically 16–32 bytes), and the symmetric algorithm does the actual heavy lifting on the real data. That's the hybrid model, covered in Part 3.

---

## Part 2: ECC Key Generation

```
$ openssl ecparam -genkey -name prime256v1 -out ecc_private.pem
$ openssl ec -in ecc_private.pem -pubout -out ecc_public.pem
```

**Real file size comparison:**
```
$ wc -c rsa_private.pem ecc_private.pem
1704 rsa_private.pem
 302 ecc_private.pem
```
Ratio: **1704 / 302 ≈ 5.6x** — the RSA-2048 private key is over 5.6 times larger than the ECC P-256 key that provides roughly equivalent real-world security (P-256 is generally rated around the security level of RSA-3072, so this comparison is even a bit generous to RSA).

**Why ECC gets away with much smaller keys**: RSA's security relies on the difficulty of factoring a large number — an easier math problem to attack than it looks, which is why RSA needs very large keys (2048+ bits) to stay hard to break. ECC's security instead relies on the elliptic curve discrete logarithm problem, which has no known shortcut attack anywhere near as effective as the best RSA-factoring attacks — so a much smaller key (256 bits) provides comparable real-world difficulty to break.

**Why this matters for constrained environments**: MedDefense's BD Alaris infusion pumps and Philips monitors are small embedded devices with limited CPU, memory, and (for battery-powered ones) power budget. A smaller key means less data to store, less data to transmit, and dramatically less computational work per cryptographic operation — RSA's expensive modular exponentiation on a 2048+ bit number is a real burden on a low-power microcontroller, while ECC's equivalent operation on a 256-bit curve is far cheaper. For devices like these, ECC isn't just a nice-to-have efficiency gain — it can be the difference between a cryptographic operation completing in milliseconds versus draining the battery meaningfully faster.

---

## Part 3: The Hybrid Model

TLS (and nearly all real encrypted communication) doesn't pick one approach — it uses both, in sequence, each for what it's good at. First, the two parties use **asymmetric encryption to solve the key exchange problem**: the client and server agree on a shared secret without ever having met before, using each other's public keys (in modern TLS, this is actually done via Diffie-Hellman key exchange authenticated by the server's certificate, rather than literally RSA-encrypting a key — but the role is the same: asymmetric crypto establishes trust and agrees on a secret). Once that shared secret exists, both sides derive a **symmetric session key** from it, and every byte of actual application data from that point on is encrypted with fast symmetric encryption (AES). This combination is superior to using either alone because asymmetric crypto is too slow and too size-limited (Part 1) to encrypt bulk data directly, while symmetric crypto alone can't solve the "how do two strangers agree on a secret over an insecure network" problem in the first place — each algorithm covers the other's weakness.

**Applied to MedDefense's patient portal**: when a patient connects over HTTPS, the **TLS handshake** (using the server's certificate and a key exchange algorithm, typically ECDHE today) handles establishing the shared secret — this is the asymmetric part. Once the handshake completes, the **TLS record layer** encrypts the actual page content, form submissions, and session data using a symmetric cipher (in a modern configuration, AES-256-GCM) negotiated during that handshake. The portal's current TLS 1.0 support (1x02 Finding 005) is a weakness in exactly this record-layer symmetric encryption stage — old, breakable cipher configurations, not a failure of the asymmetric handshake itself.

---

## Part 4: The Key Length Table

| Algorithm | Type | Key Length(s) | Equivalent Security | Status | MedDefense Usage |
|---|---|---|---|---|---|
| AES-128 | Symmetric | 128 bits | 128-bit | Approved | Acceptable; AES-256 preferred for regulated PHI data |
| AES-256 | Symmetric | 256 bits | 256-bit | Approved | **Recommended standard** — should be the default everywhere |
| RSA-2048 | Asymmetric | 2048 bits | ~112-bit | Approved (minimum) | Acceptable short-term; NIST recommends transitioning away by ~2030 |
| RSA-4096 | Asymmetric | 4096 bits | ~140-bit | Approved | Fine, but slower with no huge benefit over ECC at similar security |
| ECC P-256 | Asymmetric | 256 bits | ~128-bit | Approved | **Recommended** for new deployments, especially constrained medical devices |
| ECC P-384 | Asymmetric | 384 bits | ~192-bit | Approved | Good for higher-assurance needs (e.g., protecting root CAs) |
| DES | Symmetric | 56 bits | ~40-bit (broken) | **Not Approved** | Still enabled on ad-dc-01/02 Kerberos (1x02 Finding 018) — must be disabled |
| 3DES | Symmetric | 112 bits (effective) | Deprecated | **Not Approved** (NIST deprecated 2023) | Not confirmed in use, but should be explicitly disabled if present |
| ChaCha20-Poly1305 | Symmetric (AEAD) | 256 bits | 256-bit | Approved | Not currently used; good alternative to AES-GCM on hardware without AES-NI |
| RC4 | Symmetric (stream) | 40–2048 bits | Broken (biased keystream) | **Not Approved** | Still enabled on ad-dc-01/02 for Kerberos (1x02 Finding 018) — must be disabled |

**For a healthcare environment handling regulated PHI data**: DES and RC4 are flatly unacceptable and already confirmed present in MedDefense's own environment (Finding 018) — these aren't theoretical risks, they're active findings that need to be closed. AES-256 and ECC P-256/P-384 should be the actual working standard going forward; RSA-2048 is acceptable as a floor but shouldn't be the target for new systems.
