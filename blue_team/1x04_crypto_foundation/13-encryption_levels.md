# The Encryption Levels

## Comparison of the 6 Levels (Sec+ 1.4)

| Level | Scope | Performance Impact | Key Management | Use Case |
|---|---|---|---|---|
| **Full-disk** | Entire physical/virtual disk | Low — happens below the filesystem, hardware-accelerated (AES-NI) on modern CPUs | One key (or few) unlocks everything, typically tied to boot (TPM-backed or passphrase) | Laptops, physical servers, anything at risk of physical theft |
| **Partition** | One logical partition of a disk | Low, same as full-disk | Separate key per partition — more granular than whole-disk | Applying different policies to different sections of one disk (e.g., unencrypted boot partition, encrypted data partition) |
| **Volume** | A logical volume, which may span multiple physical disks | Low, same as full-disk (this is what Task 12's LUKS lab actually demonstrated) | One key per volume, decoupled from physical disk boundaries | Storage that's resized or spans disks — RAID arrays, NAS shares, LVM |
| **File** | Individual files | Moderate — overhead depends on how many files/how often they're accessed, but modern filesystem-level implementations (e.g., Linux fscrypt) are efficient | More complex — potentially many keys, or per-user/per-file keys to track | Documents that travel independently of the disk they were created on — attachments, shared files, individual images |
| **Database** | Entire database or tablespace (Transparent Data Encryption) | Moderate — modern TDE implementations add single-digit-percent overhead, transparent to queries | Single or few keys, managed by/integrated with the database engine itself | Protecting an entire database at rest with zero application code changes |
| **Record** | Individual fields or records within a database | **Highest** — every query touching an encrypted field pays a decrypt cost, and can break native indexing/search unless special techniques are used | Most complex — potentially different keys per field type, application-aware | Protecting a small number of exceptionally sensitive fields (SSN, psychiatric notes) while the rest of the database stays normally queryable |

**One-sentence "best choice" for each:**
- **Full-disk**: best when the primary threat is physical loss or theft of the whole device.
- **Partition**: best when one disk needs to carry sections with genuinely different protection policies.
- **Volume**: best when storage needs to scale, resize, or span physical disks while keeping one consistent encryption boundary.
- **File**: best when individual files need to travel or be shared independently, each with its own access boundary.
- **Database**: best when an entire database needs protection at rest with no changes to how the application queries it.
- **Record**: best when only a handful of specific fields carry exceptional sensitivity and need protection even from otherwise-authorized database users.

---

## MedDefense Encryption Level Map

| Data Store | Recommended Level | Justification |
|---|---|---|
| **Patient records (PostgreSQL, ehr-db-01)** | **Database (TDE)**, with **Record-level** as a targeted supplement for the most sensitive fields (e.g., behavioral health or substance-use notes subject to heightened 42 CFR Part 2 protection) | The whole database holds broadly sensitive PHI, so TDE protects everything transparently without touching application code; a small number of exceptionally sensitive fields warrant the extra record-level barrier even against DBAs with routine database access. |
| **Backup data (NAS-01)** | **Volume** | Matches Task 12's own LUKS lab directly, and matches the built-in Synology shared-folder encryption feature the audit notes confirm already exists but isn't enabled — the whole RAID array/backup share is the natural encryption boundary. |
| **Financial records (MySQL, billing-srv-01)** | **Database (TDE)** | Billing data (names, DOB, SSNs, insurance, card last-4) is sensitive across most of the schema, not confined to one or two columns — TDE covers the whole database without the performance/complexity cost record-level encryption would add here. |
| **Medical images (PACS, pacs-srv-01)** | **File** | DICOM studies are stored as individual files on the filesystem, not as database rows — file-level encryption matches how PACS actually stores data, and pairs naturally with DICOM TLS for the in-transit half (Task 0). |
| **Email (O365)** | **Already adequate at rest/in transit** (Microsoft-managed, roughly volume-equivalent); recommend **message-level** (S/MIME or Microsoft Purview Message Encryption) for any message actually containing PHI | Task 0 already rated O365 at-rest/in-transit as Adequate — the real gap is message *content* itself being sent in plaintext despite transport encryption (Sarah's own note: "I've told them not to email PHI. They do it anyway"), which only a message-level control can actually fix. |
| **Employee laptops** | **Full-disk** | The textbook full-disk use case — the dominant threat to a mobile device is physical loss or theft, and full-disk encryption protects everything on it with one boot-time key, no per-file complexity needed. |
| **BD Alaris pump firmware/configuration** | **File-level equivalent** (the device's stored configuration/credential data specifically), vendor-dependent | Embedded medical device firmware doesn't support general-purpose disk/volume encryption the way a server does — the realistic target is protecting the specific configuration and credential store on the device (directly relevant given Finding 010's confirmed unchanged default credentials), and that protection is gated entirely by what BD's firmware actually supports, not something MedDefense can add unilaterally. |
