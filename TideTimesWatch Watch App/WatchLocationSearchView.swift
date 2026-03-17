import SwiftUI
import MapKit

struct WatchLocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    
    @State private var searchText = ""
    @State private var searchResults: [Location] = []
    @State private var isSearching = false
    
    struct SuggestedLocation: Identifiable {
        var id: String { name }
        let name: String
        let location: Location?
        
        init(_ name: String, location: Location? = nil) {
            self.name = name
            self.location = location
        }
    }
    
    private let suggestedLocations: [SuggestedLocation] = [
        SuggestedLocation("Ha Long, Vietnam", location: Location(name: "Ha Long, Vietnam", latitude: 20.9506903, longitude: 107.074347, isLikelyCoastal: true)),
        SuggestedLocation("Hai Phong, Vietnam", location: Location(name: "Hai Phong, Vietnam", latitude: 20.865139, longitude: 106.683830, isLikelyCoastal: true)),
        SuggestedLocation("San Francisco Harbor"),
        SuggestedLocation("Miami Beach", location: Location(id: UUID(), name: "Miami Beach", latitude: 25.7906, longitude: -80.1300, isLikelyCoastal: true)),
        SuggestedLocation("Boston Harbor"),
        SuggestedLocation("Seattle Waterfront"),
        SuggestedLocation("San Diego Bay"),
        SuggestedLocation("Long Beach Harbor"),
        SuggestedLocation("Charleston Harbor"),
        SuggestedLocation("Virginia Beach"),
        SuggestedLocation("Portland Harbor"),
        SuggestedLocation("Galveston Bay")
    ]
    
    // Expanded coastal keywords for better matching
    private let coastalKeywords = [
        "harbor", "port", "beach", "bay", "coast", "ocean", "sea", "gulf",
        "pier", "marina", "dock", "wharf", "inlet", "cove", "shore", "point",
        "lighthouse", "jetty", "breakwater", "seawall",
        "waterfront", "seaside", "coastal", "oceanfront", "beachfront",
        "surf", "sailing", "boating"
    ]
    
    var body: some View {
        List {
            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if searchResults.isEmpty && !searchText.isEmpty {
                Text("No Coastal Locations Found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            } else if searchResults.isEmpty {
                Section("Popular") {
                    ForEach(suggestedLocations) { suggestion in
                        Button(suggestion.name) {
                            handleSelection(suggestion)
                        }
                    }
                }
            } else {
                Section("Results") {
                    ForEach(searchResults) { loc in
                        Button(loc.name) {
                            selectLocation(loc)
                        }
                    }
                }
            }
        }
        .navigationTitle("Locations")
        .searchable(text: $searchText, prompt: "Search")
        .onChange(of: searchText) { _, newValue in
            Task {
                await searchLocation(query: newValue)
            }
        }
    }
    
    private func handleSelection(_ suggestion: SuggestedLocation) {
        if let loc = suggestion.location {
            selectLocation(loc)
        } else {
            searchText = suggestion.name
            Task {
                await searchLocation(query: suggestion.name)
            }
        }
    }
    
    private func selectLocation(_ loc: Location) {
        watchConnectivity.location = loc
        dismiss()
    }
    
    private func searchLocation(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        defer { isSearching = false }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.resultTypes = [.pointOfInterest, .address]
        
        do {
            let search = MKLocalSearch(request: searchRequest)
            let response = try await search.start()
            
            let filteredResults = response.mapItems
                .map { item -> (Location, Bool, Double) in
                    let name = item.name?.lowercased() ?? ""
                    let locality = item.placemark.locality?.lowercased() ?? ""
                    let subLocality = item.placemark.subLocality?.lowercased() ?? ""
                    let searchContext = "\(name) \(locality) \(subLocality)"
                    
                    let isCoastal = coastalKeywords.contains { keyword in
                        searchContext.contains(keyword)
                    }
                    
                    let coordinate = item.placemark.coordinate
                    let distanceToCoast = abs(coordinate.longitude)
                    
                    let location = Location(
                        name: [item.name, item.placemark.locality]
                            .compactMap { $0 }
                            .joined(separator: ", "),
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        isLikelyCoastal: isCoastal
                    )
                    
                    return (location, isCoastal, distanceToCoast)
                }
                .sorted { (a, b) -> Bool in
                    if a.1 != b.1 { return a.1 && !b.1 }
                    return a.2 < b.2
                }
                .map { $0.0 }
            
            searchResults = Array(filteredResults.prefix(10))
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }
}
