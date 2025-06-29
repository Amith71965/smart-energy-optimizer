/**
 * This is the devices route file for the backend of the Smart Energy Optimizer project.
 * It contains the configuration for the devices route, including the import of the express library.
 * It also contains the configuration for the devices route, including the import of the express library.
 *
 * The devices route is used to get the devices, get a specific device, and control a device.
 *
 */
const express = require('express');
const router = express.Router();

// This will be injected by the main server
let orchestrator;

// Initialize with orchestrator instance
router.use((req, res, next) => {
    if (!orchestrator) {
        // Get orchestrator from app locals (set in server.js)
        orchestrator = req.app.locals.orchestrator;
    }
    next();
});

// GET /api/devices - List all devices
router.get('/', (req, res) => {
    try {
        const devices = orchestrator.getDevices();
        res.json({
            status: 'success',
            data: devices,
            count: devices.length
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

// GET /api/devices/:id - Get specific device
router.get('/:id', (req, res) => {
    try {
        const devices = orchestrator.getDevices();
        const device = devices.find(d => d.id === req.params.id);
        
        if (!device) {
            return res.status(404).json({
                status: 'error',
                message: 'Device not found'
            });
        }
        
        res.json({
            status: 'success',
            data: device
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

// POST /api/devices/:id/control - Control device
router.post('/:id/control', (req, res) => {
    try {
        const { action, value } = req.body;
        const result = orchestrator.controlDevice(req.params.id, action, value);
        
        if (result.status === 'error') {
            return res.status(400).json(result);
        }
        
        res.json(result);
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

module.exports = router;