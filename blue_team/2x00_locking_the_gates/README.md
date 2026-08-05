# 2x00 - Locking the Gates

## Background

Week seven at MedDefense Health Systems. The Board approved the security
strategy on Friday; this workstream is Phase 2 of the Crimson Tide 72-hour
emergency plan: infrastructure hardening.

Three Linux servers carry three weeks of risk sitting in production:

| Server | Role | Status |
|---|---|---|
| `billing-srv-01` | Ubuntu 22.04, Apache, MySQL, SSH | Fresh OS upgrade from 18.04 (resolves Finding 011), needs full hardening |
| `web-srv-01` | Ubuntu 22.04, Apache/Nginx, patient portal | Internet-facing, TLS already improved, OS-level hardening is zero |
| `log-srv-01` | Ubuntu 22.04, fresh build | Centralized log collection - must be the most hardened host, since a compromised log server lets an attacker erase evidence |

This directory produces **no report**. Every deliverable is a shell script
that either changes measurable system state or produces structured,
machine-readable JSON. The scripts are the documentation.

## Rules every script in this directory follows

- Shebang is exactly `#!/bin/bash`, every script is executable, every file
  ends with a newline.
- **Idempotent.** Running a script twice produces the same result as
  running it once - every mutating action is guarded by a check for the
  current state before it changes anything.
- **JSON out.** Every analysis, assessment or validation task writes a
  structured JSON file so results are auto-checkable, not just eyeballed.
- **Show the delta.** State is captured before hardening and again after,
  so the improvement is provable, not asserted.
- **Every deviation from the CIS Benchmark is justified in-line** with a
  comment explaining what was skipped and what compensating control (if
  any) replaces it.
- **Every hardening action is tied back to a finding or threat** from the
  MedDefense engagement (e.g. Finding 009 - SSH password auth, Finding 011
  - unsupported Ubuntu 18.04, Finding 026 - outdated kernel, or the
    Crimson Tide advisory) so the "why" survives alongside the "how."

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

### Output

A human-readable summary is printed to stdout:

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
overwritten on each subsequent run for that host - `results/` is
git-ignored since its contents are host-specific and regenerated on
demand, not checked-in artifacts).

## Author

Valeria Azurduy
