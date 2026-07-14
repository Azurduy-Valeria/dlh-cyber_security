# MedDefense Health Systems - Incident Classification (CIA Triad)

## Incident A - Ransomware on billing-srv-01 (January 15)

- **Primary pillar:** Availability
- **Justification:** The billing server was encrypted and inaccessible, preventing Finance from processing insurance claims for 4 days.
- **Secondary pillar:** Integrity
- **Connection:** Ransomware encryption is itself an unauthorized modification of the data - the files were altered (encrypted) without authorization, and the 3-week-old backup meant the most recent legitimate version of that data could not be restored.

## Incident B - Patient portal IDOR / broken access control (February 2)

- **Primary pillar:** Confidentiality
- **Justification:** A broken access control let authenticated patients view other patients' lab results by manipulating a URL parameter - information was exposed to people who should not have had access to it.
- **Secondary pillar:** None clearly evidenced
- **Connection:** The incident as reported only describes unauthorized viewing, not modification or denial of access; no integrity or availability impact is documented.

## Incident C - Pharmacy dosage data corruption (March 18)

- **Primary pillar:** Integrity
- **Justification:** A buggy database update script overwrote medication dosage values, causing the system to display incorrect data across all three sites.
- **Secondary pillar:** Availability
- **Connection:** Once the data could no longer be trusted, the system was effectively unusable for its intended clinical purpose for ~6 hours, even though it remained technically online.

## Incident D - Public website defacement (April 5)

- **Primary pillar:** Integrity
- **Justification:** The homepage content was replaced with an unauthorized political message - an unauthorized modification of the system.
- **Secondary pillar:** Availability
- **Connection:** The legitimate website was unavailable to visitors in its intended form until it was restored from backup roughly 2 hours later.

## Incident E - EHR outage during database migration (May 22)

- **Primary pillar:** Availability
- **Justification:** A planned migration overran and an untested rollback procedure led to a 9-hour EHR outage, forcing physicians onto paper records.
- **Secondary pillar:** None clearly evidenced
- **Connection:** No unauthorized access or data modification is described; the impact was purely on the system being reachable/usable.

## Incident F - IT intern's personal laptop on internal network (June 10)

- **Primary pillar:** Confidentiality
- **Justification:** An unmanaged personal device with a torrent client sharing files sat on the internal network (not the guest network) for 3 weeks with access to the same segment as the HR file share, creating exposure risk for HR data.
- **Secondary pillar:** Integrity (potential, unconfirmed)
- **Connection:** A rogue, uncontrolled device with 3 weeks of internal network access could also have been used to modify data it could reach, though no actual modification is reported in the log - this is a residual risk rather than a confirmed impact.
