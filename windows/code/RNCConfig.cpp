#include "pch.h"
#include "RNCConfig.h"
#include <JSValue.h>

using namespace winrt::Microsoft::ReactNative;

namespace winrt::RNCConfig
{
	RNCConfigCodegen::ConfigModuleSpec_getConfig_returnType RNCConfigModule::getConfig() noexcept
	{
		JSValueObject obj{};
	#if __has_include("RNCConfigValuesObject.inc.g.h")
	#include "RNCConfigValuesObject.inc.g.h"
	#endif

		RNCConfigCodegen::ConfigModuleSpec_getConfig_returnType ret = { std::move(obj)};
		return ret; 
	}
}
