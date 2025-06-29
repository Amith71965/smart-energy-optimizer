/**
 * Real Energy Prediction Agent - Powered by IBM watsonx.ai
 * Replaces mock predictions with actual AI forecasting
 */

const WatsonxService = require('../services/watsonx-service');

class EnergyPredictionAgent {
    constructor() {
        this.watsonx = new WatsonxService();
        this.predictions = [];
        this.predictionHistory = [];
        this.lastUpdate = null;
        
        console.log('🔮 Energy Prediction Agent initialized with AI');
    }

    /**
     * Start continuous prediction generation
     */
    async startPredictions(devices, getHistoricalData, onPredictionsUpdate) {
        this.devices = devices;
        this.getHistoricalData = getHistoricalData;
        this.onPredictionsUpdate = onPredictionsUpdate;

        // Generate initial predictions
        await this.generatePredictions();

        // Schedule prediction updates every 5 minutes
        setInterval(async () => {
            await this.generatePredictions();
        }, 5 * 60 * 1000);

        console.log('🔮 Energy prediction service started with AI');
    }

    /**
     * Generate 24-hour energy predictions using AI
     */
    async generatePredictions() {
        try {
            const historicalData = this.getHistoricalData();
            if (historicalData.length < 24) {
                console.log('⏳ Insufficient historical data for AI predictions, using baseline...');
                this.predictions = this.generateBaselinePredictions();
                this.notifyUpdate();
                return;
            }

            console.log('🔮 Generating AI-powered energy predictions...');

            const currentHour = new Date().getHours();
            
            // Get AI predictions
            const aiPredictions = await this.watsonx.generateEnergyPredictions(
                this.devices,
                historicalData,
                currentHour
            );

            // Enhance AI predictions with additional analysis
            const enhancedPredictions = this.enhancePredictions(aiPredictions, currentHour);

            // Validate and clean predictions
            this.predictions = this.validatePredictions(enhancedPredictions);

            // Store prediction history for accuracy tracking
            this.storePredictionHistory();

            // Calculate prediction accuracy if we have historical predictions
            const accuracy = this.calculatePredictionAccuracy();

            this.lastUpdate = new Date().toISOString();

            // Notify listeners
            this.notifyUpdate();

            console.log('✅ AI energy predictions generated');
            console.log(`📊 Generated ${this.predictions.length} hourly predictions`);
            if (accuracy) {
                console.log(`🎯 Prediction accuracy: ${(accuracy * 100).toFixed(1)}%`);
            }

        } catch (error) {
            console.error('❌ AI prediction generation failed:', error.message);
            
            // Fallback to statistical predictions
            this.predictions = this.generateStatisticalPredictions();
            this.lastUpdate = new Date().toISOString();
            this.notifyUpdate();
        }
    }

    /**
     * Enhance AI predictions with additional context
     */
    enhancePredictions(aiPredictions, currentHour) {
        return aiPredictions.map((prediction, index) => {
            const hour = (currentHour + index) % 24;
            const timeContext = this.getTimeContext(hour);
            const weatherFactor = this.getWeatherFactor(hour);
            const seasonalFactor = this.getSeasonalFactor();

            return {
                ...prediction,
                hour: hour,
                time_context: timeContext,
                weather_factor: weatherFactor,
                seasonal_factor: seasonalFactor,
                peak_probability: this.calculatePeakProbability(hour, prediction.predictedUsage),
                cost_tier: this.getCostTier(hour),
                confidence_adjusted: this.adjustConfidence(prediction.confidence, timeContext),
                generated_at: new Date().toISOString()
            };
        });
    }

    /**
     * Validate and clean prediction data
     */
    validatePredictions(predictions) {
        return predictions.filter(p => {
            // Filter out invalid predictions
            return p.predictedUsage > 0 && 
                   p.predictedUsage < 20000 && // Reasonable max for home
                   p.confidence > 0 && 
                   p.confidence <= 1;
        }).map(p => ({
            ...p,
            // Ensure reasonable bounds
            predictedUsage: Math.max(500, Math.min(15000, p.predictedUsage)),
            predictedCost: Math.max(0.1, Math.min(5.0, p.predictedCost)),
            confidence: Math.max(0.3, Math.min(1.0, p.confidence))
        }));
    }

