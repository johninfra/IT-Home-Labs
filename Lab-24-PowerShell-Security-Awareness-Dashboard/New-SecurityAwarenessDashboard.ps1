#requires -version 5.1
<#
.SYNOPSIS
    Generates a detailed, standalone Windows security awareness and endpoint posture dashboard.

.DESCRIPTION
    Performs read-only security checks against the local Windows computer and creates an
    interactive HTML report. The script does not change security settings, install software,
    upload data, or require internet access. Run from an elevated PowerShell session for the
    most complete results.

.PARAMETER OutputPath
    Destination HTML path. Defaults to the current directory with the computer name and time.

.PARAMETER DaysToAnalyze
    Number of days of Windows security events to summarize. Default: 7. Range: 1-30.

.PARAMETER Organization
    Optional organization or lab name displayed in the dashboard header.

.PARAMETER OpenReport
    Opens the generated dashboard in the default browser after creation.

.EXAMPLE
    .\New-SecurityAwarenessDashboard.ps1 -OpenReport

.EXAMPLE
    .\New-SecurityAwarenessDashboard.ps1 -OutputPath C:\Reports\SecurityDashboard.html -DaysToAnalyze 14 -Organization "Contoso IT"

.NOTES
    Compatible with Windows PowerShell 5.1 and PowerShell 7+ on Windows.
    This is a point-in-time defensive assessment, not a vulnerability scanner or compliance
    certification. Validate findings against organizational policy before remediation.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path -Path (Get-Location) -ChildPath ("Security-Awareness-Dashboard-{0}-{1}.html" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd-HHmmss'))),

    [Parameter()]
    [ValidateRange(1, 30)]
    [int]$DaysToAnalyze = 7,

    [Parameter()]
    [ValidateLength(0, 100)]
    [string]$Organization = 'Security Awareness Program',

    [Parameter()]
    [switch]$OpenReport
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$script:Findings = New-Object System.Collections.Generic.List[object]
$script:CollectionErrors = New-Object System.Collections.Generic.List[string]

function ConvertTo-HtmlSafe {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return '' }
    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Get-RegistryValueSafe {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [AllowNull()][object]$Default = $null
    )
    try {
        $item = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
        return $item.$Name
    }
    catch { return $Default }
}

function Invoke-SafeCheck {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [AllowNull()][object]$Fallback = $null
    )
    try { return & $ScriptBlock }
    catch {
        $script:CollectionErrors.Add(("{0}: {1}" -f $Name, $_.Exception.Message))
        return $Fallback
    }
}

function Add-Finding {
    param(
        [Parameter(Mandatory)][ValidateSet('Identity','Endpoint','Network','Data Protection','Updates','Logging','Attack Surface','System')][string]$Category,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('Pass','Warn','Fail','Info','Unknown')][string]$Status,
        [Parameter(Mandatory)][ValidateSet('Critical','High','Medium','Low','Informational')][string]$Severity,
        [Parameter(Mandatory)][string]$Finding,
        [Parameter(Mandatory)][string]$Recommendation,
        [AllowEmptyString()][string]$Evidence = '',
        [ValidateRange(0, 10)][int]$Weight = 1
    )
    $script:Findings.Add([pscustomobject]@{
        Category       = $Category
        Name           = $Name
        Status         = $Status
        Severity       = $Severity
        Finding        = $Finding
        Recommendation = $Recommendation
        Evidence       = $Evidence
        Weight         = $Weight
    })
}

function Get-IsAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch { return $false }
}

function Convert-CimDate {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return $null }
    try { return [Management.ManagementDateTimeConverter]::ToDateTime([string]$Value) }
    catch {
        try { return [datetime]$Value }
        catch { return $null }
    }
}

function Get-SeverityRank {
    param([string]$Severity)
    switch ($Severity) {
        'Critical' { 5 }
        'High' { 4 }
        'Medium' { 3 }
        'Low' { 2 }
        default { 1 }
    }
}

function Get-EventCount {
    param(
        [Parameter(Mandatory)][string]$LogName,
        [Parameter(Mandatory)][int]$Id,
        [Parameter(Mandatory)][datetime]$StartTime
    )
    try {
        $measurement = (
            Get-WinEvent -FilterHashtable @{ LogName = $LogName; Id = $Id; StartTime = $StartTime } -ErrorAction Stop |
                Measure-Object
        )
        return [int]$measurement.Count
    }
    catch {
        if ($_.Exception.Message -notmatch 'No events were found') {
            $script:CollectionErrors.Add(("Event {0}/{1}: {2}" -f $LogName, $Id, $_.Exception.Message))
        }
        return 0
    }
}

$reportStarted = Get-Date
$isAdmin = Get-IsAdministrator
$eventStart = (Get-Date).AddDays(-$DaysToAnalyze)

# --- System inventory --------------------------------------------------------
$os = Invoke-SafeCheck -Name 'Operating system inventory' -ScriptBlock { Get-CimInstance Win32_OperatingSystem }
$computer = Invoke-SafeCheck -Name 'Computer inventory' -ScriptBlock { Get-CimInstance Win32_ComputerSystem }
$bios = Invoke-SafeCheck -Name 'BIOS inventory' -ScriptBlock { Get-CimInstance Win32_BIOS }
$bootTime = if ($os) { Convert-CimDate $os.LastBootUpTime } else { $null }
$osCaption = if ($os) { [string]$os.Caption } else { 'Windows (version unavailable)' }
$osBuild = if ($os) { [string]$os.BuildNumber } else { 'Unknown' }
$manufacturer = if ($computer) { [string]$computer.Manufacturer } else { 'Unknown' }
$model = if ($computer) { [string]$computer.Model } else { 'Unknown' }

Add-Finding -Category 'System' -Name 'Assessment privileges' `
    -Status $(if ($isAdmin) { 'Pass' } else { 'Warn' }) -Severity 'Low' `
    -Finding $(if ($isAdmin) { 'Assessment is running with administrator rights.' } else { 'Assessment is not elevated; some security data may be unavailable.' }) `
    -Recommendation $(if ($isAdmin) { 'Use privileged access only when needed and close the elevated session after the assessment.' } else { 'Re-run PowerShell as Administrator for complete BitLocker, event log, TPM, and Defender visibility.' }) `
    -Evidence ("User: {0}\{1}; Elevated: {2}" -f $env:USERDOMAIN, $env:USERNAME, $isAdmin) -Weight 0

# --- Microsoft Defender and security products -------------------------------
$defender = Invoke-SafeCheck -Name 'Microsoft Defender status' -ScriptBlock { Get-MpComputerStatus -ErrorAction Stop }
if ($defender) {
    $defenderHealthy = [bool]$defender.AntivirusEnabled -and [bool]$defender.RealTimeProtectionEnabled
    Add-Finding -Category 'Endpoint' -Name 'Microsoft Defender real-time protection' `
        -Status $(if ($defenderHealthy) { 'Pass' } else { 'Fail' }) -Severity 'Critical' `
        -Finding $(if ($defenderHealthy) { 'Microsoft Defender Antivirus and real-time protection are enabled.' } else { 'Microsoft Defender Antivirus or real-time protection is disabled.' }) `
        -Recommendation $(if ($defenderHealthy) { 'Keep real-time, behavior, cloud-delivered, and tamper protection enabled.' } else { 'Enable the approved endpoint protection platform and investigate why real-time protection is disabled.' }) `
        -Evidence ("Antivirus={0}; RealTime={1}; Behavior={2}; IOAV={3}" -f $defender.AntivirusEnabled, $defender.RealTimeProtectionEnabled, $defender.BehaviorMonitorEnabled, $defender.IoavProtectionEnabled) -Weight 10

    $sigAge = [int]$defender.AntivirusSignatureAge
    Add-Finding -Category 'Endpoint' -Name 'Antimalware intelligence freshness' `
        -Status $(if ($sigAge -le 3) { 'Pass' } elseif ($sigAge -le 7) { 'Warn' } else { 'Fail' }) `
        -Severity $(if ($sigAge -gt 7) { 'High' } else { 'Medium' }) `
        -Finding ("Defender security intelligence is {0} day(s) old." -f $sigAge) `
        -Recommendation 'Update security intelligence immediately if stale; verify Windows Update, proxy, and Defender update sources.' `
        -Evidence ("Version: {0}; Last updated: {1}" -f $defender.AntivirusSignatureVersion, $defender.AntivirusSignatureLastUpdated) -Weight 6

    if ($null -ne $defender.IsTamperProtected) {
        Add-Finding -Category 'Endpoint' -Name 'Tamper protection' `
            -Status $(if ($defender.IsTamperProtected) { 'Pass' } else { 'Warn' }) -Severity 'High' `
            -Finding $(if ($defender.IsTamperProtected) { 'Microsoft Defender tamper protection is enabled.' } else { 'Microsoft Defender tamper protection appears disabled.' }) `
            -Recommendation 'Enable tamper protection through Windows Security or the organization endpoint-management platform.' `
            -Evidence ("TamperProtected={0}" -f $defender.IsTamperProtected) -Weight 6
    }

    $cloudEnabled = [bool]$defender.NISEnabled
    Add-Finding -Category 'Endpoint' -Name 'Network inspection protection' `
        -Status $(if ($cloudEnabled) { 'Pass' } else { 'Warn' }) -Severity 'Medium' `
        -Finding $(if ($cloudEnabled) { 'Defender Network Inspection System is enabled.' } else { 'Defender Network Inspection System is not reported as enabled.' }) `
        -Recommendation 'Enable network protection and confirm Defender platform components are current.' `
        -Evidence ("NIS={0}; NIS signature age={1}" -f $defender.NISEnabled, $defender.NISSignatureAge) -Weight 3
}
else {
    Add-Finding -Category 'Endpoint' -Name 'Endpoint protection visibility' -Status 'Unknown' -Severity 'High' `
        -Finding 'Microsoft Defender status could not be queried. Another security product may be active, or access may be restricted.' `
        -Recommendation 'Confirm that an approved, healthy endpoint detection and response product is installed and centrally monitored.' `
        -Evidence 'Get-MpComputerStatus returned no data.' -Weight 8
}

