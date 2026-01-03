#!/bin/bash
# PH11-SRE-06: DEV Endpoints Checker
# Vérifie que tous les endpoints DEV sont accessibles et que TLS est valide
# Usage: ./ph11_sre06_check_endpoints_dev.sh [output_dir]

set -euo pipefail

# Configuration
OUTPUT_DIR="${1:-/opt/keybuzz/logs/sre/endpoints}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/check_$TIMESTAMP.json"

# DEV endpoints à vérifier
DEV_ENDPOINTS=(
    "admin-dev.keybuzz.io"
    "client-dev.keybuzz.io"
    "api-dev.keybuzz.io"
    "grafana-dev.keybuzz.io"
)

# Expected HTTP status codes (200, 302, 301, 401 sont acceptables)
VALID_STATUS_CODES="200|301|302|401|404"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to check DNS
check_dns() {
    local host="$1"
    local ips
    ips=$(dig +short "$host" 2>/dev/null | head -2 | tr '\n' ',' | sed 's/,$//')
    if [ -n "$ips" ]; then
        echo "$ips"
        return 0
    else
        echo "FAILED"
        return 1
    fi
}

# Function to check HTTPS
check_https() {
    local host="$1"
    local status
    status=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 30 "https://$host" 2>/dev/null || echo "000")
    echo "$status"
}

# Function to get TLS cert expiration
get_cert_expiry() {
    local host="$1"
    local expiry
    expiry=$(echo | openssl s_client -connect "$host:443" -servername "$host" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d'=' -f2 || echo "FAILED")
    echo "$expiry"
}

# Function to get days until expiry
get_days_until_expiry() {
    local host="$1"
    local expiry_epoch
    local now_epoch
    local days
    
    expiry_epoch=$(echo | openssl s_client -connect "$host:443" -servername "$host" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null | grep notAfter | cut -d'=' -f2 | xargs -I{} date -d {} +%s 2>/dev/null || echo "0")
    now_epoch=$(date +%s)
    
    if [ "$expiry_epoch" != "0" ] && [ -n "$expiry_epoch" ]; then
        days=$(( (expiry_epoch - now_epoch) / 86400 ))
        echo "$days"
    else
        echo "-1"
    fi
}

# Start JSON output
echo "{" > "$OUTPUT_FILE"
echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$OUTPUT_FILE"
echo "  \"checker\": \"ph11_sre06_check_endpoints_dev\"," >> "$OUTPUT_FILE"
echo "  \"endpoints\": [" >> "$OUTPUT_FILE"

# Check each endpoint
first=true
all_ok=true
for host in "${DEV_ENDPOINTS[@]}"; do
    if [ "$first" = true ]; then
        first=false
    else
        echo "    ," >> "$OUTPUT_FILE"
    fi
    
    # Run checks
    dns_result=$(check_dns "$host")
    http_status=$(check_https "$host")
    cert_expiry=$(get_cert_expiry "$host")
    days_to_expiry=$(get_days_until_expiry "$host")
    
    # Determine status
    dns_ok="false"
    http_ok="false"
    tls_ok="false"
    
    if [ "$dns_result" != "FAILED" ]; then
        dns_ok="true"
    fi
    
    if echo "$http_status" | grep -qE "^($VALID_STATUS_CODES)$"; then
        http_ok="true"
    fi
    
    if [ "$cert_expiry" != "FAILED" ] && [ "$days_to_expiry" -gt 0 ]; then
        tls_ok="true"
    fi
    
    # Overall status
    if [ "$dns_ok" = "true" ] && [ "$http_ok" = "true" ] && [ "$tls_ok" = "true" ]; then
        overall="OK"
    else
        overall="FAILED"
        all_ok=false
    fi
    
    # Write JSON
    cat >> "$OUTPUT_FILE" << EOF
    {
      "host": "$host",
      "dns": {
        "ok": $dns_ok,
        "ips": "$dns_result"
      },
      "http": {
        "ok": $http_ok,
        "status": $http_status
      },
      "tls": {
        "ok": $tls_ok,
        "expiry": "$cert_expiry",
        "days_remaining": $days_to_expiry
      },
      "overall": "$overall"
    }
EOF
done

# Close JSON
echo "  ]," >> "$OUTPUT_FILE"
if [ "$all_ok" = true ]; then
    echo "  \"status\": \"OK\"," >> "$OUTPUT_FILE"
else
    echo "  \"status\": \"FAILED\"," >> "$OUTPUT_FILE"
fi
echo "  \"output_file\": \"$OUTPUT_FILE\"" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

# Output summary
echo "=============================================="
echo "DEV Endpoints Check - $(date)"
echo "=============================================="
cat "$OUTPUT_FILE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f\"Status: {d['status']}\")
print()
print('| Host | DNS | HTTP | TLS | Days |')
print('|------|-----|------|-----|------|')
for e in d['endpoints']:
    dns = '✅' if e['dns']['ok'] else '❌'
    http = '✅' + str(e['http']['status']) if e['http']['ok'] else '❌' + str(e['http']['status'])
    tls = '✅' if e['tls']['ok'] else '❌'
    days = e['tls']['days_remaining']
    print(f\"| {e['host']} | {dns} | {http} | {tls} | {days}d |\")
"
echo ""
echo "Log: $OUTPUT_FILE"
echo "=============================================="

# Exit with appropriate code
if [ "$all_ok" = true ]; then
    exit 0
else
    exit 1
fi
