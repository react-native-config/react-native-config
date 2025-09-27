#ifdef RCT_NEW_ARCH_ENABLED
#import "RNCConfigSpec.h"

@interface RNCConfigModule : NSObject <NativeConfigModuleSpec>
#else

#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#elif __has_include("React/RCTBridgeModule.h")
#import "React/RCTBridgeModule.h"
#else
#import "RCTBridgeModule.h"
#endif

@interface RNCConfigModule : NSObject <RCTBridgeModule>
#endif // RCT_NEW_ARCH_ENABLED

+ (NSDictionary *)env;
+ (NSString *)envFor: (NSString *)key;

@end
