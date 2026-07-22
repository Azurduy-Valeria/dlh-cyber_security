# The Framework Landscape

## Part 1: Three-Framework Summary

**NIST CSF 2.0**
Published by the U.S. National Institute of Standards and Technology. It's a strategic framework — a set of outcomes to guide *what* a security program should cover, not a checklist of technical settings. It's organized into 6 Functions (Govern, Identify, Protect, Detect, Respond, Recover), each broken into Categories and Subcategories describing specific desired outcomes. It's voluntary and sector-agnostic, used by organizations of any size — from small businesses to federal agencies — as a common language to describe security posture and set priorities.

**CIS Controls v8**
Published by the Center for Internet Security, a nonprofit. It's an implementation framework — a prioritized, concrete list of 18 controls (each with specific "safeguards") telling you exactly what to configure and in what order. Controls are grouped into 3 Implementation Groups by organizational maturity: IG1 (essential hygiene, 56 safeguards), IG2 (foundational, +74 safeguards), IG3 (advanced, +23 safeguards). It's used by IT/security teams who already know *what* they need to do (often from CSF or a risk assessment) and need the specific technical to-do list.

**ISO/IEC 27001**
Published by the International Organization for Standardization. It's a certifiable management-system standard: it defines requirements for an Information Security Management System (ISMS) — a formal, auditable process for managing risk continuously (Plan-Do-Check-Act cycle), backed by a set of 93 controls in Annex A. Unlike CSF or CIS, an organization can be independently audited and *certified* against ISO 27001. It's typically adopted by organizations that need to prove compliance to customers, partners, or regulators — often a contractual or sales requirement.

## Part 2: Relationship Map

These three are not competitors — they answer different questions and stack together. **NIST CSF answers "What should we do?"** — it gives MedDefense the strategic map (Govern, Identify, Protect, Detect, Respond, Recover) without prescribing exact technical steps. **CIS Controls answer "How should we do it?"** — for each CSF function, CIS gives the concrete safeguard (e.g., CSF's "Protect" function is largely satisfied by implementing CIS Controls 3-6, 9-11). **ISO 27001 answers "Can we prove we are doing it?"** — it wraps the whole thing in a formal, auditable management system with a certificate a regulator, insurer, or business partner can verify. A mature program typically uses CSF to set direction, CIS Controls to implement it, and ISO 27001 (if/when certification is needed) to formalize and prove it — they layer, they don't compete.

## Part 3: MedDefense Framework Selection

**Recommendation: NIST CSF 2.0 as the strategic backbone, CIS Controls v8 (IG1 first) as the implementation plan. Defer ISO 27001 certification.**

Reasoning:
- MedDefense is a regional hospital with **no framework in place today** and a **tiny security team** (1 analyst, 1 Deputy CISO). It needs a framework that's free, flexible, and doesn't require a certification audit team it doesn't have — that's CSF + CIS, not ISO.
- **CSF gives structure fast**: it lets James Chen report progress to the Board in plain terms ("we're Partial on Detect, targeting Managed in 6 months") without needing outside consultants.
- **CIS Controls give the actual to-do list** a 2-person team can execute: IG1 is explicitly designed as the "minimum viable" baseline for any organization, which matches MedDefense's current maturity level exactly.
- **ISO 27001 is deferred, not rejected.** Certification requires a functioning ISMS, internal audits, and (usually) hiring auditors — real cost and headcount MedDefense doesn't have yet. It becomes worth pursuing later if a major payer, partner, or cyber-insurance underwriter *requires* the certificate — but chasing certification before the basics (asset inventory, patching, MFA) exist would be building the audit trail for a program that doesn't yet function.

MedDefense still needs to demonstrate compliance to regulators (HIPAA) and the Board today — CSF + CIS together produce exactly that evidence (a Current Profile, a scored control set, a documented gap-closure plan) without the overhead of a certification program.
