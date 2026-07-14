
## Introduction to Cyber Security

**What is Cybersecurity?**
Practice of protecting systems, networks and data from digital attacks, theft or damage.

**What are the core principles of cybersecurity?**
CIA -> Confidentiality, Integrity, Avaliability

**How does encryption contribute to security?**
It transforms readable text into ciphertext to ensure confidentiality.

**What is risk management in cybersecurity?**
It is the process of identifying, assessing and prioritizing risks to minimize their impact.

**What are the different types of cybersecurity threats?**
Malware, phishing, ransomware, DDos attacks…

**What is the difference between a virus and a worm?**
A virus requires human action to spread, while a worm replicates itself automatically across networks.

**What is social engineering in the context of security?**
Psychological manipulation of people into performing actions or divulging confidential information.

**What are the key components of an information security program?**
Essential components include governance, risk management, security controls, awareness training, and incident response.

**How do security policies and frameworks contribute to an organization's security posture?**
They establish standardized rules, procedures, and best practices to consistently manage and mitigate security risks.

**What is the purpose of the OWASP Top Ten?**
It serves as an industry standard awareness document outlining the most critical vulnerabilities on web applications.

**What is the role of access control in cybersecurity?**
It restricts the access to users and systems to resources based on defined permissions

**How does multi-factor authentication enhance security?**
MFA requires to provide 2 or more forms of identity verification, then if one is compromised the attacker needs still the other form.

**What are the common methods for securing a network?**
Key methods include firewalls, intrusion detection/prevention systems, network segmentation, and regular patching.

---

## Linux, Shell, Basics - General

**Shebang**
The #! at the start of a script that tells the OS which interpreter to use (e.g., #!/bin/bash).

---

## What is the Shell

**Shell**
A program that provides a command-line interface to interact with the OS by reading and executing commands.

**Terminal vs. Shell**
The terminal is the window/application that displays input/output; the shell is the program running inside it that interprets commands.

**Shell prompt**
The text displayed before your cursor (e.g., user@host:~$) indicating the shell is ready for input.

---


## Looking Around
**Symbolic link**
A pointer to another file by path; breaks if the target is deleted.

**Hard link**
An additional name pointing to the same inode/data; persists if the original is deleted.

**Hard vs. symbolic**
Hard links share the same inode and can't cross filesystems; symlinks are path-based references that can.

---

## LTS

**LTS**
Long Term Support — a software release (commonly Ubuntu) guaranteed to receive updates/security patches for an extended period (typically 5 years).

---

## Linux shell, processes and signals

**PID (Process Identifier)**
A unique number assigned by the OS to identify each running process.

**Process**
An instance of a computer program that is being executed.

**Finding a Process' PID**
Use commands like ps aux, top, or pgrep.

**Killing a Process**
Use the kill command followed by the PID (e.g., kill 1234).

**Signal**
A software interrupt sent to a process to notify it of an event or request action.

**Non-Ignorable Signals**
SIGKILL (9) and SIGSTOP (19).

---

## Linux Security Basics

**What is Linux**
Linux is a free, open-source operating system kernel that serves as the foundation for various Unix-like OS distributions.

**What is a Linux Command**
A Linux command is a specific instruction typed into the terminal to execute programs, manage files, or configure system settings.

**What is the structure of the Linux operating system**
The Linux structure consists of four main layers: the hardware, the kernel (core), the shell (interface), and the user applications.

**What is the purpose of the FHS and what are the benefits of using it**
The Filesystem Hierarchy Standard defines directory structure to ensure consistency across distributions, simplifying software compatibility and administration.

**What are the different directories in the Linux file system, and what are their purposes**
Key directories include /bin (user binaries), /etc (configuration files), /var (variable data like logs), /home (user data), and /tmp (temporary files).

**How to protect files and directories**
Protect files by setting appropriate permissions with chmod, managing ownership with chown, and optionally applying encryption or mandatory access controls like SELinux/AppArmor.

**How to monitor and investigate system activity**
Monitor activity using tools like top, htop, journalctl for logs, and auditd to track system calls and policy violations.

**How to securely transfer files and data**
Securely transfer data using encrypted protocols such as SFTP (SSH File Transfer Protocol) or SCP over SSH to ensure confidentiality and integrity.

**How to configure and manage a firewall**
Configure and manage firewalls using utilities like ufw (Uncomplicated Firewall) or editing rules directly with iptables or nftables.

**How to identify and terminate malicious processes**
Identify malicious processes using ps, top, or netstat to spot anomalies, then terminate them safely using the kill command with the specific PID.

**How to use the ps and kill commands to identify and terminate malicious processes**
Use ps aux | grep [process] to find the Process ID (PID) and then run kill -9 [PID] to force-terminate the malicious process.

**How to use the netstat and ss commands to monitor network traffic for suspicious activity**
Use netstat -tulpn or ss -tulpn to list active connections and listening ports, helping you spot unauthorized outbound connections or open services.

**How to use the nmap, lynis and tcpdump commands to analyze network traffic for suspicious behavior**
Use nmap to scan network topology, tcpdump to capture packet-level traffic, and lynis to audit system security and detect misconfigurations.

**How to use iptables and ufw to manage the firewall rules on Linux systems**
Use ufw allow/deny [port] for simplified management or write specific iptables -A [chain] -j [action] rules to control packet filtering at a granular level.

---

## Permissions, SUID & SGID

**What are the three user-based permission groups in Linux?**
Owner, group, and others.

**What are the Linux commands chmod, sudo, su, chown, and chgrp used for?**
chmod modifies file access rights, sudo executes commands with elevated privileges, su switches the current user identity, chown changes file ownership, and chgrp changes the associated group.

**What is the purpose of the setuid and setgid in Linux file permissions, and how do you use them?**
setuid and setgid cause a file to execute with the permissions of its owner or group respectively and are applied using chmod u+s or g+s.

**What is the difference between the chown and chgrp commands?**
chown is used to change both the user and group ownership of a file, whereas chgrp is restricted to changing only the group ownership.

**What are some best practices for managing file permissions on Linux?**
Best practices include applying the principle of least privilege, avoiding world-writable permissions on sensitive files, and regularly auditing access controls.

**How can you audit file permissions changes on your system?**
You can audit file permission changes by configuring auditd rules to monitor specific paths or by analyzing system logs for relevant syscalls.

**What is Umask in Linux?**
Umask is a numeric mask that determines the default file creation permissions by subtracting specified bits from the system's maximum allowable permissions.

---

## MAC

**What is MAC in Linux?**
MAC (Mandatory Access Control) is a security model where the system enforces access policies that users cannot modify, overriding traditional discretionary permissions.

**How does SELinux enforce MAC?**
SELinux enforces MAC by attaching security labels to processes and objects and allowing or denying actions based on configurable policy rules.

**What are the differences between SELinux and AppArmor?**
SELinux uses label-based policies with fine-grained type enforcement, while AppArmor uses path-based profiles that are generally simpler to configure and manage.

**What is the purpose of policy in MAC systems?**
A policy defines the rules governing which interactions between subjects and objects are permitted, serving as the authoritative source for all access decisions.

**How do labels work in SELinux?**
Labels assign a security context (user, role, type, and optionally level) to every process and object, and policy rules reference these labels to determine allowed operations.

**What are Type Enforcement, Role-Based Access Control, and Multi-Level Security in SELinux?**
Type Enforcement governs access by process and object types, RBAC restricts which roles can access which types, and MLS adds hierarchical secrecy levels to prevent unauthorized information flow.

**How can you check the status of SELinux on a system?**
Run sestatus or getenforce to see whether SELinux is enabled and whether it is running in enforcing, permissive, or disabled mode.

**What are common SELinux management commands?**
Common commands include sestatus, getenforce, setenforce, audit2allow, restorecon, chcon, and semanage.

**How do you set file contexts in SELinux?**
Use chcon for temporary context changes or semanage fcontext with restorecon for persistent, policy-backed modifications.

**What is an AppArmor profile?**
An AppArmor profile is a set of rules defining what files, capabilities, and network accesses a confined application is permitted to use.

**How do you reload AppArmor profiles?**
Run aa-disable or aa-enforce followed by apparmor_parser -r <profile> or simply systemctl reload apparmor.

**What is the concept of least privilege in MAC?**
Least privilege means granting only the minimum access rights necessary for a process or user to perform their intended function, reducing the attack surface.

**How do you troubleshoot SELinux issues?**
Check /var/log/audit/audit.log for AVC denials, use audit2why and audit2allow to interpret them, and temporarily switch to permissive mode to isolate SELinux-related blocks.

**What is the significance of audit logs in MAC systems?**
Audit logs record every policy denial and relevant access event, providing visibility into blocked operations and enabling administrators to refine policies.

**Can you explain the concept of capabilities in Linux security?**
Capabilities break the monolithic root privilege into distinct units (e.g., CAP_NET_RAW, CAP_SYS_ADMIN), allowing fine-grained assignment of specific kernel-level permissions to processes without granting full root.

**How do you use semanage?**
Use semanage to modify SELinux policy components persistently—for example, semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?") to add a file context rule, followed by restorecon -R /web.

---

## Windows Fundamentals

**What is Windows and how does it differ from other operating systems?**
Windows is a proprietary, GUI-centric operating system developed by Microsoft that relies on the NT kernel and closed-source architecture, distinguishing it from open-source or UNIX-like systems.

**What is the Windows architecture and how do kernel mode and user mode interact?**
The architecture separates privileged kernel mode (handling hardware and core OS functions) from unprivileged user mode (running applications), with interactions occurring strictly through defined system calls and message passing to ensure stability.

**How does the Windows file system (NTFS) work and what are permissions and ACLs?**
NTFS manages data storage using Master File Table records and enforces security via Access Control Lists (ACLs) containing Access Control Entries (ACEs) that define specific allow/deny rules for users and groups.

**What is the Windows Registry and what role does it play in system configuration?**
The Registry is a hierarchical database storing low-level settings for the OS and applications, serving as the central repository for configuration data that replaces many legacy text-based config files.

**How does Windows manage users, groups, and access control?**
Windows uses Security Identifiers (SIDs) to uniquely identify users and groups, applying access tokens generated at login to enforce permissions against objects secured by ACLs.

**How do you navigate the Windows interface and use built-in administrative tools?**
Navigation is primarily graphical via the Start menu and File Explorer, while administrative tasks are performed using tools like Computer Management, Task Manager, PowerShell, and the Settings app.

