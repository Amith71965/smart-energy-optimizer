//
//  ContentView.swift
//  ios-app
//
//  Created by Amith Kumar Yadav K on 28/06/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var webSocketService: WebSocketService
    @State private var selectedTab = 0
    @State private var showingConnectionStatus = false
    
    var body: some View {
        ZStack {
            // Background gradient
            Color.backgroundGradient
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Tab 1: Dashboard
                DashboardView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Dashboard")
                    }
                    .tag(0)
                
                // Tab 2: Devices
                DevicesView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Devices")
                    }
                    .tag(1)
                
                // Tab 3: Analytics
                AnalyticsView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Analytics")
                    }
                    .tag(2)
                
                // Tab 4: AI Optimization
                OptimizationView()
                    .tabItem {
                        Image(systemName: "brain.head.profile")
                        Text("AI Optimize")
                    }
                    .tag(3)
            }
            .accentColor(.energyBlue)
            
            // Connection Status Overlay
            if showingConnectionStatus {
                ConnectionStatusOverlay()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            setupAppearance()
        }
        .overlay(alignment: .topTrailing) {
            // Connection Status Button
            Button(action: {
                withAnimation(.spring()) {
                    showingConnectionStatus.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: webSocketService.getConnectionStatusIcon())
                        .foregroundColor(webSocketService.connectionStatus.color)
                    
                    if webSocketService.isConnected {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.green)
                            .scaleEffect(0.8)
                            .opacity(0.8)
                            .animation(.easeInOut(duration: 1.0).repeatForever(), value: webSocketService.isConnected)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.glassStroke, lineWidth: 1)
                )
            }
            .padding(.top, 8)
            .padding(.trailing, 16)
        }
    }
    
    private func setupAppearance() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // Configure tab bar item appearance
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Connection Status Overlay
struct ConnectionStatusOverlay: View {
    @EnvironmentObject var webSocketService: WebSocketService
    @EnvironmentObject var apiManager: APIManager
    
    var body: some View {
        VStack(spacing: 16) {
            // WebSocket Status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wifi")
                        .foregroundColor(webSocketService.connectionStatus.color)
                    Text("Real-time Connection")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                
                HStack {
                    Circle()
                        .fill(webSocketService.connectionStatus.color)
                        .frame(width: 8, height: 8)
                    
                    Text(webSocketService.connectionStatus.description)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                    
                    Spacer()
                    
                    if webSocketService.messagesReceived > 0 {
                        Text("\(webSocketService.messagesReceived) msgs")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
            }
            
            // API Status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "server.rack")
                        .foregroundColor(apiManager.isConnected ? .green : .red)
                    Text("API Connection")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                
                HStack {
                    Circle()
                        .fill(apiManager.isConnected ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text(apiManager.isConnected ? "Connected" : "Disconnected")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                    
                    Spacer()
                    
                    if apiManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                }
            }
            
            // Reconnect Button
            if !webSocketService.isConnected {
                Button("Reconnect") {
                    webSocketService.forceReconnect()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.energyBlue)
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.glassStroke, lineWidth: 1)
        )
        .shadow(radius: 20)
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var webSocketService: WebSocketService
    @State private var animateUsage = false
    @State private var animateCost = false
    
    // Calculate real-time cost based on current usage
    private func calculateRealTimeCost() -> Double {
        let currentUsage = webSocketService.realTimeEnergyReading?.totalPower ?? 
                          apiManager.energySummary?.totalCurrentUsage ?? 0
        
        // Get accumulated cost from API or calculate based on current usage
        if let apiCost = apiManager.energySummary?.totalTodaysCost, apiCost > 0 {
            return apiCost
        }
        
        // Fallback: Calculate estimated daily cost from current usage
        let kWh = currentUsage / 1000.0  // Convert watts to kilowatts
        let estimatedDailyUsage = kWh * 24.0  // Estimate full day usage
        let ratePerKWh = 0.12  // $0.12 per kWh
        return estimatedDailyUsage * ratePerKWh
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Smart Energy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        Spacer()
                        
                        // AI Status Badge
                        AIStatusBadge()
                    }
                    
                    Text("Real-time monitoring and optimization")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.8))
                        .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Usage Ring and Cost
                HStack(spacing: 20) {
                    // Energy Usage Ring
                    EnergyUsageRing(
                        usage: webSocketService.realTimeEnergyReading?.totalPower ?? apiManager.energySummary?.totalCurrentUsage ?? 0,
                        maxUsage: 10.0,
                        animate: animateUsage
                    )
                    
                    // Cost Counter
                    CostCounter(
                        cost: calculateRealTimeCost(),
                        animate: animateCost
                    )
                }
                .padding(.horizontal)
                
                // Device Status Grid
                DeviceStatusGrid()
                    .padding(.horizontal)
                
                // Live Energy Chart
                LiveEnergyChart()
                    .padding(.horizontal)
                
                // Today's Summary
                TodaysSummaryCard()
                    .padding(.horizontal)
                
                Spacer(minLength: 100) // Tab bar spacing
            }
        }
        .refreshable {
            await apiManager.refreshAllData()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateUsage = true
            }
            withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
                animateCost = true
            }
        }
    }
}

// MARK: - AI Status Badge
struct AIStatusBadge: View {
    @EnvironmentObject var webSocketService: WebSocketService
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.energyBlue)
                .scaleEffect(webSocketService.isConnected ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(), value: webSocketService.isConnected)
            
            Text("AI Active")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.energyBlue.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .energyBlue.opacity(0.3), radius: 4)
    }
}

// MARK: - Energy Usage Ring
struct EnergyUsageRing: View {
    let usage: Double
    let maxUsage: Double
    let animate: Bool
    
    private var progress: Double {
        min(usage / maxUsage, 1.0)
    }
    
    private var usageColor: Color {
        switch progress {
        case 0..<0.3: return .energyGreen
        case 0.3..<0.7: return .energyOrange
        default: return .energyRed
        }
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 12)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animate ? progress : 0)
                .stroke(
                    AngularGradient(
                        colors: [usageColor, usageColor.opacity(0.3)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.5), value: animate)
            
            // Center content
            VStack(spacing: 4) {
                Text(usage.formattedPower)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .shadow(color: .white.opacity(0.4), radius: 2, x: 0, y: 1)
                
                Text("Current Usage")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.7))
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }
        .frame(width: 140, height: 140)
        .background(.ultraThinMaterial, in: Circle())
        .overlay(
            Circle()
                .stroke(Color.glassStroke, lineWidth: 1)
        )
        .shadow(radius: 10)
    }
}

// MARK: - Cost Counter
struct CostCounter: View {
    let cost: Double
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                AnimatedCounter(
                    value: animate ? cost : 0,
                    format: "$%.2f"
                )
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .shadow(color: .white.opacity(0.4), radius: 2, x: 0, y: 1)
                
                Text("Today's Cost")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.energyGreen)
                
                Text("12% saved")
                    .font(.caption)
                    .foregroundColor(.energyGreen)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.glassStroke, lineWidth: 1)
        )
        .shadow(radius: 10)
    }
}

// MARK: - Animated Counter
struct AnimatedCounter: View {
    let value: Double
    let format: String
    
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text(String(format: format, displayValue))
            .onChange(of: value) { _, newValue in
                withAnimation(.easeInOut(duration: 1.0)) {
                    displayValue = newValue
                }
            }
            .onAppear {
                displayValue = value
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(APIManager())
        .environmentObject(WebSocketService())
}
