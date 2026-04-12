from PyQt6.QtGui import QAction, QIcon
from PyQt6.QtWidgets import QApplication, QMenu, QSystemTrayIcon

from settings_window import SettingsWindow


class TrayIcon(QSystemTrayIcon):
    def __init__(self, app: QApplication):
        super().__init__()
        self._app = app
        self._settings_win: SettingsWindow | None = None

        self.setIcon(QIcon.fromTheme("input-keyboard", QIcon.fromTheme("preferences-desktop-keyboard")))
        self.setToolTip("AfterKey")

        menu = QMenu()

        settings_action = QAction("Settings...", menu)
        settings_action.triggered.connect(self._open_settings)
        menu.addAction(settings_action)

        menu.addSeparator()

        quit_action = QAction("Quit", menu)
        quit_action.triggered.connect(app.quit)
        menu.addAction(quit_action)

        self.setContextMenu(menu)

    def _open_settings(self):
        if self._settings_win is None or not self._settings_win.isVisible():
            self._settings_win = SettingsWindow()
        self._settings_win.show()
        self._settings_win.raise_()
        self._settings_win.activateWindow()
