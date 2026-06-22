# Assignment 4: Cloud Storage Service Threat Model


## Question 1: Attack Surface Mapping - Entry Points Ranked by Risk

### What is Attack Surface?

The **attack surface** is the sum of all entry points where an attacker could interact with the system.

Every entry point is a potential vulnerability. We need to identify ALL entry points and rank by risk.

---

### Attack Surface Map

```
                          ATTACKER
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
    Internet            Admin Network         Physical
    (Public)            (Internal)            (Data Center)
        │                    │                    │
        ├─ Upload API        ├─ Admin UI         ├─ Server room
        ├─ Download API      ├─ Database         ├─ Debug ports
        ├─ Share API         ├─ Logs             └─ Hardware
        ├─ Public Links      └─ Config files
        ├─ Auth Endpoints
        ├─ API Keys
        └─ Third-party integrations
```

---

### All Entry Points with Risk Assessment

#### **HIGH RISK Entry Points**

### EP1: File Upload Endpoint (HIGH RISK)

**Description:** API endpoint where users upload files

**Endpoint:** `POST /api/files/upload`

**Why HIGH risk:**
- Directly accepts user input (file content)
- No authentication validation possible (what if auth is bypassed?)
- Large file size = can consume resources
- File type not validated = could upload malware

**Attack vectors:**
1. **Malicious file upload** - Upload virus, malware, ransomware
2. **File bomb / Zip bomb** - Tiny file that expands to 1TB (DoS attack)
3. **Path traversal** - Upload file to `/etc/passwd` instead of user folder
4. **Bypassing file type checks** - Upload .exe disguised as .pdf


**Mitigations:**
- Validate file type (check magic bytes, not just extension)
- Set file size limits (max 5GB per file)
- Reject suspicious file names
- Store in random name: `/uploads/uuid_random_name.bin`
- Scan with antivirus before accepting

**Risk Level:** **CRITICAL** (direct code execution possible)

---

### EP2: Public Link Sharing (`GET /api/share/:token`)

**Description:** Unauthenticated endpoint for accessing shared files via public link

**Endpoint:** `GET /api/share/abc123defg456`

**Why HIGH risk:**
- No authentication required (public)
- If token is guessable = anyone can access any file
- If token is leaked = file is compromised
- Could enable brute force attacks

**Attack vectors:**
1. **Weak token generation** - Token is sequential: 1, 2, 3, 4... (attacker guesses next)
2. **Token brute force** - Try all 6-digit tokens: 000000-999999
3. **Token leakage** - Shared link captured in logs, browser history, email
4. **No expiration** - Token valid forever, even if access should be revoked

**Mitigations:**
- Use cryptographically random tokens (at least 32 chars)
- Implement rate limiting (max 5 attempts per minute)
- Set expiration (token valid for 7 days, then expires)
- Log all share link access
- Revoke token when link is deleted

**Risk Level:** **CRITICAL** (unauthorized data access)

---

### EP3: Authentication Endpoints

**Description:** Login, password reset, OAuth endpoints

**Endpoints:** 
- `POST /api/auth/login`
- `POST /api/auth/reset-password`
- `GET /api/auth/oauth/google`

**Why HIGH risk:**
- Attacker entry point to user accounts
- Password reset vulnerable to social engineering
- OAuth misconfiguration = account takeover

**Attack vectors:**
1. **Brute force login** - Try 100,000 passwords per second
2. **Credential stuffing** - Use leaked credentials from other sites
3. **Phishing** - Send fake reset email with attacker's OAuth provider
4. **OAuth misconfiguration** - Accept tokens from attacker's OAuth app

**Mitigations:**
- Rate limiting: Max 5 login attempts per 15 minutes
- Account lockout: Freeze account after 10 failed attempts
- MFA: Require phone confirmation
- Password reset verification: Require email + SMS
- OAuth validation: Only allow trusted providers (Google, Microsoft)

**Risk Level:** **CRITICAL** (account takeover)

---

### EP4: API Key Endpoints (`GET /api/keys`, `POST /api/keys/create`)

