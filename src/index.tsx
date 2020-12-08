import { NativeModules } from 'react-native';

type GeolocationType = {
  multiply(a: number, b: number): Promise<number>;
};

const { Geolocation } = NativeModules;

export default Geolocation as GeolocationType;