**What are Windows processes and services and how do you monitor them?**
Processes are active program instances running in memory, while services run in the background without direct user interaction; both are monitored and managed via Task Manager or the Services.msc console.

**How do you use the Command Prompt (cmd.exe) for basic system administration?**
Command Prompt executes legacy DOS-style commands like dir, ipconfig, and netstat to perform file management, network diagnostics, and system queries in a text-based interface.

**What are Windows Event Logs and how do you read and interpret them?**
Event Logs record system, security, and application events chronologically, which administrators analyze using Event Viewer to troubleshoot issues, track security incidents, and monitor system health.

**What built-in security features does Windows provide, such as UAC, Windows Defender, and BitLocker?**
Windows includes User Account Control (UAC) to limit privilege escalation, Windows Defender for real-time antivirus protection, and BitLocker for full-disk encryption of data volumes.

**How does Windows handle network configuration and connectivity?**
Network configuration is managed through the Network and Sharing Center, PowerShell cmdlets, and the TCP/IP stack settings, utilizing DHCP, DNS, and firewall rules to establish and secure connections.

**What are common Windows-based attack surfaces and how can they be mitigated?**
Common attack vectors include unpatched vulnerabilities, weak credentials, and exposed RDP ports, which are mitigated by regular updates, strong authentication policies, firewall restrictions, and disabling unnecessary services.

---

## Forensic Ethics & Methodologies

**What is digital forensics?**
Digital forensics is the scientific process of identifying, preserving, analyzing, and presenting digital evidence in a manner that is legally admissible.

**Why is ethics important in digital forensics?**
Ethics ensure investigators maintain public trust, protect individual privacy rights, and guarantee that evidence is handled impartially without bias or unauthorized access.

**What are common ethical issues in digital forensics?**
Common issues include privacy violations, scope creep during data collection, conflicts of interest, and the accidental exposure of sensitive non-relevant information.

**What is the role of integrity in forensic analysis?**
Integrity ensures that evidence remains unaltered from the time of seizure to presentation in court, typically verified through cryptographic hashing to prove authenticity.

**How does one maintain objectivity in digital investigations?**
Objectivity is maintained by following standardized procedures, avoiding preconceived notions about the outcome, and documenting all findings regardless of whether they support the initial hypothesis.

**What are the ACPO principles for computer forensics?**
The ACPO principles mandate that no action should change data, an audit trail must be created, the investigator must be competent, and law enforcement guidance must be followed throughout the process.

**How do you ensure evidence is admissible in court?**
Evidence is made admissible by strictly adhering to legal standards, maintaining a documented chain of custody, using validated tools, and proving the evidence's authenticity and integrity.

**What is chain of custody and why is it crucial?**
Chain of custody is the chronological documentation of who handled evidence, when, and why; it is crucial to prevent tampering claims and establish the evidence's reliability in legal proceedings.

**What are the stages of the digital forensic process?**
The standard stages are identification, preservation, collection, examination, analysis, and reporting, often followed by presentation in legal or administrative settings.

**How does one document findings in a forensic report?**
Findings are documented in a clear, reproducible report that details the methodology used, tools employed, step-by-step actions taken, and the specific results obtained without interpretation or bias.

**What are some standard digital forensic methodologies?**
Standard methodologies include the NIST SP 800-86 framework, the Scientific Method applied to digital evidence, and industry-specific protocols like those from SANS or IACIS.

**How does one handle digital evidence to preserve its integrity?**
Integrity is preserved by creating bit-for-bit forensic images, writing-blocking original media, calculating hash values before and after analysis, and storing evidence in secure, controlled environments.

**What are some common tools used in digital forensics?**
Common tools include Autopsy (open source), EnCase, FTK (Forensic Toolkit), Wireshark for network analysis, and various write-blockers like Tableau or WiebeTech hardware.

**What organizations set standards for digital forensic practices?**
Key organizations include NIST (National Institute of Standards and Technology), ISO (International Organization for Standardization), SWGDE (Scientific Working Group on Digital Evidence), and ENFSI.

**How do you stay current with evolving technology in forensics?**
Investigators stay current through continuous education, attending conferences (like DFRWS), obtaining certifications (CFE, GCFA), and participating in professional communities and training workshops.

**What are the legal implications of digital forensic investigations?**
Legal implications involve compliance with search and seizure laws (like the Fourth Amendment in the US), adherence to data protection regulations (like GDPR), and potential liability for mishandling evidence or violating privacy.

---

## Networking Fundamentals

**What is networking and why is it essential?**
Networking connects devices to share resources and data, enabling communication, collaboration, and access to centralized systems across organizations.

**What is the difference between LAN and WAN?**
LAN spans a limited geographic area like a building while WAN covers larger distances connecting multiple locations or cities.

**What are the main network topologies (Bus, Star, Ring, Mesh)?**
Bus uses a single backbone cable, Star centers around a hub/switch, Ring connects nodes in a circle, and Mesh provides redundant interconnections between all nodes.

**What is the difference between physical and logical topology?**
Physical topology describes actual cable/device layout while logical topology defines how data flows through the network regardless of physical connections.

**What are the 7 layers of the OSI model and their functions?**
Physical (cabling/signals), Data Link (frames/MAC), Network (packets/routing), Transport (segments/reliability), Session (connections), Presentation (encryption/formatting), Application (user interfaces).

**What happens at each layer during data transmission?**
Data encapsulates downward adding headers at each layer during transmission and decapsulates upward removing headers at the receiving end.

**What is encapsulation and decapsulation?**
Encapsulation adds protocol headers/footers as data moves down layers while decapsulation removes them as data moves up layers at the destination.

**What are the 4 layers of the TCP/IP model?**
Network Interface, Internet, Transport, and Application layers corresponding to OSI's combined physical/data link, network, transport, and session/presentation/application.

**How does TCP/IP compare to the OSI model?**
TCP/IP condenses OSI's 7 layers into 4 practical layers with TCP/IP being implementation-focused while OSI serves as a theoretical reference framework.

---

## Protocols & Transmission

**What are the main network protocols (HTTP, HTTPS, FTP, SSH, DNS, DHCP)?**
HTTP/HTTPS for web traffic, FTP for file transfer, SSH for secure remote access, DNS for name resolution, and DHCP for automatic IP address assignment.

**What is the difference between TCP and UDP?**
TCP is connection-oriented with guaranteed delivery and ordering while UDP is connection-less with faster but unreliable transmission without guarantees.

**What are the different types of transmission media (wired vs wireless)?**
Wired includes twisted pair copper cables and fiber optics while wireless uses radio waves including Wi-Fi, cellular, and microwave technologies.

**What is the role of a Hub, Switch, Router, Firewall?**
Hubs broadcast traffic indiscriminately, switches direct frames by MAC addresses, routers route packets between networks, and firewalls filter traffic by rules.

**What is the difference between Layer 2 and Layer 3 devices?**
Layer 2 devices forward frames using MAC addresses while Layer 3 devices route packets using IP addresses across networks.

**What is a VLAN and why is it used?**
A Virtual Local Area Network logically segments broadcast domains on a single switch for improved security, performance, and traffic management.

**What is 802.1Q tagging?**
IEEE 802.1Q adds a 4-byte tag to Ethernet frames identifying VLAN membership for trunk links carrying multiple VLANs.

**What are VLAN hopping attacks and how to prevent them?**
VLAN hopping allows unauthorized access across VLANs via switch spoofing or double-tagging; prevent by disabling auto-trunking and limiting native VLAN usage.

**What is Inter-VLAN routing?**
Inter-VLAN routing enables communication between different VLANs using a router or Layer 3 switch acting as a gateway between segmented networks.

**What is a MAC address and how is it structured?**
A Media Access Control address is a 48-bit unique hardware identifier formatted as six hexadecimal pairs separating OUI from device-specific portions.

**What is the difference between OUI and NIC-specific portions?**
The first 24 bits (OUI) identify the manufacturer while the last 24 bits uniquely identify the individual network interface card.

**What are special MAC addresses (broadcast, multicast)?**
Broadcast FF:FF:FF:FF:FF:FF reaches all devices while multicast addresses target specific groups and unicast targets a single destination.

**What is an IPv4 address and its format?**
An IPv4 address is a 32-bit numerical identifier expressed in dotted decimal notation as four octets separated by periods (e.g., 192.168.1.1).

**What are IP address classes (A, B, C, D, E)?**
Class A supports large networks (first bit 0), Class B medium (first bits 10), Class C small (first bits 110), Class D for multicast, Class E experimental.

**What are private IP ranges (RFC 1918)?**
Private ranges include 10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16 which cannot be routed publicly and require NAT for internet access.

**What are special IP addresses (loopback, broadcast)?**
Loopback 127.0.0.1 tests local TCP/IP stack and broadcast sends to all hosts within a network segment.

**What is CIDR notation?**
Classless Inter-Domain Routing notation expresses IP blocks using prefix length (e.g., /24) indicating the number of bits in the network portion.

**How to calculate subnets, hosts per subnet, and network ranges?**
Subnet count equals 2^(borrowed bits), hosts per subnet equals 2^(host bits)-2, and ranges are determined by incrementing the subnet portion systematically.

**How to perform subnetting manually?**
Identify borrowed bits, calculate block size from least significant subnet bit, then increment network addresses by that block value.

**What is ARP and how does it work?**
Address Resolution Protocol maps IP addresses to MAC addresses by broadcasting requests and caching responses in an ARP table.

**What are the security concerns with ARP (ARP spoofing)?**
ARP lacks authentication allowing attackers to forge MAC-to-IP mappings enabling man-in-the-middle interception and traffic redirection attacks.

**Why was IPv6 developed and how does it differ from IPv4?**
IPv6 was created to address IPv4 exhaustion with 128-bit addresses eliminating NAT, built-in IPsec, and simplified header structure.

**What are well-known ports (0-1023)?**
Well-known ports are system-reserved for standard services like HTTP(80), HTTPS(443), SSH(22), DNS(53), and SMTP(25).

**What are registered ports and dynamic ports?**
Registered ports (1024-49151) are assigned by IANA for applications while dynamic/ephemeral ports (49152-65535) are client-assigned temporarily.

**What is DHCP and what problem does it solve?**
Dynamic Host Configuration Protocol automates IP address assignment preventing manual configuration errors and managing address pool allocation efficiently.

