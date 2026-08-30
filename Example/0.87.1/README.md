# react-native-config example — React Native 0.87.1

Example app demonstrating [react-native-config](../../) on React Native 0.87 (New Architecture).

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
