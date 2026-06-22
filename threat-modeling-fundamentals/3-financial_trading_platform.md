# Assignment 3: Financial Trading Platform Threat Model

## Question 1: Most Critical CIA Component - Can Security Conflict with Performance?

### The Answer: **Integrity** is Most Critical in Financial Systems

**Why Integrity (Not Confidentiality):**

In a trading platform:
- **Data leak** (Confidentiality failure) = Bad
  - But only affects one trader's portfolio data
  - Customer embarrassed, sues for damages
  - Impact: Single user's privacy, limited financial loss

- **Data modification** (Integrity failure) = CATASTROPHIC
  - Attacker changes: buy order quantity, sell price, account balance
  - Trader unknowingly places $1M order instead of $100 order
  - Trader loses $900,000
  - Or attacker transfers funds to their account
  - Impact: Direct financial loss, market manipulation, fraud

- **System downtime** (Availability failure) = Bad
  - But temporary (servers come back online)
  - Traders miss trades but no permanent data loss
  - Impact: Lost opportunity, frustration

**Why Integrity Is Most Critical:**
```
Integrity failure = Permanent financial loss (cannot be undone)
Confidentiality failure = Privacy loss (damage but not financial)
Availability failure = Temporary outage (recovers)

Integrity is the only one that causes actual money to disappear
```

**Regulatory Perspective (SEC/FINRA):**
- SEC Rule 10b-5: Prohibits fraud in securities trading
- FINRA Rule 2010: Requires fair dealing
- Integrity violation = Direct violation of securities law
- Fines: $1-100M+ for compliance violations

---

### Can Security Requirements Conflict with Performance?

**YES - There ARE conflicts between security and performance:**

#### Conflict 1: Encryption vs Speed

**Security:** Encrypt all trades (AES-256 encryption)
```
- Adds computational overhead
- Each trade takes extra milliseconds to encrypt/decrypt
- Increases latency
```

**Performance:** No encryption for speed
```
- Trades execute instantly
- But trades transmitted in plaintext
- Attacker can intercept and modify trades
```

**Trade-off:**
```
SECURE: 150ms latency (encrypt + verify)
FAST:   50ms latency (no encryption)

Problem: Financial trades need < 100ms latency
        So we need encryption that adds < 50ms overhead
        
Solution: Hardware acceleration, optimized crypto libraries
```

---

#### Conflict 2: Logging/Audit Trail vs Throughput

**Security:** Log every trade
```
- Record: who, what, when, where, how
- Prevents fraud (audit trail proves what happened)
- Required by SEC/FINRA regulations
- BUT: Disk writes slow down system
- Each trade generates log entry
- 1000 trades/second = 1000 disk writes = bottleneck
```

**Performance:** No logging for speed
```
- Trades execute instantly
- No disk I/O overhead
- But no proof of what happened
- Fraud/manipulation undetectable
```

**Trade-off:**
```
SECURE: Log every trade, audit trail, slower
FAST:   No logging, instant trades, but unauditable

Solution: Asynchronous logging
  - Log in background (doesn't block trade)
  - Trade executed instantly
  - Log written to separate system
  - Both security and performance
```

---

#### Conflict 3: Multi-Factor Authentication vs Speed

**Security:** Require MFA for all trades
```
- User logs in with password
- Receives SMS code
- User enters SMS code to confirm trade
- Prevents unauthorized trades
- BUT: Adds 30+ second delay (user typing SMS code)
```

**Performance:** No MFA for speed
```
- Instant trade execution
- But anyone with password can trade
- Account compromise = massive loss
```

**Trade-off:**
```
SECURE: MFA for all trades (+30 sec delay)
FAST:   Instant trades (no MFA)

Solution: Risk-based MFA
  - Small trade (<$1,000): No MFA needed (fast)
  - Medium trade ($1,000-$10,000): MFA required (security)
  - Large trade (>$10,000): MFA + manual approval (high security)
```

---

#### Conflict 4: Input Validation vs Latency

**Security:** Validate all inputs thoroughly
```
- Check trade amount is valid number
- Check price is within reasonable range
- Check user has sufficient funds
- Check order doesn't violate risk limits
- All this checking adds milliseconds of latency
```

**Performance:** Skip validation for speed
```
- Trade executed instantly without checks
- But invalid trades possible
- Prevent buffer overflows and injection attacks
```

