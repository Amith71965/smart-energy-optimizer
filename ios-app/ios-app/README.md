# Smart Energy Optimizer iOS App

A cutting-edge iOS application for the IBM TechXchange Hackathon featuring real-time energy monitoring, AI-powered optimization, and ultra-modern glassmorphism UI design.

## 🚀 Features

### 📊 Real-time Dashboard
- **Live Energy Monitoring**: Real-time power consumption tracking with animated circular progress rings
- **Cost Counter**: Animated cost tracking with live updates and savings insights
- **Device Status Grid**: Beautiful glassmorphism cards showing all 4 smart devices
- **Live Energy Chart**: Real-time line charts with gradient fills using Charts framework
- **AI Status Indicator**: Pulsing AI activity indicator with connection status

### 🏠 Smart Device Control
- **Interactive Device Cards**: Glassmorphism design with haptic feedback
- **Smart Toggles**: Custom animated switches with spring physics
- **Temperature Control**: HVAC temperature adjustment with sliders and +/- buttons
- **Brightness Control**: Lighting brightness control with sun icons
- **Power Meters**: Animated horizontal progress bars showing device usage
- **Real-time Updates**: WebSocket-powered live device status updates

### 📈 Advanced Analytics
- **Interactive Charts**: Beautiful charts using Apple's Charts framework
- **Usage Trends**: 24-hour, 7-day, and 30-day trend analysis
- **Device Breakdown**: Pie charts showing power distribution across devices
- **AI Predictions**: Dashed line charts showing 24-hour AI forecasts with confidence bands
- **Efficiency Metrics**: Progress bars and scoring system for energy efficiency

### 🤖 AI Optimization
- **Smart Recommendations**: AI-powered energy optimization suggestions
- **Priority System**: High/Medium/Low priority recommendations with color coding
- **Savings Calculator**: Real-time potential savings calculations
- **One-tap Apply**: Smooth animations for applying AI recommendations
- **Optimization History**: Timeline of past optimizations and their savings

## 🎨 Design Features

### Glassmorphism UI
- **Ultra-thin Material**: iOS 17 blur effects throughout the app
- **Glass Stroke**: Subtle borders with transparency
- **Shadow Effects**: Dynamic shadows that respond to device states
- **Gradient Backgrounds**: Deep space to electric blue gradients

### Animations & Interactions
- **Spring Physics**: Smooth spring animations for all interactions
- **Haptic Feedback**: Tactile feedback for device controls and interactions
- **Micro-animations**: Pulsing indicators, scaling effects, and smooth transitions
- **Live Data Animations**: Real-time chart updates with staggered reveals

### Color System
- **Energy Blue**: #007AFF - Primary accent color
- **Energy Green**: #34C759 - Success and efficiency color
- **Energy Orange**: #FF9500 - Warning and cost color
- **Energy Red**: #FF3B30 - Alert and high usage color
- **Dynamic Gradients**: Device-specific gradients that change based on state

## 🛠 Technical Implementation

### Architecture
- **SwiftUI 5.0**: Latest SwiftUI features and modifiers
- **Combine Framework**: Reactive data flow and state management
- **@Observable**: Modern state management with iOS 17
- **Charts Framework**: Native iOS charts for beautiful visualizations
- **Network Framework**: Real-time network monitoring

### Real-time Data
- **WebSocket Service**: Real-time connection to backend at ws://localhost:3000
- **API Manager**: HTTP client with retry logic and offline capability
- **Auto-reconnection**: Automatic WebSocket reconnection with exponential backoff
- **Network Monitoring**: Real-time network status monitoring

### Data Models
```swift
// Device Management
struct EnergyDevice: Identifiable, Codable
struct DeviceReading: Codable
struct EnergySummary: Codable

// AI & Predictions
struct Prediction: Identifiable, Codable
struct Recommendation: Identifiable, Codable
struct OptimizationResponse: Codable

// Real-time Data
struct WebSocketMessage: Codable
struct SystemHealth: Codable
```

### API Integration
- **GET /api/devices** - Smart device data
- **GET /api/energy/current** - Real-time energy readings
- **GET /api/energy/summary** - Usage summary and statistics
- **GET /api/predictions** - AI-powered 24-hour forecasts
- **GET /api/optimization/recommendations** - AI optimization suggestions
- **POST /api/devices/:id/control** - Device control actions

