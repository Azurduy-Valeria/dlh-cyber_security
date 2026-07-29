# The Chain of Trust

Captured live from github.com — 3 certificates in the chain.

## Part 1: Capture the Full Chain

```
$ openssl s_client -connect github.com:443 -servername github.com -showcerts
```
3 certificates returned. Split into individual files and inspected:

| Position | Role | Subject | Issuer |
|---|---|---|---|
| 0 | **Leaf** | CN = github.com | C=GB, O=Sectigo Limited, CN=Sectigo Public Server Authentication CA DV E36 |
| 1 | **Intermediate** | C=GB, O=Sectigo Limited, CN=Sectigo Public Server Authentication CA DV E36 | C=GB, O=Sectigo Limited, CN=Sectigo Public Server Authentication Root E46 |
| 2 | **"Root" sent by the server** | C=GB, O=Sectigo Limited, CN=Sectigo Public Server Authentication Root E46 | C=US, O=The USERTRUST Network, CN=USERTrust ECC Certification Authority |

Notice the pattern: **each certificate's Issuer field exactly matches the next certificate's Subject field** — that's literally what "chain" means here. The leaf was signed by the intermediate; the intermediate was signed by "Root E46."

**A real, useful nuance this capture surfaced**: certificate #2 (labeled "root" in the chain position) is **not actually self-signed** — its Subject and Issuer are different (it's signed by USERTrust ECC Certification Authority). This is a *cross-signed* intermediate, not the true root. The actual self-signed USERTrust root lives only in the client's local trust store and is never transmitted over the wire at all, because the client already has it and doesn't need the server to send it.

---

## Part 2: Manual Chain Verification

**Full chain (leaf + intermediate + the server's "root"), verified against the system trust store:**
```
$ openssl verify -untrusted 01_intermediate.pem -untrusted 02_root.pem 00_leaf.pem
00_leaf.pem: OK
```

**Remove the intermediate and try again (leaf + "root" only):**
```
$ openssl verify -untrusted 02_root.pem 00_leaf.pem
CN = github.com
error 20 at 0 depth lookup: unable to get local issuer certificate
error 00_leaf.pem: verification failed
```

**What this demonstrates**: the leaf certificate was signed *directly* by the intermediate CA, not by the root — so without the intermediate present, OpenSSL has no way to link `github.com`'s certificate to anything in the trust store, even though a "root"-labeled certificate was still supplied. This is exactly why servers must send the full chain (leaf + all intermediates) rather than just the leaf: a client's trust store only contains root CAs, and if any intermediate link is missing, the chain simply doesn't connect — no amount of the *right* root certificate being present fixes a *missing* intermediate.

---

## Part 3: Revocation Mechanisms

**CRL (Certificate Revocation List)**: a CA-published, digitally signed list of every certificate serial number that CA has revoked before its natural expiration. A client downloads the list and checks whether the certificate it's validating appears on it. **Main limitation**: these lists can grow large (some CAs' CRLs run into the megabytes) and are only updated periodically (hours to days), so a certificate revoked minutes ago may not appear on the list a client just downloaded — there's an inherent window where a revoked certificate can still appear valid.

**OCSP (Online Certificate Status Protocol)**: instead of downloading an entire list, the client sends a single, targeted query — "is *this specific* certificate still valid?" — to the CA's OCSP responder, and gets a real-time yes/no/unknown answer. This is far more current and bandwidth-efficient than a CRL. **OCSP Stapling** improves on plain OCSP further: instead of the *client* querying the CA (which leaks the client's browsing activity to the CA and adds latency to every connection), the *server* periodically queries the OCSP responder itself and "staples" the signed, time-stamped response directly onto the TLS handshake it sends to clients — the client gets the same freshness guarantee without a separate round-trip or without the CA learning who's visiting which site.

**For MedDefense — if the portal's private key were compromised** (per the 1x03 scenario referenced): the exact sequence would be:
1. **Immediately generate a new key pair** — the compromised private key can never be trusted again, no matter what.
2. **Contact the issuing CA and request revocation** of the current certificate, citing key compromise as the reason (this typically gets prioritized/expedited by CAs over routine revocation requests).
3. **Generate a new CSR** using the new key pair (see Task 10) and submit it for a replacement certificate.
4. **Install the new certificate** on web-srv-01 once issued, and confirm the old one is fully removed from the server configuration.
5. **Verify the old certificate now shows as revoked** via both CRL and OCSP lookups.
6. **Force session invalidation** for any active sessions that might have been established using the compromised key, and rotate any secrets that might have been exposed alongside the key (e.g., if the key leaked via a Git repository, audit that repo's full history and any other credentials that might have been committed alongside it).
7. **Notify affected stakeholders** as required — this could trigger HIPAA breach notification obligations depending on what the compromise actually exposed.

---

## Part 4: Trust Store Exploration

```
$ grep -c "BEGIN CERTIFICATE" /etc/ssl/certs/ca-certificates.crt
121
```

This Linux system trusts **121 root CA certificates** by default (Mozilla's curated CA bundle, standard on Debian/Ubuntu, stored individually under `/usr/share/ca-certificates/mozilla/` and symlinked from `/etc/ssl/certs/`).

**Inspecting the USERTrust ECC root** (the one that ultimately anchors github.com's chain above):
```
$ openssl x509 -in /usr/share/ca-certificates/mozilla/USERTrust_ECC_Certification_Authority.crt -noout -subject -dates
subject=C = US, ST = New Jersey, L = Jersey City, O = The USERTRUST Network, CN = USERTrust ECC Certification Authority
notBefore=Feb  1 00:00:00 2010 GMT
notAfter=Jan 18 23:59:59 2038 GMT
```

**Validity period: 28 years (2010–2038).** This is a real surprise if you're used to thinking in terms of the 90-day leaf certificates just inspected in Task 8 — but it makes sense once you separate the roles. A root CA's private key is kept offline, air-gapped, and used only to sign intermediates (rarely) — it's the most protected key in the entire chain, so it's given a very long life specifically *because* it's handled with far more care than a leaf certificate that sits on a web server facing the internet every day. The short-lived leaf certificates exist precisely so that if *they're* compromised (a much easier target), the blast radius and exposure window are both small — the root's long lifetime and the leaf's short lifetime are two sides of the same risk-management logic, not a contradiction.