**Description:** Endpoints for creating and managing API keys

**Why HIGH risk:**
- API keys grant access without password
- If leaked, attacker can access files indefinitely
- Often stored in version control by accident
- Not rotated frequently enough

**Attack vectors:**
1. **Leaked API key** - Key committed to GitHub, found by attacker
2. **API key theft** - Attacker steals key from user's app
3. **Weak API key generation** - Predictable keys can be guessed

**Mitigations:**
- API key rotation: Force rotation every 90 days
- Scope API keys: Key can only read, not write
- Rate limiting per key: Monitor unusual usage
- Log all API key access
- Alert on key usage from unusual location

**Risk Level:** **HIGH** (persistent access if leaked)

---

#### **MEDIUM RISK Entry Points**

### EP5: File Download Endpoint (`GET /api/files/:fileId/download`)

**Description:** Users download files they own

**Why MEDIUM risk:**
- Requires authentication (some protection)
- Could be used for resource exhaustion (download same file 1000 times)
- Could bypass authorization (access other users' files)

**Attack vectors:**
1. **Brute force file IDs** - Try to download fileId 1, 2, 3...
2. **Directory traversal** - Request `/api/files/../../admin_logs/download`
3. **Resource exhaustion** - Download 100GB file 100 times in parallel

**Mitigations:**
- Verify ownership: Check user owns file before download
- Rate limiting: Max 10 downloads per minute
- Path validation: Reject paths with ".."

**Risk Level:** **MEDIUM** (requires some authentication, limited damage)

---

### EP6: File Sharing Endpoints (`POST /api/files/:fileId/share`)

**Description:** Users share files with other users

**Why MEDIUM risk:**
- Requires authentication (some protection)
- Could share files without owner permission
- No validation of recipient identity

**Attack vectors:**
1. **Share files with wrong user** - Attacker modifies recipient ID
2. **Over-sharing** - Share sensitive files with attacker-controlled account
3. **Share permissions not revoked** - File shared permanently

**Mitigations:**
- Verify file ownership: Only owner can share
- Email confirmation: Recipient confirms share
- Time-limited shares: Auto-revoke after 30 days
- Share auditing: Log all share actions

**Risk Level:** **MEDIUM** (requires authentication, limited scope)

---

### EP7: Admin Interface

**Description:** Admin dashboard for managing users, files, system

**Why MEDIUM risk:**
- Only admins access (protected)
- But if compromised = full system takeover
- Often has weaker security than user-facing

**Attack vectors:**
1. **Admin account compromise** - Attacker becomes admin
2. **Admin interface vulnerability** - CSRF, XSS, SQL injection
3. **Weak admin password** - Admin password is "admin123"

**Mitigations:**
- Strong authentication for admins
- IP whitelist: Only allow from office IP
- MFA required for admins
- Admin actions require approval from second admin
- Audit all admin actions

**Risk Level:** **MEDIUM** 

---

#### **LOW-MEDIUM RISK Entry Points**

### EP8: File Versioning Endpoint (`GET /api/files/:fileId/versions`)

**Description:** Access previous versions of files

**Why LOW-MEDIUM risk:**
- Requires authentication
- Attacker could access deleted sensitive data (versions are kept)
- Could consume storage (versions not cleaned up)

**Mitigations:**
- Limit version history: Keep only last 10 versions
- Auto-delete old versions: Delete versions >30 days old
- Audit versioning access: Log who views versions

**Risk Level:** **LOW-MEDIUM** (limited damage, requires auth)

---

### EP9: Client-Side Encryption Keys

**Description:** Users' encryption keys in browser/mobile app

**Why LOW-MEDIUM risk:**
- If key extracted from client = all files decrypted
- Keys stored in app memory or device storage
- Could be extracted with debugging tools

**Mitigations:**
- Use secure enclave (hardware-backed key storage on phones)
- Never store keys in localStorage or app memory
- Use zero-knowledge architecture (only user has key)

**Risk Level:** **LOW-MEDIUM** (requires local device access or malware)

---

### EP10: Third-Party Integrations

**Description:** OAuth, API integrations with Google Drive, Dropbox, etc.

**Why LOW-MEDIUM risk:**
- Third-party could be compromised
- User could accidentally grant too much permission
- Token could be leaked

**Mitigations:**
- Request minimum permissions needed
- Validate tokens regularly
- Allow users to disconnect integrations anytime
- Audit third-party access

**Risk Level:** **LOW-MEDIUM** (depends on third-party security)

---

### Summary: Attack Surface Ranked by Risk

| Rank | Entry Point | Risk Level | Likelihood | Impact | Reason |
|------|---|---|---|---|---|
| **1** | File Upload | **CRITICAL** | High | Critical | Direct malware upload, DoS, path traversal |
| **2** | Public Share Links | **CRITICAL** | High | Critical | Weak tokens, brute force, data access |
| **3** | Authentication (Login) | **CRITICAL** | High | Critical | Account takeover via brute force |
| **4** | API Keys | **HIGH** | Medium | Critical | Persistent access if leaked, often exposed |
| **5** | File Download | **MEDIUM** | Medium | Medium | Requires auth, but could bypass authorization |
| **6** | File Sharing | **MEDIUM** | Medium | Medium | Requires auth, could share with attacker |
| **7** | Admin Interface | **MEDIUM** | Low | Critical | Only admins, but full compromise if breached |
| **8** | File Versioning | **LOW-MEDIUM** | Low | Medium | Could access deleted data, requires auth |
| **9** | Client Keys | **LOW-MEDIUM** | Low | Critical | Requires device compromise or malware |
| **10** | Third-Party Integrations | **LOW-MEDIUM** | Low | Medium | Depends on third party, user permission |

---

## Question 2: Storing Encryption Keys in Database - STRIDE Analysis

### The Problem

A developer proposes: "Let's store encryption keys in the database alongside encrypted data. Makes it convenient!"

**This is CRITICAL SECURITY FAILURE because:**

When database is breached, attacker gets:
- Encryption keys (useless if they weren't in DB)
- Encrypted data (useless without keys)
- But with BOTH: Everything is decrypted

---

### STRIDE Analysis: Why This Is Dangerous

#### S - Spoofing Identity

**Threat:** Attacker impersonates user after gaining encryption key

**How:**
```
1. Breach database, extract user's encryption key
2. Extract user's session token
3. Impersonate user, access files
4. Decrypt files with stolen key
```

**Impact:** Account takeover, data access

---

#### T - Tampering with Data

**Threat:** Attacker modifies encrypted files because they have key

**How:**
```
1. Extract encryption key from database
2. Decrypt file: "Invoice: $100"
3. Modify to: "Invoice: $10"
4. Re-encrypt with stolen key
5. Store modified encrypted data
6. User downloads, decrypts, sees false invoice
```

**Impact:** CRITICAL - Data integrity violated, financial fraud possible

**Why this matters:**
- With key in separate location = attacker cannot modify
- With key in database = attacker can decrypt, modify, re-encrypt
- User has no way to know file was tampered with

---

#### R - Repudiation

**Threat:** No audit trail of who accessed encrypted data

**How:**
```
1. Attacker uses stolen key to decrypt files
2. No audit log (key in same database = attacker controls logs)
3. Attacker modifies audit logs to cover tracks
4. User cannot prove attacker accessed files
```

**Impact:** No accountability, attacker undetected

---

#### I - Information Disclosure

**Threat:** ALL user data exposed due to single breach

**How:**
```
Normal setup:
- Database breached → encrypted data leaked (but key elsewhere)
- User data still protected (needs key from separate system)

Vulnerable setup:
- Database breached → both key AND data leaked
- ALL files immediately decrypted
- Complete data exposure
```

**Impact:** CRITICAL - All files for all users exposed

**Real-world example:**
```
Company breached, 50 million records leaked
News: "Encrypted database compromised"
Reality: Keys also compromised (in same database)
Result: All 50 million records decrypted, sold on dark web
```

---

#### D - Denial of Service

**Threat:** Attacker deletes encryption keys, making all files unrecoverable

**How:**
```
1. Attacker breaches database
2. Deletes all encryption keys
3. Users still have encrypted files, but no keys
4. Files permanently unreadable
5. Attacker holds keys for ransom
```

**Impact:** Files unrecoverable without ransom payment

---

#### E - Elevation of Privilege

**Threat:** Attacker uses encryption key to elevate to admin

**How:**
```
1. Extract encryption key from database (encrypted admin password?)
2. Decrypt admin password
3. Login as admin
4. Full system compromise
```

**Impact:** Complete system takeover

---

### Summary: STRIDE Threats from Key Storage in DB

| STRIDE | Threat | Impact |
|--------|--------|--------|
| **S - Spoofing** | Impersonate user with stolen key | Account takeover |
| **T - Tampering** | Modify encrypted files with stolen key | Data integrity violation |
| **R - Repudiation** | Modify audit logs, deny access | No accountability |
| **I - Info Disclosure** | All files decrypted when DB breached | Complete data exposure |
| **D - DoS** | Delete keys, render files unrecoverable | Ransom/extortion attack |
| **E - Elevation** | Decrypt admin password | System takeover |

**All 6 STRIDE categories affected by poor key storage**

---

### The CORRECT Way to Store Encryption Keys

#### Design 1: Keys Not in Database (RECOMMENDED)

SECURE DESIGN: Keys separate from data
Encryption keys stored SEPARATELY:
- Hardware Security Module (HSM) = dedicated hardware for keys
- AWS KMS = managed key service
- HashiCorp Vault = encrypted key storage
- Client-side encryption = user's device stores key (zero-knowledge)

Result: 
If database breached → encrypted data leaked, but keys safe
If key storage breached → keys leaked, but data protected differently
Attacker needs BOTH to decrypt = much harder


**Advantages:**
- Database breach doesn't expose keys
- Keys managed separately with stronger security
- Different security teams manage keys vs data

---

#### Design 2: Client-Side Encryption (ZERO-KNOWLEDGE)

**Advantages:**
- Server/cloud provider cannot access files even with direct access
- Impossible for administrator to view user files
- User has full control over encryption key
- Regulatory compliance (especially GDPR, HIPAA)

**Disadvantages:**
- If user loses password/device = files unrecoverable
- Sharing requires complex key exchange
- Cannot use password reset (would break encryption)

---

#### Design 3: Hardware Security Module (HSM)

```
┌─────────────────────────────────────────┐
│        Cloud Storage Service             │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    Application Server            │  │
│  │  (handles uploads, sharing)      │  │
│  └──────────────┬───────────────────┘  │
│                 │                       │
│                 │ Requests encrypted    │
│                 ▼ key (never sees key)  │
│  ┌──────────────────────────────────┐  │
│  │  Hardware Security Module (HSM)  │  │
│  │  - Encryption keys stored here   │  │
│  │  - Isolated hardware             │  │
│  │  - Cannot extract keys           │  │
│  │  - Tamper-proof                  │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘

// Application code:
app.post('/api/files/encrypt', (req, res) => {
  const { fileData, userId } = req.body;
  
  // Request HSM to encrypt (application never sees key)
  const encryptedData = hsm.encrypt(fileData, userId);
  
  // Store encrypted data in database
  db.insert('files', {
    userId: userId,
    encryptedData: encryptedData
    // Key stays in HSM, never stored in database
  });
});

// Result:
// Database breach = encrypted files, but no keys
// HSM breach = very difficult (isolated, tamper-proof)
// Attacker needs both = nearly impossible
```

**Advantages:**
- Keys never touch application code
- Hardware-level protection
- Industry-standard for financial/healthcare

**Disadvantages:**
- Expensive ($10,000+ per HSM)
- Complex setup
- Slower than software encryption

---

### Comparison: Key Storage Methods

| Method | Security | Ease of Use | Cost | Use Case |
|--------|----------|------------|------|----------|
| **Keys in DB** | ❌ CRITICAL | Easy | Free | NEVER USE |
| **Keys elsewhere in cloud** | ⚠️ Medium | Medium | Low | Small apps |
| **AWS KMS** | ✅ High | Easy | $1/month | Most services |
| **Client-side (Zero-Knowledge)** | ✅✅ Highest | Hard | Free | Maximum privacy |
| **Hardware HSM** | ✅✅✅ Highest | Hard | Expensive | Banks, healthcare |

---

## Question 3: Risk Matrix for Top 5 Threats

A **risk matrix** shows likelihood × impact = risk level.

Risk Score = Likelihood (1-5) × Impact (1-5)

```
Risk Levels:
- 1-4: LOW
- 5-9: MEDIUM
- 10-15: HIGH
- 16-20: CRITICAL
- 20-25: CATASTROPHIC
```

---

### Top 5 Threats Identified

#### Threat 1: Malicious File Upload (Code Execution)

**Threat Description:**
Attacker uploads malicious file (virus, ransomware, malware) that executes on server or client systems.

**Likelihood: 4/5** (Very Likely)
- File upload is obvious attack surface
- Easy to exploit (just upload a file)
- Automated tools can test file upload
- Many developers forget file validation
- Only slightly difficult: Requires bypassing file type check

**Impact: 5/5** (Catastrophic)
- Remote code execution on server = system compromise
- Ransomware executes = all files encrypted
- Worm spreads to other user systems
- Server completely compromised
- Attacker gains admin access
- Maximum possible damage

**Risk Score:** 4 × 5 = **20** = **CATASTROPHIC**

**Mitigation:**
- Validate file type (magic bytes, not extension)
- Antivirus scan all uploads
- Run uploads in sandboxed environment
- Store uploads separately from code
- Execute only authenticated files
- Set file size limits

---

#### Threat 2: Public Share Link Brute Force

**Threat Description:**
Attacker brute forces share tokens to access other users' files without permission.

**Scenario:**
```
Share link format: /share/abc123
Token is 6-character alphanumeric: 36^6 = 2.17 billion possible tokens

Attacker tries:
- 000000, 000001, 000002...
- 100 attempts/second = 566 years to try all (seems safe)

BUT: Many tokens invalid, only valid ones return file
If attacker tries 1000 different share links:
- One of them probably works (95% chance)
- Easy brute force
```

**Likelihood: 4/5** (Very Likely)
- Public links are obvious attack surface
- No authentication required = easy to test
- Weak token generation common
- Automated tools available
- Requires minimal skill

**Impact: 4/5** (Critical)
- Access to files without permission
- Privacy violation for shared files
- Could be sensitive documents (medical, financial)
- Not quite 5/5 because limited to shared files (not all files)

**Risk Score:** 4 × 4 = **16** = **CRITICAL**

**Mitigation:**
- Generate cryptographically random tokens (32+ chars)
- Use rate limiting (5 attempts/minute, then block)
- Set token expiration (7 days, then auto-revoke)
- Log all access attempts
- Alert on suspicious patterns

---

#### Threat 3: Encryption Key Storage in Database

**Threat Description:**
If keys stored in database, complete data compromise when database breached.

**Likelihood: 3/5** (Likely)
- Only happens if developer makes poor design choice
- Not likely in well-designed system
- But possible in rushed/underfunded projects
- Once data is breached, keys definitely compromised

**Impact: 5/5** (Catastrophic)
- All encrypted files immediately decrypted
- Complete data exposure for all users
- Attacker gets plaintext of everything
- No way to recover from this (data already stolen)
- Maximum damage

**Risk Score:** 3 × 5 = **15** = **HIGH/CRITICAL**

**Mitigation:**
- Store keys in separate system (KMS, HSM, vault)
- Never store keys in database
- Client-side encryption (zero-knowledge)
- Key rotation policy
- Audit key access

---

#### Threat 4: Database Breach (SQL Injection)

**Threat Description:**
Attacker uses SQL injection to access database, stealing user data, files, credentials.

**Likelihood: 3/5** (Likely)
- SQL injection requires vulnerable code
- With modern ORMs, likelihood reduced
- But still common in legacy systems
- Takes moderate skill to exploit

**Impact: 5/5** (Catastrophic)
- Access to all user data
- Access to encrypted files (even if can't decrypt)
- Access to user credentials
- Access to API keys
- Complete system compromise
- Could lead to data sale, ransom, identity theft

**Risk Score:** 3 × 5 = **15** = **HIGH/CRITICAL**

**Mitigation:**
- Use parameterized queries (ORM like Prisma, Sequelize)
- Input validation/sanitization
- Web Application Firewall (WAF)
- Regular security testing
- Intrusion detection system

---

#### Threat 5: Account Takeover (Brute Force / Credential Stuffing)

**Threat Description:**
Attacker compromises user account via brute force or stolen credentials.

**Likelihood: 4/5** (Very Likely)
- Users often reuse passwords across sites
- Credential breaches common (leaks available online)
- No rate limiting = easy brute force
- Automated tools available
- Very common attack in practice

**Impact: 4/5** (Critical)
- Access to user's files
- Privacy violation
- Could modify/delete files
- But limited to single user (not all users)
- Not quite 5/5 because doesn't affect system as a whole

**Risk Score:** 4 × 4 = **16** = **CRITICAL**

**Mitigation:**
- Rate limiting: 5 login attempts per 15 minutes
- Account lockout: Freeze after 10 attempts
- MFA required
- Password strength requirements
- Login alerts: "New login from Russia"
- Session timeout: 30 minutes inactivity

---

### Risk Matrix Table

| Risk ID | Threat | Likelihood | Impact | Score | Level |
|---------|--------|-----------|--------|-------|-------|
| **R1** | Malicious File Upload | 4 | 5 | **20** | 🔴 CATASTROPHIC |
| **R2** | Public Share Brute Force | 4 | 4 | **16** | 🔴 CRITICAL |
| **R3** | Keys in Database | 3 | 5 | **15** | 🟠 HIGH/CRITICAL |
| **R4** | SQL Injection / DB Breach | 3 | 5 | **15** | 🟠 HIGH/CRITICAL |
| **R5** | Account Takeover | 4 | 4 | **16** | 🔴 CRITICAL |

---

### Risk Matrix Visualization

```
IMPACT
  5 │ R3 ★    R4 ★    
    │ R1 ★
  4 │              R2 ★    R5 ★
    │
  3 │
    │
  2 │
    │
  1 │
    └─────────────────────────────────
      1    2    3    4    5    LIKELIHOOD

★ = Threat plotted on matrix

Red zone (Upper Right): CATASTROPHIC/CRITICAL
  - High likelihood + High impact = immediate action needed

Orange zone: HIGH/CRITICAL
  - Medium likelihood + Very high impact = urgent action

Yellow zone: MEDIUM
  - Could be either medium likelihood or medium impact

Green zone: LOW
  - Low likelihood or low impact
```

---

### Risk Prioritization

**Fix in this order:**
1. **R1 (File Upload)** - Score 20 - Fix IMMEDIATELY
2. **R2 (Share Brute Force)** - Score 16 - Fix within days
3. **R5 (Account Takeover)** - Score 16 - Fix within days
4. **R3 (Keys in DB)** - Score 15 - Fix before launch
5. **R4 (SQL Injection)** - Score 15 - Fix before launch

---

### Mitigation Summary

| Threat | Mitigation |
|--------|-----------|
| **File Upload** | Validate file type, antivirus scan, sandbox execution |
| **Share Brute Force** | Random tokens, rate limiting, expiration, logging |
| **Keys in DB** | Store in KMS/HSM, client-side encryption, key rotation |
| **SQL Injection** | Parameterized queries, input validation, WAF |
| **Account Takeover** | MFA, rate limiting, lockout, login alerts |
