#!/bin/bash
set -e

echo "🔍 Ищу контейнер homeassistant..."
CONTAINER_NAME="homeassistant"
CONTAINER_ID=$(docker ps --filter "name=${CONTAINER_NAME}" --format "{{.ID}}" | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
  echo "❌ Контейнер ${CONTAINER_NAME} не найден!"
  exit 1
fi

echo "✅ Найден контейнер: ${CONTAINER_ID}"

TMP_DIR=$(mktemp -d)
echo "📂 Использую временный каталог: ${TMP_DIR}"

echo "⬇️ Скачиваю HACS..."
curl -sL https://github.com/hacs/integration/releases/latest/download/hacs.zip -o "${TMP_DIR}/hacs.zip"

echo "📦 Распаковываю..."
unzip -q "${TMP_DIR}/hacs.zip" -d "${TMP_DIR}"

echo "📤 Создаю папку в контейнере..."
docker exec "${CONTAINER_NAME}" mkdir -p /config/custom_components/hacs

echo "📤 Копирую HACS в контейнер..."
docker cp "${TMP_DIR}/." "${CONTAINER_NAME}:/config/custom_components/hacs/"

rm -rf "${TMP_DIR}"

echo "✅ HACS установлен и готов!"
echo "ℹ️ Перезапусти Home Assistant:"
echo "   docker restart ${CONTAINER_NAME}"