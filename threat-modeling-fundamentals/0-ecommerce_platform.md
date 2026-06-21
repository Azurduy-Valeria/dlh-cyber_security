# E-Commerce Threat Model 

---

## Three STRIDE Threats for Checkout Process

### Threat 1: Price Tampering (STRIDE: Tampering)

**STRIDE Category:** Tampering with Data

**Threat Description:**
Attacker modifies the product price in the checkout request. Since the frontend calculates the price, an attacker can intercept the request and change the amount from $99.99 to $0.01 before the server processes it.

**How it happens:**
1. User adds item ($99.99) to cart and clicks checkout
2. Frontend sends: `{ amount: 99.99 }`
3. Attacker intercepts the request and changes it to: `{ amount: 0.01 }`
4. Server charges $0.01 instead of $99.99
5. Attacker gets product for $0.01

**Potential Impact:**
- **Business:** Lost revenue on every transaction
- **Integrity:** Order amounts are incorrect
- **Severity:** HIGH

**Mitigation:**
- **Server recalculates the price** - Never trust the amount from the frontend
- Always fetch product prices from the database on the server


---

### Threat 2: Session Token Stolen (STRIDE: Spoofing Identity)

**STRIDE Category:** Spoofing Identity

**Threat Description:**
Attacker steals the user's authentication token (JWT). With the stolen token, the attacker can impersonate the user and make purchases on their account.

**How it happens:**
1. User logs in, receives JWT token
2. Token stored in browser (localStorage)
3. Attacker uses XSS attack or WiFi interception to steal the token
4. Attacker uses stolen token to make API requests as the user
5. Attacker places orders and steals payment information

**Potential Impact:**
- **Confidentiality:** Attacker reads user's personal data and order history
- **Integrity:** Attacker modifies user's profile and payment methods
- **Severity:** CRITICAL

**Mitigation:**
- **Store token in httpOnly cookie** instead of localStorage
- httpOnly means JavaScript cannot access it (prevents XSS theft)
- Combine with HTTPS to prevent interception



---

### Threat 3: Shipping Address Changed (STRIDE: Tampering)

**STRIDE Category:** Tampering with Data

**Threat Description:**
Attacker modifies the shipping address during checkout. Instead of shipping to the user's address, the product ships to the attacker's address. Attacker receives the package.

**How it happens:**
1. User enters shipping address and clicks checkout
2. Frontend sends: `{ shippingAddress: "123 Main St" }`
3. Attacker intercepts and changes to: `{ shippingAddress: "456 Attacker St" }`
4. Product ships to attacker instead
5. User's credit card is charged, attacker receives product

**Potential Impact:**
- **Integrity:** Shipping address is changed
- **Business:** Fraud, customer disputes, refunds
- **Severity:** HIGH

**Mitigation:**
- **Server validates the address** - Use address stored in user's account, not the request
- Never accept address directly from the checkout request


---

## QUESTION 2: Trust Boundaries

A **trust boundary** is a line where data goes from one trust level to another. You need security controls at every boundary.

### Trust Boundary 1: User Browser → Web Server

**What:** Data traveling from the user's computer to your server

**Data crossing:** Login credentials, payment info, personal data

**Problem:** 
- Browser is controlled by the user (could be hacked)
- Internet connection is public (attacker could intercept)

**Solution:**
- Use HTTPS/TLS encryption
- Data is encrypted in transit, attacker cannot read it

```
User Browser (Untrusted)
    │
    ├─ HTTPS Encryption ─┤
    │
    ▼
Your Server (Trusted)
```

---

### Trust Boundary 2: Web Server → Database

**What:** Data traveling from your Node.js API to PostgreSQL database

**Data crossing:** All customer data, passwords, orders, payments

**Problem:**
- If API server is hacked, attacker could read entire database
- Database contains most sensitive information

**Solution:**
- Database should have separate login credentials
- Use encrypted connection to database
- Give database user only minimum permissions needed

---

### Trust Boundary 3: Your Server → Stripe (Payment Gateway)

**What:** Data traveling from your server to Stripe's payment service

**Data crossing:** Payment tokens, charge amounts, customer info

**Problem:**
- Your server could be hacked
- Actual credit card data should NEVER touch your server

**Solution:**
- Never send raw credit card numbers
- Stripe creates a "token" (temporary, one-time use)
- Your server only sends the token to Stripe, not the card


---

## QUESTION 3: DREAD Scoring for SQL Injection in Product Search

**What is SQL Injection?**
Attacker enters special characters in the search box that change the SQL query, allowing them to:
- Read all data from database
- Modify data
- Delete tables


### DREAD Scoring

| Factor | Score | Why |
|--------|-------|-----|
| **D - Damage** | 9/10 | Attacker can read/delete entire database. Catastrophic. |
| **R - Reproducibility** | 8/10 | Attack works reliably every time if code is vulnerable. |
| **E - Exploitability** | 8/10 | Easy to exploit - just need browser. Tools like SQLMap automate it. |
| **A - Affected Users** | 10/10 | ALL users affected - entire database can be compromised. |
| **D - Discoverability** | 9/10 | Easy to find - automated security scanners find this immediately. |
| **TOTAL SCORE** | **44/50** | **CRITICAL** |

### Score Explanation

**Damage (9/10):**
- Attacker can steal all customer names, emails, addresses
- Attacker can delete entire products table
- Attacker can modify orders
- This is catastrophic for business

**Reproducibility (8/10):**
- If the code is vulnerable, the attack works 100% of the time
- SQL syntax is consistent
- Not quite 10 because different databases have slight variations

**Exploitability (8/10):**
- Very easy to exploit
- No special tools needed (just a browser)
- SQL injection tutorials everywhere
- Tools like SQLMap automate the entire process
- Not quite 10 because basic SQL knowledge helps

**Affected Users (10/10):**
- EVERY user is at risk simultaneously
- Entire database can be stolen in one query
- This is the highest impact level

**Discoverability (9/10):**
- Product search is visible on main page
- No login required to test it
- Automated scanners immediately test for SQL injection
- Attacker can find this in minutes

### How to Fix SQL Injection

Use **parameterized queries**, this makes SQL injection impossible.
