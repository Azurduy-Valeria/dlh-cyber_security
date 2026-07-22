# The Self-Audit: Lynis on My Own Machine

## Part 1: The Audit

Ran `sudo lynis audit system` on my own machine (Ubuntu 24.04, kernel 6.17.0, hostname `tux`) - 272 tests performed across every category from kernel hardening to malware detection. Raw output analyzed below.

## Part 2: Analyzing the Results

### Hardening Index

**62 / 100** 

For context, Lynis treats anything below ~70 as "room for real improvement" rather than a failing grade - this is a normal daily-driver desktop, not a hardened server, so a mid-range score with a long suggestion list is expected rather than alarming.

### Top 5 Warnings

Lynis's own formal "Warnings:" bucket only listed **2** items (`PKGS-7392` and `TIME-3185`) - but reading the full raw output the way Task 0 trained me to (don't just read the headline bucket, read the whole document), three more findings buried deeper in the log are genuinely more security-relevant than several items Lynis itself only classed as "Suggestions." I'm treating these 5 as the real top-priority list:

| # | Finding | What Lynis checks | Why it matters | Remediation |
|---|---|---|---|---|
| 1 | **PKGS-7392** - vulnerable packages found | Cross-references installed package versions against known-CVE package databases | At least one installed package has a publicly known vulnerability with a fix already available - the exact same "patch exists, hasn't been applied" pattern that dominated the entire MedDefense scan report | `apt-get update && apt-get upgrade`, and ideally enable `unattended-upgrades` so this doesn't recur |
| 2 | Root filesystem **NOT ENCRYPTED** (`/` and `/boot/efi` on `/dev/nvme0n1p2` / `p1`) | Whether the disk is protected by DM-Crypt/LUKS at rest | If this machine is lost, stolen, or the drive is pulled and mounted elsewhere, every file - credentials, session tokens, personal data - is readable with zero additional effort | Full-disk encryption (LUKS) has to be set up at install time on most distros; retrofitting it requires a reinstall or a `cryptsetup`-based migration - worth doing before it's needed, not after |
| 3 | GRUB2 found, **no password protection** (`BOOT-5122`) | Whether the boot loader itself requires a credential before its menu can be edited | Anyone with brief physical access can edit boot parameters (e.g., append `init=/bin/bash`) and get a root shell without ever supplying a password - this bypasses every other authentication control on the box | Set a GRUB superuser password via `grub-mkpasswd-pbkdf2` and `/etc/grub.d/40_custom`, then `update-grub` |
| 4 | **Logging failed login attempts: DISABLED** | Whether failed authentication attempts get written anywhere | If this is off, a brute-force attempt against a local account produces zero log trail - the exact detection gap that let MedDefense's billing-server cryptominer run for two weeks across three "just restart it" tickets before anyone looked at the right log | Enable `pam_tally2`/`faillock` logging in PAM, and make sure `auth` facility logs are actually retained |
| 5 | **TIME-3185** - systemd-timesyncd hasn't synced recently | Whether the system clock is actually staying in sync with NTP, not just whether an NTP client is installed | Clock drift breaks certificate validation, Kerberos-style time-window auth, and - most relevantly to this whole project - log correlation across hosts during an incident (this is literally what Finding 022 flagged on ehr-srv-01 in the MedDefense report) | Check `timedatectl status` and network reachability to NTP servers; restart `systemd-timesyncd` if it's stuck |

### Top 5 Suggestions

Out of 47 listed, these 5 are the ones I'd actually act on first - each closes a distinct, meaningful security gap rather than being pure hygiene:

1. **Install fail2ban** (`DEB-0880`) - automatically bans hosts after repeated authentication failures. Directly mitigates the brute-force risk that Warning #4 above shows I have no visibility into at all right now.
2. **Install a PAM password-strength module** like `pam_cracklib`/`pam_passwdqc` (`AUTH-9262`) - enforces password complexity at the OS level instead of relying on users choosing good passwords voluntarily.
3. **Enable auditd** (`ACCT-9628`) - turns on kernel-level audit logging (file access, syscalls, privilege use). Right now this machine has *no* audit trail beyond whatever systemd's journal happens to capture by default.
4. **Install a file integrity monitoring tool** like AIDE or Tripwire (`FINT-4350`) - would detect unauthorized modification of system binaries or config files. Currently nothing on this machine would notice if `/usr/bin/ssh` got swapped for a backdoored copy.
5. **Install a malware scanner** like rkhunter or chkrootkit (`HRDN-7230`) - this machine currently has zero on-host malware/rootkit detection capability, confirmed directly by the scan (`Installed malware scanner: NOT FOUND`).

### Category Breakdown

Lynis doesn't print a numeric sub-score per category in the terminal output - the 62 is a single blended index - but reading through the sections, a clear pattern emerges:

