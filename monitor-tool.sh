#!/bin/bash

# System Monitor Script
# Überwacht CPU, RAM und Festplatten-Auslastung und schreibt alles in eine Log-Datei

# Standard-Konfiguration
INTERVAL=5
LOG_DIR="./logs"
CPU_WARN=75
CPU_CRIT=90
RAM_WARN=75
RAM_CRIT=90
DISK_WARN=75
DISK_CRIT=90

# Erstelle das Log-Verzeichnis falls es nicht existiert
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/monitor_$(date '+%d-%m-%Y_%H-%M-%S').log"

# Funktion zum Schreiben von Nachrichten ins Logfile
log_message() {
    local MESSAGE="$1"
    local TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$TIME - $MESSAGE" >> "$LOG_FILE"
}

# Funktion zum Anzeigen im Terminal mit Farbe
display_status() {
    local VALUE=$1
    local NAME="$2"
    local WARN=$3
    local CRIT=$4
    local USED="$5"
    local TOTAL="$6"
    
    local COLOR_RESET="\033[0m"
    local COLOR_OK="\033[32m"
    local COLOR_WARN="\033[33m"
    local COLOR_CRIT="\033[31m"
    
    local OUTPUT="$NAME: ${VALUE}%"
    if [ ! -z "$USED" ] && [ ! -z "$TOTAL" ]; then
        OUTPUT="$NAME: ${VALUE}% (${USED} of ${TOTAL})"
    fi
    
    # if/elif/else Verzweigung
    if [ "$VALUE" -ge "$CRIT" ]; then
        echo -e "${COLOR_CRIT}${OUTPUT}${COLOR_RESET}"
    elif [ "$VALUE" -ge "$WARN" ]; then
        echo -e "${COLOR_WARN}${OUTPUT}${COLOR_RESET}"
    else
        echo -e "${COLOR_OK}${OUTPUT}${COLOR_RESET}"
    fi
}

# Funktion zum Loggen ins File
log_to_file() {
    local VALUE=$1
    local NAME="$2"
    local WARN=$3
    local CRIT=$4
    local DETAILS="$5"
    
    if [ "$VALUE" -ge "$CRIT" ]; then
        log_message "KRITISCH! $NAME Auslastung: ${VALUE}% (Schwellenwert: ${CRIT}%) - $DETAILS"
    elif [ "$VALUE" -ge "$WARN" ]; then
        log_message "WARNUNG! $NAME Auslastung: ${VALUE}% (Schwellenwert: ${WARN}%) - $DETAILS"
    else
        log_message "OK - $NAME Auslastung: ${VALUE}% - $DETAILS"
    fi
}

# Startmeldung
log_message "System Monitor gestartet"

# Frage den Benutzer nach eigenen Einstellungen
echo "Would you like to set your own thresholds?"
echo "Default values:"
echo "  CPU Warning: $CPU_WARN%, Critical: $CPU_CRIT%"
echo "  RAM Warning: $RAM_WARN%, Critical: $RAM_CRIT%"
echo "  Disk Warning: $DISK_WARN%, Critical: $DISK_CRIT%"
echo "  Interval: ${INTERVAL} seconds"
echo ""
read -p "Use custom values? (y/n, Enter for default): " USE_CUSTOM

# Wenn der Benutzer eigene Werte möchte, frage nach jedem Wert
if [ "$USE_CUSTOM" = "y" ] || [ "$USE_CUSTOM" = "Y" ]; then
    read -p "CPU warning threshold (Enter for $CPU_WARN): " INPUT
    [ ! -z "$INPUT" ] && CPU_WARN=$INPUT
    read -p "CPU critical threshold (Enter for $CPU_CRIT): " INPUT
    [ ! -z "$INPUT" ] && CPU_CRIT=$INPUT
    read -p "RAM warning threshold (Enter for $RAM_WARN): " INPUT
    [ ! -z "$INPUT" ] && RAM_WARN=$INPUT
    read -p "RAM critical threshold (Enter for $RAM_CRIT): " INPUT
    [ ! -z "$INPUT" ] && RAM_CRIT=$INPUT
    read -p "Disk warning threshold (Enter for $DISK_WARN): " INPUT
    [ ! -z "$INPUT" ] && DISK_WARN=$INPUT
    read -p "Disk critical threshold (Enter for $DISK_CRIT): " INPUT
    [ ! -z "$INPUT" ] && DISK_CRIT=$INPUT
    read -p "Update interval in seconds (Enter for $INTERVAL): " INPUT
    [ ! -z "$INPUT" ] && INTERVAL=$INPUT
    log_message "Custom thresholds set: CPU(${CPU_WARN}/${CPU_CRIT}) RAM(${RAM_WARN}/${RAM_CRIT}) DISK(${DISK_WARN}/${DISK_CRIT}) Interval=${INTERVAL}s"
fi

