#!/usr/bin/env python3

import sys
import signal

from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QApplication

from overlay import OverlayWindow
from key_monitor import KeyEventBridge
from tray import TrayIcon


def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    app = QApplication(sys.argv)
    app.setApplicationName("AfterKey")
    app.setQuitOnLastWindowClosed(False)

    overlay = OverlayWindow()
    overlay.show()

    bridge = KeyEventBridge()
    bridge.key_pressed.connect(overlay.add_key, Qt.ConnectionType.QueuedConnection)
    bridge.start()

    tray = TrayIcon(app)
    tray.show()

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
