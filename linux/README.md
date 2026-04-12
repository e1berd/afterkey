# AfterKey — Linux

Keystroke overlay for Linux (KDE Plasma / Wayland / X11).
Built with PyQt6 + evdev.

## Requirements

- Python 3.10+
- User must be in the `input` group:
  ```
  sudo usermod -aG input $USER
  ```
  Then log out and log back in.

## Run from source

```bash
python3 -m venv .venv
.venv/bin/pip install PyQt6 evdev
.venv/bin/python3 afterkey.py
```

## Build standalone binary

```bash
.venv/bin/pip install pyinstaller
.venv/bin/pyinstaller --onefile --name afterkey --windowed afterkey.py
```

Binary will be in `dist/afterkey`.

## Install system-wide

```bash
chmod +x install.sh
./install.sh
```

This creates a venv in `~/.local/share/afterkey/`, a launcher in `~/.local/bin/`,
and a `.desktop` file for the application menu.

To autostart on login:
```
cp ~/.local/share/applications/afterkey.desktop ~/.config/autostart/
```

## Project structure

```
afterkey.py          — entry point
settings.py          — persistent settings (QSettings)
keymap.py            — evdev keycode → symbol mapping
key_monitor.py       — keyboard capture via evdev (background thread)
overlay.py           — transparent overlay window with key bubbles
settings_window.py   — settings GUI (General / Appearance / Position)
tray.py              — system tray icon and menu
```
