#include "settings.h"

Settings::Settings() : QObject(nullptr) {}

Settings& Settings::instance() {
    static Settings s;
    return s;
}

void Settings::set(const QString& key, const QVariant& value) {
    if (m_qs.value(key) == value) return;
    m_qs.setValue(key, value);
    emit changed();
}

void Settings::reset() {
    for (auto& [key, val] : std::initializer_list<std::pair<const char*, QVariant>>{
        {"display_duration", 3.0}, {"max_keys", 5}, {"position", "bottom_right"},
        {"show_modifiers", true}, {"font_size", 32}, {"corner_radius", 12},
        {"border_width", 1.0}, {"bg_color", "#000000"}, {"bg_opacity", 0.3},
        {"text_color", "#ffffff"}, {"text_opacity", 1.0},
        {"border_color", "#ffffff"}, {"border_opacity", 0.2},
    }) {
        m_qs.setValue(key, val);
    }
    emit changed();
}
