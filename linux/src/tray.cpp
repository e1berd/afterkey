#include "tray.h"
#include "settingswindow.h"

#include <QMenu>
#include <QApplication>

TrayIcon::TrayIcon(QObject* parent) : QSystemTrayIcon(parent) {
    setIcon(QIcon::fromTheme("input-keyboard", QIcon::fromTheme("preferences-desktop-keyboard")));
    setToolTip("AfterKey");

    auto* menu = new QMenu;
    connect(menu->addAction("Settings..."), &QAction::triggered, this, &TrayIcon::openSettings);
    menu->addSeparator();
    connect(menu->addAction("Quit"), &QAction::triggered, qApp, &QApplication::quit);
    setContextMenu(menu);
}

void TrayIcon::openSettings() {
    if (!m_settingsWin || !m_settingsWin->isVisible())
        m_settingsWin = new SettingsWindow;
    m_settingsWin->show();
    m_settingsWin->raise();
    m_settingsWin->activateWindow();
}
