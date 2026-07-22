## Three Things We Fix This Week

**1. The billing server can be taken over remotely.**
A software bug lets an attacker break in and take full control, no password needed — likely how the hidden cryptominer got onto this same server in January. If exploited: billing and claims processing stops. **Fix: patch it. ~$5,000, 48 hours.**

**2. Our patient records database has no lock on the door.**
Any device on our network can connect directly to the database holding every patient record. If exploited: a full patient data breach, with the legal and reputational fallout HIPAA demands. **Fix: restrict which systems can connect. Under $1,000, 48 hours — a config change, not new software.**

**3. Our domain controller has a well-known weak spot.**
An attacker on any one computer can use a common technique to take over the system that manages every employee login. If exploited: every server we have could be locked down or ransomed at once, not just one. **Fix: turn on a setting already built into the software. Under $1,000, one week.**

**Total: ~$7,000 and a few IT hours** — not a budget problem, a scheduling one.

---

In three weeks, we've gone from mapping what we have, to understanding who'd attack it, to knowing exactly where the cracks are and what to fix first.