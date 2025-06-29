import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var webSocketService: WebSocketService
    @State private var selectedTimeRange: TimeRange = .day
    @State private var selectedChartType: ChartType = .usage
    @State private var showingExportSheet = false
    
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
    }
    
    enum ChartType: String, CaseIterable {
        case usage = "Usage"
        case cost = "Cost"
        case efficiency = "Efficiency"
        
        var color: Color {
            switch self {
            case .usage: return .energyBlue
            case .cost: return .energyOrange
            case .efficiency: return .energyGreen
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Analytics")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(colors: [.white, .energyBlue], startPoint: .leading, endPoint: .trailing)
                                    )
                                
                                Spacer()
                                
                                Button(action: {
                                    showingExportSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                }
                            }
                            
                            Text("Detailed insights and energy patterns")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Time Range Selector
                        TimeRangeSelector(selectedRange: $selectedTimeRange)
                            .padding(.horizontal)
                        
                        // Chart Type Selector
                        ChartTypeSelector(selectedType: $selectedChartType)
                            .padding(.horizontal)
                        
                        // Main Chart Placeholder
                        VStack(spacing: 16) {
                            Text("📊 Analytics Charts")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("Advanced analytics charts coming soon with full Charts framework integration")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                            
                            // Simple data display
                            if let summary = apiManager.energySummary {
                                VStack(spacing: 12) {
                                    HStack {
                                        VStack {
                                            Text(summary.totalTodaysUsage.formattedPower)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.energyBlue)
                                            Text("Usage")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        VStack {
                                            Text(summary.totalTodaysCost.formattedCost)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.energyOrange)
                                            Text("Cost")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        VStack {
                                            Text("\(summary.efficiencyScore)%")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.energyGreen)
                                            Text("Efficiency")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(40)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.glassStroke, lineWidth: 1)
                        )
                        .shadow(radius: 10)
                        .padding(.horizontal)
                        
                        // Device Breakdown Placeholder
                        VStack(spacing: 16) {
                            Text("🏠 Device Breakdown")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            if !apiManager.devices.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(apiManager.devices) { device in
                                        HStack {
                                            Circle()
                                                .fill(device.type.color)
                                                .frame(width: 12, height: 12)
                                            
                                            Text(device.name)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Text(device.currentPower.formattedPower)
                                                .foregroundColor(device.type.color)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.glassStroke, lineWidth: 1)
                        )
                        .shadow(radius: 10)
                        .padding(.horizontal)
                        
                        Spacer(minLength: 100) // Tab bar spacing
                    }
                }
                .refreshable {
                    await apiManager.refreshAllData()
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataSheet()
        }
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
                        .foregroundColor(selectedRange == range ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedRange == range ? .white : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.glassStroke, lineWidth: 1)
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
                        .foregroundColor(selectedType == type ? .black : .white)
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
                .stroke(Color.glassStroke, lineWidth: 1)
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