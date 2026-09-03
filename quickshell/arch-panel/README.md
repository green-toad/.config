# arch-panel — панель для Quickshell

Компактная панель 800×30px, расположена вверху по центру экрана.

## Структура

```
arch-panel/
├── shell.qml              # точка входа
├── Panel.qml               # PanelWindow: бар + выпадающая часть (единый surface)
├── DropdownPanel.qml        # содержимое выпадающей панели
├── Widgets/
│   ├── Workspaces.qml       # кружки рабочих столов (Hyprland IPC)
│   ├── SysTray.qml          # системный трей (Quickshell.Services.SystemTray)
│   ├── CircularGauge.qml    # круговой индикатор (CPU/RAM)
│   ├── QuickStatusRow.qml   # громкость / Wi-Fi / батарея
│   ├── UpdateButton.qml     # кнопка "Обновить" → scripts/update.sh
│   └── ImageDropZone.qml    # drag&drop зона → scripts/on-image-drop.sh
├── Services/
│   ├── qmldir                # регистрация singleton-сервисов
│   ├── SystemUsage.qml       # CPU/RAM из /proc
│   ├── AudioService.qml      # громкость через wpctl (PipeWire)
│   ├── WifiService.qml       # SSID через nmcli
│   └── BatteryService.qml    # заряд через Quickshell.Services.UPower
└── scripts/
    ├── update.sh              # пример: pacman/paru/yay -Syu
    └── on-image-drop.sh       # пример: обработка перетащенного файла
```

## Как это работает

- **Один `PanelWindow`**, а не два отдельных окна: у него `implicitHeight`
  анимированно меняется между `30px` и `30px + высота дропдауна`. Именно
  поэтому выпадающая часть визуально "вытекает" из панели, как в
  референсе (vast-shell использует тот же принцип единого layer-surface,
  расширяющегося вниз, вместо отдельного popup-окна).
- **Логотип дистрибутива** — `MouseArea` с `hoverEnabled: true` на левой
  зоне бара. При наведении вызывается `requestOpen()`, `Timer` с задержкой
  закрывает панель, если курсор ушёл и с логотипа, и с самой дропдаун-зоны
  (чтобы не мигало при переходе мыши между ними).
- **Рабочие столы** — `Workspaces.qml` подписан на `Hyprland.workspaces` /
  `Hyprland.focusedWorkspace`, активный кружок шире и подсвечен акцентным
  цветом (`Behavior` анимирует переход).
- **Системный трей** — прямое использование `Quickshell.Services.SystemTray`
  + `QsMenuAnchor`, поэтому все контекстные меню приложений (в т.ч. правый
  клик) работают "из коробки", без самописной реализации протокола.
- **Кнопка «Обновить»** и **окно для перетаскивания изображений** только
  вызывают внешние bash-скрипты через `Quickshell.Io.Process` —
  никакой логики применения темы/стиля внутри QML нет, это оставлено
  полностью на стороне скрипта.

## Установка

Требуется Quickshell (`quickshell-git` в AUR) и Hyprland.

```bash
mkdir -p ~/.config/quickshell/arch-panel
cp -r ./* ~/.config/quickshell/arch-panel/
mkdir -p ~/.config/arch-panel/scripts
cp scripts/*.sh ~/.config/arch-panel/scripts/
chmod +x ~/.config/arch-panel/scripts/*.sh

quickshell -c ~/.config/quickshell/arch-panel
```

Зависимости для скриптов и виджетов: `wireplumber` (wpctl), `networkmanager`
(nmcli), `upower`, `libnotify`, шрифт с глифами Nerd Font
(`ttf-nerd-fonts-symbols` или аналог) — иначе иконки в баре не отобразятся.

## Настройка под себя

- Замените глиф Arch-логотипа в `Panel.qml` (`logoArea`) на путь к SVG/PNG
  через `Image`, если не хотите использовать Nerd Font glyph.
- `scriptPath` в `UpdateButton.qml` и `ImageDropZone.qml` можно вынести в
  общий JSON-конфиг по аналогии с `Data/configurations.json` в vast-shell.
- Количество видимых рабочих столов регулируется `visibleCount` в
  `Workspaces.qml` (по умолчанию 5).
