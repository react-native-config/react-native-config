/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import Config from '@pasteltech/react-native-config';
import React from 'react';
import {StyleSheet, Text, View} from 'react-native';

const App = () => {
  console.log('Config:', Config);
  return (
    <View style={styles.container}>
      <Text style={styles.text}>ENV={Config.ENV}</Text>
      <Text style={styles.text}>API_URL={Config.API_URL}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  text: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
});

export default App;
