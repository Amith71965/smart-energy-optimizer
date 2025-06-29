import SwiftUI

struct OptimizationView: View {
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var webSocketService: WebSocketService
    @State private var showingApplyConfirmation = false
    @State private var selectedRecommendation: Recommendation?
    @State private var appliedRecommendations: Set<String> = []
    @State private var showingSavingsDetail = false
    @State private var isLoading = false
    
    var recommendations: [Recommendation] {
        webSocketService.realTimeRecommendations.isEmpty ? 
        apiManager.recommendations : webSocketService.realTimeRecommendations
    }
    
    var totalPotentialSavings: Double {
        recommendations.reduce(0) { $0 + $1.potentialSavings }
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
                                Text("AI Optimization")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                AIStatusIndicator()
                            }
                            
                            Text("Smart recommendations to optimize your energy usage")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.7))
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Loading state
                        if isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.blue)
                                
                                Text("AI analyzing your energy patterns...")
                                    .font(.subheadline)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .padding(40)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(radius: 10)
                            .padding(.horizontal)
                        }
                        // Show recommendations if available
                        else if !recommendations.isEmpty {
                            // Savings Summary Card
                            SavingsSummaryCard(
                                totalSavings: totalPotentialSavings,
                                recommendationCount: recommendations.count
                            ) {
                                showingSavingsDetail = true
                            }
                            .padding(.horizontal)
                            
                            // AI Recommendations Header
                            HStack {
                                Text("🤖 AI Recommendations")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Text("\(recommendations.count) active")
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.6))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.blue.opacity(0.1), in: Capsule())
                            }
                            .padding(.horizontal)
                            
                            // Recommendations List
                            ForEach(recommendations) { recommendation in
                                RecommendationCard(
                                    recommendation: recommendation,
                                    isApplied: appliedRecommendations.contains(recommendation.id)
                                ) {
                                    selectedRecommendation = recommendation
                                    showingApplyConfirmation = true
                                }
                                .padding(.horizontal)
                            }
                            
                            // Optimization History
                            OptimizationHistoryCard()
                                .padding(.horizontal)
                        }
                        // No recommendations available
                        else {
                            NoRecommendationsView()
                                .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 100) // Tab bar spacing
                    }
                }
                .refreshable {
                    await loadRecommendations()
                }
            }
        }
        .sheet(isPresented: $showingApplyConfirmation) {
            if let recommendation = selectedRecommendation {
                ApplyRecommendationSheet(recommendation: recommendation) {
                    await applyRecommendation(recommendation)
                }
            }
        }
        .sheet(isPresented: $showingSavingsDetail) {
            SavingsDetailSheet(
                recommendations: recommendations,
                totalSavings: totalPotentialSavings
            )
        }
        .onAppear {
            Task {
                await loadRecommendations()
            }
        }
    }
    
    private func loadRecommendations() async {
        isLoading = true
        
        // Fetch recommendations from API
        await apiManager.refreshAllData()
        
        // Small delay to show loading state
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        isLoading = false
    }
    
    private func applyRecommendation(_ recommendation: Recommendation) async {
        // Apply the recommendation through the API
        let result = await apiManager.applyRecommendation(recommendationId: recommendation.id)
        
        switch result {
        case .success:
            // Mark as applied
            appliedRecommendations.insert(recommendation.id)
            
            // Refresh data to get updated recommendations
            await loadRecommendations()
            
        case .failure(let error):
            print("Failed to apply recommendation: \(error.localizedDescription)")
        }
        
        showingApplyConfirmation = false
        selectedRecommendation = nil
    }
}

// MARK: - AI Status Indicator
struct AIStatusIndicator: View {
    @EnvironmentObject var webSocketService: WebSocketService
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.blue)
                .scaleEffect(webSocketService.isConnected ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(), value: webSocketService.isConnected)
            
            Text("AI Analyzing")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .blue.opacity(0.3), radius: 4)
    }
}

