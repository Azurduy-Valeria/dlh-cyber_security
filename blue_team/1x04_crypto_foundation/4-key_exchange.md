# The Key Exchange

All commands actually run — real 2048-bit DH exchange, real derived secrets.

## Part 1: The DH Simulation

```
$ openssl dhparam -out dhparams.pem 2048
Generating DH parameters, 2048 bit long safe prime
[... progress dots, took ~12 seconds ...]

$ cat dhparams.pem
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAmxilppYBMzrVhRKbKDph0AhiRqelBZXdySqAXNF7EN1XVlLxL07O
... (public parameters — the shared "p" and "g" values both Alice and Bob use)
-----END DH PARAMETERS-----
```

**Alice generates her private key from the shared parameters, and extracts her public key:**
```
$ openssl genpkey -paramfile dhparams.pem -out alice_private.pem
$ openssl pkey -in alice_private.pem -pubout -out alice_public.pem
```
```
$ openssl pkey -in alice_private.pem -text -noout
DH Private-Key: (2048 bit)
private-key:
    79:19:f2:72:e4:5a:78:21:9b:bd:5a:7e:f8:98:dd:
    39:59:0c:f9:ee:ab:ba:04:96:1c:a5:d0:7d:a1:2a:
    ...
```

**Bob does exactly the same, using the *same* shared parameters file:**
```
$ openssl genpkey -paramfile dhparams.pem -out bob_private.pem
$ openssl pkey -in bob_private.pem -pubout -out bob_public.pem
```

**Alice derives the shared secret using Bob's public key:**
```
$ openssl pkeyutl -derive -inkey alice_private.pem -peerkey bob_public.pem -out alice_secret.bin
$ xxd alice_secret.bin | head -3
00000000: 6c1b 5506 52d1 2fbe 1335 4eb4 c64d 1447  l.U.R./..5N..M.G
00000010: 27a2 80e6 1f6a 5848 1045 4be3 1203 64e5  '....jXH.EK...d.
00000020: 7c2c 6f17 765a 0040 0ed0 0f0e 12f6 d530  |,o.vZ.@.......0
```

**Bob derives the shared secret using Alice's public key:**
```
$ openssl pkeyutl -derive -inkey bob_private.pem -peerkey alice_public.pem -out bob_secret.bin
$ xxd bob_secret.bin | head -3
00000000: 6c1b 5506 52d1 2fbe 1335 4eb4 c64d 1447  l.U.R./..5N..M.G
00000010: 27a2 80e6 1f6a 5848 1045 4be3 1203 64e5  '....jXH.EK...d.
00000020: 7c2c 6f17 765a 0040 0ed0 0f0e 12f6 d530  |,o.vZ.@.......0
```

**Compare:**
```
$ diff alice_secret.bin bob_secret.bin
(no output — files are identical)

$ sha256sum alice_secret.bin bob_secret.bin
7a020a1fc38ae469ee379930c8c3e8e12dda72b90e87cd489f5934c49dd34a17  alice_secret.bin
7a020a1fc38ae469ee379930c8c3e8e12dda72b90e87cd489f5934c49dd34a17  bob_secret.bin
```
Same hash, both sides. Alice and Bob, using only their own private key and the other party's *public* key, arrived at the exact same 256-byte secret.

---

## Part 2: The Explanation (for Robert Kim, CFO)

Alice and Bob never sent each other the secret key itself — they only ever exchanged public values that, by themselves, don't reveal it. Think of it like two people publicly agreeing on a paint color recipe, each secretly adding their own private color to it, swapping the resulting mixed paint in public, and then each adding their *own* secret color to the paint they received — mathematically, both end up at the exact same final color, but anyone who only saw the public exchanges can't work backward to figure out what either person's private color was. That "mixing" is done with a mathematical operation (modular exponentiation) that's easy to compute in one direction but computationally infeasible to reverse — Eve, watching the whole exchange, sees both public keys go by, but calculating the final shared secret from those public values alone would take longer than is practical with any realistic amount of computing power. So Eve sees everything that was transmitted and still ends up empty-handed, while Alice and Bob — who never transmitted the secret at all — both land on the identical value.

---

## Part 3: The MITM Attack

Plain Diffie-Hellman proves that *whoever* you exchanged keys with now shares a secret with you — but it never proves *who* that was. If Eve sits on the network path, she can intercept Alice's public key before it reaches Bob, send Alice her own public key pretending to be Bob's, and simultaneously do the same trick facing Bob — she ends up with two separate, valid shared secrets: one with Alice (who thinks she's talking to Bob) and one with Bob (who thinks he's talking to Alice). From there, Eve decrypts everything Alice sends, reads or modifies it, then re-encrypts it under the Bob-facing secret and forwards it along — both Alice and Bob complete their handshakes successfully and have no mathematical way to detect that a third secret exchange happened in the middle.

**Mapped to MedDefense**: if the Central–Westside VPN tunnel relied on DH alone with no certificate-based authentication, an attacker positioned on the network path between the two sites (or who compromises the under-hardened Westside consumer router that terminates one end of the tunnel) could perform exactly this attack — establishing separate key exchanges with each endpoint and silently relaying, reading, or altering all traffic between the hospital sites while both ends believe they have a secure direct tunnel to each other. **Certificates prevent this because they add a piece DH alone doesn't have: cryptographic proof of identity, backed by a trusted third party (the CA).** Instead of just exchanging public DH values blindly, each side also presents a certificate proving "this public key genuinely belongs to Central" or "to Westside," signed by an authority both sides already trust — so if Eve tries to substitute her own public key, she'd need a valid certificate proving she's the real Central or Westside, which she can't produce without also having compromised the CA itself. This is exactly why modern VPNs and TLS use certificate-authenticated key exchange (like IKEv2 with certificate auth, or ECDHE inside TLS) rather than raw, unauthenticated DH.