$avProducts = @(Invoke-SafeCheck -Name 'Security Center antivirus inventory' -ScriptBlock {
    @(Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction Stop)
} -Fallback @())
if ($avProducts.Count -gt 0) {
    Add-Finding -Category 'Endpoint' -Name 'Registered antivirus products' -Status 'Info' -Severity 'Informational' `
        -Finding ("Windows Security Center reports {0} antivirus product(s)." -f $avProducts.Count) `
        -Recommendation 'Avoid running multiple active real-time antivirus engines unless the vendors explicitly support coexistence.' `
        -Evidence (($avProducts | ForEach-Object { $_.displayName }) -join ', ') -Weight 0
}

# --- Firewall and network posture -------------------------------------------
$firewallProfiles = @(Invoke-SafeCheck -Name 'Windows Firewall profiles' -ScriptBlock { @(Get-NetFirewallProfile -ErrorAction Stop) } -Fallback @())
if ($firewallProfiles.Count -gt 0) {
    foreach ($profile in $firewallProfiles) {
        Add-Finding -Category 'Network' -Name ("Windows Firewall - {0} profile" -f $profile.Name) `
            -Status $(if ($profile.Enabled) { 'Pass' } else { 'Fail' }) -Severity 'High' `
            -Finding $(if ($profile.Enabled) { ("The {0} firewall profile is enabled." -f $profile.Name) } else { ("The {0} firewall profile is disabled." -f $profile.Name) }) `
            -Recommendation 'Keep all firewall profiles enabled. Manage exceptions narrowly through approved policy.' `
            -Evidence ("Enabled={0}; Inbound={1}; Outbound={2}; NotifyOnListen={3}" -f $profile.Enabled, $profile.DefaultInboundAction, $profile.DefaultOutboundAction, $profile.NotifyOnListen) -Weight 6
    }
}
else {
    Add-Finding -Category 'Network' -Name 'Windows Firewall visibility' -Status 'Unknown' -Severity 'High' `
        -Finding 'Firewall profile configuration could not be collected.' `
        -Recommendation 'Verify all Domain, Private, and Public firewall profiles are enabled.' -Evidence 'Get-NetFirewallProfile returned no data.' -Weight 6
}

$netProfiles = @(Invoke-SafeCheck -Name 'Active network profiles' -ScriptBlock { @(Get-NetConnectionProfile -ErrorAction Stop) } -Fallback @())
$publicNetworks = @($netProfiles | Where-Object { $_.NetworkCategory -eq 'Public' })
Add-Finding -Category 'Network' -Name 'Active network classification' `
    -Status $(if ($publicNetworks.Count -gt 0) { 'Info' } else { 'Pass' }) -Severity 'Informational' `
    -Finding $(if ($netProfiles.Count -eq 0) { 'No active network profile was returned.' } elseif ($publicNetworks.Count -gt 0) { 'At least one active connection is classified Public, which applies the most restrictive Windows sharing posture.' } else { 'No active connection is classified Public.' }) `
    -Recommendation 'Use Public for untrusted networks. Use Private or Domain only for trusted networks with appropriate controls.' `
    -Evidence (($netProfiles | ForEach-Object { "{0} ({1})" -f $_.Name, $_.NetworkCategory }) -join '; ') -Weight 0

$riskyPorts = @{
    21='FTP'; 23='Telnet'; 135='RPC'; 139='NetBIOS'; 445='SMB'; 3389='RDP'; 5985='WinRM HTTP'; 5986='WinRM HTTPS'
}
$listeners = @(Invoke-SafeCheck -Name 'Listening TCP ports' -ScriptBlock { @(Get-NetTCPConnection -State Listen -ErrorAction Stop) } -Fallback @())
$exposedListeners = @($listeners | Where-Object { $riskyPorts.ContainsKey([int]$_.LocalPort) })
if ($exposedListeners.Count -gt 0) {
    $listenerEvidence = $exposedListeners | Sort-Object LocalPort, LocalAddress -Unique | ForEach-Object {
        "{0}:{1} ({2})" -f $_.LocalAddress, $_.LocalPort, $riskyPorts[[int]$_.LocalPort]
    }
    Add-Finding -Category 'Attack Surface' -Name 'Security-sensitive listening services' -Status 'Warn' -Severity 'Medium' `
        -Finding ("Detected {0} security-sensitive listening endpoint(s). A listener is not automatically a vulnerability, but it increases attack surface." -f $exposedListeners.Count) `
        -Recommendation 'Confirm each service is required, restricted by firewall scope, patched, authenticated, and disabled when not in use.' `
        -Evidence ($listenerEvidence -join '; ') -Weight 4
}
else {
    Add-Finding -Category 'Attack Surface' -Name 'Security-sensitive listening services' -Status 'Pass' -Severity 'Medium' `
        -Finding 'No listeners were detected on the dashboard high-interest port list.' `
        -Recommendation 'Continue reviewing listening services and firewall rules as part of routine hardening.' `
        -Evidence ("Total TCP listeners observed: {0}" -f $listeners.Count) -Weight 4
}

# --- Encryption, boot trust, and platform security --------------------------
$bitlocker = Invoke-SafeCheck -Name 'BitLocker status' -ScriptBlock {
    Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
}
if ($bitlocker) {
    $encrypted = ([string]$bitlocker.VolumeStatus -eq 'FullyEncrypted') -and ([string]$bitlocker.ProtectionStatus -eq 'On')
    Add-Finding -Category 'Data Protection' -Name 'System-drive encryption' `
        -Status $(if ($encrypted) { 'Pass' } else { 'Fail' }) -Severity 'High' `
        -Finding $(if ($encrypted) { 'The Windows system drive is fully encrypted and BitLocker protection is on.' } else { 'The Windows system drive is not fully protected by BitLocker.' }) `
        -Recommendation 'Enable full-volume encryption and escrow the recovery key in an approved secure location. Test recovery procedures.' `
        -Evidence ("VolumeStatus={0}; ProtectionStatus={1}; Encryption={2}; Percent={3}" -f $bitlocker.VolumeStatus, $bitlocker.ProtectionStatus, $bitlocker.EncryptionMethod, $bitlocker.EncryptionPercentage) -Weight 8
}
else {
    Add-Finding -Category 'Data Protection' -Name 'System-drive encryption' -Status 'Unknown' -Severity 'High' `
        -Finding 'BitLocker status could not be determined.' `
        -Recommendation 'Run elevated and verify that the system drive is fully encrypted with recovery material securely escrowed.' `
        -Evidence 'Get-BitLockerVolume returned no data or is unavailable.' -Weight 8
}

