#import "RNCConfig.h"
#import "GeneratedDotEnv.m" // written during build by BuildDotenvConfig.rb

// A GeneratedDotEnv.m produced by an older version of the library defines DOT_ENV alone. That
// copy lives in node_modules and is only replaced when the codegen build phase runs, which is
// precisely the case this file reports on - so fall back rather than failing to compile.
#ifndef RNC_DOT_ENV_FOUND
#define RNC_DOT_ENV_FOUND 0
#endif
#ifndef RNC_DOT_ENV_PATH
#define RNC_DOT_ENV_PATH @"(unknown - GeneratedDotEnv.m predates this diagnostic)"
#endif

@implementation RNCConfig

+ (NSDictionary *)env {
    NSDictionary *env = (NSDictionary *)DOT_ENV;
    [self warnOnceIfEmpty:env];
    return env;
}

+ (NSString *)envFor: (NSString *)key {
    NSString *value = (NSString *)[self.env objectForKey:key];
    return value;
}

// An empty config reaches JS as `{}` with nothing else to go on, and is the most reported
// symptom against this library. Say which file was looked for, and whether it was found, at the
// point the emptiness is first observed.
//
// NSLog rather than RCTLog: this file is also compiled into the `Extension` subspec, which has no
// React dependency.
+ (void)warnOnceIfEmpty:(NSDictionary *)env {
    if (env.count > 0) {
        return;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (RNC_DOT_ENV_FOUND) {
            NSLog(@"[react-native-config] Config is empty. The env file was read from %@, and no "
                  @"variables were parsed out of it - check that it contains KEY=value lines.",
                  RNC_DOT_ENV_PATH);
        } else {
            NSLog(@"[react-native-config] Config is empty: no env file was found. Looked for %@.\n"
                  @"  - If the path is wrong, set ENVFILE (e.g. `ENVFILE=.env.staging npx react-native run-ios`),\n"
                  @"    or point the library at the right root if this project is in a monorepo.\n"
                  @"  - If the path is right, the 'Config codegen' build phase did not run: re-run\n"
                  @"    `pod install`, then build again.\n"
                  @"  See https://github.com/react-native-config/react-native-config#troubleshooting",
                  RNC_DOT_ENV_PATH);
        }
    });
}

@end
