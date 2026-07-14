# MedDefense Health Systems - Structured Environment Summary

## 1. Organization Overview

**Sites**

- **MedDefense Central Hospital**
  - Location type: Downtown, 350-bed acute care facility (6 floors + basement server room)
  - Function: Emergency, Surgery, Cardiology, Radiology, Oncology, Pediatrics, Maternity, Pharmacy, Laboratory, Administration
  - Approx. headcount: ~1,400

- **Westside Clinic**
  - Location type: Suburban, 12 min from Central, 2-story medical office complex
  - Function: Outpatient — primary care, diagnostic imaging (X-ray, ultrasound, no MRI), blood work, minor procedures, physical therapy
  - Approx. headcount: ~180

- **Corporate HQ**
  - Location type: Greenfield Business Park, 15 min from Central, leased office (3rd floor of 5-story building)
  - Function: Finance, HR, Legal, Marketing, Executive Leadership, IT (12 staff)
  - Approx. headcount: ~220

Total organization-wide: ~2,000 employees.

**Reporting Structure (security-relevant)**

- CEO: Dr. Patricia Morales
- CISO position: **vacant**
- James Chen - Deputy CISO (acting), reports formally to the vacant CISO role but in practice reports directly to the CEO
  - Val - Security Analyst, replacing Marcus Webb
- Sarah Park - IT Director, peer to James Chen, but James has no authority over IT operations (only security policy) - noted as a source of friction
  - 3x System Administrators
  - 2x Network Technicians
  - 1x Database Administrator
  - 2x Helpdesk Analysts (incl. Mike Torres, lead)
  - 2x Desktop Support Technicians
  - 1x IT Intern (vacant)

## 2. IT Infrastructure Identified

**Servers - Central**
- ehr-srv-01 (Ubuntu 20.04) - EHR application server
- ehr-db-01 (Ubuntu 20.04, PostgreSQL) - EHR database
- pacs-srv-01 (Windows Server 2016) - PACS imaging server
- billing-srv-01 (Ubuntu 18.04) - Billing/claims processing
- ad-dc-01 / ad-dc-02 (Windows Server 2019) - Primary/secondary domain controllers
- file-srv-01 (Windows Server 2016) - Department file shares
- print-srv-01 (Windows Server 2012 R2, unverified >1yr, EOL Oct 2023) - Print server
- backup-srv-01 (Ubuntu 22.04, Veeam agent) - Backup, replicates to a NAS in the same server room/rack
- web-srv-01 (Ubuntu 20.04) - Public website + patient portal, sits in DMZ

**Servers - Westside**
- ws-srv-01 (Windows Server 2016) - Local file server + scheduling
- Possible additional server in the closet (unconfirmed, per Marcus's note)

**Servers - HQ**
- None on-premise; staff use cloud services and connect to Central over site-to-site VPN

**Network Equipment**
- Central: Cisco core switch (model unknown), 2x Cisco access switches per floor, 1x Fortinet FortiGate 100F firewall, Ubiquiti UniFi APs (12 units)
- Westside: 1x unmanaged switch (brand unknown), 1x consumer-grade Netgear Nighthawk router (also carries the site-to-site VPN to Central), no firewall
- HQ: network managed by building landlord, MedDefense has its own VLAN

**Endpoints**
- Central: ~320 Windows 10 workstations, ~60 thin clients (clinical areas)
- Westside: ~45 Windows 10 workstations
- HQ: ~120 Windows 10/11 workstations, ~30 remote-capable laptops
- ~25 iPads for physician rounds (management status unclear)
- Counts are ~8 months old (last AD report); no current complete inventory

**Medical Devices (IoT) - Central**
- ~80 Philips IntelliVue patient monitors (network-connected)
- ~120 BD Alaris infusion pumps (network-connected, dosage updates)
- 1x Siemens MAGNETOM MRI scanner - runs Windows XP
- 1x GE Revolution CT scanner - OS unknown
- IP-based nurse call system, integrated with phone system
- HID Global badge/access system, connected to AD for some doors

**Network Topology**
- Central: flat network, all device classes (servers, workstations, medical devices) on one broadcast domain, 10.10.0.0/16, no VLANs
- Guest WiFi exists at Central (separate SSID) but isolation is unverified
- Westside connects to Central via IPSec VPN riding on the consumer router
- HQ connects to Central via site-to-site VPN over the building-managed network

## 3. Data and Services

**Data types handled**
- Protected health information (EHR records, PACS imaging, lab results)
- Billing/claims and financial data
- Employee/HR data
- Legal data
- Authentication/identity data (AD)

**Critical services dependent on IT infrastructure**
- EHR (patient records) - clinical staff org-wide
- PACS (medical imaging) - Radiology, referring clinicians
- Billing/claims processing - Administration, Finance
- Patient portal / public website - patients, public
- Domain services / authentication (AD) - all staff
- File shares - departments
- Medical device operation (monitors, infusion pumps, MRI, CT) - clinical staff, patients
- Nurse call and badge/access systems - clinical staff, facilities/security

**Users**: clinical staff (Central, Westside), administrative/corporate staff (HQ), IT staff, and patients (via portal, and indirectly via connected medical devices).

## 4. Known Unknowns

- Exact model of Central's Cisco core switch - unknown
- Brand of Westside's unmanaged switch - unknown
- WiFi AP hardware at Westside - unknown
- Whether a second server exists in the Westside closet - unconfirmed (Marcus flagged, never verified)
- print-srv-01's existence/status - marked [UNVERIFIED], not physically confirmed in over a year
- Whether Central's guest WiFi SSID is actually network-isolated - unverified
- ACLs on the HQ VPN - not audited
- Root cause of billing-srv-01's recurring performance issues - unresolved, only being restarted
- Whether iPads used for rounds are under any device management - unclear
- OS of the GE Revolution CT scanner - unknown
- Total accurate endpoint count - no current inventory (last AD report ~8 months old, incomplete per Marcus)
- Whether Sophos AV is up to date across all endpoints - not verified
- Full cloud service inventory - only O365 confirmed; suspected shadow IT in other departments, not documented
- No formal HIPAA Security Rule assessment has been performed; Legal claims compliance but has no supporting evidence
- No formal incident response plan; the January ransomware incident on billing-srv-01 was handled ad hoc
- No business continuity or disaster recovery plan; UPS at Central covers only ~20 minutes of outage
- No formal vulnerability assessment has been done on any servers
- No documented threat landscape analysis specific to the organization
- Contradiction: Sarah Park describes network segmentation as "planned for next fiscal year" (per Marcus, 4+ months ago with no progress), while the network diagram and Marcus's notes confirm the network is still fully flat
- The network diagram itself is explicitly marked incomplete/simplified by its author (Marcus): "Real topology is messier"
- Physical security gap: server room uses the same generic badge as general staff; no cameras cover the server room corridor; Westside's server closet does not lock at all
- Guard coverage is limited to Central only (Mon–Fri, 7AM–7PM); no coverage at Westside or HQ, and no night/weekend coverage anywhere
