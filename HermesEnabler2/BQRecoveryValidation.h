#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

static inline bool BQRecoveryParseDeviceBrand(const uint8_t *bytes, size_t length, uint8_t maxBrand, int32_t *brandOut) {
    if (!bytes || length < 4 || !brandOut || maxBrand < 1) return false;
    uint8_t value = bytes[2];
    *brandOut = value >= 1 && value <= maxBrand ? value : 0;
    return true;
}

static inline bool BQRecoveryBoolSlotIsUsable(const uint8_t *bytes, size_t length, size_t presenceBase, size_t index) {
    if (!bytes || presenceBase > length || index >= length - presenceBase || index > (length / 8) || length - index * 8 < 8) return false;
    return bytes[presenceBase + index] == 1 && bytes[index * 8] <= 1;
}

// A complete button-names property is a NUL-terminated list containing the
// standard help and menu buttons. A missing or malformed list is not evidence
// that the watch lacks an Action Button.
static inline bool BQRecoveryParseButtonNames(const uint8_t *names, size_t length, bool *hasAppOut) {
    if (!names || length == 0 || length > 4096) return false;
    bool hasHelp = false, hasMenu = false, hasApp = false;
    size_t offset = 0;
    while (offset < length) {
        const uint8_t *end = memchr(names + offset, 0, length - offset);
        if (!end) return false;
        const char *name = (const char *)names + offset;
        if (strcmp(name, "help") == 0) hasHelp = true;
        if (strcmp(name, "menu") == 0) hasMenu = true;
        if (strcmp(name, "app") == 0) hasApp = true;
        offset = (size_t)(end - names) + 1;
    }
    if (!hasHelp || !hasMenu) return false;
    if (hasAppOut) *hasAppOut = hasApp;
    return true;
}