**What is the DORA process (Discover, Offer, Request, Acknowledgement)?**
Client broadcasts Discover, server responds with Offer, client requests the offered address, and server acknowledges completing IP lease assignment.

**What is a DHCP lease and how does renewal work?**
A DHCP lease is temporary IP assignment renewed automatically at 50% of lease time through unicast T1 renewal or broadcast T2 rebind.

**What are DHCP attacks (Rogue Server, Starvation)?**
Rogue server attacks assign malicious configurations while starvation exhausts the address pool by flooding requests with fake MAC addresses.

**What is DHCP Snooping and how does it protect networks?**
DHCP Snooping distinguishes trusted from untrusted ports blocking rogue server responses and validating DHCP packet integrity against a binding database.

**What is NAT and why is it used?**
Network Address Translation maps private internal addresses to public external addresses conserving IPv4 space and providing basic security obfuscation.

**What is the difference between Static NAT, Dynamic NAT, and PAT?**
Static creates permanent 1:1 mappings, Dynamic pools addresses dynamically assigning them, and PAT uses port multiplexing many:one for maximum conservation.

**What is Port Forwarding?**
Port forwarding redirects incoming traffic on a specific public port to an internal private IP address and port mapping.

**What is NAT Traversal (STUN, TURN, ICE)?**
STUN discovers public addresses, TURN relays through intermediate servers, and ICE combines methods for establishing connections through NAT.

**What is Carrier-Grade NAT (CGNAT)?**
CGNAT extends NAT to ISP level where multiple subscribers share public IPs creating additional addressing constraints for end users.

**What is DNS and how does it work?**
Domain Name System resolves human-readable domain names to IP addresses through hierarchical query cascading from recursive to authoritative servers.

**What is the DNS hierarchy (Root, TLD, Authoritative)?**
Root servers delegate to Top-Level Domains which delegate to authoritative name servers holding actual resource records for specific domains.

**What is the DNS resolution process?**
Recursive resolver queries root, receives TLD referral, queries TLD, receives authoritative referral, queries authoritative server returning final answer cached locally.

**What are the main DNS record types (A, AAAA, CNAME, MX, NS, TXT, PTR)?**
A stores IPv4, AAAA IPv6, CNAME aliases, MX mail routing, NS name servers, TXT text verification, and PTR reverse lookup entries.

**What are DNS security threats (Spoofing, Hijacking, Tunneling)?**
Spoofing returns false records, hijacking redirects domains to attacker servers, and tunneling exfiltrates data through DNS query responses.

**What is DNSSEC and encrypted DNS (DoH, DoT)?**
DNSSEC digitally signs records ensuring authenticity while DoH/DoT encrypt queries preventing eavesdropping and modification attacks.

---

## Authentication & Directory Services

**What is RADIUS and how does it work?**
Remote Authentication Dial-In User Service centralizes authentication using shared secrets and UDP transmitting credentials to verify access authorization.

**What is TACACS+ and how does it differ from RADIUS?**
TACACS+ separates authentication authorization accounting over TCP encrypting entire payloads while RADIUS only encrypts passwords and combines AAA.

**What is Kerberos and what attacks target it?**
Kerberos provides ticket-based mutual authentication requiring KDC; attacks include Golden Ticket, Silver Ticket, Pass-the-Ticket, and AS-REP Roasting.

**What is LDAP and how is it used in networks?**
Lightweight Directory Access Protocol queries hierarchical directory databases for user authentication, group memberships, and centralized identity management.

**Why is NTP important for security?**
Network Time Protocol ensures synchronized clocks critical for log correlation, certificate validation, Kerberos ticket timestamps, and forensic analysis accuracy.

**What is Syslog and its severity levels?**
Syslog collects and forwards logs across 8 severity levels from Emergency(0) to Debug(7) enabling centralized monitoring and incident investigation.

**What is an Autonomous System (AS) and ASN?**
An Autonomous System is a network under single administrative control identified by a unique Autonomous System Number for routing policy purposes.

**What is BGP and how does it work?**
Border Gateway Protocol exchanges routing information between ASes selecting optimal paths based on policies maintaining global internet connectivity tables.

**What are BGP hijacking attacks?**
BGP hijacking announces illegitimate prefixes redirecting traffic to attacker-controlled networks enabling interception disruption or surveillance.

**What is peering vs transit?**
Peering directly exchanges traffic between networks without payment while transit purchases upstream connectivity accessing broader internet reach.

**What is an Internet Exchange Point (IXP)?**
IXPs are physical facilities where networks interconnect for efficient local traffic exchange reducing latency and transit costs through direct peering.

**What is a CDN and how does Anycast work?**
Content Delivery Networks cache content geographically while Anycast routes users to nearest identical IP announced from multiple locations simultaneously.

**What are the Wi-Fi frequency bands (2.4 GHz, 5 GHz, 6 GHz)?**
2.4GHz offers range with congestion, 5GHz provides speed with better penetration balance, and 6GHz delivers maximum throughput with limited range.

**What are the Wi-Fi standards (802.11a/b/g/n/ac/ax)?**
Standards progress from 802.11a/b legacy through g/n improvements to ac(WiFi5) and ax(WiFi6) offering increasing speeds and efficiency gains.

**What is the difference between WEP, WPA, WPA2, WPA3?**
WEP is broken RC4, WPA introduced TKIP, WPA2 mandates AES-CCMP, and WPA3 adds Simultaneous Authentication Equals forward secrecy protection.

**What are common wireless attacks (Evil Twin, Deauth, KRACK)?**
Evil Twin mimics legitimate APs, deauthentication floods disconnect clients forcing reconnection, and KRACK exploits WPA2 handshake key reinstallation flaws.

**What are wireless security best practices?**
Use WPA3 when available strong passphrases disable WPS separate SSIDs monitor for rogue APs and enable 802.1X Enterprise authentication.

**What is the difference between PSK and Enterprise authentication?**
PSK uses shared pre-shared keys vulnerable to compromise while Enterprise leverages RADIUS authenticating each user individually with certificates or credentials.

---

## Security Principles & Defense

**What is the CIA Triad (Confidentiality, Integrity, Availability)?**
Confidentiality prevents unauthorized disclosure, Integrity ensures data accuracy and trustworthiness, and Availability guarantees accessible resources when needed.

**What is Defense in Depth?**
Defense in Depth layers multiple security controls across people processes and technology ensuring breach prevention even if individual controls fail.

**What are the key security principles (Least Privilege, Zero Trust)?**
Least Privilege grants minimum necessary access rights while Zero Trust assumes no implicit trust requiring continuous verification of every request.

**What is AAA (Authentication, Authorization, Accounting)?**
Authentication verifies identity, Authorization grants permissions, and Accounting tracks user actions for accountability and auditing compliance.

**What are the main attack categories (Reconnaissance, Interception, DoS)?**
Reconnaissance gathers intelligence, Interception modifies/captures data in transit, and Denial-of-Service overwhelms resources preventing legitimate access.

**What is a Man-in-the-Middle (MitM) attack?**
MitM positions attackers between communicating parties intercepting modifying or injecting messages without either party detecting the manipulation.

**What are DDoS attacks (Volumetric, Protocol, Application)?**
Volumetric floods bandwidth, Protocol exhausts infrastructure state tables, and Application targets resource-intensive endpoints exhausting server capacity.

**What are common password attacks?**
Brute force tries combinations, dictionary uses wordlists, rainbow tables use precomputed hashes, and credential stuffing reuses leaked credentials.

**What are the types of firewalls (Packet Filtering, Stateful, NGFW)?**
Packet filters check individual packets, stateful track connection context, and Next-Gen Firewalls add deep inspection IDS application awareness.

**How to write firewall rules?**
Define source destination port protocol action allow/deny order matters placing specific rules before general ones with implicit deny all default.

**What is a DMZ?**
Demilitarized Zone isolates publicly-facing servers from internal networks limiting lateral movement if perimeter systems get compromised.

**What is the difference between IDS and IPS?**
Intrusion Detection Systems alert on suspicious activity while Intrusion Prevention Systems actively block detected threats inline with traffic flow.

**What are detection methods (Signature, Anomaly, Heuristic)?**
Signatures match known patterns, anomalies identify deviations from baseline behavior, and heuristics apply rule-based logic to detect novel threat indicators.

**What is network segmentation and why is it important?**
Segmentation divides networks into isolated zones containing breaches limiting lateral movement and enforcing granular security policy boundaries.

**What is Zero Trust architecture?**
Zero Trust requires explicit verification for every access request regardless of network location implementing microsegmentation continuous monitoring multi-factor auth.

**What is a SIEM and what logs should be monitored?**
Security Information Event Management aggregates correlates analyzes logs from firewalls endpoints authentication systems and critical infrastructure components continuously.

**What is NAC (Network Access Control)?**
Network Access Control validates device compliance identity health posture before granting network access blocking non-compliant endpoints.

**What is 802.1X authentication and the EAP methods?**
802.1X provides port-based network access control using Extensible Authentication Protocol variants including PEAP EAP-TLS and EAP-TTLS.

---

## Scanning & Enumeration

**What are the types of port scans (TCP Connect, SYN, UDP)?**
TCP Connect completes three-way handshakes, SYN sends flags without completion stealthier, and UDP probes open/closed filtered UDP services.

**What are the port states (Open, Closed, Filtered)?**
Open accepts connections, Closed rejects connections actively, and Filtered drops packets silently leaving status ambiguous to scanners.

**What protocols are used for network enumeration (SNMP, NetBIOS, SMB, LDAP)?**
SNMP extracts device information, NetBIOS enumerates Windows shares, SMB reveals file shares/user sessions, and LDAP queries directory structures.

**How to defend against reconnaissance?**
Implement strict firewall rules limit exposed services disable unnecessary protocols log scan attempts use IDS and employ honeytokens honeypots.

---

## Cryptography Basics

**What is cryptography in cybersecurity?**
The science of securing data through mathematical algorithms that convert readable information into unreadable formats to protect confidentiality, integrity, and authenticity.

**What are the different types of cryptography?**
Symmetric encryption (single shared key), asymmetric encryption (public-private key pairs), and cryptographic hashing (one-way functions).

**What is Encryption?**
The process of transforming plaintext into ciphertext using an algorithm and key, rendering data unreadable without the appropriate decryption key.

**What is Decryption?**
The reverse process of converting ciphertext back into readable plaintext using the correct cryptographic key.

