package com.lugg.RNCConfig;

import androidx.annotation.NonNull;
import com.facebook.react.BaseReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.module.model.ReactModuleInfo;
import com.facebook.react.module.model.ReactModuleInfoProvider;
import java.util.HashMap;
import java.util.Map;

public class RNCConfigPackage extends BaseReactPackage {

  @Override
  public NativeModule getModule(String name, @NonNull ReactApplicationContext reactContext) {
    if (name.equals(RNCConfigModuleImpl.NAME)) {
      return new RNCConfigModule(reactContext);
    } else {
      return null;
    }
  }

  @NonNull
  @Override
  public ReactModuleInfoProvider getReactModuleInfoProvider() {
    return new ReactModuleInfoProvider() {
      @NonNull
      @Override
      public Map<String, ReactModuleInfo> getReactModuleInfos() {
        final Map<String, ReactModuleInfo> moduleInfos = new HashMap<>();
        boolean isTurboModule = BuildConfig.IS_NEW_ARCHITECTURE_ENABLED;
        moduleInfos.put(
            RNCConfigModule.NAME,
            new ReactModuleInfo(
                RNCConfigModule.NAME,
                RNCConfigModule.NAME,
                false, // canOverrideExistingModule
                true, // needsEagerInit
                false, // hasConstants
                false, // isCxxModule
                isTurboModule // isTurboModule
            ));
        return moduleInfos;
      };
    };
  }
}
