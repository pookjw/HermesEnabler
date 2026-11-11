#include "../HermesEnabler2/BQRecoveryValidation.h"

#include <assert.h>

int main(void) {
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
