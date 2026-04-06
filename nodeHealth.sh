#!/bin/bash

set -euo pipefail

LOG_FILE="./logs/health.log"
SERVICE_NAME="nginx"
URL="http://localhost"
CONTAINER="my-app"

mkdir -p logs

# Trap
cleanup() {
    echo "$(date) - Script interrupted" >> $LOG_FILE
}
trap cleanup SIGINT SIGTERM EXIT

	echo "$(date +"%F %T.%3N") [INFO] Health check started" >> $LOG_FILE

# CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)

# Memory
MEMORY_USAGE=$(free | awk '/Mem/ {printf("%.0f"), $3/$2 * 100}')

# Disk
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# Log system stats
echo "CPU: $CPU_USAGE%" >> $LOG_FILE
echo "Memory: $MEMORY_USAGE%" >> $LOG_FILE
echo "Disk: $DISK_USAGE%" >> $LOG_FILE

# HTTP check
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $URL)

# Service check
if ! ps -ef | grep "[n]ginx" > /dev/null; then
    echo "Nginx down, restarting..." >> $LOG_FILE
    sudo systemctl restart $SERVICE_NAME
fi

# HTTP check fix
if [[ "$HTTP_STATUS" != "200" ]]; then
    echo "Service unhealthy, restarting..." >> $LOG_FILE
    sudo systemctl restart $SERVICE_NAME
fi

# Docker check
if ! docker ps | grep -q $CONTAINER; then
    echo "Container down, restarting..." >> $LOG_FILE
    docker restart $CONTAINER || true
fi

echo "Completed" >> $LOG_FILE
