wp=$(find $HOME/.config/wallpapers -maxdepth 1 -type f -print | shuf -n 1)

cp $wp $HOME/.config/wallpapers/swap/image.jpg

hellwal -i $wp


cp $HOME/.cache/hellwal/qlm-colors.qml $HOME/.config/quickshell/bigClock/Colors.qml

cp $HOME/.cache/hellwal/qlm-colors.qml $HOME/.config/quickshell/arch-panel/Colors.qml

cp $HOME/.cache/hellwal/qlm-colors.qml $HOME/.config/quickshell/kaomoji/Colors.qml

cp $HOME/.cache/hellwal/theme.toml .config/elio/theme.toml

killall hyprpaper
hyprpaper &
