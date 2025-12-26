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

dnf upgrade -y

dnf install -y opendoas neovim htop zoxide
echo "permit :wheel" > /etc/doas.conf

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub app.zen_browser.zen

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

echo
echo "[✓] Beanie Budgie bootstrap complete. Reboot recommended."
