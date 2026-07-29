# The Implementation Playbook

## Action #1: Encrypt ehr-db-01 (PostgreSQL) + Enforce SSL-Only Connections

**Priority**: Immediate (CRYPTO-001/002, T15)
**System Affected**: ehr-db-01
**Prerequisites**: KMS/HSM key vault provisioned and reachable from ehr-db-01 (T14); a fresh, verified, tested backup taken immediately before starting (not just the routine NAS backup); maintenance window scheduled and communicated.

**Steps**:
1. Provision the TDE master key in the KMS/HSM vault; verify retrieval works from ehr-db-01 over the intended network path.
2. Put ehr-srv-01's application into maintenance mode to stop writes during the transition.
3. Enable PostgreSQL encryption at rest using the retrieved key.
4. Re-encrypt existing data files (the long-running step — estimate duration against DB size before finalizing the window).
5. Edit `pg_hba.conf`: remove every `hostnossl` line for `10.10.0.0/16`, leaving only `hostssl` entries.
6. Reload PostgreSQL to apply the config change.
7. Bring ehr-srv-01's application back online and watch its first connections.

**Validation**:
- Confirm the database engine reports the tablespace as encrypted.
- Attempt a non-SSL connection from a test host — confirm it's refused.
- Confirm a clinician can load a real patient record end-to-end.
- Compare query response time against a pre-change baseline.

**Rollback**:
- Restore from the pre-change backup if re-encryption fails or corrupts data.
- Revert `pg_hba.conf` if SSL enforcement breaks application connectivity.
- Maximum acceptable downtime: **4 hours overnight** — beyond that, roll back and reschedule with more staging time.

**Maintenance Window**: Overnight, required — this touches the live clinical EHR database directly.
**Communication**: James and Sarah + clinical department heads 48 hours ahead; on-call clinical staff notified the night of the change; all-clear sent the next morning.

---

## Action #2: Encrypt billing-srv-01 (MySQL) + Restrict Network Binding

