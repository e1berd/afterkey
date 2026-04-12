#pragma once

#include <QObject>
#include <QSettings>
#include <QString>

class Settings : public QObject {
    Q_OBJECT

public:
    static Settings& instance();

    double displayDuration() const { return m_qs.value("display_duration", 3.0).toDouble(); }
    int maxKeys() const { return m_qs.value("max_keys", 5).toInt(); }
    QString position() const { return m_qs.value("position", "bottom_right").toString(); }
    bool showModifiers() const { return m_qs.value("show_modifiers", true).toBool(); }
    int fontSize() const { return m_qs.value("font_size", 32).toInt(); }
    int cornerRadius() const { return m_qs.value("corner_radius", 12).toInt(); }
    double borderWidth() const { return m_qs.value("border_width", 1.0).toDouble(); }
    QString bgColor() const { return m_qs.value("bg_color", "#000000").toString(); }
    double bgOpacity() const { return m_qs.value("bg_opacity", 0.3).toDouble(); }
    QString textColor() const { return m_qs.value("text_color", "#ffffff").toString(); }
    double textOpacity() const { return m_qs.value("text_opacity", 1.0).toDouble(); }
    QString borderColor() const { return m_qs.value("border_color", "#ffffff").toString(); }
    double borderOpacity() const { return m_qs.value("border_opacity", 0.2).toDouble(); }

    QVariant get(const QString& key, const QVariant& fallback = {}) const { return m_qs.value(key, fallback); }
    void set(const QString& key, const QVariant& value);
    void reset();

signals:
    void changed();

private:
    Settings();
    QSettings m_qs{"AfterKey", "AfterKey"};
};
