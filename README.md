# 🏡 Smart Energy Optimizer - IBM TechXchange Hackathon 2025

**Real-time Smart Home Energy Management with IBM watsonx.ai Integration**

![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)
![IBM watsonx.ai](https://img.shields.io/badge/IBM-watsonx.ai-blue.svg)
![iOS](https://img.shields.io/badge/iOS-16.0+-lightgrey.svg)

Dashboard            |  Devices
:-------------------------:|:-------------------------:
![](https://github.com/Amith71965/smart-energy-optimizer/blob/a08600532278a204f6742e5252bb463d7dbdf6de/ios-app/App-1.png)  |  ![](https://github.com/Amith71965/smart-energy-optimizer/blob/36216633f0a6240f10c850028032ef167a12fad6/ios-app/Devices.png)

Dashboard            |  Devices
:-------------------------:|:-------------------------:
![](https://github.com/Amith71965/smart-energy-optimizer/blob/a08600532278a204f6742e5252bb463d7dbdf6de/ios-app/App-1.png)  |  ![](https://github.com/Amith71965/smart-energy-optimizer/blob/36216633f0a6240f10c850028032ef167a12fad6/ios-app/Devices.png)

## 🎯 **Project Overview**

Smart Energy Optimizer is an intelligent home energy management system that leverages **IBM watsonx.ai** to provide real-time energy monitoring, AI-powered predictions, and smart optimization recommendations. Built for the IBM TechXchange Hackathon 2025.

### **🌟 Key Features**
- 🤖 **Real IBM watsonx.ai Integration** - Granite-3-8b-instruct model for energy predictions
- 📱 **Native iOS App** - Beautiful SwiftUI interface with glassmorphism design
- ⚡ **Real-time Monitoring** - Live energy consumption tracking with WebSocket updates
- 🔮 **AI Predictions** - 24-hour energy forecasts with peak/off-peak analysis
- 🎯 **Smart Recommendations** - AI-powered optimization suggestions
- 🏠 **Device Control** - Remote control of smart home devices
- 📊 **Live Analytics** - Real-time charts and energy flow visualization

## 🏗️ **System Architecture**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   iOS App       │    │   Backend API    │    │ IBM watsonx.ai  │
│   (SwiftUI)     │◄──►│   (Node.js)      │◄──►│ (Granite Model) │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌────────▼────────┐              │
         │              │ Device Simulator │              │
         │              │  (Real-time)     │              │
         │              └─────────────────┘              │
         │                                               │
         └───────────── WebSocket Real-time ─────────────┘
```

## 🚀 **Getting Started**

### **Prerequisites**
- Node.js 18+
- Xcode 15+ (for iOS development)
- IBM Cloud account with watsonx.ai access

### **Backend Setup**

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/smart-energy-optimizer.git
   cd smart-energy-optimizer
   ```

2. **Install backend dependencies**
   ```bash
   cd backend
   npm install
   ```

3. **Configure IBM watsonx.ai**
   ```bash
   cp .env.example .env
   # Edit .env with your IBM Cloud credentials:
   # WATSONX_API_KEY=your_api_key
   # WATSONX_PROJECT_ID=your_project_id
   # WATSONX_URL=https://us-south.ml.cloud.ibm.com
   ```

4. **Start the backend server**
   ```bash
   npm start
   # Server runs on http://localhost:3000
   ```

5. **Start device simulators** (in new terminal)
   ```bash
   cd simulators
   npm install
   npm start
   ```

### **iOS App Setup**

1. **Open Xcode project**
   ```bash
   cd ios-app
   open ios-app.xcodeproj
   ```

2. **Configure network settings**
   - Ensure `Info.plist` allows localhost connections
   - Backend URL: `http://localhost:3000`
   - WebSocket URL: `ws://localhost:3000`

3. **Build and run**
   - Select iPhone simulator
   - Press ⌘+R to build and run

## 📱 **iOS App Features**

### **Dashboard**
- Real-time energy usage ring (kW display)
- Current cost tracking
- Device status grid with live updates
- Live energy flow chart
- Today's summary with efficiency scoring

### **Device Management**
- HVAC temperature control (60-85°F)
- Lighting brightness control (0-100%)
- Appliance on/off toggle
- Real-time power consumption display

### **AI Analytics**
- 24-hour energy predictions
- Peak/off-peak period identification
- Cost optimization recommendations
- Efficiency trend analysis

### **Real-time Features**
- WebSocket live updates (30-second intervals)
- Smooth animations and transitions
- Haptic feedback for interactions
- Auto-reconnection handling

## 🤖 **IBM watsonx.ai Integration**

### **AI Agents**
1. **Monitor Agent** - Real-time energy pattern analysis
2. **Prediction Agent** - 24-hour consumption forecasting
3. **Optimization Agent** - Smart recommendation generation

### **Model Details**
- **Model:** `ibm/granite-3-8b-instruct`
- **Authentication:** IBM Cloud IAM with auto-refresh
- **Response Time:** < 2 seconds average
- **Fallback:** Graceful degradation with statistical models

### **AI Capabilities**
- Energy consumption prediction with 70% confidence
- Peak hour identification (7-9 AM, 6-9 PM)
- Cost optimization recommendations
- Device usage pattern analysis

## 🔧 **API Endpoints**

### **Core APIs**
- `GET /health` - System health and AI status
- `GET /api/devices` - Device list and status
- `GET /api/energy/current` - Real-time energy readings
- `GET /api/energy/summary` - Dashboard summary data

### **AI APIs**
- `GET /api/predictions` - 24-hour AI forecasts
- `GET /api/optimization/recommendations` - AI suggestions

### **Device Control**
- `POST /api/devices/:id/control` - Device control actions

### **WebSocket**
- `ws://localhost:3000` - Real-time data streaming

## 📊 **Demo Data**

The system includes realistic device simulation:
- **HVAC System:** 800-1200W consumption
- **Water Heater:** 1000-1500W consumption  
- **Kitchen Lights:** 50-100W consumption
- **Washing Machine:** 0W (off) / 800W (running)

## 🎨 **Design System**

### **Colors**
- Energy Blue: `#007AFF`
- Energy Green: `#34C759`
- Energy Orange: `#FF9500`
- Energy Red: `#FF3B30`

### **UI Features**
- Glassmorphism design with ultra-thin materials
- Dark text on light backgrounds for accessibility
- Smooth animations with spring physics
- Haptic feedback for user interactions

## 🏆 **Hackathon Highlights**

### **Innovation**
- ✅ Real IBM watsonx.ai integration (not mock)
- ✅ 3 specialized AI agents working in concert
- ✅ Real-time WebSocket data streaming
- ✅ Professional iOS app with native performance

### **Technical Excellence**
- ✅ Granite-3-8b-instruct model integration
- ✅ SwiftUI with modern iOS development patterns
- ✅ RESTful API design with proper error handling
- ✅ Real-time data visualization

### **User Experience**
- ✅ Intuitive energy management interface
- ✅ Actionable AI recommendations
- ✅ Real-time feedback and control
- ✅ Professional design and animations

## 📈 **Performance Metrics**

- **Backend Response Time:** < 100ms for most endpoints
- **AI Processing Time:** < 2 seconds for predictions
- **Data Update Frequency:** Every 30 seconds
- **WebSocket Latency:** < 50ms
- **iOS App:** 60fps smooth animations

## 🛠️ **Technology Stack**

### **Backend**
- Node.js with Express.js
- WebSocket for real-time communication
- IBM watsonx.ai SDK
- Device simulation with realistic patterns

### **iOS App**
- SwiftUI 5.0 with @Observable pattern
- Combine framework for reactive programming
- Network framework for connection monitoring
- Native iOS performance optimization

### **AI/ML**
- IBM watsonx.ai platform
- Granite-3-8b-instruct model
- Statistical fallback algorithms
- Real-time data processing

## 📄 **License**

MIT License - Built for IBM TechXchange Hackathon 2025

## 👨‍💻 **Author**

**Amith Kumar Yadav K**
- IBM TechXchange Hackathon 2025 Participant
- Smart Energy Optimization with watsonx.ai

---

**🏆 Ready for IBM TechXchange Hackathon Demonstration!**
