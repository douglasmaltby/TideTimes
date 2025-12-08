import Foundation
import SwiftUI

@Observable
class TideViewModel {
    private let apiClient = TideAPIClient()
    private let userDefaults = UserDefaults.standard
    
    var currentLocation: Location? {
        didSet {
            if let location = currentLocation {
                saveLocation(location)
            }
        }
    }
    var tideData: TideData?
    var isLoading = false
    var error: Error?
    
    init() {
        loadSavedLocation()
    }
    
    func loadSavedLocation() {
        if let data = userDefaults.data(forKey: "savedLocation"),
           let location = try? JSONDecoder().decode(Location.self, from: data) {
            currentLocation = location
            Task {
                await fetchTideData()
            }
        }
    }
    
    private func saveLocation(_ location: Location) {
        if let encoded = try? JSONEncoder().encode(location) {
            userDefaults.set(encoded, forKey: "savedLocation")
        }
    }
    
    @MainActor
    func fetchTideData() async {
        guard let location = currentLocation else { return }
        
        isLoading = true
        error = nil
        
        do {
            print("Fetching tide data for: \(location.name)")
            tideData = try await apiClient.fetchTideData(
                latitude: location.latitude,
                longitude: location.longitude
            )
            print("Received tide data: \(String(describing: tideData))")
        } catch {
            self.error = error
            print("Error fetching tide data: \(error)")
        }
        
        isLoading = false
    }
} 