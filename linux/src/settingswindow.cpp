#include "settingswindow.h"
#include "settings.h"

#include <QTabWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QGridLayout>
#include <QColorDialog>

SettingsWindow::SettingsWindow(QWidget* parent) : QMainWindow(parent) {
    setWindowTitle("AfterKey Settings");
    setFixedSize(420, 650);

    auto* tabs = new QTabWidget;
    tabs->addTab(generalTab(), "General");
    tabs->addTab(appearanceTab(), "Appearance");
    tabs->addTab(positionTab(), "Position");
    setCentralWidget(tabs);
}

QWidget* SettingsWindow::generalTab() {
    auto& s = Settings::instance();
    auto* w = new QWidget;
    auto* layout = new QVBoxLayout(w);
    layout->setSpacing(16);

    auto* grp = new QGroupBox("General Settings");
    auto* gl = new QVBoxLayout(grp);

    QLabel* durLabel;
    gl->addLayout(sliderRow("Display Duration (s)", "display_duration", 0.5, 10.0, 0.5, durLabel));
    durLabel->setText(QString::number(s.displayDuration(), 'f', 1));

    QLabel* maxLabel;
    gl->addLayout(sliderRow("Max Items", "max_keys", 1, 20, 1, maxLabel));
    maxLabel->setText(QString::number(s.maxKeys()));

    auto* cb = new QCheckBox("Show Modifier Keys");
    cb->setChecked(s.showModifiers());
    connect(cb, &QCheckBox::toggled, [](bool v) { Settings::instance().set("show_modifiers", v); });
    gl->addWidget(cb);

    layout->addWidget(grp);

    auto* resetBtn = new QPushButton("Reset to Defaults");
    connect(resetBtn, &QPushButton::clicked, [this, cb, durLabel, maxLabel]() {
        Settings::instance().reset();
        auto& s = Settings::instance();
        cb->setChecked(s.showModifiers());
        durLabel->setText(QString::number(s.displayDuration(), 'f', 1));
        maxLabel->setText(QString::number(s.maxKeys()));
    });
    layout->addWidget(resetBtn);
    layout->addStretch();

    return w;
}

QWidget* SettingsWindow::appearanceTab() {
    auto* w = new QWidget;
    auto* layout = new QVBoxLayout(w);

    auto* grp = new QGroupBox("Appearance");
    auto* gl = new QVBoxLayout(grp);

    QLabel* dummy;
    gl->addLayout(sliderRow("Font Size", "font_size", 16, 64, 2, dummy));
    gl->addLayout(sliderRow("Corner Radius", "corner_radius", 0, 30, 2, dummy));
    gl->addLayout(sliderRow("Border Width", "border_width", 0, 5, 0.5, dummy));

    for (auto& [label, colorKey, opacityKey] : std::initializer_list<std::tuple<QString, QString, QString>>{
        {"Background", "bg_color", "bg_opacity"},
        {"Text", "text_color", "text_opacity"},
        {"Border", "border_color", "border_opacity"},
    }) {
        auto* sep = new QFrame;
        sep->setFrameShape(QFrame::HLine);
        gl->addWidget(sep);
        gl->addLayout(colorRow(label + " Color", colorKey));
        gl->addLayout(sliderRow(label + " Opacity", opacityKey, 0, 1, 0.05, dummy));
    }

    layout->addWidget(grp);
    layout->addStretch();
    return w;
}

QWidget* SettingsWindow::positionTab() {
    auto* w = new QWidget;
    auto* layout = new QVBoxLayout(w);

    auto* grp = new QGroupBox("Overlay Position");
    auto* grid = new QGridLayout(grp);
    grid->setSpacing(6);

    const std::pair<QString, QString> positions[] = {
        {"Top Left", "top_left"}, {"Top Center", "top_center"}, {"Top Right", "top_right"},
        {"Center Left", "center_left"}, {"Center", "center"}, {"Center Right", "center_right"},
        {"Bottom Left", "bottom_left"}, {"Bottom Center", "bottom_center"}, {"Bottom Right", "bottom_right"},
    };

    auto& s = Settings::instance();
    for (int i = 0; i < 9; ++i) {
        auto* btn = new QPushButton(positions[i].first);
        btn->setFixedHeight(50);
        btn->setCheckable(true);
        btn->setChecked(s.position() == positions[i].second);

        auto posId = positions[i].second;
        connect(btn, &QPushButton::clicked, [this, posId]() {
            Settings::instance().set("position", posId);
            for (int j = 0; j < 9; ++j) {
                const QString ids[] = {
                    "top_left", "top_center", "top_right",
                    "center_left", "center", "center_right",
                    "bottom_left", "bottom_center", "bottom_right",
                };
                m_posButtons[j]->setChecked(ids[j] == posId);
            }
        });

        grid->addWidget(btn, i / 3, i % 3);
        m_posButtons.push_back(btn);
    }

    layout->addWidget(grp);
    layout->addStretch();
    return w;
}

QLayout* SettingsWindow::sliderRow(const QString& label, const QString& key,
                                    double min, double max, double step, QLabel*& valLabel) {
    auto& s = Settings::instance();
    auto* row = new QVBoxLayout;

    auto* top = new QHBoxLayout;
    top->addWidget(new QLabel(label));
    valLabel = new QLabel;
    valLabel->setAlignment(Qt::AlignRight);
    top->addWidget(valLabel);
    row->addLayout(top);

    auto* slider = new QSlider(Qt::Horizontal);
    int steps = static_cast<int>((max - min) / step);
    slider->setRange(0, steps);

    auto current = s.get(key);
    double curVal = current.isValid() ? current.toDouble() : min;
    slider->setValue(static_cast<int>((curVal - min) / step));
    valLabel->setText(step >= 1 ? QString::number(static_cast<int>(curVal)) : QString::number(curVal, 'f', step < 0.1 ? 2 : 1));

    connect(slider, &QSlider::valueChanged, [=, &s](int pos) {
        double val = min + pos * step;
        s.set(key, val);
        valLabel->setText(step >= 1 ? QString::number(static_cast<int>(val)) : QString::number(val, 'f', step < 0.1 ? 2 : 1));
    });

    row->addWidget(slider);
    return row;
}

QLayout* SettingsWindow::colorRow(const QString& label, const QString& key) {
    auto& s = Settings::instance();
    auto* row = new QHBoxLayout;
    row->addWidget(new QLabel(label));

    auto* btn = new QPushButton;
    btn->setFixedSize(40, 25);
    auto color = s.get(key, "#000000").toString();
    btn->setStyleSheet(QString("background-color: %1;").arg(color));

    connect(btn, &QPushButton::clicked, [btn, key, &s]() {
        auto cur = QColor(s.get(key, "#000000").toString());
        auto c = QColorDialog::getColor(cur);
        if (!c.isValid()) return;
        s.set(key, c.name());
        btn->setStyleSheet(QString("background-color: %1;").arg(c.name()));
    });

    row->addWidget(btn);
    return row;
}
