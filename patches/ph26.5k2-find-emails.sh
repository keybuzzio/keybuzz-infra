#!/bin/bash
# PH26.5K2: Find email storage on mail-core-01

echo "=== Exploring mail-core-01 (10.0.0.160) ==="

ssh -o StrictHostKeyChecking=no root@10.0.0.160 << 'ENDSSH'
echo "1. Docker containers running:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null || echo "No docker or no containers"

echo ""
echo "2. Looking for mail directories:"
ls -la /var/mail/ 2>/dev/null || echo "/var/mail not found"
ls -la /var/spool/mail/ 2>/dev/null || echo "/var/spool/mail not found"
ls -la /home/*/Maildir/ 2>/dev/null || echo "No Maildir in /home"

echo ""
echo "3. Looking for docker-mailserver data:"
ls -la /docker-data/ 2>/dev/null || echo "/docker-data not found"
ls -la /opt/mailserver/ 2>/dev/null || echo "/opt/mailserver not found"

echo ""
echo "4. Finding large directories:"
du -sh /var/* 2>/dev/null | sort -h | tail -10

echo ""
echo "5. Searching for recent .eml files:"
find / -name "*.eml" -mtime -30 2>/dev/null | head -10 || echo "None found"

echo ""
echo "6. Checking postfix spool:"
ls -la /var/spool/postfix/ 2>/dev/null | head -10 || echo "No postfix spool"
ENDSSH
