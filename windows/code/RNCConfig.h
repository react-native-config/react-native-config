#pragma once

#include "pch.h"

#if __has_include("../codegen/NativeConfigModuleDataTypes.g.h")
  #include "../codegen/NativeConfigModuleDataTypes.g.h"
#endif
#include "../codegen/NativeConfigModuleSpec.g.h"

#include "NativeModules.h"

#if __has_include("RNCConfigValues.h")
#include "RNCConfigValues.h"
#endif

namespace winrt::RNCConfig
{
  REACT_MODULE(RNCConfigModule);
  struct RNCConfigModule
  {
    using ModuleSpec = RNCConfigCodegen::ConfigModuleSpec;

#if __has_include("RNCConfigValuesModule.inc.g.h")
#include "RNCConfigValuesModule.inc.g.h"
#else
// Generated constants will be included at build-time
#endif

  REACT_SYNC_METHOD(getConfig);
  RNCConfigCodegen::ConfigModuleSpec_getConfig_returnType getConfig() noexcept;
};
}
