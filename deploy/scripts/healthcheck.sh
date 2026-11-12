#!/usr/bin/env bash
set -euo pipefail

fail=0
usage=$(df --output=pcent / | tail -1 | tr -dc '0-9')
[ "$usage" -lt 85 ] || { echo "DISK ${usage}% used"; fail=1; }
avail=$(free -m | awk '/^Mem:/ {print $7}')
[ "$avail" -gt 200 ] || { echo "MEMORY ${avail} MB available"; fail=1; }
for svc in nginx postgresql devops-api; do
 systemctl is-active --quiet "$svc" || { echo "SERVICE $svc inactive"; fail=1; }
done
curl -fsS --max-time 3 http://127.0.0.1:5000/health >/dev/null || { echo "HTTP API unhealthy"; fail=1; }
exit "$fail"