$tpm = Invoke-SafeCheck -Name 'TPM status' -ScriptBlock { Get-Tpm -ErrorAction Stop }
if ($tpm) {
    $tpmReady = [bool]$tpm.TpmPresent -and [bool]$tpm.TpmReady -and [bool]$tpm.TpmEnabled
    Add-Finding -Category 'System' -Name 'Trusted Platform Module' `
        -Status $(if ($tpmReady) { 'Pass' } else { 'Warn' }) -Severity 'Medium' `
        -Finding $(if ($tpmReady) { 'A present, enabled, and ready TPM is reported.' } else { 'The TPM is missing, disabled, or not ready.' }) `
        -Recommendation 'Enable and initialize TPM 2.0 in accordance with hardware support and organizational policy.' `
        -Evidence ("Present={0}; Ready={1}; Enabled={2}; Activated={3}" -f $tpm.TpmPresent, $tpm.TpmReady, $tpm.TpmEnabled, $tpm.TpmActivated) -Weight 4
}

$secureBoot = Invoke-SafeCheck -Name 'Secure Boot status' -ScriptBlock { Confirm-SecureBootUEFI -ErrorAction Stop }
if ($null -ne $secureBoot) {
    Add-Finding -Category 'System' -Name 'Secure Boot' `
        -Status $(if ($secureBoot) { 'Pass' } else { 'Fail' }) -Severity 'High' `
        -Finding $(if ($secureBoot) { 'UEFI Secure Boot is enabled.' } else { 'UEFI Secure Boot is disabled.' }) `
        -Recommendation 'Enable Secure Boot where supported after validating firmware, operating system, and recovery-key readiness.' `
        -Evidence ("SecureBoot={0}" -f $secureBoot) -Weight 6
}
else {
    Add-Finding -Category 'System' -Name 'Secure Boot' -Status 'Unknown' -Severity 'Medium' `
        -Finding 'Secure Boot status could not be determined; the system may use legacy BIOS or access may be restricted.' `
        -Recommendation 'Verify UEFI Secure Boot in System Information or firmware settings.' -Evidence 'Confirm-SecureBootUEFI returned no data.' -Weight 3
}

# --- Identity and account controls ------------------------------------------
$uacEnabled = (Get-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -Default 0) -eq 1
$uacPrompt = Get-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'ConsentPromptBehaviorAdmin' -Default -1
Add-Finding -Category 'Identity' -Name 'User Account Control' `
    -Status $(if ($uacEnabled -and $uacPrompt -ne 0) { 'Pass' } elseif ($uacEnabled) { 'Warn' } else { 'Fail' }) `
    -Severity 'High' `
    -Finding $(if (-not $uacEnabled) { 'User Account Control is disabled.' } elseif ($uacPrompt -eq 0) { 'UAC is enabled, but administrator elevation may occur without a consent prompt.' } else { 'UAC is enabled with an administrator consent or credential prompt.' }) `
    -Recommendation 'Keep UAC enabled. Require a secure-desktop consent or credential prompt and use separate standard and administrative accounts.' `
    -Evidence ("EnableLUA={0}; ConsentPromptBehaviorAdmin={1}" -f [int]$uacEnabled, $uacPrompt) -Weight 7

$localUsers = @(Invoke-SafeCheck -Name 'Local user inventory' -ScriptBlock { @(Get-LocalUser -ErrorAction Stop) } -Fallback @())
if ($localUsers.Count -gt 0) {
    $enabledUsers = @($localUsers | Where-Object { $_.Enabled -eq $true })
    $noExpirationReported = @($enabledUsers | Where-Object { $null -eq $_.PasswordExpires })
    Add-Finding -Category 'Identity' -Name 'Enabled local accounts' `
        -Status $(if ($enabledUsers.Count -le 3) { 'Pass' } else { 'Warn' }) -Severity 'Medium' `
        -Finding ("Found {0} enabled local account(s), including {1} with no password-expiration date reported." -f $enabledUsers.Count, $noExpirationReported.Count) `
        -Recommendation 'Disable unused accounts, avoid shared accounts, enforce managed password controls, and prefer centralized identity where available.' `
        -Evidence (($enabledUsers | ForEach-Object { "{0} [PasswordExpires={1}]" -f $_.Name, $(if ($null -eq $_.PasswordExpires) { 'Not reported' } else { $_.PasswordExpires }) }) -join '; ') -Weight 4

    $guest = $localUsers | Where-Object { $_.SID.Value -match '-501$' } | Select-Object -First 1
    if ($guest) {
        Add-Finding -Category 'Identity' -Name 'Built-in Guest account' `
            -Status $(if (-not $guest.Enabled) { 'Pass' } else { 'Fail' }) -Severity 'High' `
            -Finding $(if ($guest.Enabled) { 'The built-in Guest account is enabled.' } else { 'The built-in Guest account is disabled.' }) `
            -Recommendation 'Keep the built-in Guest account disabled unless an approved, controlled use case exists.' `
            -Evidence ("Account={0}; Enabled={1}" -f $guest.Name, $guest.Enabled) -Weight 6
    }
}

$admins = @(Invoke-SafeCheck -Name 'Local Administrators membership' -ScriptBlock { @(Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop) } -Fallback @())
if ($admins.Count -gt 0) {
    Add-Finding -Category 'Identity' -Name 'Local administrator exposure' `
        -Status $(if ($admins.Count -le 3) { 'Pass' } else { 'Warn' }) -Severity 'High' `
        -Finding ("The local Administrators group contains {0} member(s)." -f $admins.Count) `
        -Recommendation 'Review membership regularly, remove stale principals, use separate admin identities, and deploy Windows LAPS for local administrator passwords.' `
        -Evidence (($admins | ForEach-Object { "{0} ({1})" -f $_.Name, $_.ObjectClass }) -join '; ') -Weight 6
}
else {
    Add-Finding -Category 'Identity' -Name 'Local administrator exposure' -Status 'Unknown' -Severity 'High' `
        -Finding 'Local Administrators membership could not be enumerated.' `
        -Recommendation 'Run elevated and review the local Administrators group for least privilege.' -Evidence 'No group membership data returned.' -Weight 4
}

$autoAdminLogon = Get-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoAdminLogon' -Default '0'
$defaultPassword = Get-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultPassword' -Default $null
Add-Finding -Category 'Identity' -Name 'Automatic logon credentials' `
    -Status $(if ($autoAdminLogon -eq '1' -or $null -ne $defaultPassword) { 'Fail' } else { 'Pass' }) -Severity 'Critical' `
    -Finding $(if ($autoAdminLogon -eq '1' -or $null -ne $defaultPassword) { 'Automatic logon is enabled or a default password value exists in the Winlogon registry location.' } else { 'No Winlogon automatic-logon password configuration was detected.' }) `
    -Recommendation 'Disable automatic logon and remove stored Winlogon credentials. Use approved kiosk or autologon controls when explicitly required.' `
    -Evidence ("AutoAdminLogon={0}; DefaultPasswordPresent={1}" -f $autoAdminLogon, ($null -ne $defaultPassword)) -Weight 10

$wdigest = Get-RegistryValueSafe -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest' -Name 'UseLogonCredential' -Default 0
Add-Finding -Category 'Identity' -Name 'WDigest credential caching' `
    -Status $(if ([int]$wdigest -eq 0) { 'Pass' } else { 'Fail' }) -Severity 'Critical' `
    -Finding $(if ([int]$wdigest -eq 0) { 'WDigest plaintext credential caching is not enabled.' } else { 'WDigest UseLogonCredential is enabled, which can expose reusable credentials in memory.' }) `
    -Recommendation 'Disable WDigest plaintext credential caching and investigate why the setting was changed.' `
    -Evidence ("UseLogonCredential={0}" -f $wdigest) -Weight 10

$lsaRunAsPpl = Get-RegistryValueSafe -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'RunAsPPL' -Default 0
Add-Finding -Category 'Identity' -Name 'LSA protection' `
    -Status $(if ([int]$lsaRunAsPpl -in 1,2) { 'Pass' } else { 'Warn' }) -Severity 'High' `
    -Finding $(if ([int]$lsaRunAsPpl -in 1,2) { 'Local Security Authority protection is configured.' } else { 'LSA protection is not explicitly configured in the checked registry location.' }) `
    -Recommendation 'Enable LSA protection after completing Microsoft compatibility validation for authentication packages and drivers.' `
    -Evidence ("RunAsPPL={0}" -f $lsaRunAsPpl) -Weight 5

# --- Updates and software maintenance ---------------------------------------
$hotfixes = @(Invoke-SafeCheck -Name 'Installed hotfix inventory' -ScriptBlock { @(Get-HotFix -ErrorAction Stop | Sort-Object InstalledOn -Descending) } -Fallback @())
$latestHotfix = $hotfixes | Where-Object { $null -ne $_.InstalledOn } | Select-Object -First 1
if ($latestHotfix) {
    $patchAge = [math]::Floor(((Get-Date) - [datetime]$latestHotfix.InstalledOn).TotalDays)
    Add-Finding -Category 'Updates' -Name 'Recent Windows update evidence' `
        -Status $(if ($patchAge -le 45) { 'Pass' } elseif ($patchAge -le 90) { 'Warn' } else { 'Fail' }) `
        -Severity $(if ($patchAge -gt 90) { 'High' } else { 'Medium' }) `
        -Finding ("The most recently reported hotfix was installed {0} day(s) ago." -f $patchAge) `
        -Recommendation 'Apply operating-system and third-party security updates within organizational remediation targets. Verify update compliance centrally.' `
        -Evidence ("{0}; Installed {1:yyyy-MM-dd}; {2}" -f $latestHotfix.HotFixID, $latestHotfix.InstalledOn, $latestHotfix.Description) -Weight 7
}
else {
    Add-Finding -Category 'Updates' -Name 'Recent Windows update evidence' -Status 'Unknown' -Severity 'High' `
        -Finding 'No dated Windows hotfix record was returned.' `
        -Recommendation 'Check Windows Update history and centralized patch-management status.' -Evidence 'Get-HotFix returned no dated records.' -Weight 5
}

