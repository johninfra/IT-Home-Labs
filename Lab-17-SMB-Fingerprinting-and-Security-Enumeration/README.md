# Lab 17 - SMB Fingerprinting and Security Enumeration with Metasploit

## Overview

In this lab, I used the Metasploit Framework on a Kali Linux virtual machine to perform SMB fingerprinting and security enumeration against a Windows 11 host system. The objective was to identify operating system details, SMB protocol versions, encryption capabilities, and security configurations exposed through the Server Message Block (SMB) service.

This exercise demonstrates practical cybersecurity skills involving reconnaissance, service enumeration, operating system fingerprinting, and security assessment techniques commonly used by penetration testers and security analysts.

## Lab Setup

The lab environment consisted of a Kali Linux virtual machine and a Windows 11 host machine connected on the same local network.

Kali Linux was used as the assessment workstation while the Windows host served as the target system for SMB enumeration.

Environment Details:

- Attacker Machine: Kali Linux
- Target Machine: Windows 11 Host
- Virtualization Platform: VMware Workstation
- Security Tool: Metasploit Framework
- Network Type: Local Lab Network

## Tools Used

- Kali Linux
- Metasploit Framework
- SMB Protocol
- VMware Workstation
- Windows 11
- Linux Terminal

## Network Configuration

### Attacker System

- Operating System: Kali Linux
- Role: Security Assessment Workstation
- Platform: Virtual Machine

### Target System

- Operating System: Windows 11
- Hostname: JCWINDOWSLAPTOP
- Role: SMB Enumeration Target

### Network Details

- Both systems were connected to the same network segment.
- Connectivity was verified prior to testing.
- Enumeration activities were conducted in a controlled home lab environment.

## Tasks Performed

1. Started the Kali Linux virtual machine.
2. Opened Metasploit Framework.
3. Loaded the SMB version enumeration module.
4. Configured the target host IP address.
5. Executed SMB fingerprinting against the Windows host.
6. Identified the operating system version.
7. Enumerated SMB protocol versions.
8. Reviewed encryption capabilities.
9. Verified SMB signing requirements.
10. Documented findings and security observations.

## Commands Used

```bash
msfconsole
```

```bash
search smb_version
```

```bash
use auxiliary/scanner/smb/smb_version
```

```bash
set RHOSTS 192.168.1.5
```

```bash
run
```

## Screenshots

### SMB Fingerprinting Results

![SMB Fingerprinting Results](screenshots/smb_fingerprinting_results.png)

## Results

The SMB enumeration scan successfully identified the Windows host operating system, SMB protocol version, and multiple security-related configurations.

Host Information Discovered:

- Hostname: JCWINDOWSLAPTOP
- Operating System: Windows 11 Version 24H2
- Build Number: 10.0.26100

SMB Information Discovered:

- SMB Dialect: SMB 3.1.1
- Packet Signing: Required
- Encryption Support: Enabled

Encryption Capabilities Identified:

- AES-256-GCM
- AES-128-GCM

The scan revealed that the target system is running a modern and fully supported version of Windows 11 with advanced SMB security protections enabled.

## Key Takeaways

- Learned how to perform SMB fingerprinting using Metasploit.
- Gained experience identifying operating system details remotely.
- Practiced service enumeration techniques used during penetration testing.
- Improved understanding of SMB security mechanisms.
- Learned how SMB signing protects against network-based attacks.
- Developed familiarity with modern SMB encryption standards.
- Strengthened reconnaissance and documentation skills.

## Skills Demonstrated

- Metasploit Framework
- SMB Enumeration
- SMB Fingerprinting
- Operating System Identification
- Network Reconnaissance
- Security Assessment
- Service Enumeration
- Cybersecurity Documentation
- Technical Analysis
- Penetration Testing Fundamentals

## Conclusion

This lab provided hands on experience using Metasploit Framework to perform SMB fingerprinting and security enumeration against a Windows 11 host system. Through SMB reconnaissance techniques, I successfully identified the operating system version, hostname, SMB protocol version, encryption capabilities, and security configurations exposed by the target.

The assessment demonstrated how security professionals gather valuable information about target systems during the reconnaissance phase of a security engagement. The results confirmed that the Windows host was running modern SMB security features including SMB 3.1.1, mandatory packet signing, and AES-GCM encryption, significantly reducing exposure to legacy SMB attacks and common network-based threats.
