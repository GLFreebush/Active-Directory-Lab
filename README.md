# Active-Directory-Home-Lab

Hands-on Active Directory home lab documenting user/group management, GPO hardening, and screenshots.

---

## Lab Setup

| Component       | Details                              |
|-----------------|--------------------------------------|
| Host machine    | Mac (Apple Silicon)                  |
| Hypervisor      | Parallels / VMware Fusion            |
| DC VM           | Windows Server 2022 (Evaluation)     |
| Client VM       | Windows 11 Pro                       |
| Virtual network | Host-only / Internal                 |
| DC Hostname     | DC01                                 |
| DC Static IP    | 192.168.x.x *(fill in)*              |
| Domain name     | lab.local *(fill in)*                |

---

## Step-by-Step Progress

### Step 1 — Windows Server VM
- [ ] Downloaded Windows Server 2022 evaluation ISO
- [ ] Created VM in hypervisor
- [ ] Installed Windows Server, set Administrator password
- [ ] Set static IP and hostname (`DC01`)

### Step 2 — Active Directory Domain Services
- [ ] Installed AD DS role via Server Manager
- [ ] Promoted server to Domain Controller (new forest: `lab.local`)
- [ ] Rebooted and verified domain is live

### Step 3 — Virtual Network Configuration
- [ ] Both VMs placed on same virtual network
- [ ] Windows 11 DNS pointed to DC's static IP

### Step 4 — Domain Join (Windows 11)
- [ ] Joined Windows 11 client to `lab.local` domain
- [ ] Verified login with domain user account

### Step 5 — OUs, Users & Groups
- [ ] Created OUs: `IT`, `HR`, `Finance`
- [ ] Created user accounts (see table below)
- [ ] Created security groups and assigned members

### Step 6 — Group Policy (GPO)
- [ ] Password policy GPO created and linked
- [ ] USB restriction GPO configured
- [ ] Lock screen timeout GPO configured
- [ ] Verified with `gpupdate /force` on client

### Step 7 — Documentation & Screenshots
- [ ] Screenshots added to `Screenshots/` folder
- [ ] README filled in with final details

---

## Active Directory Configuration

### Domain
- **Domain name:** `lab.local` *(update as needed)*
- **Domain Controller:** `DC01`

### OU Structure
```
lab.local
├── IT
├── HR
└── Finance
```

### Users Created

| Username     | Full Name       | OU       | Group        |
|--------------|-----------------|----------|--------------|
| *(fill in)*  | *(fill in)*     | IT       | IT-Admins    |
| *(fill in)*  | *(fill in)*     | HR       | HR-Staff     |
| *(fill in)*  | *(fill in)*     | Finance  | Finance-Team |

### Groups Created

| Group Name   | Scope  | OU       |
|--------------|--------|----------|
| IT-Admins    | Global | IT       |
| HR-Staff     | Global | HR       |
| Finance-Team | Global | Finance  |

---

## Group Policy (GPO)

| GPO Name            | Linked To    | Settings                                   |
|---------------------|--------------|--------------------------------------------|
| Password-Policy     | lab.local    | Min length 12, complexity on, lockout 5    |
| Disable-USB         | lab.local    | Deny removable storage read/write          |
| Lock-Screen-Timeout | lab.local    | Screen saver timeout 10 min, password req  |

---

## What You Learned
- 
- 
- 

---

## Scripts

Automation scripts are in the `scripts/` folder:

| Script                        | Purpose                                      |
|-------------------------------|----------------------------------------------|
| `scripts/Install-ADDS.ps1`    | Install AD DS role and promote to DC         |
| `scripts/New-ADStructure.ps1` | Create OUs, users, and groups                |
| `scripts/Set-GPOs.ps1`        | Configure and link Group Policy Objects      |

---

## Screenshots

| Description          | File                                        |
|----------------------|---------------------------------------------|
| DC promotion wizard  | `Screenshots/setup/dc-promotion.png`        |
| OU structure         | `Screenshots/ad/ou-structure.png`           |
| User creation        | `Screenshots/ad/user-creation.png`          |
| Group membership     | `Screenshots/ad/group-membership.png`       |
| GPO password policy  | `Screenshots/gpo/gpo-password-policy.png`   |
| GPO USB restriction  | `Screenshots/gpo/gpo-usb-restriction.png`   |
| GPO lock screen      | `Screenshots/gpo/gpo-lock-screen.png`       |
| Domain join          | `Screenshots/client/domain-join.png`        |
| Domain login         | `Screenshots/client/domain-login.png`       |
