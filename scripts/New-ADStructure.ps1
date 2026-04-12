#Requires -RunAsAdministrator
#Requires -Module ActiveDirectory
<#
.SYNOPSIS
    Creates Organizational Units, Security Groups, and Users in Active Directory.

.DESCRIPTION
    Run this script on the Domain Controller after AD DS is installed and the domain is live.
    It creates a standard OU structure (IT, HR, Finance) with groups and sample user accounts.

.NOTES
    - Run in an elevated PowerShell session on DC01.
    - Update $DomainDN and the Users array to match your environment.
#>

# ── Configuration ────────────────────────────────────────────────────────────
$DomainDN       = "DC=lab,DC=local"   # Distinguished name of your domain
$DefaultPassword = (ConvertTo-SecureString "Welcome1!" -AsPlainText -Force)

# OUs to create directly under the domain root
$OUs = @("IT", "HR", "Finance")

# Groups: Name, OU
$Groups = @(
    @{ Name = "IT-Admins";    OU = "IT"      },
    @{ Name = "HR-Staff";     OU = "HR"      },
    @{ Name = "Finance-Team"; OU = "Finance" }
)

# Users: FirstName, LastName, Username, OU, Group
$Users = @(
    @{ First = "Alice"; Last = "Smith";   Sam = "asmith";   OU = "IT";      Group = "IT-Admins"    },
    @{ First = "Bob";   Last = "Jones";   Sam = "bjones";   OU = "HR";      Group = "HR-Staff"     },
    @{ First = "Carol"; Last = "White";   Sam = "cwhite";   OU = "Finance"; Group = "Finance-Team" }
)
# ─────────────────────────────────────────────────────────────────────────────

# ── Create OUs ────────────────────────────────────────────────────────────────
Write-Host "`n[1/3] Creating Organizational Units..." -ForegroundColor Cyan
foreach ($OU in $OUs) {
    $ouPath = "OU=$OU,$DomainDN"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouPath'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $OU -Path $DomainDN
        Write-Host "  Created OU: $OU" -ForegroundColor Green
    } else {
        Write-Host "  OU already exists: $OU" -ForegroundColor Yellow
    }
}

# ── Create Groups ─────────────────────────────────────────────────────────────
Write-Host "`n[2/3] Creating Security Groups..." -ForegroundColor Cyan
foreach ($Group in $Groups) {
    $groupPath = "OU=$($Group.OU),$DomainDN"
    if (-not (Get-ADGroup -Filter "Name -eq '$($Group.Name)'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $Group.Name -GroupScope Global -GroupCategory Security -Path $groupPath
        Write-Host "  Created group: $($Group.Name) in OU=$($Group.OU)" -ForegroundColor Green
    } else {
        Write-Host "  Group already exists: $($Group.Name)" -ForegroundColor Yellow
    }
}

# ── Create Users ──────────────────────────────────────────────────────────────
Write-Host "`n[3/3] Creating User Accounts..." -ForegroundColor Cyan
foreach ($User in $Users) {
    $userPath = "OU=$($User.OU),$DomainDN"
    $upn      = "$($User.Sam)@$($DomainDN -replace 'DC=','' -replace ',','.')"

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($User.Sam)'" -ErrorAction SilentlyContinue)) {
        New-ADUser `
            -GivenName           $User.First `
            -Surname             $User.Last `
            -Name                "$($User.First) $($User.Last)" `
            -SamAccountName      $User.Sam `
            -UserPrincipalName   $upn `
            -Path                $userPath `
            -AccountPassword     $DefaultPassword `
            -Enabled             $true `
            -PasswordNeverExpires $false `
            -ChangePasswordAtLogon $true

        Add-ADGroupMember -Identity $User.Group -Members $User.Sam
        Write-Host "  Created user: $($User.Sam) -> OU=$($User.OU), Group=$($User.Group)" -ForegroundColor Green
    } else {
        Write-Host "  User already exists: $($User.Sam)" -ForegroundColor Yellow
    }
}

Write-Host "`nAD structure setup complete." -ForegroundColor Green
