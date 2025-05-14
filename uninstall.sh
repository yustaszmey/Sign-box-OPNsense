#!/bin/bash

echo -e ''
echo -e "\033[32m========Sing-box for OPNsense Удаление пакетов в один клик=========\033[0m"
echo -e ''

# Определение расцветки
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# Настройка ведения журнала
log() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# Удаление программ и конфигураций
log "$YELLOW" "Удаление программ и конфигураций, ожидайте..."
# Удаление конфигураций
rm -rf /usr/local/etc/sing-box
rm -rf /usr/local/etc/tun2socks

# Очистка rc.d
rm -f /usr/local/etc/rc.d/singbox
rm -f /usr/local/etc/rc.d/tun2socks

# Очистка rc.conf
rm -f /etc/rc.conf.d/tun2socks
rm -f /etc/rc.conf.d/singbox
# Очистка action
rm -f /usr/local/opnsense/service/conf/actions.d/actions_sing-box.conf
rm -f /usr/local/opnsense/service/conf/actions.d/actions_tun2socks.conf

# Очистка меню и кэша
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/singbox
rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json

# Очистка inc
rm -f /usr/local/etc/inc/plugins.inc.d/singbox.inc
rm -f /usr/local/etc/inc/plugins.inc.d/tun2socks.inc

# Очистка php
rm -f /usr/local/www/services_sing_box.php
rm -f /usr/local/www/services_tun2socks.php
rm -f /usr/local/www/status_sing_box_logs.php
rm -f /usr/local/www/status_sing_box.php
rm -f /usr/local/www/status_tun2socks_logs.php
rm -f /usr/local/www/status_tun2socks.php
rm -f /usr/local/www/sub.php

# Удаление программ
rm -f /usr/local/bin/sing-box
rm -f /usr/local/bin/tun2socks
echo ""

# Рестарт всех служб
log "$YELLOW" "Рестарт всех служб, ожидайте..."
/usr/local/etc/rc.reload_all >/dev/null 2>&1
service configd restart > /dev/null 2>&1
echo ""

# 完成提示
log "$GREEN" "После завершения деинсталляции, пожалуйста, вручную удалите интерфейс TUN, псевдоним и плавающие правила обхода брандмауэра и измените несвязанный DNS-порт на 53."
echo ""