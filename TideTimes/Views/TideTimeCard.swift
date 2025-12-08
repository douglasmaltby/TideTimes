import SwiftUI

struct TideTimeCard: View {
    let prediction: TidePrediction
    
    init(prediction: TidePrediction) {
        self.prediction = prediction
    }
    
    private var isHighTide: Bool {
        prediction.type == "H"
    }
    
    private var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isHighTide ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.title2)
                .foregroundStyle(isHighTide ? .blue : .indigo)
            
            Text(isHighTide ? "High Tide" : "Low Tide")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(timeFormatter.string(from: prediction.date))
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(String(format: "%.1f ft", prediction.height))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isHighTide ? "High" : "Low") tide at \(timeFormatter.string(from: prediction.date)), \(String(format: "%.1f", prediction.height)) feet")
    }
} 