## 📱 Requirements

### iOS Version
- **Minimum**: iOS 16.0
- **Recommended**: iOS 17.0+ for best performance
- **Target**: iPhone 15 Pro for optimal experience

### Frameworks Required
```swift
import SwiftUI
import Charts
import Combine
import Foundation
import Network
```

### Network Configuration
The app requires localhost access for development. The Info.plist includes:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## 🚀 Setup Instructions

### 1. Prerequisites
- Xcode 15.0 or later
- iOS 16.0+ device or simulator
- Backend API running on localhost:3000

### 2. Project Setup
1. Open `ios-app.xcodeproj` in Xcode
2. Ensure the following frameworks are linked:
   - SwiftUI
   - Charts
   - Combine
   - Network
   - Foundation

### 3. Build Configuration
1. Set deployment target to iOS 16.0
2. Enable background app refresh capabilities
3. Configure App Transport Security for localhost

### 4. Backend Connection
1. Ensure backend API is running on `http://localhost:3000`
2. WebSocket server should be available at `ws://localhost:3000`
3. Test connection using the in-app connection status indicator

### 5. Testing
1. Run on iPhone 15 Pro simulator for best experience
2. Test real-time data updates via WebSocket
3. Verify device control functionality
4. Check chart animations and interactions

## 📊 Performance Features

### Optimization
- **60 FPS**: Smooth animations throughout the app
- **Efficient Memory**: Optimized for large datasets
- **Battery Friendly**: Background optimization for real-time updates
- **Network Efficient**: Smart caching and retry logic

### Accessibility
- **VoiceOver Support**: Full accessibility support
- **Dynamic Type**: Supports iOS dynamic font sizing
- **High Contrast**: Optimized for accessibility settings
- **Haptic Feedback**: Tactile feedback for all interactions

## 🎯 IBM TechXchange Hackathon Features

### Innovation
- **Real IBM watsonx.ai Integration**: Actual AI predictions and recommendations
- **Professional UI/UX**: Production-quality glassmorphism design
- **Real-time Architecture**: WebSocket-powered live updates
- **Modern iOS Development**: Latest SwiftUI 5.0 and iOS 17 features

### Technical Excellence
- **Clean Architecture**: Separation of concerns with MVVM pattern
- **Error Handling**: Comprehensive error handling and offline support
- **Performance**: Optimized for smooth 60 FPS performance
- **Scalability**: Designed to handle multiple devices and large datasets

### User Experience
- **Intuitive Interface**: Easy-to-use device controls and navigation
- **Beautiful Animations**: Delightful micro-interactions throughout
- **Informative Analytics**: Clear data visualization and insights
- **Smart Recommendations**: Actionable AI-powered suggestions

## 🔧 Development Notes

### File Structure
```
ios-app/
├── ios-app/
│   ├── SmartEnergyOptimizerApp.swift    # App entry point
│   ├── DataModels.swift                 # All data structures
│   ├── APIManager.swift                 # HTTP API client
│   ├── WebSocketService.swift           # Real-time WebSocket service
│   ├── ContentView.swift                # Main tabbed interface
│   ├── DashboardComponents.swift        # Dashboard UI components
│   ├── DevicesView.swift                # Device control interface
│   ├── AnalyticsView.swift              # Charts and analytics
│   ├── OptimizationView.swift           # AI recommendations
│   ├── Info.plist                       # App configuration
│   └── README.md                        # This file
```

### Key Components
- **APIManager**: Handles all HTTP requests with retry logic
- **WebSocketService**: Manages real-time connections with auto-reconnect
- **DataModels**: Comprehensive data structures for all app data
- **UI Components**: Reusable glassmorphism components with animations

## 🏆 Hackathon Ready

This iOS app is specifically designed for the IBM TechXchange Hackathon with:

✅ **Real IBM watsonx.ai Integration**  
✅ **Professional Production Quality**  
✅ **Ultra-modern Glassmorphism UI**  
✅ **Real-time Data Visualization**  
✅ **Smart Device Control**  
✅ **AI-powered Optimization**  
✅ **Beautiful Charts & Analytics**  
✅ **Smooth 60 FPS Performance**  
✅ **Comprehensive Error Handling**  
✅ **Dark Mode Optimized**  

Ready to impress the judges with cutting-edge iOS development and real AI integration! 🚀 