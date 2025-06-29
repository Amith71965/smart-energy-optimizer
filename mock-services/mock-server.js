/**
 * DEPRECATED: Mock watsonx.ai service 
 * 
 * This mock service has been REPLACED by real IBM watsonx.ai integration.
 * The real AI services are now implemented in:
 * - backend/services/watsonx-service.js
 * - backend/agents/real-*.js
 * 
 * This file is kept for reference only.
 */

const express = require('express');
const app = express();

app.use(express.json());

// Deprecated notice endpoint
app.get('/', (req, res) => {
    res.json({
        status: 'deprecated',
        message: 'Mock watsonx.ai service has been replaced by real IBM watsonx.ai integration',
        real_integration: {
            location: 'backend/services/watsonx-service.js',
            agents: [
                'backend/agents/real-monitor-agent.js',
                'backend/agents/real-prediction-agent.js', 
                'backend/agents/real-optimization-agent.js'
            ],
            model: 'ibm/granite-3-8b-instruct'
        },
        timestamp: new Date().toISOString()
    });
});

// All other endpoints return deprecation notice
app.use('*', (req, res) => {
    res.status(410).json({
        status: 'gone',
        message: 'This mock service has been replaced by real IBM watsonx.ai integration',
        redirect: 'Use the main backend API at port 3000'
    });
});

const MOCK_PORT = 3001;
app.listen(MOCK_PORT, () => {
    console.log(`⚠️  DEPRECATED: Mock services running on port ${MOCK_PORT}`);
    console.log(`🤖 Real AI services now integrated in main backend (port 3000)`);
    console.log(`🔗 Check: http://localhost:3000/health for real AI status`);
});

module.exports = app;