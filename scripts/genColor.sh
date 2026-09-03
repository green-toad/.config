wp=$(find $HOME/.config/wallpapers -maxdepth 1 -type f -print | shuf -n 1)

cat > $HOME/.config/hypr/hyprpaper.conf <<EOF
wallpaper {
        monitor = eDP-1
        path = $wp
        fit_mode = cover
}
wallpaper {
	monitor = HDMI-A-1
	path = $wp
	fit_mode = cover
}

splash=false
EOF

hellwal -i $wp


cp $HOME/.cache/hellwal/qlm-colors.qml $HOME/.config/quickshell/bigClock/Colors.qml

cp $HOME/.cache/hellwal/qlm-colors.qml $HOME/.config/quickshell/arch-panel/Colors.qml

killall hyprpaper
hyprpaper &
