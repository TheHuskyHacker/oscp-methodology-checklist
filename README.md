# R.A.N.C.H. — OSCP Methodology Checklist

> *"Saddle up boys. We're headed for the brick wall."*

An interactive Bash checklist for OSCP exam methodology, built around the **R.A.N.C.H.** framework:
**Recon · Attack Surface · Navigate · Compromise · Harvest**

By Aaron "The Husky Hacker" Gaddis

---

## Features

- **142+ checklist items** across 8 sections with command references for every technique
- **Per-target state tracking** — progress saves automatically and persists between sessions
- **Color-coded terminal UI** with the R.A.N.C.H. ASCII banner
- **Toggle items by ID** — quick to mark off steps as you work through a box
- **Exam day tips** — time management, passing scenarios, file transfer and reverse shell cheat sheets

## Requirements

- Bash 4.0+ (for associative arrays)
- A terminal with color support

## Installation

```bash
git clone https://github.com/TheHuskyHacker/oscp-methodology-checklist
cd oscp-methodology-checklist
chmod +x oscp-methodology-checklist.sh
```

## Usage

```bash
./oscp-methodology-checklist.sh <TARGET_IP>
```

### Example

```bash
./oscp-methodology-checklist.sh 10.10.10.50
```

This opens the interactive menu for that target. Progress is saved to `~/.oscp-checklist/10_10_10_50.state` and restored automatically the next time you run the script with the same IP.

### Main Menu

| Key | Action |
|-----|--------|
| `1` | R — Recon |
| `2` | A — Attack Surface |
| `3` | N — Navigate (Pivoting & Lateral Movement) |
| `4` | C — Compromise: Linux Privesc |
| `5` | C — Compromise: Windows Privesc |
| `6` | C — Compromise: Active Directory |
| `7` | H — Harvest (Loot & Proof) |
| `8` | Exam Day Tips & Cheat Sheet |
| `a` | Show ALL sections |
| `p` | Show progress summary |
| `r` | Reset all checkmarks |
| `q` | Quit |

### Inside a Section

Each item has an ID (e.g. `R01`, `CL15`, `CA18`), a description, and a command reference.

```
  [ ] R01  Quick TCP scan (top 1000)
        nmap -sC -sV -oN nmap/initial 10.10.10.50

  [✓] R02  Full TCP port scan
        nmap -p- --min-rate 5000 -oN nmap/alltcp 10.10.10.50
```

| Key | Action |
|-----|--------|
| Item ID (e.g. `R01`) | Toggle that item checked/unchecked |
| `b` | Back to main menu |
| `q` | Quit |

## Sections

### R — Recon
Port scanning (TCP/UDP/SNMP) and service enumeration for 14 common services (FTP, SSH, SMTP, DNS, HTTP, SMB, RPC, LDAP, Kerberos, NFS, MSSQL, MySQL, RDP, WinRM).

### A — Attack Surface
Web enumeration (directory/file brute force, vhosts, source review, CMS detection, API discovery, parameter fuzzing), credential gathering (CeWL, default creds, hydra, AS-REP Roasting, password spraying), and vulnerability identification (SQLi, file upload, LFI/RFI, SSTI, command injection).

### N — Navigate
Pivoting (Ligolo-ng, Chisel, SSH tunnels) and lateral movement (Pass-the-Hash, Evil-WinRM, RDP, WMI, PsExec, internal scanning from pivot hosts).

### C — Compromise: Linux Privesc
Quick wins (sudo/SUID/kernel), credential hunting, cron/timer abuse, PATH/library/Python module hijacking, Docker group, NFS no_root_squash, capabilities, and shell stabilization.

### C — Compromise: Windows Privesc
Token privileges (Potato family), service exploits (unquoted paths, binary hijack, AlwaysInstallElevated), credential hunting (Mimikatz, SAM, LSASS, LaZagne, Sticky Notes, KeePass, web.config, PS history, Sublime sessions, Thunderbird, GPP cPassword), and automated enumeration.

### C — Compromise: Active Directory
BloodHound, LDAP/GPO enum, Kerberoasting, AS-REP Roasting, Shadow Credentials, GMSA, ACL abuse chains (ForceChangePassword, GenericAll, WriteDACL, WriteOwner, AddMember), DCSync, Golden Ticket, Constrained Delegation, ADCS (ESC1/ESC4), coercion/relay, and MSSQL xp_cmdshell.

### H — Harvest
Flag capture with proof screenshots, hash dumping, pivot discovery, and credential reuse.

### Exam Day Tips
Time management for the 23:45-hour exam, passing score scenarios, "if you're stuck" checklist, listener setup, file transfer cheat sheet, and reverse shell quick reference.

## State Files

Progress is stored in `~/.oscp-checklist/` with one file per target IP:

```
~/.oscp-checklist/
├── 10_10_10_50.state
├── 192_168_1_100.state
└── 172_16_0_5.state
```

Each `.state` file is a simple key=value format. To reset a single target, delete its file. To reset everything:

```bash
rm -rf ~/.oscp-checklist/
```

## Exam Day Workflow

```bash
# Start the checklist for the AD set
./oscp-methodology-checklist.sh 10.10.10.100

# Work through R → A → N → C → H, toggling items as you go
# Progress auto-saves

# Move to the next standalone
./oscp-methodology-checklist.sh 10.10.10.101

# Check overall progress any time with 'p'
```

## Companion Files

| File | Description |
|------|-------------|
| `oscp-methodology-checklist.sh` | Interactive Bash checklist (this tool) |
| `oscp-methodology-checklist.md` | Static Markdown version with checkboxes |

## License

MIT

## Author

**Aaron "The Husky Hacker" Gaddis**
- GitHub: [@HackingHusky](https://github.com/HackingHusky)
- Blog: [husky-hacker-read.com](https://husky-hacker-read.com)
- YouTube: [@TheHuskeyHacker](https://youtube.com/@TheHuskeyHacker)
- Portfolio: [thehuskyhacker.com](https://thehuskyhacker.com)
