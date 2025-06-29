/**
 * Test Script for IBM watsonx.ai Integration
 * Run this to verify the AI services are working
 */

require('dotenv').config();
const WatsonxService = require('./services/watsonx-service');

async function testWatsonxIntegration() {
    console.log('🧪 Testing IBM watsonx.ai Integration...\n');

    const watsonx = new WatsonxService();

    try {
        // Test 1: Health Check
        console.log('1️⃣ Testing watsonx.ai service health...');
        const health = await watsonx.healthCheck();
        console.log(`   Status: ${health.status}`);
        console.log(`   Message: ${health.message}\n`);

        if (health.status === 'unhealthy') {
            console.log('❌ watsonx.ai service is not healthy. Check your credentials.');
            return;
        }

        // Test 2: Energy Pattern Analysis
        console.log('2️⃣ Testing AI energy pattern analysis...');
        const mockDevices = [
            { id: 'hvac_001', name: 'Living Room Thermostat', type: 'hvac', currentPower: 2800, isOn: true },
            { id: 'water_heater_001', name: 'Water Heater', type: 'water_heater', currentPower: 3200, isOn: true }
        ];
        const mockHistoricalData = Array.from({ length: 20 }, (_, i) => ({
            timestamp: new Date(Date.now() - i * 30000).toISOString(),
            totalPower: 2000 + Math.random() * 1000
        }));

        const analysis = await watsonx.analyzeEnergyPatterns(mockDevices, mockHistoricalData);
        console.log('   AI Analysis Result:');
        console.log(`   - Efficiency Score: ${(analysis.efficiency_score * 100).toFixed(1)}%`);
        console.log(`   - Peak Usage Time: ${analysis.peak_usage_time}`);
        console.log(`   - Insights: ${analysis.insights?.join(', ') || 'None'}\n`);

        // Test 3: Energy Predictions
        console.log('3️⃣ Testing AI energy predictions...');
        const predictions = await watsonx.generateEnergyPredictions(mockDevices, mockHistoricalData, new Date().getHours());
        console.log(`   Generated ${predictions.length} hourly predictions`);
        if (predictions.length > 0) {
            const nextHour = predictions[0];
            console.log(`   Next hour prediction: ${nextHour.predictedUsage?.toFixed(0)}W (${(nextHour.confidence * 100).toFixed(1)}% confidence)`);
        }
        console.log('');

        // Test 4: Optimization Recommendations
        console.log('4️⃣ Testing AI optimization recommendations...');
        const recommendations = await watsonx.generateOptimizationRecommendations(mockDevices, predictions, new Date().getHours());
        console.log(`   Generated ${recommendations.length} recommendations`);
        if (recommendations.length > 0) {
            const topRec = recommendations[0];
            console.log(`   Top recommendation: ${topRec.title}`);
            console.log(`   - Description: ${topRec.description}`);
            console.log(`   - Potential Savings: $${topRec.potentialSavings?.toFixed(2) || '0.00'}`);
        }
        console.log('');

        console.log('✅ All watsonx.ai integration tests passed!');
        console.log('🤖 Your Smart Energy Optimizer is ready with real AI power!');

    } catch (error) {
        console.error('❌ watsonx.ai integration test failed:', error.message);
        console.log('\n🔧 Troubleshooting:');
        console.log('1. Check your environment variables:');
        console.log('   - WATSONX_API_KEY');
        console.log('   - WATSONX_PROJECT_ID');
        console.log('   - WATSONX_URL');
        console.log('   - WATSONX_MODEL_ID');
        console.log('2. Verify your IBM Cloud credentials are valid');
        console.log('3. Check your internet connection');
        console.log('4. The system will fall back to statistical analysis if AI fails');
    }
}

// Run the test
if (require.main === module) {
    testWatsonxIntegration();
}

module.exports = testWatsonxIntegration; 