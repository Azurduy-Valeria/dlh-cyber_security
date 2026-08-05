# 2x00 - Locking the Gates

## Task 0 - Baseline Snapshot

**Script:** [`0-baseline_snapshot.sh`](0-baseline_snapshot.sh)

Captures the complete pre-hardening security state of a host: identity
(hostname/OS/kernel/uptime), running services, open ports and listening
sockets, SUID/SGID binaries, world-writable files (excluding `/proc`,
`/sys`, `/dev`), security-relevant `sysctl` parameters, effective SSH
configuration, and active user accounts / sudo group membership.

It is read-only - it never modifies the system - which is what makes it
safe to re-run at any point for a fresh comparison snapshot.

### Usage

```bash
sudo ./0-baseline_snapshot.sh
```
