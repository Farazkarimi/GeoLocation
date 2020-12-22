
import CoreLocation
import UserNotifications

@objc(Geolocation)
class Geolocation: NSObject {
    var locationManager = CLLocationManager()
    @objc var emitter = RCTEventEmitter()
    
    override init() {
        super.init()
    }
    
    @objc(configure:withOffline:withTimeInterval:withToken:)
    func configure(url: String, offline: Bool, timeInterval: Double, token: String) {
        GeoLocationManager.setup(.init(url: url, offline: offline, timeInterval: timeInterval, token: token))
        GeoLocationManager.shared.onServerResponsed = { [weak self] result in
            guard let self = self else { return }
            self.emitter.sendEvent(withName: "onLocationChanged", body: result)
        }
    }
    
    @objc(start:)
    func start(resolver: RCTPromiseResolveBlock) {
        let isStarted = GeoLocationManager.shared.start()
        resolver(isStarted)
    }
    
    @objc(stop:)
    func stop(resolver: RCTPromiseResolveBlock) {
        GeoLocationManager.shared.stop()
        resolver(true)
    }
    
    @objc(getExplicitLocation:)
    func getExplicitLocation(resolver: RCTPromiseResolveBlock) {
       resolver(GeoLocationManager.shared.getCurrentLocation())
    }
    
    @objc(setConfig:)
    func setConfig(timeInterval: Double) {
        GeoLocationManager.setTimeInterval(timeInterval: timeInterval)
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
        var timeInterval: TimeInterval
        let token: String
    }
    
    private static var config:Config?
    
    class func setup(_ config:Config){
        GeoLocationManager.config = config
    }
    
    class func setTimeInterval(timeInterval: Double) {
        GeoLocationManager.config?.timeInterval = timeInterval
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
    }
    
    func start() -> Bool {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        switch CLLocationManager.authorizationStatus() {
        
        case .notDetermined, .restricted, .denied:
            return false
        case .authorizedWhenInUse, .authorizedAlways,.authorized:
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
            return true
        default:
            return false
        }
    }
    
    func stop() {
        locationManager?.delegate = nil
        locationManager = nil
    }
    
    func getCurrentLocation() -> String? {
        var currentLoc: CLLocation!
        if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
        CLLocationManager.authorizationStatus() == .authorizedAlways) {
           currentLoc = locationManager?.location
           print(currentLoc.coordinate.latitude)
           print(currentLoc.coordinate.longitude)
           
           let jsonObject: [String: Any] = [
               "lat": currentLoc.coordinate.longitude,
               "lng": currentLoc.coordinate.latitude,
           ]
           
           do {
               let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions()) as NSData
               let jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
            return jsonString
         
           } catch _ {
               print ("JSON Failure")
            return nil
           }
        }
        return nil
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
