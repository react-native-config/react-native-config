# react-native-config example

Example app demonstrating [react-native-config](../) on React Native 0.87 (New Architecture).

The app reads `ENV` and `API_URL` from the [`.env`](.env) file in this directory and renders them on screen.

## Setup

```sh
yarn install
```

## iOS

```sh
cd ios
bundle install
bundle exec pod install
cd ..
yarn ios
```

## Android

```sh
yarn android
```

## Tests

```sh
yarn test
```

## Note for contributors

The app depends on the library through a symlink (`"react-native-config": "link:../"`), so building the iOS example runs the Config codegen build phase against the real library sources and overwrites `ios/ReactNativeConfig/GeneratedDotEnv.m` in the repository root. Don't commit that change — restore the placeholder before committing:

```sh
git checkout -- ../ios/ReactNativeConfig/GeneratedDotEnv.m
```