// MARK: - Savings Summary Card
struct SavingsSummaryCard: View {
    let totalSavings: Double
    let recommendationCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Potential Savings")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        HStack(spacing: 8) {
                            Text(String(format: "$%.2f", totalSavings))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text("per month")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(.green.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "leaf.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        
                        Text("\(recommendationCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                }
                
                // Progress indicator
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Tap to see detailed savings breakdown")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.5))
                }
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .green.opacity(0.2), radius: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let recommendation: Recommendation
    let isApplied: Bool
    let onApply: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: recommendation.priority.icon)
                            .font(.caption)
                            .foregroundColor(recommendation.priority.color)
                        
                        Text(recommendation.priority.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(recommendation.priority.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(recommendation.priority.color.opacity(0.1), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(recommendation.priority.color.opacity(0.3), lineWidth: 1)
                    )
                    
                    Text(recommendation.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                if isApplied {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            // Description
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.7))
                .lineLimit(3)
            
            // Savings and action
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Potential Savings")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.6))
                    
                    Text(String(format: "$%.2f", recommendation.potentialSavings))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                if !isApplied {
                    SmartApplyButton(
                        priority: recommendation.priority,
                        onApply: onApply
                    )
                } else {
                    Text("Applied")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.green.opacity(0.1), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.green.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(recommendation.priority.color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: recommendation.priority.color.opacity(0.1), radius: 8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Smart Apply Button
struct SmartApplyButton: View {
    let priority: Recommendation.Priority
    let onApply: () -> Void
    
    @State private var isApplying = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isApplying = true
            }
            
            onApply()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.3)) {
                    isApplying = false
                }
            }
        }) {
            HStack(spacing: 8) {
                if isApplying {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.caption)
                }
                
                Text(isApplying ? "Applying..." : "Apply")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(priority.gradient, in: Capsule())
            .shadow(color: priority.color.opacity(0.3), radius: 4)
        }
        .disabled(isApplying)
        .animation(.spring(response: 0.3), value: isApplying)
    }
}

// MARK: - No Recommendations View
struct NoRecommendationsView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("All Optimized!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("Your energy system is running efficiently. Check back later for new optimization opportunities.")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .shadow(radius: 10)
    }
}

// MARK: - Optimization History Card
struct OptimizationHistoryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Optimizations")
                .font(.headline)
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                HistoryItem(
                    title: "HVAC Schedule Optimized",
                    savings: "$12.50",
                    timeAgo: "2 hours ago",
                    icon: "thermometer"
                )
                
                HistoryItem(
                    title: "Lighting Brightness Adjusted",
                    savings: "$5.25",
                    timeAgo: "1 day ago",
                    icon: "lightbulb.fill"
                )
                
                HistoryItem(
                    title: "Water Heater Temperature Reduced",
                    savings: "$8.75",
                    timeAgo: "3 days ago",
                    icon: "drop.fill"
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
}

// MARK: - History Item
struct HistoryItem: View {
    let title: String
    let savings: String
    let timeAgo: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Spacer()
            
            Text(savings)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Apply Recommendation Sheet
struct ApplyRecommendationSheet: View {
    let recommendation: Recommendation
    let onApply: () async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isApplying = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(recommendation.priority.gradient)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .shadow(color: recommendation.priority.color.opacity(0.3), radius: 20)
                    
                    VStack(spacing: 8) {
                        Text("Apply Recommendation")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(recommendation.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Details
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(recommendation.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Potential Savings")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "$%.2f", recommendation.potentialSavings))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Priority")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(recommendation.priority.rawValue.capitalized)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(recommendation.priority.color)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        isApplying = true
                        Task {
                            await onApply()
                            isApplying = false
                        }
                    }) {
                        HStack {
                            if isApplying {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            
                            Text(isApplying ? "Applying..." : "Apply Recommendation")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(recommendation.priority.gradient, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isApplying)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Savings Detail Sheet
struct SavingsDetailSheet: View {
    let recommendations: [Recommendation]
    let totalSavings: Double
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Total savings summary
                VStack(spacing: 12) {
                    Text("Total Monthly Savings")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "$%.2f", totalSavings))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding()
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                
                // Breakdown by recommendation
                List {
                    ForEach(recommendations) { recommendation in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recommendation.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(recommendation.priority.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(recommendation.priority.color)
                            }
                            
                            Spacer()
                            
                            Text(String(format: "$%.2f", recommendation.potentialSavings))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Savings Breakdown")
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
    OptimizationView()
        .environmentObject(APIManager())
        .environmentObject(WebSocketService())
} 