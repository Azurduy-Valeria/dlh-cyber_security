# The TLS Audit

Part 1 uses real, live data pulled directly from SSL Labs' public API (`api.ssllabs.com/api/v3/analyze`), not the HTML report — same underlying scan engine as the website, just queried programmatically since the web UI's scan-and-poll flow isn't practical to drive through my tools.

## Part 1: SSL Labs Analysis

### A+ site: www.ssllabs.com

| Field | Value |
|---|---|
| Overall Grade | **A+** |
| Protocol support | TLS 1.2, TLS 1.3 only — no TLS 1.0/1.1 negotiable at all |
| Forward secrecy | Robust (all simulated clients get forward secrecy) |
| Known vulnerabilities | Heartbleed: No · POODLE: No · FREAK: No · Logjam: No · RC4: No |
| HSTS | **Present** |

### B-graded site: badssl.com

| Field | Value |
|---|---|
| Overall Grade | **B** |
| Protocol support | **TLS 1.0, TLS 1.1, and TLS 1.2 all still negotiable** |
| Forward secrecy | Robust where negotiated |
| Known vulnerabilities | Heartbleed: No · POODLE: No · FREAK: No · Logjam: No · RC4: No |
| HSTS | **Absent** |

**What separates them**: badssl.com isn't failing because of an actively broken cipher or a known CVE — every specific vulnerability check comes back clean on both sites. It's graded down purely for **still allowing TLS 1.0/1.1 to be negotiated at all**, plus having **no HSTS header** to force browsers toward HTTPS automatically. This is an important, realistic finding: a B grade doesn't mean "vulnerable to a specific named attack" — it means "carrying legacy capability it doesn't need," which is exactly the same category of problem as MedDefense's own Finding 005.

---

## Part 2: MedDefense Portal Assessment (Predicted)

The portal can't be tested directly (internal-only), but based on **Finding 005** (TLS 1.0 supported alongside TLS 1.2, no TLS 1.3, no HSTS, no OCSP stapling) and **Finding 013** (certificate near/past expiration), here's the predicted grade and every contributing issue:

**Predicted grade: F**, not just a "B" — because an expired certificate is an automatic, severe SSL Labs penalty (not a partial deduction like protocol support), and Finding 013 states the certificate is now inside its final ~18 days, trending toward actual expiration if unaddressed.

**Every issue that would reduce the grade:**
1. **TLS 1.0 supported** — the same specific weakness that caps badssl.com at a B, present here too.
2. **No TLS 1.3** — missing the current-generation protocol entirely is itself a deduction, separate from allowing old ones.
3. **No HSTS configured** — same gap as badssl.com above.
4. **No OCSP stapling** — adds a deduction and a real handshake latency cost for every one of the portal's ~800 daily connections.
5. **Certificate at end of validity window (Finding 013)** — if this assessment runs after the actual expiration date, SSL Labs caps the result at **F** regardless of every other configuration detail, exactly like the `expired.badssl.com` certificate inspected in Task 8.
6. **Undocumented cipher suite** — the audit notes flag that MedDefense is running Apache's untouched default cipher list, which almost certainly includes older, weaker suites negotiable alongside strong ones (mirroring the exact "supports old protocol AND new" pattern seen in both live SSL Labs results above).

---

## Part 3: The Hardened Configuration

Apache format, for MedDefense's patient portal:

```apache
# --- Protocol versions: TLS 1.2 and 1.3 only ---
SSLProtocol -all +TLSv1.2 +TLSv1.3
# Disabling everything below 1.2 removes BEAST/POODLE/Lucky Thirteen exposure
# entirely (Finding 005) — there's no "partial" fix for TLS 1.0, only off.

# --- Cipher suite selection, ordered by preference ---
SSLCipherSuite TLSv1.2:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305
SSLHonorCipherOrder on
# TLS 1.3's own suite negotiation (AES-256-GCM/CHACHA20-POLY1305) is handled
# separately by the protocol itself and doesn't use this legacy directive.
#
# ECDHE-first: guarantees forward secrecy on every connection (Task 4's whole
# point — a captured session today can't be decrypted later even if a key
# leaks). AES-256-GCM first: authenticated encryption, and Task 1's own
# benchmarking showed GCM is not just safer but faster on modern hardware.
# ChaCha20-Poly1305 included as a fallback for clients/devices without
# AES-NI hardware acceleration (Task 6).

# --- HSTS ---
Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
# 63072000 seconds = 2 years, the de facto standard for HSTS preload-list
# eligibility. This forces every browser that's ever connected once to
# refuse a downgrade to plain HTTP for the full two years, directly
# closing the downgrade attack described in Part 4 below.

# --- OCSP Stapling ---
SSLUseStapling on
SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"
# The server fetches and caches the revocation status itself (Task 9, Part 3)
# instead of making every patient's browser query the CA directly — faster
# handshakes, and no leak of patient browsing metadata to the CA.

# --- Session handling ---
SSLSessionTickets off
# Modern guidance disables stateless session tickets by default unless
# they're rotated frequently — a static or rarely-rotated ticket key becomes
# a long-lived way to decrypt past sessions if it's ever compromised,
# undermining the forward secrecy ECDHE was just used to guarantee above.

SSLInsecureRenegotiation off
# Blocks the legacy, unauthenticated TLS renegotiation mechanism that has
# its own known MITM-injection history — there's no legitimate reason for
# a 2026-era deployment to still allow it.
```

---

## Part 4: The Downgrade Attack

A TLS downgrade attack exploits the fact that, historically, clients and servers negotiate the *highest mutually supported* protocol version — and an on-path attacker can interfere with that negotiation itself. If MedDefense's portal supports both TLS 1.0 and TLS 1.2, an attacker positioned on the network path (the same flat-network problem from Task 14) can strip or corrupt the parts of the initial handshake that advertise TLS 1.2 support, or simply interfere with the connection attempt until the client falls back to the older, weaker protocol it's still willing to accept — the client believes it negotiated normally, with no visible error, while actually landing on TLS 1.0, which is then vulnerable to BEAST/POODLE-style attacks the attacker can exploit directly. **The simplest and most complete prevention is exactly what Part 3 already does: stop supporting TLS 1.0/1.1 entirely.** A downgrade attack can only force a fallback to a protocol the server is still willing to speak — if TLS 1.0 isn't in the server's supported list at all, there's nothing left to downgrade *to*, and the connection simply fails cleanly instead of silently succeeding on a weak protocol.
