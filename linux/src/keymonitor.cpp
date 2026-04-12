#include "keymonitor.h"
#include "keymap.h"
#include "settings.h"

#include <linux/input.h>
#include <fcntl.h>
#include <unistd.h>
#include <poll.h>
#include <dirent.h>
#include <sys/ioctl.h>
#include <cstring>

#define BITS_PER_LONG (sizeof(long) * 8)
#define NLONGS(x) (((x) + BITS_PER_LONG - 1) / BITS_PER_LONG)
#define TEST_BIT(arr, bit) ((arr[(bit) / BITS_PER_LONG] >> ((bit) % BITS_PER_LONG)) & 1)

void KeyMonitor::stop() {
    m_stop = true;
    wait();
}

bool KeyMonitor::isKeyboard(int fd) {
    unsigned long evbits[NLONGS(EV_MAX)] = {};
    unsigned long keybits[NLONGS(KEY_MAX)] = {};

    if (ioctl(fd, EVIOCGBIT(0, sizeof(evbits)), evbits) < 0) return false;
    if (!TEST_BIT(evbits, EV_KEY)) return false;
    if (ioctl(fd, EVIOCGBIT(EV_KEY, sizeof(keybits)), keybits) < 0) return false;

    return TEST_BIT(keybits, KEY_A) && TEST_BIT(keybits, KEY_Z);
}

std::vector<int> KeyMonitor::findKeyboards() {
    std::vector<int> fds;
    auto* dir = opendir("/dev/input");
    if (!dir) return fds;

    while (auto* entry = readdir(dir)) {
        if (strncmp(entry->d_name, "event", 5) != 0) continue;

        auto path = std::string("/dev/input/") + entry->d_name;
        int fd = open(path.c_str(), O_RDONLY | O_NONBLOCK);
        if (fd < 0) continue;

        if (isKeyboard(fd))
            fds.push_back(fd);
        else
            close(fd);
    }

    closedir(dir);
    return fds;
}

void KeyMonitor::run() {
    auto fds = findKeyboards();
    if (fds.empty()) {
        qWarning("No keyboard devices found. Make sure you are in the 'input' group.");
        return;
    }

    std::vector<pollfd> pfds;
    for (int fd : fds)
        pfds.push_back({fd, POLLIN, 0});

    while (!m_stop) {
        if (poll(pfds.data(), pfds.size(), 100) <= 0) continue;

        for (auto& pfd : pfds) {
            if (!(pfd.revents & POLLIN)) continue;

            input_event ev;
            while (read(pfd.fd, &ev, sizeof(ev)) == sizeof(ev)) {
                if (ev.type == EV_KEY)
                    handleKey(ev.code, ev.value);
            }
        }
    }

    for (int fd : fds)
        close(fd);
}

void KeyMonitor::handleKey(int code, int value) {
    if (KeyMap::isModifier(code)) {
        if (value == 1 || value == 2)
            m_modifiers.insert(code);
        else
            m_modifiers.erase(code);
        return;
    }

    if (value != 1) return;

    auto name = KeyMap::name(code);
    if (name.isEmpty()) return;

    auto& s = Settings::instance();
    auto text = s.showModifiers() ? modifierPrefix() + name : name;
    emit keyPressed(text);
}

QString KeyMonitor::modifierPrefix() {
    QString prefix;
    auto has = [&](int a, int b) { return m_modifiers.count(a) || m_modifiers.count(b); };

    if (has(KEY_LEFTMETA, KEY_RIGHTMETA))   prefix += "Super+";
    if (has(KEY_LEFTCTRL, KEY_RIGHTCTRL))   prefix += "Ctrl+";
    if (has(KEY_LEFTALT, KEY_RIGHTALT))     prefix += "Alt+";
    if (has(KEY_LEFTSHIFT, KEY_RIGHTSHIFT)) prefix += "Shift+";

    return prefix;
}
