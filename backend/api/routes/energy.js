const express = require('express');
const router = express.Router();

let orchestrator;

router.use((req, res, next) => {
    orchestrator = req.app.locals.orchestrator;
    next();
});

// GET /api/energy/current - Get current energy readings
router.get('/current', (req, res) => {
    try {
        const readings = orchestrator.getEnergyReadings();
        const latest = readings[readings.length - 1] || null;
        
        res.json({
            status: 'success',
            data: latest,
            timestamp: new Date().toISOString()
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
        const { hours = 24, deviceId } = req.query;
        let readings = orchestrator.getEnergyReadings();
        
        // Filter by device if specified
        if (deviceId) {
            readings = readings.filter(r => 
                r.devices.some(d => d.id === deviceId)
            );
        }
        
        // Limit to specified hours
        const hoursAgo = new Date(Date.now() - hours * 60 * 60 * 1000);
        readings = readings.filter(r => new Date(r.timestamp) >= hoursAgo);
        
        res.json({
            status: 'success',
            data: readings,
            count: readings.length,
            period: `${hours} hours`
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

// GET /api/energy/summary - Get energy usage summary
router.get('/summary', (req, res) => {
    try {
        const devices = orchestrator.getDevices();
        const readings = orchestrator.getEnergyReadings();
        
        const summary = {
            totalCurrentUsage: devices.reduce((sum, d) => sum + d.currentPower, 0),
            totalTodaysCost: devices.reduce((sum, d) => sum + d.todaysCost, 0),
            totalTodaysUsage: devices.reduce((sum, d) => sum + d.todaysUsage, 0),
            activeDevices: devices.filter(d => d.isOn).length,
            totalDevices: devices.length,
            lastUpdated: readings.length > 0 ? readings[readings.length - 1].timestamp : null
        };
        
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

module.exports = router;