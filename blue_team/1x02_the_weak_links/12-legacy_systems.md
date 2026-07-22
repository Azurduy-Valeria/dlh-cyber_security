## System 1: Windows XP SP3 (10.10.1.70, WS-RAD-01 — MRI Workstation)

### EOL Research

Searching NVD for CVEs affecting Windows XP published in the last 2 years turns up **essentially none** — and that absence is itself the finding, not good news. Microsoft stopped testing new vulnerability research against XP when it went EOL in April 2014; security researchers and CNAs simply don't include a 12-year-dead OS in the scope of new advisories anymore. NVD's most recent Windows Remote Desktop Services CVEs (e.g., CVE-2025-24035/CVE-2025-24045) list Server 2008 through Server 2025 and Windows 10/11 in their affected-product data — XP is absent, not because it's immune, but because nobody's checking. XP's real vulnerability count is frozen exactly where it was in 2014, and everything discovered in any shared Windows code since then that *would* apply to it simply never gets confirmed or counted.

The 2 most critical vulnerabilities affecting this host remain the three already in the scan report — I'm not aware of anything newer specifically confirmed against XP, so these stand as the most critical by default:
- **MS08-067 (CVE-2008-4250)** — CVSS **10.0**, the highest score anywhere in the entire 31-finding report, and **re-added to CISA's KEV catalog on 2026-05-20** (confirmed in Task 4) — an 18-year-old bug still being actively exploited *right now*.
- **BlueKeep (CVE-2019-0708)** — CVSS 9.8, weaponized Metasploit RCE module, KEV-listed since the catalog's launch day.

### Permanent Exposure

"Unpatched" describes a state that can change — a patch exists, someone hasn't applied it yet, and applying it closes the gap. "EOL" describes a state that *cannot* change through patching, ever, because the vendor has permanently stopped producing patches for that product line. Every vulnerability disclosed in shared Windows code from this point forward that happens to also affect XP's architecture will never receive a fix for XP specifically — not because MedDefense is slow, but because there is no fix to apply. The only way to actually close this risk is to stop running the vulnerable software altogether; patching, by definition, is not an option that exists anymore for this host.

### Scan Findings Affecting This System

Only **Finding 004** — but it bundles three fully independent RCE paths (EternalBlue/SMB, BlueKeep/RDP, MS08-067/Server service), all confirmed present via open ports 445 and 3389. All three are exploitable *specifically because* the OS is EOL: none of them would exist on a currently-supported, patched Windows installation, since Microsoft fixed all three years ago for every OS still receiving updates.

### Compensating Controls

