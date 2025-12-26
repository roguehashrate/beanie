# beanie.ks - Built for Fedora 43 (2025)
%include /usr/share/spin-kickstarts/fedora-live-budgie.ks

%packages
neovim
htop
zoxide
opendoas
flatpak
curl
git
-sudo
%end

%post
# Configure doas system-wide
echo "permit :wheel" > /etc/doas.conf
ln -sf /usr/bin/doas /usr/local/bin/sudo

# Create the First-Boot Setup Script
cat <<'EOF' > /usr/local/bin/beanie-bootstrap.sh
#!/bin/bash
USER_NAME=$(id -nu 1000)
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

if [ ! -z "$USER_NAME" ]; then
    mkdir -p "$USER_HOME/.local/bin"
    mkdir -p "$USER_HOME/.config/pkgz"

    # Install pkgz
    HOME="$USER_HOME" bash -c 'curl -sS raw.githubusercontent.com | bash'

    # Create config.toml
    cat > "$USER_HOME/.config/pkgz/config.toml" <<EOL
[sources]
dnf = true
flatpak = true

[elevator]
command = "doas"
EOL

    # Fix Path and shell env
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.bashrc"
    echo 'eval "$(zoxide init bash)"' >> "$USER_HOME/.bashrc"

    # Pre-install Zen Browser (Flatpak)
    flatpak remote-add --if-not-exists flathub dl.flathub.org
    flatpak install -y flathub io.github.zen_browser.zen

    chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.local" "$USER_HOME/.config"
    rm /etc/profile.d/beanie-trigger.sh
fi
EOF

chmod +x /usr/local/bin/beanie-bootstrap.sh

# Trigger the bootstrap on first login
cat <<'EOF' > /etc/profile.d/beanie-trigger.sh
#!/bin/bash
[ -f /usr/local/bin/beanie-bootstrap.sh ] && /usr/local/bin/beanie-bootstrap.sh
EOF

chmod +x /etc/profile.d/beanie-trigger.sh
%end
