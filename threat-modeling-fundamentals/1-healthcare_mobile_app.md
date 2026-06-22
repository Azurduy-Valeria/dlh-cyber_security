# Assignment 1: Healthcare Mobile App Threat Model

## Question 1: Most Critical Asset

### Patient Medical Records (PHI - Protected Health Information)

**Why it's most critical:**
Patient medical records are the most valuable and sensitive asset because they contain personal health information (PHI) and require protection under HIPAA (Health Insurance Portability and Accountability Act).


The CIA Triad has three components: **Confidentiality, Integrity, Availability**. Medical records need ALL THREE to be secure.

#### C - Confidentiality (Keep Private)

**What it means:** Only authorized people can read medical records

**Why critical:**
- Medical records contain sensitive info: diagnoses, medications, mental health, STI status, pregnancy, substance abuse history
- If exposed, patient faces discrimination, embarrassment, blackmail
- Employer could deny job if learning about health condition
- Insurance company could deny coverage
- HIPAA violation = $100-$1.5M fines per record

**Example of breach:**
```
Attacker hacks app, downloads all patient records
Patient finds records for sale on dark web
Patient's employer learns about mental health diagnosis
Patient gets fired
Patient sues hospital for $5M+ damages
```

#### I - Integrity (Keep Accurate)

**What it means:** Medical records cannot be modified by unauthorized people

**Why critical:**
- If medical data is altered, doctors prescribe wrong treatment
- If allergy list is modified, doctor prescribes allergen → patient dies
- If medication list is deleted, doctor doesn't know patient is on blood thinner → wrong surgery = hemorrhage
- Wrong medical data = patient death

**Example of tampering:**
```
Attacker modifies patient record:
  Removed: "Penicillin allergy"
  
Doctor sees no allergy warning
Doctor prescribes penicillin
Patient has severe allergic reaction → hospital
Patient could have died
```

#### A - Availability (Keep Accessible)

**What it means:** Doctors can access records instantly when needed

**Why critical:**
- Emergency room doctor needs patient history immediately
- If system is down, doctor cannot see critical info (heart condition, blood type, medications)
- Surgery scheduled but records unavailable = surgery delayed
- Patient dies because history wasn't available

**Example of DoS:**
```
Attacker floods system, causes crash
Patient has heart attack, arrives at ER
Doctor tries to access patient's cardiac history → system offline
Doctor doesn't know patient has cardiac condition
Surgery proceeds without knowing history
Patient dies from complications that could have been prevented
```

---

### Why ALL THREE Matter for Medical Records

| CIA Component | Impact of Failure | Severity |
|---|---|---|
| **Confidentiality FAILS** | Privacy violation, discrimination, HIPAA fines ($100-1.5M+) | CRITICAL |
| **Integrity FAILS** | Wrong treatment, patient death, lawsuit | CRITICAL |
| **Availability FAILS** | Emergency care delayed, patient death | CRITICAL |

---

## Question 2: Apply STRIDE to "Message Healthcare Providers" Feature

### Feature Overview
Patients can send messages to their doctors through the app. Doctors can reply with medical advice.

---

### Threat 1: Spoofing Identity (S)

**What:** Attacker impersonates doctor or patient

**Realistic scenario:**
```
1. Attacker hacks patient's app account
2. Attacker sends message pretending to be patient: "Stop taking my blood pressure medication"
3. Doctor reads message (thinks it's patient), replies: "OK I'll stop your prescription"
4. Real patient stops life-saving medication
5. Patient has heart attack = patient dies
```

**Or reversed:**
```
1. Attacker creates fake doctor account (if weak signup)
2. Sends patient message: "You don't need that medication anymore"
3. Patient stops medication believing doctor authorized it
4. Patient gets sick
```

**Impact:** Wrong medical decisions, patient harm

---

### Threat 2: Tampering with Data (T)

**What:** Attacker modifies message content

