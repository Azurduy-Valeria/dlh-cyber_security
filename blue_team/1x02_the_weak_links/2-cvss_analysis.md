## Exercise 1: Deconstruction

**Vector** (Finding 001, CVE-2021-44790): `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`
**Base Score**: 9.8 (Critical)

### AV - Attack Vector

**Stands for**: How close to the target the attacker needs to be to exploit it.

**Selected value**: **N (Network)** - the vulnerable component is bound to a network stack and exploitable remotely, up to and including across the internet.

**Other possible values**:
| Value | Meaning | Effect on score |
|---|---|---|
| A (Adjacent) | Attacker must be on the same physical/logical network segment (same broadcast domain, Bluetooth range, etc.) | Lower - smaller pool of potential attackers |
| L (Local) | Attacker needs local access - a shell, a logged-in session | Lower still - requires an existing foothold |
| P (Physical) | Attacker needs to physically touch the device | Lowest - hardest precondition to meet |

**Why N was selected here**: mod_lua's `r:parsebody()` processes the body of an incoming HTTP request. Any client that can reach port 80 on billing-srv-01 - which the report shows is a live Apache service - can send the crafted request. No prior foothold, adjacency, or physical access is needed; this is exploitable from anywhere the network route exists.

### AC - Attack Complexity

**Stands for**: Whether conditions outside the attacker's control (timing, specific configuration, race conditions, needing to defeat a mitigation) must exist for the attack to succeed.

**Selected value**: **L (Low)** - no special access conditions or circumstances beyond what's already assumed (mod_lua being loaded is a *precondition of the vulnerability existing at all*, not "attack complexity" in the CVSS sense - complexity is about repeatable, on-demand exploitation once the vector applies).

**Other possible value**:
| Value | Meaning | Effect on score |
|---|---|---|
| H (High) | Success depends on conditions the attacker can't reliably engineer (e.g., winning a race condition, needing information not readily available) | Lower - attack is not repeatable on demand |

**Why L was selected here**: once mod_lua is loaded, a crafted request reliably triggers the overflow every time - there's no race window or extra reconnaissance step required.

### PR - Privileges Required

**Stands for**: The level of access the attacker must already have on the vulnerable system *before* launching the attack.

**Selected value**: **N (None)** - no account or authentication of any kind is needed.

**Other possible values**:
| Value | Meaning | Effect on score |
|---|---|---|
| L (Low) | Attacker needs a basic authenticated account (user-level) | Lower - filters out unauthenticated attackers |
| H (High) | Attacker needs significant/admin-level access already | Much lower - if you already have that access, the vulnerability adds little |

**Why N was selected here**: the billing application accepts requests (e.g., a form submission) without requiring a login. This is what makes the RCE chain in Finding 001→002 so dangerous - no credentials are a barrier at all.

### UI - User Interaction

**Stands for**: Whether a human other than the attacker (a victim) has to do something - click a link, open a file - for the exploit to work.

**Selected value**: **N (None)** - fully automatable, no victim action needed.

**Other possible value**:
| Value | Meaning | Effect on score |
|---|---|---|
| R (Required) | A victim must take some action (open an attachment, visit a page) | Lower - success now depends on tricking a person |

**Why N was selected here**: the attacker talks directly to the web server; there's no second party in the loop to be tricked.

### S - Scope

**Stands for**: Whether the impact of the vulnerability stays confined to the vulnerable component's own security authority, or spills over into a different one (e.g., a container escape reaching the host, a browser plugin bug reaching the OS).

**Selected value**: **U (Unchanged)** - the compromise (RCE as the `www-data` process) stays within the same authority as the vulnerable component itself.

**Other possible value**:
| Value | Meaning | Effect on score |
|---|---|---|
| C (Changed) | The exploited component can impact resources beyond its own security scope | Generally *raises* the score for high-impact vulnerabilities - CVSS's formula weighs a scope-crossing compromise as worse, and also changes how the Privileges Required metric is weighted |

