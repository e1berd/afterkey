#include "overlay.h"
#include "settings.h"

#include <QPainter>
#include <QPainterPath>
#include <QGuiApplication>
#include <QScreen>
#include <QDateTime>

static constexpr int MARGIN = 50;
static constexpr int SPACING = 8;
static constexpr int PAD_H = 20;
static constexpr int PAD_V = 12;

OverlayWindow::OverlayWindow(QWidget* parent) : QWidget(parent) {
    setWindowFlags(
        Qt::FramelessWindowHint
        | Qt::WindowStaysOnTopHint
        | Qt::X11BypassWindowManagerHint
        | Qt::WindowTransparentForInput
        | Qt::WindowDoesNotAcceptFocus
    );
    setAttribute(Qt::WA_TranslucentBackground);
    setAttribute(Qt::WA_TransparentForMouseEvents);
    setAttribute(Qt::WA_ShowWithoutActivating);

    connect(&m_timer, &QTimer::timeout, this, &OverlayWindow::cleanup);
    m_timer.start(100);

    connect(&Settings::instance(), &Settings::changed, this, &OverlayWindow::reposition);
    reposition();
}

void OverlayWindow::reposition() {
    if (auto* screen = QGuiApplication::primaryScreen())
        setGeometry(screen->availableGeometry());
    update();
}

void OverlayWindow::addKey(const QString& text) {
    auto& s = Settings::instance();
    auto expireMs = QDateTime::currentMSecsSinceEpoch() + static_cast<qint64>(s.displayDuration() * 1000);
    m_keys.push_back({text, expireMs});

    while (static_cast<int>(m_keys.size()) > s.maxKeys())
        m_keys.erase(m_keys.begin());

    update();
}

void OverlayWindow::cleanup() {
    auto now = QDateTime::currentMSecsSinceEpoch();
    auto before = m_keys.size();

    std::erase_if(m_keys, [now](const KeyDisplay& k) { return k.expireMs < now; });

    if (m_keys.size() != before)
        update();
}

std::vector<OverlayWindow::BubbleRect> OverlayWindow::layoutBubbles() {
    auto& s = Settings::instance();
    auto pos = s.position();

    QFont font("sans-serif", s.fontSize());
    font.setBold(true);
    QFontMetrics fm(font);

    std::vector<BubbleRect> bubbles;
    int totalH = 0;

    for (auto& key : m_keys) {
        int w = fm.horizontalAdvance(key.text) + PAD_H * 2;
        int h = fm.height() + PAD_V * 2;
        bubbles.push_back({{0, 0, (double)w, (double)h}, key.text});
        totalH += h;
    }
    if (!bubbles.empty())
        totalH += SPACING * (static_cast<int>(bubbles.size()) - 1);

    int yStart;
    if (pos.contains("top"))         yStart = MARGIN;
    else if (pos.contains("bottom")) yStart = height() - MARGIN - totalH;
    else                             yStart = (height() - totalH) / 2;

    int y = yStart;
    for (auto& b : bubbles) {
        int bw = static_cast<int>(b.rect.width());
        int x;
        if (pos.contains("left"))        x = MARGIN;
        else if (pos.contains("right"))  x = width() - MARGIN - bw;
        else                             x = (width() - bw) / 2;

        b.rect.moveTopLeft({(double)x, (double)y});
        y += static_cast<int>(b.rect.height()) + SPACING;
    }

    return bubbles;
}

void OverlayWindow::paintEvent(QPaintEvent*) {
    if (m_keys.empty()) return;

    auto& s = Settings::instance();
    auto bubbles = layoutBubbles();

    QPainter p(this);
    p.setRenderHint(QPainter::Antialiasing);

    QFont font("sans-serif", s.fontSize());
    font.setBold(true);
    p.setFont(font);

    double radius = s.cornerRadius();

    QColor bg(s.bgColor());
    bg.setAlphaF(s.bgOpacity());

    QColor tc(s.textColor());
    tc.setAlphaF(s.textOpacity());

    QColor bc(s.borderColor());
    bc.setAlphaF(s.borderOpacity());

    for (auto& b : bubbles) {
        QPainterPath path;
        path.addRoundedRect(b.rect, radius, radius);
        p.fillPath(path, bg);

        if (s.borderWidth() > 0) {
            p.setPen(QPen(bc, s.borderWidth()));
            p.drawRoundedRect(b.rect, radius, radius);
        }

        p.setPen(tc);
        p.drawText(b.rect, Qt::AlignCenter, b.text);
    }
}
