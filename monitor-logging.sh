#!/bin/bash


init_log() {
    # Log-Verzeichnis anlegen (falls nicht vorhanden)
    mkdir -p "$LOG_DIR" || {
        echo "Konnte Log-Verzeichnis $LOG_DIR nicht erstellen." >&2
        exit 1
    }

    # Optionale Kopfzeile (nur wenn Datei leer ist)
    if [ ! -s "$LOG_FILE" ]; then
        echo "===== System Monitor Log gestartet am $(date '+%Y-%m-%d %H:%M:%S') =====" >> "$LOG_FILE"
    fi
}

log_action() {
    local level="$1"   # z.B. INFO, WARN, ERROR, CRITICAL
    shift              # entfernt das erste Argument, der Rest ist die Nachricht
    local message="$*"

    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    echo "$timestamp [$level] $message" >> "$LOG_FILE"
}

log_action() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    local line="$timestamp [$level] $message"

    # In Datei schreiben
    echo "$line" >> "$LOG_FILE"

    # Zusätzlich im Terminal anzeigen
    case "$level" in
        INFO)
            echo "$line"
            ;;
        WARN)
            echo -e "\033[33m$line\033[0m"   # gelb
            ;;
        ERROR|CRITICAL)
            echo -e "\033[31m$line\033[0m"   # rot
            ;;
        *)
            echo "$line"
            ;;
    esac
}

 