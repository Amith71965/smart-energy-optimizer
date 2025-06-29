/**
 * Energy routes for the Smart Energy Optimizer backend
 * Handles energy readings, summaries, and analytics data
 */
const express = require('express');
const router = express.Router();

// This will be injected by the main server
let orchestrator;

// Initialize with orchestrator instance
router.use((req, res, next) => {
    if (!orchestrator) {
        orchestrator = req.app.locals.orchestrator;
    }
    next();
});

// GET /api/energy/current - Get current energy reading
router.get('/current', (req, res) => {
    try {
        const currentReading = orchestrator.getCurrentEnergyReading();
        res.json({
            status: 'success',
            data: currentReading,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

// GET /api/energy/summary - Get energy summary
router.get('/summary', (req, res) => {
    try {
        const summary = orchestrator.getEnergySummary();
        res.json({
            status: 'success',
            data: summary
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

// GET /api/energy/analytics - Get analytics data for charts
router.get('/analytics', (req, res) => {
    try {
        const { timeRange = '24h', chartType = 'usage' } = req.query;
        const analyticsData = generateAnalyticsData(timeRange, chartType);
        
        res.json({
            status: 'success',
            data: analyticsData,
            timeRange,
            chartType,
            generatedAt: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

// GET /api/energy/history - Get historical energy data
router.get('/history', (req, res) => {
    try {
        const { hours = 24 } = req.query;
        const historyData = generateHistoricalData(parseInt(hours));
        
        res.json({
            status: 'success',
            data: historyData,
            hours: parseInt(hours),
            generatedAt: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

// Add this route to energy.js
router.post('/reading', (req, res) => {
    try {
        console.log('📊 Received energy reading:', req.body);
        // Store the reading (in real app, would save to database)
        res.json({
            status: 'success',
            message: 'Reading received'
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

// Helper function to generate analytics data
function generateAnalyticsData(timeRange, chartType) {
    const now = new Date();
    let dataPoints = [];
    let intervalMs, count;
    
    switch (timeRange) {
        case '24h':
            intervalMs = 60 * 60 * 1000; // 1 hour
            count = 24;
            break;
        case '7d':
            intervalMs = 24 * 60 * 60 * 1000; // 1 day
            count = 7;
            break;
        case '30d':
            intervalMs = 24 * 60 * 60 * 1000; // 1 day
            count = 30;
            break;
        default:
            intervalMs = 60 * 60 * 1000;
            count = 24;
    }
    
    for (let i = 0; i < count; i++) {
        const timestamp = new Date(now.getTime() - (i * intervalMs));
        const value = generateRealisticValue(chartType, timestamp, timeRange);
        
        dataPoints.unshift({
            timestamp: timestamp.toISOString(),
            value: value,
            type: chartType
        });
    }
    
    return dataPoints;
}

// Helper function to generate realistic values based on chart type and time
function generateRealisticValue(chartType, timestamp, timeRange) {
    const hour = timestamp.getHours();
    const dayOfWeek = timestamp.getDay();
    const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;
    
    switch (chartType) {
        case 'usage':
            // Energy usage patterns
            let baseUsage;
            if (timeRange === '24h') {
                // Hourly patterns
                if (hour >= 7 && hour <= 9) {
                    baseUsage = 4.2; // Morning peak
                } else if (hour >= 18 && hour <= 22) {
                    baseUsage = 4.8; // Evening peak
                } else if (hour >= 23 || hour <= 6) {
                    baseUsage = 1.2; // Night low
                } else {
                    baseUsage = 2.8; // Daytime normal
                }
            } else {
                // Daily/monthly patterns
                baseUsage = isWeekend ? 3.2 : 3.8;
            }
            
            // Add realistic variation
            const variation = (Math.random() - 0.5) * 0.6;
            return Math.max(0.5, baseUsage + variation);
            
        case 'cost':
            // Cost follows usage with rate variations
            const usageValue = generateRealisticValue('usage', timestamp, timeRange);
            let rateMultiplier = 1.0;
            
            // Peak rate hours (higher cost per kWh)
            if (timeRange === '24h' && ((hour >= 7 && hour <= 9) || (hour >= 18 && hour <= 22))) {
                rateMultiplier = 1.4;
            }
            
            return usageValue * 0.16 * rateMultiplier;
            
        case 'efficiency':
            // Efficiency is generally inverse to peak usage
            let baseEfficiency;
            if (timeRange === '24h') {
                if (hour >= 7 && hour <= 9 || hour >= 18 && hour <= 22) {
                    baseEfficiency = 72; // Lower during peak
                } else if (hour >= 23 || hour <= 6) {
                    baseEfficiency = 88; // Higher at night
                } else {
                    baseEfficiency = 80; // Normal during day
                }
            } else {
                baseEfficiency = isWeekend ? 82 : 78;
            }
            
            const efficiencyVariation = (Math.random() - 0.5) * 8;
            return Math.max(60, Math.min(95, baseEfficiency + efficiencyVariation));
            
        default:
            return Math.random() * 5;
    }
}

// Helper function to generate historical energy readings
function generateHistoricalData(hours) {
    const now = new Date();
    const data = [];
    
    for (let i = 0; i < hours; i++) {
        const timestamp = new Date(now.getTime() - (i * 60 * 60 * 1000));
        const devices = orchestrator ? orchestrator.getDevices() : [];
        
        // Generate realistic power readings for each device
        const deviceReadings = devices.map(device => {
            let power = 0;
            const hour = timestamp.getHours();
            
            switch (device.type) {
                case 'hvac':
                    // HVAC varies with time of day and season
                    if (hour >= 7 && hour <= 9 || hour >= 18 && hour <= 22) {
                        power = Math.random() * 2000 + 2000; // 2-4 kW during peak
                    } else if (hour >= 23 || hour <= 6) {
                        power = Math.random() * 800 + 200; // 0.2-1 kW at night
                    } else {
                        power = Math.random() * 1200 + 800; // 0.8-2 kW normal
                    }
                    break;
                    
                case 'water_heater':
                    // Water heater cycles
                    if (Math.random() > 0.7) {
                        power = Math.random() * 1000 + 3000; // 3-4 kW when heating
                    } else {
                        power = Math.random() * 200 + 50; // 50-250W standby
                    }
                    break;
                    
                case 'lighting':
                    // Lighting follows occupancy patterns
                    if (hour >= 18 && hour <= 23) {
                        power = Math.random() * 300 + 200; // 200-500W evening
                    } else if (hour >= 6 && hour <= 8) {
                        power = Math.random() * 200 + 150; // 150-350W morning
                    } else if (hour >= 9 && hour <= 17) {
                        power = Math.random() * 100 + 50; // 50-150W day
                    } else {
                        power = Math.random() * 50 + 10; // 10-60W night
                    }
                    break;
                    
                case 'appliance':
                    // Appliances run occasionally
                    if (Math.random() > 0.85) {
                        power = Math.random() * 1500 + 500; // 500W-2kW when running
                    } else {
                        power = Math.random() * 20 + 5; // 5-25W standby
                    }
                    break;
                    
                default:
                    power = Math.random() * 1000;
            }
            
            return {
                id: device.id,
                power: Math.round(power),
                isOn: power > 100
            };
        });
        
        const totalPower = deviceReadings.reduce((sum, device) => sum + device.power, 0);
        
        data.unshift({
            timestamp: timestamp.toISOString(),
            totalPower,
            devices: deviceReadings
        });
    }
    
    return data;
}

module.exports = router;