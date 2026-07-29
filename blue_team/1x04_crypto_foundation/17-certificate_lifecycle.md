# Certificate Lifecycle Management

## Certificate Inventory

| Certificate | Current Issuer | Expiration (estimated) | Owner |
|---|---|---|---|
| **Patient portal** (web-srv-01) | Let's Encrypt, 90-day validity | Per 1x02 Finding 013, ~18 days remaining at time of assessment — the emergency this whole plan exists to prevent recurring | IT Director (Sarah) / Security Analyst |
| **EHR internal** (ehr-srv-01) | Unclear — Finding 030's CN mismatch (`ehr.meddefense.local` vs. IP access) suggests either a self-signed or improperly-scoped internal cert; the issuer itself is undocumented, which is a finding on its own | Unknown — not tracked anywhere today | IT / Database Administrator |
| **VPN tunnels** (FortiGate, Central–Westside, Central–HQ) | Likely FortiGate-generated self-signed, or PSK-based with no certificate at all (unclear which — another documentation gap) | Unknown | IT / Network team |
| **Email signing** (S/MIME, per Task 13/15's recommendation) | **Not yet issued** — a new certificate need created by this project's own findings, not a pre-existing one | N/A — to be established | Security Analyst / IT |
| **Code signing** | **Not currently applicable** — no evidence MedDefense develops or distributes signed software beyond internal scripts; flag for future if that changes | N/A | N/A |

The inventory itself is the first finding: **before this task, none of these certificates were tracked anywhere as a single list** — exactly the "no certificate inventory" problem this task exists to fix.

---

## Auto-Renewal Strategy

**Recommendation: ACME/Let's Encrypt for the patient portal specifically.** With ~800 daily patient connections and a portal that's already the *one* internet-facing system in the entire environment (1x02's own scope note), the clinical impact of an unplanned expiration is severe — patients locked out of viewing records, requesting refills, or messaging providers, with zero warning to them beyond a browser error. A 90-day Let's Encrypt certificate paired with genuine ACME automation (`certbot renew` on a scheduled timer, per Task 10) means the *actual* root cause of the current emergency — missing automation, not certificate lifetime — gets fixed permanently. A 1-year commercial CA certificate might feel safer on paper, but it only delays the next unattended-renewal failure by extending the gap between failures; it doesn't remove the dependency on someone remembering to act.

---

## Monitoring and Alerting

**System**: a certificate expiration monitor (e.g., an automated script checking `openssl x509 -enddate` against every certificate in the inventory above, or a dedicated tool) running daily, checked against the central inventory — not a manual calendar reminder, which is effectively what failed the first time.

| Threshold | Recipients | Action expected |
|---|---|---|
| **90 days** | Security Analyst (routine) | Confirm renewal automation is scheduled and functioning; no action needed if so |
| **60 days** | Security Analyst + IT Director | Verify the automation actually ran a test/dry-run renewal successfully |
| **30 days** | Security Analyst + IT Director + Deputy CISO (James) | Escalated visibility — confirm renewal has occurred or is actively in progress; this is the point at which "automation should have already handled this" |
| **7 days** | All of the above **+ CEO/executive notification if still unresolved** | True emergency escalation — this is exactly the situation MedDefense is in *right now* per Finding 013, and it should never reach this threshold again without automation having already failed twice over |

---

## Certificate Policy (5 Rules)

1. **All new production certificates must use ECC P-256 keys or better** — RSA-2048 is only acceptable where a specific, documented legacy compatibility requirement exists, not as a default choice.
2. **Self-signed certificates are prohibited in production.** All internal services must use certificates from either MedDefense's approved internal CA (if one is established) or a trusted public CA — this directly closes the undocumented-issuer gap found in the EHR internal certificate above.
3. **Every certificate must be registered in the central inventory with a named owner and active expiration monitoring before it is deployed to any production system** — no certificate goes live without already being tracked.
4. **Wildcard certificates are prohibited.** Every certificate must list explicit SAN entries for each hostname it covers, scoping any future key compromise to only the hostnames actually in use (Task 8's reasoning).
5. **Any certificate protecting a system that handles ePHI must use automated renewal wherever technically feasible**, and manual renewal processes (where automation genuinely isn't possible) must have a named backup owner and a 60-day-out calendar escalation, not rely on a single person's memory.
