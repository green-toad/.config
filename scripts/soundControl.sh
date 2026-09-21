CARD=$(pactl list cards short | awk '/bluez_card/{print $2; exit}')


echo "устройство:"
echo $CARD
echo ""

echo "оступные профили:"

pactl list cards | awk -v c="Name: $CARD" '
  index($0, c) {f=1; next}
  f && /^\tProfiles:/ {p=1; next}
  f && p && /^\t\t[a-z]/ {sub(/^[ \t]+/,""); sub(/:.*/,""); print}
  f && p && /^\t[A-Z]/ {exit}
'
echo ""

echo "актуальный профиль:"

pactl list cards | awk -v c="Name: $CARD" '
  index($0, c) {f=1}
  f && /Active Profile:/ {print $NF; exit}
'
echo ""

if [[ "$1" == "select" || "$1" == "-s" ]]; then
    echo "выбери новый режим:"
    read profile

    pactl set-card-profile "$CARD" $profile
fi
