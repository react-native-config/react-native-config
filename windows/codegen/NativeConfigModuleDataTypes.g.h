
/*
 * This file is auto-generated from a NativeModule spec file in js.
 *
 * This is a C++ Spec class that should be used with MakeTurboModuleProvider to register native modules
 * in a way that also verifies at compile time that the native module matches the interface required
 * by the TurboModule JS spec.
 */
#pragma once
// clang-format off

#include <string>
#include <optional>
#include <functional>
#include <vector>
#include <JSValue.h>

namespace RNCConfigCodegen {

struct ConfigModuleSpec_getConfig_returnType {
    winrt::Microsoft::ReactNative::JSValue config;
};

} // namespace RNCConfigCodegen
