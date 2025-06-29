import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var webSocketService: WebSocketService
    @State private var selectedTimeRange: TimeRange = .day
    @State private var selectedChartType: ChartType = .usage
    @State private var showingExportSheet = false
    @State private var chartData: [SimpleDataPoint] = []
    @State private var isLoading = false
    
    enum TimeRange: String, CaseIterable {
        case day = "24H"
        case week = "7D"
        case month = "30D"
        
        var title: String {
            switch self {
            case .day: return "Last 24 Hours"
            case .week: return "Last 7 Days"
            case .month: return "Last 30 Days"
            }
        }
        
        var dataPoints: Int {
            switch self {
            case .day: return 24
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    enum ChartType: String, CaseIterable {
        case usage = "Usage"
        case cost = "Cost"
        case efficiency = "Efficiency"
        
        var color: Color {
            switch self {
            case .usage: return .blue
            case .cost: return .orange
            case .efficiency: return .green
            }
        }
        
        var unit: String {
            switch self {
            case .usage: return "kW"
            case .cost: return "$"
            case .efficiency: return "%"
            }
        }
        
        var icon: String {
            switch self {
            case .usage: return "bolt.fill"
            case .cost: return "dollarsign.circle.fill"
            case .efficiency: return "leaf.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.95), Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Analytics")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingExportSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.black)
                                        .font(.title3)
                                }
                            }
                            
                            Text("Detailed insights and energy patterns")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.7))
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Time Range Selector
                        TimeRangeSelector(selectedRange: $selectedTimeRange)
                            .padding(.horizontal)
                        
                        // Chart Type Selector
                        ChartTypeSelector(selectedType: $selectedChartType)
                            .padding(.horizontal)
                        
                        // Simple Analytics Chart
                        SimpleAnalyticsChart(
                            data: chartData,
                            chartType: selectedChartType,
                            timeRange: selectedTimeRange,
                            isLoading: isLoading
                        )
                        .padding(.horizontal)
                        
                        // Current Stats Summary
                        SimpleStatsCard(
                            data: chartData,
                            chartType: selectedChartType
                        )
                        .padding(.horizontal)
                        
                        // Device Breakdown
                        DeviceBreakdownCard()
                            .padding(.horizontal)
                        
                        Spacer(minLength: 100) // Tab bar spacing
                    }
                }
                .refreshable {
                    await loadAnalyticsData()
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataSheet()
        }
        .onAppear {
            Task {
                await loadAnalyticsData()
            }
        }
        .onChange(of: selectedTimeRange) { _, _ in
            Task {
                await loadAnalyticsData()
            }
        }
        .onChange(of: selectedChartType) { _, _ in
            Task {
                await loadAnalyticsData()
            }
        }
    }
    
    private func loadAnalyticsData() async {
        isLoading = true
        
        // Convert enum values to API parameters
        let timeRangeParam = selectedTimeRange.rawValue.lowercased()
        let chartTypeParam = selectedChartType.rawValue.lowercased()
        
        // Try to fetch real data from backend
        let result = await apiManager.fetchAnalyticsData(timeRange: timeRangeParam, chartType: chartTypeParam)
        
        switch result {
        case .success(let response):
            // Convert API response to simple data points
            chartData = response.data.map { apiDataPoint in
                SimpleDataPoint(
                    id: UUID(),
                    value: apiDataPoint.value,
                    label: apiDataPoint.label ?? ""
                )
            }
        case .failure(let error):
            print("Failed to fetch analytics data: \(error.localizedDescription)")
            // Fallback to simulated data
            chartData = generateSimpleData(for: selectedChartType, timeRange: selectedTimeRange)
        }
        
        isLoading = false
    }
    
    private func generateSimpleData(for chartType: ChartType, timeRange: TimeRange) -> [SimpleDataPoint] {
        let dataPoints = timeRange.dataPoints
        
        return (0..<dataPoints).map { index in
            let baseValue: Double
            
            switch chartType {
            case .usage:
                baseValue = Double.random(in: 2.0...5.0)
            case .cost:
                baseValue = Double.random(in: 0.3...0.8)
            case .efficiency:
                baseValue = Double.random(in: 70...95)
            }
            
            return SimpleDataPoint(
                id: UUID(),
                value: baseValue,
                label: "Point \(index + 1)"
            )
        }
    }
}

// MARK: - Simple Data Point
struct SimpleDataPoint: Identifiable {
    let id: UUID
    let value: Double
    let label: String
}

// MARK: - Simple Analytics Chart
struct SimpleAnalyticsChart: View {
    let data: [SimpleDataPoint]
    let chartType: AnalyticsView.ChartType
    let timeRange: AnalyticsView.TimeRange
    let isLoading: Bool
    
