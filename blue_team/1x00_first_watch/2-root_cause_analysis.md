# Root Cause Analysis: billing-srv-01 "Performance Degradation"

**Analyst:** Security Analyst, MedDefense Health Systems
**Subject:** Third recurring CPU saturation ticket on billing-srv-01
**Requested by:** James Chen, Deputy CISO

James asked to review the diagnostics before anyone signs off on the sysadmin's hardware upgrade recommendation. The evidence does not support a capacity problem. billing-srv-01 is compromised.

## What kworker is actually doing

The line that matters is this one:

```
8834   www-data  20   0  94.2   3.1    ./kworker -o stratum+tcp://pool.monero.org:4443
```

`kworker` is supposed to be a kernel worker thread. Legitimate kernel worker threads show up in `top`/`ps` wrapped in brackets, like `[kworker/0:1]` - they're kernel-managed, they don't live at a filesystem path, they don't take command-line flags, and they never open outbound network connections. This one is running from a local path (`./kworker`), it's owned by `www-data` (the web application user, not the kernel), and it's passing a `-o` flag pointing at `stratum+tcp://pool.monero.org:4443`.

`stratum+tcp://` is the standard protocol miners use to talk to a mining pool. `pool.monero.org` is a Monero (XMR) mining pool; Monero is the currency most commonly used for unauthorized mining because its privacy features make the mined coins difficult to trace back to the operator. This is cryptomining malware - most likely XMRig or a variant - running under a filename chosen deliberately to resemble a legitimate kernel thread in process listings. The disguise was effective enough that the same process generated three separate performance tickets, each closed as a hardware issue.

The fact that it's running as `www-data` tells me how it most likely got there: through the web application stack (Apache, per the `apache2` process in the same listing), not through an OS-level or SSH compromise. `/proc/8834/exe` resolves to `/var/www/html/.cache/kworker` — the binary is sitting inside a hidden directory under the web root, owned by `www-data`, not root. That ownership and location rule out a privileged/OS-level installation: whoever placed this file did so through the web application's own filesystem permissions, which means through the web application itself.

`config.json` in that same directory confirms it: three pool URLs (`pool.monero.org:4443`, plus two fallback pools on ports 8080 and 3333), a wallet address, and keys (`cpu-priority`, `threads`, `donate-level`, `background`) that match XMRig's configuration schema exactly. This is not a guess — it's the miner's own config file, hardened with fallback pools so it keeps mining even if one pool is blocked.

The netstat output corroborates all three connections: established sessions to `185.243.115.89:4443`, `91.121.87.10:8080`, and `104.238.140.32:3333`, all owned by PID 8834, alongside Apache's normal listener on port 80.

Timestamps matter here too. `stat` shows the binary and config were both written 14 days ago. The last manual restart of this server (ticket #4398) was 12 days ago. The miner predates that restart by two days and is still running now — meaning the reboot did not remove it. Something is re-launching it at startup (a cron entry, a systemd unit, or an init script we have not yet located). That is a persistence mechanism, not a one-off process, and it changes the remediation calculus: a service restart, or even a full reboot, has already been tried by the sysadmin's own timeline and failed to clear the infection.

## The real violations - before we even get to Availability

The sysadmin's ticket describes Availability impact ("CPU saturation," "undersized for the workload"). That's the visible symptom. It's not the primary problem, and it's not even the first pillar that was broken. Two things had to go wrong before the CPU ever spiked:

**1. Integrity.** An unauthorized binary was placed on this server and is currently executing. That is an unauthorized modification of the system itself - not of a data file, but of the system's own trusted state. The moment an attacker can drop and run their own process on billing-srv-01, we've lost the ability to say what else on that box is legitimate. Every other process, cron entry, and config file on that server is now suspect until proven otherwise.

**2. Confidentiality.** Whatever gave the attacker enough access to execute code as `www-data` gave them a foothold on the server that processes billing and claims data. A running foothold isn't just a mining platform - it's a vantage point. We have no logging that tells us this attacker didn't also read from the billing database, environment variables, config files with credentials, or anything else reachable from that user context. Absence of evidence of data theft is not evidence of absence; we simply don't have the visibility to rule it out.

Only after both of those have already happened does the CPU load climb high enough to page someone. Availability is the pillar that made this visible, not the pillar that was actually violated first.

## Why "upgrade the hardware" doesn't fix anything

If MedDefense buys a bigger box or migrates this VM to something more powerful, the miner keeps running - it just has more headroom to hide in. A miner tuned to consume 94% of a 4-core VM will happily tune itself to consume a smaller percentage of an 8-core VM and generate less CPU alerting in the process. We would be spending money to make the compromise quieter.

There is also direct evidence that a resource-level fix does not work here: ticket #4398 already restarted this server 12 days ago, two days after the miner was planted, and the miner survived that restart. A larger VM is a bigger version of a fix that has already failed once.

Nothing about a hardware upgrade addresses the actual problem: there is still an attacker-controlled process on the server, with a persistence mechanism that survives a reboot, and the access vector that let it get there in the first place remains open and unidentified. The recommendation treats the resource-consumption symptom while leaving the compromise itself in place.

## The question this raises about January

This is the same server that was hit by ransomware in January, and it was rebuilt after that incident. Now, months later, it's running cryptomining malware planted through the same application layer (Apache, running as `www-data`). Two unrelated attackers landing on the exact same box through the same process ownership is not a coincidence I'm willing to accept at face value.

Marcus's notes name a specific, checkable hypothesis: the billing application runs on Apache 2.4.29, a version with known, public remote-code-execution vulnerabilities, and he suspected that vulnerability was never patched during the January rebuild. That would explain both incidents with a single root cause — a vulnerable, unpatched Apache instance exposed on this server both before and after the rebuild, exploited first for ransomware deployment and later, independently, for cryptomining. I have not personally confirmed the Apache version is still 2.4.29 or reviewed patch logs from the rebuild, so I am treating this as the leading hypothesis rather than a settled conclusion, but it is consistent with everything in the diagnostics: the attacker had web-application-level access (`www-data`), not OS-level or SSH access, which is exactly what an unpatched Apache RCE would produce.

The question I want answered before we do anything else to this server is: **was Apache patched during the January rebuild, and if not, why not?** Until that is confirmed, rebuilding or upgrading billing-srv-01 again just resets the clock until the next compromise. Given what's already documented about this environment (flat 10.10.0.0/16 network, ehr-db-01 reachable from the entire subnet, SSH password auth still enabled on Linux hosts, no formal vulnerability assessment ever performed), I would not assume this server's exposure is unique to it. I want the Apache version and patch level confirmed, the access/error logs from around the file-drop date (14 days ago) reviewed to establish how the attacker got in, and the persistence mechanism keeping PID 8834 running across reboots identified and removed.
