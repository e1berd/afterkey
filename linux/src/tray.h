#pragma once

#include <QSystemTrayIcon>

class SettingsWindow;

class TrayIcon : public QSystemTrayIcon {
    Q_OBJECT

public:
    explicit TrayIcon(QObject* parent = nullptr);

private:
    SettingsWindow* m_settingsWin = nullptr;
    void openSettings();
};
