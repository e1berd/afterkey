# AfterKey — Windows (alpha)

> **Alpha version.** Not yet tested on real hardware. May contain bugs.

Keystroke overlay for Windows.
Built with C# / WPF / .NET 8. Zero external dependencies.

## Requirements

- Windows 10/11
- [.NET 8 Runtime](https://dotnet.microsoft.com/download/dotnet/8.0) (or SDK to build from source)

## Build

```powershell
cd AfterKey
dotnet build -c Release
```

Binary will be in `AfterKey/bin/Release/net8.0-windows/`.

## Publish as single file

```powershell
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
```

## Project structure

```
AfterKey/
├── App.xaml / App.xaml.cs            — entry point, system tray
├── KeyMap.cs                         — virtual key codes → symbols
├── KeyboardHook.cs                   — Win32 low-level keyboard hook
├── AppSettings.cs                    — JSON-backed persistent settings
├── OverlayWindow.xaml / .xaml.cs     — transparent always-on-top overlay
├── SettingsWindow.xaml / .xaml.cs     — settings UI (General / Appearance / Position)
└── AfterKey.csproj
```

## How it works

- Keyboard capture via `SetWindowsHookEx` with `WH_KEYBOARD_LL`
- Overlay uses `WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW` for click-through and no taskbar entry
- Settings stored in `%APPDATA%/AfterKey/settings.json`
- System tray via `NotifyIcon`
