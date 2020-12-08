import * as React from 'react';
import { StyleSheet, View, Text } from 'react-native';
import Geolocation from 'geolocation';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();
  const [loc, setLoc] = React.useState({});

  React.useEffect(() => {
    Geolocation.multiply(3, 7).then(setResult);
    Geolocation.getLocation(2, 3).then((res) => {
      const response = JSON.parse(res);
      setLoc(response);
    })
  }, []);
console.log(result)
  return (
    <View style={styles.container}>
      <Text>lat: {loc.lat}</Text>
      <Text>lng: {loc.lng}</Text>

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
