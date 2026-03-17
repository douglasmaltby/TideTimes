import SwiftUI

struct WatchContentView: View {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @State private var tideData: TideData?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showLocationPicker = false
    
    // We recreate API client here since watchOS can also fetch its own data.
    private let apiClient = TideAPIClient()
    
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading Tides...")
                } else if let error = error {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("Error loading data")
                            .font(.caption)
                    }
                } else if let tideData = tideData {
                    WatchTideGraphView(tideData: tideData, locationName: watchConnectivity.location?.name ?? "Unknown")
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "applewatch.watchface")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        Text("Select a location")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("TideTimes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showLocationPicker = true }) {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                NavigationStack {
                    WatchLocationSearchView()
                }
            }
            .onChange(of: watchConnectivity.location) { oldLocation, newLocation in
                if let location = newLocation {
                    Task {
                        await fetchTideData(for: location)
                    }
                }
            }
            .onAppear {
                if watchConnectivity.location == nil {
                    let defaultLocation = Location(id: UUID(), name: "Miami Beach", latitude: 25.7906, longitude: -80.1300, isLikelyCoastal: true)
                    watchConnectivity.location = defaultLocation
                    // onChange might not catch the initial update if the view just appeared
                    Task {
                        await fetchTideData(for: defaultLocation)
                    }
                }
            }
        }
    }
    
    @MainActor
    private func fetchTideData(for location: Location) async {
        isLoading = true
        error = nil
        tideData = nil
        
        do {
            tideData = try await apiClient.fetchTideData(
                latitude: location.latitude,
                longitude: location.longitude
            )
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

#Preview {
    WatchContentView()
}
