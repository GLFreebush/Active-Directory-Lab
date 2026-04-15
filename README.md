# Active-Directory-Home-Lab

Hands-on Active Directory home lab documenting user/group management, GPO hardening, and screenshots.

## Lab setup
- Host machine: Mac (Apple Silicon)
- Hypervisor: (Parallels)
- VMs:
  - Domain Controller (Windows Server: DC1 Azure )
  - Client (Windows 11 Pro: Windows 11 )
- Virtual network: (NAT / Host-only)
- Notes:

## What you configured
#Requires -RunAsAdministrator
<#
Active Directory Lab Build Script
- Creates OU structure under the domain root
- Creates role/resource groups
- Creates users and group membership
- Creates SMB share and sets share + NTFS permissions
- Creates and links GPOs:
  - Map H: drive to \\dc2.glfreebush.lab\HR for ROLE_HR
  - Disable Control Panel for ROLE_HR

Run on the Domain Controller (DC2) as a Domain Admin.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Module($name) {
  if (-not (Get-Module -ListAvailable -Name $name)) {
    throw "Missing module: $name. Install the required Windows feature/RSAT component and retry."
  }
}

Assert-Module ActiveDirectory
Import-Module ActiveDirectory

# ---------- Domain / Naming ----------
$domain = Get-ADDomain
$DN = $domain.DistinguishedName
$NetBIOS = $domain.NetBIOSName

# If your DC hostname differs, change these:
$DcFqdn = "dc2.glfreebush.lab"
$ShareRoot = "D:\Shares"
$HrSharePath = Join-Path $ShareRoot "HR"
$HrShareName = "HR"   # visible share name

Write-Host "Domain DN: $DN"
Write-Host "NetBIOS: $NetBIOS"
Write-Host "DC FQDN: $DcFqdn"
Write-Host "HR share path: $HrSharePath"
Write-Host "HR share name: $HrShareName"

# ---------- OU Structure ----------
# Corp
$ouCorp              = "OU=Corp,$DN"
$ouUsers             = "OU=Users,$ouCorp"
$ouUsersHR           = "OU=HR,$ouUsers"
$ouUsersIT           = "OU=IT,$ouUsers"
$ouComputers         = "OU=Computers,$ouCorp"
$ouWorkstations      = "OU=Workstations,$ouComputers"
$ouGroups            = "OU=Groups,$ouCorp"
$ouGroupsRole        = "OU=Role,$ouGroups"
$ouGroupsResource    = "OU=Resource,$ouGroups"

$ouList = @(
  @{ Name="Corp";         Path=$DN },
  @{ Name="Users";        Path=$ouCorp },
  @{ Name="HR";           Path=$ouUsers },
  @{ Name="IT";           Path=$ouUsers },
  @{ Name="Computers";    Path=$ouCorp },
  @{ Name="Workstations"; Path=$ouComputers },
  @{ Name="Groups";       Path=$ouCorp },
  @{ Name="Role";         Path=$ouGroups },
  @{ Name="Resource";     Path=$ouGroups }
)

foreach ($ou in $ouList) {
  $ouDn = "OU=$($ou.Name),$($ou.Path)"
  if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$ouDn)" -ErrorAction SilentlyContinue)) {
    Write-Host "Creating OU: $ouDn"
    New-ADOrganizationalUnit -Name $ou.Name -Path $ou.Path -ProtectedFromAccidentalDeletion $false | Out-Null
  } else {
    Write-Host "OU exists: $ouDn"
  }
}

# ---------- Groups ----------
$groups = @(
  @{ Name="ROLE_HR";           Path=$ouGroupsRole;     Scope="Global"; Category="Security" },
  @{ Name="ROLE_IT";           Path=$ouGroupsRole;     Scope="Global"; Category="Security" },
  @{ Name="RES_HR_SHARE_RW";   Path=$ouGroupsResource; Scope="Global"; Category="Security" },
  @{ Name="RES_HR_SHARE_RO";   Path=$ouGroupsResource; Scope="Global"; Category="Security" }
)

foreach ($g in $groups) {
  if (-not (Get-ADGroup -LDAPFilter "(cn=$($g.Name))" -SearchBase $g.Path -ErrorAction SilentlyContinue)) {
    Write-Host "Creating group: $($g.Name)"
    New-ADGroup -Name $g.Name -SamAccountName $g.Name -GroupScope $g.Scope -GroupCategory $g.Category -Path $g.Path | Out-Null
  } else {
    Write-Host "Group exists: $($g.Name)"
  }
}

