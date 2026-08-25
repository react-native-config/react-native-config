package com.lugg.RNCConfig;

import android.content.res.Resources;
import android.util.Log;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.WritableMap;
import java.lang.ClassNotFoundException;
import java.lang.IllegalAccessException;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;

public class RNCConfigModuleImpl {
  public static final String NAME = "RNCConfigModule";

  private static final String TAG = "ReactNative";

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

    final List<String> candidates = buildConfigPackageCandidates();
    Class<?> clazz = null;

    for (String candidate : candidates) {
      try {
        clazz = Class.forName(candidate + ".BuildConfig");
        break;
      }
      catch (ClassNotFoundException e) {
        // Not here - try the next candidate.
      }
    }

    if (clazz == null) {
      Log.w(TAG, "ReactConfig: Could not find BuildConfig class. Tried: " + candidates + ". "
          + "If BuildConfig is generated somewhere else, point the library at it with "
          + "`resValue \"string\", \"build_config_package\", \"<your namespace>\"` in android/app/build.gradle.");
    }
    else {
      Field[] fields = clazz.getDeclaredFields();
      for(Field f: fields) {
        try {
          realConstants.put(f.getName(), f.get(null));
        }
        catch (IllegalAccessException e) {
          Log.d(TAG, "ReactConfig: Could not access BuildConfig field " + f.getName());
        }
      }
    }

    ret.put("config", realConstants);

    return MapConverter.convertMapToWritableMap(ret);
  }

  /**
   * Packages that may hold the app's generated BuildConfig, most-specific first.
   *
   * BuildConfig is generated in the module's `namespace`, which is not necessarily the
   * applicationId: `applicationIdSuffix` and per-flavor `applicationId` change the latter and
   * leave the former alone. Resolving only via getPackageName() therefore misses BuildConfig on
   * any such variant, and the config silently arrives in JS as {}.
   */
  private List<String> buildConfigPackageCandidates() {
    // LinkedHashSet keeps the priority order below while dropping duplicates, which is the
    // common case: for most apps all three candidates are the same string.
    final Set<String> candidates = new LinkedHashSet<>();

    // 1. An explicit `resValue "string", "build_config_package", "..."`. Honoured first so that
    //    existing setups relying on it keep working, and so it stays an escape hatch when the
    //    derived candidates below are wrong.
    int resId = this.context.getResources().getIdentifier(
        "build_config_package", "string", this.context.getPackageName());
    if (resId != 0) {
      try {
        candidates.add(this.context.getString(resId));
      }
      catch (Resources.NotFoundException e) {
        // Declared but unreadable - fall through to the derived candidates.
      }
    }

    // 2. The package declaring the Application class. That class is part of the app module, so
    //    its package is the `namespace` - unaffected by applicationId/applicationIdSuffix.
    Package applicationPackage = this.context.getApplicationContext().getClass().getPackage();
    if (applicationPackage != null) {
      candidates.add(applicationPackage.getName());
    }

    // 3. The applicationId. Correct whenever it matches the namespace, which is the default.
    candidates.add(this.context.getApplicationContext().getPackageName());

    return new ArrayList<>(candidates);
  }
}
