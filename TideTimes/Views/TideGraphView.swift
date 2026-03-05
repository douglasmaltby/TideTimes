import Charts
import SwiftUI

struct TideGraphView: View {
    let tideData: TideData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Graph section
                GraphSection(tideData: tideData)
                    .padding(.horizontal)
                    .padding(.top, 8) // Add some breathing room from the nav title
                
                // High/Low tide times section
                TideTimesSection(predictions: tideData.predictions)
            }
            .padding(.vertical)
        }
    }
}

// Graph component
private struct GraphSection: View {
    let tideData: TideData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Graph with axes
            Chart {
                ForEach(tideData.predictions, id: \.date) { prediction in
                    // Beautiful gradient area under the curve
                    AreaMark(
                        x: .value("Time", prediction.date),
                        y: .value("Height", prediction.height)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue.opacity(0.4), .blue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // The actual tide line
                    LineMark(
                        x: .value("Time", prediction.date),
                        y: .value("Height", prediction.height)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
                
                // Current time indicator line
                if let lastDate = tideData.predictions.last?.date, Date() < lastDate,
                   let firstDate = tideData.predictions.first?.date, Date() > firstDate {
                    RuleMark(x: .value("Now", Date()))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .foregroundStyle(.red)
                        .annotation(position: .top, alignment: .center) {
                            Text("Now")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.red))
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                    if let date = value.as(Date.self) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            VStack(spacing: 2) {
                                Text(date, format: .dateTime.hour())
                                Text(date, format: .dateTime.month().day())
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                // Let Charts automatically determine good tick increments based on the domain
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    if let height = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f", height))
                        }
                    }
                }
            }
            // Dynamically calculate the precise domain with padding
            .chartYScale(domain: {
                let heights = tideData.predictions.map { $0.height }
                let minHeight = heights.min() ?? -2.0
                let maxHeight = heights.max() ?? 10.0
                let padding = (maxHeight - minHeight) * 0.15 // 15% padding on top and bottom
                return (minHeight - padding)...(maxHeight + padding)
            }())
            .frame(height: 220)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
}

#Preview {
    TideGraphView(tideData: TideData(predictions: []))
} 
