
/*
 * This file is auto-generated from a NativeModule spec file in js.
 *
 * This is a C++ Spec class that should be used with MakeTurboModuleProvider to register native modules
 * in a way that also verifies at compile time that the native module matches the interface required
 * by the TurboModule JS spec.
 */
#pragma once
// clang-format off

// #include "NativeConfigModuleDataTypes.g.h" before this file to use the generated type definition
#include <NativeModules.h>
#include <tuple>

namespace RNCConfigCodegen {

inline winrt::Microsoft::ReactNative::FieldMap GetStructInfo(ConfigModuleSpec_getConfig_returnType*) noexcept {
    winrt::Microsoft::ReactNative::FieldMap fieldMap {
        {L"config", &ConfigModuleSpec_getConfig_returnType::config},
    };
    return fieldMap;
}

struct ConfigModuleSpec : winrt::Microsoft::ReactNative::TurboModuleSpec {
  static constexpr auto methods = std::tuple{
      SyncMethod<ConfigModuleSpec_getConfig_returnType() noexcept>{0, L"getConfig"},
  };

  template <class TModule>
  static constexpr void ValidateModule() noexcept {
    constexpr auto methodCheckResults = CheckMethods<TModule, ConfigModuleSpec>();

    REACT_SHOW_METHOD_SPEC_ERRORS(
          0,
          "getConfig",
          "    REACT_SYNC_METHOD(getConfig) ConfigModuleSpec_getConfig_returnType getConfig() noexcept { /* implementation */ }\n"
          "    REACT_SYNC_METHOD(getConfig) static ConfigModuleSpec_getConfig_returnType getConfig() noexcept { /* implementation */ }\n");
  }
};

} // namespace RNCConfigCodegen
