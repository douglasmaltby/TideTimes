import Foundation
import CoreLocation

struct Location: Identifiable, Codable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let isLikelyCoastal: Bool
    
    init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double, isLikelyCoastal: Bool = false) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.isLikelyCoastal = isLikelyCoastal
    }
} 