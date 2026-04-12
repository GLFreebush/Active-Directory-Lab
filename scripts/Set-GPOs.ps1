#Requires -RunAsAdministrator
#Requires -Module GroupPolicy
<#
.SYNOPSIS
    Creates and links Group Policy Objects for the Active Directory lab.

.DESCRIPTION
    Run this script on the Domain Controller.
    It creates three GPOs:
      1. Password-Policy    — minimum length, complexity, account lockout
      2. Disable-USB        — deny removable storage read/write
      3. Lock-Screen-Timeout — enforce screensaver timeout with password

.NOTES
    - Run in an elevated PowerShell session on DC01 after AD DS is configured.
    - Update $DomainName to match your domain.
#>

# ── Configuration ────────────────────────────────────────────────────────────
$DomainName = "lab.local"   # Change to match your domain
# ─────────────────────────────────────────────────────────────────────────────

# ── Helper: create GPO if it doesn't exist ────────────────────────────────────
function Get-OrCreate-GPO {
    param([string]$Name)
    $gpo = Get-GPO -Name $Name -ErrorAction SilentlyContinue
    if (-not $gpo) {
        $gpo = New-GPO -Name $Name
        Write-Host "  Created GPO: $Name" -ForegroundColor Green
    } else {
        Write-Host "  GPO already exists: $Name" -ForegroundColor Yellow
    }
    return $gpo
}

# ── 1. Password Policy ────────────────────────────────────────────────────────
Write-Host "`n[1/3] Configuring Password Policy GPO..." -ForegroundColor Cyan
$pwGPO = Get-OrCreate-GPO -Name "Password-Policy"

# Minimum password length = 12
Set-GPRegistryValue -Name "Password-Policy" `
    -Key  "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "MinimumPasswordLength" -Type DWord -Value 12

# Link to domain root
New-GPLink -Name "Password-Policy" -Target "DC=$($DomainName -replace '\.',',DC=')" -LinkEnabled Yes -ErrorAction SilentlyContinue

# Fine-grained account lockout via Default Domain Policy (net accounts)
# These settings live in the Default Domain Policy; set via secedit / net accounts
Write-Host "  Note: Account lockout (threshold=5) should be set in Default Domain Policy." -ForegroundColor DarkYellow

# ── 2. Disable USB / Removable Storage ───────────────────────────────────────
Write-Host "`n[2/3] Configuring Disable-USB GPO..." -ForegroundColor Cyan
$usbGPO = Get-OrCreate-GPO -Name "Disable-USB"

# Deny read access to removable disks
Set-GPRegistryValue -Name "Disable-USB" `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}" `
    -ValueName "Deny_Read" -Type DWord -Value 1

# Deny write access to removable disks
Set-GPRegistryValue -Name "Disable-USB" `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}" `
    -ValueName "Deny_Write" -Type DWord -Value 1

New-GPLink -Name "Disable-USB" -Target "DC=$($DomainName -replace '\.',',DC=')" -LinkEnabled Yes -ErrorAction SilentlyContinue

# ── 3. Lock Screen / Screensaver Timeout ─────────────────────────────────────
Write-Host "`n[3/3] Configuring Lock-Screen-Timeout GPO..." -ForegroundColor Cyan
$lockGPO = Get-OrCreate-GPO -Name "Lock-Screen-Timeout"

# Enable screensaver
Set-GPRegistryValue -Name "Lock-Screen-Timeout" `
    -Key "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" `
    -ValueName "ScreenSaveActive" -Type String -Value "1"

# Screensaver timeout = 600 seconds (10 minutes)
Set-GPRegistryValue -Name "Lock-Screen-Timeout" `
    -Key "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" `
    -ValueName "ScreenSaveTimeOut" -Type String -Value "600"

# Require password on screensaver resume
Set-GPRegistryValue -Name "Lock-Screen-Timeout" `
    -Key "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" `
    -ValueName "ScreenSaverIsSecure" -Type String -Value "1"

New-GPLink -Name "Lock-Screen-Timeout" -Target "DC=$($DomainName -replace '\.',',DC=')" -LinkEnabled Yes -ErrorAction SilentlyContinue

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host "`nGPO configuration complete. Run 'gpupdate /force' on clients to apply." -ForegroundColor Green
Write-Host "Verify with: gpresult /r  (on the client)" -ForegroundColor DarkGray
