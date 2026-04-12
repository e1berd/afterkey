#include "overlay.h"
#include "keymonitor.h"
#include "tray.h"

#include <QApplication>
#include <cstdlib>
#include <signal.h>

int main(int argc, char* argv[]) {
    if (qEnvironmentVariable("XDG_SESSION_TYPE") == "wayland")
        qputenv("QT_QPA_PLATFORM", "xcb");

    signal(SIGINT, [](int) { QApplication::quit(); });

    QApplication app(argc, argv);
    app.setApplicationName("AfterKey");
    app.setQuitOnLastWindowClosed(false);

    OverlayWindow overlay;
    overlay.show();

    KeyMonitor monitor;
    QObject::connect(&monitor, &KeyMonitor::keyPressed, &overlay, &OverlayWindow::addKey, Qt::QueuedConnection);
    monitor.start();

    TrayIcon tray;
    tray.show();

    int ret = app.exec();
    monitor.stop();
    return ret;
}
