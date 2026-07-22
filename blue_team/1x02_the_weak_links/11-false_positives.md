## False Positive 1: OpenSSH Version Outdated

**Finding ID**: 020

**Reported Vulnerability**: OpenSSH 8.9p1 on backup-srv-01 is affected by CVE-2023-38408, a critical (CVSS 9.8) PKCS#11 provider vulnerability in `ssh-agent`.

**Why It Is a False Positive**: The scanner correctly identified the software version and correctly matched it to a real CVE - this isn't a bad version-match. The problem is exploitability preconditions: CVE-2023-38408 requires `ssh-agent` to be running *with agent forwarding enabled to a host the attacker controls*. SecurePoint's own note in the finding says exactly this: exploitation "requires ssh-agent forwarding to an attacker-controlled system, which is unlikely in this server's operational context." backup-srv-01 runs Veeam's backup agent - an automated, unattended process with no indication anywhere in the environment documentation that an administrator routinely SSHes *through* this box with agent forwarding turned on to some other, less-trusted server. Without that specific human workflow, the vulnerable code path is never reached, no matter how outdated the OpenSSH version is.

**Validation Method**: Check `sshd_config` and any admin `~/.ssh/config` files for `AllowAgentForwarding`/`ForwardAgent` settings, and review whoever administers backup-srv-01 about whether they ever jump through this host via forwarded agent to a third-party or cloud destination. Also confirm (via Task 4's research) that this CVE still has zero public Exploit-DB entries and isn't in CISA KEV - both of which held true as of this assessment.

**Risk of Acting on This FP**: Emergency-patching OpenSSH out of cycle on a production backup server, potentially disrupting Veeam's automated backup jobs during the maintenance window, spends real sysadmin hours and introduces its own change-management risk - all to close a door that was never open in this environment. That's time not spent on Finding 001/002 or Finding 007, which are genuinely Critical.

**Risk of Not Validating**: If it turns out someone *does* routinely forward their agent through this exact box to manage an external vendor's server (entirely plausible given MedTech Solutions' EHR maintenance contract or other third-party access), this becomes a real, remotely-triggerable path to code execution on the one server that connects to the organization's sole backup copy - precisely the asset Task 6 already flagged as a single point of failure. Dismissing this without ever asking the SSH-forwarding question would be dangerous specifically because of what this host protects.

## False Positive 2: TLS Certificate Common Name Mismatch

**Finding ID**: 030

**Reported Vulnerability**: The TLS certificate on ehr-srv-01 is issued for `ehr.meddefense.local`, but some clients connect via the IP address directly (10.10.2.10), triggering certificate validation warnings.

**Why It Is a False Positive**: The scan report says this itself, in plain language, at the end of the finding: *"This is an operational issue, not a security vulnerability."* It's easy to miss precisely because it's filed as Informational and sits near the bottom of the report - this is exactly the "resist the temptation to only read the red ones" discipline from Task 0 paying off. A CN mismatch when connecting by IP instead of hostname is expected TLS behavior, not a flaw: the certificate is doing exactly what it's supposed to do by refusing to silently validate a name it was never issued for. Notably, the scanner itself almost certainly triggered this exact warning by connecting to `10.10.2.10` directly during the authenticated scan, which is standard scanner behavior (target by IP), not evidence of a real operational pattern among actual users.

**Validation Method**: Check whether any *legitimate* traffic to ehr-srv-01 actually resolves and connects via the proper hostname (internal DNS/reverse-proxy logs) rather than the raw IP - if all real clinical traffic goes through `ehr.meddefense.local`, the mismatch only ever appears during infrastructure scanning or ad hoc admin access, confirming it as non-impactful in normal operation.

**Risk of Acting on This FP**: The tempting "fix" - issuing a certificate that also covers the internal IP address as a Subject Alternative Name - is itself a discouraged practice (IP SANs on internal certs create their own management overhead and occasionally security review flags), so acting on this risks spending effort creating a *worse* certificate configuration to silence a warning that was never a real vulnerability.

**Risk of Not Validating**: Close to zero from a pure security standpoint (the report already disclaims it), but there's a real secondary risk in blanket-dismissing findings like this without documenting *why*: if staff or clinicians get used to routinely clicking through certificate warnings on this system because "it's just the known IP thing," they lose the instinct to treat a *real* certificate warning (e.g., from an actual on-path attacker) as suspicious. A confirmed false positive still deserves a documented, communicated reason - not silent dismissal - precisely to avoid training people to ignore warnings in general.

## False Positive 3: System Clock Skew Detected

**Finding ID**: 022

**Reported Vulnerability**: ehr-srv-01's clock is 47 seconds ahead of the scanner's NTP reference; the finding warns this "can cause issues with certificate validation, Kerberos authentication, and log correlation."

**Why It Is a False Positive**: The measurement itself is real - the scanner didn't invent the 47-second offset. What's false is the *risk framing*. Kerberos's default clock-skew tolerance (both in Windows Active Directory and MIT Kerberos, via `krb5.conf`'s `clockskew` parameter) is **5 minutes (300 seconds)** - 47 seconds is roughly one-sixth of that tolerance and would never actually cause an authentication failure. TLS certificate validity windows are measured in months to years, so a sub-minute skew has no practical effect on certificate validation either. The only place a 47-second drift could matter at all is fine-grained log correlation during a very tightly-timed forensic reconstruction - a real but much narrower concern than the finding's broad framing suggests.

**Validation Method**: Check the domain's configured Kerberos clock-skew tolerance (`Default Domain Policy` → Kerberos Policy settings, or `krb5.conf`) and confirm 47 seconds sits well inside it - it does, by a wide margin. Also check `systemd-timesyncd`/NTP logs on ehr-srv-01 to confirm this is a stable, small, one-time reading rather than an actively growing drift (a genuinely unmonitored, worsening drift would eventually become a real problem, which the initial 47-second snapshot alone can't rule out).

**Risk of Acting on This FP**: Treating this as an urgent misconfiguration and pulling a sysadmin off other work to investigate "why Kerberos authentication is about to break" wastes time chasing a failure mode that isn't close to happening at this magnitude.

**Risk of Not Validating**: The risk isn't in this specific 47-second reading - it's in assuming a snapshot means "always fine" and never checking again. If the underlying NTP sync is actually failing (not just briefly lagging) and the drift grows unchecked, it could eventually cross the Kerberos tolerance threshold or genuinely complicate log correlation during a future incident - exactly the kind of forensic-timeline problem Task 0 already flagged as a real risk in this environment. A confirmed-fine reading today doesn't mean the underlying NTP client is healthy; that's worth a one-time check, not a recurring worry.

