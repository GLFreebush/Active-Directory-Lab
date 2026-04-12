#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs Active Directory Domain Services and promotes the server to a Domain Controller.

.DESCRIPTION
    Run this script on a fresh Windows Server VM (DC01).
    It installs the AD DS role, then promotes the server to a new forest Domain Controller.

.NOTES
    - Run in an elevated PowerShell session on the Windows Server VM.
    - The server will reboot automatically after promotion.
    - Update $DomainName and $SafeModePassword before running.
#>

# ── Configuration ────────────────────────────────────────────────────────────
$DomainName      = "lab.local"          # Change to your desired domain
$DomainNetBIOS   = "LAB"                # NetBIOS name (usually first segment of domain)
$SafeModePassword = (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force)
# ─────────────────────────────────────────────────────────────────────────────

Write-Host "`n[1/3] Installing AD DS role..." -ForegroundColor Cyan
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Write-Host "`n[2/3] Importing AD DS Deployment module..." -ForegroundColor Cyan
Import-Module ADDSDeployment

Write-Host "`n[3/3] Promoting server to Domain Controller (new forest: $DomainName)..." -ForegroundColor Cyan
Install-ADDSForest `
    -DomainName                    $DomainName `
    -DomainNetbiosName             $DomainNetBIOS `
    -SafeModeAdministratorPassword $SafeModePassword `
    -InstallDns                    `
    -Force                         `
    -NoRebootOnCompletion:$false    # Server will reboot automatically

Write-Host "`nDomain Controller promotion complete. The server will reboot now." -ForegroundColor Green