$pendingRebootChecks = [ordered]@{
    'ComponentBasedServicing' = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
    'WindowsUpdate' = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    'PendingFileRename' = $null -ne (Get-RegistryValueSafe -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -Default $null)
}
$pendingReboot = $pendingRebootChecks.Values -contains $true
Add-Finding -Category 'Updates' -Name 'Pending restart' `
    -Status $(if ($pendingReboot) { 'Warn' } else { 'Pass' }) -Severity 'Medium' `
    -Finding $(if ($pendingReboot) { 'Windows reports at least one pending-restart indicator.' } else { 'No checked pending-restart indicator was detected.' }) `
    -Recommendation $(if ($pendingReboot) { 'Save work and restart during an approved maintenance window to complete security updates and servicing.' } else { 'Continue restarting promptly after security updates when requested.' }) `
    -Evidence (($pendingRebootChecks.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }) -join '; ') -Weight 3

# --- Attack-surface reduction and remote administration ---------------------
$smb1State = Invoke-SafeCheck -Name 'SMBv1 feature state' -ScriptBlock {
    (Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction Stop).State
}
if ($null -ne $smb1State) {
    Add-Finding -Category 'Attack Surface' -Name 'SMBv1 protocol' `
        -Status $(if ([string]$smb1State -eq 'Disabled') { 'Pass' } else { 'Fail' }) -Severity 'Critical' `
        -Finding $(if ([string]$smb1State -eq 'Disabled') { 'The SMBv1 optional feature is disabled.' } else { ("The SMBv1 optional feature state is {0}." -f $smb1State) }) `
        -Recommendation 'Disable SMBv1. Replace or isolate legacy systems that require it.' `
        -Evidence ("SMB1Protocol state={0}" -f $smb1State) -Weight 10
}
else {
    Add-Finding -Category 'Attack Surface' -Name 'SMBv1 protocol' -Status 'Unknown' -Severity 'High' `
        -Finding 'The SMBv1 optional-feature state could not be determined.' `
        -Recommendation 'Verify that the SMBv1 client and server components are disabled.' -Evidence 'Feature query returned no data.' -Weight 6
}

$rdpDenied = Get-RegistryValueSafe -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Default 1
$rdpNla = Get-RegistryValueSafe -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Default 0
$rdpEnabled = [int]$rdpDenied -eq 0
Add-Finding -Category 'Attack Surface' -Name 'Remote Desktop exposure' `
    -Status $(if (-not $rdpEnabled) { 'Pass' } elseif ([int]$rdpNla -eq 1) { 'Warn' } else { 'Fail' }) `
    -Severity $(if ($rdpEnabled -and [int]$rdpNla -eq 0) { 'Critical' } else { 'High' }) `
    -Finding $(if (-not $rdpEnabled) { 'Remote Desktop connections are disabled.' } elseif ([int]$rdpNla -eq 1) { 'Remote Desktop is enabled with Network Level Authentication.' } else { 'Remote Desktop is enabled without Network Level Authentication.' }) `
    -Recommendation $(if (-not $rdpEnabled) { 'Keep RDP disabled unless required.' } else { 'Require NLA and MFA through an approved access layer; restrict source networks; never expose RDP directly to the internet.' }) `
    -Evidence ("RDPEnabled={0}; NLA={1}" -f $rdpEnabled, ([int]$rdpNla -eq 1)) -Weight 7

$remoteRegistry = Invoke-SafeCheck -Name 'Remote Registry service' -ScriptBlock { Get-Service -Name RemoteRegistry -ErrorAction Stop }
if ($remoteRegistry) {
    Add-Finding -Category 'Attack Surface' -Name 'Remote Registry service' `
        -Status $(if ($remoteRegistry.Status -eq 'Stopped') { 'Pass' } else { 'Warn' }) -Severity 'Medium' `
        -Finding ("The Remote Registry service is {0}." -f $remoteRegistry.Status) `
        -Recommendation 'Keep Remote Registry stopped or disabled unless a managed administrative workflow explicitly requires it.' `
        -Evidence ("Status={0}; StartType={1}" -f $remoteRegistry.Status, $remoteRegistry.StartType) -Weight 3
}

$smartscreen = Get-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'SmartScreenEnabled' -Default 'NotConfigured'
Add-Finding -Category 'Endpoint' -Name 'Microsoft Defender SmartScreen' `
    -Status $(if ([string]$smartscreen -in 'RequireAdmin','Warn') { 'Pass' } elseif ([string]$smartscreen -eq 'Off') { 'Fail' } else { 'Unknown' }) `
    -Severity 'High' `
    -Finding ("The checked SmartScreen configuration value is '{0}'." -f $smartscreen) `
    -Recommendation 'Enable SmartScreen and reputation-based protection for apps, files, and supported browsers through managed policy.' `
    -Evidence ("SmartScreenEnabled={0}" -f $smartscreen) -Weight 5

