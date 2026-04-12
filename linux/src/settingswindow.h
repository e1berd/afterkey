#pragma once

#include <QMainWindow>
#include <QSlider>
#include <QCheckBox>
#include <QPushButton>
#include <QLabel>
#include <vector>

class SettingsWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit SettingsWindow(QWidget* parent = nullptr);

private:
    std::vector<QPushButton*> m_posButtons;
    bool m_loading = false;

    QWidget* generalTab();
    QWidget* appearanceTab();
    QWidget* positionTab();

    QLayout* sliderRow(const QString& label, const QString& key,
                       double min, double max, double step, QLabel*& valLabel);
    QLayout* colorRow(const QString& label, const QString& key);

    void loadValues();
};
