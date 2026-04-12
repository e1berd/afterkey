#include "keymap.h"
#include <unordered_map>
#include <unordered_set>

static const std::unordered_map<int, QString> SPECIAL = {
    {KEY_TAB, "⇥"}, {KEY_SPACE, "␣"}, {KEY_ENTER, "↵"}, {KEY_KPENTER, "↵"},
    {KEY_BACKSPACE, "⌫"}, {KEY_ESC, "ESC"},
    {KEY_LEFT, "←"}, {KEY_RIGHT, "→"}, {KEY_UP, "↑"}, {KEY_DOWN, "↓"},
    {KEY_DELETE, "DEL"}, {KEY_HOME, "HOME"}, {KEY_END, "END"},
    {KEY_PAGEUP, "PGUP"}, {KEY_PAGEDOWN, "PGDN"}, {KEY_INSERT, "INS"},
    {KEY_CAPSLOCK, "CAPS"}, {KEY_PRINT, "PRTSC"},
    {KEY_SCROLLLOCK, "SCRLK"}, {KEY_PAUSE, "PAUSE"},
    {KEY_F1, "F1"}, {KEY_F2, "F2"}, {KEY_F3, "F3"}, {KEY_F4, "F4"},
    {KEY_F5, "F5"}, {KEY_F6, "F6"}, {KEY_F7, "F7"}, {KEY_F8, "F8"},
    {KEY_F9, "F9"}, {KEY_F10, "F10"}, {KEY_F11, "F11"}, {KEY_F12, "F12"},
};

static const std::unordered_map<int, QString> CHARS = {
    {KEY_A, "A"}, {KEY_B, "B"}, {KEY_C, "C"}, {KEY_D, "D"}, {KEY_E, "E"},
    {KEY_F, "F"}, {KEY_G, "G"}, {KEY_H, "H"}, {KEY_I, "I"}, {KEY_J, "J"},
    {KEY_K, "K"}, {KEY_L, "L"}, {KEY_M, "M"}, {KEY_N, "N"}, {KEY_O, "O"},
    {KEY_P, "P"}, {KEY_Q, "Q"}, {KEY_R, "R"}, {KEY_S, "S"}, {KEY_T, "T"},
    {KEY_U, "U"}, {KEY_V, "V"}, {KEY_W, "W"}, {KEY_X, "X"}, {KEY_Y, "Y"},
    {KEY_Z, "Z"},
    {KEY_1, "1"}, {KEY_2, "2"}, {KEY_3, "3"}, {KEY_4, "4"}, {KEY_5, "5"},
    {KEY_6, "6"}, {KEY_7, "7"}, {KEY_8, "8"}, {KEY_9, "9"}, {KEY_0, "0"},
    {KEY_MINUS, "-"}, {KEY_EQUAL, "="}, {KEY_LEFTBRACE, "["},
    {KEY_RIGHTBRACE, "]"}, {KEY_SEMICOLON, ";"}, {KEY_APOSTROPHE, "'"},
    {KEY_GRAVE, "`"}, {KEY_BACKSLASH, "\\"}, {KEY_COMMA, ","},
    {KEY_DOT, "."}, {KEY_SLASH, "/"},
};

static const std::unordered_set<int> MODIFIERS = {
    KEY_LEFTCTRL, KEY_RIGHTCTRL, KEY_LEFTSHIFT, KEY_RIGHTSHIFT,
    KEY_LEFTALT, KEY_RIGHTALT, KEY_LEFTMETA, KEY_RIGHTMETA,
};

QString KeyMap::name(int code) {
    if (auto it = SPECIAL.find(code); it != SPECIAL.end()) return it->second;
    if (auto it = CHARS.find(code); it != CHARS.end()) return it->second;
    return {};
}

bool KeyMap::isModifier(int code) {
    return MODIFIERS.count(code);
}
