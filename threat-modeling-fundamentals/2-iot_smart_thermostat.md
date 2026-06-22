# Assignment 2: IoT Smart Thermostat Threat Model


## Question 1: Five IoT-Specific Threats

IoT devices have unique threats because they are **physical devices with limited security**, long lifespan, and physical access possible.

### Threat 1: Physical Tampering & Debug Port Access (UART/JTAG)

**What:** Attacker gains physical access to device and uses debug ports to extract data

**How it works:**
```
1. Thermostat uses UART or JTAG debug port (common in IoT)
2. Attacker opens thermostat physically
3. Connects probe to debug port pins
4. Uses UART adapter (cost: $10 on eBay)
5. Dumps entire firmware from device memory
6. Extracts encryption keys, Wi-Fi passwords, API credentials
```

**Why web apps don't have this threat:**
- Web app runs in data center (physical access controlled)
- No debug ports available
- No hardware to tamper with

**Impact:**
- Extract Wi-Fi password → access home network
- Extract API keys → impersonate device
- Extract firmware → reverse engineer security

---

### Threat 2: Default or Weak Credentials

**What:** Device ships with default username/password (admin/admin) or hardcoded credentials

**How it works:**
```
1. Thermostat has default password: admin/password123
2. Attacker connects to device's WiFi
3. Logs in with default credentials
4. Takes control of thermostat
5. Or attacker finds firmware on GitHub, extracts hardcoded API key
```

**Why web apps don't have this threat:**
- Each user creates unique password during registration
- Web app doesn't have "factory default" credentials
- Users must set password (even if weak)

**Impact:**
- Complete device takeover
- Change temperature settings
- Disable heating (freeze home in winter)
- Exfiltrate data

---

### Threat 3: Unencrypted Wireless Communications

**What:** Device sends data over unencrypted WiFi or Bluetooth

**How it works:**
```
1. Thermostat sends temperature data to cloud: "Current temp: 72F"
2. NOT encrypted (sent as plaintext)
3. Attacker on WiFi network uses packet sniffer (Wireshark)
4. Captures all thermostat traffic
5. Learns home occupancy patterns:
   - Thermostat at 65F during day = nobody home
   - Thermostat at 72F at night = people sleeping
   - Can predict: when home is empty for burglary
```

**Why web apps don't have this threat:**
- HTTPS encrypts all data in transit
- Assumes network is hostile
- Web protocol requires encryption

