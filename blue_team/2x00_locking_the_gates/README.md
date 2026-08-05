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

Root is recommended (full SUID/world-writable sweep, listening-socket
process owners, sshd's fully resolved effective config) but not required:
run without `sudo` and the script still completes, with a warning on
stderr and a reduced-visibility snapshot (`ran_as_root: false` in the
JSON).

### Output

A human-readable summary prints to stdout:

```
Hostname: billing-srv-01
OS: Ubuntu 22.04.3 LTS
Running services: 24
Open ports: 11
SUID binaries: 23
SGID binaries: 12
World-writable files: 7
```

The full structured record is written to
`results/baseline_snapshot_<hostname>.json` (created on first run,
overwritten on each later run for that host - `results/` is git-ignored
since it's regenerated output, not a checked-in artifact).
