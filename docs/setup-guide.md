# Active Directory Home Lab — Setup Guide

Step-by-step instructions for building the lab from scratch on a Mac (Apple Silicon) host.

---

## Prerequisites

- Mac with Apple Silicon and at least **16 GB RAM** (8 GB minimum)
- Hypervisor: [Parallels Desktop](https://www.parallels.com/) or [VMware Fusion](https://www.vmware.com/products/fusion.html)
- [Windows Server 2022 Evaluation ISO](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022) (free 180-day trial)
- Windows 11 Pro VM (already running)

---

## Step 1 — Create the Windows Server VM (DC01)

1. In your hypervisor, create a **new VM**:
   - OS: Windows Server 2022
   - RAM: 2–4 GB
   - Disk: 60 GB (dynamic)
   - Network: same virtual network as Windows 11 VM (Host-only or Internal)
2. Mount the Windows Server ISO and install (Desktop Experience edition recommended)
3. Set a strong **Administrator password** (e.g., `P@ssw0rd123!`)
4. After installation, set the hostname to **DC01**:
   ```powershell
   Rename-Computer -NewName "DC01" -Restart
   ```
5. Assign a **static IP** (example for 192.168.100.x network):
   ```powershell
   New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.100.10 `
       -PrefixLength 24 -DefaultGateway 192.168.100.1
   Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1
   ```

---

## Step 2 — Install AD DS & Promote to Domain Controller

Run [`scripts/Install-ADDS.ps1`](../scripts/Install-ADDS.ps1) in an elevated PowerShell session on DC01,  
**or** follow the manual steps below:

1. Open **Server Manager → Manage → Add Roles and Features**
2. Select **Active Directory Domain Services** → Install
3. Click the notification flag → **Promote this server to a domain controller**
4. Choose **Add a new forest**, enter `lab.local`
5. Set the **DSRM password** and complete the wizard
6. The server will reboot automatically

**Verify:** After reboot, open **Active Directory Users and Computers** — you should see `lab.local`.

---

## Step 3 — Configure the Virtual Network

### On DC01
- Static IP: `192.168.100.10` (or whatever you chose in Step 1)
- DNS: `127.0.0.1`

### On Windows 11 Client
Change DNS to point to the DC:
```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.100.10
```

**Verify connectivity:**
```powershell
ping DC01.lab.local
nslookup lab.local
```

---

## Step 4 — Join Windows 11 to the Domain

On the Windows 11 VM:

**Option A — GUI:**  
Settings → System → About → **Domain or Workgroup** → Change → Domain → `lab.local`  
Authenticate with `LAB\Administrator`, then reboot.

**Option B — PowerShell:**
```powershell
Add-Computer -DomainName "lab.local" -Credential (Get-Credential) -Restart
```

**Verify:** Log in with a domain account: `lab\asmith` (once users are created).

---

## Step 5 — Create OUs, Users & Groups

Run [`scripts/New-ADStructure.ps1`](../scripts/New-ADStructure.ps1) on DC01 in an elevated PowerShell session.

This creates:
- **OUs:** IT, HR, Finance
- **Groups:** IT-Admins, HR-Staff, Finance-Team
- **Users:** asmith (IT), bjones (HR), cwhite (Finance)

All users are created with `ChangePasswordAtLogon = $true`.

**Verify in ADUC:**
```
lab.local
├── IT
│   ├── Alice Smith (asmith)
│   └── IT-Admins
├── HR
│   ├── Bob Jones (bjones)
│   └── HR-Staff
└── Finance
    ├── Carol White (cwhite)
    └── Finance-Team
```

---

## Step 6 — Configure Group Policy

Run [`scripts/Set-GPOs.ps1`](../scripts/Set-GPOs.ps1) on DC01 in an elevated PowerShell session.

This creates and links:

| GPO                 | Key Settings                                           |
|---------------------|--------------------------------------------------------|
| `Password-Policy`   | Min length 12, complexity enforced, lockout after 5   |
| `Disable-USB`       | Deny read/write on removable storage devices          |
| `Lock-Screen-Timeout` | Screensaver at 10 min, password required on resume  |

**Apply and verify on client:**
```powershell
gpupdate /force
gpresult /r
```

---

## Step 7 — Screenshots

Take screenshots at each milestone and place them in the `Screenshots/` folder:

| Screenshot                           | Save as                                     |
|--------------------------------------|---------------------------------------------|
| DC promotion wizard                  | `Screenshots/setup/dc-promotion.png`        |
| AD Users and Computers - OU tree     | `Screenshots/ad/ou-structure.png`           |
| New user dialog                      | `Screenshots/ad/user-creation.png`          |
| Group members tab                    | `Screenshots/ad/group-membership.png`       |
| GPO password policy settings         | `Screenshots/gpo/gpo-password-policy.png`   |
| GPO USB restriction settings         | `Screenshots/gpo/gpo-usb-restriction.png`   |
| GPO screensaver settings             | `Screenshots/gpo/gpo-lock-screen.png`       |
| Windows 11 domain join dialog        | `Screenshots/client/domain-join.png`        |
| Domain user login on Windows 11      | `Screenshots/client/domain-login.png`       |

---

## Troubleshooting

| Problem                        | Fix                                                             |
|--------------------------------|-----------------------------------------------------------------|
| Can't ping DC from client      | Check both VMs are on the same virtual network                 |
| Domain join fails              | Verify DNS on client points to DC's IP; try `nslookup lab.local` |
| GPO not applying               | Run `gpupdate /force`; check `gpresult /r` for errors          |
| AD DS install fails            | Ensure Windows Server is activated or using evaluation edition |
| ADUC not opening               | Run `dsa.msc` or install RSAT tools                            |
