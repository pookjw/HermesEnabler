#pragma once
#import <Foundation/Foundation.h>


extern NSString * const BQErrorDomain;

// ---- logging / paths -------------------------------------------------------
void BQLog(NSString *fmt, ...);
NSString *BQLogPath(void);
NSString *BQDocuments(void);
NSString *BQGroupRoot(void);
NSString *BQGroupID(void);
NSArray<NSString *> *BQGroupIDs(void);
NSDictionary *BQProbeEscapeClasses(NSString *target);
NSDictionary *BQProbeClass2Parts(NSString *target);
dispatch_queue_t BQWorkQueue(void);

// ---- init ------------------------------------------------------------------
BOOL BQCoreInit(void);

// ---- sandbox escape lease --------------------------------------------------
// Escape to `target` (an MCM container or a directory inside one). On success
// returns a sandbox-extension handle >= 0 and sets *linkOut to a path that
// resolves to `target` (the app group's Library/Caches symlink). Call
// BQEndEscape() to release and restore the app group.
int64_t BQEscape(NSString *target, NSString **linkOut);
void BQEndEscape(int64_t handle);

// Experimental class-2 parent fallback. Off by default because moving the
// app's own Library can be killed by the sandbox on some builds. Enable from
// Settings only when an app group is unavailable.
BOOL BQClass2ParentEnabled(void);
void BQSetClass2ParentEnabled(BOOL on);
BOOL BQCheckAccess(NSString *target, BOOL writable, NSString **err);

// ---- MobileGestalt ---------------------------------------------------------
NSMutableDictionary *BQLoadGestalt(NSString **err);
BOOL BQSaveGestalt(NSDictionary *dict, NSString **err);
BOOL BQRestoreGestalt(NSString **err);
BOOL BQBackupExists(void);
NSString *BQBackupPath(void);
BOOL BQInPlaceWrite(void);
void BQSetInPlaceWrite(BOOL on);
NSString *BQMobileGestaltPath(void);

// ---- PosterBoard -----------------------------------------------------------
NSString *BQFindPosterBoardContainer(NSString **err);
BOOL BQApplyTendies(NSURL *url, int *count, NSString **err);
BOOL BQResetPosterBoard(NSString **err);
BOOL BQOpenPosterBoard(void);
NSString *BQPosterBoardDescriptorsPath(NSString *ext);
NSArray<NSString *> *BQPosterBoardExtensions(void);

// ---- respring (NeoSpring / WebKit) ----------------------------------------
void BQRespring(void);

// Writes DeviceBrand into the verified CacheData layout, retaining the original backup.
BOOL BQEnableHermes(NSString **err);
BOOL BQSetHermesEnabled(BOOL enabled, NSString **err);
BOOL BQGetHermesEnabled(BOOL *enabled, NSString **err);

// Reads whether the respective capability overrides are recorded as enabled.
BOOL BQGetAODSupport(BOOL *enabled, NSString **err);
BOOL BQGetAODSecondsSupport(BOOL *enabled, NSString **err);
BOOL BQGetActionButton(BOOL *enabled, NSString **err);
BOOL BQGetDoubleTap(BOOL *enabled, NSString **err);
BOOL BQGetDepthCapability(BOOL *enabled, NSString **err);
BOOL BQGetAbsoluteAltimeter(BOOL *enabled, NSString **err);
BOOL BQGetAlwaysOnCompass(BOOL *enabled, NSString **err);
BOOL BQGetAODVibrancy(BOOL *enabled, NSString **err);
BOOL BQGetWatchKeyboard(BOOL *enabled, NSString **err);
BOOL BQGetPeriodicALSUpdates(BOOL *enabled, NSString **err);
BOOL BQGetRaiseToSpeak(BOOL *enabled, NSString **err);
BOOL BQGetContinuousHeartRate(BOOL *enabled, NSString **err);
BOOL BQGetCompassOrienteering(BOOL *enabled, NSString **err);
BOOL BQGetEnvironmentalDosimetry(BOOL *enabled, NSString **err);
BOOL BQGetBatteryInformation(BOOL *enabled, NSString **err);
BOOL BQGetAlwaysListening(BOOL *enabled, NSString **err);
BOOL BQGetRotateToWake(BOOL *enabled, NSString **err);
BOOL BQGetSwimmingWorkouts(BOOL *enabled, NSString **err);

// Updates the corresponding CacheExtra capability overrides.
BOOL BQSetAODSupport(BOOL enabled, NSString **err);
BOOL BQSetAODSecondsSupport(BOOL enabled, NSString **err);
BOOL BQSetActionButton(BOOL enabled, NSString **err);
BOOL BQSetDoubleTap(BOOL enabled, NSString **err);
BOOL BQSetDepthCapability(BOOL enabled, NSString **err);
BOOL BQSetAbsoluteAltimeter(BOOL enabled, NSString **err);
BOOL BQSetAlwaysOnCompass(BOOL enabled, NSString **err);
BOOL BQSetAODVibrancy(BOOL enabled, NSString **err);
BOOL BQSetWatchKeyboard(BOOL enabled, NSString **err);
BOOL BQSetPeriodicALSUpdates(BOOL enabled, NSString **err);
BOOL BQSetRaiseToSpeak(BOOL enabled, NSString **err);
BOOL BQSetContinuousHeartRate(BOOL enabled, NSString **err);
BOOL BQSetCompassOrienteering(BOOL enabled, NSString **err);
BOOL BQSetEnvironmentalDosimetry(BOOL enabled, NSString **err);
BOOL BQSetBatteryInformation(BOOL enabled, NSString **err);
BOOL BQSetAlwaysListening(BOOL enabled, NSString **err);
BOOL BQSetRotateToWake(BOOL enabled, NSString **err);
BOOL BQSetSwimmingWorkouts(BOOL enabled, NSString **err);