# Nest role into resource group (AGDLP-ish)
Write-Host "Nesting ROLE_HR into RES_HR_SHARE_RW"
Add-ADGroupMember -Identity "RES_HR_SHARE_RW" -Members "ROLE_HR" -ErrorAction SilentlyContinue

# ---------- Users ----------
$tempPw = Read-Host -AsSecureString "Enter a temporary password for new users"
$users = @(
  @{ Sam="hr.jane"; Given="Jane"; Surname="HR";   OU=$ouUsersHR; UPN="hr.jane@glfreebush.lab"; Display="Jane (HR)" },
  @{ Sam="hr.tom";  Given="Tom";  Surname="HR";   OU=$ouUsersHR; UPN="hr.tom@glfreebush.lab";  Display="Tom (HR)" },
  @{ Sam="it.alex"; Given="Alex"; Surname="IT";   OU=$ouUsersIT; UPN="it.alex@glfreebush.lab"; Display="Alex (IT)" }
)

foreach ($u in $users) {
  if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.Sam)'" -ErrorAction SilentlyContinue)) {
    Write-Host "Creating user: $($u.Sam)"
    New-ADUser -Name $u.Display `
      -SamAccountName $u.Sam `
      -UserPrincipalName $u.UPN `
      -GivenName $u.Given `
      -Surname $u.Surname `
      -DisplayName $u.Display `
      -Path $u.OU `
      -AccountPassword $tempPw `
      -Enabled $true `
      -ChangePasswordAtLogon $true | Out-Null
  } else {
    Write-Host "User exists: $($u.Sam)"
  }
}

Write-Host "Adding HR users to ROLE_HR"
Add-ADGroupMember -Identity "ROLE_HR" -Members "hr.jane","hr.tom" -ErrorAction SilentlyContinue

Write-Host "Adding IT user to ROLE_IT"
Add-ADGroupMember -Identity "ROLE_IT" -Members "it.alex" -ErrorAction SilentlyContinue

# ---------- Share + NTFS Permissions ----------
Write-Host "Creating share folder: $HrSharePath"
New-Item -ItemType Directory -Path $HrSharePath -Force | Out-Null

# Set NTFS ACL:
# - SYSTEM: Full
# - Domain Admins: Full
# - RES_HR_SHARE_RW: Modify
# Remove inheritance and clear existing explicit rules for a clean demo
Write-Host "Setting NTFS permissions on $HrSharePath"
$acl = Get-Acl $HrSharePath
$acl.SetAccessRuleProtection($true, $false) # disable inheritance, do not preserve inherited rules

# Clear existing rules
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }

$inheritFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
$propFlags    = [System.Security.AccessControl.PropagationFlags]"None"

$ruleSystem = New-Object System.Security.AccessControl.FileSystemAccessRule(
  "SYSTEM","FullControl",$inheritFlags,$propFlags,"Allow"
)
$ruleDA = New-Object System.Security.AccessControl.FileSystemAccessRule(
  "$NetBIOS\Domain Admins","FullControl",$inheritFlags,$propFlags,"Allow"
)
$ruleHRRW = New-Object System.Security.AccessControl.FileSystemAccessRule(
  "$NetBIOS\RES_HR_SHARE_RW","Modify",$inheritFlags,$propFlags,"Allow"
)

$acl.AddAccessRule($ruleSystem) | Out-Null
$acl.AddAccessRule($ruleDA) | Out-Null
$acl.AddAccessRule($ruleHRRW) | Out-Null

Set-Acl -Path $HrSharePath -AclObject $acl

# Create SMB share + permissions
Import-Module SmbShare

if (-not (Get-SmbShare -Name $HrShareName -ErrorAction SilentlyContinue)) {
  Write-Host "Creating SMB share: $HrShareName"
  New-SmbShare -Name $HrShareName -Path $HrSharePath -FullAccess "$NetBIOS\Domain Admins" | Out-Null
} else {
  Write-Host "SMB share exists: $HrShareName"
}

# Share permissions:
# - Authenticated Users: Read
# - RES_HR_SHARE_RW: Change
Write-Host "Setting SMB share permissions on $HrShareName"
# Remove broad defaults, then add what we want (best-effort)
Get-SmbShareAccess -Name $HrShareName | ForEach-Object {
  try { Revoke-SmbShareAccess -Name $HrShareName -AccountName $_.AccountName -Force -Confirm:$false | Out-Null } catch {}
}

Grant-SmbShareAccess -Name $HrShareName -AccountName "Authenticated Users" -AccessRight Read -Force | Out-Null
Grant-SmbShareAccess -Name $HrShareName -AccountName "$NetBIOS\RES_HR_SHARE_RW" -AccessRight Change -Force | Out-Null
Grant-SmbShareAccess -Name $HrShareName -AccountName "$NetBIOS\Domain Admins" -AccessRight Full -Force | Out-Null

# ---------- GPO Creation ----------
# Note: Requires GroupPolicy module (installed on DC)
Assert-Module GroupPolicy
Import-Module GroupPolicy

$gpoMap = "USR-Map-HDrive-HR"
$gpoCP  = "USR-Disable-ControlPanel-HR"

# Create if missing
if (-not (Get-GPO -Name $gpoMap -ErrorAction SilentlyContinue)) {
  Write-Host "Creating GPO: $gpoMap"
  New-GPO -Name $gpoMap | Out-Null
} else { Write-Host "GPO exists: $gpoMap" }

if (-not (Get-GPO -Name $gpoCP -ErrorAction SilentlyContinue)) {
  Write-Host "Creating GPO: $gpoCP"
  New-GPO -Name $gpoCP | Out-Null
} else { Write-Host "GPO exists: $gpoCP" }

# Link GPOs to HR Users OU (this targets HR users cleanly)
Write-Host "Linking GPOs to OU=HR"
New-GPLink -Name $gpoMap -Target $ouUsersHR -Enforced:$false -ErrorAction SilentlyContinue | Out-Null
New-GPLink -Name $gpoCP  -Target $ouUsersHR -Enforced:$false -ErrorAction SilentlyContinue | Out-Null

# Security filtering: apply only to ROLE_HR (remove Authenticated Users apply)
Write-Host "Security filtering GPOs to ROLE_HR"
# Remove Authenticated Users "Apply group policy"
try { Set-GPPermissions -Name $gpoMap -TargetName "Authenticated Users" -TargetType Group -PermissionLevel None } catch {}
try { Set-GPPermissions -Name $gpoCP  -TargetName "Authenticated Users" -TargetType Group -PermissionLevel None } catch {}

Set-GPPermissions -Name $gpoMap -TargetName "ROLE_HR" -TargetType Group -PermissionLevel GpoApply | Out-Null
Set-GPPermissions -Name $gpoCP  -TargetName "ROLE_HR" -TargetType Group -PermissionLevel GpoApply | Out-Null

# GPO setting: Disable Control Panel
# User Config -> Administrative Templates -> Control Panel -> Prohibit access to Control Panel and PC settings
Write-Host "Configuring Control Panel restriction in $gpoCP"
$regKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
Set-GPRegistryValue -Name $gpoCP -Key $regKey -ValueName "NoControlPanel" -Type DWord -Value 1 | Out-Null

# Drive mapping via registry is not ideal; best practice is Group Policy Preferences (Drive Maps).
# GPP Drive Maps isn't directly supported by simple Set-GPRegistryValue.
# We'll create the share + document GUI step OR you can import a GPP XML preference item.
Write-Warning @"
Drive mapping should be done with Group Policy Preferences:
User Configuration -> Preferences -> Windows Settings -> Drive Maps
Map H: to \\$DcFqdn\$HrShareName
Item-level targeting: Security Group = ROLE_HR

This script created the GPO and linked/filtered it. Configure the Drive Map in GPMC (2-minute step) for best results.
"@

Write-Host "DONE."
Write-Host "Next: On Windows 11, sign in as GLFREEBUSH\\hr.jane and run: gpupdate /force"
Write-Host "Then verify: H: drive mapping + Control Panel blocked + share access."
### Active Directory
- Domain name:
- OU structure:
- Users created:
- Groups created:

### Group Policy (GPO)
- GPOs created/linked:
- Settings configured:

## What you learned
-
-
-

## Screenshots
Add screenshots in the `Screenshots/` folder and reference them here:
- User creation: `Screenshots/user-creation.png`
- Group setup: `Screenshots/group-setup.png`
- GPO settings: `Screenshots/gpo-settings.png`
