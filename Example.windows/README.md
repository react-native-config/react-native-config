# react-native-config Windows example

Minimal Windows example demonstrating [react-native-config](../) on React Native 0.79 with [react-native-windows](https://github.com/microsoft/react-native-windows) 0.79 — the newest React Native version react-native-windows supports today. The main cross-platform example on the latest React Native lives in [`Example/`](../Example); this app should be upgraded and folded into it once react-native-windows catches up.

The app reads `ENV` and `API_URL` from the [`.env`](.env) file in this directory and renders them on screen.

## Setup

```sh
yarn install
```

## Run (requires Windows)

```sh
yarn windows
```

## Tests

```sh
yarn test
yarn test:windows
```

## Note for contributors

Like the main example, this app depends on the library through a symlink (`"react-native-config": "link:../"`), so builds run against the real library sources in the repository root.
