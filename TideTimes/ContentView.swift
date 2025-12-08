//
//  ContentView.swift
//  TideTimes
//
//  Created by Douglas Maltby on 1/19/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = TideViewModel()
    @State private var showingLocationSearch = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let tideData = viewModel.tideData {
                    TideGraphView(tideData: tideData)
                } else if viewModel.isLoading {
                    ProgressView("Loading tide data...")
                        .controlSize(.large)
                } else if let error = viewModel.error {
                    ContentUnavailableView {
                        Label("Error Loading Data", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
                    } actions: {
                        Button("Try Again") {
                            Task {
                                await viewModel.fetchTideData()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ContentUnavailableView {
                        Label("Select a Location", systemImage: "mappin.and.ellipse")
                    } description: {
                        Text("Choose a location to view tide information")
                    }
                }
            }
            .navigationTitle(viewModel.currentLocation?.name ?? "Tide Times")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingLocationSearch = true
                    } label: {
                        Label("Change Location", systemImage: "location.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
