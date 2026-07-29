# The CSR Workshop

## Part 1: Key Generation Decision

**Choice: ECC P-256.**

Justification: at the security level MedDefense actually needs (roughly equivalent to RSA-3072, per Task 6's table), P-256 is dramatically cheaper to compute than RSA-2048 or RSA-4096 — real numbers from Task 1/2's own benchmarking showed the size and computational gap directly. For a web server handling ~800 patient connections per day, that's not a huge load in absolute terms, but every TLS handshake still pays the asymmetric-crypto cost once, and ECC's smaller keys mean less data exchanged and faster handshake math on every single one of those 800 daily connections, with zero compromise on security level. Compatibility is a non-issue today — P-256 has been universally supported in browsers and mobile OSes for close to a decade, and both real-world certificates inspected in Task 8 (letsencrypt.org, github.com) already use P-256 in production. This also directly matches the Algorithm Reference Table's own recommendation (Task 6) to standardize on ECC P-256 for new certificate deployments.

```
$ openssl ecparam -genkey -name prime256v1 -out portal_key.pem
$ chmod 600 portal_key.pem
```

---

## Part 2: CSR Generation

Config file (`openssl.cnf`) used to supply every required field non-interactively:

```ini
[ req ]
default_bits       = 256
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions      = req_ext

[ dn ]
CN = portal.meddefense.local
O  = MedDefense Health Systems
OU = Information Technology
L  = Central City
ST = State
C  = US

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = portal.meddefense.local
DNS.2 = portal.meddefense.com
DNS.3 = www.portal.meddefense.com
```

```
$ openssl req -new -key portal_key.pem -out portal.csr -config openssl.cnf
```

`portal.meddefense.com` and `www.portal.meddefense.com` are included alongside the internal `portal.meddefense.local` name specifically because patients accessing the portal from outside the internal network (mobile devices, home computers) would resolve a public-facing hostname, not the internal `.local` name — missing that SAN entry would break access for exactly the population (patients, not staff) this certificate exists to serve.

---

## Part 3: CSR Inspection

```
$ openssl req -text -noout -in portal.csr
Certificate Request:
    Data:
        Version: 1 (0x0)
        Subject: CN = portal.meddefense.local, O = MedDefense Health Systems, OU = Information Technology, L = Central City, ST = State, C = US
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        Attributes:
            Requested Extensions:
                X509v3 Subject Alternative Name:
                    DNS:portal.meddefense.local, DNS:portal.meddefense.com, DNS:www.portal.meddefense.com
    Signature Algorithm: ecdsa-with-SHA256
```

**Verification against the requirements**: CN is correct (`portal.meddefense.local`), Organization/OU/Locality/State/Country are all present and correct, the key is confirmed as P-256 (256-bit ECC as decided in Part 1), and — critically — **all three required SAN entries are present** in the Requested Extensions block. Every field checks out.

---

## Part 4: The Full Certificate Lifecycle

1. **CSR generated** *(done — Parts 1–3 above)*. Private key stays on web-srv-01, never leaves it.
2. **Submission to the CA**: **Let's Encrypt, via ACME automation** (`certbot` or similar), not a manual commercial CA submission. This is a deliberate choice tied directly to fixing the *actual* root cause of Finding 013 — the certificate expired because renewal wasn't automated, not because a 90-day lifetime is inherently a problem. ACME's entire design point is scriptable, unattended renewal.
3. **Validation process**: for a DV certificate, Let's Encrypt validates domain control only — typically via an HTTP-01 challenge (placing a token file at a specific path on the web server) or a DNS-01 challenge (publishing a specific TXT record). No organizational identity vetting happens at this tier, which is why issuance is fast (minutes) and why DV is appropriate here (Task 8, Part 3).
4. **Certificate issuance**: the CA returns the signed leaf certificate plus the intermediate chain needed to complete trust back to a root already in browsers' trust stores (Task 9).
5. **Installation on the web server**: the new certificate and full chain are installed in Apache/Nginx's TLS configuration alongside the existing private key, and the web server is reloaded (not necessarily restarted, to avoid dropping active connections).
6. **Verification the new certificate is serving correctly**: run `openssl s_client -connect portal.meddefense.local:443 -servername portal.meddefense.local` and confirm the returned certificate's serial number, validity dates, and SAN list match the newly issued one — exactly the inspection technique practiced in Tasks 8–9. Also confirm the chain verifies cleanly (Task 9, Part 2) and that no mixed-content or old-cert caching issues appear in a real browser test.
7. **Decommission of the old certificate**: once the new certificate is confirmed live and stable, request revocation of the old one from its issuing CA (removes any risk from a still-valid-but-superseded certificate lingering) and remove the old key/cert files from the server rather than leaving them in place.
8. **Monitoring for the next renewal**: this is the step that was missing and caused Finding 013 in the first place. Configure `certbot renew` (or equivalent) as an automated cron/systemd timer job, and — critically — add active monitoring (e.g., a check that alerts if the live certificate's expiration date drops under 14 days) so a renewal *failure* is caught immediately rather than discovered only when the certificate has already expired.
