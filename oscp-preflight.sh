#!/bin/bash
# OSCP Exam Preflight — Run before connecting to VPN
# Verifies all critical tools are installed and functional

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BOLD="\033[1m"
RESET="\033[0m"

PASS=0
FAIL=0
WARN=0

check() {
    if command -v "$1" &>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} $1"
        ((PASS++))
    else
        echo -e "  ${RED}✗${RESET} $1 ${RED}— NOT FOUND${RESET}"
        ((FAIL++))
    fi
}

check_python_module() {
    if python3 -c "import $1" &>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} python3: $1"
        ((PASS++))
    else
        echo -e "  ${RED}✗${RESET} python3: $1 ${RED}— pip install $1${RESET}"
        ((FAIL++))
    fi
}

check_file() {
    if [ -f "$1" ]; then
        echo -e "  ${GREEN}✓${RESET} $1"
        ((PASS++))
    else
        echo -e "  ${YELLOW}?${RESET} $1 ${YELLOW}— not found${RESET}"
        ((WARN++))
    fi
}

echo -e "\n${BOLD}🐺 OSCP EXAM PREFLIGHT CHECK${RESET}"
echo -e "────────────────────────────────────\n"

# --- Enumeration ---
echo -e "${BOLD}[ENUMERATION]${RESET}"
check nmap
check gobuster
check feroxbuster
check nikto
check enum4linux
check snmpwalk
check onesixtyone
check wfuzz
check ffuf
echo ""

# --- Web / Exploitation ---
echo -e "${BOLD}[WEB / EXPLOITATION]${RESET}"
check searchsploit
check sqlmap
check hydra
check msfvenom
check curl
check wget
check whatweb
check exiftool
echo ""

# --- Shells & Listeners ---
echo -e "${BOLD}[SHELLS & LISTENERS]${RESET}"
check nc
check ncat
check rlwrap
check socat
check msfconsole
echo ""

# --- Active Directory ---
echo -e "${BOLD}[ACTIVE DIRECTORY]${RESET}"
check crackmapexec
check evil-winrm
check impacket-psexec
check impacket-wmiexec
check impacket-secretsdump
check impacket-GetUserSPNs
check impacket-GetNPUsers
check impacket-GetADUsers
check rpcclient
check ldapsearch
check_python_module bloodhound
echo ""

# --- File Transfer ---
echo -e "${BOLD}[FILE TRANSFER]${RESET}"
check python3
check scp
check ftp
check smbclient
check_python_module pyftpdlib
check_python_module http.server
echo ""

# --- Privesc ---
echo -e "${BOLD}[PRIVILEGE ESCALATION]${RESET}"
check_file /usr/share/wordlists/rockyou.txt
check_file /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt
check_file /usr/share/seclists/Fuzzing/LFI/LFI-Jhaddix.txt
echo ""

# --- Custom Tools ---
echo -e "${BOLD}[YOUR TOOLS]${RESET}"
if [ -f "$HOME/oscp-tools/The-Armed-Detective-Agency/agency_portal.py" ]; then
    echo -e "  ${GREEN}✓${RESET} agency_portal.py (HTTP server)"
    ((PASS++))
else
    echo -e "  ${YELLOW}?${RESET} agency_portal.py — check path"
    ((WARN++))
fi

if [ -f "$HOME/oscp-tools/No-Longer-Human-FTP-Server/dazai_ftp.py" ]; then
    echo -e "  ${GREEN}✓${RESET} dazai_ftp.py (FTP stager)"
    ((PASS++))
else
    echo -e "  ${YELLOW}?${RESET} dazai_ftp.py — check path"
    ((WARN++))
fi
echo ""

# --- Docker / BloodHound CE ---
echo -e "${BOLD}[BLOODHOUND CE]${RESET}"
check docker
check bloodhound-cli
if sudo docker ps 2>/dev/null | grep -q bloodhound; then
    echo -e "  ${GREEN}✓${RESET} BloodHound containers running"
    ((PASS++))
else
    echo -e "  ${YELLOW}?${RESET} BloodHound containers not running — bloodhound-cli install"
    ((WARN++))
fi
echo ""

# --- Network ---
echo -e "${BOLD}[NETWORK]${RESET}"
check openvpn
check ip
check ss
echo ""

# --- Summary ---
echo -e "────────────────────────────────────"
echo -e "${BOLD}RESULTS:${RESET} ${GREEN}${PASS} passed${RESET}  ${RED}${FAIL} failed${RESET}  ${YELLOW}${WARN} warnings${RESET}"

if [ $FAIL -eq 0 ]; then
    echo -e "\n${GREEN}${BOLD}All critical tools ready. Go get that 70. 🐺${RESET}\n"
else
    echo -e "\n${RED}${BOLD}Fix the ${FAIL} failed item(s) before exam start.${RESET}\n"
fi