# --- PowerShell and audit logging -------------------------------------------
$scriptBlockLogging = Get-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Name 'EnableScriptBlockLogging' -Default 0
$moduleLogging = Get-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' -Name 'EnableModuleLogging' -Default 0
$transcription = Get-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' -Name 'EnableTranscripting' -Default 0
$loggingCount = @(@($scriptBlockLogging, $moduleLogging, $transcription) | Where-Object { [int]$_ -eq 1 }).Count
Add-Finding -Category 'Logging' -Name 'PowerShell security logging' `
    -Status $(if ([int]$scriptBlockLogging -eq 1 -and [int]$moduleLogging -eq 1) { 'Pass' } elseif ($loggingCount -gt 0) { 'Warn' } else { 'Fail' }) `
    -Severity 'High' `
    -Finding ("PowerShell logging controls enabled: {0} of 3 checked." -f $loggingCount) `
    -Recommendation 'Enable script block and module logging through Group Policy. Evaluate protected transcription storage and central log forwarding.' `
    -Evidence ("ScriptBlock={0}; Module={1}; Transcription={2}" -f $scriptBlockLogging, $moduleLogging, $transcription) -Weight 6

$securityLog = Invoke-SafeCheck -Name 'Security event log configuration' -ScriptBlock { Get-WinEvent -ListLog Security -ErrorAction Stop }
if ($securityLog) {
    $sizeMb = [math]::Round($securityLog.MaximumSizeInBytes / 1MB, 1)
    Add-Finding -Category 'Logging' -Name 'Security event log capacity' `
        -Status $(if ($sizeMb -ge 128) { 'Pass' } elseif ($sizeMb -ge 32) { 'Warn' } else { 'Fail' }) -Severity 'Medium' `
        -Finding ("The local Security event log maximum size is {0} MB." -f $sizeMb) `
        -Recommendation 'Size logs for the required retention window and forward security telemetry to a protected central platform.' `
        -Evidence ("Enabled={0}; RecordCount={1}; MaximumSizeMB={2}; LogMode={3}" -f $securityLog.IsEnabled, $securityLog.RecordCount, $sizeMb, $securityLog.LogMode) -Weight 4
}

# --- Recent defensive signals -----------------------------------------------
$eventSummary = [ordered]@{
    FailedLogons          = Get-EventCount -LogName 'Security' -Id 4625 -StartTime $eventStart
    AccountLockouts       = Get-EventCount -LogName 'Security' -Id 4740 -StartTime $eventStart
    ExplicitCredentials   = Get-EventCount -LogName 'Security' -Id 4648 -StartTime $eventStart
    NewProcesses          = Get-EventCount -LogName 'Security' -Id 4688 -StartTime $eventStart
    AuditLogCleared       = Get-EventCount -LogName 'Security' -Id 1102 -StartTime $eventStart
    DefenderDetections    = Get-EventCount -LogName 'Microsoft-Windows-Windows Defender/Operational' -Id 1116 -StartTime $eventStart
}

if ($eventSummary.AuditLogCleared -gt 0) {
    Add-Finding -Category 'Logging' -Name 'Security audit log clearing' -Status 'Fail' -Severity 'Critical' `
        -Finding ("Security event 1102 occurred {0} time(s) during the analysis window." -f $eventSummary.AuditLogCleared) `
        -Recommendation 'Validate every audit-log clearing event immediately; preserve central logs and investigate unauthorized clearing.' `
        -Evidence ("Window: {0:yyyy-MM-dd HH:mm} through {1:yyyy-MM-dd HH:mm}" -f $eventStart, (Get-Date)) -Weight 10
}
else {
    Add-Finding -Category 'Logging' -Name 'Security audit log clearing' -Status 'Pass' -Severity 'Critical' `
        -Finding 'No Security event 1102 was observed during the selected analysis window.' `
        -Recommendation 'Forward logs centrally so local deletion cannot erase the authoritative record.' `
        -Evidence ("Window: last {0} day(s)" -f $DaysToAnalyze) -Weight 7
}

if ($eventSummary.DefenderDetections -gt 0) {
    Add-Finding -Category 'Endpoint' -Name 'Recent Defender detections' -Status 'Warn' -Severity 'High' `
        -Finding ("Microsoft Defender recorded {0} malware or potentially unwanted software detection event(s) in the analysis window." -f $eventSummary.DefenderDetections) `
        -Recommendation 'Review detection details, remediation state, affected files/users, persistence indicators, and related telemetry.' `
        -Evidence ("Event ID 1116 count={0}; Window={1} days" -f $eventSummary.DefenderDetections, $DaysToAnalyze) -Weight 6
}
else {
    Add-Finding -Category 'Endpoint' -Name 'Recent Defender detections' -Status 'Pass' -Severity 'High' `
        -Finding 'No Defender event 1116 was observed during the selected analysis window.' `
        -Recommendation 'Continue monitoring. Absence of alerts does not prove absence of compromise.' `
        -Evidence ("Window={0} days" -f $DaysToAnalyze) -Weight 3
}

# --- Score and summary -------------------------------------------------------
$scoredFindings = @($script:Findings | Where-Object { $_.Weight -gt 0 -and $_.Status -notin 'Info','Unknown' })
$possiblePoints = [double](($scoredFindings | Measure-Object Weight -Sum).Sum)
$earnedPoints = 0.0
foreach ($item in $scoredFindings) {
    switch ($item.Status) {
        'Pass' { $earnedPoints += $item.Weight }
        'Warn' { $earnedPoints += ($item.Weight * 0.5) }
    }
}
$score = if ($possiblePoints -gt 0) { [math]::Round(($earnedPoints / $possiblePoints) * 100) } else { 0 }
$grade = if ($score -ge 90) { 'A' } elseif ($score -ge 80) { 'B' } elseif ($score -ge 70) { 'C' } elseif ($score -ge 60) { 'D' } else { 'F' }
$riskLabel = if ($score -ge 90) { 'Low observed risk' } elseif ($score -ge 75) { 'Moderate observed risk' } elseif ($score -ge 60) { 'Elevated observed risk' } else { 'High observed risk' }
$statusCounts = @{}
foreach ($status in 'Pass','Warn','Fail','Unknown','Info') {
    $statusCounts[$status] = @($script:Findings | Where-Object Status -eq $status).Count
}

$orderedFindings = @($script:Findings | Sort-Object @{Expression={ if ($_.Status -eq 'Fail') { 0 } elseif ($_.Status -eq 'Warn') { 1 } elseif ($_.Status -eq 'Unknown') { 2 } elseif ($_.Status -eq 'Pass') { 3 } else { 4 } }}, @{Expression={ Get-SeverityRank $_.Severity }; Descending=$true}, Category, Name)
$priorityItems = @($orderedFindings | Where-Object { $_.Status -in 'Fail','Warn' } | Select-Object -First 8)

function New-FindingRows {
    param([object[]]$Items)
    $rows = New-Object System.Text.StringBuilder
    foreach ($item in $Items) {
        $search = ConvertTo-HtmlSafe ("{0} {1} {2} {3} {4} {5}" -f $item.Category, $item.Name, $item.Status, $item.Severity, $item.Finding, $item.Recommendation)
        $rowTemplate = @'
<tr data-status="{0}" data-category="{1}" data-search="{2}">
  <td><span class="status status-{3}">{4}</span></td>
  <td><span class="severity severity-{5}">{6}</span></td>
  <td><div class="finding-name">{7}</div><div class="category-label">{8}</div></td>
  <td>{9}</td>
  <td>{10}</td>
  <td><details><summary>View evidence</summary><code>{11}</code></details></td>
</tr>
'@
        $row = $rowTemplate -f (ConvertTo-HtmlSafe $item.Status), (ConvertTo-HtmlSafe $item.Category), $search, $item.Status.ToLowerInvariant(), (ConvertTo-HtmlSafe $item.Status), $item.Severity.ToLowerInvariant(), (ConvertTo-HtmlSafe $item.Severity), (ConvertTo-HtmlSafe $item.Name), (ConvertTo-HtmlSafe $item.Category), (ConvertTo-HtmlSafe $item.Finding), (ConvertTo-HtmlSafe $item.Recommendation), (ConvertTo-HtmlSafe $item.Evidence)
        [void]$rows.AppendLine($row)
    }
    return $rows.ToString()
}

function New-PriorityCards {
    param([object[]]$Items)
    if ($Items.Count -eq 0) { return '<div class="empty-state">No failed or warning checks were observed. Continue validating controls and monitoring for change.</div>' }
    $cards = New-Object System.Text.StringBuilder
    $index = 0
    foreach ($item in $Items) {
        $index++
        $cardTemplate = @'
<article class="priority-card">
  <div class="priority-number">{0}</div>
  <div><div class="priority-meta">{1} &middot; {2} &middot; {3}</div><h3>{4}</h3><p>{5}</p><div class="next-step"><strong>Next step:</strong> {6}</div></div>
</article>
'@
        $card = $cardTemplate -f $index, (ConvertTo-HtmlSafe $item.Severity), (ConvertTo-HtmlSafe $item.Category), (ConvertTo-HtmlSafe $item.Status), (ConvertTo-HtmlSafe $item.Name), (ConvertTo-HtmlSafe $item.Finding), (ConvertTo-HtmlSafe $item.Recommendation)
        [void]$cards.AppendLine($card)
    }
    return $cards.ToString()
}

$findingRows = New-FindingRows -Items $orderedFindings
$priorityCards = New-PriorityCards -Items $priorityItems
$collectionErrorHtml = if ($script:CollectionErrors.Count -gt 0) {
    ($script:CollectionErrors | ForEach-Object { '<li>{0}</li>' -f (ConvertTo-HtmlSafe $_) }) -join "`n"
} else { '<li>No collection errors recorded.</li>' }

