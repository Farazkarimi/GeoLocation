import * as React from 'react';
import { StyleSheet, View, Text } from 'react-native';
import Geolocation from 'geolocation';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();

  // React.useEffect(() => {
  //   Geolocation.multiply(3, 7).then(setResult);
  // }, []);
console.log(result)
  return (
    <View style={styles.container}>
      <Text>Result:</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
