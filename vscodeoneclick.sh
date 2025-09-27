#!/bin/bash
set -e

LOG()  { echo -e "\e[1;32m[INFO]\e[0m $*"; }
ERR()  { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; exit 1; }

if [[ $EUID -ne 0 ]]; then
    ERR "Запусти скрипт от root или через sudo."
fi

echo "=== Установка code-server ==="

# --- Запрос пароля ---
read -r -s -p "Введите пароль для входа в code-server: " USER_PASSWORD; echo ""
read -r -s -p "Повторите пароль: " USER_PASSWORD_CONFIRM; echo ""
while [ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]; do
    echo "Пароли не совпадают. Попробуйте снова."
    read -r -s -p "Введите пароль: " USER_PASSWORD; echo ""
    read -r -s -p "Повторите пароль: " USER_PASSWORD_CONFIRM; echo ""
done
[ -n "$USER_PASSWORD" ] || ERR "Пароль не может быть пустым."

# --- Запрос порта ---
read -r -p "Введите порт для code-server (по умолчанию 8088): " USER_PORT
USER_PORT=${USER_PORT:-8088}

# --- Выбор раздела ---
mapfile -t raw_opts < <(df -h --output=target,avail | awk 'NR>1 && $2+0 > 1 {print $1}' | sort -u)
if [ ${#raw_opts[@]} -eq 0 ]; then
    ERR "Нет разделов с >1ГБ свободного места."
fi

if [ ${#raw_opts[@]} -eq 1 ]; then
    MOUNT_POINT="${raw_opts[0]}"
else
    echo "Выберите раздел для установки:"
    for i in "${!raw_opts[@]}"; do
        echo " $((i+1))) ${raw_opts[i]}"
    done
    read -rp "Номер: " CHOICE
    MOUNT_POINT="${raw_opts[$((CHOICE-1))]}"
fi

INSTALL_DIR="${MOUNT_POINT%/}/code-server"
LOG "Установка в: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# --- Определение архитектуры ---
ARCH=$(uname -m)
case "$ARCH" in
    armv7l)   PLATFORM="linux-armv7l" ;;
    aarch64)  PLATFORM="linux-arm64" ;;
    x86_64)   PLATFORM="linux-amd64" ;;
    *) ERR "Неизвестная архитектура: $ARCH" ;;
esac

# --- Скачивание code-server ---
URL=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest \
    | grep "browser_download_url" \
    | grep "$PLATFORM" \
    | cut -d '"' -f 4)
LOG "Скачивание: $URL"
curl -fsSL "$URL" | tar -xz --strip-components=1 -C "$INSTALL_DIR"

# --- Симлинк ---
ln -sf "$INSTALL_DIR/bin/code-server" /usr/local/bin/code-server

# --- Конфиг ---
mkdir -p "$INSTALL_DIR/config"
cat > "$INSTALL_DIR/config/config.yaml" <<EOF
bind-addr: 0.0.0.0:${USER_PORT}
auth: password
password: ${USER_PASSWORD}
cert: false
EOF

# --- systemd ---
cat > /etc/systemd/system/code-server.service <<EOF
[Unit]
Description=code-server
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/bin/code-server --config $INSTALL_DIR/config/config.yaml
Restart=always
Environment=HOME=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

# --- Запуск ---
systemctl daemon-reload
systemctl enable --now code-server

# --- Финальное сообщение ---
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo ""
echo "=============================================="
echo " Code-Server установлен!"
echo " Адрес: http://${IP_ADDRESS}:${USER_PORT}"
echo " Пароль: ${USER_PASSWORD}"
echo " Конфиг: $INSTALL_DIR/config/config.yaml"
echo "=============================================="
