#!/usr/bin/env bash

LOG_FILE="logs/disk-check.log"
mkdir -p logs

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# 1. Validate argument presence
if [ "$#" -lt 1 ]; then
    echo "Error: Missing threshold argument." >&2
    log "Error: Missing threshold argument."
    exit 2
fi

THRESHOLD="$1"
PATH_TO_CHECK="${2:-/}"

# 2. Validate threshold integer range (1-100)
if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -lt 1 ] || [ "$THRESHOLD" -gt 100 ]; then
    echo "Error: Threshold must be an integer between 1 and 100." >&2
    log "Error: Invalid threshold '$THRESHOLD'."
    exit 2
fi

if [ ! -e "$PATH_TO_CHECK" ]; then
    echo "Error: Path '$PATH_TO_CHECK' does not exist." >&2
    log "Error: Path '$PATH_TO_CHECK' not found."
    exit 2
fi

# 3. macOS (Darwin) vs Linux df compatibility
OS_TYPE=$(uname -s)
if [ "$OS_TYPE" = "Darwin" ]; then
    USAGE=$(df -k "$PATH_TO_CHECK" | awk 'NR==2 {print $5}' | tr -d '%')
else
    USAGE=$(df -P "$PATH_TO_CHECK" | awk 'NR==2 {print $5}' | tr -d '%')
fi

log "Checked disk usage on '$PATH_TO_CHECK': $USAGE% (Threshold: $THRESHOLD%)"

echo "Path Checked: $PATH_TO_CHECK"
echo "Disk Usage:   $USAGE%"
echo "Threshold:    $THRESHOLD%"

if [ "$USAGE" -ge "$THRESHOLD" ]; then
    echo "WARNING: Disk usage reached or exceeded threshold!"
    log "Alert: Disk usage ($USAGE%) reached or exceeded threshold ($THRESHOLD%)."
    exit 1
else
    echo "OK: Disk usage is within safe limits."
    log "Status OK: Usage below threshold."
    exit 0
fi