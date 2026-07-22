# The CFO Challenge

## Objection 1: "We have never been breached... can you demonstrate we WILL be breached?"

**Acknowledgment**: Fair — no one can promise a future breach with certainty, and a 12-year clean track record is real.
**Counter-Evidence**: The cryptominer was a compromise — unauthorized code execution on billing-srv-01 that ran undetected for two weeks. The 1x02 scan found that exact same server still has a documented, public exploit chain (Findings 001/002) sitting unpatched. This isn't a hypothetical threat — it's the same category of event that already happened, through a path that's still open today.
**Business Framing**: We're not asking to fund protection against something that's never happened. We're asking to fund protection against something that already happened once, on a server that can still be hit the same way.
**Recommendation**: I can't prove "WILL." I can show you a confirmed, exploitable vulnerability plus a prior real incident — a stronger basis than most prevention spending gets. Share the specific scan findings with the CFO directly rather than asking him to take the probability on faith.

## Objection 2: "Your ALE numbers are estimates, not facts."

**Acknowledgment**: Completely correct — I flagged confidence levels (High/Medium/Low) on every single estimate precisely because they're estimates, not measured facts.
**Counter-Evidence**: Even cutting the ransomware ALE in half (to $150,000 instead of $300,000), the proposed fix (segmentation + MFA, $65,000) still produces strongly positive net value. The recommendation doesn't depend on the number being exactly right — it holds even under a much more conservative assumption.
**Business Framing**: This is exactly how insurers and CFOs already price uncertain risk everywhere else in the business — nobody demands a guaranteed loss figure before buying fire insurance.
**Recommendation**: Concede partially — commit to updating the ALE estimates with real data (post-implementation incident counts, scan results) at the 6-month review instead of treating this as a static, one-time number.

## Objection 3: "Insurance is cheaper than controls."

**Acknowledgment**: Genuinely valid — carrying a $1M policy is real protection, and not every organization has one.
**Counter-Evidence**: The policy's $1M aggregate limit is below the $2,000,000 total asset value estimated for the ransomware scenario alone (Task 6) — regulatory penalties, reputation damage, and extended downtime can exceed what the policy pays. Insurers are also increasingly conditioning coverage (or renewal pricing) on documented baseline controls like MFA and segmentation.
**Business Framing**: Insurance and controls aren't substitutes, they're complements. Underinvesting in controls risks a denied claim or a spiked premium after the next incident — insurance without controls compounds the exposure rather than replacing it.
**Recommendation**: Before finalizing the budget, review the policy's actual exclusions and requirements with the broker — if coverage is already conditioned on controls we don't have, this isn't optional spending, it's what keeps the policy we're already paying $38,000/year for valid.

## Objection 4: "This should be IT's regular budget, not a special ask."

**Acknowledgment**: Fair concern — unchecked, every department claiming a "special budget" is exactly how budgets spiral.
**Counter-Evidence**: Sarah's $1.2M IT budget funds infrastructure, support, and operations that don't overlap with these controls — SIEM, MFA, and backup replication don't exist in any current line item. Reallocating from her existing budget means cutting something IT already depends on to fund this instead of adding new capability.
**Business Framing**: This is a one-time catch-up investment, not permanent new departmental overhead. Once implemented, ongoing maintenance costs fold naturally into IT's regular budget next year.
**Recommendation**: Concede partially — agree that steady-state costs of these controls should move into IT's regular budget in future years. This year's $120,000 ask is specifically a one-time investment because MedDefense has never had any of these controls before.

## Objection 5: "Can we start with $60,000 and see if it works?"

**Acknowledgment**: Phased funding for a new program is genuinely standard practice, and reasonable given this is the first dedicated security budget MedDefense has ever had.
**Counter-Evidence**: The four highest-value controls (segmentation, backup replication, SIEM, MFA) total exactly $88,000 combined. A $60,000 cap forces dropping segmentation — the single highest-value control on the list — or leaving three of the four best investments unfunded. Segmentation specifically can't be done "half now, half later"; a partially segmented network still allows the same lateral movement that makes every other finding dangerous.
**Business Framing**: I can offer a genuinely phased approach without cutting the most effective control.
**Recommendation**: Counter-propose $88,000 this year for the four highest-ROI controls in full, with the remaining items (scoped EDR, Westside firewall, credential rotation — about $22,000) requested next year alongside measurable results: fewer findings on rescan, MFA adoption rate, a successful backup restore test.

---

## Closing Statement

Across the top 5 risks identified in this assessment, MedDefense currently carries an estimated $724,500 per year in expected loss — not a worst-case number, but the statistically expected annual cost of doing nothing. The proposed $110,000 program reduces that exposure to roughly $189,000 per year, a reduction of over half a million dollars in expected annual risk for a program that costs less than one-sixth of that reduction. The cost of inaction isn't zero and isn't hypothetical — it's a number the organization is already paying, quietly, every year it goes unaddressed; the $110,000 program is simply the cheapest way found to stop paying it.
