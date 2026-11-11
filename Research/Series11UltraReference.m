// Historical reference only; NOT a build target. Depends on legacy BQCore helpers.
// Verified against libMobileGestalt 24S5284h: question record at 0x1e2dd0610
// has cache index 470, type 5 (SInt32). Value = index * 8; present = 0x1680 + index.
// ClockKit maps main-screen-class 38 to sizeClass 9, deviceCategory 6, isUltra=YES.
static BOOL bq_ultra_layout(NSDictionary *plist, NSString **err) {
    char build[128] = {0}, model[128] = {0};
    size_t length = sizeof(build); sysctlbyname("kern.osversion", build, &length, NULL, 0);
    length = sizeof(model); sysctlbyname("hw.machine", model, &length, NULL, 0);
    NSData *data = plist[@"CacheData"];
    if (strcmp(build, "24S5284h") || strcmp(model, "Watch7,18") ||
        ![plist[@"CacheUUID"] isEqual:@"DB380F61-0014-418D-9799-876666B459E3"] ||
        ![data isKindOfClass:NSData.class] || data.length != 0x1950 ||
        ![plist[@"CacheExtra"] isKindOfClass:NSDictionary.class]) {
        if (err) *err = @"Ultra layout is verified only for this Series 11 on build 24S5284h. No changes written.";
        return NO;
    }
    const uint8_t *b = data.bytes;
    uint32_t value = 0; memcpy(&value, b + 0xeb0, sizeof(value));
    if (b[0x1856] != 1 || (value != 35 && value != 38) ||
        ((NSDictionary *)plist[@"CacheExtra"])[@"fdh+s6j3VijuyrK7xLjd7g"] != nil) {
        if (err) *err = @"Unexpected main-screen-class state; no changes written.";
        return NO;
    }
    return YES;
}

BOOL BQGetUltraFacesEnabled(BOOL *enabled, NSString **err) {
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist || !bq_ultra_layout(plist, err)) return NO;
    uint32_t value; memcpy(&value, (const uint8_t *)[plist[@"CacheData"] bytes] + 0xeb0, sizeof(value));
    if (enabled) *enabled = value == 38;
    return YES;
}

BOOL BQSetUltraFacesEnabled(BOOL enabled, NSString **err) {
    if (!BQBackupExists()) { if (err) *err = @"Back up MobileGestalt first."; return NO; }
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist || !bq_ultra_layout(plist, err)) return NO;
    NSDictionary *original = [NSDictionary dictionaryWithContentsOfFile:BQBackupPath()];
    if (!bq_ultra_layout(original, err)) return NO;
    uint32_t originalValue;
    memcpy(&originalValue, (const uint8_t *)[original[@"CacheData"] bytes] + 0xeb0, sizeof(originalValue));
    if (originalValue != 35) { if (err) *err = @"Original screen-class backup is not valid."; return NO; }
    NSData *beforeData = plist[@"CacheData"];
    NSString *snapshotPath = [BQDocuments() stringByAppendingPathComponent:@"BeforeUltraRawGestalt.plist"];
    if (enabled && ![[NSFileManager defaultManager] fileExistsAtPath:snapshotPath]) {
        NSData *snapshot = [NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
        if (!snapshot || ![snapshot writeToFile:snapshotPath options:NSDataWritingAtomic error:nil] ||
            ![[NSDictionary dictionaryWithContentsOfFile:snapshotPath] isEqual:plist]) {
            if (err) *err = @"Pre-Ultra snapshot could not be verified. No changes written.";
            return NO;
        }
    }
    NSMutableDictionary *updated = [plist mutableCopy];
    NSMutableData *data = [beforeData mutableCopy];
    uint32_t value = enabled ? 38 : originalValue;
    memcpy((uint8_t *)data.mutableBytes + 0xeb0, &value, sizeof(value));
    updated[@"CacheData"] = data;
    // Preserve every other byte, CacheExtra, and the independent DeviceBrand/Hermès field.
    if (!BQSaveGestalt(updated, err)) return NO;
    NSDictionary *check = BQLoadGestalt(err);
    if (![check isEqual:updated]) {
        NSString *rollbackError = nil;
        BOOL restored = BQSaveGestalt(plist, &rollbackError);
        if (err) *err = restored ? @"Ultra verification failed; previous cache restored."
                                : [NSString stringWithFormat:@"Ultra verification failed; restore failed: %@", rollbackError];
        return NO;
    }
    BQLog(@"Ultra screen-class %@: %u. Hermès bytes preserved.", enabled ? @"enabled" : @"restored", value);
    return YES;
}
