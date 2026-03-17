import Charts
import SwiftUI

struct WatchTideGraphView: View {
    let tideData: TideData
    let locationName: String
    
    // Track the date the user has scrubbed to via the Digital Crown / Pan Gesture
    @State private var selectedDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header showing selected or current value
            HStack {
                VStack(alignment: .leading) {
                    Text(locationName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(headerDateText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(headerHeightText)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                }
                Spacer()
                
                // Show current time indicator
                if isShowingCurrentTime {
                    Text("NOW")
                        .font(.system(size: 8, weight: .heavy))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red.opacity(0.8)))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
            
            // The scrollable graph
            Chart {
                ForEach(tideData.predictions, id: \.date) { prediction in
                    // Area gradient
                    AreaMark(
                        x: .value("Time", prediction.date),
                        y: .value("Height", prediction.height)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue.opacity(0.5), .blue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // The line
                    LineMark(
                        x: .value("Time", prediction.date),
                        y: .value("Height", prediction.height)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                
                // Always draw a subtle rule mark for "Now" if within range
                if let lastDate = tideData.predictions.last?.date, Date() < lastDate,
                   let firstDate = tideData.predictions.first?.date, Date() > firstDate {
                    RuleMark(x: .value("Now", Date()))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.red.opacity(0.5))
                }
                
                // Draw a solid rule mark for the selected position if scrubbing
                if let selectedDate = selectedDate {
                    RuleMark(x: .value("Selected", selectedDate))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .foregroundStyle(.yellow)
                        .annotation(position: .top) {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 8, height: 8)
                        }
                }
            }
            // Allow selection on X-axis using Digital Crown or dragging
            .chartXSelection(value: $selectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                    if let date = value.as(Date.self) {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(.gray.opacity(0.3))
                        AxisValueLabel {
                            Text(date, format: .dateTime.hour())
                                .font(.system(size: 8))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray.opacity(0.2))
                    if let height = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.0f", height))
                                .font(.system(size: 8))
                        }
                    }
                }
            }
            .chartYScale(domain: {
                let heights = tideData.predictions.map { $0.height }
                let minHeight = heights.min() ?? -2.0
                let maxHeight = heights.max() ?? 10.0
                let padding = (maxHeight - minHeight) * 0.15
                return (minHeight - padding)...(maxHeight + padding)
            }())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Add horizontal padding inside the chart to ensure labels don't get cut off
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 3600 * 24) // Show 24 hours at a time in the scroll view
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Computed Properties for Header
    
    private var closestPrediction: TidePrediction? {
        // If scrubbing, find the nearest prediction to the selected date
        if let scrubDate = selectedDate {
            return tideData.predictions.min(by: { abs($0.date.timeIntervalSince(scrubDate)) < abs($1.date.timeIntervalSince(scrubDate)) })
        }
        
        // Default to current time if we have data for now
        let now = Date()
        return tideData.predictions.min(by: { abs($0.date.timeIntervalSince(now)) < abs($1.date.timeIntervalSince(now)) })
    }
    
    private var isShowingCurrentTime: Bool {
        // If user hasn't scrolled, or scrolled back to roughly "now"
        guard let selected = selectedDate else { return true }
        return abs(selected.timeIntervalSinceNow) < 1800 // Within 30 minutes
    }
    
    private var headerDateText: String {
        guard let prediction = closestPrediction else { return "No Data" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, h:mm a" // e.g., "Mon, 2:00 PM"
        return formatter.string(from: prediction.date)
    }
    
    private var headerHeightText: String {
        guard let prediction = closestPrediction else { return "-- ft" }
        return String(format: "%.1f ft", prediction.height)
    }
}
