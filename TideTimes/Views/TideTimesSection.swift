import SwiftUI

struct TideTimesSection: View {
    let predictions: [TidePrediction]
    
    var filteredPredictions: [TidePrediction] {
        predictions.filter { $0.type != nil }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("High & Low Tides")
                .font(.title2.bold())
                .padding(.horizontal)
                .padding(.top, 8)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredPredictions) { prediction in
                    let isHighTide = prediction.type?.lowercased() == "h"
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label {
                                Text(isHighTide ? "High Tide" : "Low Tide")
                                    .font(.subheadline.weight(.semibold))
                            } icon: {
                                Image(systemName: isHighTide ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundStyle(isHighTide ? .blue : .teal)
                            }
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(timeString(from: prediction.date))
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundStyle(.primary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", prediction.height))
                                    .font(.system(.title3, design: .rounded).weight(.semibold))
                                    .foregroundStyle(isHighTide ? .blue : .teal)
                                Text("ft")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.black.opacity(0.05), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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