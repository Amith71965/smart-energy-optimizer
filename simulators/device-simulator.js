const axios = require('axios');
const { v4: uuidv4 } = require('uuid');

class SmartHomeSimulator {
    constructor() {
        this.devices = this.initializeDevices();
        this.isRunning = false;
        this.backendUrl = process.env.BACKEND_URL || 'http://localhost:3000';
    }

    initializeDevices() {
        return [
            {
                id: 'hvac_001',
                name: 'Living Room Thermostat',
                type: 'hvac',
                location: 'living_room',
                baseConsumption: 3000,
                currentState: 'on',
                targetTemp: 72
            },
            {
                id: 'water_heater_001',
                name: 'Water Heater',
                type: 'water_heater',
                location: 'basement',
                baseConsumption: 4000,
                currentState: 'on'
            },
            {
                id: 'lighting_001',
                name: 'Kitchen Lights',
                type: 'lighting',
                location: 'kitchen',
                baseConsumption: 200,
                currentState: 'on',
                brightness: 100
            },
            {
                id: 'washer_001',
                name: 'Washing Machine',
                type: 'appliance',
                location: 'laundry_room',
                baseConsumption: 2200,
                currentState: 'off'
            }
        ];
    }

    generateRealisticData(device) {
        const now = new Date();
        const hour = now.getHours();
        
        // Time-based usage patterns
        let usageMultiplier = 1.0;
        
        // Peak hours (7-9 AM, 6-9 PM)
        if ((hour >= 7 && hour <= 9) || (hour >= 18 && hour <= 21)) {
            usageMultiplier = 1.8;
        }
        // Off-peak hours (11 PM - 6 AM)
        else if (hour >= 23 || hour <= 6) {
            usageMultiplier = 0.3;
        }
        
        // Device-specific patterns
        if (device.type === 'lighting') {
            // Lights used more in evening/night
            usageMultiplier *= (hour >= 17 || hour <= 7) ? 1.5 : 0.2;
        } else if (device.type === 'water_heater') {
            // Water heater has morning and evening peaks
            usageMultiplier *= ((hour >= 6 && hour <= 8) || (hour >= 18 && hour <= 22)) ? 1.3 : 0.7;
        }
        
        // Random variation
        const randomFactor = 0.8 + (Math.random() * 0.4);
        
        const powerWatts = device.currentState === 'on' 
            ? device.baseConsumption * usageMultiplier * randomFactor
            : 0;

        return {
            deviceId: device.id,
            deviceType: device.type,
            location: device.location,
            timestamp: now.toISOString(),
            powerWatts: Math.round(powerWatts * 100) / 100,
            energyKwh: Math.round((powerWatts / 1000) * 100) / 100,
            state: device.currentState,
            metadata: this.getDeviceMetadata(device)
        };
    }

    getDeviceMetadata(device) {
        const metadata = {};
        
        if (device.type === 'hvac') {
            metadata.temperature = 70 + (Math.random() * 6); // 70-76°F
            metadata.targetTemp = device.targetTemp || 72;
            metadata.mode = 'auto';
        } else if (device.type === 'lighting') {
            metadata.brightness = device.brightness || 100;
            metadata.colorTemp = 3000; // Warm white
        } else if (device.type === 'water_heater') {
            metadata.waterTemp = 120 + (Math.random() * 20); // 120-140°F
            metadata.targetTemp = 140;
        }
        
        return metadata;
    }

    async sendDataToBackend(data) {
        try {
            // Send to energy data endpoint
            await axios.post(`${this.backendUrl}/api/energy/reading`, data);
            console.log(`📊 Sent data for ${data.deviceId}: ${data.powerWatts}W`);
        } catch (error) {
            console.error(`❌ Failed to send data for ${data.deviceId}:`, error.message);
        }
    }

    start() {
        console.log('🏠 Starting Smart Home Device Simulators...');
        console.log(`📡 Backend URL: ${this.backendUrl}`);
        console.log(`📊 Simulating ${this.devices.length} devices`);
        
        this.isRunning = true;
        
        // Send data every 30 seconds
        this.dataInterval = setInterval(() => {
            if (this.isRunning) {
                this.devices.forEach(device => {
                    const data = this.generateRealisticData(device);
                    this.sendDataToBackend(data);
                });
            }
        }, 30000);

        // Randomly change device states to simulate real usage
        this.stateInterval = setInterval(() => {
            if (this.isRunning) {
                this.randomlyChangeDeviceStates();
            }
        }, 300000); // Every 5 minutes

        console.log('✅ Simulators started successfully');
        console.log('📈 Sending data every 30 seconds');
        console.log('🎛️ Random state changes every 5 minutes');
    }

    randomlyChangeDeviceStates() {
        // Randomly turn devices on/off to simulate real usage
        this.devices.forEach(device => {
            if (Math.random() < 0.1) { // 10% chance
                device.currentState = device.currentState === 'on' ? 'off' : 'on';
                console.log(`🎛️ ${device.name} turned ${device.currentState}`);
            }
        });
    }

    stop() {
        console.log('🛑 Stopping simulators...');
        this.isRunning = false;
        if (this.dataInterval) clearInterval(this.dataInterval);
        if (this.stateInterval) clearInterval(this.stateInterval);
        console.log('✅ Simulators stopped');
    }
}

// Start simulator
const simulator = new SmartHomeSimulator();
simulator.start();

// Graceful shutdown
process.on('SIGINT', () => {
    simulator.stop();
    process.exit(0);
});

module.exports = SmartHomeSimulator;