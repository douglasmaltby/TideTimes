import SwiftUI

struct TideTimesSection: View {
    let predictions: [TidePrediction]
    
    var filteredPredictions: [TidePrediction] {
        predictions.filter { $0.type != nil }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("High & Low Tides")
                .font(.headline)
                .padding(.horizontal)
                .frame(height: 44)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                ForEach(filteredPredictions) { prediction in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tideTypeString(prediction.type))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Text(timeString(from: prediction.date))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text(String(format: "%.1f ft", prediction.height))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func tideTypeString(_ type: String?) -> String {
        switch type?.lowercased() {
        case "h":
            return "High Tide"
        case "l":
            return "Low Tide"
        default:
            return ""
        }
    }
} 