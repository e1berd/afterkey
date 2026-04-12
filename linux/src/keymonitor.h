#pragma once

#include <QThread>
#include <atomic>
#include <set>
#include <vector>

class KeyMonitor : public QThread {
    Q_OBJECT

public:
    using QThread::QThread;
    void stop();

signals:
    void keyPressed(const QString& text);

protected:
    void run() override;

private:
    std::atomic<bool> m_stop{false};
    std::set<int> m_modifiers;

    std::vector<int> findKeyboards();
    bool isKeyboard(int fd);
    void handleKey(int code, int value);
    QString modifierPrefix();
};
