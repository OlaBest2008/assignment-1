#!/usr/bin/env bash
LOG_FILE="logs/system-info.log"
mkdir -p logs

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "Executing system-info.sh"

echo "=========================================="
echo "          SYSTEM INFORMATION              "
echo "=========================================="
echo "Hostname:         $(hostname)"
echo "Current User:     $(whoami)"
echo "Date/Time:        $(date)"
echo "Operating System: $(uname -s)"
echo "Kernel Version:   $(uname -r)"
echo "Uptime:           $(uptime -p 2>/dev/null || uptime)"
echo "CPU Model:        $(lscpu | grep "Model name:" | sed 's/Model name:\s*//' || echo "N/A")"
echo "Memory Usage:     $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Current Directory:$(pwd)"
echo "=========================================="

log "Successfully completed system-info.sh"