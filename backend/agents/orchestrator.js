/**
 * This is the orchestrator file for the backend of the Smart Energy Optimizer project.
 * It contains the configuration for the orchestrator, including the import of the node-cron library.
 * It also contains the configuration for the orchestrator, including the import of the node-cron library.
 *
 * The orchestrator is used to orchestrate the AI agents, the IoT platform, and the energy data service.
 *
 */
const cron = require('node-cron');

class EnergyManagementOrchestrator {
    constructor() {
        this.devices = this.initializeMockDevices();
        this.energyReadings = [];
        this.predictions = [];
        this.recommendations = [];
        this.broadcastCallback = null;
    }

    initializeMockDevices() {
        return [
            {
                id: 'hvac_001',
                name: 'Living Room Thermostat',
                type: 'hvac',
                location: 'Living Room',
                isOn: true,
                currentPower: 2800,
                todaysUsage: 24.5,
                todaysCost: 4.90,
                targetTemp: 72
            },
            {
                id: 'water_heater_001',
                name: 'Water Heater',
                type: 'water_heater',
                location: 'Basement',
                isOn: true,
                currentPower: 3200,
                todaysUsage: 18.2,
                todaysCost: 3.64
            },
            {
                id: 'lighting_001',
                name: 'Kitchen Lights',
                type: 'lighting',
                location: 'Kitchen',
                isOn: true,
                currentPower: 180,
                todaysUsage: 2.1,
                todaysCost: 0.42,
                brightness: 100
            },
            {
                id: 'washer_001',
                name: 'Washing Machine',
                type: 'appliance',
                location: 'Laundry Room',
                isOn: false,
                currentPower: 0,
                todaysUsage: 3.5,
                todaysCost: 0.70
            }
        ];
    }

    startRealTimeProcessing(broadcastCallback) {
        this.broadcastCallback = broadcastCallback;
        
        // Update device data every 30 seconds
        setInterval(() => {
            this.updateDeviceReadings();
        }, 30000);
        
        // Generate predictions every 5 minutes
        setInterval(() => {
            this.generatePredictions();
        }, 300000);
        
        // Generate recommendations every 10 minutes
        setInterval(() => {
            this.generateRecommendations();
        }, 600000);
        
        console.log('🤖 AI orchestrator started with real-time processing');
    }

    updateDeviceReadings() {
        const now = new Date();
        const hour = now.getHours();
        
        // Update each device with realistic usage patterns
        this.devices.forEach(device => {
            if (device.isOn) {
                const baseUsage = this.getBaseUsage(device.type);
                const timeMultiplier = this.getTimeMultiplier(hour);
                const randomFactor = 0.8 + Math.random() * 0.4;
                
                device.currentPower = baseUsage * timeMultiplier * randomFactor;
                device.todaysUsage += device.currentPower / 1000 / 120; // Update every 30 seconds
                device.todaysCost = device.todaysUsage * 0.12;
            } else {
                device.currentPower = 0;
            }
        });

        // Create energy reading
        const totalUsage = this.devices.reduce((sum, device) => sum + device.currentPower, 0);
        const reading = {
            timestamp: now.toISOString(),
            totalPower: totalUsage,
            devices: this.devices.map(d => ({
                id: d.id,
                power: d.currentPower,
                isOn: d.isOn
            }))
        };

        this.energyReadings.push(reading);
        
        // Keep only last 100 readings
        if (this.energyReadings.length > 100) {
            this.energyReadings = this.energyReadings.slice(-100);
        }

        // Broadcast to connected clients
        if (this.broadcastCallback) {
            this.broadcastCallback({
                type: 'energy_update',
                data: reading
            });
        }
    }

    getBaseUsage(deviceType) {
        const baseUsages = {
            hvac: 3000,
            water_heater: 4000,
            lighting: 200,
            appliance: 1500
        };
        return baseUsages[deviceType] || 1000;
    }

    getTimeMultiplier(hour) {
        // Peak hours: 7-9 AM, 6-9 PM
        if ((hour >= 7 && hour <= 9) || (hour >= 18 && hour <= 21)) {
            return 1.8;
        }
        // Off-peak hours: 11 PM - 6 AM
        if (hour >= 23 || hour <= 6) {
            return 0.3;
        }
        return 1.0;
    }

    async generatePredictions() {
        // Mock AI prediction generation
        const predictions = [];
        const currentHour = new Date().getHours();
        
        for (let i = 0; i < 24; i++) {
            const hour = (currentHour + i) % 24;
            const baseUsage = 2000;
            const timeMultiplier = this.getTimeMultiplier(hour);
            const prediction = {
                hour,
                predictedUsage: baseUsage * timeMultiplier,
                predictedCost: (baseUsage * timeMultiplier * 0.12) / 1000,
                confidence: 0.85 + Math.random() * 0.1
            };
            predictions.push(prediction);
        }
        
        this.predictions = predictions;
        
        if (this.broadcastCallback) {
            this.broadcastCallback({
                type: 'predictions_update',
                data: predictions
            });
        }
        
        console.log('🔮 Generated new energy predictions');
    }

    async generateRecommendations() {
        const recommendations = [];
        const hour = new Date().getHours();
        
        // Peak hour optimization
        if (hour >= 17 && hour <= 19) {
            recommendations.push({
                id: 'peak_optimization',
                title: 'Pre-cool Before Peak Hours',
                description: 'Set thermostat to 68°F for next 2 hours to avoid peak rates',
                potentialSavings: 1.25,
                deviceId: 'hvac_001',
                action: 'pre_cool',
                priority: 'high'
            });
        }
        
        // Load shifting
        if (hour >= 20) {
            recommendations.push({
                id: 'load_shift',
                title: 'Delay Washing Machine',
                description: 'Start wash cycle at 11 PM for 30% savings',
                potentialSavings: 0.85,
                deviceId: 'washer_001',
                action: 'delay',
                priority: 'medium'
            });
        }
        
        // Efficiency optimization
        recommendations.push({
            id: 'efficiency',
            title: 'Reduce Kitchen Lighting',
            description: 'Dim lights to 80% for minimal impact',
            potentialSavings: 0.15,
            deviceId: 'lighting_001',
            action: 'dim',
            priority: 'low'
        });
        
        this.recommendations = recommendations;
        
        if (this.broadcastCallback) {
            this.broadcastCallback({
                type: 'recommendations_update',
                data: recommendations
            });
        }
        
        console.log('💡 Generated new optimization recommendations');
    }

    // API methods for external access
    getDevices() {
        return this.devices;
    }

    getEnergyReadings() {
        return this.energyReadings;
    }

    getPredictions() {
        return this.predictions;
    }

    getRecommendations() {
        return this.recommendations;
    }

    controlDevice(deviceId, action, value = null) {
        const device = this.devices.find(d => d.id === deviceId);
        if (!device) return { status: 'error', message: 'Device not found' };

        switch (action) {
            case 'toggle':
                device.isOn = !device.isOn;
                break;
            case 'turn_on':
                device.isOn = true;
                break;
            case 'turn_off':
                device.isOn = false;
                break;
            case 'set_temperature':
                if (device.type === 'hvac') {
                    device.targetTemp = value;
                }
                break;
            case 'set_brightness':
                if (device.type === 'lighting') {
                    device.brightness = value;
                    device.currentPower = (device.currentPower / device.brightness) * value;
                }
                break;
        }

        // Broadcast device update
        if (this.broadcastCallback) {
            this.broadcastCallback({
                type: 'device_update',
                data: device
            });
        }

        return { status: 'success', device };
    }
}

module.exports = { EnergyManagementOrchestrator };