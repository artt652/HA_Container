#!/bin/bash
set -e

echo "📦 Список запущенных контейнеров:"
CONTAINERS=($(docker ps --format "{{.Names}}"))

if [ ${#CONTAINERS[@]} -eq 0 ]; then
    echo "❌ Нет запущенных контейнеров."
    exit 1
fi

for i in "${!CONTAINERS[@]}"; do
    echo "[$i] ${CONTAINERS[$i]}"
done

read -p "Выберите номер контейнера для установки HACS (по умолчанию 0): " INDEX
INDEX=${INDEX:-0}

if ! [[ "$INDEX" =~ ^[0-9]+$ ]] || [ "$INDEX" -ge "${#CONTAINERS[@]}" ]; then
    echo "❌ Неверный выбор."
    exit 1
fi

CONTAINER_NAME="${CONTAINERS[$INDEX]}"
echo "🔍 Выбран контейнер: ${CONTAINER_NAME}"

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
    echo "⚠️ Контейнер не перезапущен."
    echo "Пример команды для ручного перезапуска:"
    echo "   docker restart ${CONTAINER_NAME}"
fi