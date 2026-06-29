wp=$(find /home/nyashka/.config/wallpapers -maxdepth 1 -type f -print | shuf -n 1)

cat > /home/nyashka/.config/hypr/hyprpaper.conf <<EOF
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

killall hyprpaper
hyprpaper &

killall waybar
waybar &
