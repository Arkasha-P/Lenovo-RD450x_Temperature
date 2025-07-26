#!/bin/bash

# Конфигурация
SCRIPT_NAME="temp_cpu.sh"
SERVICE_NAME="cpu_temp_monitor"
GITHUB_RAW_URL="https://raw.githubusercontent.com/Arkasha-P/Lenovo-RD450x_Temperature/main/temp_cpu.sh"
INSTALL_DIR="/usr/local/bin"
LOG_DIR="/var/log"
SERVICE_DIR="/etc/systemd/system"

# Скачивание скрипта
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ Скачивание и настройка скрипта...                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
wget -q "$GITHUB_RAW_URL" -O "$INSTALL_DIR/$SCRIPT_NAME" || {
    echo "Ошибка при скачивании скрипта!"
    exit 1
}

# Настройка прав
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
touch "$LOG_DIR/$SERVICE_NAME.log"
chmod 644 "$LOG_DIR/$SERVICE_NAME.log"

# Создание systemd службы
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ Создание systemd службы...                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
cat > "$SERVICE_DIR/$SERVICE_NAME.service" <<EOL
[Unit]
Description=CPU Temperature Monitor
After=network.target

[Service]
Type=simple
EnvironmentFile=$CONFIG_FILE
ExecStart=$INSTALL_DIR/$SCRIPT_NAME
Restart=always
RestartSec=5
User=root
StandardOutput=append:$LOG_DIR/$SERVICE_NAME.log
StandardError=append:$LOG_DIR/$SERVICE_NAME.log

[Install]
WantedBy=multi-user.target
EOL

# Обновление systemd
systemctl daemon-reload

# Включение автозапуска
systemctl enable "$SERVICE_NAME.service" >/dev/null 2>&1

# Запуск службы
systemctl start "$SERVICE_NAME.service"

# Добавление алиаса
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ Настройка алиасов...                                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
ALIAS_CMD="alias tempmon='tail -f $LOG_DIR/$SERVICE_NAME.log'"
grep -qF "$ALIAS_CMD" ~/.bashrc || echo "$ALIAS_CMD" >> ~/.bashrc
source ~/.bashrc

# Итоговая информация
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ Установка успешно завершена!                               ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║ Основной скрипт: $INSTALL_DIR/$SCRIPT_NAME                ║"
echo "║ Логи:            $LOG_DIR/$SERVICE_NAME.log              ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║ Команды управления:                                        ║"
echo "║   Просмотр логов: tempmon                                  ║"
echo "║   Статус службы: systemctl status $SERVICE_NAME          ║"
echo "║   Перезапуск:    systemctl restart $SERVICE_NAME         ║"
echo "║   Редактировать: nano $INSTALL_DIR/$SCRIPT_NAME           ║"
echo "╚════════════════════════════════════════════════════════════╝"
