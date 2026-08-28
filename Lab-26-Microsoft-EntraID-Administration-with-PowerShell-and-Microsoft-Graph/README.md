# Microsoft Entra ID Administration with PowerShell and Microsoft Graph

## Overview

This lab demonstrates Microsoft Entra ID administration using PowerShell and the Microsoft Graph PowerShell SDK.

The objective was to establish a secure administrative connection to a Microsoft Entra tenant, verify the authenticated tenant and delegated Microsoft Graph permissions, enumerate directory users and groups, inspect privileged directory role assignments, and properly terminate the Microsoft Graph session.

This lab demonstrates practical experience with:

- Microsoft Entra ID
- Microsoft Graph
- PowerShell
- Identity and Access Management (IAM)
- Role-Based Access Control (RBAC)
- OAuth delegated permissions
- User and group administration
- Privileged role verification
- Administrative session management

---

## Video Demonstration

**Duration:** 4 minutes 37 seconds

▶️ [Watch the full Microsoft Entra ID PowerShell lab](./Microsoft-Entra-ID-Administration-with-PowerShell-and-Microsoft-Graph.mp4)

> The video demonstrates the complete workflow from Microsoft Entra ID tenant verification through Microsoft Graph authentication, directory enumeration, privileged role verification, and session termination.

---

## Lab Environment

| Component | Technology |
|---|---|
| Operating System | Windows |
| Shell | PowerShell |
| Identity Platform | Microsoft Entra ID |
| API | Microsoft Graph |
| PowerShell SDK | Microsoft.Graph |
| Authentication | Delegated OAuth |
| Authorization | Microsoft Entra RBAC |
| Tenant Type | Microsoft Entra Free |

---

## Lab Objectives

The objectives of this lab were to:

1. Connect PowerShell to a specific Microsoft Entra tenant.
2. Authenticate through Microsoft Graph.
3. Request least-privilege delegated permissions required for directory queries.
4. Verify the active Microsoft Graph authentication context.
5. Enumerate all users within the tenant.
6. Enumerate all groups within the tenant.
7. Review Microsoft Entra directory role definitions.
8. Verify privileged Global Administrator role assignments.
9. Demonstrate awareness of Microsoft Entra RBAC.
10. Properly disconnect the Microsoft Graph administrative session.

---

# 1. Install the Microsoft Graph PowerShell SDK

The Microsoft Graph PowerShell SDK provides PowerShell cmdlets for interacting with Microsoft Entra ID and other Microsoft 365 services through Microsoft Graph.

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

The Graph authentication module can be verified with:

```powershell
Get-Command Connect-MgGraph
```

---

# 2. Connect to the Microsoft Entra Tenant

The Microsoft Graph session was established against a specific Microsoft Entra tenant.

```powershell
Connect-MgGraph `
    -TenantId "REDACTED-TENANT-ID" `
    -Scopes "User.Read.All","Group.Read.All","RoleManagement.Read.Directory","Directory.Read.All"
```

### Permissions Requested

| Microsoft Graph Scope | Purpose |
|---|---|
| `User.Read.All` | Read user profiles in the directory |
| `Group.Read.All` | Read groups and group properties |
| `RoleManagement.Read.Directory` | Read Microsoft Entra directory role information |
| `Directory.Read.All` | Read directory objects |

Using explicit delegated scopes helps maintain a least-privilege administrative model.

---

# 3. Verify Microsoft Graph Authentication Context

After authentication, the active Graph context was reviewed.

```powershell
Get-MgContext
```

This verifies information such as:

- authenticated account
- tenant ID
- granted scopes
- authentication type
- Graph environment
- PowerShell host version

This step is important because successful authentication does not necessarily guarantee that PowerShell connected to the intended tenant or received the expected permissions.

---

# 4. Enumerate Microsoft Entra Users

All users within the Microsoft Entra tenant were queried using Microsoft Graph.

```powershell
Get-MgUser -All |
    Select-Object DisplayName, UserPrincipalName, AccountEnabled |
    Format-Table -AutoSize
```

### Information Retrieved

- Display Name
- User Principal Name
- Account status

This demonstrates directory enumeration through Microsoft Graph rather than relying solely on the graphical Entra admin center.

---

# 5. Enumerate Microsoft Entra Groups

All groups within the tenant were queried.

```powershell
Get-MgGroup -All |
    Select-Object DisplayName, SecurityEnabled, MailEnabled, GroupTypes |
    Format-Table -AutoSize
```

### Information Retrieved

- Group display name
- Security-enabled status
- Mail-enabled status
- Group type

This allows administrators to quickly inventory security groups and other directory group objects.

---

# 6. Review the Global Administrator Role

Microsoft Entra uses Role-Based Access Control to determine which identities have administrative privileges.

The Global Administrator role definition was retrieved using Microsoft Graph.

```powershell
$role = Get-MgRoleManagementDirectoryRoleDefinition `
    -Filter "displayName eq 'Global Administrator'"
```

The role definition can then be displayed with:

```powershell
$role
```

---

# 7. Retrieve Global Administrator Role Assignments

Active assignments for the Global Administrator role were queried.

```powershell
$assignments = Get-MgRoleManagementDirectoryRoleAssignment `
    -Filter "roleDefinitionId eq '$($role.Id)'"
```

This retrieves directory role assignment objects associated with the Global Administrator role.

---

# 8. Resolve Role Assignments to Users

Role assignment objects contain principal IDs, so the IDs were resolved to readable Microsoft Entra user accounts.

```powershell
foreach ($assignment in $assignments) {

    $user = Get-MgUser -UserId $assignment.PrincipalId

    [PSCustomObject]@{
        Role              = $role.DisplayName
        DisplayName       = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
    }
}
```

