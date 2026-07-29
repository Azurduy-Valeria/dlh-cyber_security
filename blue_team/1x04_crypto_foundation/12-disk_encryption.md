# The Disk Encryption Lab

All commands actually run, including real `sudo cryptsetup` operations on a loop-backed file.

## Part 1: LUKS Setup

```
$ dd if=/dev/zero of=encrypted_volume.img bs=1M count=500
500+0 records in
500+0 records out
524288000 bytes (524 MB, 500 MiB) copied, 0.0802393 s

$ sudo cryptsetup luksFormat --batch-mode encrypted_volume.img
(passphrase supplied)
```

**Real LUKS header info** (via `cryptsetup luksDump`) — worth reading closely, since it directly confirms concepts from earlier tasks:
```
Version:        2
cipher:         aes-xts-plain64
Keyslots:
  0: luks2
     Key:        512 bits
     Cipher key: 512 bits
     PBKDF:      argon2id
     Time cost:  11
```
**LUKS2's own default key-derivation function is Argon2id** — exactly the algorithm recommended for MedDefense's own application passwords back in Task 3. This isn't a coincidence; it's the same real-world consensus about what resists brute-forcing a passphrase-derived key today.

```
$ sudo cryptsetup luksOpen encrypted_volume.img secure_vol
$ sudo mkfs.ext4 -q /dev/mapper/secure_vol
$ sudo mkdir -p /mnt/secure_test
$ sudo mount /dev/mapper/secure_vol /mnt/secure_test
$ echo "MedDefense confidential test data: Patient MRN-99201 backup verification string" | sudo tee /mnt/secure_test/test_data.txt
$ sudo umount /mnt/secure_test
$ sudo cryptsetup luksClose secure_vol
```

---

## Part 2: Verification

**With the volume closed, search the raw file for the plaintext we wrote:**
```
$ strings encrypted_volume.img | grep -i "MedDefense\|MRN-99201\|confidential"
(no output)
```
**Not found — confirmed.** The only human-readable content anywhere in the raw file is the LUKS2 header itself (a JSON blob describing the cipher, KDF parameters, and keyslot metadata) — which is *supposed* to be readable, since a client needs it to know how to attempt decryption at all. Everything past the header is indistinguishable from random noise; the actual plaintext I wrote is completely gone from the raw bytes.

**What this proves about encryption at rest**: the "at rest" protection is real and total — someone who steals the physical drive (or, for MedDefense, the actual NAS-01 hardware) gets a file full of high-entropy noise plus a public header describing *how* it's encrypted, not *the data itself*. This is precisely the scenario Sarah's crypto audit notes describe as currently unprotected: "if the NAS is stolen... every backup is readable in plaintext" — this lab is the proof that LUKS closes exactly that gap.

**Full reopen → mount → verify → close cycle:**
```
$ sudo cryptsetup luksOpen encrypted_volume.img secure_vol
$ sudo mount /dev/mapper/secure_vol /mnt/secure_test
$ cat /mnt/secure_test/test_data.txt
MedDefense confidential test data: Patient MRN-99201 backup verification string
$ sudo umount /mnt/secure_test
$ sudo cryptsetup luksClose secure_vol
```
Data survived the full close/reopen cycle intact, byte for byte.

---

## Part 3: Automation Script

See `12-luks_manager.sh`. Tested end-to-end (`create` → `open` → write a file → `close`) with real execution — confirmed the mapper device is created, the filesystem persists across the cycle, and `close` fully unmounts and removes the mapping.

---

## Part 4: MedDefense Backup Encryption Design (NAS-01)

**Encryption level: volume-level** (LUKS-style, or Synology's built-in AES-256-CBC shared-folder encryption already available per the audit notes), not full-disk or file-level. Full-disk encryption tied to NAS firmware can complicate RAID rebuilds and hardware replacement; file-level encryption (encrypting each database dump individually before it lands on the NAS) is more granular but operationally heavier — every backup job would need its own encryption step, and filenames/metadata stay exposed. Volume-level encryption protects the entire backup destination transparently: existing Veeam jobs keep working unmodified, and one key covers everything written there.

**Performance overhead**: based on Task 1's own benchmarking, AES on modern hardware with AES-NI acceleration adds single-digit-percent overhead to throughput, not a multiplier — `openssl speed` showed multi-gigabyte-per-second AES throughput on this same class of hardware. Since a nightly backup job is generally I/O-bound (network/disk transfer speed) rather than CPU-bound, the actual added time to the backup window should be minor — a reasonable planning estimate is a few percent longer, not meaningfully cutting into the backup window.

**Where the key is stored: NOT on the NAS itself** — ideally a dedicated key management system, or at minimum a separate, access-controlled system only specific IT staff can reach. Sarah's own audit notes already state exactly why: *"If we encrypt the backups on the NAS and the key is stored on the NAS, and ransomware encrypts the NAS, we lose both the backups AND the key."* Storing the key elsewhere means a NAS compromise (Finding 015) exposes ciphertext an attacker still can't read, and a physical NAS loss doesn't also destroy the only copy of the key needed to ever recover anything from an offsite copy.

**If the key is lost**: the backup data becomes permanently, cryptographically unrecoverable — full stop, no brute-force shortcut against a properly implemented AES-256 key. This is the real trade-off encryption introduces: it converts "ransomware destroys our backups" into a different failure mode, "we lose the key and destroy our own backups just as completely." The mitigation is **key escrow** — a securely stored second copy of the key, ideally split across at least two custodians or locations, so no single lost credential (or single compromised person) can either read the backups illegitimately or accidentally destroy access to them.

**Integration with offsite backup replication (1x03 Task 7's control)**: yes, the cloud replica must also be encrypted — both in transit (TLS to the cloud provider) and at rest once stored there. **MedDefense should hold the key itself** (a customer-managed key, e.g., a customer-managed CMK in AWS KMS) rather than relying solely on the cloud provider's own default server-side encryption with provider-managed keys. This preserves the same principle as the on-premises design: even if the cloud account or the provider's own infrastructure were compromised, decrypting the actual backup data still requires the separately-held MedDefense key, not just access to the storage bucket.
