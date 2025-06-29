/**
 * Real AI Energy Management Orchestrator - Powered by IBM watsonx.ai
 * Replaces mock orchestrator with actual AI coordination
 */

const EnergyMonitorAgent = require('./real-monitor-agent');
const EnergyPredictionAgent = require('./real-prediction-agent');
const EnergyOptimizationAgent = require('./real-optimization-agent');

class RealEnergyManagementOrchestrator {
    constructor() {
        // Initialize real AI agents
        this.monitorAgent = new EnergyMonitorAgent();
        this.predictionAgent = new EnergyPredictionAgent();
        this.optimizationAgent = new EnergyOptimizationAgent();
        
        // Data storage
        this.devices = this.initializeMockDevices();
        this.energyReadings = [];
        this.broadcastCallback = null;
        
        // Agent coordination
        this.agentStatus = {
            monitor: 'initializing',
            prediction: 'initializing',
            optimization: 'initializing'
        };
        
        console.log('🤖 Real AI Energy Management Orchestrator initialized');
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

    async startRealTimeProcessing(broadcastCallback) {
        this.broadcastCallback = broadcastCallback;
        
        console.log('🚀 Starting real AI-powered energy management system...');

        try {
            // Start device data updates
            this.startDeviceUpdates();

            // Start AI agents with coordination
            await this.startAIAgents();

            // Start agent coordination
            this.startAgentCoordination();

            console.log('✅ Real AI energy management system started successfully');
            console.log('🔍 Monitor Agent: AI-powered energy analysis');
            console.log('🔮 Prediction Agent: AI-powered forecasting');
            console.log('💡 Optimization Agent: AI-powered recommendations');

        } catch (error) {
            console.error('❌ Failed to start AI energy management system:', error.message);
            throw error;
        }
    }

    startDeviceUpdates() {
        // Update device data every 30 seconds
        setInterval(() => {
            this.updateDeviceReadings();
        }, 30000);
        
        console.log('📊 Device data updates started');
    }

    async startAIAgents() {
        try {
            // Start monitor agent
            await this.monitorAgent.startMonitoring(
                this.devices,
                () => this.energyReadings,
                (analysis) => this.handleAnalysisUpdate(analysis)
            );
            this.agentStatus.monitor = 'running';

            // Start prediction agent
            await this.predictionAgent.startPredictions(
                this.devices,
                () => this.energyReadings,
                (predictions) => this.handlePredictionsUpdate(predictions)
            );
            this.agentStatus.prediction = 'running';

            // Start optimization agent
            await this.optimizationAgent.startOptimization(
                this.devices,
                () => this.predictionAgent.getPredictions(),
                () => this.energyReadings,
                (recommendations) => this.handleRecommendationsUpdate(recommendations)
            );
            this.agentStatus.optimization = 'running';

            console.log('🤖 All AI agents started successfully');

        } catch (error) {
            console.error('❌ Failed to start AI agents:', error.message);
            throw error;
        }
    }

    startAgentCoordination() {
        // Coordinate agents every 2 minutes
        setInterval(() => {
            this.coordinateAgents();
        }, 2 * 60 * 1000);

        // Health check every 5 minutes
        setInterval(() => {
            this.performHealthCheck();
        }, 5 * 60 * 1000);

        console.log('🔄 Agent coordination started');
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
                
                device.currentPower = Math.round(baseUsage * timeMultiplier * randomFactor);
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
        
        // Keep only last 1000 readings (about 8 hours at 30-second intervals)
        if (this.energyReadings.length > 1000) {
            this.energyReadings = this.energyReadings.slice(-1000);
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

    coordinateAgents() {
        console.log('🔄 Coordinating AI agents...');

        // Check if all agents are running
        const allAgentsRunning = Object.values(this.agentStatus).every(status => status === 'running');
        
        if (!allAgentsRunning) {
            console.warn('⚠️ Not all AI agents are running:', this.agentStatus);
        }

        // Trigger coordinated updates if needed
        const currentAnalysis = this.monitorAgent.getCurrentAnalysis();
        const currentPredictions = this.predictionAgent.getPredictions();
        const currentRecommendations = this.optimizationAgent.getRecommendations();

        // Log coordination status
        console.log('🔄 Agent coordination status:');
        console.log(`   📊 Monitor: ${currentAnalysis ? 'Active' : 'Pending'}`);
        console.log(`   🔮 Predictions: ${currentPredictions.length} forecasts`);
        console.log(`   💡 Recommendations: ${currentRecommendations.length} active`);
    }

    async performHealthCheck() {
        console.log('🏥 Performing AI system health check...');

        try {
            const healthChecks = await Promise.all([
                this.monitorAgent.healthCheck(),
                this.predictionAgent.healthCheck(),
                this.optimizationAgent.healthCheck()
            ]);

            const [monitorHealth, predictionHealth, optimizationHealth] = healthChecks;

            console.log('🏥 AI System Health Status:');
            console.log(`   🔍 Monitor Agent: ${monitorHealth.status} - ${monitorHealth.message}`);
            console.log(`   🔮 Prediction Agent: ${predictionHealth.status} - ${predictionHealth.message}`);
            console.log(`   💡 Optimization Agent: ${optimizationHealth.status} - ${optimizationHealth.message}`);

            // Update agent status
            this.agentStatus.monitor = monitorHealth.status === 'healthy' ? 'running' : 'degraded';
            this.agentStatus.prediction = predictionHealth.status === 'healthy' ? 'running' : 'degraded';
            this.agentStatus.optimization = optimizationHealth.status === 'healthy' ? 'running' : 'degraded';

            // Broadcast health status
            if (this.broadcastCallback) {
                this.broadcastCallback({
                    type: 'system_health',
                    data: {
                        overall_status: this.getOverallSystemHealth(),
                        agents: {
                            monitor: monitorHealth,
                            prediction: predictionHealth,
                            optimization: optimizationHealth
                        },
                        timestamp: new Date().toISOString()
                    }
                });
            }

        } catch (error) {
            console.error('❌ Health check failed:', error.message);
        }
    }

    getOverallSystemHealth() {
        const statuses = Object.values(this.agentStatus);
        
        if (statuses.every(s => s === 'running')) return 'healthy';
        if (statuses.some(s => s === 'running')) return 'degraded';
        return 'unhealthy';
    }

    handleAnalysisUpdate(analysis) {
        console.log('📊 Received AI analysis update');
        
        if (this.broadcastCallback) {
            this.broadcastCallback({
                type: 'analysis_update',
                data: analysis
            });
        }
    }

    handlePredictionsUpdate(predictionsData) {
        console.log('🔮 Received AI predictions update');
        
        if (this.broadcastCallback) {
            this.broadcastCallback({
                type: 'predictions_update',
                data: predictionsData.predictions
            });
        }
    }

    handleRecommendationsUpdate(recommendationsData) {
        console.log('💡 Received AI recommendations update');
        
        if (this.broadcastCallback) {
            this.broadcastCallback({
                type: 'recommendations_update',
                data: recommendationsData.recommendations
            });
        }
    }

    // API methods for external access
    getDevices() {
        return this.devices;
    }

    getEnergyReadings() {
        return this.energyReadings;
    }

    getPredictions() {
        return this.predictionAgent.getPredictions();
    }

    getRecommendations() {
        return this.optimizationAgent.getRecommendations();
    }

    getCurrentAnalysis() {
        return this.monitorAgent.getCurrentAnalysis();
    }

    async applyRecommendation(recommendationId) {
        return await this.optimizationAgent.applyRecommendation(
            recommendationId,
            (deviceId, action, value) => this.controlDevice(deviceId, action, value)
        );
    }

    controlDevice(deviceId, action, value = null) {
        const device = this.devices.find(d => d.id === deviceId);
        if (!device) return { success: false, message: 'Device not found' };

        console.log(`🎛️ Controlling device ${device.name}: ${action}${value ? ` = ${value}` : ''}`);

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
                    device.targetTemp = parseInt(value);
                }
                break;
            case 'set_brightness':
                if (device.type === 'lighting') {
                    device.brightness = parseInt(value);
                    device.currentPower = (device.currentPower / device.brightness) * parseInt(value);
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

        return { success: true, device };
    }

    getSystemStats() {
        return {
            total_devices: this.devices.length,
            active_devices: this.devices.filter(d => d.isOn).length,
            total_power: this.devices.reduce((sum, d) => sum + d.currentPower, 0),
            daily_cost: this.devices.reduce((sum, d) => sum + d.todaysCost, 0),
            energy_readings_count: this.energyReadings.length,
            predictions_count: this.predictionAgent.getPredictions().length,
            recommendations_count: this.optimizationAgent.getRecommendations().length,
            agent_status: this.agentStatus,
            system_health: this.getOverallSystemHealth()
        };
    }
}

module.exports = { RealEnergyManagementOrchestrator }; 