**What is the importance of cryptography?**
It protects sensitive data at rest and in transit, ensures authentication, prevents tampering, and maintains regulatory compliance across digital systems.

**What are the types of cryptography?**
Symmetric cryptography uses one shared secret key, asymmetric uses mathematically linked public-private key pairs, and hashing produces irreversible fixed-length digests for integrity verification.

**What are the applications of cryptography?**
Secure communications (TLS/SSL), disk encryption, digital signatures, cryptocurrency/blockchain, authentication systems, VPN tunneling, and secure key exchange protocols.

**What is a hash algorithm?**
A one-way mathematical function that converts arbitrary-length input into a fixed-length deterministic output used for integrity checks and password storage without reversible decryption.

**What SHA stands for?**
Secure Hash Algorithm, a family of cryptographic hash functions published by NIST producing digests of varying bit lengths (SHA-1, SHA-256, SHA-512, etc.).

**What is John the Ripper?**
An open-source password cracking tool that recovers passwords from hashed formats using dictionary attacks, brute force, and rule-based transformations.

**How to use John the Ripper?**
Run john against a hash file specifying format with --format=, optional wordlist with --wordlist=, and rules with --rules; cracked passwords display via --show.

**How to crack advanced hashes with John the Ripper?**
Specify exact hash format, apply aggressive rule sets (--rules=Jumbo), use large/custom wordlists, enable incremental mode, and leverage dynamic magic for auto-detection.

**What is hashcat?**
A high-performance password recovery tool leveraging GPU acceleration to crack hashes significantly faster than CPU-based tools, supporting hundreds of hash types and multiple attack modes.

**How to use hashcat?**
Execute hashcat with the hash file, hash type identifier (-m #), attack mode (-a #), and wordlist/mask path; cracked results display with --show.

---

## Authentication vs Authorization

### General Concepts

**What is the purpose of authentication in computer security?**
Authentication verifies the identity of a user, system, or entity requesting access.

**What is the purpose of authorization in access control systems?**
Authorization determines what actions and resources an authenticated entity is permitted to access.

**What are the fundamental differences between authentication and authorization?**
Authentication confirms who you are; authorization determines what you can do.

**What is the correct sequence of authentication and authorization in security systems?**
Authentication always occurs first, followed by authorization — you must prove identity before permissions can be evaluated.

### Authentication

**What are the three main authentication factors?**
Something you know (password/PIN), something you have (token/smart card), and something you are (biometrics).

**How does the authentication process work?**
A subject presents credentials which are validated against a stored identity record, and a token or session is issued upon success.

**What are the main authentication protocols?**
OAuth 2.0, OpenID Connect (OIDC), SAML, Kerberos, and RADIUS.

**What is the difference between single-factor and multi-factor authentication?**
Single-factor uses one credential type, while MFA combines two or more distinct factors, significantly reducing compromise risk.

**What HTTP status code indicates authentication failure?**
401 Unauthorized indicates authentication failure (despite the misleading name).

### Authorization

**What are the main authorization models?**
RBAC, ABAC, ACL (Access Control List), MAC (Mandatory Access Control), and DAC (Discretionary Access Control).

**How does Role-Based Access Control (RBAC) work?**
Permissions are assigned to roles, and users inherit those permissions by being assigned to the appropriate role.

**How does Attribute-Based Access Control (ABAC) differ from RBAC?**
ABAC evaluates dynamic attributes (user, resource, environment, action) rather than static roles, enabling finer-grained and context-aware decisions.

**What are the components of authorization?**
Subject (requester), action (operation), resource (target object), and policy/context (rules governing the decision).

**What HTTP status code indicates authorization failure?**
403 Forbidden indicates the authenticated user lacks permission for the requested resource.

### Security Best Practices

**What are the advantages of implementing both authentication and authorization?**
Together they enforce defense-in-depth — ensuring only verified identities access only their permitted resources.

**What are the security risks of skipping authentication or authorization?**
Skipping authentication allows impersonation and uncontrolled entry; skipping authorization lets any authenticated user access all resources, leading to privilege escalation and data breaches.

**How do authentication and authorization work together to protect systems?**
Authentication gates entry by verifying identity, then authorization restricts scope by enforcing least-privilege access policies.

**What is the difference between a username/password and biometric authentication?**
Username/password is a knowledge factor that can be shared or reset, while biometrics is an inherent factor that is unique to the individual and cannot be easily changed if compromised.

---

## Email Security Protocols

### Email Security Fundamentals

**What is email authentication and why is it important?**
Email authentication verifies that a message comes from who it claims to be from, preventing spoofing and phishing attacks.

**What are the main threats that email authentication protocols protect against?**
Email spoofing, phishing, domain impersonation, BEC (Business Email Compromise), and unauthorized sending on behalf of a domain.

**How do SPF, DKIM, and DMARC work together to provide comprehensive email security?**
SPF authorizes sending servers, DKIM verifies message integrity via cryptographic signatures, and DMARC ties both together with alignment checks and enforcement policies.

**What is the difference between email spoofing and domain impersonation?**
Spoofing forges the sender address directly, while domain impersonation uses a lookalike domain (e.g., paypa1.com instead of paypal.com).

### Sender Policy Framework (SPF)

**What is SPF and what problem does it solve?**
SPF is a DNS-based protocol that specifies which mail servers are authorized to send email on behalf of a domain, preventing unauthorized senders from spoofing that domain.

**How does SPF authorize sending mail servers?**
By publishing a DNS TXT record listing permitted IP addresses, ranges, and included domains that receivers check against the connecting server's IP.

**What is the correct syntax for an SPF record?**
v=spf1 [mechanisms] [qualifier]all — e.g., v=spf1 ip4:192.0.2.0/24 include:_spf.google.com -all.

**What are the different SPF mechanisms (ip4, include, mx, a, all) and when do you use each?**
ip4/ip6 for specific IP ranges, include to incorporate another domain's SPF, mx to authorize your MX servers, a to authorize IPs from your domain's A record, and all as the catch-all default.

**What are the SPF qualifiers (+pass, -fail, ~softfail, ?neutral) and what do they mean?**
+ = pass (default), - = fail (reject), ~ = softfail (mark suspicious but accept), ? = neutral (no policy assertion).

**What is the SPF evaluation order and why does it matter?**
Mechanisms are evaluated left to right; the first matching mechanism determines the result, so order affects which rules take priority.

**What are the different SPF results (pass, fail, softfail, neutral, temperror, permerror)?**
Pass = authorized, fail = unauthorized, softfail = probably unauthorized, neutral = no assertion, temperror = transient DNS error, permerror = permanent record error (e.g., syntax invalid).

**What is the 10 DNS lookup limit in SPF and why does it exist?**
RFC 7208 limits resolving include, a, mx, and redirect mechanisms to 10 total lookups to prevent DNS amplification attacks and excessive load on receiving servers.

**Why does email forwarding break SPF and how can you mitigate this?**
Forwarding changes the originating IP, failing the receiver's SPF check; mitigation includes ARC (Authenticated Received Chain), SRS (Sender Rewriting Scheme), or relying on DKIM which survives forwarding.

**What does -all mean in an SPF record and why is it important?**
It means "fail all servers not explicitly authorized," ensuring that any sender not listed is marked as unauthorized — the strongest enforcement stance.

**How do you test and validate an SPF record?**
Use dig TXT domain.com, online tools like MXToolbox or dmarcian, or send test emails and inspect the Received-SPF header.

### DomainKeys Identified Mail (DKIM)

**What is DKIM and how does it differ from SPF?**
DKIM attaches a cryptographic signature to messages verified via a public key in DNS, proving content integrity and sender authorization — unlike SPF which only validates the sending server's IP.

**How does DKIM use cryptographic signatures to verify email authenticity?**
The sending server signs selected headers and body with a private key; the receiver retrieves the public key from DNS and verifies the signature.

**What is a DKIM selector and why are selectors used?**
A selector is a string in the DKIM header that identifies which specific key to look up in DNS, enabling multiple concurrent keys and key rotation.

**What are the components of a DKIM signature header?**
Key fields include v (version), a (algorithm), b (signature value), bh (body hash), d (domain), h (signed headers), s (selector), and c (canonicalization).

**How does the DKIM signing process work step-by-step?**
1) Canonicalize headers/body → 2) Hash the body → 3) Sign selected headers and body hash with the private key → 4) Attach the DKIM-Signature header → 5) Send.

**How does the DKIM verification process work step-by-step?**
1) Extract selector and domain from DKIM-Signature → 2) Query [selector]._domainkey.[domain] in DNS for the public key → 3) Canonicalize → 4) Verify signature with the public key → 5) Compare body hash.

**What are canonicalization methods (simple/simple, relaxed/relaxed) and when do you use each?**
Simple preserves headers/body exactly; relaxed tolerates whitespace/case changes — relaxed is preferred for headers and body since mail servers often modify content in transit.

**What is the format of a DKIM DNS record?**
A TXT record at [selector]._domainkey.[domain] containing v=DKIM1; k=rsa; p=[base64-encoded-public-key].

**How do you generate DKIM keys and what key size should you use?**
Use OpenSSL (openssl genrsa -out private.pem 2048) — RSA 2048-bit minimum; 4096-bit recommended for longer-term use; Ed25519 is also now supported.

**Why is DKIM forwarding-friendly while SPF is not?**
Because the DKIM signature travels with the message and verifies against DNS (independent of the sending IP), while SPF breaks when the connecting IP changes during forwarding.

**What is DKIM key rotation and how do you perform it?**
Publishing a new selector/key pair alongside the old one, allowing signed messages already in transit to still verify under the old key before removing it — typically done every 6–12 months.

**How do you test and validate DKIM signatures?**
Send a test email and inspect the Authentication-Results header, use tools like DKIM Validator, or verify manually with dig TXT selector._domainkey.domain.com.

### Domain-based Message Authentication, Reporting & Conformance (DMARC)

**What is DMARC and how does it build on SPF and DKIM?**
DMARC uses SPF and DKIM results plus alignment checks between the envelope/domain/from addresses to determine a policy action (none/quarantine/reject) and provides reporting.

**What are the required and optional DMARC tags?**
Required: v (version) and p (policy); Optional: rua (aggregate reports), ruf (forensic reports), sp (subdomain policy), pct (percentage), ri (report interval), adkim/aspf (alignment mode).

**What are the three DMARC policy levels (none, quarantine, reject) and what does each do?**
none = monitor only, no enforcement; quarantine = send failing messages to spam; reject = drop failing messages entirely.

