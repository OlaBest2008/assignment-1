#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="logs/network-check.log"
mkdir -p logs

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# 1. Validate host argument
if [ "$#" -lt 1 ] || [ -z "${1:-}" ]; then
    echo "Error: Host argument is required." >&2
    log "Error: Host argument missing."
    exit 2
fi

HOST="$1"
PORT="${2:-}"

# 2. Validate optional port argument (1-65535)
if [ -n "$PORT" ]; then
    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        echo "Error: Invalid port number '$PORT'. Valid range: 1-65535." >&2
        log "Error: Invalid port '$PORT'."
        exit 2
    fi
fi

log "Executing network-check.sh on host: $HOST, port: ${PORT:-None}"

echo "=========================================="
echo "          NETWORK CHECK                   "
echo "=========================================="

# 3. macOS / Linux cross-platform DNS resolution
RESOLVED_IP=""
if command -v getent >/dev/null 2>&1; then
    RESOLVED_IP=$(getent hosts "$HOST" | awk '{ print $1 }' | head -n 1 || true)
fi

if [ -z "$RESOLVED_IP" ] && command -v dscacheutil >/dev/null 2>&1; then
    RESOLVED_IP=$(dscacheutil -q host -a name "$HOST" | awk '/ip_address:/ {print $2}' | head -n 1 || true)
fi

if [ -z "$RESOLVED_IP" ]; then
    RESOLVED_IP=$(ping -c 1 "$HOST" 2>/dev/null | head -n 1 | awk -F'[()]' '{print $2}' || true)
fi

# Fallback for localhost if offline
if [ "$HOST" = "localhost" ] && [ -z "$RESOLVED_IP" ]; then
    RESOLVED_IP="127.0.0.1"
fi

if [ -z "$RESOLVED_IP" ]; then
    echo "Error: Unable to resolve host '$HOST'." >&2
    log "Error: Failed to resolve host '$HOST'."
    exit 1
fi

echo "Target Host:    $HOST"
echo "Resolved IP:    $RESOLVED_IP"

echo -n "Ping Check:     "
if ping -c 2 -t 2 "$HOST" > /dev/null 2>&1 || ping -c 2 -W 2 "$HOST" > /dev/null 2>&1; then
    echo "SUCCESS"
    log "Ping to $HOST succeeded."
else
    echo "FAILED"
    log "Ping to $HOST failed."
fi

echo "------------------------------------------"
echo "Network Interfaces:"
ifconfig -a 2>/dev/null || ip -brief addr show 2>/dev/null || echo "Interfaces active"
echo "------------------------------------------"

# 4. Optional TCP Port Check
if [ -n "$PORT" ]; then
    echo -n "TCP Port $PORT Check: "
    if nc -z -w 3 "$HOST" "$PORT" 2>/dev/null || timeout 3 bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
        echo "OPEN"
        log "Port $PORT on $HOST is open."
    else
        echo "CLOSED / UNREACHABLE"
        log "Port $PORT on $HOST is closed or unreachable."
        exit 1
    fi
fi

log "Network check completed successfully."
exit 0