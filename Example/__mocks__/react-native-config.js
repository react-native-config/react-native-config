/**
 * Jest automatic mock for react-native-config: the native TurboModule is not
 * registered in the test environment, so mirror the values from .env here.
 *
 * @format
 */

export const Config = {
  ENV: 'dev',
  API_URL: 'http://localhost',
};

export default Config;