As noted above, **1x00's own control gap analysis (G-006) already establishes that zero compensating controls exist for this exact host** — it's named specifically as the example of an unpatchable asset with no segmentation, isolation, or monitoring substituted in its place. So there's nothing proposed to evaluate for adequacy; the absence itself is the gap. What I'd recommend, in priority order:
1. **VLAN isolation** — place this workstation on its own segment, firewalled to allow traffic *only* to the PACS server (10.10.2.12) and whatever it legitimately needs to reach, nothing else on `10.10.0.0/16`.
2. **Disable SMB and RDP entirely** at the host firewall level if neither is actually required for clinical operation — both open ports map directly to the three CVEs above.
3. **Application whitelisting** (since the OS itself can't be patched, restricting what can *execute* is the next-best layer).
4. **Dedicated monitoring** for this specific host — anomalous outbound connections from an MRI control workstation are a strong compromise signal, and right now nothing in the environment would notice.

### Business Decision

**Do not spend this quarter's migration budget here** — not because it isn't the highest-criticality asset (it is: sole MRI scanner, direct patient-safety impact, highest CVSS in the report), but because migrating a certified medical device controller isn't a same-quarter IT project regardless of funding. It requires OEM (Siemens) engagement and likely FDA recertification of the imaging system as a whole — a vendor- and regulator-gated timeline, not a budget-gated one. The right use of a *small* slice of this budget here is the compensating VLAN isolation above; the full migration budget should go elsewhere (see the final Business Decision section below).


## System 2: Windows Server 2012 R2 (10.10.2.31, print-srv-01 — Print Server)

### EOL Research

Unlike XP, Server 2012 R2 (EOL October 2023, less than 3 years ago as of this scan) is *still* receiving CVE disclosures — because Microsoft sells Extended Security Updates (ESU) for it, and continues testing/patching for paying ESU customers. NVD shows a substantial and ongoing stream: the November 2025 Patch Tuesday cycle alone lists Server 2012 R2 as affected in over a dozen CVEs, spanning both remote code execution and elevation-of-privilege classes. This is a meaningfully different exposure pattern than XP: the vulnerabilities keep coming, MedDefense just isn't in the position to receive the fixes unless it's paying for ESU — and nothing in the 1x00 environment documentation indicates that enrollment exists (print-srv-01 is even flagged `[UNVERIFIED]`, not physically confirmed in over a year).

Most critical from the last 2 years:
- **CVE-2025-24035** and **CVE-2025-24045** — both CVSS **8.1**, Windows Remote Desktop Services remote code execution, both explicitly listing Server 2012 R2 as affected.

### Permanent Exposure

Same structural argument as System 1, one step less severe: Server 2012 R2 *can* still receive patches, but only through a paid ESU program MedDefense shows no sign of having purchased. Without that enrollment, every one of these newly-disclosed 2025 CVEs is just as permanently unpatched for this specific host as anything on the XP box — the fix exists somewhere, MedDefense simply isn't entitled to receive it. That's functionally the same permanent-exposure problem as full EOL, just one budget decision away from being solvable rather than being solvable at all.

### Scan Findings Affecting This System

**Finding 008** — Windows Server 2012 R2 End-of-Life, citing **CVE-2021-34527 (PrintNightmare)**, CVSS 8.8, with the Print Spooler service confirmed running. This is exploitable specifically because of EOL status in the same way as System 1: the fix has existed since 2021, but without active patching (ESU or otherwise), it was never applied here.

### Compensating Controls

1x00's control gap analysis doesn't name print-srv-01 specifically the way it names the MRI scanner — so there's no proposed control to evaluate here either; this asset simply wasn't discussed at that level of detail. I'd recommend:
1. **Disable the Print Spooler service** if this server serves any function beyond active printing — PrintNightmare requires the spooler to be running, and a huge fraction of print-server compromises exploit exactly this service.
2. **Restrict network reachability** to only the workstations/departments that actually print, rather than leaving it reachable from the whole flat network.
3. **Physically verify this host still exists and is still needed** — it's flagged `[UNVERIFIED]` in the 1x00 asset inventory, which is itself worth resolving before investing further security effort in a system nobody has confirmed is even still in service.


## System 3: Ubuntu 18.04 LTS, no ESM (10.10.2.15, billing-srv-01 — Billing/Claims Processing)

### EOL Research

"Ubuntu 18.04"-tagged CVEs are sparse in the 2024–2026 window for the same underlying reason as Windows XP, just less extreme: standard support ended June 2023, so mainstream testing has largely moved to currently-supported releases. The real, measurable exposure here isn't at the distro level — it's at the *component* level: the exact packages this scan already confirmed running (Apache 2.4.29, MySQL, OpenSSH, kernel 4.15.0-213-generic) keep accumulating CVEs against the upstream projects regardless of which distro ships them.

I checked one high-profile recent candidate carefully rather than assuming it applies: **CVE-2025-32463**, a critical (CVSS 9.3) sudo local-privilege-escalation vulnerability via the `--chroot` option, published June 2025. On closer inspection, it only affects sudo versions **1.9.14 through 1.9.17** — Ubuntu 18.04 ships **sudo 1.8.21p2** by default, which predates the vulnerable code path entirely. **This CVE likely does not apply to billing-srv-01** unless sudo was manually upgraded, which nothing in the environment documentation suggests. This is worth stating plainly rather than skipping past it: not every recent, critical, same-OS-family CVE actually applies to a specific installed version — exactly the discipline Task 11 built around false positives.

The two most critical items that *do* concretely apply, both already confirmed in the scan itself:
- **Finding 026**: kernel 4.15.0-213-generic carries **47 known CVEs with available patches** — the actual, already-quantified number for this host.
- **CVE-2019-0211** (Finding 002, CVSS 7.8) — the Apache use-after-free privilege escalation, fixed upstream in Apache 2.4.39, still unpatched here because of the ESM gap (Finding 011).

### Permanent Exposure

Same core argument again: without Ubuntu Pro/ESM enrollment, this host stopped receiving OS-level security patches after standard support ended, and every kernel or package CVE disclosed since is permanently unpatched here regardless of severity — not because a fix doesn't exist upstream, but because nothing is applying it to this specific installation.

### Scan Findings Affecting This System

The most concentrated cluster in the whole report — **Findings 001, 002, 006, 009, 011, 026** all affect this single host. **001 and 002 are exploitable specifically because of EOL status**: Apache 2.4.29 has had fixes for both CVE-2021-44790 (2.4.52) and CVE-2019-0211 (2.4.39) for years — they remain open here purely because this OS isn't receiving updates (Finding 011). **026** (47 kernel CVEs) is the most direct EOL-caused finding of all, since Finding 011 explicitly ties the lack of patches to the missing ESM enrollment.

### Compensating Controls

No 1x00 material discusses compensating controls for this host specifically either. I'd recommend, consistent with Task 6's misconfiguration analysis:
1. **Enroll in Ubuntu Pro/ESM immediately** — unlike Systems 1 and 2, this is the one system where a real vendor patch path still exists and simply isn't being used; it's the cheapest possible fix of the three.
2. **Disable mod_lua** if the billing application doesn't actually require it — removes Finding 001 entirely without waiting for any patch.
3. **Network-restrict MySQL and SSH** to only the specific hosts/admins that need them (Findings 006, 009), rather than leaving both reachable from the flat network.

### Business Decision

**Do not spend the quarter's budget here either** — this one has a real, cheap, immediate ESM-enrollment option that doesn't require a full OS migration project at all; spending scarce migration budget on a full reinstall here would be solving a problem that has a faster, cheaper fix available first.
