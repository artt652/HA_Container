#!/bin/bash
set -e

echo "📦 Список запущенных контейнеров:"

# Используем mapfile вместо $() с split
mapfile -t CONTAINERS < <(docker ps --format "{{.Names}}")

if [ "${#CONTAINERS[@]}" -eq 0 ]; then
    echo "❌ Нет запущенных контейнеров."
    exit 1
fi

DEFAULT_INDEX=-1
for i in "${!CONTAINERS[@]}"; do
    echo "[$i] ${CONTAINERS[$i]}"
    if [ "${CONTAINERS[$i]}" == "homeassistant" ]; then
        DEFAULT_INDEX=$i
    fi
done

if [ $DEFAULT_INDEX -ne -1 ]; then
    echo "ℹ️ По умолчанию выбран контейнер 'homeassistant' (номер $DEFAULT_INDEX)"
else
    DEFAULT_INDEX=0
    echo "ℹ️ По умолчанию выбран первый контейнер в списке (номер 0)"
fi

# read -r чтобы избежать проблем с обратными слэшами
read -r -p "Введите номер контейнера для установки HACS (по умолчанию $DEFAULT_INDEX): " INDEX
INDEX=${INDEX:-$DEFAULT_INDEX}

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
echo "⏳ Перезапускаем контейнер ${CONTAINER_NAME}..."

if docker restart "$CONTAINER_NAME"; then
    echo "🔄 Контейнер перезапущен успешно."
else
    echo "❌ Не удалось перезапустить контейнер автоматически."
    echo "Используйте команду вручную:"
    echo "   docker restart ${CONTAINER_NAME}"
fi