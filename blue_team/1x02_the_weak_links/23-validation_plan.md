## Post-Patch Verification

Three of Task 20's Immediate-horizon fixes, and exactly how to confirm each one worked:

**Finding 001/002 — Apache patch, billing-srv-01**
- Re-check the Apache version banner (`curl -I` or a fresh authenticated scan) and confirm it reports 2.4.52 or later.
- In a controlled test window, attempt the actual public proof-of-concept exploit (EDB-51193) against the patched host and confirm it fails.
- Run `searchsploit --cve CVE-2019-0211` logic manually against the new version number and confirm it now falls outside the vulnerable range (2.4.17–2.4.38).

**Finding 003 — PostgreSQL restriction, ehr-db-01**
- From a test host that is *not* ehr-srv-01 (e.g., a spare workstation), attempt to connect to port 5432 and confirm the connection is refused or times out.
- From ehr-srv-01 itself, confirm the connection still succeeds — the fix should block everyone else without breaking the one legitimate path.
- Open the actual `pg_hba.conf` file and confirm the old `10.10.0.0/16` line was removed, not just commented out or overridden by a duplicate rule further down.

**Finding 031/017 — Ghostcat fix, ehr-srv-01**
- Attempt to connect to port 8009 from another host and confirm it's refused (if AJP was disabled) or rejected without the configured secret (if restricted instead).
- Re-run the actual Ghostcat exploit (the Metasploit module or the EDB script) against the host in a controlled test and confirm it no longer succeeds.

The common thread: **don't just confirm the change was made — confirm the specific attack no longer works.** A config file that looks right and a live exploit attempt that actually fails are two different levels of proof, and only the second one is real validation.

---

## Compensating Control Validation (MRI, Medical IoT)

For the VLAN isolation protecting the MRI workstation and the medical device segmentation project:

- **From outside the medical VLAN** (a regular workstation or a test host on another segment), attempt to reach the MRI workstation's SMB (445) and RDP (3389) ports, and the Philips monitors' web/HL7 ports. All attempts should be blocked or time out.
- **From inside the medical VLAN**, attempt to reach an out-of-scope host (billing-srv-01, for example). This should *also* be blocked — isolation needs to work in both directions, not just keep outsiders from getting in.
- **Confirm the one legitimate path still works** — the MRI workstation reaching the PACS server, specifically.
- **Check the firewall's own logs** to confirm blocked attempts are actually being recorded, not just silently dropped with no trace — prevention without visibility just recreates the same detection gap from Task 6/8.
- **Re-test quarterly.** Firewall rules drift over time — someone adds a "temporary" exception during a troubleshooting session and forgets to remove it. A control that was verified once and never checked again isn't meaningfully different from no control at all.

---

## Rescan Schedule

**Recommendation: monthly full authenticated rescans**, plus event-driven rescans whenever a new critical CVE is announced for software MedDefense actually runs.

Quarterly is too slow: Task 4 found that MS08-067 — an 18-year-old vulnerability — was freshly added to CISA's active-exploitation catalog just two months before this scan. Waiting three months between scans means real, currently-exploited threats can sit undetected for most of that window. Weekly, on the other hand, is probably more than a 12-person IT department (per the 1x00 org chart) can sustain without dedicated automation. Monthly is the realistic middle ground — frequent enough to catch newly-weaponized threats against already-known assets, light enough for the actual team size to maintain.

---

## Continuous Intelligence

- **Subscribe to CISA's KEV feed** (RSS or JSON) and check it against MedDefense's asset inventory at least weekly — automated if possible, manually reviewed if not.
- **Subscribe to vendor advisories directly** for every major vendor in the environment: Microsoft, Fortinet, Canonical/Ubuntu, Apache, Synology, BD, and Philips — rather than waiting to discover a new CVE the next time a full scan runs.
- **Set a standing weekly 30-minute review** where the security analyst checks these feeds against the environment and flags anything relevant for out-of-cycle action.

This isn't a hypothetical nice-to-have — Task 4 found the scan report's own claim that Ghostcat wasn't in CISA KEV was already wrong by the time this assessment ran. Nobody had gone back to check. Continuous intelligence is what closes that exact gap.

---

## Continuous Vulnerability Management Lifecycle

**Scan → Triage → Prioritize → Remediate → Validate → Repeat**

| Step | What happens | Who's responsible |
|---|---|---|
| **Scan** | Run the scheduled (monthly) or event-triggered scan | Security Analyst |
| **Triage** | Sort every finding into Actionable Critical / Standard / Informational / False Positive | Security Analyst |
| **Prioritize** | Weigh asset criticality, exploit maturity, and threat context on top of raw severity | Security Analyst + IT Director |
| **Remediate** | Apply the patch, config change, or compensating control | IT Ops, with Vendor involvement for medical devices/firmware and Clinical staff coordination for anything touching patient-care systems |
| **Validate** | Run the specific post-patch check — not just "was it applied" but "does the attack still work" | Security Analyst |
| **Repeat** | Own the cadence, fund the tooling, and make sure the loop doesn't quietly stop after one good cycle | Management/IT Director |

The loop only has value if it actually loops. A one-time vulnerability assessment (like the one this whole project has been built around) is a snapshot — valuable, but already partially stale by the time it's read. The lifecycle above is what keeps that snapshot from being the only one MedDefense ever takes.
