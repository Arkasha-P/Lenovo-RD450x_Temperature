#!/bin/bash

systemctl stop cpu_temp_monitor
systemctl daemon-reload
rm /etc/systemd/system/cpu_temp_monitor.service
rm /usr/local/bin/cpu_temp_monitor.sh
rm /var/log/cpu_temp_monitor.log
sed -i '/tempmon/d' ~/.bashrc
