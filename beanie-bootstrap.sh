#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Please run this script as root."
  exit 1
fi

if id "1000" &>/dev/null; then
    USER_NAME=$(id -nu 1000)
else
    echo "❌ No non-root user found with UID 1000."
    exit 1
fi

USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
echo "[*] Configuring Beanie for user: $USER_NAME"

dnf upgrade -y
dnf install -y dnf-plugins-core curl git

dnf groupinstall -y "GNOME Desktop Environment" --setopt=group_package_types=mandatory,default
dnf install -y xorg-x11-server-Xorg xorg-x11-xinit mesa-dri-drivers \
gdm nautilus gnome-software gnome-text-editor gnome-terminal \
eog yelp abrt gnome-control-center gnome-maps gnome-calendar \
gnome-contacts gnome-weather gnome-music gnome-boxes \
pipewire pipewire-alsa pipewire-pulse wireplumber \
flatpak gnome-software-plugin-flatpak

systemctl enable gdm
systemctl set-default graphical.target

if grep -q "^WaylandEnable=false" /etc/gdm/custom.conf; then
    sed -i 's/^WaylandEnable=false/#WaylandEnable=false/' /etc/gdm/custom.conf
fi

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.zenbrowser.Zen

dnf install -y opendoas
echo "permit :wheel" > /etc/doas.conf

mkdir -p "$USER_HOME/.local/bin"
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.local"

HOME="$USER_HOME" bash -c 'curl -sS https://raw.githubusercontent.com/roguehashrate/pkgz/main/install.sh | bash'
chown "$USER_NAME:$USER_NAME" "$USER_HOME/.local/bin/pkgz"

grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$USER_HOME/.bashrc" || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.bashrc"

mkdir -p "$USER_HOME/.config/pkgz"
cat > "$USER_HOME/.config/pkgz/config.toml" <<EOL
[sources]
dnf = true
flatpak = true

[elevator]
command = "doas"
EOL
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/pkgz"

dnf install -y gedit gnome-terminal vlc

dnf clean all
rm -rf /var/cache/dnf

echo "[✓] Beanie bootstrap complete. Reboot recommended."
