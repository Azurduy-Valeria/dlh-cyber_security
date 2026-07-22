## CVE #1 — Critical

**CVE ID**: CVE-2021-44790

**NVD URL**: https://nvd.nist.gov/vuln/detail/CVE-2021-44790

**Description (in my own words)**: This is a memory corruption bug in `mod_lua`, an optional Apache module that lets admins write request-handling logic in the Lua scripting language. When a Lua script calls the `r:parsebody()` function to parse a multipart request body (like a file upload form), Apache doesn't correctly bound-check the data it's copying into its buffer. An attacker can send a specially crafted request body that overflows that buffer, corrupting adjacent memory. Because this happens before any login is required and needs no user interaction, a successful exploit could let an attacker run arbitrary code on the server. The catch (and why it matters less broadly than the CVSS score alone suggests) is that `mod_lua` isn't loaded by default — a server has to explicitly opt into it, which the scan confirmed billing-srv-01 did.

**Affected Products** (from NVD CPE data):
- Apache HTTP Server, all versions up to and including 2.4.51 (the primary affected product)
- Debian Linux 10.0 and 11.0 (which bundle Apache builds affected by this)
- Fedora 34, 35, and 36
- Oracle HTTP Server 12.2.1.3.0 / 12.2.1.4.0, and several other Oracle Communications products that embed Apache

**CVSS v3.1 Vector String**: `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`

**CVSS Base Score**: 9.8 (Critical)

**CWE**: CWE-787 — Out-of-bounds Write

**References**:
| Link | What it is |
|---|---|
| http://httpd.apache.org/security/vulnerabilities_24.html | Vendor Advisory — Apache's own security page listing the fixed version (2.4.52) |
| http://packetstormsecurity.com/files/171631/Apache-2.4.x-Buffer-Overflow.html | Exploit — a public write-up/PoC demonstrating the overflow |
| https://www.oracle.com/security-alerts/cpuapr2022.html | Patch, Third Party Advisory — Oracle's quarterly Critical Patch Update noting which of their products bundle the fix |

**Published Date**: December 20, 2021

**Last Modified**: June 17, 2026 (NVD entries get re-touched periodically — e.g. CVSS/CPE re-scoring — long after original publication, which is worth remembering: "last modified" is not "last relevant")


## CVE #2 — High

**CVE ID**: CVE-2021-34527 (a.k.a. **PrintNightmare**)

**NVD URL**: https://nvd.nist.gov/vuln/detail/CVE-2021-34527

**Description (in my own words)**: The Windows Print Spooler service (`spoolsv.exe`) runs as SYSTEM on every Windows machine by default, even ones with no printer attached, because it also handles print driver installation. This CVE covers a flaw in how the spooler validates driver installation requests — a low-privileged, authenticated user (or a remote attacker over the network in the right configuration) can trick the spooler into loading an attacker-supplied "driver" that's actually malicious code, which then executes with SYSTEM privileges. In practice this means a normal domain user account can be turned into full administrative control of the machine, or an attacker who already has a low-privilege foothold can escalate to SYSTEM. This is exactly why the scanner flagged it against print-srv-01 (Finding 008) — the Print Spooler service was confirmed running on an already-EOL server, which is precisely the target this vulnerability needs.

**Affected Products** (from NVD CPE data):
- Windows Server 2012 R2 (matches print-srv-01 directly)
- Windows Server 2016, 2019, and 2022
- Windows 10 (multiple builds: 1507 through 22H2) and Windows 11 (21H2, 22H2)

**CVSS v3.1 Vector String**: `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H`

**CVSS Base Score**: 8.8 (High)

