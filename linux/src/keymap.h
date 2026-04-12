#pragma once

#include <QString>
#include <linux/input-event-codes.h>

namespace KeyMap {
    QString name(int code);
    bool isModifier(int code);
}
