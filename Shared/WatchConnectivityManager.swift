import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    @Published var location: Location?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activation completed with state: \(activationState.rawValue)")
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    // Send location to Watch
    func sendLocation(_ location: Location) {
        guard WCSession.default.activationState == .activated else { return }
        guard WCSession.default.isWatchAppInstalled else { return }
        
        do {
            let encodedData = try JSONEncoder().encode(location)
            let dictionary: [String: Any] = ["locationData": encodedData]
            try WCSession.default.updateApplicationContext(dictionary)
            print("Successfully sent location to Watch: \(location.name)")
        } catch {
            print("Error encoding or sending location context: \(error)")
        }
    }
    #endif
    
    // Receive context (running on Watch)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let locationData = applicationContext["locationData"] as? Data {
                do {
                    let location = try JSONDecoder().decode(Location.self, from: locationData)
                    self.location = location
                    print("Received location from iOS: \(location.name)")
                } catch {
                    print("Error decoding received location: \(error)")
                }
            }
        }
    }
}
