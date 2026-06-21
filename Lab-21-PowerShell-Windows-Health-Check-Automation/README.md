# Lab 21 – PowerShell Windows Health Check Automation

## Overview

This lab demonstrates the development of a PowerShell automation tool designed to collect and report key Windows system health information. The script automates the gathering of commonly requested troubleshooting data and exports the results to a timestamped report file.

The goal of this project was to strengthen PowerShell scripting skills while creating a practical tool that could be used by Help Desk, Desktop Support, and Systems Administration teams to quickly assess workstation health.

---

## Objective

Automate the collection of critical Windows system information to reduce manual troubleshooting effort and improve efficiency during workstation diagnostics.

---

## Technologies Used

- PowerShell 5.1
- Windows 11
- Visual Studio Code
- Windows Management Instrumentation (WMI/CIM)

---

## Skills Demonstrated

- PowerShell Scripting
- Windows Administration
- IT Operations Automation
- Troubleshooting Methodology
- Performance Monitoring
- System Information Gathering
- Documentation
- Technical Reporting

---

## Lab Environment

| Component | Details |
|------------|------------|
| Operating System | Windows 11 |
| Scripting Language | PowerShell |
| Development Environment | Visual Studio Code |
| Report Format | TXT |
| Project Type | IT Operations Automation |

---

## Script Functions

The PowerShell script automatically collects:

### System Information

- Computer Name
- Logged-In User
- Windows Version
- System Uptime

### Performance Information

- CPU Utilization
- Memory Usage
- Disk Usage

### Network Information

- IPv4 Addresses

### Security Information

- Windows Defender Status

### Reporting

- Displays results in the console
- Exports results to a timestamped text report

---

## Screenshot

### Script Development and Output

![PowerShell Health Check Automation](screenshots/powershell-automation-healthcheck.png)

---

## Sample Output

```text
WINDOWS HEALTH CHECK REPORT

Report Time      : 2026-06-20 22:08:41
Computer Name    : LAB-CLIENT01
Current User     : DOMAIN\User
Uptime           : 0 day(s), 9 hour(s), 34 minute(s)

CPU Usage        : 68%
RAM Usage        : 13.18 GB used / 15.72 GB total
Disk Space (C:) : 180.44 GB free / 475.73 GB total

IP Addresses(s) : 192.168.x.x, 192.168.x.x

Windows Version : Microsoft Windows 11
Windows Defender: Running
```

---

## Business Value

In a production IT environment, technicians frequently gather workstation health information during troubleshooting sessions. This process can be repetitive and time-consuming.

This automation solution provides:

- Faster workstation assessments
- Consistent troubleshooting data collection
- Reduced manual effort
- Standardized reporting
- Improved operational efficiency

---

## Challenges Encountered

During development, several challenges were addressed:

- Retrieving accurate uptime information
- Formatting memory and disk statistics for readability
- Filtering non-relevant network adapters
- Creating clean report output
- Exporting timestamped reports

---

## Lessons Learned

Through this project I gained experience with:

- PowerShell variables
- Conditional logic
- CIM/WMI queries
- Object manipulation
- Data formatting
- Script documentation
- Automation workflows

---

## Future Enhancements

Planned improvements include:

- CSV export functionality
- HTML report generation
- Event Log collection
- Failed login detection
- Disk space threshold alerts
- Memory utilization alerts
- Email notification support
- Scheduled task integration
- Active Directory integration
- Health scoring system

---

## Repository Structure

```text
PowerShell-Windows-Health-Check/
│
├── HealthCheck.ps1
├── README.md
│
├── screenshots/
│   └── powershell-automation-healthcheck.png
│
└── sample-reports/
    └── HealthCheck-Sample.txt
```

---

## Author

**John Tyler**

IT Support Technician | Systems Administration Enthusiast | Cybersecurity & Cloud Computing Student

GitHub: https://github.com/johninfra

---

## Disclaimer

All screenshots and report data included in this repository have been sanitized to remove personally identifiable information and internal system details.
