import SwiftUI

struct DevicesView: View {
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var webSocketService: WebSocketService
    @State private var selectedDevice: EnergyDevice?
    @State private var showingDeviceDetail = false
    
    var devices: [EnergyDevice] {
        webSocketService.realTimeDeviceUpdates.isEmpty ? 
        apiManager.devices : webSocketService.realTimeDeviceUpdates
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Smart Devices")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 1)
                                
                                Spacer()
                                
                                DeviceStatusSummary(devices: devices)
                            }
                            
                            Text("Control and monitor your smart home devices")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.8))
                                .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Device Cards
                        if devices.isEmpty {
                            // Loading or empty state
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(.energyBlue)
                                    .scaleEffect(1.5)
                                
                                Text("Loading devices...")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .padding(.horizontal)
                        } else {
                            ForEach(devices) { device in
                                DeviceControlCard(device: device) {
                                    selectedDevice = device
                                    showingDeviceDetail = true
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 100) // Tab bar spacing
                    }
                }
                .refreshable {
                    await apiManager.refreshAllData()
                }
                .onAppear {
                    Task {
                        await apiManager.refreshAllData()
                    }
                }
            }
        }
        .sheet(isPresented: $showingDeviceDetail) {
            if let device = selectedDevice {
                DeviceDetailView(device: device)
            }
        }
    }
}

// MARK: - Device Status Summary
struct DeviceStatusSummary: View {
    let devices: [EnergyDevice]
    
    private var activeDevices: Int {
        devices.filter { $0.isOn }.count
    }
    
    private var totalPower: Double {
        devices.reduce(0) { $0 + $1.currentPower }
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.energyGreen)
                    .frame(width: 8, height: 8)
                    .scaleEffect(activeDevices > 0 ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(), value: activeDevices > 0)
                
                Text("\(activeDevices)/\(devices.count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(totalPower.formattedPower)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Device Control Card
struct DeviceControlCard: View {
    let device: EnergyDevice
    let onTap: () -> Void
    
    @EnvironmentObject var apiManager: APIManager
    @State private var isToggling = false
    @State private var localIsOn: Bool
    @State private var localTemperature: Double
    @State private var localBrightness: Int
    
    init(device: EnergyDevice, onTap: @escaping () -> Void) {
        self.device = device
        self.onTap = onTap
        self._localIsOn = State(initialValue: device.isOn)
        self._localTemperature = State(initialValue: device.targetTemp ?? 70.0)
        self._localBrightness = State(initialValue: device.brightness ?? 100)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                // Device icon and info
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(device.type.gradient)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: device.type.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .shadow(color: device.type.color.opacity(0.3), radius: 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(device.location)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Power toggle
                SmartToggle(isOn: $localIsOn, color: device.type.color) {
                    await toggleDevice()
                }
                .disabled(isToggling)
            }
            
            // Power and cost info
            HStack(spacing: 20) {
                PowerInfoCard(
                    title: "Current Power",
                    value: device.currentPower.formattedPower,
                    icon: "bolt.fill",
                    color: localIsOn ? device.type.color : .gray
                )
                
                PowerInfoCard(
                    title: "Today's Cost",
                    value: device.todaysCost.formattedCost,
                    icon: "dollarsign.circle.fill",
                    color: .energyOrange
                )
                
                PowerInfoCard(
                    title: "Usage",
                    value: device.todaysUsage.formattedPower,
                    icon: "chart.bar.fill",
                    color: .energyBlue
                )
            }
            
            // Device-specific controls
            if localIsOn {
                deviceSpecificControls
            }
            
            // Quick actions
            HStack(spacing: 12) {
                Button("Details") {
                    onTap()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.glassStroke, lineWidth: 1)
                )
                
                Spacer()
                
                if localIsOn {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.energyGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.energyGreen.opacity(0.1), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.energyGreen.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Text("Standby")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.gray.opacity(0.1), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(localIsOn ? device.type.color.opacity(0.3) : Color.glassStroke, lineWidth: 1)
        )
        .shadow(color: localIsOn ? device.type.color.opacity(0.2) : .clear, radius: 15)
        .animation(.easeInOut(duration: 0.3), value: localIsOn)
        .onChange(of: device.isOn) { _, newValue in
            localIsOn = newValue
        }
        .onChange(of: device.targetTemp) { _, newValue in
            if let temp = newValue {
                localTemperature = temp
            }
        }
        .onChange(of: device.brightness) { _, newValue in
            if let brightness = newValue {
                localBrightness = brightness
            }
        }
    }
    
    @ViewBuilder
    private var deviceSpecificControls: some View {
        switch device.type {
        case .hvac:
            TemperatureControl(
                temperature: $localTemperature,
                color: device.type.color
            ) { newTemp in
                await setTemperature(newTemp)
            }
            
        case .lighting:
            BrightnessControl(
                brightness: $localBrightness,
                color: device.type.color
            ) { newBrightness in
                await setBrightness(newBrightness)
            }
            
        case .waterHeater, .appliance:
            EmptyView()
        }
    }
    
    private func toggleDevice() async {
        isToggling = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        await apiManager.toggleDevice(device.id)
        
        isToggling = false
    }
    
    private func setTemperature(_ temperature: Double) async {
        await apiManager.setDeviceTemperature(device.id, temperature: temperature)
    }
    
    private func setBrightness(_ brightness: Int) async {
        await apiManager.setDeviceBrightness(device.id, brightness: brightness)
    }
}

// MARK: - Smart Toggle
struct SmartToggle: View {
    @Binding var isOn: Bool
    let color: Color
    let onToggle: () async -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isAnimating = true
            }
            
            Task {
                await onToggle()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3)) {
                        isAnimating = false
                    }
                }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isOn ? color : Color.white.opacity(0.1))
                    .frame(width: 60, height: 32)
                    .shadow(color: isOn ? color.opacity(0.3) : .clear, radius: 8)
                
                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .offset(x: isOn ? 14 : -14)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .shadow(radius: 2)
            }
        }
        .animation(.spring(response: 0.3), value: isOn)
        .animation(.spring(response: 0.2), value: isAnimating)
    }
}