    private var maxValue: Double {
        data.map(\.value).max() ?? 1.0
    }
    
    private var minValue: Double {
        data.map(\.value).min() ?? 0.0
    }
    
    private var averageValue: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Chart Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: chartType.icon)
                            .foregroundColor(chartType.color)
                            .font(.title3)
                        
                        Text("\(chartType.rawValue) Analytics")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    
                    Text(timeRange.title)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                }
                
                Spacer()
                
                if !isLoading && !data.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Current")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.6))
                        
                        Text(String(format: "%.1f %@", data.last?.value ?? 0, chartType.unit))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(chartType.color)
                    }
                }
            }
            
            // Chart Area
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(chartType.color)
                        .scaleEffect(1.2)
                    
                    Text("Loading \(chartType.rawValue.lowercased()) data...")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.6))
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else if data.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.black.opacity(0.3))
                    
                    Text("No data available")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.6))
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                // Simple Bar Chart
                SimpleBarChart(
                    data: data,
                    color: chartType.color,
                    maxValue: maxValue
                )
                .frame(height: 200)
                
                // Chart Statistics
                HStack(spacing: 20) {
                    StatItem(
                        title: "Average",
                        value: String(format: "%.1f %@", averageValue, chartType.unit),
                        color: chartType.color
                    )
                    
                    StatItem(
                        title: "Peak",
                        value: String(format: "%.1f %@", maxValue, chartType.unit),
                        color: .red
                    )
                    
                    StatItem(
                        title: "Low",
                        value: String(format: "%.1f %@", minValue, chartType.unit),
                        color: .green
                    )
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .shadow(radius: 10)
    }
}

// MARK: - Simple Bar Chart
struct SimpleBarChart: View {
    let data: [SimpleDataPoint]
    let color: Color
    let maxValue: Double
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(data) { point in
                VStack {
                    Spacer()
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: CGFloat(point.value / maxValue) * 150)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.02))
        )
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.black.opacity(0.6))
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Simple Stats Card
struct SimpleStatsCard: View {
    let data: [SimpleDataPoint]
    let chartType: AnalyticsView.ChartType
    
    private var averageValue: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Performance Insights")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                InsightCard(
                    title: "Average",
                    value: String(format: "%.1f", averageValue),
                    subtitle: chartType.unit,
                    color: chartType.color,
                    icon: "chart.bar.fill"
                )
                
                InsightCard(
                    title: "Status",
                    value: getStatusText(),
                    subtitle: "Current",
                    color: getStatusColor(),
                    icon: "checkmark.circle.fill"
                )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .shadow(radius: 10)
    }
    
    private func getStatusText() -> String {
        switch chartType {
        case .usage: return "Normal"
        case .cost: return "Low"
        case .efficiency: return "Good"
        }
    }
    
    private func getStatusColor() -> Color {
        switch chartType {
        case .usage: return .blue
        case .cost: return .green
        case .efficiency: return .green
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.black.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Device Breakdown Card
struct DeviceBreakdownCard: View {
    @EnvironmentObject var apiManager: APIManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🏠 Device Breakdown")
                    .font(.title2)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("Current Usage")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
            }
            
            if !apiManager.devices.isEmpty {
                VStack(spacing: 12) {
                    ForEach(apiManager.devices) { device in
                        HStack {
                            Circle()
                                .fill(device.type.color)
                                .frame(width: 12, height: 12)
                            
                            Text(device.name)
                                .foregroundColor(.black)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f kW", device.currentPower))
                                .foregroundColor(device.type.color)
                                .fontWeight(.medium)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 4)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                        .tint(.blue)
                    
                    Text("Loading device data...")
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
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .shadow(radius: 10)
    }
}

// MARK: - Time Range Selector
struct TimeRangeSelector: View {
    @Binding var selectedRange: AnalyticsView.TimeRange
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsView.TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    selectedRange = range
                }) {
                    Text(range.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedRange == range ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedRange == range ? Color.black : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .animation(.spring(response: 0.3), value: selectedRange)
    }
}

// MARK: - Chart Type Selector
struct ChartTypeSelector: View {
    @Binding var selectedType: AnalyticsView.ChartType
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsView.ChartType.allCases, id: \.self) { type in
                Button(action: {
                    selectedType = type
                }) {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedType == type ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedType == type ? type.color : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .animation(.spring(response: 0.3), value: selectedType)
    }
}

// MARK: - Export Data Sheet
struct ExportDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("📊 Export functionality coming soon...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(APIManager())
        .environmentObject(WebSocketService())
} 