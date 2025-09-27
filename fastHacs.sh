#!/bin/bash
set -e

echo "🔍 Ищу контейнер homeassistant..."
CONTAINER_ID=$(docker ps --filter "name=homeassistant" --format "{{.ID}}" | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
  echo "❌ Контейнер homeassistant не найден!"
  exit 1
fi

echo "✅ Найден контейнер: $CONTAINER_ID"

# Временный каталог
TMP_DIR=$(mktemp -d)
echo "📂 Использую временный каталог: $TMP_DIR"

# Скачивание HACS
echo "⬇️ Скачиваю HACS..."
curl -sL https://github.com/hacs/integration/releases/latest/download/hacs.zip -o "$TMP_DIR/hacs.zip"

# Распаковка
echo "📦 Распаковываю..."
unzip -q "$TMP_DIR/hacs.zip" -d "$TMP_DIR"

# Проверка папки
if [ ! -d "$TMP_DIR/custom_components/hacs" ]; then
  echo "❌ Ошибка: не найдена папка custom_components/hacs после распаковки!"
  exit 1
fi

# Копирование в контейнер
echo "📤 Копирую HACS в контейнер..."
docker exec "$CONTAINER_ID" mkdir -p /config/custom_components
docker cp "$TMP_DIR/custom_components/hacs" "$CONTAINER_ID":/config/custom_components/

# Очистка
rm -rf "$TMP_DIR"

echo "✅ Установка завершена!"
echo "ℹ️ Перезапусти Home Assistant через интерфейс или командой:"
echo "   docker restart $CONTAINER_ID"