import * as React from 'react';
import { StyleSheet, View, Text } from 'react-native';
import Geolocation from 'geolocation';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();
  const [loc, setLoc] = React.useState({});

  React.useEffect(() => {
  }, []);
console.log(result)
  return (
    <View style={styles.container}>
      <Text>lat: </Text>
      <Text>lng: </Text>

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
