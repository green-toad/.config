#!/usr/bin/env bash
# Пример скрипта обработки перетащенного изображения.
# Панель вызывает: bash on-image-drop.sh /путь/к/файлу
set -euo pipefail

FILE="${1:?Не передан путь к файлу}"

if [[ ! -f "$FILE" ]]; then
    notify-send "Arch Panel" "Файл не найден: $FILE" -i dialog-error
    exit 1
fi

# Пример: установить как обои через swaybg/hyprpaper, или запустить любую
# другую обработку — конвертацию, генерацию палитры matugen и т.д.
notify-send "Arch Panel" "Изображение получено: $(basename "$FILE")" -i "$FILE"

# Пример вызова генератора палитры (если используется matugen):
# matugen image "$FILE"
