#!/bin/bash

LOGFILE="$1"

if [ -z "$LOGFILE" ]; then
    echo "Usage: $0 /path/to/access.log"
    exit 1
fi

if [ ! -f "$LOGFILE" ]; then
    echo "File not found!"
    exit 1
fi

# ===== Colors =====
RED='\033[1;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}=============================================="
echo -e "      ADVANCED MALICIOUS ACCESS LOG SCAN"
echo -e "==============================================${NC}"
echo ""

TMPFILE=$(mktemp)

# Detect suspicious patterns
grep -Ei \
"union|select|--|or 1=1|%27|<script|%3Cscript|onerror|alert\(|\.\./|%2e%2e|etc/passwd|boot.ini|php://|file://|data://|expect://|_ignition|\.env|phpunit|shell\.php|cmd\.php|upload\.php|wp-admin|xmlrpc|jndi:ldap|jndi:rmi|whoami|id;|\$\(|curl|wget|sqlmap|nikto|nmap|masscan|bash -i|nc |/bin/sh" \
"$LOGFILE" > "$TMPFILE"

TOTAL=$(wc -l < "$TMPFILE")

echo -e "${YELLOW}Total Suspicious Requests Found:${NC} $TOTAL"
echo ""

if [ "$TOTAL" -eq 0 ]; then
    echo -e "${GREEN}No obvious malicious requests detected.${NC}"
    rm "$TMPFILE"
    exit 0
fi

# ===== FIRST MALICIOUS =====
echo -e "${RED}===== FIRST MALICIOUS REQUEST =====${NC}"
head -n 1 "$TMPFILE"
echo ""

# ===== SQLi =====
echo -e "${RED}[CRITICAL] SQL Injection Attempts${NC}"
grep -Ei "union|select|--|or 1=1|%27" "$TMPFILE"

# ===== RCE =====
echo ""
echo -e "${RED}[CRITICAL] Remote Code Execution Attempts${NC}"
grep -Ei "whoami|id;|\$\(|bash -i|nc |/bin/sh|_ignition|phpunit" "$TMPFILE"

# ===== Backdoor Probing =====
echo ""
echo -e "${RED}[CRITICAL] Backdoor / Webshell Probing${NC}"
grep -Ei "shell\.php|cmd\.php|upload\.php|c99|r57" "$TMPFILE"

# ===== File Disclosure =====
echo ""
echo -e "${RED}[CRITICAL] Sensitive File Probing (.env, passwd)${NC}"
grep -Ei "\.env|etc/passwd|boot.ini" "$TMPFILE"

# ===== Path Traversal =====
echo ""
echo -e "${YELLOW}[HIGH] Path Traversal${NC}"
grep -Ei "\.\./|%2e%2e" "$TMPFILE"

# ===== XSS =====
echo ""
echo -e "${YELLOW}[HIGH] XSS Attempts${NC}"
grep -Ei "<script|%3Cscript|onerror|alert\(" "$TMPFILE"

# ===== Log4Shell =====
echo ""
echo -e "${RED}[CRITICAL] Log4Shell Attempts${NC}"
grep -Ei "jndi:ldap|jndi:rmi" "$TMPFILE"

# ===== Scanner User Agents =====
echo ""
echo -e "${YELLOW}[MEDIUM] Automated Scanners${NC}"
grep -Ei "sqlmap|nikto|nmap|masscan|curl|wget" "$TMPFILE"

# ===== Brute Force Detection =====
echo ""
echo -e "${RED}[CRITICAL] Brute Force Detection (Login Abuse)${NC}"

grep "POST /login" "$LOGFILE" | \
awk '{print $1}' | sort | uniq -c | sort -nr | \
awk '$1 > 10'

# ===== 404 Enumeration =====
echo ""
echo -e "${YELLOW}[HIGH] Directory Bruteforce (404 Scanning)${NC}"

awk '$9 == 404 {print $1}' "$LOGFILE" | \
sort | uniq -c | sort -nr | \
awk '$1 > 20'

# ===== Top Attacking IPs =====
echo ""
echo -e "${RED}===== TOP ATTACKING IPS =====${NC}"
awk '{print $1}' "$TMPFILE" | sort | uniq -c | sort -nr | head

rm "$TMPFILE"

echo ""
echo -e "${BLUE}Scan completed.${NC}"