**Trade-off:**
```
SECURE: Full validation (adds 10ms latency)
FAST:   No validation (instant, but unsafe)

Solution: Cached validation
  - Pre-validate known good data
  - Only validate new/unusual data
  - Keep validation efficient (< 1ms)
```


---

## Question 2: Threat Model - Automated Trading Rules Feature

### Feature Overview

Users can set automated trading rules like:
- "Sell all Tesla stock if price > $200"
- "Buy Bitcoin if price < $30,000"
- "Automatically rebalance portfolio weekly"

These rules execute automatically without user intervention.

---

### Top 3 Risks

### Risk 1: Malicious Rule Injection (Attacker Creates Draining Rule)

**What:** Attacker modifies user's trading rule to drain their account

**Attack scenario:**
```
Legitimate rule: "Sell AAPL if price > $150"

Attacker compromises user account and changes to:
"Transfer all cash to account 999999 every hour"

Rule executes every hour:
Hour 1: Transfer $10,000
Hour 2: Transfer $10,000
Hour 3: Transfer $10,000
...
By end of day: $240,000 transferred

User opens app at end of day, entire account empty
Account drained before user notices
```

**Impact:**
- Complete account compromise
- Financial loss (money transferred out)
- Attacker escapes with funds

**Mitigation:**
1. **Rule approval workflow**
   - When user modifies rule, require confirmation
   - Send email confirming rule change
   - User must explicitly approve before rule activates

2. **Rule validation/sandboxing**
   - Run rule in simulator first (test without executing)
   - Show user: "This rule would result in: sell 100 shares at market price"
   - User reviews simulation, approves

3. **Kill switch**
   - User can instantly disable all automated rules
   - Button: "Stop All Automated Trading"
   - Prevents further damage if account compromised

---

### Risk 2: Logic Flaws Causing Massive Unintended Trades (Race Condition)

**What:** Bug in rule logic causes unexpected behavior, user loses money

**Attack scenario 1 - Logic error:**
```
Rule: "Buy 100 shares if price drops 10%"

Bug in code: Rule misinterprets percentage
  User meant: "Drop 10% from last known price ($100)"
  Code calculated: "Drop 10% from ALL TIME LOW ($50)"
  
Market drops to $55
Rule triggers (thinking it's 10% drop)
Buys at $55 (not the intended $90)

User loses money because logic was wrong
```

**Attack scenario 2 - Race condition:**
```
Rule 1: "If AAPL > $150, sell all AAPL"
Rule 2: "If cash > $100,000, invest in AAPL"

Both rules check conditions at same millisecond:
  AAPL price: $150.01
  Cash: $100,001

Rule 1 executes: Sell all AAPL → get $100,000 cash
SAME MILLISECOND
Rule 2 executes: Buy AAPL with cash → spend $100,000

Both rules fired, user back where started, plus fees paid twice
Money lost to transaction fees
```

**Impact:**
- Unintended trades executed
- Transaction fees paid multiple times
- Account drained by repeated errors

**Mitigation:**
1. **Loss limits**
   - Set maximum loss per day: "Stop trading if down $5,000"
   - Circuit breaker: pause all rules if threshold reached

2. **Sandbox/simulation testing**
   - Before activating rule, test on historical data
   - Show: "This rule would have resulted in 47 trades over last 3 months, 32 profitable, 15 losses"
   - User sees outcome before risking real money

3. **Code review & testing**
   - Automated tests for common rule logic
   - Unit tests: "If price drops 10%, correctly identify"
   - Integration tests: "Multiple rules don't conflict"

---

### Risk 3: Unauthorized Rule Modification (Privilege Escalation)

**What:** Attacker gains access to another user's account and modifies their rules

**Attack scenario:**
```
Trader A has rule: "Buy index fund weekly"

Attacker compromises Trader A's account
Modifies rule to: "Sell all positions every hour"

Trader A's rule executes automatically:
Hour 1: Sell all holdings
Hour 2: No holdings left (nothing to sell)
Hour 3: No holdings (already sold)
...

By morning, Trader A's entire portfolio is liquidated
Market value lost, taxes owed on short-term gains
Trader loses hundreds of thousands
```

**Impact:**
- Account takeover
- Unauthorized trading
- Financial loss

