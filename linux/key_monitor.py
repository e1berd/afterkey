import threading
from selectors import DefaultSelector, EVENT_READ

import evdev
from evdev import ecodes
from PyQt6.QtCore import QObject, pyqtSignal

from keymap import key_name, MODIFIER_KEYS
from settings import settings


class KeyEventBridge(QObject):
    key_pressed = pyqtSignal(str)

    def __init__(self):
        super().__init__()
        self._active_modifiers: set[int] = set()
        self._stop = threading.Event()

    def start(self):
        self._stop.clear()
        threading.Thread(target=self._read_loop, daemon=True).start()

    def stop(self):
        self._stop.set()

    def _find_keyboards(self) -> list[evdev.InputDevice]:
        devices = []
        for path in evdev.list_devices():
            dev = evdev.InputDevice(path)
            caps = dev.capabilities(verbose=False)
            has_keys = ecodes.EV_KEY in caps
            if has_keys and ecodes.KEY_A in caps[ecodes.EV_KEY] and ecodes.KEY_Z in caps[ecodes.EV_KEY]:
                devices.append(dev)
            else:
                dev.close()
        return devices

    def _read_loop(self):
        keyboards = self._find_keyboards()
        if not keyboards:
            print("ERROR: No keyboard devices found. Make sure you are in the 'input' group.")
            return

        print(f"Monitoring {len(keyboards)} keyboard(s): {[d.name for d in keyboards]}")

        selector = DefaultSelector()
        for dev in keyboards:
            selector.register(dev, EVENT_READ)

        try:
            while not self._stop.is_set():
                for key, _ in selector.select(timeout=0.1):
                    try:
                        for event in key.fileobj.read():
                            if event.type == ecodes.EV_KEY:
                                self._handle_key(event)
                    except OSError:
                        pass
        finally:
            selector.close()
            for dev in keyboards:
                dev.close()

    def _handle_key(self, event):
        code = event.code

        if code in MODIFIER_KEYS:
            (self._active_modifiers.add if event.value in (1, 2) else self._active_modifiers.discard)(code)
            return

        if event.value != 1:
            return

        name = key_name(code)
        if not name:
            return

        mods = self._modifier_prefix() if settings["show_modifiers"] else ""
        self.key_pressed.emit(mods + name)

    def _modifier_prefix(self) -> str:
        has = self._active_modifiers
        parts = []
        if has & {ecodes.KEY_LEFTMETA, ecodes.KEY_RIGHTMETA}:
            parts.append("Super+")
        if has & {ecodes.KEY_LEFTCTRL, ecodes.KEY_RIGHTCTRL}:
            parts.append("Ctrl+")
        if has & {ecodes.KEY_LEFTALT, ecodes.KEY_RIGHTALT}:
            parts.append("Alt+")
        if has & {ecodes.KEY_LEFTSHIFT, ecodes.KEY_RIGHTSHIFT}:
            parts.append("Shift+")
        return "".join(parts)
