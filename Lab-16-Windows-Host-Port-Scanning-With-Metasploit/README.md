# Lab 16 - Windows Host Port Scanning with Metasploit

## Overview

In this lab, I used the Metasploit Framework on a Kali Linux virtual machine to perform TCP port scanning and service enumeration against a Windows host machine. The objective was to identify open ports, discover exposed services, and gain hands on experience using Metasploit's auxiliary scanning modules.

This exercise demonstrates practical cybersecurity skills involving reconnaissance, network enumeration, attack surface identification, and security assessment techniques commonly used by penetration testers and security analysts.

## Lab Setup

The lab environment consisted of a Kali Linux virtual machine and a Windows 11 host system connected on the same local network.

Kali Linux was used as the scanning workstation while the Windows host machine served as the target for assessment.

Environment Details:

- Attacker Machine: Kali Linux
- Target Machine: Windows 11 Host
- Virtualization Platform: VMware Workstation
- Security Tool: Metasploit Framework
- Network Type: Local Lab Network

## Tools Used

- Kali Linux
- Metasploit Framework
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
- IP Address: 192.168.1.5
- Role: Scan Target

### Network Details

- Both systems were connected to the same network segment.
- Connectivity was verified prior to scanning.
- Testing was conducted in a controlled home lab environment.

## Tasks Performed

1. Started the Kali Linux virtual machine.
2. Opened Metasploit Framework.
3. Loaded the TCP Port Scanner auxiliary module.
4. Configured the target IP address.
5. Reviewed scanner configuration options.
6. Executed a TCP port scan against the Windows host.
7. Enumerated open ports and services.
8. Analyzed discovered services.
9. Captured scan evidence.
10. Documented findings and observations.

## Commands Used

```bash
msfconsole
```

```bash
use auxiliary/scanner/portscan/tcp
```

```bash
set RHOSTS 192.168.1.5
```

```bash
show options
```

```bash
run
```

## Screenshots

### Metasploit TCP Port Scan Results

![Metasploit TCP Port Scan Results](screenshots/metasploit_scan_results.png)

## Results

The Metasploit TCP Port Scanner successfully identified multiple open ports on the Windows host system.

Open Ports Discovered:

- TCP 135 - Microsoft RPC Endpoint Mapper
- TCP 139 - NetBIOS Session Service
- TCP 445 - SMB File Sharing
- TCP 903 - VMware Authorization Service
- TCP 913 - VMware Workstation Service
- TCP 2869 - UPnP Service
- TCP 5040 - Windows Event Collector
- TCP 5357 - Web Services on Devices
- TCP 7680 - Windows Delivery Optimization

The scan completed successfully and demonstrated the ability to identify network services exposed by a Windows workstation. The discovered ports provide valuable information for security assessments and highlight potential areas requiring further investigation.

## Key Takeaways

- Learned how to use Metasploit auxiliary scanner modules.
- Gained experience performing TCP port scanning.
- Practiced identifying exposed network services.
- Improved understanding of Windows network services.
- Learned how attackers and defenders enumerate hosts.
- Developed practical reconnaissance and documentation skills.
- Reinforced the importance of reducing unnecessary exposed services.

## Skills Demonstrated

- Metasploit Framework
- Port Scanning
- Service Enumeration
- Network Reconnaissance
- Vulnerability Assessment
- Windows Security Fundamentals
- Linux Administration
- Security Analysis
- Technical Documentation
- Cybersecurity Operations

## Conclusion

This lab provided hands on experience using Metasploit Framework to perform network reconnaissance and service enumeration against a Windows host system. Through TCP port scanning, I identified multiple exposed services and gained practical experience assessing a system's attack surface.

The exercise strengthened my understanding of reconnaissance methodologies, improved my familiarity with Metasploit Framework, and demonstrated how security professionals identify potential entry points during vulnerability assessments and penetration testing engagements.
