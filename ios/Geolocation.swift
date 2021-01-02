
import CoreLocation
import UserNotifications

@objc(Geolocation)
class Geolocation: NSObject {
    
    public static var  eventEmitter = RCTEventEmitter()
    let reachability = try! Reachability()
    
    override init() {
        super.init()
    }
    
    @objc(configure:)
    func configure(object: NSDictionary) {
        
        guard let obj = object as? [String: Any] else { fatalError("cant parse object") }
        let urlMap = obj["url"] as? String
        let offlineMap = obj["offline"] as? Bool
        let timeIntervalMap = obj["timeInterval"] as? Double
        let tokenMap = obj["token"] as? String
        
        guard let url = urlMap, let offline = offlineMap, let timeInterval = timeIntervalMap, let token = tokenMap else { fatalError("cant parse object") }
        
        GeoLocationManager.setup(GeoLocationManager.Config(url: url, offline: offline, timeInterval: timeInterval, token: token))
        
        httpResponseListener()
        locationStatusListener()
        networkChangeListener()
    }
    
    @objc(start:withRejecter:)
    func start(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        let isStarted = GeoLocationManager.shared.start()
        if isStarted { resolver(true) } else { rejecter("404", "Location is not available", nil) }
    }
    
    @objc(stop:withRejecter:)
    func stop(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        GeoLocationManager.shared.stop()
        resolver(true)
    }
    
    @objc(getExplicitLocation:withRejecter:)
    func getExplicitLocation(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        let location = GeoLocationManager.shared.getCurrentLocation()
        if let location = location {
            resolver(location)
        }else {
            rejecter("404", "Location is not available", nil)
        }
    }
    
    @objc(setConfig:)
    func setConfig(timeInterval: String) {
        if let interval = Double(timeInterval) {
            GeoLocationManager.setTimeInterval(timeInterval: interval)
        }
    }
}



extension Geolocation {
    private func httpResponseListener() {
        GeoLocationManager.shared.onServerResponsed = { result in
            Geolocation.eventEmitter.sendEvent(withName: "positionHttpResponse", body: result)
        }
        
        GeoLocationManager.shared.onServerFailed = { _ in
            Geolocation.eventEmitter.sendEvent(withName: "positionHttpRequestFail", body: nil)
        }
    }
    
    private func locationStatusListener() {
        GeoLocationManager.shared.self.onLocationStatusChanged = { status in
            switch status {
            case .success:
                Geolocation.eventEmitter.sendEvent(withName: "location:on:fail'", body: "failed")
            case .failed:
                Geolocation.eventEmitter.sendEvent(withName: "location:on:success'", body: "success")
            }
        }
    }
    
    private func networkChangeListener() {
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
                Geolocation.eventEmitter.sendEvent(withName: "isNetworkConnected", body: true)
            } else {
                Geolocation.eventEmitter.sendEvent(withName: "isNetworkConnected", body: true)
                print("Reachable via Cellular")
            }
        }
        reachability.whenUnreachable = { _ in
            print("Not reachable")
            Geolocation.eventEmitter.sendEvent(withName: "isNetworkConnected", body: false)
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
                Geolocation.eventEmitter.sendEvent(withName: "isNetworkConnected", body: true)
            } else {
                Geolocation.eventEmitter.sendEvent(withName: "isNetworkConnected", body: true)
                print("Reachable via Cellular")
            }
        }
        reachability.whenUnreachable = { _ in
            print("Not reachable")
            Geolocation.eventEmitter.sendEvent(withName: "isNetworkConnected", body: false)
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
}
