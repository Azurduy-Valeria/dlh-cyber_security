# The Crypto Inventory: MedDefense Data Protection Map

Built from Sarah Park's crypto audit notes, cross-referenced against 1x02 vulnerability findings and 1x00 observations. A few cells are marked **N/A** rather than forced into "Absent" — some data categories genuinely don't have a meaningful state at rest, in transit, or in use (e.g., VPN traffic is never "at rest"). Forcing those into "Absent" would overstate the gap count.

---

## Data Protection Map

### 1. Patient Medical Records (EHR — PostgreSQL on ehr-db-01)

| State | Protection | Evidence | Status |
|---|---|---|---|
| At Rest | None | Audit notes: ext4 filesystem, no encryption layer — root/drive access = plaintext records | **Absent** |
| In Transit | Partial (SSL available, not enforced) | Audit notes: `ssl=on` but `pg_hba.conf` still allows `hostnossl` from the whole `/16`; can't confirm which sessions are actually encrypted. Also see 1x02 Finding 003 (same exposure, different angle) | **Weak** |
| In Use | None | Audit notes: decrypted in memory, no extra protection; nurse station screensaver timeout set to "Never" (1x00 Physical Assessment, Observation 3) | **Absent** |

### 2. Financial/Billing Data (MySQL on billing-srv-01)

| State | Protection | Evidence | Status |
|---|---|---|---|
| At Rest | None | Audit notes: unencrypted ext4; forensic review after the cryptominer incident found DB files readable without MySQL credentials | **Absent** |
| In Transit | None enforced | Audit notes: bound to `0.0.0.0`, no SSL enforcement, plaintext MySQL protocol; matches 1x02 Finding 006 | **Weak** |
| In Use | None (inferred) | Not separately documented in the audit, but consistent with the organization-wide pattern Sarah describes ("we encrypt almost nothing") | **Absent** |

### 3. Medical Images (DICOM on PACS)

| State | Protection | Evidence | Status |
|---|---|---|---|
| At Rest | None | Audit notes: local disk, unencrypted, headers partially readable in a text editor | **Absent** |
| In Transit | None | Audit notes: DICOM TLS exists as a standard (PS3.15) but isn't configured anywhere; matches 1x02 Finding 024 | **Absent** |
| In Use | None (inferred) | Not separately documented; same inferred pattern as above | **Absent** |

### 4. Credentials (Active Directory, application passwords)

| State | Protection | Evidence | Status |
|---|---|---|---|
| At Rest | Weak | Audit notes: NTHash (MD4) by default for NTLM; Kerberos still permits RC4 and DES alongside AES (1x02 Finding 018) | **Weak** |
| In Transit | Weak | Audit notes: LDAP not encrypted by default; matches 1x02 Finding 007 (LDAP signing not required) | **Weak** |
| In Use | None | Not addressed in the audit at all — no mention of credential/ticket memory protection (e.g., Credential Guard); treating an unaddressed gap as absent | **Absent** |

### 5. Backup Data (NAS-01)

| State | Protection | Evidence | Status |
|---|---|---|---|
| At Rest | None (available but unused) | Audit notes: RAID-5, no encryption; Synology's own AES-256-CBC shared-folder encryption exists but isn't enabled | **Absent** |
| In Transit | None (inferred) | Not directly documented (replication traffic to the NAS), but no encryption mechanism mentioned anywhere in the backup pipeline | **Absent** |
| In Use | — | N/A — backup data doesn't have a meaningful "in use/actively processed" state | **N/A** |

### 6. Email (O365)

| State | Protection | Evidence | Status |
|---|---|---|---|
| At Rest | BitLocker + per-mailbox encryption (Microsoft-managed) | Audit notes | **Adequate** |
| In Transit | TLS 1.2 enforced (Microsoft, since 2023) | Audit notes | **Adequate** |
| In Use | None at the message-content level | Audit notes: no S/MIME or OME configured; PHI gets emailed in plaintext content despite transport encryption, against Sarah's explicit instruction | **Weak** |

### 7. VPN Traffic (Site-to-Site Tunnels)

| State | Protection | Evidence | Status |
|---|---|---|---|
| At Rest | — | N/A — VPN traffic has no "at rest" state | **N/A** |
| In Transit | AES-256 + SHA-256, IKEv2/DH Group 14 | Audit notes — algorithm choice itself is solid | **Weak** (see note below) |
| In Use | — | N/A — same reasoning as At Rest | **N/A** |

**Note on VPN/In Transit**: the algorithms alone would rate "Adequate," but Sarah's own audit flags that the Westside end of the tunnel terminates on a consumer-grade router with unknown firmware/patch history. Strong encryption terminating on an unvetted endpoint isn't a real "Adequate" — rating it **Weak** reflects the actual end-to-end trust chain, not just the cipher suite on paper.

---

## Gap Summary

Of the 21 cells, **3 are Not Applicable** (Backup/In Use, VPN/At Rest, VPN/In Use), leaving **18 assessable cells**:

| Status | Count | % of assessable cells |
|---|---|---|
| Adequate | 2 | 11% |
| Weak | 6 | 33% |
| Absent | 10 | 56% |

**Overall crypto coverage**: Only **11%** of MedDefense's data flows have fully adequate protection — and both of those (email at rest/in transit) are protections Microsoft provides by default, not something MedDefense configured itself. If partial credit is given for "Weak" protection (counted as half-credit), the weighted coverage score is **(2×1 + 6×0.5 + 10×0) / 18 ≈ 28%** — still far from adequate, and this generous framing is the *best-case* read of the data.

The pattern matches Sarah's own summary exactly: "we encrypt almost nothing that we control." Every cell marked Absent or Weak in this map is a candidate for the remediation work in the rest of this project.
