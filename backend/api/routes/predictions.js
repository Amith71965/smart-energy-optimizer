const express = require('express');
const router = express.Router();

let orchestrator;

router.use((req, res, next) => {
    orchestrator = req.app.locals.orchestrator;
    next();
});

// GET /api/predictions - Get energy predictions
router.get('/', (req, res) => {
    try {
        const { hours = 24 } = req.query;
        let predictions = orchestrator.getPredictions();
        
        // Limit to specified hours
        predictions = predictions.slice(0, hours);
        
        res.json({
            status: 'success',
            data: predictions,
            count: predictions.length,
            generatedAt: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

// POST /api/predictions/generate - Force generate new predictions
router.post('/generate', async (req, res) => {
    try {
        await orchestrator.generatePredictions();
        const predictions = orchestrator.getPredictions();
        
        res.json({
            status: 'success',
            message: 'Predictions generated successfully',
            data: predictions,
            generatedAt: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

module.exports = router;