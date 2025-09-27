#!/usr/bin/env bash
set -e

# 1. Имя контейнера (по умолчанию homeassistant)
CONTAINER_NAME=${1:-homeassistant}

# 2. Поиск ID запущенного контейнера
CONTAINER_ID=$(docker ps -qf "name=${CONTAINER_NAME}")

if [ -z "$CONTAINER_ID" ]; then
  echo "❌ Контейнер с именем ‘${CONTAINER_NAME}’ не найден."
  exit 1
fi

echo "🔍 Найден контейнер ${CONTAINER_NAME} (${CONTAINER_ID})"

# 3. Временный каталог на хосте
TMP_DIR=$(mktemp -d)
echo "📂 Использую временный каталог: $TMP_DIR"

# 4. Скачивание последней версии HACS
echo "⬇️ Скачиваю HACS..."
curl -L https://github.com/hacs/integration/releases/latest/download/hacs.zip -o "$TMP_DIR/hacs.zip"

# 5. Распаковка архива
unzip -q "$TMP_DIR/hacs.zip" -d "$TMP_DIR"

# 6. Копирование в контейнер (внутрь /config/custom_components)
echo "📦 Копирую HACS в контейнер..."
docker exec "$CONTAINER_ID" sh -c 'mkdir -p /config/custom_components'
docker cp "$TMP_DIR/custom_components/hacs" "$CONTAINER_ID:/config/custom_components/"

# 7. Очистка временных файлов
rm -rf "$TMP_DIR"

# 8. Перезапуск контейнера
docker restart "$CONTAINER_ID"
echo "✅ HACS установлен и контейнер перезапущен."