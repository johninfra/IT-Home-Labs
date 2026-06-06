# Lab 18: Splunk SIEM Security Monitoring & Alerting Platform

## Overview

In this lab, I deployed and configured a fully functional Security Information and Event Management (SIEM) platform using Splunk Enterprise on Kali Linux. Starting from a problematic installation, I repaired Linux file and Journald permissions, configured log ingestion, developed security dashboards, created real time alerts, and successfully detected reconnaissance activity.

This project simulates Security Operations Center (SOC) analyst responsibilities by collecting, analyzing, visualizing, and alerting on security relevant events generated throughout the environment.

---

## Security Dashboard

![SOC Security Dashboard](screenshots/security-dashboard.png)

The dashboard provides visibility into:

- Authentication Events by Service
- Top Targeted Ports
- Top Attacker Source IP Addresses
- Security Metrics Visualization
- Threat Monitoring Activity

---

## Objectives

- Deploy Splunk Enterprise SIEM
- Configure Linux log ingestion
- Troubleshoot and repair Splunk installation issues
- Analyze authentication events
- Monitor network activity
- Build SOC style dashboards
- Create real time security alerts
- Detect reconnaissance activity
- Investigate attacker source IPs
- Develop SIEM administration skills

---

## Technologies Used

| Category | Technologies |
|-----------|-------------|
| SIEM Platform | Splunk Enterprise |
| Operating System | Kali Linux |
| Log Sources | Linux Journald |
| Monitoring | Authentication Events |
| Network Analysis | Nmap |
| Detection | Real Time Alerts |
| Visualization | Splunk Dashboards |
| Query Language | SPL |

---

## Environment

### Host System

- Kali Linux
- Splunk Enterprise 10.x
- Local SIEM Environment

### Data Sources

- Linux Journald Logs
- Authentication Events
- Firewall Activity
- Network Activity
- Reconnaissance Events

---

# Step 1: Splunk Deployment & Troubleshooting

The installation process began with a non functional Splunk environment that required troubleshooting before security monitoring could be performed.

### Tasks Completed

- Mounted Linux file systems
- Corrected file ownership issues
- Repaired Journald permissions
- Validated log ingestion
- Verified Splunk service operation
- Configured HTTPS access
- Confirmed data indexing functionality

### Skills Demonstrated

- Linux Administration
- SIEM Deployment
- Service Troubleshooting
- File Permissions Management
- Security Hardening

---

# Step 2: Authentication Monitoring

After log ingestion was operational, authentication related events were analyzed using Splunk Search Processing Language (SPL).

### Authentication Failure Query

```spl
index=* sourcetype=journald "authentication failure"
```

### Authentication Failure Detection

![Authentication Failure Detection](screenshots/splunk-authentication-failure.png)

### Findings

The search successfully identified failed authentication attempts recorded by Linux PAM authentication services.

Information collected included:

- Username
- Authentication Status
- Source Process
- Host Information
- Timestamp Data

### Security Relevance

Authentication failures can indicate:

- Brute force attacks
- Credential misuse
- Unauthorized access attempts
- User account compromise
- Misconfigured services

---

# Step 3: Security Dashboard Development

A custom SOC dashboard was created to provide centralized visibility into security activity.

### Dashboard Components

#### Authentication Events by Service

Displays services generating authentication activity.

#### Top Targeted Ports

Identifies ports receiving the highest volume of network activity.

#### Top Attacker Source IPs

Highlights source systems responsible for suspicious activity.

### Benefits

- Improved situational awareness
- Faster threat identification
- Centralized monitoring
- Security metrics visualization
- SOC workflow support

### Dashboard Screenshot

![SOC Security Dashboard](screenshots/security-dashboard.png)

---

# Step 4: Reconnaissance Detection

To simulate attacker behavior, an Nmap SYN scan was performed against the local host.

### Nmap Scan

```bash
nmap -sS -F localhost
```

### Results

```text
Starting Nmap 7.98

Nmap scan report for localhost (127.0.0.1)

PORT     STATE SERVICE
8000/tcp open  http-alt
```

### Security Significance

Port scanning is commonly observed during:

- Reconnaissance
- Enumeration
- Vulnerability Assessment
- Initial Attack Planning

Detecting these activities early improves defensive response capabilities.

---

# Step 5: Real Time Alert Engineering

A real time Splunk alert was configured to detect Nmap reconnaissance activity.

### Alert Configuration

| Setting | Value |
|----------|----------|
| Alert Type | Real Time |
| Trigger Mode | Per Result |
| Severity | Medium |
| Detection | Nmap Port Scan Activity |

### Triggered Alerts

![Nmap Detection Alerts](screenshots/nmap-alerts.png)

### Outcome

Immediately after performing the Nmap scan, Splunk generated multiple alerts indicating successful detection of reconnaissance activity.

This validated:

- Log Collection
- Event Correlation
- Detection Logic
- Alert Generation
- Security Monitoring

---

# SPL Queries Used

## Authentication Failures

```spl
index=* sourcetype=journald "authentication failure"
```

## Authentication Events by Service

```spl
index=* sourcetype=journald
| stats count by SYSTEMD_UNIT
| sort - count
```

## Top Targeted Ports

```spl
index=*
| stats count by DPT
| sort - count
```

## Top Attacker Source IP Addresses

```spl
index=*
| stats count by src_ip
| sort - count
```

---

# Security Concepts Demonstrated

- Security Information and Event Management (SIEM)
- Log Collection & Aggregation
- Security Monitoring
- Authentication Analysis
- Threat Detection
- Detection Engineering
- Security Analytics
- Network Reconnaissance Monitoring
- Security Alerting
- Dashboard Development
- Incident Investigation
- SOC Operations

---

# Skills Demonstrated

## Cybersecurity

- Threat Detection
- Security Monitoring
- Security Analytics
- Reconnaissance Detection
- Incident Investigation

## SIEM Administration

- Splunk Deployment
- Log Ingestion
- SPL Query Development
- Dashboard Creation
- Alert Engineering

## Linux Administration

- Journald Management
- File Permissions
- Service Troubleshooting
- System Monitoring

---

# Key Takeaways

This lab demonstrates the complete lifecycle of deploying and operating a SIEM platform in a security monitoring environment.

Major accomplishments included:

- Repairing a broken Splunk deployment
- Configuring Linux log ingestion
- Monitoring authentication activity
- Building SOC dashboards
- Creating real time alerts
- Detecting reconnaissance activity
- Investigating security events
- Developing practical SIEM administration skills

The completed environment successfully collected, analyzed, visualized, and alerted on security relevant activity, simulating real world SOC analyst workflows.

---

# Resume Bullet

Built and administered a Splunk Enterprise SIEM environment on Kali Linux, configured Linux Journald log ingestion, developed SPL based threat detection queries, created SOC security dashboards, engineered real time reconnaissance alerts, and successfully detected simulated Nmap port scanning activity through active security monitoring workflows.