Example output:

```text
Role                  DisplayName   UserPrincipalName
----                  -----------   -----------------
Global Administrator  John Tyler    [REDACTED]
```

This demonstrates how Microsoft Graph can be used to identify privileged identities within a Microsoft Entra tenant.

---

# 9. Microsoft Entra RBAC Validation

The Microsoft Entra admin center was also used to independently verify the Global Administrator assignment.

This demonstrated the relationship between:

- Microsoft Graph permissions
- Microsoft Entra directory roles
- delegated authentication
- RBAC
- administrative authorization

A Graph permission does not automatically make a user a Microsoft Entra administrator.

The authenticated user must also possess sufficient directory privileges for the requested administrative operation.

---

# 10. Disconnect the Microsoft Graph Session

After completing the administrative tasks, the Graph session was explicitly terminated.

```powershell
Disconnect-MgGraph
```

The session state can then be verified:

```powershell
Get-MgContext
```

No active Graph context should remain after the session has been successfully disconnected.

Explicit session termination is a good administrative security practice, particularly when working with privileged accounts or multiple Microsoft Entra tenants.

---

# Security Considerations

Sensitive information was intentionally excluded or redacted from the public lab demonstration.

Examples include:

- passwords
- temporary passwords
- authentication tokens
- refresh tokens
- MFA codes
- recovery codes
- FIDO2/security-key information
- client secrets
- certificate private keys
- personal account identifiers where unnecessary

Tenant IDs and Microsoft Entra object IDs are identifiers rather than authentication secrets, but unnecessary identifiers were minimized or redacted as an operational security best practice.

---

# Key Concepts Demonstrated

## Microsoft Graph

Microsoft Graph provides a unified API for interacting with Microsoft cloud services, including Microsoft Entra ID.

The Microsoft Graph PowerShell SDK exposes Graph functionality through PowerShell cmdlets such as:

```powershell
Connect-MgGraph
Get-MgUser
Get-MgGroup
Get-MgRoleManagementDirectoryRoleDefinition
Get-MgRoleManagementDirectoryRoleAssignment
Disconnect-MgGraph
```

---

## Delegated Authentication

This lab used delegated authentication.

With delegated authentication:

```text
User
  |
  v
Microsoft Identity Platform
  |
  v
OAuth Access Token
  |
  v
Microsoft Graph
  |
  v
Microsoft Entra Tenant
```

Microsoft Graph performs operations within the permissions granted to the application and the privileges available to the authenticated user.

---

## Role-Based Access Control

Microsoft Entra RBAC determines which administrative actions an identity is authorized to perform.

Examples of Microsoft Entra administrative roles include:

- Global Administrator
- User Administrator
- Groups Administrator
- Authentication Administrator
- Helpdesk Administrator
- Security Administrator
- Global Reader

This lab verified an active Global Administrator role assignment through both Microsoft Graph PowerShell and the Microsoft Entra admin center.

---

# Skills Demonstrated

- Microsoft Entra ID administration
- Microsoft Graph PowerShell
- PowerShell administration
- Identity and Access Management
- Directory enumeration
- User administration
- Group administration
- Microsoft Entra RBAC
- Privileged role auditing
- OAuth delegated authentication
- Graph API permissions
- Least-privilege concepts
- Secure administrative session management
- Cloud identity troubleshooting

---

# Commands Used

```powershell
# Connect to Microsoft Graph
Connect-MgGraph `
    -TenantId "REDACTED-TENANT-ID" `
    -Scopes "User.Read.All","Group.Read.All","RoleManagement.Read.Directory","Directory.Read.All"

# Verify Graph authentication context
Get-MgContext

# List all users
Get-MgUser -All |
    Select-Object DisplayName, UserPrincipalName, AccountEnabled |
    Format-Table -AutoSize

# List all groups
Get-MgGroup -All |
    Select-Object DisplayName, SecurityEnabled, MailEnabled, GroupTypes |
    Format-Table -AutoSize

# Retrieve Global Administrator role definition
$role = Get-MgRoleManagementDirectoryRoleDefinition `
    -Filter "displayName eq 'Global Administrator'"

# Retrieve Global Administrator assignments
$assignments = Get-MgRoleManagementDirectoryRoleAssignment `
    -Filter "roleDefinitionId eq '$($role.Id)'"

# Resolve role assignments
foreach ($assignment in $assignments) {

    $user = Get-MgUser -UserId $assignment.PrincipalId

    [PSCustomObject]@{
        Role              = $role.DisplayName
        DisplayName       = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
    }
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph

# Confirm Graph context has been removed
Get-MgContext
```

---

# Lab Outcome

This lab successfully demonstrated remote Microsoft Entra ID administration through Microsoft Graph PowerShell.

The workflow included:

```text
Microsoft Entra Tenant
        |
        v
Microsoft Graph Authentication
        |
        v
Delegated OAuth Permissions
        |
        v
PowerShell Administrative Session
        |
        +--> Enumerate Users
        |
        +--> Enumerate Groups
        |
        +--> Inspect Directory Roles
        |
        +--> Verify Global Administrator Assignment
        |
        v
Disconnect Administrative Session
```

The lab demonstrates practical familiarity with Microsoft cloud identity administration, Microsoft Graph, PowerShell, IAM concepts, RBAC, and privileged-access verification.

---

## Video

▶️ **[Microsoft Entra ID Administration with PowerShell and Microsoft Graph — Full Lab Video](./Microsoft-Entra-ID-Administration-with-PowerShell-and-Microsoft-Graph.mp4)**

**Duration:** 4:37
