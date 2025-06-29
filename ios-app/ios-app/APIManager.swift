import Foundation
import Combine
import Network

class APIManager: ObservableObject {
    static let shared = APIManager()
    
    private let baseURL = "http://localhost:3000"
    private let session: URLSession
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var devices: [EnergyDevice] = []
    @Published var energySummary: EnergySummary?
    @Published var currentReading: EnergyReading?
    @Published var predictions: [Prediction] = []
    @Published var recommendations: [Recommendation] = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        
        startNetworkMonitoring()
    }
    
    deinit {
        monitor.cancel()
        updateTimer?.invalidate()
    }
    
    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Periodic Updates
    func startPeriodicUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchAllData()
            }
        }
        
        // Initial fetch
        Task {
            await fetchAllData()
        }
    }
    
    func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Main Data Fetching
    @MainActor
    private func fetchAllData() async {
        guard isConnected else { return }
        
        isLoading = true
        
        async let devicesResult = fetchDevices()
        async let summaryResult = fetchEnergySummary()
        async let currentResult = fetchCurrentReading()
        async let predictionsResult = fetchPredictions()
        async let recommendationsResult = fetchRecommendations()
        
        // Process results individually to avoid heterogeneous collection
        let devicesResultValue = await devicesResult
        let summaryResultValue = await summaryResult
        let currentResultValue = await currentResult
        let predictionsResultValue = await predictionsResult
        let recommendationsResultValue = await recommendationsResult
        
        // Update state based on successful results
        switch devicesResultValue {
        case .success(let response):
            print("✅ Devices loaded: \(response.data.count) devices")
            self.devices = response.data
        case .failure(let error):
            print("❌ Devices failed: \(error.localizedDescription)")
            self.lastError = error.localizedDescription
        }
        
        switch summaryResultValue {
        case .success(let response):
            self.energySummary = response.data
        case .failure(let error):
            self.lastError = error.localizedDescription
        }
        
        switch currentResultValue {
        case .success(let response):
            self.currentReading = response.data
        case .failure(let error):
            self.lastError = error.localizedDescription
        }
        
        switch predictionsResultValue {
        case .success(let response):
            self.predictions = response.predictions.map { predictionData in
                Prediction(
                    hour: predictionData.hour,
                    predictedUsage: predictionData.predictedUsage,
                    predictedCost: predictionData.predictedCost,
                    confidence: predictionData.confidence
                )
            }
        case .failure(let error):
            self.lastError = error.localizedDescription
        }
        
        switch recommendationsResultValue {
        case .success(let response):
            self.recommendations = response.recommendations
        case .failure(let error):
            self.lastError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - API Endpoints
    
    // Fetch all devices
    func fetchDevices() async -> Result<DevicesResponse, APIError> {
        return await performRequest(endpoint: "/api/devices", method: "GET", body: Optional<String>.none, responseType: DevicesResponse.self)
    }
    
    // Fetch energy summary
    func fetchEnergySummary() async -> Result<EnergySummaryResponse, APIError> {
        return await performRequest(endpoint: "/api/energy/summary", method: "GET", body: Optional<String>.none, responseType: EnergySummaryResponse.self)
    }
    
    // Fetch current energy reading
    func fetchCurrentReading() async -> Result<EnergyReadingResponse, APIError> {
        return await performRequest(endpoint: "/api/energy/current", method: "GET", body: Optional<String>.none, responseType: EnergyReadingResponse.self)
    }
    
    // Fetch AI predictions
    func fetchPredictions() async -> Result<PredictionResponse, APIError> {
        return await performRequest(endpoint: "/api/predictions", method: "GET", body: Optional<String>.none, responseType: PredictionResponse.self)
    }
    
    // Fetch AI recommendations
    func fetchRecommendations() async -> Result<OptimizationResponse, APIError> {
        return await performRequest(endpoint: "/api/optimization/recommendations", method: "GET", body: Optional<String>.none, responseType: OptimizationResponse.self)
    }
    
    // Fetch analytics data for charts
    func fetchAnalyticsData(timeRange: String, chartType: String) async -> Result<AnalyticsResponse, APIError> {
        let endpoint = "/api/energy/analytics?timeRange=\(timeRange)&chartType=\(chartType)"
        return await performRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none, responseType: AnalyticsResponse.self)
    }
    
    // Fetch historical energy data
    func fetchHistoricalData(hours: Int = 24) async -> Result<HistoricalDataResponse, APIError> {
        let endpoint = "/api/energy/history?hours=\(hours)"
        return await performRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none, responseType: HistoricalDataResponse.self)
    }
    
    // Control device
    func controlDevice(deviceId: String, action: DeviceControlAction) async -> Result<EnergyDevice, APIError> {
        let endpoint = "/api/devices/\(deviceId)/control"
        let body = DeviceControlRequest(action: action)
        
        return await performRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            responseType: EnergyDevice.self
        )
    }
    
    // Apply optimization recommendation
    func applyRecommendation(recommendationId: String) async -> Result<ApplyRecommendationResponse, APIError> {
        let endpoint = "/api/optimization/apply"
        let body = ApplyRecommendationRequest(recommendationId: recommendationId)
        
        return await performRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            responseType: ApplyRecommendationResponse.self
        )
    }
    
    // MARK: - Generic Request Handler
    private func performRequest<T: Codable, B: Codable>(
        endpoint: String,
        method: String = "GET",
        body: B? = nil,
        responseType: T.Type
    ) async -> Result<T, APIError> {
        
        guard let url = URL(string: baseURL + endpoint) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return .failure(.encodingError(error))
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                return .failure(.serverError(httpResponse.statusCode, errorMessage))
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let result = try decoder.decode(responseType, from: data)
            
            // State updates are handled in fetchAllData method
            
            return .success(result)
            
        } catch {
            if error is DecodingError {
                return .failure(.decodingError(error))
            } else {
                return .failure(.networkError(error))
            }
        }
    }
    
    // MARK: - State Management
    // State updates are now handled directly in fetchAllData method
    
    // MARK: - Convenience Methods
    func refreshAllData() async {
        await fetchAllData()
    }
    
    func getDevice(by id: String) -> EnergyDevice? {
        return devices.first { $0.id == id }
    }
    
    func toggleDevice(_ deviceId: String) async {
        // Simplified toggle that just sends the action
        let endpoint = "/api/devices/\(deviceId)/control"
        
        guard let url = URL(string: baseURL + endpoint) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["action": "toggle"]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, _) = try await session.data(for: request)
            
            // Refresh devices after control action
            await fetchAllData()
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
        }
    }
    
    func setDeviceTemperature(_ deviceId: String, temperature: Double) async {
        let action = DeviceControlAction.setTemperature(temperature)
        let result = await controlDevice(deviceId: deviceId, action: action)
        
        switch result {
        case .success:
            break
        case .failure(let error):
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
        }
    }
    
    func setDeviceBrightness(_ deviceId: String, brightness: Int) async {
        let action = DeviceControlAction.setBrightness(brightness)
        let result = await controlDevice(deviceId: deviceId, action: action)
        
        switch result {
        case .success:
            break
        case .failure(let error):
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
        }
    }
}