**Impact:**
- Privacy violation (home occupancy patterns revealed)
- Burglary risk (attacker knows when you're away)
- Man-in-the-middle attacks

---

### Threat 4: No Over-The-Air Update Security

**What:** Device accepts firmware updates without verification (no signing, encryption, or rollback protection)

**How it works:**
```
1. Attacker intercepts firmware update traffic
2. Sends malicious firmware to thermostat
3. Device accepts and installs without verification
4. Malicious firmware: turns off heating, disables security, opens backdoor
5. Or attacker replays old vulnerable firmware
6. Device forced back to version with known exploits
```

**Why web apps don't have this threat:**
- Web app deployed centrally (no "firmware updates")
- No physical device to compromise
- Updates verified and signed

**Impact:**
- Remote code execution on device
- Persistent compromise (malware survives reboot)
- Downgrade attack (rollback to vulnerable version)

---

### Threat 5: Firmware Reverse Engineering & Key Extraction

**What:** Attacker extracts and analyzes device firmware to find security flaws or cryptographic keys

**How it works:**
```
1. Attacker obtains firmware (download from internet, or extract via UART/JTAG)
2. Uses disassembler (Ghidra, IDA Pro) to decompile code
3. Finds: hardcoded encryption keys, API secrets, Wi-Fi passwords
4. Discovers security flaws in code
5. Develops exploit that affects ALL thermostats with same firmware
6. Example: finds buffer overflow in temperature parsing
   Input: 99999999999999999999999999999999F (long number)
   Buffer overflow → code execution
```

**Why web apps don't have this threat:**
- Web app code on server (not distributed to clients)
- Only frontend code exposed (intended)
- Backend logic hidden

**Impact:**
- Extract secrets used by all devices
- Find zero-day exploits
- Mass compromise of all thermostats
- Develop worm that spreads across network


## Question 2: Physical Attack Chain & Impacts

**Objective:** Attacker gains physical access to thermostat. What can they do?

### Step-by-Step Attack Chain (7+ Steps)

#### Step 1: Disassemble Device

**Action:** Remove thermostat from wall

```
Tools needed:
- Screwdriver (any type, cost: $0-5)
- Time: 2 minutes
```

**Result:** Access to internal circuit board and debug ports

---

#### Step 2: Identify Debug Ports

**Action:** Locate UART or JTAG debug ports on circuit board

```
UART ports look like: 4 pins labeled TX, RX, GND, VCC
JTAG ports look like: 5-6 pins labeled TCO, TDI, TDO, GND

Available online for most IoT devices (GitHub, forums)
```

**Result:** Know which pins to connect to

---

#### Step 3: Connect UART Adapter

**Action:** Buy USB-UART adapter ($5-10 on Amazon), connect to pins

```
USB-UART adapter:
  GND (black) → GND pin
  TX (red)   → RX pin
  RX (white) → TX pin
  
Connect USB to laptop
```

**Result:** Can communicate with device bootloader

---

#### Step 4: Dump Firmware from Flash Memory

**Action:** Use tools to extract entire firmware from device

```
Tools: minicom, pySerial, or dedicated firmware extraction tools

Command: read_memory 0x0000 0xFFFFFF > firmware.bin

Result: Complete firmware file (~2-16 MB) saved to attacker's laptop
```

**Real-world example:**
```
Attacker dumps thermostat firmware
Finds hardcoded Wi-Fi password: "MyHomeWifi2024"
Finds API key: "sk_live_51234567890abcdef"
```

---

#### Step 5: Extract Wi-Fi Credentials & API Keys

**Action:** Analyze firmware to find stored secrets

```
Reverse engineer firmware using disassembler (Ghidra):
- Finds hardcoded Wi-Fi SSID and password
- Finds API keys for cloud service
- Finds encryption keys

Example found in firmware:
  const char wifi_ssid[] = "HomeNetwork";
  const char wifi_password[] = "MyPassword123";
  const char api_key[] = "sk_live_abc123";
```

**Result:** Attacker has Wi-Fi password and API credentials

---

#### Step 6: Connect to Home Wi-Fi Network

**Action:** Use stolen Wi-Fi password to access home network

```
From laptop or smartphone:
1. Open WiFi settings
2. Select "HomeNetwork"
3. Enter password: "MyPassword123"
4. Connected to home network

Now attacker is inside the home network with access to:
- Other IoT devices (cameras, locks, speakers)
- Router (access all traffic)
- Connected computers and phones
- NAS drives with home media
```

**Result:** Full access to home network from inside

---

#### Step 7: Pivot to Home Network Systems (Lateral Movement)

**Action:** Use position inside network to attack other devices

```
From home network, attacker can:

1. Access home router
   - Change DNS to phishing site
   - Sniff all network traffic
   - Disable security features

2. Access smart locks
   - Unlock front door remotely
   - Lock owners inside (ransomware)

3. Access home camera system
   - Watch live feeds
   - Know when house is empty (for burglary)

4. Access NAS/storage
   - Steal personal files, photos, financial documents
   - Blackmail homeowner

5. Access connected PC/laptop
   - Install malware
   - Steal passwords
   - Ransomware encryption
```

---

#### Step 8: Enable Remote Access / Install Backdoor

**Action:** Modify thermostat firmware to create persistent access point

```
Create backdoor in firmware:
1. Patch firmware to listen on backdoor port
2. Flash modified firmware back to thermostat
3. Even if physical attack ends, backdoor remains active
4. Attacker connects from internet: thermostat acts as tunnel to home network
5. Persistent access even if Wi-Fi password changed

Attacker now has:
- Permanent access to home network
- Cannot be removed by changing Wi-Fi password
- Survives thermostat power cycling
```

---

### Real-World Impact of Attack Chain

#### Financial Impact
```
Burglary: Home robbed while empty = $50,000+ loss
Ransomware: All devices locked, pay $5,000 ransom
Document theft: Medical/financial records sold on dark web
Identity theft: SSN, bank details compromised
```

#### Privacy Impact
```
Camera access: Live feed of home watched
Personal files: Photos, documents exfiltrated
Video: Intimate moments recorded
Blackmail: "Send money or I release videos"
```

#### Safety Impact
```
Disable heating in winter: Freeze home (pipe damage, health risk)
Lock occupants inside: Hostage situation
Disable security system: Home vulnerable
Door lock control: Enable break-in, prevent exit
```


---

## Question 3: Security Controls for OTA (Over-The-Air) Updates

An **OTA update** allows device to receive firmware updates wirelessly without physical connection.

### Essential Security Requirements

#### Digital Code Signing

**What:** Cryptographically sign firmware so device can verify it came from manufacturer

**Why critical:**
- Attacker cannot inject malicious firmware
- Device only accepts firmware signed by manufacturer's private key
- If tampered with, signature verification fails

**How it works:**

Manufacturer side:
1. Create firmware file: thermostat_v2.0.bin
2. Calculate hash of firmware: hash = SHA256(firmware)
3. Sign hash with private key: signature = RSA_sign(hash, private_key)
4. Upload firmware + signature to update server

Device side:
1. Receive firmware + signature from cloud
2. Calculate hash of received firmware
3. Verify signature using public key: RSA_verify(signature, hash, public_key)
4. If signature valid → hash matches → firmware authentic → install
5. If signature invalid → hash mismatch → firmware tampered → reject

Attack prevention:
- Attacker modifies firmware (payload)
- Payload hash changes
- But attacker cannot recalculate signature (needs private key)
- Device detects mismatch, rejects firmware


---

#### Secure Boot

**What:** Device verifies bootloader and kernel before executing them

**Why critical:**
- Even if firmware is signed, attacker could replace bootloader
- Secure boot chain: bootloader verifies kernel, kernel verifies app
- Each step verifies the next step

**How it works:**
```
Device startup sequence:

ROM (manufacturer code) - burned into chip, cannot be modified
    ↓ verifies signature of...
Bootloader (signed)
    ↓ verifies signature of...
Kernel (signed)
    ↓ verifies signature of...
Application (signed)
    ↓
System running

If any step fails verification → boot halts, device safe
Attacker cannot inject code at any level
```

---

#### Anti-Rollback Protection

**What:** Device cannot be downgraded to older vulnerable firmware versions

**Why critical:**
- Attacker obtains old firmware with known vulnerability
- Tries to "downgrade" device to vulnerable version
- Without protection, device accepts it
- Old exploit then works

**How it works:**
```
Device stores firmware version in secure storage:
  Current version: 2.0.5
  Secure counter: 2050 (stored in tamper-proof area)

Update arrives: version 2.0.3
  Version 2.0.3 counter: 2030

Device checks: Is 2030 > 2050? NO
  → Downgrade detected
  → Firmware rejected
  → Safe from rollback attack
```

---

#### Encrypted Update Channel (TLS/HTTPS)

**What:** Update travels over encrypted connection

**Why critical:**
- Prevents attacker from intercepting and modifying firmware in transit
- Man-in-the-middle attack prevented


---

#### Firmware Integrity Verification

**What:** Device recalculates hash after download and compares

**Why critical:**
- Download could be interrupted/corrupted
- Prevents installation of corrupted firmware
- Double-checks hash after receiving

---

#### Device Authentication (Mutual TLS)

**What:** Device proves its identity to update server, server proves to device

**Why critical:**
- Attacker cannot impersonate legitimate device
- Attacker cannot impersonate update server
- Mutual authentication (both sides verify each other)

---

#### Requirement 7: Delta Updates (Differential Firmware Updates)

**What:** Only send changed portions of firmware (not entire file)

**Why critical:**
- Reduces bandwidth (home internet may be slow)
- Reduces attack surface (less data transmitted)
- Faster update = less time exposed

**How it works:**
```
Old firmware: 16 MB
New firmware: 16 MB (but only 500 KB changed)

Delta update: Send only 500 KB of changes
Device applies changes to existing firmware
Result: Much smaller download = faster, more secure
```

---

#### Requirement 8: Rollback to Safe State

**What:** If update fails, device reverts to last known good firmware

**Why critical:**
- Update process interrupted = partial firmware loaded = broken device
- Device reboots and realizes firmware is corrupted
- Automatically reinstalls last working version
