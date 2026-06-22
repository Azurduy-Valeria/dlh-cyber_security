# Assignment 0: E-Commerce Platform Threat Model

## Question 1: Three STRIDE Threats for Checkout Process

### Threat 1: Price Tampering (STRIDE: Tampering)

**STRIDE Category:** Tampering with Data

**Threat Description:**
Attacker modifies the product price in the checkout request. The frontend calculates the price, but an attacker can intercept the request and change `amount: 99.99` to `amount: 0.01` before sending to the server.

**How it happens:**
```
1. User adds item ($99.99) to cart
2. Frontend sends: POST /api/checkout { amount: 99.99 }
3. Attacker intercepts with Burp Suite
4. Changes to: { amount: 0.01 }
5. Server charges $0.01 instead of $99.99
```

**Potential Impact:**
- **Financial:** Revenue loss ($99 × thousands of transactions = millions lost)
- **Business:** Massive fraud if scaled
- **Integrity:** Order amounts are false/tampered
- **Severity:** HIGH (direct financial impact)

**Suggested Mitigation:**
Server-side price recalculation. Never trust price from frontend.


---

### Threat 2: Session Token Hijacking (STRIDE: Spoofing Identity)

**STRIDE Category:** Spoofing Identity

**Threat Description:**
Attacker steals the user's JWT authentication token. With the stolen token, the attacker can impersonate the user and access their account, view order history, and make unauthorized purchases.

**How it happens:**
```
1. User logs in and receives JWT token
2. Frontend stores in localStorage
3. Attacker uses XSS attack or public WiFi interception to steal token
4. Attacker sends requests with stolen token: 
   Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
5. Server accepts token and thinks attacker is legitimate user
6. Attacker views order history, modifies profile, places fraudulent orders
```

**Potential Impact:**
- **Confidentiality:** Access to user's personal data, order history, payment methods
- **Integrity:** Attacker modifies account information, places fake orders
- **Availability:** Account locked or misused
- **Severity:** CRITICAL (complete account compromise)

**Suggested Mitigation:**
Store JWT in httpOnly cookie to prevent XSS theft. Use HTTPS to prevent interception.


---

### Threat 3: Payment Data Interception (STRIDE: Information Disclosure)

**STRIDE Category:** Information Disclosure

**Threat Description:**
Attacker intercepts payment data (credit card info) during transmission. If the connection is not properly encrypted, or if payment data is transmitted over HTTP, the attacker can capture sensitive payment information.

**How it happens:**
```
1. User enters credit card info in checkout form
2. If not HTTPS: Attacker on public WiFi intercepts
3. Captures: card number, CVV, expiry date
4. Attacker uses card to make fraudulent charges
```

**Potential Impact:**
- **Confidentiality:** Credit card data exposed (PCI-DSS violation)
- **Financial:** Fraudulent charges, customer refunds, chargeback fees
- **Legal:** Fines for PCI-DSS non-compliance (up to $100,000+)
- **Severity:** CRITICAL (payment data exposure)

**Suggested Mitigation:**
Use Stripe tokenization. Never transmit or store raw credit card data. Always use HTTPS/TLS encryption.

---

## Question 2: Trust Boundaries

A trust boundary is where data crosses from untrusted to trusted zones. Each boundary needs security controls.

### Trust Boundary 1: User Browser ↔ Web Server (HTTPS/TLS)

**Location:** Between React frontend and Node.js API

**Data crossing:** Login credentials, cart data, payment tokens, personal information

**Why it's a boundary:**
- Browser is untrusted (user controls it, can be compromised)
- Server is trusted (you control it)
- Network is public (attacker could intercept)

**Security control required:** HTTPS/TLS Encryption


**Threats prevented:**
- MITM attacks
- Credential interception
- Payment data exposure

---

### Trust Boundary 2: Web Server ↔ Database (Protected Network)

**Location:** Between Node.js API and PostgreSQL database

**Data crossing:** All customer data, orders, passwords, payment records

**Why it's a boundary:**
- API server is semi-trusted (internet-facing, could be compromised)
- Database is highly trusted (most sensitive data)
- If API is hacked, entire database could be stolen

**Security control required:** Database authentication + limited permissions + encryption


**Threats prevented:**
- SQL injection via API
- Unauthorized database access
- Data theft from compromised server

---

### Trust Boundary 3: Web Server ↔ Stripe Payment Gateway (API Authentication)

**Location:** Between Node.js API and Stripe's external service

**Data crossing:** Payment tokens, charge amounts, customer information

**Why it's a boundary:**
- Your server is semi-trusted (could be compromised)
- Stripe is highly trusted (PCI-DSS certified)
- Direct card data should NEVER touch your server

**Security control required:** API key authentication + tokenization + HTTPS

**Threats prevented:**
- API key exposure
- Unauthorized charges
- Raw card data transmission
- PCI-DSS violations

---

**Summary - Trust Boundaries:**
| Boundary | Data | Control |
|----------|------|---------|
| Browser ↔ Server | Credentials, payments | HTTPS/TLS |
| Server ↔ Database | All customer data | DB auth + encryption |
| Server ↔ Stripe | Payment tokens | API key + tokenization |

---

## Question 3: DREAD Scoring for SQL Injection in Product Search

**Vulnerability:** Product search endpoint doesn't use parameterized queries


### DREAD Scoring Table

| Factor | Score | Justification |
|--------|-------|---|
| **D - Damage** | 9/10 | Complete database compromise. Attacker can extract all customer data, order history, passwords. Catastrophic impact. |
| **R - Reproducibility** | 10/10 | Attack works 100% of the time. No special conditions needed. Reliable exploitation every time. |
| **E - Exploitability** | 9/10 | Extremely easy. No special tools needed (just browser). SQLMap automates entire process. Basic payload syntax needed. |
| **A - Affected Users** | 10/10 | ALL users simultaneously. Every user's data can be extracted in single query. 100% of user base at risk. |
| **D - Discoverability** | 10/10 | Very easy to find. Search feature is front-and-center on website. Automated scanners find immediately. |
| **TOTAL SCORE** | **48/50** | **CRITICAL** |

### Factor Justifications

**Damage (9/10):**
- Can extract all customer PII (names, emails, addresses)
- Can extract password hashes
- Can extract all orders and payment history
- Can modify database records
- Can delete tables

**Reproducibility (10/10):**
- Works every single time if vulnerable
- No timing windows or special conditions
- SQL syntax consistent
- Payload: `' OR '1'='1'` works 100% reliably

**Exploitability (9/10):**
- Only needs browser (no special tools required)
- Manual testing takes seconds
- SQLMap fully automates (3-5 minute full database dump)
- Basic SQL knowledge needed
- Hundreds of tutorials online

**Affected Users (10/10):**
- EVERY user in database affected simultaneously
- Entire customer base at risk
- Cannot compromise "just some" users
- Complete user database can be stolen in one query

**Discoverability (10/10):**
- Product search is obvious attack surface
- Visible on main page (no need to find hidden endpoint)
- No authentication required
- Automated scanners (OWASP ZAP, Burp) find immediately
- SQL injection payloads in every security tool
- Attacker finds vulnerability in minutes

### Risk Level

```
SCORE: 48/50 = 9.6/10 = CRITICAL

Action Required:
- STOP DEVELOPMENT
- Fix immediately
- Requires CEO approval to ship with this vulnerability
```

---

