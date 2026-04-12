from PyQt6.QtCore import QObject, QSettings, pyqtSignal


DEFAULTS = {
    "display_duration": 3.0,
    "max_keys": 5,
    "position": "bottom_right",
    "show_modifiers": True,
    "font_size": 32,
    "corner_radius": 12,
    "border_width": 1.0,
    "bg_color": "#000000",
    "bg_opacity": 0.3,
    "text_color": "#ffffff",
    "text_opacity": 1.0,
    "border_color": "#ffffff",
    "border_opacity": 0.2,
}

POSITIONS = [
    "top_left", "top_center", "top_right",
    "center_left", "center", "center_right",
    "bottom_left", "bottom_center", "bottom_right",
]

_TYPE_COERCE = {
    bool: lambda v: v in (True, "true", "True", "1"),
    float: float,
    int: int,
    str: str,
}


class Settings(QObject):
    changed = pyqtSignal()

    def __init__(self):
        super().__init__()
        self._qs = QSettings("AfterKey", "AfterKey")
        self._cache: dict = {}
        for key, default in DEFAULTS.items():
            stored = self._qs.value(key)
            if stored is not None:
                coerce = _TYPE_COERCE[type(default)]
                self._cache[key] = coerce(stored)
            else:
                self._cache[key] = default

    def __getitem__(self, key: str):
        return self._cache.get(key, DEFAULTS.get(key))

    def __setitem__(self, key: str, value):
        if self._cache.get(key) == value:
            return
        self._cache[key] = value
        self._qs.setValue(key, value)
        self.changed.emit()

    def reset(self):
        for key, value in DEFAULTS.items():
            self[key] = value


settings = Settings()