**Priority**: Immediate (CRYPTO-004/005, T15)
**System Affected**: billing-srv-01
**Prerequisites**: Ubuntu Pro/ESM enrollment already completed (this should already precede any new complexity on this host, per 1x02/1x03's own sequencing); KMS/HSM key provisioned; verified backup taken.

**Steps**:
1. Provision the TDE key in the KMS/HSM vault.
2. Put the billing application into maintenance mode.
3. Enable MySQL InnoDB tablespace encryption via a keyring plugin pointed at the KMS.
4. Re-encrypt existing tablespaces.
5. Update `mysqld.cnf`: change `bind-address` from `0.0.0.0` to the specific required interface, and set `require_secure_transport = ON`.
6. Restart MySQL.
7. Bring the billing application back online.

**Validation**:
- Confirm tablespace encryption status via MySQL's information schema.
- Attempt a connection from a non-authorized host — confirm it's refused.
- Run a real test transaction through the billing application end-to-end.

**Rollback**:
- Restore from backup if re-encryption fails.
- Revert the bind-address/SSL requirement if legitimate connectivity breaks.
- Maximum acceptable downtime: **4 hours overnight**.

**Maintenance Window**: Overnight — avoid disrupting daytime claims submission deadlines.
**Communication**: IT Director, billing department lead, and Security Analyst 48 hours ahead; completion confirmed to billing before daytime operations resume.

---

## Action #3: Disable RC4/DES Kerberos Encryption + Require LDAP Signing

**Priority**: Immediate (CRYPTO-010/011, T15)
**System Affected**: ad-dc-01, ad-dc-02
**Prerequisites**: A completed inventory check confirming no legacy device/application genuinely depends on RC4/DES or unsigned LDAP (the exact caution 1x02/1x03 already flagged for this change).

**Steps**:
1. In Group Policy Management, open "Network Security: Configure encryption types allowed for Kerberos."
2. Enable only AES128/AES256 HMAC-SHA1; disable DES and RC4 options.
3. Set "Domain Controller: LDAP server signing requirements" to Require signing.
4. Force a Group Policy update domain-wide.
5. Monitor authentication logs closely for any failure pattern indicating a dependency on the disabled options.

**Validation**:
- Confirm only AES encryption types are negotiated for new Kerberos tickets.
- Attempt an unsigned LDAP bind from a test client — confirm it's rejected.
- Monitor domain-wide authentication success rates for 24–48 hours post-change.

**Rollback**:
- Revert the Group Policy settings if a legitimate legacy dependency breaks.
- Maximum acceptable downtime: **immediate rollback** on any clinical-staff authentication failure — this can't wait for a scheduled window given how central AD is to daily operations.

**Maintenance Window**: Business hours acceptable (a policy push, not a restart), but timed for early morning before peak login times, with IT actively monitoring for several hours after.
**Communication**: IT Director and Deputy CISO notified beforehand; helpdesk specifically briefed to watch for a login-failure ticket spike.

---

## Action #4: Enable NAS-01 Backup Encryption

**Priority**: Immediate (CRYPTO-013, T15)
**System Affected**: NAS-01
**Prerequisites**: KMS/HSM key provisioned and stored off the NAS (T14); DSM interface access already restricted per 1x02's own remediation; one more successful backup cycle confirmed on the old share as a fallback.

**Steps**:
1. Provision the volume encryption key in the separate key vault.
2. Create a new encrypted shared folder on the NAS (Synology's built-in AES-256 feature), using the externally-stored key.
3. Redirect the Veeam backup job's destination to the new encrypted share.
4. Run a full backup job to the new destination and confirm success.
5. After 2–3 successful nightly cycles, securely decommission the old unencrypted share.

**Validation**:
- Confirm the new share reports as encrypted in DSM.
- Run `strings` against the raw volume (same technique as Task 12's lab) — confirm no plaintext backup content is recoverable.
- Run a full restore test from the new encrypted backup to a test location.

**Rollback**:
- Redirect the Veeam job back to the old share if the new destination fails — do not delete the old share until at least 3 successful cycles are confirmed.
- Maximum acceptable downtime: if backups fail for more than **48 hours**, revert immediately to avoid a backup gap.

**Maintenance Window**: Business hours acceptable — this changes only the backup destination, not live production systems.
**Communication**: IT Director notified before starting; Security Analyst notified once cutover and restore test both succeed.

---

## Action #5: Harden Patient Portal TLS Configuration

**Priority**: Immediate (Finding 005, T11)
**System Affected**: web-srv-01
**Prerequisites**: A current, non-expiring certificate already installed (Task 10/17); the hardened config from Task 11 pre-tested against a staging copy.

**Steps**:
1. Back up the current Apache SSL configuration.
2. Apply the Task 11 hardened config: `SSLProtocol -all +TLSv1.2 +TLSv1.3`, restricted cipher suite, HSTS header, OCSP stapling, disabled session tickets/renegotiation.
3. Run `apachectl configtest` before reloading.
4. Reload (not restart) Apache to avoid dropping active connections.
5. Immediately test the live portal from an external browser over HTTPS.

**Validation**:
- Confirm TLS 1.0 is refused (`openssl s_client -connect portal:443 -tls1`).
- Confirm TLS 1.2 and 1.3 both still connect.
- Confirm the HSTS header is present in responses.
- Monitor access logs for a connection-failure spike from real patient traffic in the hour after — this is the one change most likely to visibly affect patients on very old browsers/devices.

**Rollback**:
- Restore the backed-up config and reload if a meaningful share of real patient traffic starts failing.
- Maximum acceptable downtime: roll back **immediately** if failure rate jumps noticeably above baseline within the first hour — don't wait to see if it self-resolves.

**Maintenance Window**: Low-traffic overnight window preferred, to allow monitoring before daytime patient volume begins.
**Communication**: IT Director and Deputy CISO notified beforehand; patient-facing help desk briefed in case older-browser patients report access issues in the following days.