**Realistic scenario:**
```
1. Patient sends: "I have mild headache"
2. Attacker intercepts and changes to: "I have severe chest pain - EMERGENCY"
3. Doctor thinks patient is dying, emergency response activated
4. Wasted emergency resources
5. Or message says: "I'm allergic to penicillin" changed to "I'm NOT allergic to penicillin"
6. Doctor prescribes penicillin → patient has reaction
```

**Or tampering prescription:**
```
1. Doctor sends: "Take 1 tablet of aspirin daily"
2. Attacker intercepts and changes to: "Take 10 tablets of aspirin daily"
3. Patient overdoses on aspirin = poisoning
```

**Impact:** Wrong medical treatment, patient harm

---

### Threat 3: Information Disclosure (I)

**What:** Attacker reads private medical messages

**Realistic scenario:**
```
1. Attacker hacks app, accesses patient messaging
2. Reads messages about: STI diagnosis, mental health treatment, pregnancy, substance abuse
3. Attacker blackmails patient: "Pay me $10,000 or I send your HIV diagnosis to your employer"
4. Or attacker sells info to insurance company
5. Insurance denies coverage claiming "pre-existing condition"
6. Or attacker posts on social media
```

**Impact:** Privacy violation, blackmail, discrimination, HIPAA fines

---

### Threat 4: Repudiation (R)

**What:** Someone denies sending a message (no proof who sent it)

**Realistic scenario:**
```
1. Doctor sends message: "Take 1000mg of morphine"
2. Patient takes it, has adverse reaction
3. Patient tries to sue doctor
4. Doctor denies: "I never sent that message, you're lying"
5. No audit logs, no digital signature
6. No proof doctor sent it
7. Doctor gets away with harming patient
```

**Impact:** No accountability, no legal recourse for patient

---

### Threat 5: Denial of Service (D)

**What:** Attacker makes messaging system unavailable

**Realistic scenario:**
```
1. Attacker floods messaging system with 100,000 requests/second
2. System crashes
3. Patient cannot send message to doctor during emergency
4. Doctor cannot receive urgent patient messages
5. Patient needing immediate care cannot reach doctor
6. Patient condition worsens without communication
```

**Impact:** Delayed medical care, patient harm

---

### Threat 6: Elevation of Privilege (E)

**What:** Patient hacks system to read other patients' messages

**Realistic scenario:**
```
1. Attacker logs in as Patient A
2. Hacks system to read Patient B's messages to doctor
3. Learns about other patients' medical conditions
4. Uses info for blackmail or sells to insurance companies
```

**Impact:** Mass privacy breach, blackmail, HIPAA fines


---

## Question 3: Five Security Controls - Prioritized for Patient Data

### Priority 1: End-to-End Encryption (E2EE) / Encryption at Rest + In Transit

**What:** Encrypt medical data both in transit (traveling) and at rest (stored)

**Why it's priority 1:**
- Patient data is most sensitive asset
- If attacker steals data, encrypted = useless
- Protects against HIPAA violations
- Even if database is hacked, data is unreadable


---

### Priority 2: Multi-Factor Authentication (MFA) / Strong Authentication

**What:** Require multiple verification methods (password + phone confirmation)

**Why it's priority 2:**
- Prevents account takeover (Spoofing threat)
- Even if password stolen, attacker cannot login without phone
- Protects against: credential stuffing, brute force, phishing

---

### Priority 3: Access Controls & Authorization

**What:** Verify user has permission to access data

**Why it's priority 3:**
- Patient can only see their own records (not other patients)
- Doctor can only see messages for their patients
- Prevents privilege escalation and data breach

---

### Priority 4: Digital Signatures / Message Authentication

**What:** Sign every message so recipient can verify sender and message wasn't modified

**Why it's #4:**
- Prevents Tampering (attacker cannot modify without invalidating signature)
- Prevents Spoofing (proves who actually sent message)
- Prevents Repudiation (digital proof sender sent message)

---

### Priority 5: Comprehensive Audit Logging

**What:** Keep detailed logs of all access to patient data

**Why it's piority 5:**
- Proves who accessed what and when (prevents Repudiation)
- Detects suspicious activity (anomaly detection)
- Required by HIPAA for compliance
- Enables investigation after incident

