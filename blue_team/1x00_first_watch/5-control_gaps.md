# The Missing Pieces: Control Gap Analysis


Gap ID: G-001

Gap Description: Every technical detective control in the inventory (C-004, C-007, C-011 through C-015) is a local, unforwarded log with no correlation and no alerting. The FortiGate keeps 30 days locally; Windows Event Viewer and AD logs are "checked manually when something breaks"; Linux syslog is per-host with no centralization; Marcus had started researching a SIEM (Wazuh) but never installed one. The matrix cell looks populated, but nothing in it will notice an incident while it is happening.

Category x Function Missing: Technical Detective (functional gap - the cell has entries, but no control in it performs real-time detection)

Affected Asset(s) or Zone: Entire technical environment - firewall perimeter, Windows and Linux servers, AD, web/billing applications

Risk if Unaddressed: Integrity and Availability - an active compromise can run for weeks before anyone looks at the right log at the right time. This is not hypothetical: the cryptominer on billing-srv-01 generated three separate performance tickets over roughly two weeks, each closed as a hardware issue, before anyone identified it as malware.

Evidence: Task 4 matrix, Technical/Detective column; Artifact 8 (Log Management) - "Marcus kept talking about a SIEM... never got to install anything"; root cause analysis of billing-srv-01 (Task 2)

---

Gap ID: G-002

Gap Description: No administrative process exists to detect policy violations, compliance drift, or human-layer weaknesses. There is no periodic access review, no phishing simulation program, and HIPAA Security Rule compliance "has never been formally assessed" despite Legal's claim that the organization is compliant.

Category x Function Missing: Administrative Detective (entire function absent from the category)

Affected Asset(s) or Zone: Organization-wide - user access rights, policy compliance, PHI handling practices

Risk if Unaddressed: Confidentiality and Integrity - stale or excessive access rights, policy violations, and susceptibility to social engineering can persist indefinitely because nothing is designed to surface them before an incident forces the issue.

Evidence: Task 4 matrix, Administrative/Detective column (empty); Marcus's notes - "HIPAA Security Rule compliance has never been formally assessed... Legal says 'we're compliant' but has no evidence"; Artifact 7 - "No phishing simulation campaigns have been conducted"

---

Gap ID: G-003

Gap Description: No documented incident response plan, business continuity plan, or disaster recovery plan exists anywhere in the organization. When ransomware hit billing-srv-01 in January, the response was improvised by James, Sarah, and Marcus over four days rather than executed against a plan.

Category x Function Missing: Administrative Corrective (entire function absent from the category)

Affected Asset(s) or Zone: Organization-wide - any incident requiring coordinated recovery, from a single-server compromise to a facility-wide outage

Risk if Unaddressed: Availability, and secondarily Integrity - response time and quality depend entirely on which specific people are available and improvising in the moment, which is exactly what happened in January and is not a repeatable or scalable process for a 350-bed hospital.

Evidence: Task 4 matrix, Administrative/Corrective column (empty); Marcus's notes - "No formal incident response plan exists... James, Sarah and I basically improvised for 4 days"; "No business continuity plan. No disaster recovery plan."

---

Gap ID: G-004

Gap Description: Antivirus/endpoint protection (C-009) covers only the 372 Windows workstations. The servers that actually host EHR, billing, AD, and PACS data - the assets an attacker would most want to reach - have no antivirus coverage at all: Windows servers because the license was never purchased, Linux servers because the current Sophos tier doesn't support them.

Category x Function Missing: Technical Preventive - control exists but does not cover the critical asset class

Affected Asset(s) or Zone: ehr-srv-01, ehr-db-01, billing-srv-01, ad-dc-01/02, file-srv-01, pacs-srv-01, print-srv-01, backup-srv-01

Risk if Unaddressed: Integrity and Availability - this is precisely how the billing-srv-01 cryptominer went undetected for two weeks; the servers with the highest-value data have the least malware protection of any tier in the environment.