**What is DMARC alignment and why is it important?**
Alignment ensures the domain in the From header matches the domain validated by SPF (envelope sender) or DKIM (d= tag), closing loopholes where a passing SPF/DKIM could belong to a different domain.

**What is the difference between strict and relaxed alignment modes?**
Strict requires exact domain match; relaxed allows organizational domain match (e.g., mail.example.com aligns with example.com).

**How does DMARC evaluate email authentication (SPF and DKIM checks)?**
It checks if SPF passes and the envelope domain aligns with the From header, OR if DKIM passes and the DKIM domain aligns with the From header — either suffices.

**What are the conditions for a DMARC pass result?**
At least one of SPF + alignment or DKIM + alignment must pass — that is, authenticated and aligned with the From domain.

**What is the pct tag and how is it used for gradual policy enforcement?**
pct=X applies the DMARC policy to X% of failing messages, allowing incremental rollout (e.g., pct=10 quarantines only 10% of failures).

**What is the sp tag and how does it affect subdomain policies?**
sp sets a separate DMARC policy for subdomains; if omitted, subdomains inherit the p policy — useful for rejecting subdomain spoofing while monitoring the apex domain.

**What are DMARC aggregate reports (RUA) and what information do they contain?**
XML reports sent periodically to the RUA address containing sending IP, SPF/DKIM/DMARC results, counts, and policy outcomes — used for monitoring authentication across all senders.

**What are DMARC forensic reports (RUF) and when are they sent?**
Individual failure reports sent per-message when DMARC fails, containing the original message headers and sometimes the body — useful for forensics but raises privacy concerns.

**How do you parse and analyze DMARC reports?**
Use tools like dmarcian, Postmark's DMARC tool, parsedmarc (Python), or commercial platforms that ingest XML/RUA reports and present dashboards.

**What is the recommended DMARC deployment strategy?**
Start with p=none with rua monitoring → analyze reports → move to p=quarantine with low pct → gradually increase → switch to p=reject.

### Protocol Integration

**How do SPF, DKIM, and DMARC work together in the email authentication flow?**
Receiver checks SPF (IP authorized?), DKIM (signature valid?), then DMARC (do either align with From header?) → apply DMARC policy accordingly.

**What happens when SPF passes but DKIM fails (and vice versa)?**
DMARC still passes if the one that passed aligns with the From header — only one aligned pass is needed.

**What happens when both SPF and DKIM fail?**
DMARC fails, and the receiver applies the domain's DMARC policy (none/quarantine/reject).

**How does DMARC use SPF and DKIM results to make policy decisions?**
DMARC combines the pass/fail results of each with alignment checks; if neither aligns and passes, it enforces the published policy.

**What threats does each protocol protect against?**
SPF prevents unauthorized IP spoofing, DKIM prevents content tampering and verifies sender identity, DMARC prevents domain spoofing and provides enforcement + visibility.

**What are the limitations of each protocol?**
SPF breaks on forwarding and has a 10-lookup limit; DKIM can break if intermediaries modify content; DMARC only protects the From header domain and requires at least one aligned pass.

### Implementation and Configuration

**How do you implement SPF for a domain?**
Publish a TXT record at the domain root: v=spf1 [authorized-sources] -all.

**How do you implement DKIM for a domain?**
Generate a key pair, configure your mail server to sign outgoing messages, and publish the public key at [selector]._domainkey.[domain] as a TXT record.

**How do you implement DMARC for a domain?**
Publish a TXT record at _dmarc.[domain]: v=DMARC1; p=none; rua=mailto:dmarc@domain.com.

**What is the correct order for implementing email authentication protocols?**
SPF first → DKIM second → DMARC last (starting at p=none with reporting).

**How do you configure subdomain policies?**
Use the sp tag in the DMARC record, or publish a separate DMARC record at _dmarc.subdomain.domain.com.

**How do you handle third-party email services in SPF records?**
Use include: directives pointing to the provider's SPF record (e.g., include:_spf.google.com), being mindful of the 10-lookup limit.

**How do you troubleshoot authentication failures?**
Inspect Authentication-Results and Received-SPF headers, validate DNS records with dig/online tools, check alignment, and analyze DMARC reports.

### DNS and Technical Details

**Where are SPF, DKIM, and DMARC records published in DNS?**
SPF at the domain root, DKIM at [selector]._domainkey.[domain], DMARC at _dmarc.[domain].

**What DNS record type is used for email authentication records?**
TXT records for all three (SPF, DKIM, and DMARC).

**How do you query DNS records using dig, nslookup, or online tools?**
dig TXT domain.com (SPF), dig TXT selector._domainkey.domain.com (DKIM), dig TXT _dmarc.domain.com (DMARC); or use MXToolbox/dmarcian.

**What is the format of each DNS record type?**
SPF: v=spf1 ... -all; DKIM: v=DKIM1; k=rsa; p=[key]; DMARC: v=DMARC1; p=none; rua=....

**How do DNS lookups work for SPF includes?**
Each include: triggers a recursive TXT lookup on the referenced domain, counting toward the 10-lookup limit.

**How do DNS lookups work for DKIM public keys?**
The verifier constructs the query [selector]._domainkey.[d=domain] and retrieves the TXT record containing the public key.

### Best Practices and Common Mistakes

**What are the best practices for SPF record configuration?**
Keep it under the 10-lookup limit, end with -all, avoid +all, use ip4/ip6 where possible, and use SPF flattening services if includes are too many.

**What are the best practices for DKIM key management?**
Use RSA 2048+ or Ed25519, rotate keys every 6–12 months, use dual selectors during rotation, and store private keys securely.

**What are the best practices for DMARC policy deployment?**
Start at p=none with rua reporting, analyze reports thoroughly, incrementally move to quarantine then reject, and set sp=reject for subdomains early.

**What are common mistakes when implementing email authentication?**
Using +all or ~all in SPF, skipping DKIM, deploying DMARC at p=reject immediately, exceeding the 10-lookup limit, and neglecting third-party senders.

**How do you avoid the SPF 10 DNS lookup limit?**
Use IP addresses directly instead of include:, consolidate includes with SPF flattening tools, or use a delegated SPF service.

**Why should you never use +all in an SPF record?**
It explicitly authorizes every IP on the internet to send email from your domain, completely defeating SPF's purpose.

**Why should you start with p=none in DMARC before enforcing policies?**
To collect reports and identify all legitimate senders before enforcement, avoiding false positives that block valid mail.

**How often should you rotate DKIM keys?**
Every 6–12 months is recommended, or immediately if a private key is compromised.

### Troubleshooting

**How do you diagnose SPF authentication failures?**
Check the Received-SPF header, verify the sending IP against the SPF record, look for include chain issues, and confirm the record doesn't exceed 10 lookups.

**How do you diagnose DKIM signature failures?**
Verify the public key is published correctly in DNS, check for body/header modifications in transit (canonicalization mismatch), confirm the selector exists, and ensure key length is supported.

**How do you diagnose DMARC policy issues?**
Analyze DMARC aggregate reports, verify alignment between SPF/DKIM domains and the From header, and check that the DMARC record is published at _dmarc.[domain].

**What tools can you use to test email authentication?**
MXToolbox, dmarcian, mail-tester.com, DKIM Validator, dig/nslookup, and Parsedmarc for report analysis.

**How do you read and interpret email headers?**
View the full message source and trace from bottom (oldest) to top (newest), looking at Authentication-Results, Received-SPF, DKIM-Signature, and Received headers.

**How do you analyze DMARC aggregate reports?**
Ingest XML reports via tools like parsedmarc or commercial dashboards, then review which IPs/senders pass or fail authentication and alignment.

**What are common causes of authentication failures?**
Unlisted third-party senders in SPF, broken include chains, modified message bodies breaking DKIM, misaligned domains, missing/expired DNS records, and forwarding scenarios.

---

## Network Protocols: Auditing and Securing

### Core Security Principles & Protocol Differentiation

**What are the three core security goals that secure protocols aim to achieve**
Confidentiality, integrity, and availability (the CIA triad).

**What is the main difference between application-layer protocols and network-layer protocols?**
Application-layer operates at OSI layer 7 (user-facing services), while network-layer operates at layer 3 (routing and addressing).

**Explain the concept of port numbers and their significance in network communication.**
Port numbers identify specific applications or services running on a host, allowing multiplexing of communications.

### Secure Web & Remote Access Protocols

**What is the difference between SSL and TLS, and which one is actually used today?**
TLS is the modern successor; SSL is deprecated and insecure.

**How the TLS handshake works when visiting a secure website?**
Client and server negotiate encryption algorithms, authenticate via certificates, and establish session keys before data transfer.

**What problem did SSH solve that older protocols like Telnet couldn't handle?**
SSH provides encrypted remote shell access, while Telnet transmits all data (including credentials) in plaintext.

**How does SSH authentication with public keys work?**
The client proves identity using a private key without transmitting it, while the server verifies against a stored public key.

**Differentiate between secure protocols like HTTPS, SFTP and their insecure counterparts HTTP, FTP.**
Secure versions encrypt data in transit; insecure versions transmit plaintext vulnerable to interception.

**Explain why HTTPS is mandatory for user trust, data protection, and modern web features.**
It prevents man-in-the-middle attacks, protects sensitive data, and is required by browsers for mixed content handling.

### Network Layer & VPN Protocols

**What is the difference between Transport Mode and Tunnel Mode in IPSec, and which is used for VPNs?**
Transport mode encrypts only payload; tunnel mode encrypts entire packet—tunnel mode is used for VPNs.

**What is the difference between the AH (Authentication Header) and ESP (Encapsulating Security Payload) protocols in IPSec?**
AH provides authentication only; ESP provides both encryption and authentication.

**Why should PPTP never be used for security-sensitive tasks.**
It has known cryptographic weaknesses and vulnerabilities including MSCHAPv2 cracking.

**What makes the modern WireGuard protocol faster and more efficient than traditional VPN protocols like OpenVPN.**
Simpler codebase, modern cryptography (ChaCha20, Curve25519), and stateless design reduce overhead.

### Common Protocol Auditing & Risk Assessment

**Explain the purpose of the Network File System (NFS) protocol and how misconfigurations can lead to exposed shares.**
NFS enables file sharing across networks; improper access controls expose sensitive directories to unauthorized users.