**CWE**: NVD-CWE-noinfo (NVD's placeholder label meaning "insufficient information was provided by the source to map this to a specific CWE category" — not every CVE gets a precise weakness classification, which surprised me at first)

**References**:
| Link | What it is |
|---|---|
| https://portal.msrc.microsoft.com/en-US/security-guidance/advisory/CVE-2021-34527 | Vendor Advisory / Patch — Microsoft's own advisory with the fix |
| https://www.cisa.gov/known-exploited-vulnerabilities-catalog?field_cve=CVE-2021-34527 | Government Resource — confirms this is on CISA's Known Exploited Vulnerabilities (KEV) catalog, meaning it's confirmed exploited in the wild, not just theoretical |
| http://packetstormsecurity.com/files/167261/Print-Spooler-Remote-DLL-Injection.html | Exploit — public proof-of-concept exploit code |

**Published Date**: July 2, 2021

**Last Modified**: June 16, 2026


## CVE #3 — Medium

**CVE ID**: CVE-2023-38408

**NVD URL**: https://nvd.nist.gov/vuln/detail/CVE-2023-38408

**Description (in my own words)**: This is a vulnerability in `ssh-agent`, the OpenSSH helper process that holds your decrypted private keys in memory so you don't have to retype a passphrase constantly. `ssh-agent` supports PKCS#11 — a standard for loading cryptographic keys from external hardware/software modules — but the way it searched for and loaded those PKCS#11 provider libraries wasn't strict enough about where it would load code from. If a user forwards their `ssh-agent` to a remote server (a common convenience feature so you can chain SSH hops without copying your key around), and that remote server is attacker-controlled, the attacker can trick the forwarded agent into loading a malicious library from a predictable path and get code execution back on the *originating* machine. It's notable this is described as an "incomplete fix" for an older 2016 CVE — the same root design issue resurfaced.

**Note on severity — this is the interesting part of picking this CVE**: NVD scores this **9.8 Critical**, and the scan report itself lists a CVSS Base of 9.8 for Finding 020 — yet the report bucket it under its **Medium** severity section, and SecurePoint's own analyst note flags it as a likely **false positive** in this environment. The reasoning: exploitation strictly requires agent forwarding to be enabled *and* the user to connect onward to a host the attacker controls — a precondition that's unlikely on backup-srv-01's actual operational role. This is a clean, concrete example of why the raw CVSS base score is not the same thing as real-world risk in a specific environment — the number describes the vulnerability in the abstract, not this deployment.

**Affected Products** (from NVD CPE data):
- OpenSSH versions before 9.3 (up to and including 9.3, 9.3p1) — matches backup-srv-01's detected `OpenSSH_8.9p1`
- Fedora 37 and 38 (which shipped affected OpenSSH builds)

**CVSS v3.1 Vector String**: `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`

**CVSS Base Score**: 9.8 (Critical, per NVD — see severity note above for why the scan report treats it as Medium/likely-false-positive in context)

**CWE**: CWE-428 — Unquoted Search Path or Element

**References**:
| Link | What it is |
|---|---|
| https://www.openssh.com/txt/release-9.3p2 | Vendor Advisory / Release Notes — OpenSSH's own release notes for the fixed version |
| https://github.com/openbsd/src/commit/7bc29a9d... | Patch — the actual upstream code commit fixing the search path logic |
| https://blog.qualys.com/vulnerabilities-threat-research/2023/07/19/ | Third Party Advisory — Qualys' research write-up, which is also who is credited with finding it |

**Published Date**: July 19, 2023

**Last Modified**: June 17, 2026


## Conceptual Questions

### What is the structure of a CVE ID? What do the year and number signify?

A CVE ID follows the format `CVE-YYYY-NNNNN` (minimum 4 digits after the year, but it can extend to more — e.g. `CVE-2014-0160` vs. a hypothetical 6-7 digit ID for a year with huge volume).

- **YYYY** is the year the ID was **assigned/reserved** by a CNA — not necessarily the year the vulnerability was discovered, disclosed, or published. A CVE can be reserved in 2023 and not actually published with full details until 2024 or later, so the year in the ID doesn't guarantee anything about when the public first learned of it.
- **NNNNN** is simply a sequential/arbitrary identifier assigned by the CNA to keep IDs unique within that year. It carries no meaning about severity, vulnerability type, or order of discovery relative to other CVEs from that year — it's purely a serial number.

### What is a CNA (CVE Numbering Authority) and what role does it play?

A CNA is an organization authorized by the CVE Program (overseen by MITRE, under CISA sponsorship) to assign CVE IDs to vulnerabilities within a defined scope — usually their own products. Examples relevant to this scan: Microsoft is a CNA for Microsoft products (which is why CVE-2021-34527 came from them), the Apache Software Foundation is a CNA for Apache projects, and OpenBSD/the OpenSSH project is (or works with) a CNA for OpenSSH.

Their role is to:
- Reserve and assign CVE IDs for vulnerabilities discovered in or reported against products in their scope, so the same flaw doesn't accidentally get two different IDs from two different reporters.
- Publish the initial CVE record (description, affected versions, references) once details can be made public — often coordinated with a patch release.
- Act as the authoritative source of truth for that vulnerability's identity, which is what lets an independent database like NVD enrich the record afterward (CVSS scoring, CPE mapping, CWE classification) without having discovered the bug itself.

MITRE also acts as the "root"/CNA-of-last-resort for vulnerabilities in products whose vendor isn't a CNA.

### What lifecycle states can a CVE have?

- **Reserved**: A CNA has claimed the ID for a vulnerability it's aware of, but no public details exist yet. This is normal during an embargo period — e.g., a researcher reports a bug to a vendor, the CNA reserves an ID immediately so it can be referenced privately, but nothing is published until a fix is ready (coordinated disclosure). If you look up a Reserved ID on NVD, you'll get little more than "this ID has been reserved."
- **Published**: The full record is public — description, references, and (usually, once NVD processes it) CVSS score, CWE mapping, and CPE/affected-product data. All three CVEs above are in this state.
- **Rejected**: The ID was withdrawn and should not be used. This happens for several reasons — most commonly it turns out to be a duplicate of another already-assigned CVE, the report didn't actually describe a real vulnerability, the reservation was never used and expired, or the submitter/CNA withdrew it. A Rejected record still exists on NVD (so the ID isn't silently reused) but its description and references are stripped and replaced with a rejection notice pointing to the correct ID if one exists.

### A Rejected CVE and why

**CVE-2024-2370** - https://nvd.nist.gov/vuln/detail/CVE-2024-2370

**Status**: Rejected

**Reason given**: *"DO NOT USE THIS CVE ID NUMBER. Consult IDs: CVE-2018-5341. Reason: This CVE Record is a duplicate of CVE-2018-5341."*
