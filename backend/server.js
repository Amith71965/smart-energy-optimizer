/**
 * This is the main server file for the backend of the Smart Energy Optimizer project.
 * It contains the configuration for the server, including the import of the routes,
 * services, and middleware.
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const WebSocket = require('ws');
const http = require('http');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Import routes
const deviceRoutes = require('./api/routes/devices');
const energyRoutes = require('./api/routes/energy');
const predictionRoutes = require('./api/routes/predictions');
const optimizationRoutes = require('./api/routes/optimization');

// Import services - REAL AI ORCHESTRATOR
const { RealEnergyManagementOrchestrator } = require('./agents/real-orchestrator');

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Initialize REAL AI orchestrator and attach to app
const orchestrator = new RealEnergyManagementOrchestrator();
app.locals.orchestrator = orchestrator;

// Root welcome message
app.get('/', (req, res) => {
    res.json({
        message: "Welcome to the Smart Energy Optimizer API - Powered by IBM watsonx.ai!",
        status: "healthy",
        timestamp: new Date().toISOString(),
        ai_integration: "IBM watsonx.ai",
        documentation: "Check the /health endpoint for service status."
    });
});

// Routes
app.use('/api/devices', deviceRoutes);
app.use('/api/energy', energyRoutes);
app.use('/api/predictions', predictionRoutes);
app.use('/api/optimization', optimizationRoutes);

// Health check with AI system status
app.get('/health', async (req, res) => {
    try {
        const systemStats = orchestrator.getSystemStats();
        
        res.json({ 
            status: 'healthy', 
            timestamp: new Date().toISOString(),
            ai_integration: 'IBM watsonx.ai',
            services: {
                api: 'running',
                websocket: 'running',
                ai_system: systemStats.system_health,
                watsonx_service: 'integrated'
            },
            system_stats: systemStats
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// WebSocket for real-time updates
wss.on('connection', (ws) => {
    console.log('📱 Client connected to WebSocket');
    
    ws.on('message', (message) => {
        console.log('📥 Received:', message.toString());
    });
    
    ws.on('close', () => {
        console.log('📱 Client disconnected');
    });
});

// Broadcast real-time data to all connected clients
function broadcastToClients(data) {
    wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
        }
    });
}

// Start background processes
orchestrator.startRealTimeProcessing(broadcastToClients);

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`🚀 Energy Optimizer API server running on port ${PORT}`);
    console.log(`📊 WebSocket server running on port ${PORT}`);
    console.log(`🤖 IBM watsonx.ai integration active`);
    console.log(`🔗 API docs: http://localhost:${PORT}/health`);
    console.log(`🌟 Real AI agents: Monitor, Prediction, Optimization`);
});

module.exports = app;