**Describe how the SMTP commands VRFY and EXPN can be exploited for user enumeration on a mail server.**
These commands reveal valid email addresses/usernames, enabling targeted phishing attacks.

**Explain the purpose of SNMP and the security risks associated with unencrypted data and default community strings.**
SNMP monitors devices but defaults allow attackers to read/write device configurations with minimal effort.

### System Hardening & Vulnerability Management

**Explain the importance of keeping network protocols and server configurations up-to-date and patched.**
Unpatched systems contain known vulnerabilities exploitable by attackers with published exploits.

**Explain the need for setting up basic firewall rules (like using iptables) to control network access.**
Firewalls filter unauthorized traffic and limit attack surface by blocking unnecessary ports.

**Identify common SSH configuration weaknesses that require hardening (permitting root login, password authentication).**
Disabling root login, password authentication, and enforcing key-based auth reduces brute-force and privilege escalation risks.

---

## Passive Reconnaissance

**What can we learn about a Server?**
We can discover its open ports, running services, OS fingerprint, and potential vulnerabilities.

**What is a DNS server?**
It is a specialized server that translates human-readable domain names into machine-readable IP addresses.

**What happens when we type www.holbertonschool.com and press ENTER?**
Your browser queries a DNS server to resolve the domain to an IP address, then establishes a TCP connection to retrieve and render the website.

**How can we find the owner information for a domain name?**
You can query public WHOIS databases or use tools like whois to retrieve registration details.

**What is dig?**
dig (Domain Information Groper) is a flexible command-line tool used for querying DNS servers and analyzing records.

**What is nslookup?**
nslookup is a network administration command-line program used to query the Domain Name System (DNS) to obtain domain name or IP address mapping.

**What are the different types of DNS RECORDS?**
Common types include A (IPv4), AAAA (IPv6), CNAME (alias), MX (mail exchange), TXT (text/verification), NS (nameserver), and SOA (start of authority).

**What is DNS Dumpster?**
DNS Dumpster is a free online reconnaissance tool that allows users to scan a domain for DNS records and map its infrastructure.

**What is Shodan.io?**
Shodan is a search engine that indexes Internet-connected devices, allowing users to find specific servers, IoT devices, and open ports by banner information.

**How can we find subdomains?**
Methods include brute-forcing with wordlists, checking certificate transparency logs, scraping search engines, and using specialized enumeration tools.

**What is subfinder?**
subfinder is a fast, passive subdomain discovery tool that gathers results from various online sources without directly interacting with the target.

**What is the difference between Active reconnaissance and Passive reconnaissance?**
Active reconnaissance involves directly interacting with the target system to gather data, while passive reconnaissance collects information from publicly available sources without touching the target.

---

## Active Reconnaissance

**What is active reconnaissance?**
Active reconnaissance is a cybersecurity phase involving direct interaction with a target system (like port scanning or sending requests) to gather detailed, real-time intelligence that often leaves detectable traces.

**Why is active reconnaissance important for cyber security?**
It provides precise, up-to-date data on open services and vulnerabilities, enabling both attackers to find entry points and defenders to validate their external attack surface and patch critical gaps.

**How can Wappalyzer be used for active reconnaissance?**
Wappalyzer performs active scanning by analyzing HTTP headers and HTML source code of web pages to fingerprint and identify the specific technology stack, CMS, and software versions in use.

**What is DNS enumeration?**
DNS enumeration is the process of querying Domain Name System records to map out network infrastructure, discover subdomains, and identify associated IP addresses and mail servers.

**How to enumerate SMTPs using command-line tools?**
You can enumerate SMTP users by running commands like telnet [target] 25 followed by VRFY [username] or EXPN [list] to verify if specific accounts exist on the mail server.

**How should we perform OS fingerprinting?**
OS fingerprinting is best performed using active tools like Nmap with flags such as -O to analyze TCP/IP stack responses, or passive methods that inspect packet characteristics without direct probing.

**What is sqlmap? How to use it?**
SQLmap is an automated penetration testing tool for detecting and exploiting SQL injection flaws; you typically use it by running a command like sqlmap -u "http://target.com/page?id=1" to test for vulnerabilities.

---

## Nmap Live Host Discovery

**What is Nmap?**
Network Scanner used for discovery and security auditing of networks.

**How to use Nmap?**
Run nmap [options] [target] in terminal/command line.

**How does Nmap scan work?**
Sends packets to targets and analyzes responses to map network characteristics.

**What is Subnetworks?**
Networks divided into smaller segments using subnet masks for better organization and security.

**How to enumerate Targets?**
Use ping scans (-sn), ARP scans, or port scans to discover live hosts.

**What is ARP Scan?**
Sends ARP requests to local network devices to identify active IP-MAC mappings.

**What is ICMP Echo Scan?**
Sends ICMP echo request (ping) packets to check if hosts respond.

**What is ICMP Timestamp Scan?**
Sends ICMP timestamp requests to gather timing information from hosts.

**What is ICMP Address Mask Scan?**
Queries hosts for their netmask/subnet configuration via ICMP.

**What is TCP SYN Ping Scan?**
Sends SYN packets to ports; response indicates live hosts without completing handshakes.

**What is TCP ACK Ping Scan?**
Uses ACK packets to probe firewall rules and determine host status.

**What is UDP Ping Scan?**
Sends UDP packets to closed/filtered ports to detect live systems.

**What can Nmap detect?**
Live hosts, open ports, running services, OS versions, vulnerabilities, and firewall configurations.

**How to scan an IP address with Nmap?**
Simply type nmap 192.168.1.1 replacing with target IP.

**How to check ports with Nmap?**
Use -p [port] flag like nmap -p 80,443 192.168.1.1.

---

## Python for Cybersecurity

**What is the correct way to write a Python script with proper syntax?**
Use valid indentation, proper keywords, and end statements with newlines or semicolons.

**What are variables, data types, and operators used for in Python?**
They store data, define data structures, and perform logical or arithmetic operations.

**What conditions would you use to implement if, elif, and else statements?**
Use if for primary checks, elif for additional conditions, and else for fallback cases.

**What is the difference between a for loop and a while loop, and when do you use each?**
Use for for iterating over sequences and while for repeating until a condition changes.

**What is a function in Python, and how do you define and call it with parameters and return values?**
A reusable block defined with def that accepts inputs (parameters) and sends back results (return).

**What is the socket module used for, and how do you import and use it in a script?**
It handles network communication; import with import socket and create connections via socket.socket().

**What are Python's built-in functions like input(), print(), len(), and open() used for?**
They handle user input, output, length calculation, and file access respectively.

**What do string methods such as .strip(), .split(), and .format() allow you to do?**
They remove whitespace, divide strings into lists, and insert values into templates.

**What operations can you perform on Python lists?**
Append, extend, remove, slice, sort, and iterate over list elements.

**What command do you use to install Python packages using pip?**
Run pip install package_name in the terminal.

**What steps are needed to import and use external modules such as dnspython, requests, or beautifulsoup4?**
Install via pip, then use import module_name at the top of your script.

**What should you look for when reading and understanding Python library documentation?**
Look for usage examples, parameter descriptions, return values, and installation instructions.

**What is the proper way to use third-party APIs effectively in Python scripts?**
Authenticate properly, handle errors, respect rate limits, and parse responses correctly.

**What methods can you use to read text files using open() and context managers?**
Use with open('file.txt') as f: followed by .read() or .readline().

**What are the correct techniques to write data to files in Python?**
Open files in write ('w') or append ('a') mode and use .write() or .writelines().

**What is the right way to parse file content line by line?**
Iterate over the file object directly inside a with block.

**What are the file modes ('r', 'w', 'a'), and what is each one used for?**
'r' reads, 'w' overwrites/writes, and 'a' appends to a file.

**How do you resolve a domain to an IP address in Python?**
Use socket.gethostbyname('domain.com').

**What is socket.gethostbyname() used for?**
It converts a hostname string into its corresponding IP address.

**What library do you use for advanced DNS queries?**
Use dnspython for resolving various DNS record types beyond basic IP mapping.

**How do you make an HTTP GET request in Python?**
Use requests.get('url') from the requests library.

**What library do you use for HTTP requests in Python?**
The requests library is the standard choice.

**How do you access response headers in Python?**
Access them via response.headers['Header-Name'] after making a request.

**How do you check if a port is open in Python?**
Attempt a connection with socket.connect_ex((ip, port)) and check for 0.

**What does socket.connect_ex() return for an open port?**
It returns 0 if the port is open and accessible.

**What library is used to parse HTML in Python?**
BeautifulSoup from the bs4 package is commonly used.

**What is BeautifulSoup used for?**
It parses HTML/XML documents to extract and navigate data easily.

**What does .prettify() do?**
It formats the parsed HTML string with proper indentation for readability.

**What is web scraping?**
Extracting data from websites automatically using code.

**What is web crawling?**
Systematically browsing the web to index pages or gather links recursively.

**What is recursion and how is it used in web crawling?**
Recursion is a function calling itself; in crawling, it follows links repeatedly to explore sites.

### Python for Cybersecurity - Packet Capture

**What is packet capture and why is it important?**
Intercepting and logging network traffic for troubleshooting, security analysis, and monitoring.

**How does Wireshark display and dissect network packets?**
It decodes each packet's protocols layer by layer, showing headers, flags, and payloads in a structured tree view.

**What is the difference between capture filters and display filters?**
Capture filters (BPF syntax) discard unwanted packets during collection; display filters filter visibility after capture without losing data.

**How do you follow TCP streams in Wireshark?**
Right-click a packet → Follow → TCP Stream to reconstruct the full conversation between hosts.

**What is tcpdump and when should you use it over Wireshark?**
A CLI packet analyzer ideal for headless servers, remote capture, or scripted automation where a GUI isn't available.

**How do you construct effective tcpdump filter expressions?**
Use BPF syntax combining primitives like host, port, proto, and logical operators (and, or, not).

**What are common indicators of network anomalies?**
Unusual traffic volumes, unexpected ports/protocols, repeated connection attempts, and abnormal DNS lookups.

**How can you identify unauthorized connections in packet captures?**
Look for traffic to unknown IPs/domains, unexpected ports, odd communication times, or unrecognized protocols.

**What tools does Wireshark provide for traffic statistics?**
Conversations, Endpoints, Protocol Hierarchy, IO Graphs, and Flow Graphs under the Statistics menu.

**How do you analyze DNS queries in network traffic?**
Filter for DNS protocol (udp.port == 53), examine query names, response codes, and lookup patterns for suspicious activity.

