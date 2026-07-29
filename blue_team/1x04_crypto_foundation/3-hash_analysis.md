# The Hash Laboratory

All hashes below were actually computed, not looked up from memory.

## Part 1: The Avalanche Effect

```
$ echo -n "MedDefense" | sha256sum
39e026e107a44b2268e43e16e61033fdcc5d2bd62b23e03aca51db35c8671098

$ echo -n "MedDefense1" | sha256sum
97a4141d69cc726a7f6ef577df588d4010c3fe4f235a8bdb616732ba9bf17b92

$ echo -n "MedDefense" | md5sum
75d47fd4b4d183456d0f98fd9ba6ae4d

$ echo -n "MedDefense1" | md5sum
0d2aed72043f78c2935e61ba8520306d
```

**Comparison** (computed precisely, not eyeballed):

| Hash | Hex characters differing | Bit-level difference |
|---|---|---|
| SHA-256 | 62 / 64 (96.9%) | 131 / 256 bits (**51.2%**) |
| MD5 | 30 / 32 (93.8%) | 71 / 128 bits (**55.5%**) |

The hex-character comparison overstates the change (a single differing bit inside a 4-bit hex nibble makes the whole displayed character "different"), which is why the **bit-level** number is the real measure of the avalanche effect. Both land right around the ideal 50% — adding one character to the input flipped roughly half the output bits in both algorithms, exactly what a well-designed hash function should do. This property is what makes hashes useful for integrity checking: a one-character tamper is not a one-character difference in the hash, it's a completely unrecognizable output.

---

## Part 2: Hash Collisions and the Birthday Problem

**Possible unique outputs:**
- MD5 (128-bit): **2^128** ≈ 3.4 × 10^38
- SHA-256 (256-bit): **2^256** ≈ 1.16 × 10^77

A shorter hash is more susceptible to collisions because of the **birthday paradox**: you don't need to search the *entire* output space to find a collision, only about the *square root* of it. For MD5, that's roughly 2^64 attempts (≈1.8 × 10^19) — still large, but computationally reachable with modern hardware, and MD5 collisions have been practically demonstrated for over a decade. For SHA-256, the birthday bound is 2^128 attempts — a number so large it remains completely out of reach of any current or foreseeable computing power. A birthday attack exploits this gap between "attacks on a specific target" (which need the full 2^n space) and "attacks that just need *any* two inputs to collide" (which only need √(2^n)) — the latter is a vastly easier bar to clear, and it drops fast as the hash gets shorter.

**Connecting to Finding 018**: if RC4 is still enabled for Kerberos tickets, that matters because RC4-encrypted Kerberos tickets use a key derived via MD4 (a predecessor to MD5, similarly broken and even faster to attack) — this is exactly what makes Kerberoasting practical. An attacker who requests an RC4-encrypted service ticket can take it offline and brute-force the account's password hash without ever touching the domain controller again, because the weak, unsalted, fast MD4-family hash underneath can be tested millions of times per second on ordinary hardware. The practical implication: **as long as RC4 stays enabled, MedDefense's Kerberos ticket encryption is only as strong as the weakest hash function it's still willing to use** — the AES-256 option existing alongside it provides zero protection for any account an attacker chooses to target via the RC4 path instead.

---

## Part 3: Rainbow Table Demonstration

```
$ echo -n "password123" | md5sum
482c811da5d5b4bc6d497ffa98491e38

$ echo -n "s4lt9xQ2:password123" | md5sum
6d537fa53f1db2c22b0451ef4ef9fbe8
```

**A note on this part**: I can't actually submit a form to crackstation.net through my available tools (I can read/summarize a page, but I can't interact with and submit its lookup form) — so I won't fabricate a fake "I looked it up and here's the screenshot" result. What I can say accurately: CrackStation's own description confirms it works by matching submitted hashes against a **190GB, 15-billion-entry precomputed lookup table** built from common wordlists and password dumps. `password123` is one of the most common passwords in existence and appears in essentially every breach compilation and wordlist ever assembled — its unsalted MD5 hash (`482c811d...`) would be found in that table in a fraction of a second, with the plaintext `password123` returned immediately. The salted version (`6d537fa5...`) would **not** be found, for a simple reason: no precomputed table anywhere contains an entry for the literal string `s4lt9xQ2:password123`, because that exact salt-plus-password combination was invented for this exercise and has never appeared in any breach or wordlist the table was built from.

