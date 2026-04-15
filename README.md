# Active Directory Home Lab

This repository documents a hands-on Active Directory lab environment, showcasing user/group/OU management, GPO hardening, delegation, and share access. It’s designed to demonstrate practical AD and Windows Server skills for employers.

---

## Lab Setup

- **Host machine:** Mac (Apple Silicon)
- **Hypervisor:** Parallels
- **VMs:**
  - `DC2` (Windows Server - Domain Controller)
  - `Windows 11` (Client)
- **Network:** NAT/Host-only

---

## What’s Configured

- Custom OU structure (`GLF-Users`, `GLF-Computers`, `GLF-Groups`)
- Users, security groups, and group membership
- SMB share with group-based permissions
- GPOs for drive mapping, restricting Control Panel, etc.
- Delegated permissions on OUs

---

## Running the Lab

1. Clone this repository.
2. On your DC VM, see [`scripts/build-lab.ps1`](scripts/build-lab.ps1) for a setup script and sample PowerShell commands.
3. Log in as created users on the client. Test group permissions and policy enforcement.

---

## Key Screenshots

| Description                          | Screenshot                                                      |
|---------------------------------------|-----------------------------------------------------------------|
| OU Structure                         | ![OU structure](Screenshots/Screenshot%20Show%20the%20OU%20Structure.png) |
| List computers in GLF-Computers OU    | ![Computers](Screenshots/Screenshot%20List%20Computers%20In%20GLF-Computers%20OU.png) |
| List users in GLF-Users OU            | ![Users](Screenshots/Screenshot%20List%20Users%20and%20Computers%20in%20Their%20OUs.png) |
| Group Membership                      | ![Group membership](Screenshots/Screenshot%20Group%20Membership.png) |
| User Properties                       | ![User properties 1](Screenshots/Screenshot%20Show%20User%20Properties%201.png) ![User properties 2](Screenshots/Screenshot%20Show%20User%20Properties%202.png) |
| GPO List                              | ![GPO List](Screenshots/Screenshot%20%20GPO%20List.png) |
| GPO Linked to GLF-Users OU            | ![GPO Linked](Screenshots/Screenshot%20GPO%20Linked%20to%20GLF-Users%20OU.png) |
| Delegated Controls                    | ![Delegated Controls](Screenshots/Screenshot%20Show%20Delegated%20Controls.png) |
| Share Folder Permissions              | ![Share Perms](Screenshots/Screenshot%20Share%20Folder%20Permissions%20Proof%20Only.png) |
| Password Change at Next Logon         | ![Pwd Change](Screenshots/Screenshot%20Password%20Change%20at%20Next%20Logon.png) |
| Domain Proof (whoami, etc.)           | ![Domain Proof](Screenshots/domain-proof.png) |
| ...                                   | *(add more as you see fit)*                                    |

---

## What I Learned

- Automated AD OU/user/group/GPO management using PowerShell
- Group-based access control and delegation
- Troubleshooting and testing Windows authentication, group policy, and resource access between VMs

---

## Scripts

See [`scripts/build-lab.ps1`](scripts/build-lab.ps1) for the full PowerShell build/demo script.

---

## How to Use the Screenshots

- All screenshots are stored in the `Screenshots` folder.
- Reference them in your documentation or presentations.

---

**_For any reviewer: All configuration steps and proof of results are documented in this repo to demonstrate hands-on proficiency with modern Windows Active Directory._**
