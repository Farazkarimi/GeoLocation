
import CoreLocation
import UserNotifications

@objc(Geolocation)
class Geolocation: NSObject {
    var locationManager = CLLocationManager()
    override init() {
        super.init()
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
            
            let jsonObject: [String: Any] = [
                "lat": currentLoc.coordinate.longitude,
                "lng": currentLoc.coordinate.latitude,
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions()) as NSData
                let jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
          
                resolve(jsonString)
            } catch _ {
                print ("JSON Failure")
            }
            
         }
     }
    
    @objc(getServerResponse:withOffline:withTimeInterval:withResolver:withRejecter:)
    func getServerResponse(token: String, offline: Bool, timeInterval: Double, resolve:@escaping  RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) {
        let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1dWlkIjoiMTljZTE3ZTk1NTVhYWE2NCIsInN1YiI6OTIsImlzcyI6Imh0dHA6Ly9zdGcuZHJvcC1kZXYuY29tL2FwaS92Mi9sb2dpbiIsImlhdCI6MTYwODAyOTkwOCwiZXhwIjo1MjA4MDI5OTA4LCJuYmYiOjE2MDgwMjk5MDgsImp0aSI6Inl5ajJlSkpyMXpQM0s5WHQifQ.oSUe6whqyR6GcY5IR8wEdisCosZKnYXoyefQ_TG67ZI"
        GeoLocationManager.setup(.init(url: "https://stg.drop-dev.com/api/v2/positions", offline: false, timeInterval: 10.0, token: token))
        GeoLocationManager.shared.onServerResponsed = { result in
            resolve(result)
        }
    }
    
}

class GeoLocationManager: NSObject {
    
    static let shared = GeoLocationManager()
    
    private var locationManager: CLLocationManager?
    private var onLocationChanged : (_ lat: Double, _ long: Double) -> () = { _ , _ in }
    private var timer: Timer?
    private var timerValue = 0
    
    private let url: String
    private let offline: Bool
    private let timeInterval: TimeInterval
    private let token: String
    
    var onServerResponsed: (String) -> () = { _ in }
    
    struct Config {
        let url: String
        let offline: Bool
        let timeInterval: TimeInterval
        let token: String
    }
    
    private static var config:Config?
    
    class func setup(_ config:Config){
        GeoLocationManager.config = config
    }
    
    private override init() {
        guard let config = GeoLocationManager.config else {
            fatalError("Error - you must call setup before accessing MySingleton.shared")
        }
        self.url = config.url
        self.offline = config.offline
        self.timeInterval = config.timeInterval
        self.token = config.token
        super.init()
        self.start()
    }
    
    private func start() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        UIDevice.current.isBatteryMonitoringEnabled = true
        // Step 4: request authorization
        locationManager?.requestWhenInUseAuthorization()
        // or
        locationManager?.requestAlwaysAuthorization()
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.activityType = .automotiveNavigation
        if UIDevice.current.batteryState == .unplugged {
            locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }else {
            locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        }
        locationManager?.distanceFilter = 100.0 // 100m
        locationManager?.startUpdatingLocation()
        
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.sendLocationIfNeeded), userInfo: nil, repeats: true)
        
        self.onLocationChanged = { lat, long in
            //if Double(self.timerValue) > self.timeInterval {
                self.timerValue = 0
                self.request(with: self.url, offline: false, lat: lat, long: long, completion: { [weak self] result in
                    guard let self = self else { return }
                    self.onServerResponsed(result)
                })
            //}
        }
    }
    
    @objc func sendLocationIfNeeded() {
        if Double(timerValue) > self.timeInterval {
            if let lat = self.locationManager?.location?.coordinate.latitude,
               let long = self.locationManager?.location?.coordinate.longitude {
                self.request(with: self.url, offline: false, lat: lat, long: long, completion: { [weak self] result in
                    guard let self = self else { return }
                    self.onServerResponsed(result)
                })
            }
            self.timerValue = 0
        }
        self.timerValue += 1
    }
    
    func request(with url: String, offline: Bool, lat: Double, long: Double, completion: @escaping (String) -> ()) {
        let parameters = "{\n  \"location\": {\n    \"coords\": {\n      \"latitude\": \"\(lat)\",\n      \"longitude\": \"\(long)\"\n    }\n  },\n  \"offline\": \(offline)\",\n  \"heading\": \"32\"\n}"
        let postData = parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: url)!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("utf-8", forHTTPHeaderField: "Accept-Charset")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(String(describing: error))
                return
            }
            completion(String(data: data, encoding: .utf8)!)
        }
        task.resume()
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }
}

// Step 5: Implement the CLLocationManagerDelegate to handle the callback from CLLocationManager
extension GeoLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
            case .denied: // Setting option: Never
                print("LocationManager didChangeAuthorization denied")
            case .notDetermined: // Setting option: Ask Next Time
                print("LocationManager didChangeAuthorization notDetermined")
            case .authorizedWhenInUse: // Setting option: While Using the App
                print("LocationManager didChangeAuthorization authorizedWhenInUse")
                
                // Stpe 6: Request a one-time location information
                locationManager?.requestLocation()
            case .authorizedAlways: // Setting option: Always
                print("LocationManager didChangeAuthorization authorizedAlways")
                
                // Stpe 6: Request a one-time location information
                locationManager?.requestLocation()
            case .restricted: // Restricted by parental control
                print("LocationManager didChangeAuthorization restricted")
            default:
                print("LocationManager didChangeAuthorization")
        }
    }
    
    // Step 7: Handle the location information
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("LocationManager didUpdateLocations: numberOfLocation: \(locations.count)")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let location = locations.first {
            self.onLocationChanged(location.coordinate.latitude, location.coordinate.longitude)
        }
//        locations.forEach { (location) in
//            self.onLocationChanged(location.coordinate.latitude, location.coordinate.longitude)
//        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager didFailWithError \(error.localizedDescription)")
        if let error = error as? CLError, error.code == .denied {
            // Location updates are not authorized.
            // To prevent forever looping of `didFailWithError` callback
            locationManager?.stopMonitoringSignificantLocationChanges()
            return
        }
    }
}


