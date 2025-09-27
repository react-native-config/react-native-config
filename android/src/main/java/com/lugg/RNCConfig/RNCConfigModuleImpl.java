package com.lugg.RNCConfig;

import android.content.res.Resources;
import android.util.Log;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.WritableMap;
import java.lang.ClassNotFoundException;
import java.lang.IllegalAccessException;
import java.lang.reflect.Field;
import java.util.Map;
import java.util.HashMap;

public class RNCConfigModuleImpl {
  public static final String NAME = "RNCConfigModule";

  private ReactApplicationContext context;

  public RNCConfigModuleImpl(ReactApplicationContext context) {
    this.context = context;
  }

  public WritableMap getConfig() {
    final Map<String, Object> ret = new HashMap<>();

    // Codegen ensures that the constants defined in the module spec and in the native module implementation
    // are consistent, which is tad problematic in this case, as the constants are dependant on the `.env`
    // file. The simple workaround is to define a `config` object that will contain actual constants.
    // This way the types between JS and Native side remain consistent, while functionality stays the same.
    // TL;DR:
    // instead of exporting { constant1: "value1", constant2: "value2" }
    // we export { config: { constant1: "value1", constant2: "value2" } }
    // because of type safety on the new arch
    final Map<String, Object> realConstants = new HashMap<>();

    try {
      int resId = this.context.getResources().getIdentifier("build_config_package", "string", context.getPackageName());
      String className;
      try {
        className = this.context.getString(resId);
      } catch (Resources.NotFoundException e) {
        className = this.context.getApplicationContext().getPackageName();
      }
      Class clazz = Class.forName(className + ".BuildConfig");
      Field[] fields = clazz.getDeclaredFields();
      for(Field f: fields) {
        try {
          realConstants.put(f.getName(), f.get(null));
        }
        catch (IllegalAccessException e) {
          Log.d("ReactNative", "ReactConfig: Could not access BuildConfig field " + f.getName());
        }
      }
    }
    catch (ClassNotFoundException e) {
      Log.d("ReactNative", "ReactConfig: Could not find BuildConfig class");
    }

    ret.put("config", realConstants);

    return MapConverter.convertMapToWritableMap(ret);
  }
}
