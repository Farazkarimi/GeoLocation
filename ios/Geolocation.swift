
import CoreLocation
import UserNotifications

@objc(Geolocation)
class Geolocation: NSObject {
    var locationManager = CLLocationManager()
    override init() {
        super.init()
        locationManager.requestWhenInUseAuthorization()
    }

    @objc(multiply:withB:withResolver:withRejecter:)
    func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        resolve(a*b)
    }

     @objc(getLocation:withB:withResolver:withRejecter:)
     func getLocation(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
         locationManager.requestWhenInUseAuthorization()
         var currentLoc: CLLocation!
         if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
         CLLocationManager.authorizationStatus() == .authorizedAlways) {
            currentLoc = locationManager.location
            print(currentLoc.coordinate.latitude)
            print(currentLoc.coordinate.longitude)
            let json = "{" + "lat"
            
            let jsonObject: [String: Any] = [
                "lat": currentLoc.coordinate.longitude,
                "lng": currentLoc.coordinate.latitude,
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions()) as NSData
                let jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue) as! String
          
                resolve(jsonString)
            } catch _ {
                print ("JSON Failure")
            }
            
         }
     }
    
    
}
