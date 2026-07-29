# Digital Signatures in Practice

*(Companion to `5-sign_verify.sh` — documents Part 1's commands and real output; the script itself covers Part 2.)*

## Part 1: Sign and Verify

Test file (using the RSA key pair generated in Task 2):
```
$ echo -n "Patient: John Smith | MRN: MED-10042 | Rx: Metoprolol 50mg | Prescriber: Dr. Patel" > prescription.txt
```

**Sign with SHA-256 and the RSA private key:**
```
$ openssl dgst -sha256 -sign rsa_private.pem -out prescription.sig prescription.txt
$ xxd prescription.sig | head -3
00000000: 8d76 4d7d 4249 25af 03c2 0ecc eb46 2e6d  .vM}BI%......F.m
00000010: 35a2 fd0a 6b65 cd69 99df b7f1 cbe4 4d97  5...ke.i......M.
00000020: 365b 8583 1d09 891c d535 c66a 752e 4ace  6[.......5.ju.J.
```
The signature is 256 bytes — the RSA-2048 key size, same as the RSA encryption output from Task 2. That's not a coincidence: signing is (conceptually) "encrypt the hash with the private key," so the output size is bound by the same modulus.

**Verify with the public key:**
```
$ openssl dgst -sha256 -verify rsa_public.pem -signature prescription.sig prescription.txt
Verified OK
```

**Tamper with one part of the file — changing the dose from 50mg to 500mg, a genuinely dangerous real-world example — and verify again:**
```
$ sed -i 's/Metoprolol 50mg/Metoprolol 500mg/' prescription_tampered.txt
$ openssl dgst -sha256 -verify rsa_public.pem -signature prescription.sig prescription_tampered.txt
4087EDC3FE730000:error:02000068:rsa routines:ossl_rsa_verify:bad signature
Verification failure
```

**Why this matters concretely**: the original signature was computed over the SHA-256 hash of the *unmodified* file. Changing even a single digit changes the hash completely (the avalanche effect from Task 3), so the signature — which is mathematically tied to that exact original hash — no longer matches. This is precisely the property that makes a digital signature legally meaningful for something like a prescription: it's not just "Dr. Patel signed something that day," it's "Dr. Patel signed *this exact dosage*, and any change to it — even a single added zero — is cryptographically detectable." That's what makes the three properties real in practice:
- **Integrity**: the failed verification above proves the content changed after signing.
- **Authentication**: only someone holding `rsa_private.pem` could have produced a signature that verifies against `rsa_public.pem`.
- **Non-repudiation**: because producing that signature required the private key, Dr. Patel can't credibly claim someone else signed it — which is exactly the legal weight HIPAA and the ESIGN Act require for something like an electronic prescription.