**Why salting defeats rainbow tables**: a rainbow table is only valuable because it's precomputed *once* and reused against *any* target using the same unsalted algorithm — the attacker's cost is paid up front, a single time, and then amortized across every password they ever want to crack. A salt breaks that economics completely: since the salt is unique per user (or at minimum per system), the attacker would need a separate precomputed table *for every possible salt value*, which is computationally infeasible at scale. This is exactly why every user needs a genuinely **unique** salt — if MedDefense reused one global salt across all accounts, an attacker would only need to build one table (for that one salt) to attack every user at once, which defeats most of the benefit; a unique salt per user forces the attacker back to cracking one password at a time, from scratch, with no shortcut.

---

## Part 4: Key Stretching

**bcrypt**: Built on the Blowfish cipher, bcrypt runs the hashing process through a configurable number of rounds (2^cost) instead of hashing once, and bakes in a unique salt automatically as part of its own output format. It resists brute-force because each guess costs meaningfully more CPU time than a plain hash, and it's also naturally resistant to GPU/ASIC acceleration compared to plain SHA-family hashes, since Blowfish's key setup doesn't parallelize as cleanly. The **cost factor** directly controls how many rounds run (each increment doubles the work), letting an operator tune the delay as hardware gets faster.

**PBKDF2**: Applies an underlying hash function (commonly HMAC-SHA256) repeatedly, a configured **iteration count** number of times, deliberately slowing down each single guess. It resists brute-force purely through repetition cost — more iterations means more work per guess — but unlike bcrypt or Argon2, it doesn't require significant memory, which makes it comparatively cheaper to attack at scale on GPUs/ASICs that can run many parallel hash computations cheaply.

**Argon2** (specifically Argon2id, the recommended variant): Deliberately requires a configurable amount of **memory**, not just CPU time, to compute — winner of the 2015 Password Hashing Competition and the current OWASP-recommended default. It resists brute-force more effectively than either alternative because GPUs and ASICs are excellent at massively parallel *cheap* computation but comparatively bad at massively parallel *expensive-memory* computation — Argon2's memory cost parameter directly limits how many guesses an attacker can run in parallel, regardless of how much raw compute they throw at it. Its parameters (memory cost, time cost, parallelism degree) all combine to control the total attack cost, rather than a single number the way bcrypt/PBKDF2 use.

**Recommendation for MedDefense's application password storage**: **Argon2id**, since it provides the strongest resistance to the GPU/ASIC-scale cracking that a stolen password database realistically faces today. If a specific compliance requirement forces MedDefense onto NIST-validated/FIPS-approved primitives only, **PBKDF2** (with a high iteration count, 600,000+) is the reasonable fallback — it's the one of the three explicitly in NIST SP 800-132.

**What Active Directory uses by default**: per Sarah's own audit notes, **AD uses NTHash (MD4) by default for NTLM compatibility** — not bcrypt, PBKDF2, or Argon2 at all. This is **not adequate**. MD4 is fast (the opposite of what password hashing wants), has no salt (identical passwords across the domain produce identical hashes, and precomputed attacks are practical), and has no iteration/stretching concept whatsoever. This is precisely why NTLM hash theft and pass-the-hash attacks remain effective decades after MD4 was broken as a general-purpose hash — the weakness isn't a misconfiguration, it's the actual default design of the mechanism, kept for backward compatibility exactly like Finding 018's RC4/DES.

---

## Part 5: Integrity Verification Script

See `3-hash_verify.sh`. Tested against 4 real cases:

```
$ ./3-hash_verify.sh patient_record.txt 4e835bed9f9b9300bbffa442fd620ebdb0c2a807739fafe2d2eeec813aa9d48d
INTEGRITY OK                                                    (exit 0)

$ ./3-hash_verify.sh patient_record.txt 0000...0000
INTEGRITY FAILED - expected 0000...0000 got 4e835bed...          (exit 1)

$ ./3-hash_verify.sh patient_record_tampered.txt 4e835bed...      # file was modified
INTEGRITY FAILED - expected 4e835bed... got b6678295...           (exit 1)

$ ./3-hash_verify.sh does_not_exist.txt abc123
Error: file 'does_not_exist.txt' not found.                       (exit 1)
```

All four cases behave as required — correct match, incorrect hash, tampered file, and missing file are all handled with the right message and exit code.
