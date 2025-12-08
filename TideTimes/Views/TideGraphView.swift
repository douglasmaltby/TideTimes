import SwiftUI

struct TideGraphView: View {
    let tideData: TideData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Graph section
                GraphSection(tideData: tideData)
                    .frame(height: 200)
                    .padding(.horizontal)
                
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
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 4) {
                // Graph with axes
                HStack(spacing: 4) {
                    // Y-axis labels
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(yAxisLabels, id: \.self) { label in
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(height: geometry.size.height / 4)
                        }
                    }
                    .frame(width: 30)
                    
                    // Main graph
                    ZStack {
                        // Background grid
                        VStack(spacing: geometry.size.height / 4) {
                            ForEach(0..<4) { _ in
                                Divider()
                                    .foregroundStyle(.gray.opacity(0.2))
                            }
                        }
                        
                        // Tide curve
                        Path { path in
                            let predictions = tideData.predictions
                            guard let firstPrediction = predictions.first else { return }
                            
                            let firstX = xPosition(for: firstPrediction.date, width: geometry.size.width)
                            let firstY = yPosition(for: firstPrediction.height, viewHeight: geometry.size.height)
                            path.move(to: CGPoint(x: firstX, y: firstY))
                            
                            for index in 1..<predictions.count {
                                let point = predictions[index]
                                let x = xPosition(for: point.date, width: geometry.size.width)
                                let y = yPosition(for: point.height, viewHeight: geometry.size.height)
                                
                                if index == 1 {
                                    let control = CGPoint(
                                        x: (firstX + x) / 2,
                                        y: firstY
                                    )
                                    path.addQuadCurve(
                                        to: CGPoint(x: x, y: y),
                                        control: control
                                    )
                                } else {
                                    let previous = predictions[index - 1]
                                    let prevX = xPosition(for: previous.date, width: geometry.size.width)
                                    let prevY = yPosition(for: previous.height, viewHeight: geometry.size.height)
                                    
                                    let control1 = CGPoint(
                                        x: prevX + (x - prevX) * 0.5,
                                        y: prevY
                                    )
                                    let control2 = CGPoint(
                                        x: prevX + (x - prevX) * 0.5,
                                        y: y
                                    )
                                    
                                    path.addCurve(
                                        to: CGPoint(x: x, y: y),
                                        control1: control1,
                                        control2: control2
                                    )
                                }
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)
                        
                        // Current time indicator
                        if let currentHeight = interpolateHeight(for: Date()) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .position(
                                    x: xPosition(for: Date(), width: geometry.size.width),
                                    y: yPosition(for: currentHeight, viewHeight: geometry.size.height)
                                )
                        }
                    }
                }
                
                // X-axis labels
                HStack(spacing: 0) {
                    Spacer(minLength: 30) // Align with y-axis labels
                    ForEach(xAxisLabels, id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(height: 30) // Add fixed height for two lines of text
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
    
    // Static formatters for performance
    private static let axisDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d\nHH:mm"
        return formatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    // Computed properties for axis labels
    private var yAxisLabels: [String] {
        let predictions = tideData.predictions
        let heights = predictions.map { $0.height }
        guard let minHeight = heights.min(),
              let maxHeight = heights.max() else {
            return []
        }
        
        let range = maxHeight - minHeight
        return stride(from: maxHeight, to: minHeight - (range/4), by: -(range/3))
            .map { String(format: "%.1f", $0) }
    }
    
    private var xAxisLabels: [String] {
        let predictions = tideData.predictions
        guard predictions.count >= 2,
              let firstDate = predictions.first?.date,
              let lastDate = predictions.last?.date else {
            return []
        }
        
        // Use static formatter
        let formatter = Self.axisDateFormatter
        
        let interval = lastDate.timeIntervalSince(firstDate) / 4
        return (0...4).map { i in
            let date = firstDate.addingTimeInterval(interval * Double(i))
            return formatter.string(from: date)
        }
    }
    
    private func timeString(from date: Date) -> String {
        return Self.timeFormatter.string(from: date)
    }
    
    private func xPosition(for date: Date, width: CGFloat) -> CGFloat {
        let predictions = tideData.predictions
        guard let firstDate = predictions.first?.date,
              let lastDate = predictions.last?.date else {
            return 0
        }
        
        let totalDuration = lastDate.timeIntervalSince(firstDate)
        let elapsedDuration = date.timeIntervalSince(firstDate)
        
        return width * CGFloat(elapsedDuration / totalDuration)
    }
    
    private func yPosition(for height: Double, viewHeight: CGFloat) -> CGFloat {
        let predictions = tideData.predictions
        let heights = predictions.map { $0.height }
        guard let minHeight = heights.min(),
              let maxHeight = heights.max(),
              maxHeight > minHeight else {
            return viewHeight / 2
        }
        
        let padding: CGFloat = 20
        let availableHeight = viewHeight - (padding * 2)
        let heightRange = maxHeight - minHeight
        let percentage = (height - minHeight) / heightRange
        
        return viewHeight - (padding + (availableHeight * CGFloat(percentage)))
    }
    
    private func interpolateHeight(for date: Date) -> Double? {
        let predictions = tideData.predictions.sorted { $0.date < $1.date }
        
        guard let beforePrediction = predictions.last(where: { $0.date <= date }),
              let afterPrediction = predictions.first(where: { $0.date > date }) else {
            return nil
        }
        
        let totalTime = afterPrediction.date.timeIntervalSince(beforePrediction.date)
        let elapsedTime = date.timeIntervalSince(beforePrediction.date)
        let percentage = elapsedTime / totalTime
        
        return beforePrediction.height + (afterPrediction.height - beforePrediction.height) * percentage
    }
}

#Preview {
    TideGraphView(tideData: TideData(predictions: []))
} 
