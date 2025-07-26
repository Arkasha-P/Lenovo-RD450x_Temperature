#!/bin/bash

# Конфигурация
LOG_FILE="/var/log/cpu_temp_monitor.log"
LOCK_FILE="/var/run/cpu_temp_monitor.pid"
HIGH_TEMP=50    # Порог включения усиленного охлаждения
LOW_TEMP=40     # Порог отключения усиленного охлаждения
CHECK_INTERVAL=5 # Интервал проверки (секунд)
COOLING_MODE=false # Текущий режим кулеров

# Защита от дублирования
if [ -f "$LOCK_FILE" ]; then
    if ps -p $(cat "$LOCK_FILE") >/dev/null 2>&1; then
        echo "Ошибка: Скрипт уже запущен (PID: $(cat "$LOCK_FILE"))" | tee -a "$LOG_FILE"
        exit 1
    else
        rm -f "$LOCK_FILE"
    fi
fi
echo $$ > "$LOCK_FILE"
trap "rm -f '$LOCK_FILE'; exit" SIGINT SIGTERM

# Функция управления кулерами
cooling_control() {
    local mode=$1
    case $mode in
        "high")
            ipmitool raw 0x2e 0x30 00 00 100 >> "$LOG_FILE" 2>&1
            COOLING_MODE=true
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Включен турбо-режим кулеров (Max temp: $2°C)" >> "$LOG_FILE"
            ;;
        "low")
            ipmitool raw 0x2e 0x30 00 00 30 >> "$LOG_FILE" 2>&1
            COOLING_MODE=false
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Включен нормальный режим кулеров (Max temp: $2°C)" >> "$LOG_FILE"
            ;;
    esac
}

# Функция получения температуры с обработкой ошибок
get_cpu_temp() {
    local sensor=$1
    local temp=$(ipmitool sensor reading "$sensor" 2>/dev/null | awk '{print $NF}' | tr -dc '0-9')
    [[ -z "$temp" || ! "$temp" =~ ^[0-9]+$ ]] && { echo "ERROR"; return 1; }
    echo "$temp"
}

# Основной цикл мониторинга
while true; do
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # Получаем температуры обоих процессоров
    temp1=$(get_cpu_temp "CPU1 Temp")
    temp2=$(get_cpu_temp "CPU2 Temp")

    # Определяем максимальную температуру
    max_temp=$(( temp1 > temp2 ? temp1 : temp2 ))

    # Логирование
    echo "[$timestamp] CPU1: ${temp1}°C, CPU2: ${temp2}°C, Max: ${max_temp}°C" >> "$LOG_FILE"

    # Управление кулерами с гистерезисом по максимальной температуре
    if $COOLING_MODE; then
        # Если кулеры в турбо-режиме, проверяем снижение до LOW_TEMP
        if [ "$max_temp" -le "$LOW_TEMP" ]; then
            cooling_control "low" "$max_temp"
        fi
    else
        # Если кулеры в нормальном режиме, проверяем превышение HIGH_TEMP
        if [ "$max_temp" -ge "$HIGH_TEMP" ]; then
            cooling_control "high" "$max_temp"
        fi
    fi

    sleep $CHECK_INTERVAL
done
