#!/usr/bin/env bash
set -euo pipefail

LOG=${1:?Usage: build-evidence-bundle.sh <filtered-log> <asn-file> [output-dir]}
ASN=${2:?Usage: build-evidence-bundle.sh <filtered-log> <asn-file> [output-dir]}
OUT=${3:-"/tmp/cloud-abuse-$(date +%Y%m%d)"}

mkdir -p "$OUT"
cp "$LOG" "$OUT/nginx-access.log"
cp "$ASN" "$OUT/bgp-asn.txt"

awk '{print $1}' "$LOG" | sort -u > "$OUT/source-ips.txt"
paste -sd';' "$OUT/source-ips.txt" > "$OUT/source-ips-form.txt"

UNIQUE_IPS=$(wc -l < "$OUT/source-ips.txt" | tr -d ' ')
REQUESTS=$(wc -l < "$LOG" | tr -d ' ')

{
  echo "Incident: Suspicious / distributed automated HTTP traffic"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "Evidence source: $LOG"
  echo "Total matching requests: $REQUESTS"
  echo "Unique source IPs: $UNIQUE_IPS"
  echo
  echo "User-Agent distribution:"
  awk -F'"' '{print $6}' "$LOG" | sort | uniq -c | sort -nr
  echo
  echo "HTTP status distribution:"
  awk -F'"' '{split($3,a," "); if(a[2] != "") print a[2]}' "$LOG" | sort | uniq -c | sort -nr
  echo
  echo "Referer distribution:"
  awk -F'"' '{print $4}' "$LOG" | sort | uniq -c | sort -nr
  echo
  echo "Request-line distribution:"
  awk -F'"' '{print $2}' "$LOG" | sort | uniq -c | sort -nr
} > "$OUT/summary.txt"

cat > "$OUT/README.txt" <<README
Cloud Abuse Investigation - Supporting Evidence
================================================

1. INCIDENT SUMMARY
-------------------
Observed activity: Suspicious / distributed automated HTTP traffic
Total matching requests: $REQUESTS
Unique source IPs: $UNIQUE_IPS

2. EVIDENCE
-----------
- nginx-access.log: filtered matching access records
- source-ips.txt: unique source IPs
- source-ips-form.txt: semicolon-delimited IPs for web forms
- bgp-asn.txt: ASN/BGP attribution evidence
- summary.txt: distributions and basic statistics

3. ATTRIBUTION BOUNDARY
-----------------------
ASN/BGP attribution identifies the network announcing source addresses. It does not by itself establish which cloud customer, instance, account, workload, proxy, NAT gateway, or other party generated the traffic.

4. REQUEST TO PROVIDER
----------------------
Please investigate whether these source addresses and timestamps can be correlated internally with customer accounts, instances, NAT/EIP resources, proxy infrastructure, workloads, or other common resources.
README

(
  cd "$OUT"
  sha256sum README.txt source-ips.txt source-ips-form.txt nginx-access.log bgp-asn.txt summary.txt > checksums.txt
)

echo "Evidence bundle created: $OUT"
echo "Requests: $REQUESTS"
echo "Unique IPs: $UNIQUE_IPS"
