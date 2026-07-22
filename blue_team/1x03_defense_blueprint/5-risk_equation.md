# The Risk Equation

*(Note: `risk-scenarios.txt` wasn't actually in the project folder, so I built 5 reasonable scenarios myself instead of guessing what it might have said. They're distinct from Task 6's "real" MedDefense risks so this stays a genuine practice exercise.)*

---

## Scenario 1: Lost/Stolen Physician iPad with Cached Patient Data

**AV**: Device replacement $1,000 + breach notification/credit monitoring for an estimated 500 cached records at ~$200/record = $100,000 + regulatory fine (smaller-scale breach) $50,000 + limited reputation hit $20,000. **AV ≈ $171,000**.
**EF**: 50% — 1x00 flagged iPad management status as "unclear," so I can't assume they're MDM-managed/encrypted, but I also can't assume they aren't; splitting the difference.
**SLE** = $171,000 × 0.5 = **$85,500**
**ARO**: 0.4 — across a ~25-device fleet used daily for rounds, some device going missing is a realistic once-every-2.5-years event, not a rare one.
**ALE** = $85,500 × 0.4 = **$34,200**
**Confidence: Medium.** The single biggest swing factor is whether these iPads are actually enrolled in a mobile device management platform. If they are (encrypted, remote-wipeable), EF collapses toward 0% and the ALE nearly disappears. That's an open question 1x00 never resolved.

---

## Scenario 2: Business Email Compromise / Fraudulent Wire Transfer

**AV**: Fraudulent transfer loss $75,000 + investigation/legal $15,000 + minor reputation $5,000. **AV ≈ $95,000**.
**EF**: 90% — successful BEC transfers are rarely fully recovered even with bank intervention.
**SLE** = $95,000 × 0.9 = **$85,500**
**ARO**: 0.3 — no MFA and uneven security-awareness completion (58–94% by site) make finance staff a realistic target, but an actual successful fund transfer (not just an attempt) is less frequent than the attempts themselves.
**ALE** = $85,500 × 0.3 = **$25,650**
**Confidence: Low.** This depends entirely on whether Finance already has an informal out-of-band verification step for wire changes (a phone callback, a second approver) that isn't documented anywhere. If that already exists, ARO could be much lower than assumed.

---

## Scenario 3: Physical Theft/Tampering via the Unlocked Server Room

**AV**: Hardware replacement + investigation $80,000 + potential PHI exposure if a drive is physically removed (larger-scale breach notification, since this room houses EHR/AD/PACS servers) $150,000 + regulatory $100,000 + reputation $100,000. **AV ≈ $430,000**.
**EF**: 40% — not every unauthorized entry results in actual data-bearing theft; some would just be opportunistic and less damaging.
**SLE** = $430,000 × 0.4 = **$172,000**
**ARO**: 0.15 — 1x00's physical walkthrough (Task 3, Observation 1) already rated this Critical: unrestricted, unmonitored, generic-badge access to the server room. Still, a targeted, damaging event is less frequent than the access gap itself being present.
**ALE** = $172,000 × 0.15 = **$25,800**
**Confidence: Medium.** The biggest swing factor is EF — if an attacker specifically targets the domain controller or backup NAS rather than generic hardware, EF could double or triple, and so would the ALE.

---

## Scenario 4: DDoS Against the Patient Portal

**AV**: Mitigation/engineering response $5,000 + revenue/operational loss during an estimated 8-hour outage at $2,000/hour = $16,000 + limited reputation impact $10,000. **AV ≈ $31,000**.
**EF**: 80% — no DDoS mitigation service currently exists, so a successful attack likely achieves most of its intended disruption for its duration.
**SLE** = $31,000 × 0.8 = **$24,800**
**ARO**: 0.5 — DDoS attempts against small healthcare portals are common industry-wide; without any mitigation in place, a successful disruptive one every 2 years is a reasonable estimate.
**ALE** = $24,800 × 0.5 = **$12,400**
**Confidence: High.** This is a comparatively well-bounded risk. The main swing factor is outage duration — it could run much longer than 8 hours without any mitigation service in place.

---

## Scenario 5: Third-Party Vendor Breach (MedTech Solutions, EHR Maintenance)

**AV**: Incident response/credential rotation $60,000 + revenue loss during EHR disruption $100,000 + regulatory (a Business Associate breach is HIPAA-reportable) $300,000 + reputation $200,000. **AV ≈ $660,000**.
**EF**: 50% — a vendor compromise doesn't automatically mean MedDefense's own systems are touched; it depends on how narrowly the vendor's access is scoped, which is currently undocumented (Control 15 doesn't exist per Task 2).
**SLE** = $660,000 × 0.5 = **$330,000**
**ARO**: 0.1 — vendor/supply-chain compromises are a real, growing risk category industry-wide, but a specific successful breach reaching MedDefense through this one vendor is a lower-frequency event than the more direct scenarios above.
**ALE** = $330,000 × 0.1 = **$33,000**
**Confidence: Low.** This entirely depends on an assumption I can't verify from here — MedTech Solutions' own security posture and the actual scope of their access. If they hold standing, unmonitored VPN access rather than time-boxed, scoped access, both EF and ARO would be significantly higher.

---

## Summary

| Scenario | ALE |
|---|---|
| Vendor breach (MedTech Solutions) | $33,000 |
| Lost/stolen iPad | $34,200 |
| BEC/wire fraud | $25,650 |
| Physical theft/server room | $25,800 |
| DDoS on patient portal | $12,400 |

The math itself is trivial multiplication. The real work was in the judgment calls — what fraction of a stolen device's data is actually exposed, whether an informal control already reduces a risk nobody documented, how often a targeted intrusion actually happens versus how often the *opportunity* for one exists. Every ALE above is only as good as its shakiest input, which is exactly why each one carries an explicit confidence rating instead of being presented as a hard number.