// MARK: - Power Info Card
struct PowerInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Temperature Control
struct TemperatureControl: View {
    @Binding var temperature: Double
    let color: Color
    let onTemperatureChange: (Double) async -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Temperature")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(temperature))°F")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    adjustTemperature(-1)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Slider(value: $temperature, in: 60...85, step: 1)
                    .accentColor(color)
                    .onChange(of: temperature) { _, newValue in
                        if !isDragging {
                            Task {
                                await onTemperatureChange(newValue)
                            }
                        }
                    }
                
                Button(action: {
                    adjustTemperature(1)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(color)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func adjustTemperature(_ delta: Double) {
        let newTemp = max(60, min(85, temperature + delta))
        temperature = newTemp
        
        Task {
            await onTemperatureChange(newTemp)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Brightness Control
struct BrightnessControl: View {
    @Binding var brightness: Int
    let color: Color
    let onBrightnessChange: (Int) async -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Brightness")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(brightness)%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    adjustBrightness(-10)
                }) {
                    Image(systemName: "sun.min.fill")
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Slider(value: Binding(
                    get: { Double(brightness) },
                    set: { brightness = Int($0) }
                ), in: 0...100, step: 1)
                .accentColor(color)
                .onChange(of: brightness) { _, newValue in
                    if !isDragging {
                        Task {
                            await onBrightnessChange(newValue)
                        }
                    }
                }
                
                Button(action: {
                    adjustBrightness(10)
                }) {
                    Image(systemName: "sun.max.fill")
                        .font(.title2)
                        .foregroundColor(color)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func adjustBrightness(_ delta: Int) {
        let newBrightness = max(0, min(100, brightness + delta))
        brightness = newBrightness
        
        Task {
            await onBrightnessChange(newBrightness)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Device Detail View
struct DeviceDetailView: View {
    let device: EnergyDevice
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Device Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(device.type.gradient)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: device.type.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: device.type.color.opacity(0.3), radius: 20)
                            
                            VStack(spacing: 8) {
                                Text(device.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(device.location)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.top, 20)
                        
                        // Status and controls would go here
                        Text("Device details and advanced controls coming soon...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                    }
                }
            }
            .navigationTitle("Device Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.energyBlue)
                }
            }
        }
    }
} 