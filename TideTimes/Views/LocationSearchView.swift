import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [Location] = []
    @State private var isSearching = false
    let viewModel: TideViewModel
    
    // Popular coastal locations to show by default
    private let suggestedLocations = [
        "San Francisco Harbor",
        "Miami Beach",
        "Boston Harbor",
        "Seattle Waterfront",
        "San Diego Bay",
        "Long Beach Harbor",
        "Charleston Harbor",
        "Virginia Beach",
        "Portland Harbor",
        "Galveston Bay",
        "Ha Long"
    ]
    
    // Expanded coastal keywords for better matching
    private let coastalKeywords = [
        // Major water bodies
        "harbor", "port", "beach", "bay", "coast", "ocean", "sea", "gulf",
        // Coastal features
        "pier", "marina", "dock", "wharf", "inlet", "cove", "shore", "point",
        // Coastal structures
        "lighthouse", "jetty", "breakwater", "seawall",
        // Coastal areas
        "waterfront", "seaside", "coastal", "oceanfront", "beachfront",
        // Water activities
        "surf", "sailing", "boating"
    ]
    
    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    ProgressView("Searching locations...")
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView {
                        Label("No Coastal Locations Found", systemImage: "mappin.slash")
                    } description: {
                        Text("Try searching for a harbor, beach, or coastal city")
                    }
                } else if searchResults.isEmpty {
                    Section("Suggested Locations") {
                        ForEach(suggestedLocations, id: \.self) { suggestion in
                            Button {
                                searchText = suggestion
                                Task {
                                    await searchLocation(query: suggestion)
                                }
                            } label: {
                                Label(suggestion, systemImage: "mappin.circle.fill")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                } else {
                    Section("Search Results") {
                        ForEach(searchResults) { location in
                            Button {
                                viewModel.currentLocation = location
                                Task {
                                    await viewModel.fetchTideData()
                                }
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(location.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        if location.isLikelyCoastal {
                                            Image(systemName: "water.waves")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    
                                    Text(location.coordinateString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: "Search for a coastal location"
            )
            .onChange(of: searchText) { _, newValue in
                Task {
                    await searchLocation(query: newValue)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
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
                    let searchText = "\(name) \(locality) \(subLocality)"
                    
                    // Check if location name or city contains coastal keywords
                    let isCoastal = coastalKeywords.contains { keyword in
                        searchText.contains(keyword)
                    }
                    
                    // Calculate rough distance to coast using longitude
                    // This is a simplified measure - could be improved
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
                    if a.1 != b.1 { // First sort by isCoastal
                        return a.1 && !b.1
                    }
                    return a.2 < b.2 // Then sort by distance to coast
                }
                .map { $0.0 }
            
            // Take top results, prioritizing coastal locations
            searchResults = Array(filteredResults.prefix(10))
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }
}

// Add this extension to Location
extension Location {
    var coordinateString: String {
        String(format: "%.4f°%@, %.4f°%@",
               abs(latitude), latitude >= 0 ? "N" : "S",
               abs(longitude), longitude >= 0 ? "E" : "W")
    }
}

#Preview {
    LocationSearchView(viewModel: TideViewModel())
} 