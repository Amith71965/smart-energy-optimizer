import SwiftUI

// MARK: - Device Status Grid
struct DeviceStatusGrid: View {
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var webSocketService: WebSocketService
    
    var devices: [EnergyDevice] {
        webSocketService.realTimeDeviceUpdates.isEmpty ? 
        apiManager.devices : webSocketService.realTimeDeviceUpdates
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Device Status")
                    .font(.headline)
                    .foregroundColor(.black)
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Spacer()
                
                Text("\(devices.filter { $0.isOn }.count)/\(devices.count) Active")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(devices) { device in
                    DeviceStatusCard(device: device)
                }
            }
        }
    }
}

// MARK: - Device Status Card
struct DeviceStatusCard: View {
    let device: EnergyDevice
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: device.type.icon)
                    .font(.title2)
                    .foregroundColor(device.type.color)
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(device.isOn ? .energyGreen : .gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(device.isOn ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(), value: device.isOn)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .shadow(color: .white.opacity(0.4), radius: 1, x: 0, y: 1)
                
                Text(device.location)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.currentPower.formattedPower)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(device.isOn ? device.type.color : .gray)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                    Text("Power")
                        .font(.caption2)
                        .foregroundColor(.black.opacity(0.5))
                }
                
                Spacer()
                
                // Power meter
                PowerMeter(power: device.currentPower, maxPower: 3.0, color: device.type.color)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(device.isOn ? device.type.color.opacity(0.3) : Color.glassStroke, lineWidth: 1)
        )
        .shadow(color: device.isOn ? device.type.color.opacity(0.2) : .clear, radius: 8)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3)) {
                    isPressed = false
                }
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Power Meter
struct PowerMeter: View {
    let power: Double
    let maxPower: Double
    let color: Color
    
    private var progress: Double {
        min(power / maxPower, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 4)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 40 * progress, height: 4)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .foregroundColor(.black.opacity(0.6))
        }
    }
}

// MARK: - Live Energy Chart
struct LiveEnergyChart: View {
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var webSocketService: WebSocketService
    @State private var chartData: [ChartDataPoint] = []
    @State private var showingChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live Energy Flow")
                    .font(.headline)
                    .foregroundColor(.black)
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(.energyGreen)
                        .frame(width: 8, height: 8)
                        .scaleEffect(webSocketService.isConnected ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(), value: webSocketService.isConnected)
                    
                    Text("Live")
                        .font(.caption)
                        .foregroundColor(.energyGreen)
                        .fontWeight(.medium)
                }
            }
            
            if showingChart && !chartData.isEmpty {
                // Chart placeholder - Charts framework integration coming soon
                VStack(spacing: 8) {
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(chartData.suffix(10), id: \.id) { dataPoint in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(LinearGradient(
                                        colors: [.energyBlue, .energyGreen],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    ))
                                    .frame(width: 18, height: max(CGFloat(dataPoint.value * 15), 12)) // Wider bars, even taller scaling
                                    .animation(.easeInOut(duration: 0.3), value: dataPoint.value)
                            }
                        }
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.05))
                    )
                    
                    Text("Live Energy Chart")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.6))
                }
                .frame(height: 140)
                .animation(.easeInOut(duration: 1.0), value: chartData.count)
            } else {
                // Loading state
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(.energyBlue)
                    
                    Text("Loading live data...")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.6))
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.glassStroke, lineWidth: 1)
        )
        .shadow(radius: 10)
        .onAppear {
            generateMockChartData()
            withAnimation(.easeInOut(duration: 0.8)) {
                showingChart = true
            }
        }
        .onChange(of: webSocketService.realTimeEnergyReading) { _, newReading in
            if let reading = newReading {
                updateChartData(with: reading)
            }
        }
    }
    
    private func generateMockChartData() {
        let now = Date()
        var baseValue = 3.0
        
        chartData = (0..<10).map { index in
            // Create smoother transitions between data points
            let variation = Double.random(in: -0.5...0.5)
            baseValue = max(1.0, min(8.0, baseValue + variation))
            
            return ChartDataPoint(
                timestamp: now.addingTimeInterval(TimeInterval(-index * 30)),
                value: baseValue
            )
        }.reversed()
    }
    
    private func updateChartData(with reading: EnergyReading) {
        // Normalize the power reading to fit chart scale (0-8 range)
        let normalizedValue = min(reading.totalPower / 1000.0, 8.0) // Convert W to kW and cap at 8
        
        let newDataPoint = ChartDataPoint(
            timestamp: Date(),
            value: normalizedValue
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            chartData.append(newDataPoint)
            
            // Keep only last 10 points for display
            if chartData.count > 10 {
                chartData.removeFirst()
            }
        }
    }
}

// MARK: - Today's Summary Card
struct TodaysSummaryCard: View {
    @EnvironmentObject var apiManager: APIManager
    
    var summary: EnergySummary? {
        apiManager.energySummary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Summary")
                    .font(.headline)
                    .foregroundColor(.black)
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Spacer()
                
                if let summary = summary {
                    EfficiencyBadge(score: summary.efficiencyScore)
                }
            }
            
            if let summary = summary {
                HStack(spacing: 20) {
                    SummaryMetric(
                        title: "Total Usage",
                        value: summary.totalTodaysUsage.formattedPower,
                        icon: "bolt.fill",
                        color: .energyBlue
                    )
                    
                    SummaryMetric(
                        title: "Total Cost",
                        value: summary.totalTodaysCost.formattedCost,
                        icon: "dollarsign.circle.fill",
                        color: .energyOrange
                    )
                    
                    SummaryMetric(
                        title: "Active Devices",
                        value: "\(summary.activeDevices)/\(summary.totalDevices)",
                        icon: "house.fill",
                        color: .energyGreen
                    )
                }
                
                // Savings insight
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text("You've saved 12% compared to yesterday!")
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .fontWeight(.medium)
                }
                .padding(12)
                .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.yellow.opacity(0.3), lineWidth: 1)
                )
            } else {
                // Loading state
                HStack {
                    ProgressView()
                        .tint(.energyBlue)
                    
                    Text("Loading summary...")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.glassStroke, lineWidth: 1)
        )
        .shadow(radius: 10)
    }
}

// MARK: - Summary Metric
struct SummaryMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.7))
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Efficiency Badge
struct EfficiencyBadge: View {
    let score: Int
    
    private var badgeColor: Color {
        switch score {
        case 90...100: return .energyGreen
        case 70..<90: return .energyOrange
        default: return .energyRed
        }
    }
    
    private var badgeText: String {
        switch score {
        case 90...100: return "Excellent"
        case 70..<90: return "Good"
        default: return "Needs Improvement"
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundColor(badgeColor)
                .font(.caption)
            
            Text("\(score)% \(badgeText)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.1), in: Capsule())
        .overlay(
            Capsule()
                .stroke(badgeColor.opacity(0.3), lineWidth: 1)
        )
    }
} 