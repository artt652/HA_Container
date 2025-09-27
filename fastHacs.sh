#!/bin/bash
set -e

CONTAINER_NAME=${1:-homeassistant}
echo "🔍 Ищу контейнер ${CONTAINER_NAME}..."
CONTAINER_ID=$(docker ps -qf "name=${CONTAINER_NAME}")

if [ -z "$CONTAINER_ID" ]; then
  echo "❌ Контейнер ${CONTAINER_NAME} не найден."
  exit 1
fi

TMP_DIR=$(mktemp -d)
echo "📂 Использую временный каталог: $TMP_DIR"

echo "⬇️ Скачиваю HACS..."
curl -sL https://github.com/hacs/integration/releases/latest/download/hacs.zip -o "$TMP_DIR/hacs.zip"

echo "📦 Распаковываю..."
unzip -q "$TMP_DIR/hacs.zip" -d "$TMP_DIR"

echo "📤 Копирую HACS в контейнер..."
docker exec "$CONTAINER_NAME" mkdir -p /config/custom_components/hacs
docker cp "$TMP_DIR/." "$CONTAINER_NAME":/config/custom_components/hacs/

rm -rf "$TMP_DIR"

echo "✅ Установка HACS завершена!"

read -p "Перезапустить контейнер ${CONTAINER_NAME}? [y/N] " REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    docker restart "$CONTAINER_NAME"
    echo "🔄 Контейнер перезапущен."
else
    echo "⚠️ Контейнер не перезапущен. Сделайте это вручную позже."
fi