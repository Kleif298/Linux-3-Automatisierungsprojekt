#!/bin/bash

interval=5

# Log-Konfiguration
LOG_DIR="./logs"
LOG_TIMESTAMP=$(date '+%d-%m-%Y_%H-%M-%S')
LOG_FILE="$LOG_DIR/monitor_${LOG_TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

log_to_file() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp [$level] $message" >> "$LOG_FILE"
}

echo "===== System Monitor Log gestartet am $(date '+%Y-%m-%d %H:%M:%S') =====" >> "$LOG_FILE"

while [ true ]; do
    clear
    echo "=== System Monitor ==="
    echo ""

    # CPU-Auslastung
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    cpu_usage_int=${cpu_usage%.*}
    echo "CPU: ${cpu_usage}%"
    
    if [ "$cpu_usage_int" -ge 90 ]; then
        log_to_file "CRITICAL" "CPU-Auslastung: ${cpu_usage}%"
    elif [ "$cpu_usage_int" -ge 75 ]; then
        log_to_file "WARN" "CPU-Auslastung: ${cpu_usage}%"
    fi


    # RAM
    used_ram_mb=$(free -m | awk '/Mem:/ {print $3}')
    total_ram_mb=$(free -m | awk '/Mem:/ {print $2}')
    ram_percent=$((used_ram_mb * 100 / total_ram_mb))
    echo "RAM: ${used_ram_mb}MB / ${total_ram_mb}MB (${ram_percent}%)"
    
    if [ "$used_ram_mb" -ge $((total_ram_mb - 500)) ]; then
        log_to_file "CRITICAL" "RAM: ${used_ram_mb}MB / ${total_ram_mb}MB (${ram_percent}%)"
    elif [ "$used_ram_mb" -ge $((total_ram_mb - 1000)) ]; then
        log_to_file "WARN" "RAM: ${used_ram_mb}MB / ${total_ram_mb}MB (${ram_percent}%)"
    fi

    # Festplattenspeicher
    used_disk=$(df -h / | awk 'NR==2 {print $3}')
    total_disk=$(df -h / | awk 'NR==2 {print $2}')
    used_percent=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "Disk: ${used_disk} / ${total_disk} (${used_percent}%)"
    
    if [ "$used_percent" -ge 90 ]; then
        log_to_file "CRITICAL" "Disk: ${used_disk} / ${total_disk} (${used_percent}%)"
    elif [ "$used_percent" -ge 80 ]; then
        log_to_file "WARN" "Disk: ${used_disk} / ${total_disk} (${used_percent}%)"
    fi

    
    echo "Nächste Aktualisierung in ${interval} Sekunden..."
    sleep $interval
done