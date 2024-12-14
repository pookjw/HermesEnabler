//
//  init.c
//  HermesEnabler
//
//  Created by Jinwoo Kim on 12/14/24.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>

namespace he_CLKDevice {
    namespace _loadDeviceInfo {
        void (*original)(id self, SEL _cmd);
        void custom(id self, SEL _cmd) {
            original(self, _cmd);
            
            assert(object_setInstanceVariable(self, "_collectionType", reinterpret_cast<void *>(5)));
//            assert()
        }
        void swizzle() {
            Method method = class_getInstanceMethod(objc_lookUpClass("CLKDevice"), sel_registerName("_loadDeviceInfo"));
            original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
            method_setImplementation(method, reinterpret_cast<IMP>(custom));
        }
    }
}

__attribute__((constructor)) void init(void) {
    he_CLKDevice::_loadDeviceInfo::swizzle();
}
