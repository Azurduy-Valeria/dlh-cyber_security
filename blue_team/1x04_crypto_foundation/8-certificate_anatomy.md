# The Certificate Anatomy

All three certificates below were captured live with `openssl s_client -connect <host>:443 -servername <host>` and inspected with `openssl x509 -text -noout`. Real data, real dates.

## Part 1: Three Real Certificates

### 1. letsencrypt.org (Let's Encrypt)

| Field | Value |
|---|---|
| Subject | CN = letsencrypt.org *(DV certs typically carry only a CN — no O/L/ST/C)* |
| Issuer | C=US, O=Let's Encrypt, CN=YE2 |
| Validity | Not Before: Jul 6 15:24:34 2026 GMT — Not After: Oct 4 15:24:33 2026 GMT (~90 days) |
| Serial Number | 05:05:bb:29:ef:e3:ee:15:2b:a3:e9:e6:87:28:10:b5:fe:b9 |
| Signature Algorithm | ecdsa-with-SHA384 |
| Public Key | id-ecPublicKey, P-256 (256 bit) |
| SAN | cp.letsencrypt.org, cp.root-x1.letsencrypt.org, cps.letsencrypt.org, cps.root-x1.letsencrypt.org, lencr.org, letsencrypt.com, **letsencrypt.org**, www.lencr.org, www.letsencrypt.com, www.letsencrypt.org |
| Key Usage / EKU | Digital Signature (critical) / TLS Web Server Authentication |
| Authority Info Access | CA Issuers: `http://ye2.i.lencr.org/` — no OCSP URI on this cert; revocation is via the separate CRL Distribution Point (`http://ye2.c.lencr.org/58.crl`) |

### 2. github.com (Sectigo — commercial CA)

| Field | Value |
|---|---|
| Subject | CN = github.com (DV) |
| Issuer | C=GB, O=Sectigo Limited, CN=Sectigo Public Server Authentication CA DV E36 |
| Validity | Not Before: Jul 3 00:00:00 2026 GMT — Not After: Sep 30 23:59:59 2026 GMT (~90 days — commercial CAs increasingly match Let's Encrypt's short lifetimes now) |
| Serial Number | 72:01:0e:03:f4:a0:67:fe:4e:79:62:66:43:07:18:f6 |
| Signature Algorithm | ecdsa-with-SHA256 |
| Public Key | id-ecPublicKey, P-256 (256 bit) |
| SAN | github.com, www.github.com |
| Key Usage / EKU | Digital Signature (critical) / TLS Web Server Authentication |
| Authority Info Access | CA Issuers URL **and** OCSP URI: `http://ocsp.sectigo.com` |

### 3. expired.badssl.com (COMODO/Sectigo — intentionally broken)

| Field | Value |
|---|---|
| Subject | OU=Domain Control Validated, OU=PositiveSSL Wildcard, CN=*.badssl.com |
| Issuer | C=GB, ST=Greater Manchester, L=Salford, O=COMODO CA Limited, CN=COMODO RSA Domain Validation Secure Server CA |
| Validity | **Not Before: Apr 9 2015 — Not After: Apr 12 2015** |
| Serial Number | 4a:e7:95:49:fa:9a:be:3f:10:0f:17:a4:78:e1:69:09 |
| Signature Algorithm | sha256WithRSAEncryption |
| Public Key | RSA, 2048 bit |
| SAN | *.badssl.com, badssl.com |
| Key Usage / EKU | Digital Signature, Key Encipherment (critical) / TLS Web Server + Client Authentication |
| Authority Info Access | CA Issuers URL and OCSP URI: `http://ocsp.comodoca.com` |

---

## Part 2: The Broken Certificate

```
$ openssl x509 -in expired_leaf.pem -noout -dates
notBefore=Apr  9 00:00:00 2015 GMT
notAfter=Apr 12 23:59:59 2015 GMT

$ date -u
Mon 27 Jul 2026 21:02:39 UTC
```

