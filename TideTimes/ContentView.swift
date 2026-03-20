//
//  ContentView.swift
//  TideTimes
//
//  Created by Douglas Maltby on 1/19/25.
//  Reverted to code before Gemma 4 experiment and misspellings on 4/2/26

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
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.blue)
                        Text("Fetching tide heights...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.animation(.easeInOut))
                } else if let error = viewModel.error {
                    ContentUnavailableView {
                        Label("Cannot Load Tides", systemImage: "wifi.slash")
                            .symbolEffect(.pulse)
                    } description: {
                        Text(error.localizedDescription)
                            .font(.callout)
                    } actions: {
                        Button {
                            Task {
                                await viewModel.fetchTideData()
                            }
                        } label: {
                            Text("Try Again")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.regular)
                    }
                } else {
                    ContentUnavailableView {
                        Label {
                            Text("Select a Location")
                                .font(.title3.bold())
                        } icon: {
                            Image(systemName: "water.waves")
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    .linearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .padding(.bottom, 8)
                        }
                    } description: {
                        Text("Choose a coastal location to view current tide predictions and graphs.")
                            .foregroundStyle(.secondary)
                    } actions: {
                        Button {
                            showingLocationSearch = true
                        } label: {
                            Text("Search Locations")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
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
