#!/bin/bash



while [ true ]; do
    echo "Monitoring system resources..."

    # CPU-Auslastung, summiert die User und System-CPU-Auslastung
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    echo "CPU-Auslastung: $cpu_usage%"

    # Freier RAM
    free_ram=$(free -m | awk '/Mem:/ {print $4 " MB"}')
    echo "Freier RAM: $free_ram"

    # Freier Festplattenspeicher im Wurzelverzeichnis
    free_disk=$(df -h / | awk 'NR==2 {print $4}')
    echo "Freier Festplattenspeicher (/): $free_disk"

    sleep 60
done;