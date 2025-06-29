import SwiftUI

struct OptimizationView: View {
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var webSocketService: WebSocketService
    @State private var showingApplyConfirmation = false
    @State private var selectedRecommendation: Recommendation?
    @State private var appliedRecommendations: Set<String> = []
    @State private var showingSavingsDetail = false
    
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
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("AI Optimization")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(colors: [.white, .energyBlue], startPoint: .leading, endPoint: .trailing)
                                    )
                                
                                Spacer()
                                
                                AIStatusIndicator()
                            }
                            
                            Text("Smart recommendations to optimize your energy usage")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Placeholder content
                        VStack(spacing: 20) {
                            Text("🤖 AI Recommendations")
                                .font(.title)
                                .foregroundColor(.white)
                            
                            Text("Smart optimization recommendations coming soon...")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
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
    }
}

// MARK: - AI Status Indicator
struct AIStatusIndicator: View {
    @EnvironmentObject var webSocketService: WebSocketService
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.energyBlue)
                .scaleEffect(webSocketService.isConnected ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(), value: webSocketService.isConnected)
            
            Text("AI Analyzing")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
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
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text(totalSavings.formattedCost)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.energyGreen)
                            
                            Text("per month")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(.energyGreen.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "leaf.fill")
                                .font(.title2)
                                .foregroundColor(.energyGreen)
                        }
                        
                        Text("\(recommendationCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                // Progress indicator
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Tap to see detailed savings breakdown")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.energyGreen.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .energyGreen.opacity(0.2), radius: 10)
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
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if isApplied {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.energyGreen)
                }
            }
            
            // Description
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
            
            // Savings and action
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Potential Savings")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(recommendation.potentialSavings.formattedCost)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.energyGreen)
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
                        .foregroundColor(.energyGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.energyGreen.opacity(0.1), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.energyGreen.opacity(0.3), lineWidth: 1)
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
                    .fill(.energyGreen.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.energyGreen)
            }
            
            VStack(spacing: 8) {
                Text("All Optimized!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your energy system is running efficiently. Check back later for new optimization opportunities.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.energyGreen.opacity(0.3), lineWidth: 1)
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
                .foregroundColor(.white)
            
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
                .stroke(Color.glassStroke, lineWidth: 1)
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
                .foregroundColor(.energyGreen)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(savings)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.energyGreen)
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
                            
                            Text(recommendation.potentialSavings.formattedCost)
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
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(recommendation.priority.color)
                        }
                    }
                }
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                // Apply Button
                Button(action: {
                    Task {
                        isApplying = true
                        await onApply()
                        isApplying = false
                    }
                }) {
                    HStack {
                        if isApplying {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                        }
                        
                        Text(isApplying ? "Applying..." : "Apply Recommendation")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(recommendation.priority.color, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
                }
                .disabled(isApplying)
            }
            .padding()
            .navigationTitle("Optimization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
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
                Text("Detailed savings breakdown coming soon...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
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