Evidence: Task 4 matrix (C-009 listed under Technical/Preventive but scoped to workstations only); Artifact 4 - "Windows servers: 15 (NOT covered - server protection license not purchased)... Linux servers: 0 (NOT covered - not supported by current Sophos tier)"

---

Gap ID: G-005

Gap Description: No physical control of any kind exists to repair, restore, or resume operations after a physical security incident - no lockdown procedure, no documented re-entry process after an evacuation, no emergency restoration plan for the facility itself.

Category x Function Missing: Physical Corrective (entire function absent from the category)

Affected Asset(s) or Zone: All three facilities - Central, Westside, and Corporate HQ

Risk if Unaddressed: Availability - combined with the absence of a business continuity plan (G-003), a physical incident (fire, flood, forced entry) has no defined path back to normal operations, which is especially dangerous for a facility already noted to have no documented procedure beyond 20 minutes of UPS runtime.

Evidence: Task 4 matrix, Physical/Corrective column (empty); Marcus's notes - "If Central loses power beyond what the UPS can handle (about 20 minutes), there is no documented procedure for clinical operations"

---

Gap ID: G-006

Gap Description: No compensating control exists anywhere in the inventory, despite MedDefense having several assets that cannot be directly secured by normal means: the flat, unsegmented `10.10.0.0/16` network leaves ehr-db-01 reachable from the entire subnet rather than restricted to ehr-srv-01, and the same flat network is what makes the unpatched medical IoT devices identified on the walk-through (Task 3, Observation 4) reachable from any compromised endpoint. Segmentation - the obvious compensating control for both - has been "on the roadmap" for over four months.

Category x Function Missing: Technical Compensating (entire function absent from the category)

Affected Asset(s) or Zone: ehr-db-01 (PostgreSQL, reachable org-wide), medical IoT (vital signs monitors, infusion pumps), any unpatchable device on the flat network

Risk if Unaddressed: Confidentiality, Integrity, and Availability - and for the medical devices specifically, direct patient-safety risk, since a device that cannot be patched and is not isolated has no protection at all beyond hoping the rest of the network holds.

Evidence: Task 4 matrix, Technical/Compensating column (empty); Marcus's notes - "ehr-db-01: PostgreSQL is accessible from the entire 10.10.0.0/16 range. Should be restricted to ehr-srv-01 only"; Task 3, Observation 4 (Medical IoT)

---

Gap ID: G-007

Gap Description: Physical preventive and detective controls (C-018 the guard, C-019 the cameras) protect only the main entrance, ER entrance, and parking garage at Central. The zones that actually matter most for a security incident - the server room, the network closet, and the administrative/IT wing - have zero physical control coverage, which is exactly what the walk-through in Task 3 found on the ground (Observations 1, 2, and 5).

Category x Function Missing: Physical Preventive and Physical Detective (control exists in the category, but does not cover the critical zones)

Affected Asset(s) or Zone: Server room, second-floor network closet, administrative wing/IT department

Risk if Unaddressed: Confidentiality, Integrity, and Availability - the two rooms holding the organization's actual infrastructure, and the corridor leading to the security team's own office, are the least physically monitored spaces in the building.

Evidence: Task 4 matrix (C-018/C-019 scoped to entrances/garage only); Artifact 6 - "No cameras in server room area, network closets or administrative wing"; Task 3, Observations 1, 2, and 5

---

Gap ID: G-008

Gap Description: No deterrent control is evidenced anywhere in the inventory - no warning signage, no visible "premises under surveillance" messaging, nothing designed specifically to discourage an attempt before it starts. The guard and cameras were classified by their actual documented function (verification and recording), not by an assumed deterrent side-effect, because no artifact describes anything built for that purpose.

Category x Function Missing: Deterrent (entire function absent across all three categories)

Affected Asset(s) or Zone: Organization-wide, all three facilities

Risk if Unaddressed: Primarily a force multiplier on every other gap in this list - deterrence is the cheapest layer of defense, and its total absence means every other control has to work harder because no one is being discouraged from trying in the first place.

Evidence: Task 4 matrix - Deterrent column empty across all three category rows; no signage, warnings, or deterrent-purpose control described in any of the eight artifacts