$style = @'
:root{--bg:#07111f;--panel:#0d1b2a;--panel2:#11263a;--text:#e8f0f7;--muted:#91a4b7;--line:#22384d;--cyan:#36d7d7;--green:#48d597;--amber:#f7ba52;--red:#ff6577;--blue:#6aa9ff;--shadow:0 18px 55px rgba(0,0,0,.28)}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:radial-gradient(circle at 20% 0,#102b43 0,transparent 32%),var(--bg);color:var(--text);font-family:Inter,Segoe UI,Arial,sans-serif;line-height:1.55}.container{width:min(1440px,94%);margin:auto}.topbar{position:sticky;top:0;z-index:20;background:rgba(7,17,31,.88);backdrop-filter:blur(12px);border-bottom:1px solid var(--line)}.topbar-inner{display:flex;align-items:center;justify-content:space-between;gap:18px;padding:13px 0}.brand{display:flex;align-items:center;gap:11px;font-weight:800;letter-spacing:.02em}.brandmark{width:34px;height:34px;display:grid;place-items:center;border:1px solid var(--cyan);border-radius:10px;color:var(--cyan)}nav{display:flex;gap:8px;flex-wrap:wrap}nav a,.button{color:var(--muted);text-decoration:none;border:1px solid transparent;padding:8px 11px;border-radius:8px;font-size:13px;cursor:pointer;background:transparent}nav a:hover,.button:hover{color:var(--text);border-color:var(--line);background:var(--panel)}.hero{padding:60px 0 30px}.eyebrow{color:var(--cyan);text-transform:uppercase;letter-spacing:.14em;font-size:12px;font-weight:800}.hero h1{font-size:clamp(34px,5vw,64px);line-height:1.04;margin:10px 0 14px;max-width:950px}.hero p{max-width:850px;color:var(--muted);font-size:17px}.meta-strip{display:flex;gap:10px;flex-wrap:wrap;margin-top:23px}.chip{padding:7px 11px;border:1px solid var(--line);border-radius:999px;color:var(--muted);font-size:12px;background:rgba(13,27,42,.65)}.grid{display:grid;gap:18px}.summary-grid{grid-template-columns:1.3fr repeat(4,1fr);margin:16px 0 38px}.card{background:linear-gradient(145deg,rgba(17,38,58,.95),rgba(13,27,42,.95));border:1px solid var(--line);border-radius:16px;padding:22px;box-shadow:var(--shadow)}.score-card{display:grid;grid-template-columns:150px 1fr;align-items:center;gap:20px}.score-ring{--score:50;width:140px;aspect-ratio:1;border-radius:50%;display:grid;place-items:center;background:conic-gradient(var(--cyan) calc(var(--score)*1%),#20364a 0);position:relative}.score-ring:after{content:"";position:absolute;inset:11px;border-radius:50%;background:var(--panel)}.score-value{z-index:1;text-align:center;font-size:39px;font-weight:850;line-height:1}.score-value small{display:block;font-size:11px;color:var(--muted);font-weight:600;margin-top:7px}.score-copy h2{font-size:25px;margin:0 0 4px}.score-copy p{color:var(--muted);margin:0;font-size:13px}.metric{min-height:145px}.metric-label{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.09em}.metric-value{font-size:38px;font-weight:850;margin:13px 0 5px}.metric small{color:var(--muted)}.pass-text{color:var(--green)}.warn-text{color:var(--amber)}.fail-text{color:var(--red)}.unknown-text{color:var(--blue)}section{scroll-margin-top:80px;margin:42px 0}.section-head{display:flex;justify-content:space-between;align-items:end;gap:20px;margin-bottom:17px}.section-head h2{font-size:28px;margin:0}.section-head p{color:var(--muted);max-width:720px;margin:4px 0 0}.priority-grid{grid-template-columns:repeat(2,1fr)}.priority-card{display:grid;grid-template-columns:43px 1fr;gap:15px;padding:18px;background:var(--panel);border:1px solid var(--line);border-radius:13px}.priority-number{width:38px;height:38px;border-radius:10px;display:grid;place-items:center;background:#192e42;color:var(--cyan);font-weight:850}.priority-meta{font-size:11px;color:var(--amber);text-transform:uppercase;letter-spacing:.09em}.priority-card h3{margin:3px 0 5px;font-size:17px}.priority-card p{color:var(--muted);font-size:13px;margin:0 0 10px}.next-step{font-size:13px}.toolbar{display:grid;grid-template-columns:1.3fr repeat(2,.65fr);gap:10px;margin-bottom:12px}input,select{width:100%;background:#091725;color:var(--text);border:1px solid var(--line);border-radius:9px;padding:11px 12px;outline:none}input:focus,select:focus{border-color:var(--cyan)}.table-wrap{overflow:auto;border:1px solid var(--line);border-radius:14px;background:var(--panel)}table{border-collapse:collapse;width:100%;min-width:1150px;font-size:13px}th{position:sticky;top:60px;background:#102337;color:#a8bac9;text-align:left;text-transform:uppercase;letter-spacing:.06em;font-size:10px;padding:13px;border-bottom:1px solid var(--line)}td{padding:14px 13px;border-bottom:1px solid var(--line);vertical-align:top;max-width:330px}tr:hover td{background:rgba(54,215,215,.025)}.finding-name{font-weight:750}.category-label{color:var(--muted);font-size:11px;margin-top:3px}.status,.severity{display:inline-block;border-radius:999px;padding:4px 9px;font-weight:750;font-size:10px;text-transform:uppercase;letter-spacing:.04em}.status-pass{color:var(--green);background:rgba(72,213,151,.1)}.status-warn{color:var(--amber);background:rgba(247,186,82,.1)}.status-fail{color:var(--red);background:rgba(255,101,119,.1)}.status-info,.status-unknown{color:var(--blue);background:rgba(106,169,255,.1)}.severity-critical,.severity-high{color:var(--red)}.severity-medium{color:var(--amber)}.severity-low,.severity-informational{color:var(--muted)}details summary{color:var(--cyan);cursor:pointer}details code{display:block;white-space:normal;color:#b8c8d6;margin-top:7px;font-size:11px}.signal-grid{grid-template-columns:repeat(6,1fr)}.signal{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:16px}.signal b{display:block;font-size:27px}.signal span{color:var(--muted);font-size:11px}.awareness-grid{grid-template-columns:repeat(3,1fr)}.awareness-card{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:20px}.awareness-card .icon{font-size:24px}.awareness-card h3{margin:9px 0 7px}.awareness-card ul{padding-left:18px;color:var(--muted);font-size:13px}.callout{border-left:3px solid var(--cyan);padding:14px 17px;background:rgba(54,215,215,.06);border-radius:0 9px 9px 0}.quiz{max-width:900px}.question{padding:18px 0;border-bottom:1px solid var(--line)}.question h3{font-size:15px}.option{display:block;padding:9px 12px;margin:7px 0;background:#0a1928;border:1px solid var(--line);border-radius:8px;cursor:pointer}.option:hover{border-color:var(--cyan)}.quiz-result{margin-top:16px;padding:16px;border-radius:10px;background:#0a1928;display:none}.two-col{grid-template-columns:1fr 1fr}.facts{display:grid;grid-template-columns:170px 1fr;gap:8px 18px;font-size:13px}.facts dt{color:var(--muted)}.facts dd{margin:0;overflow-wrap:anywhere}.errors{color:var(--muted);font-size:12px}.errors li{margin:5px 0}.empty-state{grid-column:1/-1;padding:28px;border:1px dashed var(--line);border-radius:12px;color:var(--muted)}footer{border-top:1px solid var(--line);color:var(--muted);font-size:12px;padding:32px 0 50px;margin-top:50px}.hide{display:none!important}.print-only{display:none}
@media(max-width:1100px){.summary-grid{grid-template-columns:1fr 1fr 1fr}.score-card{grid-column:1/-1}.signal-grid{grid-template-columns:repeat(3,1fr)}.awareness-grid{grid-template-columns:1fr 1fr}}
@media(max-width:720px){nav{display:none}.hero{padding-top:36px}.summary-grid,.priority-grid,.awareness-grid,.two-col{grid-template-columns:1fr}.score-card{grid-template-columns:1fr;text-align:center}.score-ring{margin:auto}.signal-grid{grid-template-columns:1fr 1fr}.toolbar{grid-template-columns:1fr}.facts{grid-template-columns:1fr}.facts dd{margin-bottom:7px}}
@media print{body{background:white;color:#111}.topbar,.toolbar,.quiz,.button{display:none!important}.container{width:100%}.card,.priority-card,.awareness-card,.signal,.table-wrap{box-shadow:none;background:white;border-color:#ccc}.hero{padding:20px 0}.hero p,.metric small,.section-head p,.priority-card p,.awareness-card ul,.facts dt,.errors{color:#444}.score-ring{background:#eee;border:8px solid #333}.score-ring:after{background:white}.print-only{display:block}section{break-inside:avoid}table{font-size:10px;min-width:0}th{position:static;background:#eee;color:#111}td{padding:7px;max-width:none}.status,.severity{border:1px solid #999;color:#111;background:white}}
'@

$scriptJs = @'
function filterFindings(){
  const q=document.getElementById('findingSearch').value.toLowerCase();
  const status=document.getElementById('statusFilter').value;
  const category=document.getElementById('categoryFilter').value;
  let visible=0;
  document.querySelectorAll('#findingsBody tr').forEach(row=>{
    const matchText=!q||row.dataset.search.toLowerCase().includes(q);
    const matchStatus=!status||row.dataset.status===status;
    const matchCategory=!category||row.dataset.category===category;
    const show=matchText&&matchStatus&&matchCategory;
    row.classList.toggle('hide',!show); if(show) visible++;
  });
  document.getElementById('visibleCount').textContent=visible;
}
function gradeQuiz(){
  const answers={q1:'b',q2:'c',q3:'b',q4:'c',q5:'a'}; let score=0; let answered=0;
  Object.keys(answers).forEach(q=>{const choice=document.querySelector('input[name="'+q+'"]:checked');if(choice){answered++;if(choice.value===answers[q])score++;}});
  const box=document.getElementById('quizResult');box.style.display='block';
  if(answered<5){box.innerHTML='<strong>Complete all five questions.</strong> You have answered '+answered+' of 5.';return;}
  const message=score===5?'Excellent - you recognized the safest response in every scenario.':score>=4?'Strong result - review the missed scenario before closing the report.':'Review the awareness guidance above and retake the knowledge check.';
  box.innerHTML='<strong>'+score+'/5 correct.</strong> '+message;
}
function toggleTheme(){document.body.classList.toggle('light');}
document.addEventListener('DOMContentLoaded',()=>{
  ['findingSearch','statusFilter','categoryFilter'].forEach(id=>document.getElementById(id).addEventListener(id==='findingSearch'?'input':'change',filterFindings));
  document.getElementById('visibleCount').textContent=document.querySelectorAll('#findingsBody tr').length;
});
'@

$generatedAt = Get-Date
$duration = [math]::Round(($generatedAt - $reportStarted).TotalSeconds, 1)
$categories = @($orderedFindings.Category | Sort-Object -Unique)
$categoryOptions = ($categories | ForEach-Object { '<option value="{0}">{0}</option>' -f (ConvertTo-HtmlSafe $_) }) -join "`n"
$osVersionDisplay = if ($os) { "{0} / {1}" -f $os.Version, $osBuild } else { 'Unknown' }
$biosDisplay = if ($bios) { "{0} / {1}" -f $bios.Manufacturer, $bios.SMBIOSBIOSVersion } else { 'Unknown' }
$bootDisplay = if ($bootTime) { $bootTime.ToString('yyyy-MM-dd HH:mm:ss') } else { 'Unknown' }
$domainDisplay = if ($computer) { [string]$computer.Domain } else { 'Unknown' }
$powerShellDisplay = $PSVersionTable.PSVersion.ToString()

$html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="dark">
<title>Security Awareness Dashboard - $(ConvertTo-HtmlSafe $env:COMPUTERNAME)</title>
<style>$style</style>
</head>
<body>
<header class="topbar"><div class="container topbar-inner">
  <div class="brand"><div class="brandmark">&#9670;</div><span>SECURITY POSTURE</span></div>
  <nav><a href="#overview">Overview</a><a href="#priorities">Priorities</a><a href="#findings">Findings</a><a href="#signals">Signals</a><a href="#awareness">Awareness</a></nav>
  <button class="button" onclick="window.print()">Print / PDF</button>
</div></header>

<main class="container">
<section class="hero" id="overview">
  <div class="eyebrow">$(ConvertTo-HtmlSafe $Organization) &middot; Endpoint Assessment</div>
  <h1>Security Awareness &amp; Endpoint Posture Dashboard</h1>
  <p>A point-in-time, read-only view of local security controls, observable risk, recent defensive signals, and the human actions that reduce the likelihood and impact of compromise.</p>
  <div class="meta-strip">
    <span class="chip">Computer: $(ConvertTo-HtmlSafe $env:COMPUTERNAME)</span>
    <span class="chip">User: $(ConvertTo-HtmlSafe ("{0}\{1}" -f $env:USERDOMAIN,$env:USERNAME))</span>
    <span class="chip">Generated: $($generatedAt.ToString('yyyy-MM-dd HH:mm:ss zzz'))</span>
    <span class="chip">Event window: $DaysToAnalyze days</span>
    <span class="chip">Elevated: $isAdmin</span>
  </div>
</section>

<div class="grid summary-grid">
  <article class="card score-card"><div class="score-ring" style="--score:$score"><div class="score-value">$score<small>/ 100 &middot; Grade $grade</small></div></div><div class="score-copy"><h2>$riskLabel</h2><p>The score summarizes weighted local configuration checks. Unknown checks are excluded, and the result is not a guarantee of security or compliance.</p></div></article>
  <article class="card metric"><div class="metric-label">Passing controls</div><div class="metric-value pass-text">$($statusCounts.Pass)</div><small>Observed as configured or healthy</small></article>
  <article class="card metric"><div class="metric-label">Warnings</div><div class="metric-value warn-text">$($statusCounts.Warn)</div><small>Review context and hardening options</small></article>
  <article class="card metric"><div class="metric-label">Failed controls</div><div class="metric-value fail-text">$($statusCounts.Fail)</div><small>Prioritize validation and remediation</small></article>
  <article class="card metric"><div class="metric-label">Unknown checks</div><div class="metric-value unknown-text">$($statusCounts.Unknown)</div><small>Unavailable, unsupported, or restricted</small></article>
</div>

<section id="priorities">
  <div class="section-head"><div><h2>Prioritized action plan</h2><p>Failed and warning checks are ordered by status and severity. Validate business context before changing managed systems.</p></div></div>
  <div class="grid priority-grid">$priorityCards</div>
</section>

<section id="findings">
  <div class="section-head"><div><h2>Detailed control findings</h2><p>Search and filter the evidence. A passing configuration is a useful signal, not proof that the control is effective against every threat.</p></div><div><span id="visibleCount">0</span> visible / $($orderedFindings.Count) total</div></div>
  <div class="toolbar">
    <input id="findingSearch" type="search" placeholder="Search control, finding, evidence, or recommendation..." aria-label="Search findings">
    <select id="statusFilter" aria-label="Filter by status"><option value="">All statuses</option><option>Fail</option><option>Warn</option><option>Pass</option><option>Unknown</option><option>Info</option></select>
    <select id="categoryFilter" aria-label="Filter by category"><option value="">All categories</option>$categoryOptions</select>
  </div>
  <div class="table-wrap"><table><thead><tr><th>Status</th><th>Severity</th><th>Control</th><th>Finding</th><th>Recommendation</th><th>Evidence</th></tr></thead><tbody id="findingsBody">$findingRows</tbody></table></div>
</section>

<section id="signals">
  <div class="section-head"><div><h2>Recent Windows security signals</h2><p>Counts from the previous $DaysToAnalyze day(s). These require appropriate audit policy and log access; zero may mean no events or insufficient telemetry.</p></div></div>
  <div class="grid signal-grid">
    <article class="signal"><b>$($eventSummary.FailedLogons)</b><span>Failed logons &middot; 4625</span></article>
    <article class="signal"><b>$($eventSummary.AccountLockouts)</b><span>Account lockouts &middot; 4740</span></article>
    <article class="signal"><b>$($eventSummary.ExplicitCredentials)</b><span>Explicit credentials &middot; 4648</span></article>
    <article class="signal"><b>$($eventSummary.NewProcesses)</b><span>New process audits &middot; 4688</span></article>
    <article class="signal"><b>$($eventSummary.AuditLogCleared)</b><span>Audit log cleared &middot; 1102</span></article>
    <article class="signal"><b>$($eventSummary.DefenderDetections)</b><span>Defender detections &middot; 1116</span></article>
  </div>
  <div class="callout" style="margin-top:16px"><strong>Interpretation:</strong> Event counts need baselines. A spike in failed logons may be user error, a stale service credential, password spraying, or another cause. Correlate user, source address, logon type, time, endpoint, and related alerts before drawing a conclusion.</div>
</section>

<section id="awareness">
  <div class="section-head"><div><h2>Security awareness playbook</h2><p>Technology reduces exposure; user decisions frequently determine whether an attempted compromise succeeds.</p></div></div>
  <div class="grid awareness-grid">
    <article class="awareness-card"><div class="icon">&#9993;</div><h3>Phishing &amp; social engineering</h3><ul><li>Pause when a message creates urgency, fear, secrecy, or unusual authority.</li><li>Inspect the actual sender domain and link destination; do not trust display names.</li><li>Verify payment, credential, MFA, and data requests through a known second channel.</li><li>Report suspicious messages using the approved process; do not forward them casually.</li></ul></article>
    <article class="awareness-card"><div class="icon">&#9906;</div><h3>Passwords &amp; MFA</h3><ul><li>Use a password manager and a unique, randomly generated password for every account.</li><li>Prefer phishing-resistant passkeys or hardware security keys where supported.</li><li>Never approve an unexpected MFA prompt or share a one-time code.</li><li>Report unexpected password-reset or account-recovery notifications immediately.</li></ul></article>
    <article class="awareness-card"><div class="icon">&#8679;</div><h3>Updates &amp; applications</h3><ul><li>Install operating-system, browser, application, and firmware updates promptly.</li><li>Install software only from approved sources; reject unsolicited remote-support tools.</li><li>Remove unused applications, browser extensions, and stale accounts.</li><li>Restart when requested so servicing and security updates can complete.</li></ul></article>
    <article class="awareness-card"><div class="icon">&#9635;</div><h3>Data handling</h3><ul><li>Store sensitive data only in approved locations with the correct access controls.</li><li>Confirm recipients before sending and minimize attachments containing sensitive data.</li><li>Encrypt portable devices and use approved secure-sharing methods.</li><li>Do not enter confidential data into public AI tools without explicit authorization.</li></ul></article>
    <article class="awareness-card"><div class="icon">&#8962;</div><h3>Remote work &amp; physical security</h3><ul><li>Lock the screen whenever the device is unattended.</li><li>Avoid unknown USB devices and protect equipment from theft or shoulder surfing.</li><li>Use trusted networks and the approved VPN or zero-trust access method.</li><li>Do not leave credentials, badges, recovery keys, or sensitive papers exposed.</li></ul></article>
    <article class="awareness-card"><div class="icon">!</div><h3>Report early</h3><ul><li>Report lost devices, mistaken data sharing, suspicious prompts, and possible malware quickly.</li><li>Disconnect from networks if active compromise is suspected, but do not erase evidence.</li><li>Record what happened, when, the account/device involved, and actions already taken.</li><li>Fast reporting limits impact; uncertainty is a reason to escalate, not wait.</li></ul></article>
  </div>
</section>

<section>
  <div class="section-head"><div><h2>Five-question knowledge check</h2><p>Use the scenarios to reinforce the safest default behavior.</p></div></div>
  <div class="card quiz">
    <div class="question"><h3>1. An executive emails an urgent request to buy gift cards and keep it confidential. What is the best first action?</h3><label class="option"><input type="radio" name="q1" value="a"> Comply quickly because the request came from leadership.</label><label class="option"><input type="radio" name="q1" value="b"> Verify through a known, independent channel and report the message.</label><label class="option"><input type="radio" name="q1" value="c"> Reply to the email asking whether it is legitimate.</label></div>
    <div class="question"><h3>2. You receive an MFA prompt you did not initiate. What should you do?</h3><label class="option"><input type="radio" name="q2" value="a"> Approve it once to stop repeated prompts.</label><label class="option"><input type="radio" name="q2" value="b"> Ignore it permanently.</label><label class="option"><input type="radio" name="q2" value="c"> Deny it, secure the account, and report the event.</label></div>
    <div class="question"><h3>3. A known vendor sends a new bank account for an invoice. What is safest?</h3><label class="option"><input type="radio" name="q3" value="a"> Trust the existing email thread.</label><label class="option"><input type="radio" name="q3" value="b"> Validate using a previously known phone number and follow payment-change controls.</label><label class="option"><input type="radio" name="q3" value="c"> Ask the vendor to resend the attachment.</label></div>
    <div class="question"><h3>4. You accidentally entered credentials into a suspicious page. What should happen next?</h3><label class="option"><input type="radio" name="q4" value="a"> Wait to see whether anything happens.</label><label class="option"><input type="radio" name="q4" value="b"> Close the page; no other action is necessary.</label><label class="option"><input type="radio" name="q4" value="c"> Report immediately, change credentials through the trusted site, and follow incident instructions.</label></div>
    <div class="question"><h3>5. Which authentication option offers the strongest phishing resistance?</h3><label class="option"><input type="radio" name="q5" value="a"> A passkey or hardware security key.</label><label class="option"><input type="radio" name="q5" value="b"> SMS one-time codes.</label><label class="option"><input type="radio" name="q5" value="c"> Security questions.</label></div>
    <button class="button" style="margin-top:16px;border-color:var(--cyan);color:var(--cyan)" onclick="gradeQuiz()">Score knowledge check</button><div class="quiz-result" id="quizResult"></div>
  </div>
</section>

<section>
  <div class="grid two-col">
    <article class="card"><h2>System context</h2><dl class="facts"><dt>Operating system</dt><dd>$(ConvertTo-HtmlSafe $osCaption)</dd><dt>Version / build</dt><dd>$(ConvertTo-HtmlSafe $osVersionDisplay)</dd><dt>Hardware</dt><dd>$(ConvertTo-HtmlSafe ("{0} {1}" -f $manufacturer,$model))</dd><dt>BIOS</dt><dd>$(ConvertTo-HtmlSafe $biosDisplay)</dd><dt>Last boot</dt><dd>$(ConvertTo-HtmlSafe $bootDisplay)</dd><dt>Domain / workgroup</dt><dd>$(ConvertTo-HtmlSafe $domainDisplay)</dd><dt>PowerShell</dt><dd>$(ConvertTo-HtmlSafe $powerShellDisplay)</dd><dt>Collection duration</dt><dd>$duration seconds</dd></dl></article>
    <article class="card"><h2>Collection notes</h2><p class="errors">Checks that fail to collect are preserved here for transparency. Common causes include insufficient privileges, unsupported hardware, disabled logs, third-party security products, or unavailable Windows modules.</p><ul class="errors">$collectionErrorHtml</ul></article>
  </div>
</section>
</main>

<footer><div class="container"><strong>Important:</strong> This dashboard is an educational, point-in-time local assessment. It does not test every control, inspect cloud identity, prove compromise, replace EDR/SIEM monitoring, or constitute a compliance certification. Protect the report because it contains system configuration and account metadata.</div></footer>
<script>$scriptJs</script>
</body></html>
"@

try {
    $fullOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    $outputDirectory = Split-Path -Path $fullOutputPath -Parent
    if (-not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($fullOutputPath, $html, (New-Object System.Text.UTF8Encoding($false)))
    $fileInfo = Get-Item -LiteralPath $fullOutputPath
    Write-Host ''
    Write-Host 'Security awareness dashboard created successfully.' -ForegroundColor Green
    Write-Host ("Path:  {0}" -f $fileInfo.FullName) -ForegroundColor Cyan
    Write-Host ("Score: {0}/100 (Grade {1})" -f $score, $grade)
    Write-Host ("Checks: {0} total | {1} pass | {2} warn | {3} fail | {4} unknown" -f $orderedFindings.Count, $statusCounts.Pass, $statusCounts.Warn, $statusCounts.Fail, $statusCounts.Unknown)
    Write-Host 'Reminder: Protect the report; it contains local system and account metadata.' -ForegroundColor Yellow

    if ($OpenReport) { Start-Process -FilePath $fileInfo.FullName }

    [pscustomobject]@{
        Path           = $fileInfo.FullName
        Score          = $score
        Grade          = $grade
        TotalChecks    = $orderedFindings.Count
        Passed         = $statusCounts.Pass
        Warnings       = $statusCounts.Warn
        Failed         = $statusCounts.Fail
        Unknown        = $statusCounts.Unknown
        CollectionErrors = $script:CollectionErrors.Count
    }
}
catch {
    throw "Unable to write the HTML dashboard to '$OutputPath'. $($_.Exception.Message)"
}
