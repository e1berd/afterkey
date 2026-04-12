import time
from dataclasses import dataclass, field
from uuid import uuid4

from PyQt6.QtCore import Qt, QTimer
from PyQt6.QtGui import QColor, QFont, QFontMetrics, QPainter, QPainterPath, QPen, QGuiApplication
from PyQt6.QtWidgets import QWidget

from settings import settings


@dataclass
class KeyDisplay:
    uid: str = field(default_factory=lambda: uuid4().hex)
    text: str = ""
    expire: float = 0.0


class KeyBubble(QWidget):
    def __init__(self, text: str, parent=None):
        super().__init__(parent)
        self.text = text
        self.setAttribute(Qt.WidgetAttribute.WA_TransparentForMouseEvents)
        self._update_size()

    def _update_size(self):
        font = QFont("sans-serif", settings["font_size"])
        font.setBold(True)
        fm = QFontMetrics(font)
        self.setFixedSize(fm.horizontalAdvance(self.text) + 40, fm.height() + 24)

    def paintEvent(self, _event):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)

        w, h = float(self.width()), float(self.height())
        radius = float(settings["corner_radius"])

        bg = QColor(settings["bg_color"])
        bg.setAlphaF(settings["bg_opacity"])
        path = QPainterPath()
        path.addRoundedRect(0.0, 0.0, w, h, radius, radius)
        p.fillPath(path, bg)

        bw = settings["border_width"]
        if bw > 0:
            bc = QColor(settings["border_color"])
            bc.setAlphaF(settings["border_opacity"])
            p.setPen(QPen(bc, bw))
            p.drawRoundedRect(int(bw / 2), int(bw / 2), int(w - bw), int(h - bw), radius, radius)

        tc = QColor(settings["text_color"])
        tc.setAlphaF(settings["text_opacity"])
        p.setPen(tc)
        font = QFont("sans-serif", settings["font_size"])
        font.setBold(True)
        p.setFont(font)
        p.drawText(self.rect(), Qt.AlignmentFlag.AlignCenter, self.text)
        p.end()


class OverlayWindow(QWidget):
    SPACING = 8
    MARGIN = 50

    def __init__(self):
        super().__init__()
        self.setWindowFlags(
            Qt.WindowType.FramelessWindowHint
            | Qt.WindowType.WindowStaysOnTopHint
            | Qt.WindowType.Tool
            | Qt.WindowType.WindowTransparentForInput
            | Qt.WindowType.WindowDoesNotAcceptFocus
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setAttribute(Qt.WidgetAttribute.WA_TransparentForMouseEvents)
        self.setAttribute(Qt.WidgetAttribute.WA_ShowWithoutActivating)

        self._keys: list[tuple[KeyDisplay, KeyBubble]] = []

        self._timer = QTimer(self)
        self._timer.timeout.connect(self._cleanup)
        self._timer.start(100)

        settings.changed.connect(self._reposition)
        self._reposition()

    def _reposition(self):
        screen = QGuiApplication.primaryScreen()
        if screen:
            self.setGeometry(screen.availableGeometry())
            self._relayout()

    def add_key(self, text: str):
        kd = KeyDisplay(text=text, expire=time.time() + settings["display_duration"])
        bubble = KeyBubble(text, self)
        bubble.show()
        self._keys.append((kd, bubble))

        while len(self._keys) > settings["max_keys"]:
            _, old = self._keys.pop(0)
            old.deleteLater()

        self._relayout()

    def _relayout(self):
        bubbles = [b for _, b in self._keys]
        if not bubbles:
            return

        pos = settings["position"]
        geo = self.geometry()
        total_h = sum(b.height() for b in bubbles) + self.SPACING * (len(bubbles) - 1)

        y = (
            self.MARGIN if "top" in pos
            else geo.height() - self.MARGIN - total_h if "bottom" in pos
            else (geo.height() - total_h) // 2
        )

        for _, bubble in self._keys:
            x = (
                self.MARGIN if "left" in pos
                else geo.width() - self.MARGIN - bubble.width() if "right" in pos
                else (geo.width() - bubble.width()) // 2
            )
            bubble.move(x, y)
            y += bubble.height() + self.SPACING

    def _cleanup(self):
        now = time.time()
        expired = [(kd, b) for kd, b in self._keys if kd.expire < now]
        if not expired:
            return
        for _, b in expired:
            b.deleteLater()
        self._keys = [(kd, b) for kd, b in self._keys if kd.expire >= now]
        self._relayout()