**Mitigation:**
1. **Strong authentication**
   - MFA required for account login
   - MFA required for password change
   - Email confirmation for rule modification

2. **Principle of least privilege**
   - API tokens: Create restricted tokens for mobile app
   - Token A: "Can read trades" only
   - Token B: "Can modify rules" only (require extra auth)
   - Tokens expire frequently (daily renewal)

3. **Rate limiting on rule modifications**
   - Maximum 5 rule modifications per hour
   - Alert user: "Your rule was modified. Confirm this was you"
   - Unusual activity detected


---

## Question 3: Defense-in-Depth After Account Compromise

### Scenario

Attacker has compromised a trader's account. They have:
- Username and password
- Valid authentication token
- Can make API calls as the user

**Question:** What defense-in-depth controls limit damage?

### Eight Defense-in-Depth Controls

#### Control 1: Anomaly Detection System

**What:** Machine learning detects unusual trading activity

**How it works:**
```
Normal trader pattern:
- Trades 9:30 AM - 4:00 PM EST (market hours)
- Buys tech stocks (AAPL, MSFT)
- Average trade size: $5,000
- From NYC office (IP address)

Attack pattern detected:
- Trading at 2:00 AM (unusual time)
- From China IP address (unusual location)
- Buying penny stocks (unusual stock type)
- Trade size: $500,000 (huge spike)

System alerts: "ALERT: Unusual trading detected"
```

#### Control 2: Transaction Velocity Checks

**What:** Limit how fast trades can be placed

**How it works:**
```
Limit: Maximum 10 trades per minute

Normal trader: 1-2 trades per minute (fine)

Attacker tries: 1000 trades per minute (automated attack)
System detects: Velocity limit exceeded
System blocks: "Rate limit exceeded"
```

#### Control 3: Manual Approval for Large Trades

**What:** Require human approval for large trades

**How it works:**
```
Trade < $10,000: Auto-approved (fast)
Trade $10,000 - $100,000: Requires SMS confirmation
Trade > $100,000: Requires email + SMS + phone call verification

Attacker tries: $500,000 trade
System: "Requires phone call verification"
System calls trader: "Confirm $500,000 trade? Press 1 to confirm"
Trader: "I didn't authorize this!"
Trade blocked
```

#### Control 4: Device Binding / Trusted Device List

**What:** Only allow trades from trusted devices

**How it works:**
```
Trader normally trades from:
- Home laptop (Mac)
- Office desktop (Windows)
- Mobile phone (iPhone)

Attacker compromises account from:
- Unknown Linux server in Russia

System: "Unrecognized device. Cannot trade. Verify via email."

Trader receives email: "Trade attempt from new device"
Trader: "I didn't do that"
Trader clicks: "This wasn't me" in email
Attacker blocked
```

#### Control 5: Geolocation Verification

**What:** Verify trader is in expected geographic location

**How it works:**
```
Trader profile:
- Usually trades from New York, USA
- Sometimes from California, USA
- Never trades from other countries

Attacker trades from:
- Shanghai, China (impossible travel from NY to Shanghai in seconds)

System: "Trading from unexpected location. Verification required."
```


#### Control 6: Session Timeout & Continuous Authentication

**What:** Force re-authentication if session becomes suspicious

**How it works:**
```
Normal behavior: One login per day, session stays active
Attacker behavior: Multiple logins from different IPs in 1 hour

System detects: "Multiple login attempts"
System: Forces re-authentication
Attacker blocked
```

#### Control 7: Account Freeze / Emergency Lockdown

**What:** User can instantly freeze account to stop all trading

**How it works:**
```
Trader notices unauthorized trades happening
Trader clicks: "Emergency - Freeze Account"
System: Instantly disables all trading
Attacker cannot execute more trades
Damage limited
```

#### Control 8: Audit Trail & Forensic Logging

**What:** Log everything for later investigation

**How it works:**
```
Trade executed: Buy 100 AAPL at $150
Logged details:
- User ID, Account ID
- Timestamp (exact millisecond)
- IP address, Device ID, Browser
- Action: BUY
- Security (if trade approved/denied)

Later investigation:
- Security team reviews logs
- Identifies all trades made by attacker
- Reverses fraudulent trades
- Attacker prosecuted
```
