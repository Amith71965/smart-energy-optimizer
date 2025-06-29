import SwiftUI
import Foundation

// MARK: - Device Models
struct EnergyDevice: Identifiable, Codable {
    let id: String
    let name: String
    let type: DeviceType
    let location: String
    var isOn: Bool
    var currentPower: Double
    var todaysUsage: Double
    var todaysCost: Double
    var targetTemp: Double?
    var brightness: Int?
    
    enum DeviceType: String, CaseIterable, Codable {
        case hvac = "hvac"
        case waterHeater = "water_heater"
        case lighting = "lighting"
        case appliance = "appliance"
        
        var icon: String {
            switch self {
            case .hvac: return "thermometer"
            case .waterHeater: return "drop.fill"
            case .lighting: return "lightbulb.fill"
            case .appliance: return "washer.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .hvac: return .blue
            case .waterHeater: return .orange
            case .lighting: return .yellow
            case .appliance: return .purple
            }
        }
        
        var gradient: LinearGradient {
            switch self {
            case .hvac:
                return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .waterHeater:
                return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .lighting:
                return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .appliance:
                return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
}

// MARK: - Energy Data Models
struct EnergyReading: Identifiable, Codable, Equatable {
    let id = UUID()
    let timestamp: String
    let totalPower: Double
    let devices: [DeviceReading]
    
    private enum CodingKeys: String, CodingKey {
        case timestamp, totalPower, devices
    }
    
    static func == (lhs: EnergyReading, rhs: EnergyReading) -> Bool {
        lhs.id == rhs.id && lhs.timestamp == rhs.timestamp && lhs.totalPower == rhs.totalPower
    }
}

struct DeviceReading: Codable {
    let id: String
    let power: Double
    let isOn: Bool
}

struct EnergySummary: Codable {
    let totalCurrentUsage: Double
    let totalTodaysCost: Double
    let totalTodaysUsage: Double
    let activeDevices: Int
    let totalDevices: Int
    let efficiencyScore: Int
    let lastUpdated: String
}

// MARK: - Prediction Models
struct Prediction: Identifiable, Codable {
    let id = UUID()
    let hour: Int
    let predictedUsage: Double
    let predictedCost: Double
    let confidence: Double
    
    private enum CodingKeys: String, CodingKey {
        case hour, predictedUsage, predictedCost, confidence
    }
}

struct PredictionResponse: Codable {
    let predictions: [PredictionData]
    let summary: PredictionSummary
}

struct PredictionData: Codable {
    let hour: Int
    let predictedUsage: Double
    let predictedCost: Double
    let confidence: Double
}

struct PredictionSummary: Codable {
    let totalPredictedUsage: Double
    let totalPredictedCost: Double
    let averageConfidence: Double
    let peakHour: Int
    let lowestHour: Int
}

// MARK: - Optimization Models
struct Recommendation: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let potentialSavings: Double
    let deviceId: String
    let action: String
    let priority: Priority
    
    enum Priority: String, CaseIterable, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "checkmark.circle"
            case .medium: return "exclamationmark.triangle"
            case .high: return "exclamationmark.octagon"
            }
        }
        
        var gradient: LinearGradient {
            switch self {
            case .low:
                return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .medium:
                return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .high:
                return LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
}

struct OptimizationResponse: Codable {
    let recommendations: [Recommendation]
    let summary: OptimizationSummary
}

struct OptimizationSummary: Codable {
    let totalPotentialSavings: Double
    let highPriorityCount: Int
    let mediumPriorityCount: Int
    let lowPriorityCount: Int
}

// MARK: - Chart Data Models
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
    let category: String?
    
    init(timestamp: Date, value: Double, category: String? = nil) {
        self.timestamp = timestamp
        self.value = value
        self.category = category
    }
}

struct UsageChartData {
    let current: [ChartDataPoint]
    let predicted: [ChartDataPoint]
    let historical: [ChartDataPoint]
}

// MARK: - WebSocket Models
struct WebSocketMessage: Codable {
    let type: MessageType
    let data: Data
    
    enum MessageType: String, Codable {
        case energyUpdate = "energy_update"
        case deviceUpdate = "device_update"
        case systemStatus = "system_status"
        case prediction = "prediction"
        case recommendation = "recommendation"
    }
    
    enum Data: Codable {
        case energyReading(EnergyReading)
        case deviceStatus([EnergyDevice])
        case systemHealth(SystemHealth)
        case predictions([Prediction])
        case recommendations([Recommendation])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let energyReading = try? container.decode(EnergyReading.self) {
                self = .energyReading(energyReading)
            } else if let devices = try? container.decode([EnergyDevice].self) {
                self = .deviceStatus(devices)
            } else if let health = try? container.decode(SystemHealth.self) {
                self = .systemHealth(health)
            } else if let predictions = try? container.decode([Prediction].self) {
                self = .predictions(predictions)
            } else if let recommendations = try? container.decode([Recommendation].self) {
                self = .recommendations(recommendations)
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid data type"))
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .energyReading(let reading):
                try container.encode(reading)
            case .deviceStatus(let devices):
                try container.encode(devices)
            case .systemHealth(let health):
                try container.encode(health)
            case .predictions(let predictions):
                try container.encode(predictions)
            case .recommendations(let recommendations):
                try container.encode(recommendations)
            }
        }
    }
}

struct SystemHealth: Codable {
    let status: String
    let uptime: Int
    let activeConnections: Int
    let lastUpdate: String
}

// MARK: - UI State Models
@Observable
class AppState {
    var selectedTab: Int = 0
    var isLoading: Bool = false
    var errorMessage: String?
    var showingError: Bool = false
    var lastUpdate: Date = Date()
    
    func setError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
}

// MARK: - Animation Models
struct AnimationState {
    var scale: Double = 1.0
    var rotation: Double = 0.0
    var opacity: Double = 1.0
    var offset: CGSize = .zero
}

// MARK: - Utility Extensions
extension Double {
    var formattedPower: String {
        String(format: "%.1f kW", self)
    }
    
    var formattedCost: String {
        String(format: "$%.2f", self)
    }
    
    var formattedPercentage: String {
        String(format: "%.0f%%", self * 100)
    }
}

extension Date {
    var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: self)
    }
}

// MARK: - Color Extensions
extension Color {
    static let energyGreen = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let energyOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let energyBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let energyRed = Color(red: 1.0, green: 0.23, blue: 0.19)
    
    static let glassMaterial = Color.white.opacity(0.9)
    static let glassStroke = Color.black.opacity(0.1)
    
    static var energyGradient: LinearGradient {
        LinearGradient(
            colors: [.energyGreen, .yellow, .energyOrange, .energyRed],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.95), Color.energyBlue.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - ShapeStyle Extensions
extension ShapeStyle where Self == Color {
    static var energyBlue: Color { Color.energyBlue }
    static var energyGreen: Color { Color.energyGreen }
    static var energyOrange: Color { Color.energyOrange }
    static var energyRed: Color { Color.energyRed }
} 