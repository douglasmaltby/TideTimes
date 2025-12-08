import Foundation

struct TideData: Codable {
    let predictions: [TidePrediction]
    
    enum CodingKeys: String, CodingKey {
        case predictions
    }
}

struct TidePrediction: Codable, Identifiable {
    // Static formatter for performance
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    let t: String  // Time in format "YYYY-MM-DD HH:MM"
    let v: String  // Water level value
    let type: String? // "H" for high tide, "L" for low tide
    let date: Date // Parsed date stored for performance
    
    var id: String { t }
    
    var height: Double {
        Double(v) ?? 0.0
    }
    
    // For JSON encoding/decoding
    enum CodingKeys: String, CodingKey {
        case t
        case v
        case type
    }
    
    init(t: String, v: String, type: String?) {
        self.t = t
        self.v = v
        self.type = type
        self.date = Self.dateFormatter.date(from: t) ?? Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let t = try container.decode(String.self, forKey: .t)
        let v = try container.decode(String.self, forKey: .v)
        
        self.t = t
        self.v = v
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.date = Self.dateFormatter.date(from: t) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(t, forKey: .t)
        try container.encode(v, forKey: .v)
        try container.encodeIfPresent(type, forKey: .type)
    }
} 