// MARK: - Request/Response Models
struct DeviceControlRequest: Codable {
    let action: DeviceControlAction
}

enum DeviceControlAction: Codable {
    case toggle(Bool)
    case setTemperature(Double)
    case setBrightness(Int)
    
    private enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "toggle":
            let value = try container.decode(Bool.self, forKey: .value)
            self = .toggle(value)
        case "setTemperature":
            let value = try container.decode(Double.self, forKey: .value)
            self = .setTemperature(value)
        case "setBrightness":
            let value = try container.decode(Int.self, forKey: .value)
            self = .setBrightness(value)
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid action type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .toggle(let value):
            try container.encode("toggle", forKey: .type)
            try container.encode(value, forKey: .value)
        case .setTemperature(let value):
            try container.encode("setTemperature", forKey: .type)
            try container.encode(value, forKey: .value)
        case .setBrightness(let value):
            try container.encode("setBrightness", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

struct ApplyRecommendationRequest: Codable {
    let recommendationId: String
}

struct ApplyRecommendationResponse: Codable {
    let success: Bool
    let message: String
    let appliedRecommendation: Recommendation?
}

// MARK: - Error Handling
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case serverError(Int, String)
    case decodingError(Error)
    case encodingError(Error)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        }
    }
}

// MARK: - API Response Wrappers
struct DevicesResponse: Codable {
    let status: String
    let data: [EnergyDevice]
    let count: Int
}

struct EnergySummaryResponse: Codable {
    let status: String
    let data: EnergySummary
}

struct EnergyReadingResponse: Codable {
    let status: String
    let data: EnergyReading
    let timestamp: String
}

struct AnalyticsResponse: Codable {
    let status: String
    let data: [AnalyticsDataPoint]
    let timeRange: String
    let chartType: String
    let generatedAt: String
}

struct HistoricalDataResponse: Codable {
    let status: String
    let data: [HistoricalEnergyReading]
    let hours: Int
    let generatedAt: String
}

struct HistoricalEnergyReading: Codable {
    let timestamp: String
    let totalPower: Double
    let devices: [DeviceReading]
}