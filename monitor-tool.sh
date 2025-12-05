#!/bin/bash

# Wie oft wird das System aktualisiert
INTERVAL=5

# Log-File erstellen und reinschreiben
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/monitor_$(date '+%d-%m-%Y_%H-%M-%S').log"
mkdir -p "$LOG_DIR"

log_to_file() {
    local LEVEL="$1"
    local MESSAGE="$2"
    local TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$TIME [$LEVEL] $MESSAGE" >> "$LOG_FILE"
}

log_to_file INFO "System Monitor gestartet"

# Hauptschleife: Überwache System
while true; do
    clear
    echo "=== System Monitor ==="
    echo ""

    # CPU-Auslastung berechnen (einfach)
    CPU_LINE=$(top -bn1 | grep "Cpu(s)")
    CPU_IDLE=$(echo $CPU_LINE | awk '{print $8}' | sed 's/id,//')
    if [ -z "$CPU_IDLE" ]; 
        then CPU_IDLE=100; 
    fi

    CPU_USAGE=$((100 - ${CPU_IDLE%.*}))
    echo "CPU: ${CPU_USAGE}%"

    if [ "$CPU_USAGE" -ge 90 ]; then
        log_to_file CRITICAL "CPU-Auslastung: ${CPU_USAGE}%"
    elif [ "$CPU_USAGE" -ge 75 ]; then
        log_to_file WARN "CPU-Auslastung: ${CPU_USAGE}%"
    fi

    # RAM-Auslastung berechnen
    TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
    USED_RAM=$(free -m | awk '/Mem:/ {print $3}')
    RAM_PERCENT=$((USED_RAM * 100 / TOTAL_RAM))
    echo "RAM: ${USED_RAM}MB / ${TOTAL_RAM}MB (${RAM_PERCENT}%)"
    if [ "$RAM_PERCENT" -ge 90 ]; then
        log_to_file CRITICAL "RAM: ${USED_RAM}MB / ${TOTAL_RAM}MB (${RAM_PERCENT}%)"
    elif [ "$RAM_PERCENT" -ge 75 ]; then
        log_to_file WARN "RAM: ${USED_RAM}MB / ${TOTAL_RAM}MB (${RAM_PERCENT}%)"
    fi

    # Festplattenspeicher berechnen
    USED_DISK=$(df -h / | awk 'NR==2 {print $3}')
    TOTAL_DISK=$(df -h / | awk 'NR==2 {print $2}')
    USED_DISK_PERCENT=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "Disk: ${USED_DISK} / ${TOTAL_DISK} (${USED_DISK_PERCENT}%)"
    if [ "$USED_DISK_PERCENT" -ge 90 ]; then
        log_to_file CRITICAL "Disk: ${USED_DISK} / ${TOTAL_DISK} (${USED_DISK_PERCENT}%)"
    elif [ "$USED_DISK_PERCENT" -ge 75 ]; then
        log_to_file WARN "Disk: ${USED_DISK} / ${TOTAL_DISK} (${USED_DISK_PERCENT}%)"
    fi

    echo ""
    echo "Nächste Aktualisierung in $INTERVAL Sekunden..."
    sleep $INTERVAL
done