**What's precisely wrong**: this certificate's validity window closed on **April 12, 2015** — over **11 years** before today's date. It's not a subtle misconfiguration; the certificate is more than a decade past expiration, kept online specifically as a stable target for testing browser/client expiration handling.

**What a browser would show**: a full-page interstitial warning — Chrome/Firefox both display something like "Your connection is not private / NET::ERR_CERT_DATE_INVALID," blocking the page entirely behind an "Advanced" click-through, rather than silently loading the page.

**The risk this creates**: an expired certificate provides no assurance that the connection hasn't been intercepted since expiration — the CA is no longer vouching for this key pair's current validity, so continuing anyway means trusting an unverified identity claim. More practically, expiration is often a symptom of a bigger problem: no monitoring or auto-renewal process exists, which is exactly what's happening with MedDefense's own portal certificate right now (1x02 Finding 013 — auto-renewal not configured).

**Would I advise a patient to proceed?** No. An expired certificate on a healthcare patient portal handling PHI and login credentials is exactly the situation where "click through the warning" should never become a habit — precisely the concern raised in Task 11 (1x02) about training people to ignore certificate warnings in general. The right advice is to stop, not proceed, and report it — even though in badssl.com's specific case it's an intentional test site with no real risk.

---

## Part 3: MedDefense Certificate Profile

**Type: Domain Validated (DV)**, not OV or EV. DV is what both Let's Encrypt and GitHub's own commercial cert actually use in practice today — browsers no longer visually distinguish EV certificates in any meaningful way (the old "green bar" UI was removed years ago across all major browsers), so EV's extra cost and manual validation overhead buys essentially nothing in user-facing trust signaling anymore. What actually matters for a patient portal is that the connection is encrypted and the domain is verified — DV delivers both.

**CA: Let's Encrypt**, via ACME automation. Free, and — critically for MedDefense's actual documented failure (Finding 013: auto-renewal not configured) — ACME's whole design point is scriptable, unattended renewal. The root cause of the current expiring-certificate problem isn't Let's Encrypt's short 90-day lifetime; it's the missing automation. Fixing that (via `certbot` or similar) solves the *actual* problem instead of just switching to a commercial CA with a longer certificate lifetime that would only delay the next unattended-renewal failure.

**SAN entries**: `portal.meddefense.local` (primary) plus any alternate hostnames patients or mobile apps might actually use to reach it (e.g., a public-facing `portal.meddefense.com` if one exists, and `www.` variants) — every hostname a real client might type or resolve needs to be listed, or that specific connection will fail certificate validation even though the "same" server is reachable under another name.

**Key algorithm: ECC P-256.** Both real-world certificates inspected above (letsencrypt.org and github.com) now use P-256, not RSA — that's the current industry default, not just a theoretical recommendation. It's faster for the ~800 daily patient connections to negotiate (Task 10 covers this performance reasoning in more depth) and matches the Algorithm Reference Table's (Task 6) recommendation.

**Validity period: 90 days**, matching Let's Encrypt's standard and both real certificates captured above. A shorter lifetime is a *feature*, not a limitation — it bounds how long a compromised key stays trusted, and forces the automation (ACME) that should have existed already, directly preventing a repeat of the current Finding 013 situation.

**Wildcard vs. single-domain**: **single-domain with explicit SAN entries**, not a wildcard (`*.meddefense.local`). A wildcard certificate's private key, if compromised, exposes every current and future subdomain at once — a much larger blast radius than the portal alone. Given MedDefense's demonstrated pattern of under-segmented, single-point-of-failure infrastructure (the flat network, the co-located backup, Task 14), a wildcard cert would just be one more single point of failure stacked onto ones that already exist. Explicit SAN entries cost nothing extra with a DV cert and keep the compromise blast radius scoped to exactly the hostnames actually in use.
