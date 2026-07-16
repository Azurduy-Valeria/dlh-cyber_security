# Physical Walk-Through: Risk Decomposition

James asked for a walk-through with fresh eyes. He raised one specific point before we started: Marcus flagged the server room access issue to Sarah Park at least twice, it was logged as "on the roadmap," and five months have passed with no change. That single fact framed how I looked at everything else on this tour - not as isolated physical lapses, but as gaps that have already been identified once, unresolved, sitting in an environment Marcus separately documented as a flat, unsegmented network (`10.10.0.0/16`, no VLANs). That detail matters for what follows: a physical weakness on any one floor of this building isn't contained to that floor once someone reaches the network.

Each observation below is decomposed into Vulnerability, Threat, and Impact, per the CIA triad, with a justified severity rating.

---

## Observation 1: Server Room Access

**Vulnerability:** The server room is on the ground floor, reachable from a corridor shared with the cafeteria. It is opened with the same generic badge issued to every employee on day one - clinical, administrative, custodial - with no role-based restriction. There is no camera on the door and no visitor log. Access is neither restricted, monitored, nor attributable to a specific individual.

**Threat:** Any badge-holder with no legitimate business in the room - or an outsider who tailgates through the cafeteria area - can enter unnoticed and unrecorded. They could steal or tamper with hardware, or plant a rogue device on the internal network. This room also houses `backup-srv-01`'s NAS in the same rack as production servers, so the same door controls access to the organization's only backup copy.

**Impact:**
- **Confidentiality** - direct console or drive access to EHR, AD, and PACS servers.
- **Integrity** - physical tampering with production hardware, or a planted rogue device.
- **Availability** - theft or damage takes down production systems *and* the backup simultaneously, since both live in the same room.

**Severity: Critical** - unrestricted, unmonitored, unattributable physical access to core infrastructure and the sole backup copy, already flagged internally five months ago and still unresolved.

---

## Observation 2: Network Closet

**Vulnerability:** The second-floor network closet holding switches and patch panels has no lock, the door was found ajar, and a laminated sheet labeled "Network Maintenance Credentials" - a working username and password for the switch management interface - is taped to the wall in plain view.

**Threat:** Anyone who walks in, with no technical effort beyond reading the sign, can log into switch management and reconfigure ports, mirror traffic for interception, or disable uplinks. Because there are no VLANs and the entire environment sits on one flat `10.10.0.0/16` broadcast domain, a compromise at this closet is not contained to the second floor - it has a path to servers, EHR systems, and medical devices org-wide.

**Impact:**
- **Confidentiality** - traffic interception via port mirroring.
- **Integrity** - switch reconfiguration, man-in-the-middle positioning.
- **Availability** - port shutdown or loop creation causing outages that propagate across the unsegmented network.

**Severity: Critical** - plaintext credentials combined with zero physical barrier turns a minor door lapse into a full network-management compromise, with no segmentation in place to limit how far it spreads.

---

## Observation 3: Nurse Station

**Vulnerability:** A third-floor nurse station workstation is logged into the EHR system with a patient record visible on screen, unattended, idle for at least 15 minutes with no session timeout enforced. A posted sign explicitly discourages logging out between shifts - this is a normalized workflow, not an accident.

**Threat:** Any visitor, patient, or staff member without authorization to that specific record can view or alter what's on screen, or use the live authenticated session to browse unrelated patient charts, or make entries that get attributed to the logged-in clinician.

**Impact:**
- **Confidentiality** - unauthorized PHI disclosure, a direct HIPAA exposure.
- **Integrity** - record edits misattributed to the wrong clinician, undermining both care accuracy and the audit trail.

**Severity: High** - PHI is exposed at the moment of observation with zero attacker effort required, and the posted sign shows the culture actively works against the fix; scoped slightly below Observations 1 and 2 because the blast radius is one workstation rather than the network or infrastructure layer.

---

## Observation 4: Medical IoT

**Vulnerability:** A connected vital signs monitor in a patient room displays its own IP address and firmware version on screen - firmware last updated in 2019 - and sits on the same IP range as the nurse station workstations, wired to a labeled wall port (`MED-3F-12`) with no apparent network isolation.

**Threat:** An attacker who gains a foothold anywhere on `10.10.0.0/16` - including via Observation 2 or Observation 3 - can pivot laterally to reach this device and others like it (Marcus's notes flag the infusion pumps as sharing the same exposure) and exploit unpatched, multi-year-old firmware to falsify readings, disrupt monitoring, or use the device as a stepping stone toward higher-consequence targets.

**Impact:**
- **Integrity** - falsified vitals or manipulated device behavior, a direct patient-safety risk.
- **Availability** - disrupted monitoring during active patient care.
- **Confidentiality** - leaked patient telemetry from the device itself.

**Severity: Critical** - an unpatched medical device reachable from anywhere on the network due to the lack of segmentation, with a credible path to direct patient harm rather than data loss alone. This is the observation where a cybersecurity gap becomes a life-safety issue.

---

## Observation 5: Emergency Exit

**Vulnerability:** A fire exit between the public waiting area and the restricted administrative wing is propped open with a wooden wedge. A handwritten sign taped to the door - "please do not close, staff passage" - has effectively disabled whatever access control existed at that boundary.

**Threat:** Any member of the public can walk directly from the waiting area into the corridor leading to the IT department and James Chen's office, with no badge check, no log, and no camera. This enables tailgating into further restricted areas, opportunistic theft, or social engineering against IT and security staff on their own floor.

**Impact:**
- **Confidentiality** - unauthorized proximity to IT staff, screens, and documents, and possibly unattended workstations.
- **Integrity / Availability** - tampering with IT equipment if physically reachable.

Beyond the CIA pillars, this observation also erodes the security team's own physical perimeter - the door being propped open leads straight to the people responsible for catching the other four observations.

**Severity: High** - a trivial, unmonitored bypass straight into the administrative/IT wing, placed just below Observations 1 and 2 because it requires a further step of internal movement before reaching the most critical assets (server room, network closet).

---

## Cross-Cutting Finding

These five observations are not independent. Observations 1, 2, and 4 all connect through the same root cause Marcus already documented: a flat, unsegmented `10.10.0.0/16` network with no VLANs. A physical compromise at any single weak point - the badge-accessible server room, the unlocked closet with posted credentials, or an idle EHR session - has an unobstructed path to reach production databases and unpatched medical IoT. Segmentation being "on the roadmap" for five months is not a minor scheduling delay; it's the control that would have contained four of these five findings to the room they were found in.
