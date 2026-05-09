# Lab 14 - Active Directory Password Reset and Ticket Resolution

## Overview
This lab demonstrates a common Tier 1 help desk support scenario involving a user password reset in Active Directory. The objective was to simulate a real world support ticket where an end user forgot their password, submitted a support request, and required account access restoration. The ticket was documented, resolved through Active Directory Users and Computers (ADUC), and then properly closed after successful password reset verification.

---

## Lab Setup

- Host Machine: Windows Laptop  
- Virtualization: VMware Workstation  
- Domain Controller: Windows Server 2022  
- Client Machine: Windows 10 VM  
- Domain: corp.local  
- Network Type: NAT  

---

## Tools Used

- Active Directory Users and Computers (ADUC)  
- Windows Server 2022  
- Windows 10 Client VM  
- VMware Workstation  
- File Explorer  

---

## Tasks Performed

### 1. Opened Help Desk Ticket
Simulated a support request submitted by user John Test who was unable to access their account after forgetting their password.

#### Ticket Opened
![Ticket Open](screenshots/ticket-open.png)

---

### 2. Accessed Active Directory User Account
Opened Active Directory Users and Computers on the domain controller and located the John Test user account within the domain environment.

#### Password Reset
![Password Reset](screenshots/johnt-password-reset.png)

---

### 3. Reset User Password
Performed a password reset for the John Test account and configured the account to regain access successfully.

#### Password Reset Completed
![Password Reset](screenshots/johnt-password-reset.png)

---

### 4. Closed Support Ticket
Verified the issue was resolved and documented the successful password reset before closing the support ticket.

#### Ticket Closed
![Ticket Closed](screenshots/ticket-closed.png)

---

## Results

- Successfully simulated a real world help desk ticket workflow  
- Located and managed a user account in Active Directory  
- Reset a user password through ADUC  
- Restored account access for the end user  
- Properly documented and closed the support ticket after resolution  

---

## Skills Demonstrated

- Active Directory user management  
- Password reset procedures  
- Tier 1 help desk troubleshooting  
- Ticket documentation and resolution workflow  
- Windows Server administration basics  
- End user support simulation  

---

## Conclusion

This lab provided hands on experience with one of the most common help desk support tasks: resetting a user password in Active Directory. By simulating the full workflow from ticket creation to ticket closure, I strengthened practical IT support skills related to account management, troubleshooting, and ticket handling. These are foundational responsibilities commonly performed in enterprise help desk and IT support environments.
