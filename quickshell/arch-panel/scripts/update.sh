#!/usr/bin/env bash
# Пример скрипта обновления системы. Вызывается панелью без аргументов.
# Реализацию смены стиля/темы делать не нужно — только собственно обновление.
set -euo pipefail

notify-send "Arch Panel" "Запуск обновления системы..." -i system-software-update || true

# pacman + AUR helper (paru/yay), при необходимости замените под себя
if command -v paru >/dev/null 2>&1; then
    paru -Syu --noconfirm
elif command -v yay >/dev/null 2>&1; then
    yay -Syu --noconfirm
else
    sudo pacman -Syu --noconfirm
fi

notify-send "Arch Panel" "Обновление завершено" -i system-software-update || true
