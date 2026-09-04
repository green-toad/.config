cp $1 $HOME/.config/wallpapers/swap/image.jpg
wp=$HOME/.config/wallpapers/swap/image.jpg

hellwal -i $wp


cp $HOME/.cache/hellwal/qlm-colors.qml $HOME/.config/quickshell/bigClock/Colors.qml

cp $HOME/.cache/hellwal/qlm-colors.qml $HOME/.config/quickshell/arch-panel/Colors.qml

killall hyprpaper
hyprpaper &
