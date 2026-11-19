#import "BQOriginalHermes.h"
#import <CoreGraphics/CoreGraphics.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// Uses Apple's installed NanoTimeKit classes only. This feature never writes
// MobileGestalt or the first-party ClockFace/FaceCollection database.
// Private API is experimental, unsupported and intentionally opt-in.

static id sController;
static id sRoot;
static id sFace;

static BOOL Has(id object, NSString *name) {
    return object && [object respondsToSelector:NSSelectorFromString(name)];
}
static id Get(id object, NSString *name) {
    return Has(object, name)
        ? ((id(*)(id, SEL))objc_msgSend)(object, NSSelectorFromString(name)) : nil;
}
static unsigned GetUnsigned(id object, NSString *name) {
    return Has(object, name)
        ? ((unsigned(*)(id, SEL))objc_msgSend)(object, NSSelectorFromString(name)) : 0;
}
static void SetUnsigned(id object, NSString *name, unsigned value) {
    if (Has(object, name))
        ((void(*)(id, SEL, unsigned))objc_msgSend)(object, NSSelectorFromString(name), value);
}
static NSArray<NSDictionary<NSString *, NSString *> *> *Styles(void) {
    return @[
        @{@"name": @"Hermès Circulaire", @"bundle": @"com.apple.NTKPoodleFaceBundle",
          @"face": @"NTKPoodleFace", @"view": @"NTKPoodleFaceView"},
        @{@"name": @"Hermès", @"bundle": @"com.apple.NTKZeusFaceBundle.NTKZeusAnalogFaceBundle",
          @"face": @"NTKZeusAnalogFace", @"view": @"NTKZeusAnalogFaceView"},
        @{@"name": @"Hermès Radial", @"bundle": @"com.apple.NTKBellonaFaceBundle",
          @"face": @"NTKBellonaFace", @"view": @"NTKBellonaFaceView"},
        @{@"name": @"Hermès Circuit H", @"bundle": @"com.apple.NTKHadesFaceBundle",
          @"face": @"NTKHadesFace", @"view": @"NTKHadesFaceView"},
        @{@"name": @"Hermès Lucky Horse", @"bundle": @"com.apple.NTKSecretariatFaceBundle",
          @"face": @"NTKSecretariatFace", @"view": @"NTKSecretariatFaceView"},
        @{@"name": @"Hermès Faubourg Party", @"bundle": @"com.apple.Hermes2025Face",
          @"face": @"NTKHermes2025FaceBundle.Hermes2025Face",
          @"view": @"NTKHermes2025FaceBundle.Hermes2025FaceView"}
    ];
}
static BOOL LoadOriginalFrameworks(void) {
    if (!dlopen("/System/Library/Frameworks/ClockKit.framework/ClockKit", RTLD_LAZY))
        return NO;
    if (!dlopen("/System/Library/PrivateFrameworks/NanoTimeKit.framework/NanoTimeKit", RTLD_LAZY))
        return NO;
    NSString *root = @"/System/Library/NanoTimeKit/FaceBundles";
#if TARGET_OS_SIMULATOR
    const char *simRoot = getenv("SIMULATOR_ROOT");
    if (simRoot && simRoot[0])
        root = [@(simRoot) stringByAppendingPathComponent:@"System/Library/NanoTimeKit/FaceBundles"];
#endif
    for (NSString *name in @[@"NTKZeusFaceBundle.bundle", @"NTKHermes2025FaceBundle.bundle"]) {
        NSBundle *bundle = [NSBundle bundleWithPath:[root stringByAppendingPathComponent:name]];
        if (!bundle || ![bundle loadAndReturnError:nil])
            return NO;
    }
    return YES;
}
static id AppHost(void) {
    id app = Get(NSClassFromString(@"UIApplication"), @"sharedApplication");
    id windows = Get(app, @"windows");
    id window = [windows respondsToSelector:@selector(firstObject)] ? [windows firstObject] : nil;
    return Get(window, @"rootViewController");
}
static BOOL ValidOneArgumentVoidMethod(id object, SEL selector, const char *allowed) {
    Method m = object ? class_getInstanceMethod([object class], selector) : NULL;
    if (!m || method_getNumberOfArguments(m) != 3) return NO;
    char *ret = method_copyReturnType(m);
    char *arg = method_copyArgumentType(m, 2);
    BOOL valid = ret && ret[0] == 'v' && arg && strchr(allowed, arg[0]) != NULL;
    if (ret) free(ret);
    if (arg) free(arg);
    return valid;
}
// Keep the genuine OS-provided BacklightServices scene state. Do not create
// synthetic BLS objects or a pretend watchOS Always-On lifecycle.
static void ConnectOriginalBacklight(id controller) {
    id app = Get(NSClassFromString(@"UIApplication"), @"sharedApplication");
    Class nativeType = NSClassFromString(@"BLSBacklightSceneVisualState");
    if (!nativeType) return;
    for (id scene in Get(app, @"connectedScenes")) {
        id env = Get(scene, @"_backlightSceneEnvironment");
        id native = Get(env, @"visualState");
        SEL setter = NSSelectorFromString(@"setBacklightVisualState:");
        if ([native isKindOfClass:nativeType] &&
            ValidOneArgumentVoidMethod(controller, setter, "@")) {
            ((void(*)(id, SEL, id))objc_msgSend)(controller, setter, native);
            return;
        }
    }
}
static void UnmountOriginal(void) {
    if (Has(sController, @"resignActive"))
        ((void(*)(id, SEL))objc_msgSend)(sController, NSSelectorFromString(@"resignActive"));
    if (Has(sController, @"willMoveToParentViewController:"))
        ((void(*)(id, SEL, id))objc_msgSend)(
            sController, NSSelectorFromString(@"willMoveToParentViewController:"), nil);
    if (Has(sRoot, @"removeFromSuperview"))
        ((void(*)(id, SEL))objc_msgSend)(sRoot, NSSelectorFromString(@"removeFromSuperview"));
    if (Has(sController, @"removeFromParentViewController"))
        ((void(*)(id, SEL))objc_msgSend)(
            sController, NSSelectorFromString(@"removeFromParentViewController"));
    sController = nil;
    sRoot = nil;
    sFace = nil;
}
@implementation BQOriginalHermes
+ (NSString *)presentFaceAtIndex:(NSInteger)index {
    if (!NSThread.isMainThread) return @"Main thread required";
    NSArray *items = Styles();
    if (index < 0 || index >= (NSInteger)items.count) return @"Invalid Apple face selection";
    // 26.x is the known test family; any later generation needs fresh ABI tests.
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 26)
        return @"This experimental native viewer is validated for watchOS 26 only";
    if (!LoadOriginalFrameworks()) return @"Apple NanoTimeKit bundles unavailable";
    NSDictionary *spec = items[index];
    id device = Get(NSClassFromString(@"CLKDevice"), @"currentDevice");
    id manager = Get(NSClassFromString(@"NTKFaceBundleManager"), @"sharedManager");
    if (!device || !manager || !Has(device, @"setCollectionType:") ||
        !Has(manager, @"faceBundleForBundleIdentifier:onDevice:forMigration:"))
        return @"Original Apple FaceBundle API unavailable";

    id face = nil;
    id controller = nil;
    id root = nil;
    id nativeFaceView = nil;
    unsigned original = GetUnsigned(device, @"collectionType");
    if (original != 1) return @"Unexpected device category; no changes made";

    // The temporary flag affects only this app process. It is always restored;
    // the system watch identity, MobileGestalt and ClockFace stay untouched.
    @try {
        SetUnsigned(device, @"setCollectionType:", 5);
        if (GetUnsigned(device, @"collectionType") == 5) {
            id bundle = ((id(*)(id, SEL, id, id, BOOL))objc_msgSend)(
                manager,
                NSSelectorFromString(@"faceBundleForBundleIdentifier:onDevice:forMigration:"),
                spec[@"bundle"], device, NO);
            if (Has(bundle, @"defaultFaceForDevice:"))
                face = ((id(*)(id, SEL, id))objc_msgSend)(
                    bundle, NSSelectorFromString(@"defaultFaceForDevice:"), device);
            Class faceClass = NSClassFromString(spec[@"face"]);
            if (face && faceClass && [face isKindOfClass:faceClass]) {
                id snapshotter = [NSClassFromString(@"NTKFaceSnapshotter") new];
                id defaults = Get(NSClassFromString(@"NTKFaceSnapshotter"),
                                  @"defaultModernSnapshotOptions");
                NSMutableDictionary *options = [defaults isKindOfClass:NSDictionary.class]
                    ? [defaults mutableCopy] : [NSMutableDictionary new];
                options[@"NTKSnapshotUseCanonicalContentKey"] = @NO;
                options[@"NTKSnapshotIgnoreSnapshotImages"] = @YES;
                if (Has(snapshotter, @"viewControllerForFace:withOptions:"))
                    controller = ((id(*)(id, SEL, id, id))objc_msgSend)(
                        snapshotter, NSSelectorFromString(@"viewControllerForFace:withOptions:"),
                        face, options);
                root = Get(controller, @"view");
                nativeFaceView = Get(controller, @"faceView");
                Class viewClass = NSClassFromString(spec[@"view"]);
                if (!nativeFaceView || !viewClass ||
                    ![nativeFaceView isKindOfClass:viewClass]) {
                    controller = nil;
                    root = nil;
                }
            }
        }
    } @catch (NSException *exception) {
        controller = nil;
        root = nil;
    } @finally {
        SetUnsigned(device, @"setCollectionType:", original);
    }
    if (!controller || !root) return @"Genuine Apple FaceView unavailable (no replica)";
    id host = AppHost();
    id hostView = Get(host, @"view");
    if (!hostView) return @"Unable to locate the Watch app host controller";
    UnmountOriginal();
    CGRect rect = ((CGRect(*)(id, SEL))objc_msgSend)(hostView, NSSelectorFromString(@"bounds"));
    if (Has(root, @"setFrame:"))
        ((void(*)(id, SEL, CGRect))objc_msgSend)(root, NSSelectorFromString(@"setFrame:"), rect);
    if (Has(root, @"setAutoresizingMask:"))
        ((void(*)(id, SEL, NSUInteger))objc_msgSend)(root, NSSelectorFromString(@"setAutoresizingMask:"), 18);
    ((void(*)(id, SEL, id))objc_msgSend)(host, NSSelectorFromString(@"addChildViewController:"), controller);
    ((void(*)(id, SEL, id))objc_msgSend)(hostView, NSSelectorFromString(@"addSubview:"), root);
    if (Has(controller, @"didMoveToParentViewController:"))
        ((void(*)(id, SEL, id))objc_msgSend)(controller, NSSelectorFromString(@"didMoveToParentViewController:"), host);
    if (Has(controller, @"unfreeze"))
        ((void(*)(id, SEL))objc_msgSend)(controller, NSSelectorFromString(@"unfreeze"));
    // The native snapshot controller starts in data mode 3. Original Apple
    // live data-mode propagation was physically verified for these five
    // classic faces; Faubourg Party's SceneEngine requires its snapshot mode.
    SEL mode = NSSelectorFromString(@"setDataMode:");
    if (index != 5 && ValidOneArgumentVoidMethod(controller, mode, "qQiI"))
        ((void(*)(id, SEL, NSInteger))objc_msgSend)(controller, mode, 1);
    if (Has(controller, @"becomeActive"))
        ((void(*)(id, SEL))objc_msgSend)(controller, NSSelectorFromString(@"becomeActive"));
    ConnectOriginalBacklight(controller);
    sController = controller;
    sRoot = root;
    sFace = face;
    Class pressClass = NSClassFromString(@"UILongPressGestureRecognizer");
    if (pressClass) {
        id recognizer = ((id(*)(id, SEL, id, SEL))objc_msgSend)(
            [pressClass alloc], NSSelectorFromString(@"initWithTarget:action:"),
            self, @selector(onOriginalLongPress:));
        if (Has(root, @"addGestureRecognizer:"))
            ((void(*)(id, SEL, id))objc_msgSend)(
                root, NSSelectorFromString(@"addGestureRecognizer:"), recognizer);
    }
    // A factory returning an object is not proof that it reached the display.
    // Fail closed if Apple's native FaceView is not attached to a real window.
    if (!Get(nativeFaceView, @"window")) {
        UnmountOriginal();
        return @"Genuine Apple FaceView was not attached to a window";
    }
    // Do not claim this is an Apple system Face Gallery selection.
    return @"native-face-mounted";
}
+ (void)onOriginalLongPress:(id)gesture {
    if (GetUnsigned(gesture, @"state") != 1) return;
    [self dismissFace];
    [NSNotificationCenter.defaultCenter
        postNotificationName:@"BQOriginalHermesDismissed" object:nil];
}
+ (void)dismissFace {
    if (!NSThread.isMainThread) return;
    UnmountOriginal();
}
+ (void)updateActualReducedLuminance:(BOOL)reduced {
    if (!NSThread.isMainThread || !sController) return;
    ConnectOriginalBacklight(sController);
    id animation = Get(sController, @"tritiumAnimationController");
    id tritium = Get(sController, @"tritiumController");
    id originalFaceView = Get(sController, @"faceView");
    if (!animation || Get(animation, @"tritiumController") != tritium ||
        Get(tritium, @"faceView") != originalFaceView ||
        !Get(originalFaceView, @"window")) return;
    SEL selector = NSSelectorFromString(@"setTritiumVisibleImmediately:");
    if (!ValidOneArgumentVoidMethod(animation, selector, "Bc")) return;
    // Invokes Apple's actual NTKTritiumAnimationController. No simulated
    // frames or handmade dimming. Does not guarantee first-party AOD timing.
    ((void(*)(id, SEL, BOOL))objc_msgSend)(animation, selector, reduced);
}
@end
