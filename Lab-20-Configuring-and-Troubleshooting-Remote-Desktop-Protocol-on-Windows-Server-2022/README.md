# Lab 20: Configuring and Troubleshooting Remote Desktop Protocol (RDP) on Windows Server 2022

## Overview

In this lab, I configured and tested Remote Desktop Protocol (RDP) access to a Windows Server 2022 Domain Controller virtual machine from my Windows host machine.

The objective was to remotely administer the server using RDP while gaining hands-on experience with:

- Windows Server administration
- Remote Desktop configuration
- Windows Defender Firewall management
- Remote access troubleshooting
- Network connectivity validation
- System administration best practices

During testing, the initial RDP connection failed because Remote Desktop was disabled on the server. After identifying the issue, I enabled Remote Desktop, verified firewall access, and successfully established a remote session from my Windows host machine.

---

## Technologies Used

- Windows Server 2022
- Windows 11 Home
- VMware Workstation
- Remote Desktop Protocol (RDP)
- Microsoft Defender Firewall
- Active Directory Domain Services (AD DS)

---

## Skills Demonstrated

- Windows Server Administration
- Remote Desktop Configuration
- Windows Defender Firewall Management
- Troubleshooting Methodology
- Network Connectivity Testing
- Remote System Administration
- Documentation and Change Management

---

## Lab Objectives

- Configure inbound firewall rules for RDP
- Understand how RDP uses TCP/UDP 3389
- Troubleshoot failed remote desktop connections
- Enable Remote Desktop on Windows Server
- Successfully connect to a server remotely
- Practice common tasks performed by Help Desk and Systems Administrators

---

## Network Environment

| Device | Purpose |
|----------|----------|
| HP Envy Laptop | Host Machine |
| Windows Server 2022 VM | Domain Controller |
| VMware Workstation | Virtualization Platform |
| RDP (TCP 3389) | Remote Access Protocol |

---

# Step 1: Configure Windows Defender Firewall for RDP

Before enabling Remote Desktop access, I created an inbound Windows Defender Firewall rule allowing RDP traffic to reach the server.

### Configuration

- Rule Type: Port
- Protocol: TCP
- Port: 3389
- Action: Allow Connection
- Profiles: Domain, Private, Public
- Rule Name: Allow Remote Connections To Server VM

### Screenshot

![Firewall Rule](screenshots/firewall-allow.png)

### Purpose

This rule allows inbound Remote Desktop traffic to reach the Windows Server virtual machine.

RDP primarily uses:

| Protocol | Port |
|-----------|--------|
| TCP | 3389 |
| UDP | 3389 |

TCP 3389 is required for RDP functionality, while UDP 3389 improves performance for graphics and responsiveness.

---

# Step 2: Initial RDP Connection Attempt

After configuring the firewall rule, I attempted to connect to the Windows Server VM from my Windows host machine using Remote Desktop Connection.

The connection failed.

### Screenshot

![RDP Disabled](screenshots/rdp-disabled1.png)

### Error Observed

Remote Desktop was unable to connect to the remote computer.

Possible causes included:

- Remote Desktop disabled
- Firewall restrictions
- Network connectivity issues
- Incorrect hostname or IP address

---

# Step 3: Investigate Server Configuration

I logged directly into the Windows Server virtual machine through VMware and reviewed the server configuration.

Navigation Path:

```text
Server Manager
→ Local Server
→ Remote Desktop
```

Upon inspection, I discovered that Remote Desktop was disabled.

To resolve the issue:

1. Opened System Properties
2. Selected the Remote tab
3. Enabled:

```text
Allow remote connections to this computer
```

4. Applied the configuration
5. Confirmed Remote Desktop status changed to Enabled

### Screenshot

![Remote Desktop Enabled](screenshots/rdp-enabled-server.png)

### Result

The server was now configured to accept inbound Remote Desktop connections.

---

# Step 4: Successful Remote Connection

After enabling Remote Desktop, I initiated a new connection from the host machine.

This time the connection was successful and I was presented with the Windows Server login screen.

### Screenshot

![Successful RDP Connection](screenshots/rdp-enabled-connection.png)

### Verification

The successful login confirmed:

- RDP service functioning properly
- Remote Desktop enabled
- Firewall rule configured correctly
- Network communication operational
- Remote administration available

---

# Troubleshooting Methodology

## 1. Identify the Problem

Remote Desktop connection failed.

## 2. Establish a Theory

Potential causes:

- RDP disabled
- Firewall blocking traffic
- Incorrect hostname
- Network issue

## 3. Test the Theory

Reviewed Windows Server Remote Desktop settings.

## 4. Establish a Plan

Enable Remote Desktop and retest connectivity.

## 5. Verify Functionality

Successfully connected to the server.

## 6. Document Findings

Recorded screenshots and documented remediation steps.

---

# Understanding Remote Desktop Protocol (RDP)

Remote Desktop Protocol (RDP) is Microsoft's remote administration protocol used to access Windows systems across a network.

### Common Enterprise Use Cases

- Remote server administration
- Help Desk support
- Desktop troubleshooting
- Application management
- User support
- Infrastructure operations

### Why RDP Matters

RDP is one of the most widely used remote management technologies in enterprise environments. Understanding how to configure, secure, and troubleshoot RDP is an important skill for:

- IT Support Specialists
- Help Desk Technicians
- Desktop Support Technicians
- Systems Administrators
- Infrastructure Engineers

---

# Key Takeaways

- Windows Defender Firewall must allow RDP traffic.
- RDP uses TCP 3389 and can also utilize UDP 3389.
- Remote Desktop must be explicitly enabled before connections are accepted.
- Following a structured troubleshooting process accelerates issue resolution.
- Remote management is a core skill for IT professionals.

---

# Outcome

Successfully configured Windows Defender Firewall, enabled Remote Desktop on a Windows Server 2022 Domain Controller, and established a remote connection from a Windows host machine.

This lab demonstrates practical experience with:

- Windows Server Administration
- Remote Access Configuration
- Windows Defender Firewall
- Troubleshooting Methodology
- Enterprise Remote Management

These are foundational skills commonly used in Help Desk, Desktop Support, Systems Administration, and IT Operations roles.
