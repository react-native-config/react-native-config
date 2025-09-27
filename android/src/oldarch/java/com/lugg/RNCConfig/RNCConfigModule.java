package com.lugg.RNCConfig;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;

public class RNCConfigModule extends ReactContextBaseJavaModule {
  public static final String NAME = "RNCConfigModule";

  private RNCConfigModuleImpl implementation;

  public RNCConfigModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.implementation = new RNCConfigModuleImpl(reactContext);
  }

  @Override
  public String getName() {
    return RNCConfigModuleImpl.NAME;
  }

  @ReactMethod(isBlockingSynchronousMethod = true)
  public WritableMap getConfig() {
    return this.implementation.getConfig();
  }
}