**Why U was selected here**: the initial RCE from mod_lua stays inside the web server process/OS boundary. (Notably, Finding 002 documents the *next step* - privilege escalation to root - as a **separate** CVE/finding rather than folding it into this one as a scope change; CVSS scores the vulnerability described, not the full attack chain a human analyst can build from it.)

### C / I / A - Confidentiality, Integrity, Availability Impact

**Stands for**: The degree of loss to each property if the vulnerability is exploited - confidentiality (unauthorized disclosure), integrity (unauthorized modification), availability (denial of legitimate access).

**Selected value for all three**: **H (High)** - total loss. Complete disclosure of all data on the system, complete ability to modify anything, complete ability to deny access.

**Other possible values** (same scale for all three metrics):
| Value | Meaning | Effect on score |
|---|---|---|
| L (Low) | Some loss, but access/control/availability is limited or partial | Lower |
| N (None) | No loss to that property at all | Lower still |

**Why H/H/H was selected here**: a buffer overflow in the request parser that leads to remote code execution doesn't give the attacker a *partial* foothold - it gives them arbitrary code execution as the web server user, meaning they can read any file that process can read, write/modify anything it can write, and crash the service at will. There's no natural "partial" version of an RCE.

### Recalculating with AV changed from Network to Local

New vector: `CVSS:3.1/AV:L/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`

Walking the same formula the calculator uses:
- **Exploitability** = 8.22 × AV × AC × PR × UI. Only AV changes, from 0.85 (N) to 0.55 (L): 8.22 × 0.55 × 0.77 × 0.85 × 0.85 ≈ **2.515** (down from 3.888 with AV:N)
- **Impact** is untouched by AV, so it stays at ≈ **5.873**
- Base Score = roundup(Impact + Exploitability) = roundup(5.873 + 2.515) = roundup(8.388) = **8.4**

**New score: 8.4 (High)**, down from 9.8 (Critical).

**Why it changes**: Attack Vector only feeds the *Exploitability* half of the score, not Impact - the damage an attacker can do once they succeed (full RCE) is identical either way. What changes is how easy it is to *get there*. Network access is the easiest possible precondition to satisfy (any host that can route to port 80 qualifies); Local access means the attacker must already have a foothold on the box - a shell, a local account, physical console access. That's a meaningfully harder bar to clear, so CVSS discounts the exploitability sub-score, which pulls the overall base score down even though the "what happens if it works" half of the equation never moved. This is a good illustration of why reading the vector string matters more than the headline number: two vulnerabilities can have identical *impact* and still land in different response-priority tiers purely because of how reachable they are.


## Exercise 2: Construction

**Given characteristics**:
- Exploitable only from the local network, not the internet → **AV:A**
- Exploitation is complex, requires specific conditions → **AC:H**
- Attacker needs low-level privileges → **PR:L**
- No user interaction needed → **UI:N**
- Scope unchanged → **S:U**
- Confidentiality completely compromised → **C:H**
- No impact on integrity → **I:N**
- No impact on availability → **A:N**

**Constructed vector**: `CVSS:3.1/AV:A/AC:H/PR:L/UI:N/S:U/C:H/I:N/A:N`

**Manual calculation** (verifying what the calculator would show):
- Exploitability = 8.22 × AV(A=0.62) × AC(H=0.44) × PR(L, unchanged scope=0.62) × UI(N=0.85)
  = 8.22 × 0.62 × 0.44 × 0.62 × 0.85 ≈ **1.182**
- Impact Sub-Score (ISC) = 1 − [(1−0.56) × (1−0) × (1−0)] = 1 − 0.44 = 0.56
- Impact (Scope Unchanged) = 6.42 × 0.56 ≈ **3.595**
- Base Score = roundup(Impact + Exploitability) = roundup(3.595 + 1.182) = roundup(4.777) = **4.8**

