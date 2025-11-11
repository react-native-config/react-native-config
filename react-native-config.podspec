# frozen_string_literal: true

require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

fabric_enabled = ENV['RCT_NEW_ARCH_ENABLED'] == '1'

Pod::Spec.new do |s|
  s.name         = 'react-native-config'
  s.version      = package['version']
  s.summary      = 'Expose config variables to React Native apps'
  s.author       = 'Pedro Belo'

  s.homepage     = 'https://github.com/luggit/react-native-config'

  s.license      = 'MIT'
  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.0'
  s.macos.deployment_target = '10.15'
  s.visionos.deployment_target = '1.0' if s.respond_to?(:visionos)

  s.source       = { git: 'https://github.com/luggit/react-native-config.git', tag: "v#{s.version.to_s}" }
  s.script_phase = {
    name: 'Config codegen',
    script: '
    #!/bin/bash

    # We have to touch the file because otherwise Xcode will not detect the change and will not re-run the script (https://github.com/luggit/react-native-config/issues/698)
    touch "${PODS_TARGET_SRCROOT}/ios/ReactNativeConfig/BuildDotenvConfig.rb"
        
    set -ex
    HOST_PATH="$SRCROOT/../.."
    "${PODS_TARGET_SRCROOT}/ios/ReactNativeConfig/BuildDotenvConfig.rb" "$HOST_PATH" "${PODS_TARGET_SRCROOT}/ios/ReactNativeConfig"
    ',
    execution_position: :before_compile,
    always_out_of_date: "1",
    input_files: ['$PODS_TARGET_SRCROOT/ios/ReactNativeConfig/BuildDotenvConfig.rb'],
    output_files: ['$BUILD_DIR/GeneratedInfoPlistDotEnv.h', '$PODS_TARGET_SRCROOT/ios/ReactNativeConfig/GeneratedDotEnv.m']
  }

  s.requires_arc = true
  s.default_subspec = 'App'

    s.subspec 'App' do |app|
    app.source_files = 'ios/**/*.{h,m,mm}'
    
    if fabric_enabled
      install_modules_dependencies(app)
    else
      app.dependency 'React-Core'
    end
  end

  # Use this subspec for iOS extensions that cannot use React dependency
  s.subspec 'Extension' do |ext|
    # Had to duplicate the script_phase since it wasn't being passed down. Not sure why
    ext.script_phase = {
      name: 'Config codegen',
      script: %(
        set -ex
        HOST_PATH="$SRCROOT/../.."
        "${PODS_TARGET_SRCROOT}/ios/ReactNativeConfig/BuildDotenvConfig.rb" "$HOST_PATH" "${PODS_TARGET_SRCROOT}/ios/ReactNativeConfig"
        ),
      execution_position: :before_compile,
      always_out_of_date: "1",
      input_files: ['$PODS_TARGET_SRCROOT/ios/ReactNativeConfig/BuildDotenvConfig.rb'],
      output_files: ['$PODS_TARGET_SRCROOT/ios/ReactNativeConfig/GeneratedDotEnv.m']
    }
    ext.source_files = ['ios/**/RNCConfig.{h,m}', 'ios/**/GeneratedDotEnv.m']
  end

end