**What are best practices for capturing network traffic?**
Capture at the right point, use capture filters to reduce noise, save to disk for offline analysis, and protect sensitive data.

**How does encryption affect traffic analysis?**
It hides payload content, forcing analysts to rely on metadata like flow patterns, timing, SNI, and volume rather than packet inspection.

---

## OWASP Top 10

**What is the OWASP Top 10?**
A standard awareness document listing the ten most critical web application security risks, updated periodically by the OWASP community.

**Why is injection dangerous?**
It allows attackers to send malicious data to an interpreter, potentially executing unintended commands or accessing unauthorized data.

**How does XSS affect web applications?**
It lets attackers inject client-side scripts into pages viewed by other users, enabling session hijacking, defacement, or credential theft.

**What is the risk of broken authentication?**
It allows attackers to compromise passwords, keys, or session tokens to assume other users' identities.

**Can you explain sensitive data exposure?**
It occurs when applications fail to adequately protect sensitive data (like credentials or PII), exposing it to unauthorized access through weak encryption or missing controls.

**Describe a security misconfiguration.**
Any insecure default setting, incomplete setup, open cloud storage, or unnecessary features left enabled—like default admin accounts or verbose error messages.

**What is XML External Entity (XXE)?**
An attack exploiting poorly configured XML parsers to disclose internal files, execute server-side requests, or cause denial of service.

**How do broken access controls impact security?**
They let users act outside their intended permissions, accessing data or functions they shouldn't—often the most prevalent and impactful flaw.

**What are common web application security flaws?**
Injection, broken authentication, XSS, broken access controls, misconfigurations, insecure deserialization, and vulnerable components rank among the most common.

**How to prevent Insecure Deserialization?**
Implement integrity checks (like digital signatures), enforce strict type constraints, and avoid deserializing data from untrusted sources entirely.

**What is the use of security logging and monitoring?**
Detecting, responding to, and investigating breaches by recording suspicious activity and alerting on anomalies in real time.

**Explain the risks of using components with known vulnerabilities.**
Attackers can exploit known CVEs in libraries, frameworks, or dependencies to compromise the application without crafting new exploits.

**How can using APIs increase security risks?**
APIs expand the attack surface by exposing additional endpoints, often with inconsistent authentication, excessive data exposure, or missing rate limiting.

**Understand SSRF and modern API-related risks.**
SSRF lets attackers coerce a server into making requests to unintended internal or external resources, often bypassing firewalls to access internal services.

**Explain the importance of Security Logging and Monitoring.**
Without it, breaches go undetected for extended periods—logging provides forensic evidence and monitoring enables rapid incident response.

**Identify risks from Vulnerable and Outdated Components.**
Outdated libraries may contain unpatched CVEs, lack vendor support, or introduce supply chain compromises that attackers actively target.

**Analyze common web application security flaws.**
Most stem from insufficient input validation, poor access control enforcement, weak authentication mechanisms, and failure to keep dependencies updated.

**Understand how modern APIs expand the attack surface.**
APIs introduce new endpoints with varying auth models, expose underlying business logic and data structures, and often inherit backend trust that attackers can abuse.

---

## BurpSuite - Fundamentals

**What is Burp Suite?**
A comprehensive integrated platform for performing security testing of web applications, developed by PortSwigger.

**How do you set up a proxy in Burp Suite?**
Configure your browser or system proxy settings to route traffic through 127.0.0.1 on port 8080 (default) and install Burp's CA certificate to intercept HTTPS.

**What are Burp Suite's main components?**
Proxy, Repeater, Intruder, Scanner (Pro only), Decoder, Comparer, and Extender, each serving distinct roles in interception, manipulation, automation, and analysis.

**How does Spider work in Burp Suite?**
It crawls the target website automatically to discover content, functionality, and hidden parameters by following links and parsing forms.

**What is the purpose of Repeater in Burp Suite?**
To manually modify and resend individual HTTP requests repeatedly while observing how the server responds to different payloads.

**How can Intruder be used for attacks?**
It automates customized attacks like fuzzing, brute-forcing, or credential stuffing using payload lists, position markers, and grep-matching rules.

**What is Burp Scanner and when to use it?**
An automated vulnerability scanning tool (available in Pro) that identifies issues like SQLi, XSS, and misconfigurations during active assessments.

**How to interpret results from Burp Suite?**
Review findings categorized by severity, examine request/response details, validate false positives manually, and prioritize based on exploitability and impact.

**What are some common issues that Burp Suite can identify?**
Injection flaws (SQLi, command injection), XSS, broken authentication, insecure direct object references, security misconfigurations, and vulnerable components.

**How do you configure Burp Suite for HTTPS traffic?**
Enable SSL/TLS in Proxy settings, navigate to any HTTPS site using the Burp-configured browser, and install Burp's Certificate Authority to decrypt encrypted traffic.

---

## Content Discovery

**What is content discovery?**
The process of identifying hidden or undocumented web resources, endpoints, directories, and files that aren't linked from the main site navigation.

**Why is content discovery important?**
It reveals attack surface areas attackers could exploit—often containing unpatched admin panels, backup files, or misconfigured services missed during standard audits.

**How does directory bruteforcing work?**
It systematically tests a wordlist of common directory/file names against a target server, checking HTTP response codes to identify existing resources.

**What is Gobuster and how is it used?**
A fast command-line tool for brute-forcing directories, subdomains, and virtual hosts by iterating through wordlists and analyzing server responses.

**Explain the use of Burp Suite in content discovery.**
Burp's Spider and passive scanning features automatically map website structure, while extensions like "Site Map" and Active Scan help uncover hidden paths.

**How does OWASP ZAP assist in content discovery?**
Its automated spider crawls sites to find all accessible URLs, and active scan modules probe for hidden content using configurable wordlists and heuristics.

**What are wordlists and how are they used in content discovery?**
Precompiled lists of common filenames/directories (like /admin, /backup) used to systematically test which paths exist on a target server.

**Describe the purpose of tools like DirBuster.**
Multi-threaded directory/file enumeration tools designed to efficiently brute-force web paths by testing thousands of wordlist entries against targets.

**What are hidden directories and files in web security?**
Resources not publicly linked but still accessible via direct URL—often admin interfaces, config backups, or developer files exposed through poor access controls.

**Explain fuzzing in the context of web security.**
Automated input manipulation where testers send unexpected/payload data to parameters to trigger errors, reveal vulnerabilities, or discover undocumented endpoints.

---

## Understanding Vulnerabilities

**What is a cybersecurity vulnerability?**
A weakness or flaw in a system, process, or design that can be exploited to compromise security.

**What are the different types of vulnerabilities (software, hardware, network)?**
Software bugs/implementation flaws, hardware firmware/physical weaknesses, and misconfigured network protocols or services, plus the human factor.

**How do vulnerabilities lead to security breaches in technology-driven organizations?**
Attackers identify and exploit weaknesses to gain unauthorized access, exfiltrate data, or disrupt operations.

**What is the difference between vulnerabilities, threats, and risks?**
A vulnerability is a weakness, a threat is a potential attacker or event exploiting it, and risk is the likelihood/consequence of that exploitation.

**What are Common Vulnerabilities and Exposures (CVE)?**
A standardized database of publicly known security vulnerabilities with unique identifiers for consistent tracking and communication.

**What is vulnerability management?**
The ongoing process of identifying, assessing, prioritizing, remediating, and monitoring security vulnerabilities across an organization.

**What is responsible disclosure in the context of vulnerabilities?**
Reported finding vulnerabilities privately to vendors first, allowing time for fixes before public disclosure.

**What are common tools used for vulnerability scanning?**
Nessus, OpenVAS, Qualys, Burp Suite, Nmap, and Microsoft Baseline Security Analyzer.

**Why is vulnerability management essential for a company's cybersecurity posture?**
It proactively reduces attack surface by systematically addressing weaknesses before adversaries can exploit them.

---

## CVE, CWE and NVD

**What are CVEs (Common Vulnerabilities and Exposures), and how do they help in identifying and sharing information about publicly known cybersecurity vulnerabilities?**
CVEs are standardized identifiers for publicly known security vulnerabilities that enable consistent tracking, communication, and reference across the global cybersecurity community.

**What is the structure of a CVE identifier (e.g., CVE-2024-1234), and what is the significance of each part?**
Format breaks down as: "CVE" prefix, year discovered/assigned (2024), and sequential ID number (1234) within that year's issuance.

**What role do CVE Numbering Authorities (CNAs) play in the CVE assignment process, and what are the criteria for becoming a CNA?**
CNAs are trusted organizations authorized to assign CVE IDs; they must demonstrate expertise in vulnerability handling and agree to follow MITRE's policies and procedures.

**How are vulnerabilities reported, reviewed, and assigned a CVE identifier through the CVE entry process?**
Reporters submit findings to relevant CNAs or MITRE directly, which review validity, uniqueness, and public disclosure readiness before issuing CVE assignments.

**How can you use the CVE database to search for and retrieve information about specific vulnerabilities?**
Use cve.mitre.org with keyword/CVE-ID search filters by year, product, vendor, or severity ratings for targeted lookups.

**What are CWEs (Common Weakness Enumeration), and how do they help in identifying common software weaknesses that can lead to vulnerabilities?**
CWEs catalog software design/code flaws that could become exploitable vulnerabilities, providing a taxonomy for secure development and testing.

**What are the different categories, types, and hierarchical structures of CWEs?**
Organized as tree hierarchy from root weaknesses (like CWE-79 XSS) through subclasses showing specific instances and relationships between weakness types.

**How are CWEs related to CVEs, and how do they describe the types of weaknesses that lead to vulnerabilities?**
Multiple CVE entries often map back to single CWEs—CWE describes the root cause flaw type while CVE documents specific instance manifestations.

**What are some common mitigation techniques and best practices for addressing weaknesses identified by CWEs?**
Input validation, output encoding, parameterized queries, proper memory management, code review, static analysis tools, and secure coding training.

**How can weaknesses be prioritized based on their severity, exploitability, and potential impact using CWE scoring?**
CWE itself lacks intrinsic scoring but teams prioritize based on exploit likelihood, asset criticality, available patches, and associated CVE CVSS scores when mapped.

**What is the role of the NVD (National Vulnerability Database) in the cybersecurity ecosystem, and how does it support vulnerability management?**
NVD serves as US-government maintained repository aggregating CVE data with enriched details like CVSS scores, affected configurations, and remediation guidance.

