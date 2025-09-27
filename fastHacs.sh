#!/bin/bash
set -e

echo "🔍 Ищу контейнер homeassistant..."
CONTAINER_ID=$(docker ps --filter "name=homeassistant" --format "{{.ID}}" | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
  echo "❌ Контейнер homeassistant не найден!"
  exit 1
fi

echo "✅ Найден контейнер: $CONTAINER_ID"

TMP_DIR=$(mktemp -d)
echo "📂 Использую временный каталог: $TMP_DIR"

echo "⬇️ Скачиваю HACS..."
curl -sL https://github.com/hacs/integration/releases/latest/download/hacs.zip -o "$TMP_DIR/hacs.zip"

echo "📦 Распаковываю..."
unzip -q "$TMP_DIR/hacs.zip" -d "$TMP_DIR"

# теперь папка называется просто "hacs"
if [ ! -d "$TMP_DIR/hacs" ]; then
  echo "❌ Ошибка: после распаковки нет папки hacs!"
  exit 1
fi

echo "📤 Копирую HACS в контейнер..."
docker exec "$CONTAINER_ID" mkdir -p /config/custom_components/hacs
docker cp "$TMP_DIR/hacs/." "$CONTAINER_ID":/config/custom_components/hacs/

rm -rf "$TMP_DIR"

echo "✅ Установка завершена!"
echo "ℹ️ Перезапусти Home Assistant через интерфейс или командой:"
echo "   docker restart $CONTAINER_ID"