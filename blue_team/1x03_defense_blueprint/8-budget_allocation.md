# The Budget Game

## Part 1: The Selection

**Funded ($110,000 of $120,000):**

| Control | Cost |
|---|---|
| Network segmentation | $60,000 |
| SIEM (Wazuh) | $15,000 |
| MFA (VPN + admin) | $5,000 |
| Offsite backup replication | $8,000 |
| Westside dedicated firewall | $5,000 |
| Scoped EDR — servers only (not full fleet) | $15,000 |
| Medical device default credential rotation (labor only) | $2,000 |
| **Total Funded** | **$110,000** |

**Deferred to next fiscal year:**
- **Full-fleet EDR upgrade** (beyond the servers-only deployment above) — workstations already have baseline Sophos coverage, so upgrading them to Intercept X is real value but lower priority than closing the *zero*-coverage gap on servers first.
- **Full medical device network isolation with dedicated monitoring** (beyond the credential fix above) — most of its value is already captured by network segmentation; the remaining incremental benefit doesn't outrank the other priorities this year.

**Rejected entirely:**
- **24/7 outsourced SOC** ($100,000) — net-negative value (Task 7: −$30,000). Most of the detection value it would provide is already captured far more cheaply by the SIEM + EDR combination being funded.

**Total spend: $110,000. Budget remaining: $10,000**, held as contingency (e.g., incident response retainer or unplanned licensing true-up).

## Part 2: The Opportunity Cost

- **By deferring the full-fleet EDR upgrade, MedDefense accepts an estimated $55,000 in annual risk exposure** — the scoped server-only deployment captures a meaningful slice of the $70,000 potential ALE reduction, but workstations remain on baseline antivirus rather than modern behavioral EDR.
- **By deferring full medical device network isolation, MedDefense accepts an estimated $18,000 in annual risk exposure** — segmentation and credential rotation close most of the gap, but dedicated monitoring and full isolation would have closed the rest.
- **Rejecting the 24/7 SOC does not carry a comparable opportunity cost.** Because it was net-negative to begin with, and its detection value is substantially duplicated by controls already funded, the real incremental loss from not having true 24/7 human coverage (versus business-hours monitoring by a 1-person team) is closer to $15,000–$20,000, not the full $70,000 the control was rated for.

## Part 3: The Alternative

**Alternative allocation**: Drop the scoped EDR ($15,000) and Westside firewall ($5,000); use that $20,000 plus the reallocated budget to fully fund medical device network isolation ($30,000) instead.

| | Primary Plan | Alternative |
|---|---|---|
| Total cost | $110,000 | $118,000 |
| Approx. gross ALE reduction | ~$510,000 | ~$488,000 |

**The primary plan wins on both cost and risk reduction.** The alternative trades away two things that matter: the Westside firewall closes a real, distinct VPN-pivot path that medical device isolation doesn't touch at all, and the scoped EDR closes the *zero*-coverage gap on servers — the exact gap that let the January cryptominer run undetected for two weeks. Spending more to fully isolate medical devices sounds appealing, but most of that risk is already captured by network segmentation; the primary plan simply gets more total risk reduction for less money by spreading the remaining budget across two under-covered gaps instead of over-investing in one that's already partially addressed.
