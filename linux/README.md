# AfterKey — Linux

Keystroke overlay for Linux (KDE Plasma / Wayland / X11).
Built with C++ / Qt6.

## Requirements

- Qt6 (already installed on KDE Plasma)
- CMake 3.20+
- User must be in the `input` group:
  ```
  sudo usermod -aG input $USER
  ```
  Then log out and log back in.

## Build

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

Binary: `build/afterkey` (~130KB)

## Install

```bash
sudo cmake --install build
```

Or copy manually:
```bash
cp build/afterkey ~/.local/bin/
```

## Autostart

Copy the desktop file to autostart:
```bash
mkdir -p ~/.local/share/applications
cp afterkey.desktop ~/.local/share/applications/
cp afterkey.desktop ~/.config/autostart/
```

## Project structure

```
src/
├── main.cpp           — entry point
├── settings.h/cpp     — persistent settings (QSettings)
├── keymap.h/cpp       — evdev keycode → symbol mapping
├── keymonitor.h/cpp   — keyboard capture via evdev (separate thread)
├── overlay.h/cpp      — transparent overlay window
├── settingswindow.h/cpp — settings UI (General / Appearance / Position)
└── tray.h/cpp         — system tray icon and menu
```
