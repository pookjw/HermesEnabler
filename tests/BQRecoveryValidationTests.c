#include "../HermesEnabler2/BQRecoveryValidation.h"

#include <assert.h>

int main(void) {
    assert(BQUltraAlternativeStateIsValid(35, 35, 38, 35, true, true, false, false, false));
    assert(BQUltraAlternativeStateIsValid(38, 35, 38, 35, true, true, false, false, false));
    assert(BQUltraAlternativeStateIsValid(36, 36, 38, 36, true, true, false, false, false));
    assert(!BQUltraAlternativeStateIsValid(37, 36, 38, 36, true, true, false, false, false));
    assert(!BQUltraAlternativeStateIsValid(29, 35, 38, 35, true, true, false, false, false));
    assert(!BQUltraAlternativeStateIsValid(35, 38, 38, 35, true, true, false, false, false));
    assert(!BQUltraAlternativeStateIsValid(35, 35, 38, 35, false, true, false, false, false));
    assert(!BQUltraAlternativeStateIsValid(35, 35, 38, 35, true, true, true, false, false));
    assert(!BQUltraAlternativeStateIsValid(35, 35, 38, 35, true, true, false, true, false));
    assert(BQUltraAlternativeStateIsValid(29, 35, 38, 35, true, true, false, false, true));
    assert(BQUltraAlternativeStateIsValid(38, 35, 29, 35, true, true, false, false, true));
    assert(!BQUltraAlternativeStateIsValid(38, 35, 29, 35, true, true, true, false, true));
    uint8_t originalCache[48] = {0}, currentCache[48] = {0};
    originalCache[8] = currentCache[8] = 7;
    originalCache[33] = currentCache[33] = 1;
    assert(BQRecoveryCachedSlotMatches(currentCache, originalCache, sizeof(originalCache), 32, 1));
    currentCache[0] = 9; // An unrelated slot can change.
    assert(BQRecoveryCachedSlotMatches(currentCache, originalCache, sizeof(originalCache), 32, 1));
    currentCache[8] = 8;
    assert(!BQRecoveryCachedSlotMatches(currentCache, originalCache, sizeof(originalCache), 32, 1));
    currentCache[8] = 7; currentCache[33] = 0;
    assert(!BQRecoveryCachedSlotMatches(currentCache, originalCache, sizeof(originalCache), 32, 1));
    assert(!BQRecoveryCachedSlotMatches(currentCache, originalCache, sizeof(originalCache), 47, 2));
    assert(!BQRecoveryCachedSlotMatches(NULL, originalCache, sizeof(originalCache), 32, 1));
    const uint8_t brandData[] = {0, 0, 3, 0};
    int32_t brand = -1;
    assert(BQRecoveryParseDeviceBrand(brandData, sizeof(brandData), 3, &brand) && brand == 3);
    assert(BQRecoveryParseDeviceBrand(brandData, sizeof(brandData), 2, &brand) && brand == 0);
    assert(!BQRecoveryParseDeviceBrand(brandData, 3, 3, &brand) && brand == 0);
    assert(!BQRecoveryParseDeviceBrand(NULL, 4, 3, &brand));
    uint8_t slots[64] = {0};
    slots[16] = 1;
    slots[42] = 1;
    assert(BQRecoveryBoolSlotIsUsable(slots, sizeof(slots), 40, 2));
    slots[42] = 0;
    assert(!BQRecoveryBoolSlotIsUsable(slots, sizeof(slots), 40, 2));
    slots[42] = 1;
    slots[16] = 2;
    assert(!BQRecoveryBoolSlotIsUsable(slots, sizeof(slots), 40, 2));
    assert(!BQRecoveryBoolSlotIsUsable(slots, sizeof(slots), 60, 8));
    assert(!BQRecoveryBoolSlotIsUsable(NULL, sizeof(slots), 40, 2));
    static const uint8_t standard[] = "help\0menu\0";
    static const uint8_t ultra[] = "help\0menu\0app\0";
    static const uint8_t similar[] = "help\0menu\0apple\0";
    static const uint8_t missingMenu[] = "help\0app\0";
    static const uint8_t unterminated[] = {'h', 'e', 'l', 'p', 0, 'm', 'e', 'n', 'u'};
    bool hasApp = true;

    assert(BQRecoveryParseButtonNames(standard, sizeof(standard) - 1, &hasApp) && !hasApp);
    assert(BQRecoveryParseButtonNames(ultra, sizeof(ultra) - 1, &hasApp) && hasApp);
    assert(BQRecoveryParseButtonNames(similar, sizeof(similar) - 1, &hasApp) && !hasApp);
    assert(!BQRecoveryParseButtonNames(missingMenu, sizeof(missingMenu) - 1, &hasApp));
    assert(!BQRecoveryParseButtonNames(unterminated, sizeof(unterminated), &hasApp));
    assert(!BQRecoveryParseButtonNames(NULL, 0, &hasApp));
    assert(!BQRecoveryParseButtonNames(standard, 4097, &hasApp));
    return 0;
}
