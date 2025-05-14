#!/bin/bash

echo -e ''
echo -e "\033[32m========Sing-Box for OPNsense Установка пакетов в один клик=========\033[0m"
echo -e ''

# Определение расцветки
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

# Определение каталогов
ROOT="/usr/local"
BIN_DIR="$ROOT/bin"
WWW_DIR="$ROOT/www"
CONF_DIR="$ROOT/etc"
MODELS_DIR="$ROOT/opnsense/mvc/app/models/OPNsense"
RC_DIR="$ROOT/etc/rc.d"
PLUGINS="$ROOT/etc/inc/plugins.inc.d"
ACTIONS="$ROOT/opnsense/service/conf/actions.d"
RC_CONF="/etc/rc.conf.d/"
CONFIG_FILE="/conf/config.xml"
TMP_FILE="/tmp/config.xml.tmp"
TIMESTAMP=$(date +%F-%H%M%S)
BACKUP_FILE="/conf/config.xml.bak.$TIMESTAMP"

# Настройка ведения журнала
log() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# Создать каталог
log "$YELLOW" "Создать каталог..."
sleep 1
mkdir -p "$CONF_DIR/sing-box/ui" "$CONF_DIR/tun2socks" || log "$RED" "Не удалось создать каталог！"

# Копируем файл
log "$YELLOW" "Копируем файл..."
sleep 1
log "$YELLOW" "Генерация меню..."
# Удаляем кэш меню
rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json
sleep 1
log "$YELLOW" "Генерация данных..."
sleep 1
log "$YELLOW" "Меняем разрешение на файлы..."
sleep 1
chmod +x bin/*
chmod +x rc.d/*
cp -f bin/* "$BIN_DIR/" || log "$RED" "bin не удалось скопировать файл！"
cp -f www/* "$WWW_DIR/" || log "$RED" "www не удалось скопировать файл！"
cp -f plugins/* "$PLUGINS/" || log "$RED" "plugins не удалось скопировать файл！"
cp -f actions/* "$ACTIONS/" || log "$RED" "actions не удалось скопировать файл！"
cp -R -f menu/* "$MODELS_DIR/" || log "$RED" "menu не удалось скопировать файл！"
cp -R -f ui/* "$CONF_DIR/sing-box/ui/" || log "$RED" "ui не удалось скопировать файл！"
cp rc.d/* "$RC_DIR/" || log "$RED" "rc.d не удалось скопировать файл！"
cp conf/config_sing-box.json "$CONF_DIR/sing-box/config.json" || log "$RED" "sing-box не удалось выполнить копирование конфигурационного файла！"
cp conf/config_tun2socks.yaml "$CONF_DIR/tun2socks/config.yaml" || log "$RED" "tun2socks не удалось выполнить копирование конфигурационного файла！"
sleep 1

# Добавляем в автозагрузку
log "$YELLOW" "Настройка системных служб..."
cp -f rc.conf/* "$RC_CONF/" || log "$RED" "rc.conf не удалось скопировать файл！"
sleep 1

# Запуск интерфейса tun
log "$YELLOW" "Запуск tun2socks..."
service tun2socks start > /dev/null 2>&1
echo ""

# Резервная копия конфигурационного файла
cp "$CONFIG_FILE" "$BACKUP_FILE" || {
  echo "Не удалось выполнить резервное копирование конфигурации, отмена！"
  echo ""
  exit 1
}

# Добавляем интерфейс tun
log "$YELLOW" "Добавляем интерфейс tun..."
sleep 1
if grep -q "<if>tun_3000</if>" "$CONFIG_FILE"; then
  echo "Интерфейс с таким именем существует, пропускаем."
  echo ""
else
  awk '
  BEGIN { inserted = 0 }
  /<interfaces>/ { print; next }
  /<\/interfaces>/ && inserted == 0 {
    print "    <tun_3000>"
    print "      <if>tun_3000</if>"
    print "      <descr>TUN</descr>"
    print "      <enable>1</enable>"
    print "      <spoofmac/>"
    print "      <gateway_interface>1</gateway_interface>"
    print "      <ipaddr>10.10.0.1</ipaddr>"
    print "      <subnet>32</subnet>"
    print "    </tun_3000>"
    inserted = 1
  }
  { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
  echo "Добавление интерфейса завершено."
  echo ""
fi

# Добавить псевдоним CN_IP
log "$YELLOW" "Добавить псевдоним CN_IP..."
if grep -q "<content>https://ispip.clang.cn/all_cn.txt</content>" "$CONFIG_FILE"; then
  echo "Псевдоним уже существует, пропускаем."
  echo "" 
else
  awk '
  BEGIN { inserted = 0 }
  /<aliases\/>/ && inserted == 0 {
    print "        <aliases>"
    print "          <alias uuid=\"315eb669-41ef-48c2-90bb-d5c9d99a00eb\">"
    print "            <enabled>1</enabled>"
    print "            <name>CN_IP</name>"
    print "            <type>urltable</type>"
    print "            <path_expression/>"
    print "            <proto/>"
    print "            <interface/>"
    print "            <counters>0</counters>"
    print "            <updatefreq>1</updatefreq>"
    print "            <content>https://ispip.clang.cn/all_cn.txt</content>"
    print "            <password/>"
    print "            <username/>"
    print "            <authtype/>"
    print "            <categories/>"
    print "            <description>&#x4E2D;&#x56FD;IP&#x5217;&#x8868;</description>"
    print "          </alias>"
    print "        </aliases>"
    inserted = 1
    next
  }
  /<alias .*?>/ && inserted == 0 {
    print "          <alias uuid=\"315eb669-41ef-48c2-90bb-d5c9d99a00eb\">"
    print "            <enabled>1</enabled>"
    print "            <name>CN_IP</name>"
    print "            <type>urltable</type>"
    print "            <path_expression/>"
    print "            <proto/>"
    print "            <interface/>"
    print "            <counters>0</counters>"
    print "            <updatefreq>1</updatefreq>"
    print "            <content>https://ispip.clang.cn/all_cn.txt</content>"
    print "            <password/>"
    print "            <username/>"
    print "            <authtype/>"
    print "            <categories/>"
    print "            <description>&#x4E2D;&#x56FD;IP&#x5217;&#x8868;</description>"
    print "          </alias>"
    inserted = 1
  }
  { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
    echo "Добавление псевдонима завершено."
    echo "" 
fi

# Добавление правил брандмауэра (некитайский IP-адрес передается на прозрачный шлюз TUN_GW)
log "$YELLOW" "Добавление правил брандмауэра..."
sleep 1
if grep -q "<gateway>TUN_GW</gateway>" "$CONFIG_FILE"; then
  echo "Правило с таким названием существует, пропускаем."
  echo ""
else
  awk '
  /<filter>/ {
    print
    print "    <rule uuid=\"c0398153-597b-403b-9069-734734b46497\">"
    print "      <type>pass</type>"
    print "      <interface>lan</interface>"
    print "      <ipprotocol>inet</ipprotocol>"
    print "      <statetype>keep state</statetype>"
    print "      <descr>&#x56FD;&#x5916;IP&#x8D70;&#x900F;&#x660E;&#x7F51;&#x5173;</descr>"
    print "      <gateway>TUN_GW</gateway>"
    print "      <direction>in</direction>"
    print "      <floating>yes</floating>"
    print "      <quick>1</quick>"
    print "      <source>"
    print "        <network>lan</network>"
    print "      </source>"
    print "      <destination>"
    print "        <address>CN_IP</address>"
    print "        <not>1</not>"
    print "      </destination>"
    print "    </rule>"
    next
  }
  { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
  echo "Добавление правила завершено."
  echo ""
fi

# Меняем порт Unbound 5355
sleep 1
log "$YELLOW" "Меняем порт Unbound..."

PORT_OK=$(awk '
BEGIN {
  in_unbound = 0
  in_general = 0
}
/<unboundplus[^>]*>/ { in_unbound = 1 }
/<\/unboundplus>/ { in_unbound = 0 }
{
  if (in_unbound && /<general>/) {
    in_general = 1
  }
  if (in_unbound && /<\/general>/) {
    in_general = 0
  }
  if (in_unbound && in_general && /<port>5355<\/port>/) {
    print "yes"
    exit
  }
}
' "$CONFIG_FILE")

if [ "$PORT_OK" = "yes" ]; then
  echo "Порт уже 5355，пропускаем."
else
  awk '
  BEGIN {
    in_unbound = 0
    in_general = 0
    port_handled = 0
  }
  {
    if ($0 ~ /<unboundplus[^>]*>/) {
      in_unbound = 1
    }
    if ($0 ~ /<\/unboundplus>/) {
      in_unbound = 0
    }

    if (in_unbound && $0 ~ /<general>/) {
      in_general = 1
      print
      next
    }

    if (in_unbound && in_general && $0 ~ /<\/general>/) {
      if (port_handled == 0) {
        print "        <port>5355</port>"
        port_handled = 1
      }
      in_general = 0
      print
      next
    }

    if (in_unbound && in_general && $0 ~ /<port>.*<\/port>/ && port_handled == 0) {
      sub(/<port>.*<\/port>/, "<port>5355</port>")
      port_handled = 1
      print
      next
    }

    print
  }
  ' "$CONFIG_FILE" > "$TMP_FILE"

  if [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$CONFIG_FILE"
    echo "Порт был настроен на 5355"
  else
    log "$RED" "Не удалось настроить, проверьте файл конфигурации."
  fi
fi
echo ""

# Рестарт службы Unbound
log "$YELLOW" "Рестарт службы Unbound..."
/usr/local/etc/rc.d/unbound restart > /dev/null 2>&1
echo ""

# Рестарт брендмауэра
log "$YELLOW" "Рестарт брендмауэра..."
configctl filter reload > /dev/null 2>&1
echo ""

# Рестарт configd
log "$YELLOW" "Рестарт configd..."
service configd restart > /dev/null 2>&1
echo ""

# Рестарт всех служб
# log "$YELLOW" "Применение изменений..."
# /usr/local/etc/rc.reload_all >/dev/null 2>&1
# echo "Все службы перезапущены！"
# echo ""

# Завершение
log "$GREEN" "Перейдите на страницу VPN > Sing-Box"
echo ""
