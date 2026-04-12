from PyQt6.QtWidgets import (
    QMainWindow, QTabWidget, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QGroupBox, QGridLayout, QPushButton, QCheckBox,
    QSpinBox, QDoubleSpinBox, QFrame, QColorDialog,
)
from PyQt6.QtGui import QColor

from settings import settings, POSITIONS


class SettingsWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("AfterKey Settings")
        self.setFixedSize(420, 650)
        self._pos_buttons: list[QPushButton] = []

        tabs = QTabWidget()
        tabs.addTab(self._general_tab(), "General")
        tabs.addTab(self._appearance_tab(), "Appearance")
        tabs.addTab(self._position_tab(), "Position")
        self.setCentralWidget(tabs)

    def _general_tab(self):
        w = QWidget()
        layout = QVBoxLayout(w)
        layout.setSpacing(16)

        grp = QGroupBox("General Settings")
        gl = QVBoxLayout(grp)

        gl.addLayout(self._dspin_row("Display Duration (s)", "display_duration", 0.5, 10.0, 0.5))
        gl.addLayout(self._spin_row("Max Items", "max_keys", 1, 20))

        cb = QCheckBox("Show Modifier Keys")
        cb.setChecked(settings["show_modifiers"])
        cb.toggled.connect(lambda v: settings.__setitem__("show_modifiers", v))
        gl.addWidget(cb)

        layout.addWidget(grp)

        reset_btn = QPushButton("Reset to Defaults")
        reset_btn.clicked.connect(settings.reset)
        layout.addWidget(reset_btn)

        layout.addStretch()
        return w

    def _appearance_tab(self):
        w = QWidget()
        layout = QVBoxLayout(w)
        layout.setSpacing(12)

        grp = QGroupBox("Appearance")
        gl = QVBoxLayout(grp)

        gl.addLayout(self._spin_row("Font Size", "font_size", 16, 64))
        gl.addLayout(self._spin_row("Corner Radius", "corner_radius", 0, 30))
        gl.addLayout(self._dspin_row("Border Width", "border_width", 0.0, 5.0, 0.5))

        for label, color_key, opacity_key in [
            ("Background", "bg_color", "bg_opacity"),
            ("Text", "text_color", "text_opacity"),
            ("Border", "border_color", "border_opacity"),
        ]:
            sep = QFrame()
            sep.setFrameShape(QFrame.Shape.HLine)
            gl.addWidget(sep)
            gl.addLayout(self._color_row(f"{label} Color", color_key))
            gl.addLayout(self._dspin_row(f"{label} Opacity", opacity_key, 0.0, 1.0, 0.05))

        layout.addWidget(grp)
        layout.addStretch()
        return w

    def _position_tab(self):
        w = QWidget()
        layout = QVBoxLayout(w)

        grp = QGroupBox("Overlay Position")
        grid = QGridLayout(grp)
        grid.setSpacing(6)

        labels = [
            ("Top Left", "top_left"), ("Top Center", "top_center"), ("Top Right", "top_right"),
            ("Center Left", "center_left"), ("Center", "center"), ("Center Right", "center_right"),
            ("Bottom Left", "bottom_left"), ("Bottom Center", "bottom_center"), ("Bottom Right", "bottom_right"),
        ]

        for i, (label, pos_id) in enumerate(labels):
            btn = QPushButton(label)
            btn.setFixedHeight(50)
            btn.setCheckable(True)
            btn.setChecked(settings["position"] == pos_id)
            btn.clicked.connect(self._make_pos_setter(pos_id))
            grid.addWidget(btn, i // 3, i % 3)
            self._pos_buttons.append(btn)

        layout.addWidget(grp)
        layout.addStretch()
        return w

    def _make_pos_setter(self, pos_id):
        def setter():
            settings["position"] = pos_id
            for btn, pid in zip(self._pos_buttons, POSITIONS):
                btn.setChecked(pid == pos_id)
        return setter

    def _color_row(self, label: str, key: str):
        row = QHBoxLayout()
        row.addWidget(QLabel(label))
        btn = QPushButton()
        btn.setFixedSize(40, 25)
        btn.setStyleSheet(f"background-color: {settings[key]};")

        def pick():
            c = QColorDialog.getColor(QColor(settings[key]), self)
            if c.isValid():
                settings[key] = c.name()
                btn.setStyleSheet(f"background-color: {c.name()};")

        btn.clicked.connect(pick)
        row.addWidget(btn)
        return row

    def _spin_row(self, label: str, key: str, lo: int, hi: int):
        row = QHBoxLayout()
        row.addWidget(QLabel(label))
        sp = QSpinBox()
        sp.setRange(lo, hi)
        sp.setValue(int(settings[key]))
        sp.valueChanged.connect(lambda v: settings.__setitem__(key, v))
        row.addWidget(sp)
        return row

    def _dspin_row(self, label: str, key: str, lo: float, hi: float, step: float):
        row = QHBoxLayout()
        row.addWidget(QLabel(label))
        sp = QDoubleSpinBox()
        sp.setRange(lo, hi)
        sp.setSingleStep(step)
        sp.setValue(float(settings[key]))
        sp.valueChanged.connect(lambda v: settings.__setitem__(key, v))
        row.addWidget(sp)
        return row
