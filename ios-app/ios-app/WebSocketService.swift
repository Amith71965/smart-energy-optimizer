import Foundation
import Combine
import Network
import SwiftUI

class WebSocketService: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    private let webSocketURL = URL(string: "ws://localhost:3000")!
    
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastMessage: String?
    @Published var messagesReceived: Int = 0
    
    // Real-time data publishers
    @Published var realTimeEnergyReading: EnergyReading?
    @Published var realTimeDeviceUpdates: [EnergyDevice] = []
    @Published var realTimeSystemHealth: SystemHealth?
    @Published var realTimePredictions: [Prediction] = []
    @Published var realTimeRecommendations: [Recommendation] = []
    
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectDelay: TimeInterval = 2.0
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case failed
        
        var description: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .reconnecting: return "Reconnecting..."
            case .failed: return "Connection Failed"
            }
        }
        
        var color: Color {
            switch self {
            case .disconnected: return .gray
            case .connecting: return .orange
            case .connected: return .green
            case .reconnecting: return .orange
            case .failed: return .red
            }
        }
    }
    
    init() {
        setupNetworkMonitoring()
    }
    
    deinit {
        disconnect()
        reconnectTimer?.invalidate()
        heartbeatTimer?.invalidate()
    }
    
    // MARK: - Connection Management
    func connect() {
        guard webSocketTask == nil else { return }
        
        connectionStatus = .connecting
        
        webSocketTask = urlSession.webSocketTask(with: webSocketURL)
        webSocketTask?.resume()
        
        // Start listening for messages
        receiveMessage()
        
        // Start heartbeat
        startHeartbeat()
        
        // Monitor connection state
        monitorConnection()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = .disconnected
        }
    }
    
    private func reconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            DispatchQueue.main.async {
                self.connectionStatus = .failed
            }
            return
        }
        
        reconnectAttempts += 1
        
        DispatchQueue.main.async {
            self.connectionStatus = .reconnecting
        }
        
        disconnect()
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectDelay * Double(reconnectAttempts), repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    // MARK: - Message Handling
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue listening
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.handleConnectionError()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseMessage(text)
            }
        @unknown default:
            print("Unknown message type received")
        }
        
        DispatchQueue.main.async {
            self.messagesReceived += 1
            self.lastMessage = Date().formatted(date: .omitted, time: .standard)
        }
    }
    
    private func parseMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Try to decode as WebSocketMessage first
            if let webSocketMessage = try? decoder.decode(WebSocketMessage.self, from: data) {
                handleWebSocketMessage(webSocketMessage)
                return
            }
            
            // Try to decode as direct data types
            if let energyReading = try? decoder.decode(EnergyReading.self, from: data) {
                DispatchQueue.main.async {
                    self.realTimeEnergyReading = energyReading
                }
                return
            }
            
            if let devices = try? decoder.decode([EnergyDevice].self, from: data) {
                DispatchQueue.main.async {
                    self.realTimeDeviceUpdates = devices
                }
                return
            }
            
            if let systemHealth = try? decoder.decode(SystemHealth.self, from: data) {
                DispatchQueue.main.async {
                    self.realTimeSystemHealth = systemHealth
                }
                return
            }
            
            print("Received unrecognized message format: \(text)")
            
        } catch {
            print("Failed to parse WebSocket message: \(error)")
            print("Raw message: \(text)")
        }
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        DispatchQueue.main.async {
            switch message.data {
            case .energyReading(let reading):
                self.realTimeEnergyReading = reading
                
            case .deviceStatus(let devices):
                self.realTimeDeviceUpdates = devices
                
            case .systemHealth(let health):
                self.realTimeSystemHealth = health
                
            case .predictions(let predictions):
                self.realTimePredictions = predictions
                
            case .recommendations(let recommendations):
                self.realTimeRecommendations = recommendations
            }
        }
    }
    
    // MARK: - Connection Monitoring
    private func monitorConnection() {
        // Check connection status periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, let task = self.webSocketTask else {
                timer.invalidate()
                return
            }
            
            switch task.state {
            case .running:
                if !self.isConnected {
                    DispatchQueue.main.async {
                        self.isConnected = true
                        self.connectionStatus = .connected
                        self.reconnectAttempts = 0
                    }
                }
            case .suspended, .canceling, .completed:
                if self.isConnected {
                    DispatchQueue.main.async {
                        self.isConnected = false
                        self.connectionStatus = .disconnected
                    }
                    self.handleConnectionError()
                }
                timer.invalidate()
            @unknown default:
                break
            }
        }
    }
    
    private func handleConnectionError() {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        
        // Attempt to reconnect
        reconnect()
    }
    
    // MARK: - Heartbeat
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        let heartbeat = ["type": "heartbeat", "timestamp": ISO8601DateFormatter().string(from: Date())]
        
        guard let data = try? JSONSerialization.data(withJSONObject: heartbeat),
              let message = String(data: data, encoding: .utf8) else {
            return
        }
        
        sendMessage(message)
    }
    
    // MARK: - Message Sending
    func sendMessage(_ message: String) {
        let webSocketMessage = URLSessionWebSocketTask.Message.string(message)
        
        webSocketTask?.send(webSocketMessage) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
    
    func sendDeviceControl(deviceId: String, action: String, value: Any? = nil) {
        var message: [String: Any] = [
            "type": "device_control",
            "deviceId": deviceId,
            "action": action,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let value = value {
            message["value"] = value
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let messageString = String(data: data, encoding: .utf8) else {
            return
        }
        
        sendMessage(messageString)
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied && !(self?.isConnected ?? false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.connect()
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    // MARK: - Utility Methods
    func getConnectionStatusIcon() -> String {
        switch connectionStatus {
        case .disconnected: return "wifi.slash"
        case .connecting: return "wifi.exclamationmark"
        case .connected: return "wifi"
        case .reconnecting: return "wifi.exclamationmark"
        case .failed: return "wifi.slash"
        }
    }
    
    func forceReconnect() {
        reconnectAttempts = 0
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.connect()
        }
    }
    
    // MARK: - Data Access
    func getLatestEnergyReading() -> EnergyReading? {
        return realTimeEnergyReading
    }
    
    func getLatestDeviceUpdates() -> [EnergyDevice] {
        return realTimeDeviceUpdates
    }
    
    func getSystemHealth() -> SystemHealth? {
        return realTimeSystemHealth
    }
    
    func getLatestPredictions() -> [Prediction] {
        return realTimePredictions
    }
    
    func getLatestRecommendations() -> [Recommendation] {
        return realTimeRecommendations
    }
} 