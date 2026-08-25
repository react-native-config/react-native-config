"use strict";

const NativeConfigModule = require("./codegen/NativeConfigModule").default;

if (NativeConfigModule == null) {
  // TurboModuleRegistry.get returns null when the native module is not registered in the app.
  // Left alone, the next line fails with "Cannot read property 'getConfig' of null", which says
  // nothing about the cause - so spell out the ones that actually produce this.
  throw new Error(
    "react-native-config: the native module RNCConfigModule was not found.\n\n" +
      "JavaScript loaded, but the native side is not registered in this build. Common causes:\n\n" +
      "  1. The app was not rebuilt after installing the library. Restarting Metro is not enough -\n" +
      "     rebuild the native app.\n" +
      "  2. Autolinking is disabled for this library. Check react-native.config.js for a\n" +
      "     `dependencies` entry setting `platforms.android` or `platforms.ios` to null, and\n" +
      "     remove it.\n" +
      "  3. The library is linked manually. React Native 0.60+ autolinks it, and on the New\n" +
      "     Architecture a manually linked module is not registered as a TurboModule. Remove\n" +
      "     `include ':react-native-config'` from android/settings.gradle and the matching\n" +
      "     `implementation project(':react-native-config')` from android/app/build.gradle.\n" +
      "  4. iOS only: `pod install` has not run since the library was installed.\n\n" +
      "See https://github.com/react-native-config/react-native-config#troubleshooting"
  );
}

export const Config = NativeConfigModule.getConfig().config;
export default Config;
