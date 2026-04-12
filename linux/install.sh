#!/usr/bin/env bash
set -euo pipefail

APP_NAME="afterkey"
INSTALL_DIR="$HOME/.local/share/$APP_NAME"
BIN_LINK="$HOME/.local/bin/$APP_NAME"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== AfterKey installer (Linux) ==="

if ! groups | grep -qw input; then
    echo ""
    echo "WARNING: You are not in the 'input' group."
    echo "AfterKey needs access to /dev/input/* to read keyboard events."
    echo "Run:  sudo usermod -aG input \$USER"
    echo "Then log out and log back in."
    echo ""
fi

echo "Installing to $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR"/*.py "$INSTALL_DIR/"

echo "Creating venv and installing dependencies..."
python3 -m venv "$INSTALL_DIR/.venv"
"$INSTALL_DIR/.venv/bin/pip" install -q PyQt6 evdev

mkdir -p "$(dirname "$BIN_LINK")"
cat > "$BIN_LINK" <<LAUNCHER
#!/usr/bin/env bash
exec "$INSTALL_DIR/.venv/bin/python3" "$INSTALL_DIR/afterkey.py" "\$@"
LAUNCHER
chmod +x "$BIN_LINK"

mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=AfterKey
Comment=Keystroke overlay
Exec=$INSTALL_DIR/.venv/bin/python3 $INSTALL_DIR/afterkey.py
Icon=input-keyboard
Type=Application
Categories=Utility;
StartupNotify=false
X-KDE-autostart-after=panel
EOF

echo ""
echo "Done! You can now:"
echo "  - Run:  $APP_NAME"
echo "  - Or launch 'AfterKey' from your application menu"
echo ""
echo "To autostart on login, copy the desktop file:"
echo "  cp $DESKTOP_FILE ~/.config/autostart/"