    /**
     * Generate baseline predictions when AI is unavailable
     */
    generateBaselinePredictions() {
        const predictions = [];
        const currentHour = new Date().getHours();
        
        for (let i = 0; i < 24; i++) {
            const hour = (currentHour + i) % 24;
            const baseUsage = this.calculateBaselineUsage(hour);
            
            predictions.push({
                hour: hour,
                predictedUsage: baseUsage,
                predictedCost: (baseUsage * 0.12) / 1000,
                confidence: 0.7,
                factors: this.getTimeContext(hour),
                time_context: this.getTimeContext(hour),
                peak_probability: this.calculatePeakProbability(hour, baseUsage),
                cost_tier: this.getCostTier(hour),
                source: 'baseline',
                generated_at: new Date().toISOString()
            });
        }
        
        return predictions;
    }

    /**
     * Generate statistical predictions based on historical patterns
     */
    generateStatisticalPredictions() {
        const historicalData = this.getHistoricalData();
        const predictions = [];
        const currentHour = new Date().getHours();

        // Calculate hourly averages from historical data
        const hourlyPatterns = this.calculateHourlyPatterns(historicalData);

        for (let i = 0; i < 24; i++) {
            const hour = (currentHour + i) % 24;
            const historicalAvg = hourlyPatterns[hour] || 2000;
            const trendFactor = this.calculateTrendFactor(historicalData);
            const predictedUsage = historicalAvg * trendFactor;

            predictions.push({
                hour: hour,
                predictedUsage: predictedUsage,
                predictedCost: (predictedUsage * 0.12) / 1000,
                confidence: 0.75,
                factors: this.getTimeContext(hour),
                time_context: this.getTimeContext(hour),
                peak_probability: this.calculatePeakProbability(hour, predictedUsage),
                cost_tier: this.getCostTier(hour),
                source: 'statistical',
                generated_at: new Date().toISOString()
            });
        }

        return predictions;
    }

    /**
     * Calculate hourly usage patterns from historical data
     */
    calculateHourlyPatterns(historicalData) {
        const hourlyData = {};
        
        historicalData.forEach(reading => {
            const hour = new Date(reading.timestamp).getHours();
            if (!hourlyData[hour]) hourlyData[hour] = [];
            hourlyData[hour].push(reading.totalPower);
        });

        const hourlyAverages = {};
        Object.entries(hourlyData).forEach(([hour, values]) => {
            hourlyAverages[hour] = values.reduce((sum, val) => sum + val, 0) / values.length;
        });

        return hourlyAverages;
    }

    /**
     * Calculate trend factor based on recent data
     */
    calculateTrendFactor(historicalData) {
        if (historicalData.length < 48) return 1.0;

        const recent = historicalData.slice(-24);
        const previous = historicalData.slice(-48, -24);

        const recentAvg = recent.reduce((sum, r) => sum + r.totalPower, 0) / recent.length;
        const previousAvg = previous.reduce((sum, r) => sum + r.totalPower, 0) / previous.length;

        return recentAvg / previousAvg;
    }

    /**
     * Calculate baseline usage for a given hour
     */
    calculateBaselineUsage(hour) {
        const baseUsage = 2000;
        const timeMultiplier = this.getTimeMultiplier(hour);
        const randomFactor = 0.9 + Math.random() * 0.2; // Small random variation
        
        return baseUsage * timeMultiplier * randomFactor;
    }

    /**
     * Get time multiplier for different hours
     */
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

    /**
     * Get time context for an hour
     */
    getTimeContext(hour) {
        if (hour >= 6 && hour <= 9) return "morning_peak";
        if (hour >= 10 && hour <= 16) return "daytime_normal";
        if (hour >= 17 && hour <= 21) return "evening_peak";
        if (hour >= 22 && hour <= 23) return "night_transition";
        return "overnight_low";
    }

    /**
     * Get weather factor (simplified - could integrate with weather API)
     */
    getWeatherFactor(hour) {
        // Simulate weather impact
        const season = this.getCurrentSeason();
        if (season === 'summer' && (hour >= 12 && hour <= 18)) {
            return 1.3; // Higher AC usage
        }
        if (season === 'winter' && (hour >= 6 && hour <= 9 || hour >= 17 && hour <= 22)) {
            return 1.2; // Higher heating usage
        }
        return 1.0;
    }

