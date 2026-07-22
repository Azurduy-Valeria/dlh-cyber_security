## CVE 1: CVE-2021-44790 (Apache mod_lua Buffer Overflow)

**Host**: billing-srv-01 (10.10.2.15)
**CVSS Base Score**: 9.8

### Scenario A: Current (Flat Network)

- **Who can reach this vulnerability**: Any of the ~47 scanned hosts on `10.10.0.0/16` — every workstation, every medical device, both remote sites over their site-to-site VPNs, and guest Wi-Fi if its isolation turns out to be as unverified as Marcus's notes suggest. There is no network-layer barrier between "anywhere in the organization" and port 80 on this host.
- **What the attacker can reach after exploitation**: Once RCE is achieved (and root, via the chained Finding 002), the attacker's next hop is unrestricted: MySQL on the same box (Finding 006, bound to `0.0.0.0`) for financial/billing data, then laterally to ehr-db-01's exposed PostgreSQL (Finding 003) for full PHI, ad-dc-01 via the LDAP relay path (Finding 007) for domain-wide compromise, NAS-01 (Finding 015) for the organization's sole backup copy, and the medical device fleet (Findings 010, 016). Nothing partitions this host's network view from anything else in the organization.
- **Effective Risk**: A vulnerability in a *financial application* becomes, in practice, a path to organization-wide compromise — PHI, domain trust, and backups included.

### Scenario B: Hypothetical (Segmented Network)

- **Who can reach this vulnerability**: Only hosts in a dedicated Financial/Billing VLAN, with a firewall rule permitting port 80 only from the specific finance workstations or admin jump hosts that legitimately need it — not the entire subnet.
- **What the attacker can reach after exploitation**: Limited to whatever else genuinely shares that VLAN (at most, perhaps file-srv-01, if grouped by business function). Reaching ehr-db-01, ad-dc-01, or any medical device would require a *separate* firewall-crossing exploit or an explicitly permitted, narrow inter-VLAN route — not a free pivot.
- **Effective Risk**: Contained to financial/claims data exposure — still a real breach, but not an automatic path to PHI, domain compromise, or patient-safety devices.

**Risk Amplification Factor**: The flat network converts a single-domain breach (financial data only) into an organization-wide one spanning at least five distinct critical asset classes — PHI database, domain authentication, backups, and medical devices, none of which a financial-application bug should ever have had a path to.


## CVE 2: CVE-2020-1938 (Ghostcat)

**Host**: ehr-srv-01 (10.10.2.10)
**CVSS Base Score**: 9.8

### Scenario A: Current (Flat Network)

- **Who can reach this vulnerability**: Any host on `10.10.0.0/16` can reach port 8009 (AJP) — the same universal reachability as above.
- **What the attacker can reach after exploitation**: File-read via Ghostcat almost certainly yields the exact database credentials ehr-srv-01 uses to reach ehr-db-01, enabling a direct connection to Finding 003's exposed PostgreSQL instance — complete PHI compromise. Any AD service-account credentials cached on this host are also now exposed.
- **Effective Risk**: A "web application" vulnerability becomes a direct, one-hop path to a full PHI database breach organization-wide.

### Scenario B: Hypothetical (Segmented Network)

- **Who can reach this vulnerability**: Only hosts in a Clinical Applications VLAN — and in a properly hardened deployment, AJP (8009) shouldn't be reachable from *any* other host at all, since it's designed to be a local/load-balancer-only connector, not a network-facing one.
- **What the attacker can reach after exploitation**: Still potentially ehr-db-01, **if** the two are grouped in the same clinical VLAN without further restriction — which is exactly why segmentation alone isn't the full fix here. Finding 003's own recommendation (restrict `pg_hba.conf` to accept connections only from ehr-srv-01 specifically) is what would fully contain this even *within* a segmented clinical VLAN.
- **Effective Risk**: Still serious within the clinical data domain, but no longer *also* grants domain-wide reach, financial data, or medical device access.

**Risk Amplification Factor**: Significant reduction in lateral blast radius (from "everything" to "the clinical segment only"), but this example is the one that proves segmentation isn't a silver bullet by itself — it needs to be paired with the host-level access restriction Finding 003 already recommends. Defense-in-depth here means both layers, not either one alone.


## CVE 3: CVE-2019-0708 (BlueKeep)

**Host**: WS-RAD-01 (10.10.1.70), MRI workstation
**CVSS Base Score**: 9.8

### Scenario A: Current (Flat Network)

- **Who can reach this vulnerability**: Every workstation and every other medical device on `10.10.1.0/24`, per the finding's own note that there's "no VLAN isolation" — and by extension, anything else on `10.10.0.0/16` given the network diagram shows no segmentation anywhere at all.
- **What the attacker can reach after exploitation**: This is the one CVE in this set where the danger isn't primarily *lateral pivoting to other data* — it's **wormability**. BlueKeep and EternalBlue-class vulnerabilities self-propagate host-to-host with no human operator required (this is exactly the mechanism WannaCry used against the UK's NHS in 2017, crippling hospital operations nationwide). In a flat network, a single compromised legacy host isn't just "one workstation down" — it's a launch point that can self-replicate across every other SMB/RDP-reachable Windows host in the entire organization.
- **Effective Risk**: Beyond the direct compromise of one MRI controller, this is a realistic path to an organization-wide, ransomware-style outage across every Windows host MedDefense operates — directly threatening patient care broadly, not just imaging.

### Scenario B: Hypothetical (Segmented Network)

- **Who can reach this vulnerability**: Only hosts within a dedicated Medical Device/Clinical Workstation VLAN — at minimum containing the PACS server and other radiology-adjacent equipment, but explicitly *not* billing-srv-01, ad-dc-01, or Westside/HQ workstations across the VPN, since a well-designed segmentation plan would specifically block SMB/RDP from crossing VLAN boundaries.
- **What the attacker can reach after exploitation**: A worm here would be contained to the medical-device/radiology segment. Still a real patient-care risk within that segment, but it would not cascade into billing, EHR, domain services, or the second physical site.
- **Effective Risk**: A contained, serious incident within radiology — not a hospital-wide outage event.

**Risk Amplification Factor**: The starkest of the three. Because this vulnerability class is wormable, the flat network doesn't just widen the blast radius — it changes the *kind* of event entirely, from "one imaging device compromised" to "a WannaCry-style cascading outage across the organization's Windows fleet during active patient care."

---

## Network Posture Summary

Across all 31 findings, the flat network doesn't make each vulnerability "somewhat worse" — it deletes the concept of a contained blast radius entirely. The effective organizational risk of this scan report isn't 31 separate, independently-scoped risks; it's one shared risk surface with 31 possible entry points, because compromising *any single one* of them — a financial app, a web server, a workstation, a medical device — grants a foothold from which every other host, dataset, and device class in the environment becomes reachable. This is exactly why network segmentation is arguably more impactful than patching any single CVE in this report: patching a vulnerability closes exactly one entry point while leaving the other 30 findings — and every CVE not yet disclosed — with the identical unlimited blast radius they have today. Segmentation, by contrast, permanently caps the blast radius of *every* vulnerability at once: current findings, future patches that don't get applied on schedule, and zero-days that haven't been written yet. That's precisely why the 1x00 control gap analysis (G-006) already flagged the total absence of any compensating/segmentation control as the single most consequential gap in the entire environment — more consequential, on its own, than any individual missing patch, because it's the one gap that determines how far *every other* gap is allowed to reach.
