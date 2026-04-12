#pragma once

#include <QWidget>
#include <QTimer>
#include <QString>
#include <vector>

struct KeyDisplay {
    QString text;
    qint64 expireMs;
};

class OverlayWindow : public QWidget {
    Q_OBJECT

public:
    explicit OverlayWindow(QWidget* parent = nullptr);

public slots:
    void addKey(const QString& text);

protected:
    void paintEvent(QPaintEvent* event) override;

private:
    std::vector<KeyDisplay> m_keys;
    QTimer m_timer;

    void cleanup();
    void reposition();

    struct BubbleRect {
        QRectF rect;
        QString text;
    };
    std::vector<BubbleRect> layoutBubbles();
};