**What types of data feeds are provided by the NVD, including vulnerability metrics, configurations, and impact scores?**
JSON/XML feeds containing CVE details, CVSS v2/v3 scores, CPE configurations, affected products, references, and patch availability status updates.

**How can you use the CVSS (Common Vulnerability Scoring System) to assess the severity of vulnerabilities listed in the NVD?**
CVSS provides base/temporal/environmental metrics (attack vector, complexity, privileges required, impact) generating numeric scores 0.0-10.0 for severity ranking.

**How can you effectively search, filter, and retrieve vulnerability information from the NVD?**
Apply nvd.nist.gov filters by CVE-ID, keywords, publish date ranges, CVSS score thresholds, CPE product names, or vendor/platform combinations.

**How can NVD data be integrated with security tools and platforms for automated vulnerability management?**
Pull API feeds into SIEMs, scanners, ticketing systems, and SOAR platforms to auto-correlate discoveries with known vulnerability data for prioritization workflows.

---

## File Upload Vulnerabilities

**What is an unrestricted file upload?**
It is a web vulnerability where an application accepts uploaded files without adequately validating their content, type, or structure.

**Why are file uploads a security risk?**
They allow attackers to bypass application controls by uploading malicious code that the server may execute, leading to full system compromise.

**How can file upload forms be exploited?**
Attackers trick servers into storing and executing malware, web shells, or scripts by spoofing headers, bypassing client checks, or exploiting extension weaknesses.

**What is a web shell?**
A web shell is a malicious script uploaded to a server that provides attackers with a remote command line interface to control the compromised system.

**How do MIME types relate to upload security?**
MIME types indicate file formats in HTTP headers, but relying solely on them is insecure because they can be easily forged by attackers.

**What is content-type spoofing?**
This is the technique of manipulating the Content-Type header in an upload request to make a malicious file appear as a safe image or document.

**How can server-side validation mitigate risks?**
Server-side validation enforces strict checks on file magic numbers, extensions, and content before storage, effectively preventing execution of unauthorized payloads.

**What is the importance of file extension filtering?**
Whitelisting allowed extensions ensures that only expected file types (like .jpg) can be saved, blocking executable scripts (like .php or .exe).

**How can client-side checks be bypassed?**
Client-side validations run in the user's browser and can be easily circumvented by modifying requests with proxy tools like Burp Suite or curl.

**What are some secure file upload practices?**
Best practices include whitelisting extensions, verifying file magic numbers, renaming files upon upload, storing outside the web root, and disabling script execution in upload folders.

**How does file size limitation help security?**
Limiting file sizes prevents denial-of-service attacks caused by massive uploads filling disk space and slows down brute-force attempts to upload large payloads.

**What are the risks of storing files on the same domain?**
Storing uploads on the same domain allows malicious scripts to potentially access cookies, local storage, or perform Same Origin Policy bypasses against your legitimate site.

**How do file permissions affect upload security?**
Improper permissions (like 777) on upload directories grant unintended read/write/execute rights, enabling attackers to modify or run the malicious files they placed there.

**Why should upload directories not be executable?**
Disabling execution permissions ensures that even if a malicious script is successfully uploaded, the web server treats it as data rather than running it as code.

---

## Threat Modeling Fundamentals

**Explain the CIA Triad and why it matters in cybersecurity**
The CIA Triad consists of Confidentiality, Integrity, and Availability—three core principles that guide security controls to protect information assets.

**Distinguish between assets, threats, vulnerabilities, and risks**
Assets are valuable resources, threats are potential danger sources, vulnerabilities are weaknesses, and risks represent the probability and impact of threats exploiting vulnerabilities.

**Identify trust boundaries in system architectures**
Trust boundaries mark where data transitions between different levels of trust, such as between untrusted networks and protected internal systems.

**Calculate basic risk scores using industry-standard methods**
Basic risk scores typically multiply likelihood and impact values (e.g., Risk = Likelihood × Impact) on standardized scales like 1-5 or 1-10.

**Apply STRIDE methodology to analyze system components**
STRIDE categorizes threats into Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, and Elevation of Privilege across system components.

**Use DREAD scoring to prioritize security threats**
DREAD rates threats by Damage Potential, Reproducibility, Exploitability, Affected Users, and Discoverability, each scored 1-10 for an overall risk rating.

**Understand PASTA process fundamentals for risk-centric threat analysis**
PASTA (Process for Attack Simulation and Threat Analysis) is a seven-stage framework aligning business objectives with technical requirements through attack simulation.

**Create a prioritized threat list for remediation**
Prioritize threats based on risk scores, considering business impact, exploit likelihood, available mitigations, and regulatory compliance requirements.

**Propose specific, actionable mitigations for identified threats**
Implement layered controls including input validation, authentication hardening, encryption, least privilege access, and regular security testing.

**Follow a structured steps threat modeling process**
A structured approach includes defining scope, identifying assets, diagramming architecture, identifying threats, analyzing impacts, and documenting mitigations with ownership.

---

## Security Policy Analysis

**What is a security policy and why is it important?**
A security policy is a formal document defining an organization's approach to protecting information assets, establishing expectations and requirements for security posture.

**What are the different types of security policies?**
Common types include organizational, issue-specific, and system-specific policies covering areas like access control, data handling, acceptable use, and incident response.

**What is the difference between a policy, standard, procedure, and guideline?**
Policies define mandatory rules, standards set specific technical requirements, procedures outline step-by-step implementation, and guidelines offer recommended best practices.

**How do security policies align with business objectives?**
Policies balance risk management with operational needs by translating business goals into security requirements that enable rather than hinder productivity.

**What are the essential elements of a security policy?**
Key elements include purpose, scope, roles and responsibilities, compliance requirements, enforcement mechanisms, review cycles, and exception processes.

**How do you define scope and applicability?**
Scope specifies who must comply (employees, contractors, systems), which assets are covered, and where boundaries apply across organizational environments.

**What is policy enforcement and compliance?**
Enforcement ensures adherence through monitoring, audits, and consequences while compliance validates alignment with internal policies and external regulations.

**How often should policies be reviewed and updated?**
Policies should undergo formal review at least annually or whenever significant changes occur to technology, operations, threats, or regulatory requirements.

**What is an Acceptable Use Policy (AUP)?**
An AUP defines appropriate employee behavior when using organizational IT resources, including internet, email, devices, and network access restrictions.

**What is an Access Control Policy?**
This policy governs how authentication, authorization, and accounting mechanisms control who can access specific systems, data, and facilities within the organization.

**What is an Incident Response Policy?**
An Incident Response Policy establishes procedures for detecting, reporting, containing, investigating, and recovering from security incidents and breaches.

**What is a Data Classification Policy?**
This policy categorizes information based on sensitivity levels (public, internal, confidential, restricted) to determine appropriate handling and protection measures.

**What is a Password Policy?**
A Password Policy mandates complexity requirements, rotation schedules, storage rules, and multi-factor authentication to protect authentication credentials.

**How do policies support regulatory compliance (GDPR, HIPAA, PCI-DSS)?**
Policies translate legal requirements into internal controls ensuring data protection, audit trails, breach notification, and documented security practices for regulators.

**What is a policy exception process?**
Exception processes allow temporary deviations from policies when justified, requiring documented approval, compensating controls, risk acceptance, and defined expiration dates.

**How do you measure policy effectiveness?**
Effectiveness is measured through compliance audits, incident frequency trends, user awareness metrics, violation rates, and feedback from security control testing.

---

## Exploring Career Pathways in Cybersecurity

### Career Pathways Understanding

**What are the main career tracks in penetration testing and security?**
The primary tracks include offensive security (pentesting/red teaming), defensive security (blue team/SOC), GRC (governance, risk, compliance), and incident response.

**How do offensive security roles differ from defensive security roles?**
Offensive roles simulate attacks to find weaknesses, while defensive roles monitor, detect, and respond to actual threats.

**What is the career progression from junior to senior positions?**
Progression typically flows from Junior Analyst → Security Engineer/Specialist → Senior Engineer → Principal Architect → Leadership/CISO.

**What are the emerging specializations in cybersecurity?**
Cloud security, AI/ML security, IoT/embedded systems, automotive security, and OT/ICS security are among the fastest-growing specializations.

### Role-Specific Knowledge

**What does a penetration tester do on a day-to-day basis?**
They conduct authorized security assessments, test systems for vulnerabilities, document findings, write reports, and recommend remediation strategies.

**What are the responsibilities of a red team operator vs. a vulnerability assessor?**
Red team operators simulate realistic multi-stage attacks while vulnerability assessors systematically scan and catalog known vulnerabilities.

**How does a security consultant role differ from an in-house security engineer?**
Consultants serve multiple clients across diverse environments while in-house engineers develop deep expertise protecting one organization continuously.

**What is the role of a bug bounty hunter and how viable is it as a career?**
Bug bounty hunters find vulnerabilities in exchange for bounties; viable as supplemental income but inconsistent full-time earnings without significant reputation.

### Skills & Qualifications

**What technical skills are essential for entry-level positions?**
Network fundamentals, Linux/Windows administration, basic scripting, and familiarity with security tools like Wireshark and Nmap.

**What programming languages are most valuable for security professionals?**
Python, Bash, PowerShell, and SQL are most valuable, with C/C++ and JavaScript being beneficial for specific specializations.

**How important are certifications in the hiring process?**
Certifications help pass resume filters and validate baseline knowledge, though practical experience typically carries more weight once past initial screening.

**What soft skills are critical for advancement in security careers?**
Clear communication, analytical thinking, ethical judgment, collaboration, and the ability to explain technical risks to non-technical stakeholders.

### Certifications & Education

**What is the difference between OSCP, CEH, and GPEN certifications?**
OSCP is highly respected for hands-on exploitation skills, CEH covers broad theoretical concepts, and GPEN focuses on structured penetration testing methodology.

**When should you pursue certifications vs. hands-on experience?**
Pursue certifications early to gain credibility, but prioritize hands-on labs and real-world practice throughout your entire career.

**What are the most respected certifications at different career levels?**
Entry: Security+, Network+; Mid-level: OSCP, SANS/GIAC; Senior: CISSP, OSWE/OSEP depending on specialization.

**How do employers view self-taught security professionals vs. degree holders?**
Employers increasingly value demonstrated skills and portfolios equally with degrees, particularly when backed by relevant certifications and practical experience.