    /**
     * Get seasonal factor
     */
    getSeasonalFactor() {
        const month = new Date().getMonth();
        if (month >= 5 && month <= 8) return 1.2; // Summer
        if (month >= 11 || month <= 2) return 1.1; // Winter
        return 1.0; // Spring/Fall
    }

    /**
     * Get current season
     */
    getCurrentSeason() {
        const month = new Date().getMonth();
        if (month >= 2 && month <= 4) return 'spring';
        if (month >= 5 && month <= 7) return 'summer';
        if (month >= 8 && month <= 10) return 'fall';
        return 'winter';
    }

    /**
     * Calculate peak probability for an hour
     */
    calculatePeakProbability(hour, usage) {
        const isPeakHour = (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 21);
        const usageThreshold = 3000;
        
        let probability = 0.1; // Base probability
        
        if (isPeakHour) probability += 0.6;
        if (usage > usageThreshold) probability += 0.3;
        
        return Math.min(1.0, probability);
    }

    /**
     * Get cost tier for an hour
     */
    getCostTier(hour) {
        if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 21)) {
            return 'peak';
        }
        if (hour >= 23 || hour <= 6) {
            return 'off_peak';
        }
        return 'standard';
    }

    /**
     * Adjust confidence based on time context
     */
    adjustConfidence(baseConfidence, timeContext) {
        const adjustments = {
            'morning_peak': 0.9,
            'evening_peak': 0.9,
            'daytime_normal': 0.95,
            'night_transition': 0.85,
            'overnight_low': 0.8
        };
        
        return Math.min(1.0, baseConfidence * (adjustments[timeContext] || 1.0));
    }

    /**
     * Store prediction history for accuracy tracking
     */
    storePredictionHistory() {
        const historyEntry = {
            timestamp: new Date().toISOString(),
            predictions: this.predictions.map(p => ({
                hour: p.hour,
                predicted_usage: p.predictedUsage,
                confidence: p.confidence
            }))
        };

        this.predictionHistory.push(historyEntry);

        // Keep only last 48 hours of predictions
        if (this.predictionHistory.length > 48) {
            this.predictionHistory = this.predictionHistory.slice(-48);
        }
    }

    /**
     * Calculate prediction accuracy
     */
    calculatePredictionAccuracy() {
        if (this.predictionHistory.length < 2) return null;

        const historicalData = this.getHistoricalData();
        if (historicalData.length < 24) return null;

        // Compare predictions from 1 hour ago with actual usage
        const oneHourAgo = this.predictionHistory.find(h => {
            const hoursDiff = (Date.now() - new Date(h.timestamp).getTime()) / (1000 * 60 * 60);
            return hoursDiff >= 0.9 && hoursDiff <= 1.1;
        });

        if (!oneHourAgo) return null;

        const currentHour = new Date().getHours();
        const prediction = oneHourAgo.predictions.find(p => p.hour === currentHour);
        const actual = historicalData[historicalData.length - 1]?.totalPower;

        if (!prediction || !actual) return null;

        const error = Math.abs(prediction.predicted_usage - actual) / actual;
        return Math.max(0, 1 - error);
    }

    /**
     * Notify listeners of prediction updates
     */
    notifyUpdate() {
        if (this.onPredictionsUpdate) {
            this.onPredictionsUpdate({
                predictions: this.predictions,
                last_update: this.lastUpdate,
                next_update: new Date(Date.now() + 5 * 60 * 1000).toISOString()
            });
        }
    }

    /**
     * Get current predictions
     */
    getPredictions() {
        return this.predictions;
    }

    /**
     * Get prediction for specific hour
     */
    getPredictionForHour(hour) {
        return this.predictions.find(p => p.hour === hour);
    }

    /**
     * Get peak usage predictions
     */
    getPeakPredictions() {
        return this.predictions
            .filter(p => p.peak_probability > 0.7)
            .sort((a, b) => b.predictedUsage - a.predictedUsage);
    }

    /**
     * Health check for the prediction agent
     */
    async healthCheck() {
        const watsonxHealth = await this.watsonx.healthCheck();
        
        return {
            status: watsonxHealth.status,
            message: `Prediction Agent: ${watsonxHealth.message}`,
            last_update: this.lastUpdate,
            predictions_count: this.predictions.length,
            history_count: this.predictionHistory.length
        };
    }
}

module.exports = EnergyPredictionAgent; 