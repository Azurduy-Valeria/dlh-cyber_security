# Physical Walk-Through: Risk Decomposition


Observation 1: Server Room Access

**Vulnerability:** The server room is on the ground floor, reachable from a corridor shared with the cafeteria, and opened with the same generic badge issued to every employee on day one — clinical, administrative, custodial — with no role-based restriction. There is no camera on the door and no visitor log, so access is neither restricted, monitored, nor attributable to a specific individual.

**Threat:** Any badge-holder with no legitimate business in the room, or an outsider who tailgates through the cafeteria area, enters unnoticed and unrecorded to steal or tamper with hardware, or to plant a rogue device on the internal network.

**Impact:** Confidentiality is at risk through direct console or drive access to EHR, AD, and PACS servers; Integrity through physical tampering with production hardware or a planted rogue device; and Availability is doubly exposed because `backup-srv-01`'s NAS sits in the same rack as production servers, so theft or damage here can take down production systems and the only backup copy at the same time.

**Severity:** Critical — unrestricted, unmonitored, unattributable physical access to core infrastructure and the sole backup copy, already flagged internally five months ago and still unresolved.

---

Observation 2: Network Closet

**Vulnerability:** The second-floor network closet holding switches and patch panels has no lock, the door was found ajar, and a laminated sheet labeled "Network Maintenance Credentials" — a working username and password for the switch management interface — is taped to the wall in plain view.

**Threat:** Anyone who walks in, with no technical effort beyond reading the sign, logs into switch management and reconfigures ports, mirrors traffic for interception, or disables uplinks.

**Impact:** Confidentiality is exposed through traffic interception via port mirroring; Integrity through unauthorized switch reconfiguration or man-in-the-middle positioning; and Availability through port shutdowns or loops causing outages. Because the entire environment sits on one flat `10.10.0.0/16` broadcast domain with no VLANs, none of this is contained to the second floor — it has a direct path to servers, EHR systems, and medical devices org-wide.

**Severity:** Critical — plaintext credentials combined with zero physical barrier turns a minor door lapse into a full network-management compromise, with no segmentation in place to limit how far it spreads.

---

Observation 3: Nurse Station

**Vulnerability:** A third-floor nurse station workstation is logged into the EHR system with a patient record visible on screen, unattended, idle for at least 15 minutes with no session timeout enforced, and a posted sign explicitly discourages logging out between shifts — this is a normalized workflow, not an accident.

**Threat:** Any visitor, patient, or staff member without authorization to that specific record views or alters what's on screen, or uses the live authenticated session to browse unrelated patient charts or make entries that get attributed to the logged-in clinician.

**Impact:** Confidentiality is breached through unauthorized PHI disclosure — a direct HIPAA exposure — and Integrity is at risk through record edits misattributed to the wrong clinician, undermining both care accuracy and the audit trail.

**Severity:** High — PHI is exposed at the moment of observation with zero attacker effort required, and the posted sign shows the culture actively works against the fix; scoped slightly below Observations 1 and 2 because the blast radius is one workstation rather than the network or infrastructure layer.

---

Observation 4: Medical IoT

**Vulnerability:** A connected vital signs monitor in a patient room displays its own IP address and firmware version on screen — firmware last updated in 2019 — and sits on the same unsegmented IP range as the nurse station workstations, wired to a labeled wall port (`MED-3F-12`) with no apparent network isolation.

**Threat:** An attacker who gains a foothold anywhere on `10.10.0.0/16` — including via Observation 2 or Observation 3 — pivots laterally to reach this device and others like it (Marcus's notes flag the infusion pumps as sharing the same exposure), exploiting the unpatched, multi-year-old firmware to falsify readings, disrupt monitoring, or use the device as a stepping stone toward higher-consequence targets.

**Impact:** Integrity is at risk through falsified vitals or manipulated device behavior — a direct patient-safety risk; Availability through disrupted monitoring during active patient care; and Confidentiality through leaked patient telemetry from the device itself.

**Severity:** Critical — an unpatched medical device reachable from anywhere on the network due to the lack of segmentation, with a credible path to direct patient harm rather than data loss alone. This is the observation where a cybersecurity gap becomes a life-safety issue.

---

Observation 5: Emergency Exit

**Vulnerability:** A fire exit between the public waiting area and the restricted administrative wing is propped open with a wooden wedge, and a handwritten sign taped to the door — "please do not close, staff passage" — has effectively disabled whatever access control existed at that boundary.

**Threat:** Any member of the public walks directly from the waiting area into the corridor leading to the IT department and James Chen's office, with no badge check, no log, and no camera, enabling tailgating into further restricted areas, opportunistic theft, or social engineering against IT and security staff.

**Impact:** Confidentiality is at risk through unauthorized proximity to IT staff, screens, documents, and possibly unattended workstations; Integrity and Availability through tampering with IT equipment if physically reachable. It also erodes the security team's own physical perimeter, since the propped door leads straight to the people responsible for catching the other four observations.

**Severity:** High — a trivial, unmonitored bypass straight into the administrative/IT wing, placed just below Observations 1 and 2 because it requires a further step of internal movement before reaching the most critical assets (server room, network closet).

---

## Cross-Cutting Finding

These five observations are not independent. Observations 1, 2, and 4 all connect through the same root cause Marcus already documented: a flat, unsegmented `10.10.0.0/16` network with no VLANs. A physical compromise at any single weak point - the badge-accessible server room, the unlocked closet with posted credentials, or an idle EHR session - has an unobstructed path to reach production databases and unpatched medical IoT. Segmentation being "on the roadmap" for five months is not a minor scheduling delay; it's the control that would have contained four of these five findings to the room they were found in.
