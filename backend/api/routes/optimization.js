const express = require('express');
const router = express.Router();

let orchestrator;

router.use((req, res, next) => {
    orchestrator = req.app.locals.orchestrator;
    next();
});

// GET /api/optimization/recommendations - Get optimization recommendations
router.get('/recommendations', (req, res) => {
    try {
        const recommendations = orchestrator.getRecommendations();
        
        res.json({
            status: 'success',
            data: recommendations,
            count: recommendations.length,
            totalPotentialSavings: recommendations.reduce((sum, r) => sum + r.potentialSavings, 0)
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

// POST /api/optimization/apply - Apply optimization recommendation (AI-powered)
router.post('/apply', async (req, res) => {
    try {
        const { recommendationId } = req.body;
        
        if (!recommendationId) {
            return res.status(400).json({
                status: 'error',
                message: 'recommendationId is required'
            });
        }
        
        // Apply the AI recommendation through the orchestrator
        const result = await orchestrator.applyRecommendation(recommendationId);
        
        if (result.success) {
            res.json({
                status: 'success',
                message: result.message,
                estimated_savings: result.estimated_savings,
                total_tracked_savings: result.total_tracked_savings,
                ai_powered: true,
                timestamp: new Date().toISOString()
            });
        } else {
            res.status(400).json({
                status: 'error',
                message: result.message,
                timestamp: new Date().toISOString()
            });
        }
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// GET /api/optimization/stats - Get AI optimization statistics
router.get('/stats', (req, res) => {
    try {
        const systemStats = orchestrator.getSystemStats();
        
        res.json({
            status: 'success',
            data: {
                ai_integration: 'IBM watsonx.ai',
                system_health: systemStats.system_health,
                agent_status: systemStats.agent_status,
                total_recommendations: systemStats.recommendations_count,
                total_devices: systemStats.total_devices,
                active_devices: systemStats.active_devices,
                total_power: systemStats.total_power,
                daily_cost: systemStats.daily_cost
            },
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

// GET /api/optimization/analysis - Get current AI analysis
router.get('/analysis', (req, res) => {
    try {
        const analysis = orchestrator.getCurrentAnalysis();
        
        res.json({
            status: 'success',
            data: analysis || { message: 'Analysis pending' },
            ai_powered: true,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

module.exports = router;