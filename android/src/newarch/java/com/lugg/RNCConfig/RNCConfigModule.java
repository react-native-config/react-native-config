package com.lugg.RNCConfig;

import androidx.annotation.NonNull;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.WritableMap;

public class RNCConfigModule extends NativeConfigModuleSpec {
  private final RNCConfigModuleImpl implementation;

  public RNCConfigModule(ReactApplicationContext context) {
    super(context);
    implementation = new RNCConfigModuleImpl(context);
  }

  @Override
  @NonNull
  public String getName() {
    return RNCConfigModuleImpl.NAME;
  }


  @Override
  public WritableMap getConfig() {
    return this.implementation.getConfig();
  }
}