**Strongest categories** (mostly `OK`/`FOUND`/`ENABLED`):
- **User/group account structure** - unique UIDs/GIDs, consistent password files, no accounts without passwords, no locked-account inconsistencies. The *bookkeeping* of accounts is clean.
- **Basic filesystem hygiene** - sticky bits set correctly, ACL support enabled, no stale files in `/tmp`.
- **Firewall** - host-based firewall active, iptables rules present and non-empty.
- **Networking basics** - no promiscuous interfaces, SYN cookies on, no waiting-connection anomalies.

**Weakest categories** (by far):
- **Boot and services**: GRUB has no password, Secure Boot is disabled, and running `systemd-analyze security` against every service shows the overwhelming majority rated **UNSAFE** - only about 7 of roughly 65 services came back `PROTECTED`, with a handful more at `MEDIUM` or `EXPOSED`. Service-level sandboxing on this machine is essentially not being used.
- **Kernel hardening**: comparing sysctl values against Lynis's hardened baseline, roughly half the checked keys - including `kernel.kptr_restrict`, `kernel.sysrq`, `kernel.yama.ptrace_scope`-adjacent settings, and several `net.ipv4`/`net.ipv6` redirect/forwarding controls - came back `DIFFERENT` from the recommended hardened value.
- **Accounting/auditing**: `auditd` not found, `sysstat` accounting disabled, process accounting off. There is effectively no audit trail on this system beyond default logs.
- **File integrity / malware / IDS-IPS / automation tooling**: every single one of these came back `NOT FOUND`. The entire "notice that something already went wrong" layer of defense is empty.
- **Cryptography (at rest)**: neither the root partition nor the boot partition is encrypted, and the one swap device in use is unencrypted too.

**What this says about the posture**: the pattern is *identity and account bookkeeping are fine, but hardening depth and detection are almost entirely absent*. This is close to a personal-machine mirror of the exact same shape Task 7 found across the whole MedDefense scan report - a system that isn't misconfigured in some obviously broken way, but that also has almost no defense-in-depth layered on top of "the basics work." Nothing here is actively exploited or actively broken; it's a system that would take real, sustained effort to actually harden, and nobody has done that work yet - which is a very different problem from "there's a bug," and a much more human one.


## Part 3: MedDefense Projection

I don't have access to billing-srv-01, but I know enough about it from the scan report and the 1x00 incident history to predict specific Lynis findings with real confidence - and my own machine's results give me a calibration point for what "normal, unhardened" looks like versus what an EOL, previously-compromised server would show on top of that baseline.

**1. A much longer, more severe `PKGS-7392`-class package vulnerability list.** My own up-to-date Ubuntu 24.04 machine still triggered this warning once. billing-srv-01 runs Ubuntu 18.04 with kernel `4.15.0-213-generic` - already confirmed in the scan report to carry 47 known CVEs - and no Extended Security Maintenance enrollment (Finding 011). Lynis's package-to-CVE cross-reference would almost certainly return a substantially longer list here, because unlike my machine, most of these packages have *no fixed version available at all* without ESM - the vulnerabilities aren't unpatched by choice, they're unpatched because no patch is being shipped anymore.

**2. The "Databases" section would flag MySQL directly, instead of reporting "No database engines found."** My own machine (no database installed) got a clean pass here by default. Finding 006 already establishes MySQL on billing-srv-01 is bound to `0.0.0.0`. Lynis has dedicated MySQL/database hardening checks (remote root access, anonymous accounts, test databases) - I'd expect it to explicitly flag the remote-bindable configuration as a warning, since that's precisely the kind of check this category exists to catch.

**3. SSH section would flag `PasswordAuthentication yes` and, likely, the same "Logging failed login attempts: DISABLED" finding I got locally.** My machine doesn't even run an SSH daemon, so I can't compare directly - but Finding 009 already confirms password authentication is enabled with no lockout policy on this exact host. Given that my own default Ubuntu install had failed-login logging disabled out of the box, I'd expect the same default to be true on billing-srv-01 unless someone deliberately changed it - which, per Finding 009, nobody did.

**4. Root filesystem `NOT ENCRYPTED`.** This is one of the most common gaps across ordinary server deployments - full-disk encryption has to be a deliberate decision at install time, and nothing about billing-srv-01's history suggests that decision was made. Given this server also has a confirmed prior compromise (the January cryptominer incident from the 1x00 root cause analysis), unencrypted disk means anything an attacker wrote to disk during that compromise - or anything they read, including database credentials or billing/financial data - was fully accessible the moment they had any filesystem access at all.

**5. `HRDN-7230`/`FINT-4350`-class suggestions - no malware scanner, no file integrity tool installed - and this prediction carries extra weight here specifically because of what already happened.** My own clean machine flagged this exact absence. On billing-srv-01, this isn't a hypothetical gap: the 1x00 root cause analysis documents that a cryptominer ran on this server for roughly two weeks, generating three separate performance tickets that were each closed as a hardware issue, before anyone identified it as malware. That's not a coincidence - it's the direct, observable consequence of this exact Lynis finding. If someone had run Lynis on this host *before* January and acted on `HRDN-7230`, there's a real chance the miner would have been caught by a file-integrity or rootkit check instead of by someone eventually noticing the pattern across three tickets.
