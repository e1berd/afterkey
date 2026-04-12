from evdev import ecodes


SPECIAL_KEYS = {
    ecodes.KEY_TAB: "⇥",
    ecodes.KEY_SPACE: "␣",
    ecodes.KEY_ENTER: "↵",
    ecodes.KEY_KPENTER: "↵",
    ecodes.KEY_BACKSPACE: "⌫",
    ecodes.KEY_ESC: "ESC",
    ecodes.KEY_LEFT: "←",
    ecodes.KEY_RIGHT: "→",
    ecodes.KEY_DOWN: "↓",
    ecodes.KEY_UP: "↑",
    ecodes.KEY_DELETE: "DEL",
    ecodes.KEY_HOME: "HOME",
    ecodes.KEY_END: "END",
    ecodes.KEY_PAGEUP: "PGUP",
    ecodes.KEY_PAGEDOWN: "PGDN",
    ecodes.KEY_INSERT: "INS",
    ecodes.KEY_CAPSLOCK: "CAPS",
    **{getattr(ecodes, f"KEY_F{i}"): f"F{i}" for i in range(1, 13)},
    ecodes.KEY_PRINT: "PRTSC",
    ecodes.KEY_SCROLLLOCK: "SCRLK",
    ecodes.KEY_PAUSE: "PAUSE",
}

MODIFIER_KEYS = {
    ecodes.KEY_LEFTCTRL, ecodes.KEY_RIGHTCTRL,
    ecodes.KEY_LEFTSHIFT, ecodes.KEY_RIGHTSHIFT,
    ecodes.KEY_LEFTALT, ecodes.KEY_RIGHTALT,
    ecodes.KEY_LEFTMETA, ecodes.KEY_RIGHTMETA,
}

_SYMBOL_MAP = {
    "KEY_MINUS": "-", "KEY_EQUAL": "=",
    "KEY_LEFTBRACE": "[", "KEY_RIGHTBRACE": "]",
    "KEY_SEMICOLON": ";", "KEY_APOSTROPHE": "'",
    "KEY_GRAVE": "`", "KEY_BACKSLASH": "\\",
    "KEY_COMMA": ",", "KEY_DOT": ".", "KEY_SLASH": "/",
}

_CHAR_MAP: dict[int, str] = {}
for _code, _name in ecodes.KEY.items():
    _name = _name[0] if isinstance(_name, (list, tuple)) else _name
    if not _name.startswith("KEY_"):
        continue
    suffix = _name[4:]
    if len(suffix) == 1 and suffix.isalpha():
        _CHAR_MAP[_code] = suffix.upper()
    elif suffix.isdigit():
        _CHAR_MAP[_code] = suffix
    elif _name in _SYMBOL_MAP:
        _CHAR_MAP[_code] = _SYMBOL_MAP[_name]


def key_name(code: int) -> str | None:
    return SPECIAL_KEYS.get(code) or _CHAR_MAP.get(code)