# Hauptschleife
while [ true ]; do
    clear
    echo "Monitoring run #$((COUNTER + 1))"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Last warnings and critical messages:"
    if [ -f "$LOG_FILE" ]; then
        grep -E "WARNING|CRITICAL" "$LOG_FILE" | tail -n 10
    fi
    echo ""
    
    # Hole CPU Auslastung aus /proc/stat
    if [ -f /proc/stat ]; then
        CPU_LINE1=$(grep "^cpu " /proc/stat)
        sleep 0.5
        CPU_LINE2=$(grep "^cpu " /proc/stat)
        
        CPU1_IDLE=$(echo $CPU_LINE1 | awk '{print $5}')
        CPU1_TOTAL=$(echo $CPU_LINE1 | awk '{sum=0; for(i=2;i<=NF;i++) sum+=$i; print sum}')
        CPU2_IDLE=$(echo $CPU_LINE2 | awk '{print $5}')
        CPU2_TOTAL=$(echo $CPU_LINE2 | awk '{sum=0; for(i=2;i<=NF;i++) sum+=$i; print sum}')
        
        IDLE_DIFF=$((CPU2_IDLE - CPU1_IDLE))
        TOTAL_DIFF=$((CPU2_TOTAL - CPU1_TOTAL))
        
        if [ $TOTAL_DIFF -gt 0 ]; then
            CPU_USAGE=$((100 * (TOTAL_DIFF - IDLE_DIFF) / TOTAL_DIFF))
        else
            CPU_USAGE=0
        fi
    else
        CPU_USAGE=0
    fi
    # Hole RAM Auslastung aus /proc/meminfo
    if [ -f /proc/meminfo ]; then
        TOTAL_MEM=$(grep "^MemTotal:" /proc/meminfo | awk '{print $2}')
        FREE_MEM=$(grep "^MemAvailable:" /proc/meminfo | awk '{print $2}')
        USED_MEM=$((TOTAL_MEM - FREE_MEM))
        RAM_USAGE=$((USED_MEM * 100 / TOTAL_MEM))
        TOTAL_MEM_MB=$((TOTAL_MEM / 1024))
        USED_MEM_MB=$((USED_MEM / 1024))
        FREE_MEM_MB=$((FREE_MEM / 1024))
        RAM_DETAILS="Used=${USED_MEM_MB}MB of ${TOTAL_MEM_MB}MB (Free: ${FREE_MEM_MB}MB)"
    else
        RAM_USAGE=0
        RAM_DETAILS="Konnte nicht ermittelt werden"
    fi
    
    # Hole Festplatten Auslastung mit df
    if command -v df > /dev/null; then
        DISK_INFO=$(df -h / | tail -1)
        DISK_TOTAL=$(echo $DISK_INFO | awk '{print $2}')
        DISK_USED=$(echo $DISK_INFO | awk '{print $3}')
        DISK_FREE=$(echo $DISK_INFO | awk '{print $4}')
        DISK_USAGE=$(echo $DISK_INFO | awk '{print $5}' | sed 's/%//')
        DISK_DETAILS="Used=${DISK_USED} of ${DISK_TOTAL} (Free: ${DISK_FREE})"
    else
        DISK_USAGE=0
        DISK_DETAILS="Konnte nicht ermittelt werden"
    fi
    
    CPU_DETAILS="CPU usage"
    
    # case-Struktur um verschiedene Ressourcen zu behandeln
    RESOURCE_CHECK="ALL"
    case "$RESOURCE_CHECK" in
        CPU)
            log_message "Pruefe nur CPU"
            ;;
        RAM)
            log_message "Pruefe nur RAM"
            ;;
        DISK)
            log_message "Pruefe nur Disk"
            ;;
        *)
            log_message "Pruefe alle Ressourcen"
            ;;
    esac
    
    # Zeige Status im Terminal mit Farben und logge ins File
    display_status $CPU_USAGE "CPU" $CPU_WARN $CPU_CRIT "" ""
    log_to_file $CPU_USAGE "CPU" $CPU_WARN $CPU_CRIT "$CPU_DETAILS"

    display_status $RAM_USAGE "RAM" $RAM_WARN $RAM_CRIT "${USED_MEM_MB} MB" "${TOTAL_MEM_MB} MB"
    log_to_file $RAM_USAGE "RAM" $RAM_WARN $RAM_CRIT "$RAM_DETAILS"

    display_status $DISK_USAGE "Disk" $DISK_WARN $DISK_CRIT "$DISK_USED" "$DISK_TOTAL"
    log_to_file $DISK_USAGE "Disk" $DISK_WARN $DISK_CRIT "$DISK_DETAILS"
    # for-Schleife für Countdown
    echo ""
    echo "Next check in:"
    for i in $(seq $INTERVAL -1 1); do
        echo -n "$i "
        sleep 1
    done
    echo ""
    
    COUNTER=$((COUNTER + 1))
done

# Abschlussmeldung
log_message "System monitor finished after $COUNTER runs"
echo ""
echo "Monitoring finished. Log saved in: $LOG_FILE"