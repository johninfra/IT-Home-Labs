# Lab 19: Splunk SOC Security Monitoring Dashboard

## Overview

In this lab, I designed and deployed a Splunk Enterprise SIEM environment to collect, analyze, visualize, and monitor Windows Security Logs and Sysmon telemetry. The goal was to simulate a Security Operations Center (SOC) monitoring environment by building a centralized dashboard capable of tracking authentication activity, process creation, command execution, PowerShell activity, security events, and brute force attack indicators.

The completed dashboard analyzed over 28,000 security events and provided real-time visibility into user authentication activity, Windows process creation, and Sysmon operational logs.

---

## Technologies Used

- Splunk Enterprise
- Sysmon
- Windows Event Logs
- Windows 11
- SPL (Search Processing Language)
- Security Information and Event Management (SIEM)

---

## Skills Demonstrated

- SIEM Administration
- Security Monitoring
- Threat Detection
- Log Analysis
- Security Event Investigation
- Dashboard Development
- SPL Query Development
- Windows Security Logging
- Sysmon Monitoring
- Threat Hunting

---

## Objectives

- Deploy Splunk Enterprise
- Ingest Windows Security Logs
- Ingest Sysmon Operational Logs
- Build SOC-style security dashboards
- Monitor authentication activity
- Analyze process creation events
- Track PowerShell and command execution activity
- Create brute force login detection use cases
- Visualize security events through Splunk dashboards

---

# Dashboard Overview

The completed SOC dashboard provides centralized visibility into Windows security telemetry and Sysmon activity.

## Executive Metrics

The dashboard includes key security metrics:

- Total Events: 28,237
- Monitored Hosts: 115
- PowerShell Executions: 321
- CMD Executions: 2,237
- Failed Logins: 10
- Total Process Creations: 17,791

---

## Security Monitoring Panels

### Event Volume

Tracks overall security event activity over time to identify spikes and abnormal behavior.

### Top Security Event IDs

Displays the most common Windows Security Event IDs being generated in the environment.

Examples observed:

- Event ID 5379
- Event ID 4798
- Event ID 4624
- Event ID 4672

---

## Authentication Monitoring

### Successful Logins

Monitors successful authentication activity and identifies the most active accounts.

### Authentication Failures Over Time

Tracks failed login attempts to identify suspicious authentication patterns and possible brute force activity.

### Potential Brute Force Attacks

Custom detection logic identifies accounts exceeding a defined threshold of failed login attempts.

---

## Process Monitoring

### Process Creation Activity

Uses Sysmon Event ID 1 to track process creation activity and identify unusual execution spikes.

### Top Processes

Displays the most frequently executed processes observed by Sysmon.

Examples:

- explorer.exe
- svchost.exe
- powershell.exe
- cmd.exe
- Splunk processes

---

## PowerShell Monitoring

### PowerShell Activity Over Time

Tracks PowerShell execution activity and highlights spikes that may require investigation.

This panel demonstrates monitoring of a common attack vector frequently used by threat actors.

---

## Command Execution Monitoring

### Command Execution Distribution

Visualizes execution activity for command interpreters including:

- cmd.exe
- powershell.exe

This provides visibility into scripting and command-line activity occurring within the environment.

---

## Log Source Analysis

### Events by Log Type

Breaks down event volume across multiple log sources:

- WinEventLog:Security
- WinEventLog:System
- WinEventLog:Application
- Microsoft-Windows-Sysmon/Operational

This validates successful log ingestion from multiple Windows logging sources.

---

# Dashboard Screenshot

![Splunk SOC Dashboard](screenshots/updated-splunk-soc-dashboard1.png)

---

# Key SPL Searches

## Successful Logins

```spl
index=* EventCode=4624
| stats count by Account_Name
```

## Failed Logins

```spl
index=* EventCode=4625
| stats count by host
```

## Process Creation Activity

```spl
source="WinEventLog:Microsoft-Windows-Sysmon/Operational"
EventID=1
| timechart count
```

## PowerShell Monitoring

```spl
source="WinEventLog:Microsoft-Windows-Sysmon/Operational"
powershell.exe
| stats count
```

## CMD Monitoring

```spl
source="WinEventLog:Microsoft-Windows-Sysmon/Operational"
cmd.exe
| stats count
```

## Brute Force Detection

```spl
index=* EventCode=4625
| stats count by Account_Name
| where count > 5
```

---

# Results

- Successfully deployed Splunk Enterprise SIEM
- Ingested Windows Security and Sysmon logs
- Collected and analyzed over 28,000 security events
- Built a multi-panel SOC monitoring dashboard
- Implemented authentication monitoring workflows
- Created brute force detection use cases
- Monitored PowerShell and command execution activity
- Performed event analysis using SPL searches
- Developed security visualizations for operational monitoring

---

# What I Learned

This project provided hands-on experience with SIEM deployment, Windows log ingestion, Sysmon telemetry, SPL query development, security dashboard creation, authentication monitoring, threat detection workflows, and SOC-style event analysis.

The lab closely mirrors many of the responsibilities performed by Security Operations Center (SOC) Analysts and Cybersecurity Analysts in enterprise environments.

---

# Conclusion

This project demonstrates the deployment and operation of a Splunk Enterprise SIEM platform for centralized security monitoring and threat detection. By combining Windows Security Logs, Sysmon telemetry, custom SPL searches, authentication monitoring, process analysis, and brute force detection, the lab simulates real-world SOC workflows used to monitor and investigate security events.