**Vector**: `CVSS:3.1/AV:A/AC:H/PR:L/UI:N/S:U/C:H/I:N/A:N`
**Base Score**: **4.8**
**Severity**: **Medium** (4.0–6.9 band)

This lines up with intuition: even a *complete* confidentiality break (C:H) is pulled down into Medium territory once you stack three limiting factors on the exploitability side - adjacent-only access, high complexity, and a privilege prerequisite - and the fact that two of the three impact categories (I, A) aren't affected at all.


## Exercise 3: Comparison

**Above 9.0**: Finding 001, CVE-2021-44790 - `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` = **9.8**

**Closest available comparator (5.0–7.0 band)**: Here's an honest catch worth flagging before doing the comparison - **no finding in this scan report actually carries a CVSS Base Score between 5.0 and 7.0.** Every finding that got a real CVSS number (not "N/A" scanner heuristic) landed at 7.5 or higher: F001 (9.8), F002 (7.8), F004's three CVEs (8.1, 9.8, 10.0), F005 (7.5), F008's CVE-2021-34527 (8.8), F010 (7.5), F020 (9.8), F029 (7.5), F031 (9.8). Everything the report labels "Medium" or "Low" by scanner severity has **no formal CVSS vector at all** - those are configuration findings (weak headers, exposed admin interfaces, EOL status) that OpenVAS rates by internal heuristic rather than mapping to a scored CVE. That's a real gap in the report, not an oversight on my part, and it's consistent with the observation from the First Impressions task that "Medium" severity in this document doesn't mean "CVSS 4–7" - it means something closer to "a real problem without an assigned CVE."

So the comparison below uses the two real, CVE-backed vectors that sit closest together and still show a meaningful score gap:

**Above 9.0**: Finding 001 - `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` = **9.8**
**High but lower** (closest real comparator, 7.0–7.9 range): Finding 005, CVE-2011-3389/CVE-2014-3566 (BEAST/POODLE) - `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N` = **7.5**

| Metric | Finding 001 (9.8) | Finding 005 (7.5) | Same? |
|---|---|---|---|
| AV | N | N | ✓ same |
| AC | L | L | ✓ same |
| PR | N | N | ✓ same |
| UI | N | N | ✓ same |
| S | U | U | ✓ same |
| C | H | H | ✓ same |
| **I** | **H** | **N** | ✗ different |
| **A** | **H** | **N** | ✗ different |

**What explains the gap**: Every exploitability-side metric (AV, AC, PR, UI, S) is identical between the two - both are unauthenticated, network-reachable, low-complexity, no-user-interaction, scope-unchanged. The Exploitability sub-score is therefore *exactly the same number* (≈3.888) in both calculations. The entire 2.3-point difference comes from the Impact side alone: Finding 001 is a full RCE (C:H/I:H/A:H - total loss of confidentiality, integrity, and availability), while Finding 005 is a cryptographic weakness that lets an attacker passively decrypt traffic (C:H - they can read what's being said) but doesn't let them alter it or take the service down (I:N/A:N).

**Biggest-impact components**: In this specific comparison, **Integrity and Availability impact** are what separate a 9.8 from a 7.5 - not the attack vector, not privileges, not complexity. More generally across CVSS, Impact metrics (C/I/A) and the Scope switch tend to have outsized leverage on the final number precisely because Impact is the *sum* of three independent 0–0.56 values feeding a nonlinear formula, whereas each Exploitability metric is one multiplicative factor among four. Going from one High impact category to three High impact categories (as here) moves the score by multiple points; by contrast, moving a single exploitability metric one notch (as in Exercise 1's AV:N→AV:L, a 1.4-point swing) tends to move the score less than a full impact-category swing does. The practical takeaway for triage: two vulnerabilities that look equally "reachable" can differ enormously in urgency purely based on what the attacker can *do* once they're in, not how they got there.
