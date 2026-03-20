import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [Location] = []
    @State private var isSearching = false
    let viewModel: TideViewModel
    
    struct SuggestedLocation: Identifiable {
        var id: String { name }
        let name: String
        let location: Location?
        
        init(_ name: String, location: Location? = nil) {
            self.name = name
            self.location = location
        }
    }
    
    // Popular coastal locations to show by default
    private let suggestedLocations: [SuggestedLocation] = [
        SuggestedLocation("Ha Long, Vietnam", location: Location(name: "Ha Long, Vietnam", latitude: 20.9506903, longitude: 107.074347, isLikelyCoastal: true)),
        SuggestedLocation("Hai Phong, Vietnam", location: Location(name: "Hai Phong, Vietnam", latitude: 20.865139, longitude: 106.683830, isLikelyCoastal: true)),
        SuggestedLocation("San Francisco Harbor, CA"),
        SuggestedLocation("Miami Beach, FL"),
        SuggestedLocation("Boston Harbor, MA"),
        SuggestedLocation("Seattle Waterfront, WA"),
        SuggestedLocation("San Diego Bay, CA"),
        SuggestedLocation("Long Beach Harbor, CA"),
        SuggestedLocation("Charleston Harbor, SC"),
        SuggestedLocation("Virginia Beach, VA"),
        SuggestedLocation("Portland Harbor, OR"),
        SuggestedLocation("Galveston Bay, TX")
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
                    HStack {
                        Spacer()
                        ProgressView("Searching locations...")
                            .padding()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView {
                        Label("No Coastal Locations Found", systemImage: "mappin.slash")
                    } description: {
                        Text("Try searching for a harbor, beach, or coastal city")
                    }
                    .listRowBackground(Color.clear)
                } else if searchResults.isEmpty {
                    Section {
                        ForEach(suggestedLocations, id: \.name) { suggestion in
                            Button {
                                if let customLocation = suggestion.location {
                                    // Use our exact coordinates to guarantee the search target
                                    viewModel.currentLocation = customLocation
                                    Task {
                                        await viewModel.fetchTideData()
                                    }
                                    dismiss()
                                } else {
                                    // Normal search fallback
                                    searchText = suggestion.name
                                    Task {
                                        await searchLocation(query: suggestion.name)
                                    }
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.gray)
                                        .frame(width: 32)
                                    Text(suggestion.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "magnifyingglass")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("Popular Locations")
                            .font(.headline)
                            .textCase(nil)
                            .foregroundStyle(.primary)
                    }
                } else {
                    Section {
                        ForEach(searchResults) { location in
                            Button {
                                viewModel.currentLocation = location
                                Task {
                                    await viewModel.fetchTideData()
                                }
                                dismiss()
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: location.isLikelyCoastal ? "water.waves" : "mappin.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(location.isLikelyCoastal ? .blue : .gray)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(location.name)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                        
                                        Text(location.coordinateString)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    } header: {
                        Text("Search Results")
                            .font(.headline)
                            .textCase(nil)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
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
