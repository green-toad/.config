sudo pacman -S --needed --noconfirm \
    hyprland neovim quickshell \
    dotnet-runtime dotnet-sdk base-devel git \
    mako firefox telegram-desktop zsh \
    bluez bluez-utils \
    pipewire pipewire-pulse pipewire-alsa pipewire-audio wireplumber \
    brightnessctl playerctl \
    hyprpaper fastfetch kitty xdg-desktop-portal-hyprland \
    hyprpolkitagent curl wget docker-compose ly ttf-nerd-fonts-symbols \
    hyprshot nmap metasploit ttf-dejavu

sudo systemctl enable --now bluetooth
systemctl --user enable --now pipewire pipewire-pulse wireplumber

cd ~/

git clone https://aur.archlinux.org/yay-git.git 
cd ~/yay-git
yes | makepkg -si
cd ~/
rm -rf yay-git

rm -rf .config
git clone https://github.com/green-toad/.config.git

chmod +x ~/.config/scripts/*.sh

yay -S --noconfirm hellwal mikusays github-desktop-bin

cat <<EOF > myAliases.txt
alias bnr='dotnet restore && dotnet build && dotnet run'
alias fbnr='dotnet build && dotnet run'
alias r='dotnet run'
alias bnp='dotnet restore && dotnet publish -c Release -r linux-x64 --self-contained -p:PublishSingleFile=true'
alias ff='fastfetch'
alias vnv='python -m venv .venv'
alias evnv='source .venv/bin/activate'
alias conf='nvim ~/.config'
alias off='shutdown now'
alias nslnx='~/.config/scripts/newSlnx.sh'
alias switchMyWallPap='~/.config/scripts/genColor.sh'
alias bns='dotnet restore && dotnet build -c Release'
alias fullupgrade='~/.config/scripts/fullUpdate.sh'
alias setHPparam='~/.config/scripts/soundControl.sh'
EOF

wget https://download.docker.com/linux/static/stable/x86_64/docker-29.8.2.tgz -qO- | tar xvfz - docker/docker --strip-components=1
sudo cp -rp ./docker /usr/local/bin/ && rm -r ./docker
sudo usermod -aG docker "$USER"

~/.config/scripts/fullUpdate.sh

sudo hostnamectl set-hostname nyashtop
sudo sed -i "s/127.0.1.1.*/127.0.1.1 nyashtop/" /etc/hosts

sudo systemctl enable ly@tty1.service
sudo systemctl disable getty@tty1.service

sudo cp ~/.config/ly/config.ini /etc/ly/config.ini
