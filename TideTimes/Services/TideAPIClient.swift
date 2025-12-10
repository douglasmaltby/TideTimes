import Foundation

// Add this error model
struct NOAAError: Codable {
    let error: ErrorMessage

    struct ErrorMessage: Codable {
        let message: String
    }
}

class TideAPIClient {
    private let baseURL = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"

    // Cache stations to avoid repeated network calls
    private static var cachedStations: [NOAAStation]?

    // Shared DateFormatter for API requests
    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    func fetchTideData(latitude: Double, longitude: Double) async throws -> TideData {
        // Find the nearest NOAA station
        let station = try await findNearestStation(latitude: latitude, longitude: longitude)
        print("Using station: \(station.id) - \(station.name)")

        let today = Self.apiDateFormatter.string(from: Date())
        let tomorrow = Self.apiDateFormatter.string(from: Date().addingTimeInterval(24 * 60 * 60))

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "product", value: "predictions"),
            URLQueryItem(name: "application", value: "TideTimes"),
            URLQueryItem(name: "begin_date", value: today),
            URLQueryItem(name: "end_date", value: tomorrow),
            URLQueryItem(name: "datum", value: "MLLW"),
            URLQueryItem(name: "station", value: station.id),
            URLQueryItem(name: "time_zone", value: "lst"),
            URLQueryItem(name: "units", value: "english"),
            URLQueryItem(name: "interval", value: "hilo"),  // Get only high and low tide predictions
            URLQueryItem(name: "format", value: "json"),
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        print("Requesting URL: \(url)")
        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            print("Response status code: \(httpResponse.statusCode)")
        }

        // Print raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw tide response: \(jsonString)")
        }

        // Try to decode the response
        do {
            return try JSONDecoder().decode(TideData.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw error
        }
    }

    private func findNearestStation(latitude: Double, longitude: Double) async throws -> NOAAStation
    {
        let stations: [NOAAStation]

        if let cached = Self.cachedStations {
            stations = cached
        } else {
            let components = URLComponents(
                string:
                    "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=waterlevels&units=english"
            )

            guard let url = components?.url else {
                throw URLError(.badURL)
            }

            print("Fetching stations from: \(url)")
            let (data, _) = try await URLSession.shared.data(from: url)

            let response = try JSONDecoder().decode(NOAAStations.self, from: data)
            Self.cachedStations = response.stations
            stations = response.stations
            print("Found \(stations.count) total stations")
        }

        // Find nearest station with predictions
        let nearestStations =
            stations
            .filter { station in
                // Filter for active stations with valid IDs
                !station.id.isEmpty && station.id.count <= 7  // Valid NOAA station IDs are typically 7 digits
                    && station.lat != 0 && station.lng != 0
            }
            .map { station -> (NOAAStation, Double) in
                let distance = station.distanceFrom(lat: latitude, lon: longitude)
                return (station, distance)
            }
            .filter { _, distance in
                distance < 100  // Only consider stations within 100km
            }
            .sorted { $0.1 < $1.1 }

        guard let nearestStation = nearestStations.first?.0 else {
            throw NSError(
                domain: "TideAPI",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "No tide stations found within 100km of \(latitude), \(longitude). Please try a different location closer to the coast."
                ]
            )
        }

        print(
            "Found nearest station: \(nearestStation.name) (\(nearestStation.id)) - \(String(format: "%.2f", nearestStations.first!.1))km away"
        )
        return nearestStation
    }
}

// NOAA Station Models
struct NOAAStations: Codable {
    let stations: [NOAAStation]
}

struct NOAAStation: Codable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case lat = "lat"
        case lng = "lng"
    }

    func distanceFrom(lat: Double, lon: Double) -> Double {
        let earthRadius = 6371.0  // Earth's radius in kilometers

        let lat1 = self.lat * .pi / 180
        let lat2 = lat * .pi / 180
        let deltaLat = (lat - self.lat) * .pi / 180
        let deltaLon = (lon - self.lng) * .pi / 180

        let a =
            sin(deltaLat / 2) * sin(deltaLat / 2) + cos(lat1) * cos(lat2) * sin(deltaLon / 2)
            * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }
}

// WorldTides.info API Response Models
struct WorldTidesResponse: Codable {
    let status: Int
    let callCount: Int
    let requestLat: Double
    let requestLon: Double
    let error: String?
    let heights: [WorldTidesHeight]?
    let extremes: [WorldTidesExtreme]?
}

struct WorldTidesHeight: Codable {
    let dt: Double
    let height: Double
}

struct WorldTidesExtreme: Codable {
    let dt: Double
    let height: Double
    let type: String
}
