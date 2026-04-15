# Active Directory Home Lab

This project documents a hands-on Active Directory lab, including user, group, and OU management, GPO hardening, delegation, and share access. The repo is designed to demonstrate practical AD and Windows Server skills.

---

## Lab Setup
- **Host machine:** Mac (Apple Silicon)
- **Hypervisor:** Parallels
- **VMs:**
  - DC1 (Domain Controller, Windows Server)
  - Windows 11 (client)
- **Network:** NAT/Host-only

---

## What’s Configured

- Custom OU structure (`GLF-Users`, `GLF-Computers`, `GLF-Groups`)
- Users, security groups, and delegation
- SMB share with group-based permissions
- GPOs: mapped network drives, restricted Control Panel, etc.

---

## How to Reproduce

Full PowerShell automation and command history in [`scripts/build-lab.ps1`](scripts/build-lab.ps1).

---

## Key Screenshots

| Description                                  | Screenshot                                            |
|-----------------------------------------------|-------------------------------------------------------|
| OU Structure                                 | ![OU structure](Screenshots/Screenshot%20Show%20the%20OU%20Structure.png)        |
| Users in GLF-Users OU                        | ![List users](Screenshots/Screenshot%20List%20Users%20and%20Computers%20in%20Their%20OUs.png) |
| Group Membership                             | ![Group membership](Screenshots/Screenshot%20Group%20Membership.png)             |
| User Properties                              | ![User properties](Screenshots/Screenshot%20Show%20User%20Properties%201.png)    |
| GPO List                                     | ![GPO list](Screenshots/Screenshot%20%20GPO%20List.png)                          |
| GPO Linked to OU                             | ![GPO linked](Screenshots/Screenshot%20GPO%20Linked%20to%20GLF-Users%20OU.png)   |
| Delegated Controls                           | ![Delegation](Screenshots/Screenshot%20Show%20Delegated%20Controls.png)          |
| Share Permissions                            | ![Share perms](Screenshots/Screenshot%20Share%20Folder%20Permissions%20Proof%20Only.png)    |
| Password Change at Next Logon (proof)        | ![Password change](Screenshots/Screenshot%20Password%20Change%20at%20Next%20Logon.png)      |

---

## What I Learned

- Automated OU, user, group, and GPO management with PowerShell
- Group-based access control and delegation

---

## How to Run (in Lab)

- Run the [Setup Script](scripts/build-lab.ps1) on your Domain Controller.
- Log in as created users on the client, test permissions and policies.

---
