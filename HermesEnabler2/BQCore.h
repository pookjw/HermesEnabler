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

// Adds the verified 27.3 beta 1 AOD capability overrides to CacheExtra.
BOOL BQEnableAODSupport(NSString **err);

// Adds the Action Button capability override to CacheExtra.
BOOL BQEnableActionButton(NSString **err);

