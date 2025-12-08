# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

TideTimes is an iOS app built with SwiftUI that displays tide predictions for coastal locations. The app fetches tide data from the NOAA Tides and Currents API, allowing users to search for coastal locations and visualize tide patterns through an interactive graph.

## Architecture

### MVVM Pattern
The app follows the Model-View-ViewModel (MVVM) architecture:

- **Models** (`TideTimes/Models/`): Data structures for tide predictions (`TideData`, `TidePrediction`) and locations (`Location`)
- **ViewModels** (`TideTimes/ViewModels/`): `TideViewModel` manages app state using Swift's `@Observable` macro (SwiftUI 5.0+), handles location persistence via `UserDefaults`, and coordinates with the API client
- **Views** (`TideTimes/Views/`): SwiftUI views including `TideGraphView` (renders tide curve with bezier paths), `LocationSearchView` (MapKit-based search), and supporting components
- **Services** (`TideTimes/Services/`): `TideAPIClient` handles NOAA API communication with station caching and nearest-station lookup using haversine distance calculation

### Data Flow
1. User selects location via `LocationSearchView` (MapKit search)
2. `TideViewModel` saves location to UserDefaults and calls `TideAPIClient.fetchTideData()`
3. API client finds nearest NOAA station within 100km using cached station list
4. Tide predictions are fetched and decoded into `TideData` model
5. `TideGraphView` renders interactive bezier curve graph with current time indicator
6. App restores last location on launch

### Key Technical Details
- **Date Handling**: Static `DateFormatter` instances in models/views to avoid performance overhead of repeated formatter creation
- **API Integration**: NOAA Tides and Currents API for predictions; queries 48 hours of "hilo" (high/low) data in local standard time (LST)
- **Performance**: Station list cached after first fetch; haversine formula for distance calculations; lazy view loading
- **State Management**: `@Observable` macro for view model, `@State` for view-local state

## Development Commands

### Building and Running
Since Xcode Command Line Tools are installed but not full Xcode, use Xcode IDE directly:
- Open `TideTimes.xcodeproj` in Xcode
- Build: `Cmd+B`
- Run: `Cmd+R` (requires simulator or connected device)
- Clean build folder: `Cmd+Shift+K`

### Testing
The project uses Swift Testing framework (not XCTest):
- Run all tests: `Cmd+U` in Xcode
- Test files located in `TideTimesTests/` and `TideTimesUITests/`
- Use `@Test` attribute instead of XCTest's `func test...` pattern
- Current test coverage is minimal and needs expansion

### SwiftUI Previews
- Use `Cmd+Option+P` to refresh canvas
- Most views have `#Preview` macros defined
- Previews work best with sample data

## Code Style Guidelines

### Swift & SwiftUI Standards (from .cursorrules)
- Use Swift's latest features and protocol-oriented programming
- Prefer value types (structs) over classes
- camelCase for variables/functions, PascalCase for types
- Boolean properties: use `is/has/should` prefixes (e.g., `isLikelyCoastal`)
- Prefer `let` over `var`
- Use `async/await` for concurrency (not completion handlers)
- `@Published`, `@StateObject`, `@Observable` for state management
- SF Symbols for icons
- Support dark mode and dynamic type
- Proper optional handling with Swift's type system

### API & Networking
- The app uses NOAA's public API (no API key required)
- `TideAPIClient` includes debug print statements for troubleshooting
- Station IDs are validated (max 7 digits, non-empty)
- 100km radius limit for station search
- Error messages are user-friendly with actionable guidance

### Views & UI
- Light mode only (`.preferredColorScheme(.light)` set in app root)
- Custom launch screen with 2-second display and fade transition
- GeometryReader used for responsive graph rendering
- Custom bezier curves for smooth tide visualization
- Current time indicator shown as red dot on graph

## Project Structure Notes

- Main app entry: `TideTimes/TideTimesApp.swift`
- Root view: `TideTimes/ContentView.swift`
- Extensions in `TideTimes/Extensions/` (currently only `Date+Extensions.swift`)
- Assets in `TideTimes/Assets.xcassets/`
- No external package dependencies (uses native frameworks: SwiftUI, MapKit, CoreLocation)

## Common Patterns

### Adding a New View
1. Create view file in `TideTimes/Views/`
2. Import SwiftUI
3. Add `#Preview` macro for canvas preview
4. Use existing view models or create new one if needed
5. Follow existing naming conventions (e.g., `*View.swift`, `*Section.swift`)

### Working with Dates
- Use static DateFormatter instances to avoid performance issues
- Tide API expects `yyyyMMdd` format
- Display formatters vary by context (see `TideGraphView` for examples)
- Dates stored as `Date` objects in models, formatted only for display/API

### API Response Handling
- Check for NOAA error responses with `NOAAError` model
- Print raw JSON for debugging when decoding fails
- Provide specific error messages mentioning 100km limit, coastal requirement
- Gracefully handle missing/invalid station data
