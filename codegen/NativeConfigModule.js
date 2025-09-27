// @flow
import type { TurboModule } from "react-native/Libraries/TurboModule/RCTExport";
import { TurboModuleRegistry } from "react-native";

export interface Spec extends TurboModule {
  +getConfig: () => {|
    config: Object,
  |};
}

export default (TurboModuleRegistry.get<Spec>("RNCConfigModule"): ?Spec);
