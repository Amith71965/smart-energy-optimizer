/**
 * Real Energy Monitor Agent - Powered by IBM watsonx.ai
 * Replaces mock monitoring with actual AI analysis
 */

const WatsonxService = require('../services/watsonx-service');

class EnergyMonitorAgent {
    constructor() {
        this.watsonx = new WatsonxService();
        this.analysisHistory = [];
        this.lastAnalysis = null;
        this.anomalyThreshold = 0.3; // 30% deviation triggers anomaly
        
        console.log('🔍 Energy Monitor Agent initialized with AI');
    }

    /**
     * Continuously monitor energy patterns using AI
     */
    async startMonitoring(devices, getHistoricalData, onAnalysisUpdate) {
        this.devices = devices;
        this.getHistoricalData = getHistoricalData;
        this.onAnalysisUpdate = onAnalysisUpdate;

        // Run initial analysis
        await this.performAnalysis();

        // Schedule regular analysis every 5 minutes
        setInterval(async () => {
            await this.performAnalysis();
        }, 5 * 60 * 1000);

        console.log('🔍 Energy monitoring started with AI analysis');
    }

    /**
     * Perform comprehensive energy analysis using AI
     */
    async performAnalysis() {
        try {
            const historicalData = this.getHistoricalData();
            if (historicalData.length < 10) {
                console.log('⏳ Insufficient data for AI analysis, waiting...');
                return;
            }

            console.log('🔍 Performing AI-powered energy analysis...');

            // Get AI analysis of energy patterns
            const aiAnalysis = await this.watsonx.analyzeEnergyPatterns(
                this.devices,
                historicalData
            );

            // Combine AI insights with statistical analysis
            const analysis = {
                timestamp: new Date().toISOString(),
                ai_insights: aiAnalysis,
                statistical_analysis: this.performStatisticalAnalysis(historicalData),
                device_performance: this.analyzeDevicePerformance(),
                anomalies: this.detectAnomalies(historicalData),
                efficiency_trends: this.calculateEfficiencyTrends(),
                recommendations: this.generateMonitoringRecommendations(aiAnalysis)
            };

            this.lastAnalysis = analysis;
            this.analysisHistory.push(analysis);

            // Keep only last 100 analyses
            if (this.analysisHistory.length > 100) {
                this.analysisHistory = this.analysisHistory.slice(-100);
            }

            // Notify listeners of new analysis
            if (this.onAnalysisUpdate) {
                this.onAnalysisUpdate(analysis);
            }

            console.log('✅ AI energy analysis completed');
            console.log(`📊 Efficiency Score: ${(aiAnalysis.efficiency_score * 100).toFixed(1)}%`);
            
            if (aiAnalysis.anomalies && aiAnalysis.anomalies.length > 0) {
                console.log('⚠️ Anomalies detected:', aiAnalysis.anomalies.join(', '));
            }

        } catch (error) {
            console.error('❌ Energy analysis failed:', error.message);
            
            // Fallback to statistical analysis only
            const fallbackAnalysis = {
                timestamp: new Date().toISOString(),
                ai_insights: { error: 'AI analysis unavailable' },
                statistical_analysis: this.performStatisticalAnalysis(this.getHistoricalData()),
                device_performance: this.analyzeDevicePerformance(),
                anomalies: [],
                efficiency_trends: this.calculateEfficiencyTrends(),
                recommendations: []
            };
            
            this.lastAnalysis = fallbackAnalysis;
            if (this.onAnalysisUpdate) {
                this.onAnalysisUpdate(fallbackAnalysis);
            }
        }
    }

    /**
     * Perform statistical analysis of energy data
     */
    performStatisticalAnalysis(historicalData) {
        if (!historicalData || historicalData.length === 0) {
            return { error: 'No data available' };
        }

        const recent24h = historicalData.slice(-48); // Last 24 hours (30-second intervals)
        const totalUsage = recent24h.reduce((sum, reading) => sum + reading.totalPower, 0);
        const avgUsage = totalUsage / recent24h.length;
        
        const usageValues = recent24h.map(r => r.totalPower);
        const maxUsage = Math.max(...usageValues);
        const minUsage = Math.min(...usageValues);
        
        // Calculate standard deviation
        const variance = usageValues.reduce((sum, val) => sum + Math.pow(val - avgUsage, 2), 0) / usageValues.length;
        const stdDev = Math.sqrt(variance);
        
        // Calculate peak hours
        const hourlyUsage = {};
        recent24h.forEach(reading => {
            const hour = new Date(reading.timestamp).getHours();
            if (!hourlyUsage[hour]) hourlyUsage[hour] = [];
            hourlyUsage[hour].push(reading.totalPower);
        });
        
        const hourlyAverages = Object.entries(hourlyUsage).map(([hour, values]) => ({
            hour: parseInt(hour),
            avgUsage: values.reduce((sum, val) => sum + val, 0) / values.length
        }));
        
        const peakHour = hourlyAverages.reduce((max, current) => 
            current.avgUsage > max.avgUsage ? current : max
        );

        return {
            average_usage: Math.round(avgUsage),
            max_usage: Math.round(maxUsage),
            min_usage: Math.round(minUsage),
            standard_deviation: Math.round(stdDev),
            peak_hour: peakHour.hour,
            peak_usage: Math.round(peakHour.avgUsage),
            usage_variability: stdDev / avgUsage, // Coefficient of variation
            data_points: recent24h.length
        };
    }

    /**
     * Analyze individual device performance
     */
    analyzeDevicePerformance() {
        return this.devices.map(device => {
            const baseUsage = this.getBaseUsage(device.type);
            const efficiencyRatio = device.isOn ? device.currentPower / baseUsage : 1;
            
            let status = 'normal';
            if (efficiencyRatio > 1.3) status = 'high_consumption';
            else if (efficiencyRatio < 0.7) status = 'low_consumption';
            
            return {
                device_id: device.id,
                device_name: device.name,
                current_power: device.currentPower,
                expected_power: baseUsage,
                efficiency_ratio: Math.round(efficiencyRatio * 100) / 100,
                status: status,
                is_on: device.isOn,
                daily_cost: device.todaysCost
            };
        });
    }

    /**
     * Detect anomalies in energy usage
     */
    detectAnomalies(historicalData) {
        const anomalies = [];
        
        if (historicalData.length < 20) return anomalies;
        
        const recent = historicalData.slice(-10);
        const baseline = historicalData.slice(-30, -10);
        
        const recentAvg = recent.reduce((sum, r) => sum + r.totalPower, 0) / recent.length;
        const baselineAvg = baseline.reduce((sum, r) => sum + r.totalPower, 0) / baseline.length;
        
        const deviation = Math.abs(recentAvg - baselineAvg) / baselineAvg;
        
        if (deviation > this.anomalyThreshold) {
            anomalies.push({
                type: 'usage_deviation',
                severity: deviation > 0.5 ? 'high' : 'medium',
                description: `Usage ${recentAvg > baselineAvg ? 'increased' : 'decreased'} by ${(deviation * 100).toFixed(1)}%`,
                current_usage: Math.round(recentAvg),
                baseline_usage: Math.round(baselineAvg),
                deviation_percent: Math.round(deviation * 100)
            });
        }

        // Check for device-specific anomalies
        this.devices.forEach(device => {
            if (device.isOn && device.currentPower === 0) {
                anomalies.push({
                    type: 'device_malfunction',
                    severity: 'high',
                    description: `${device.name} shows as ON but consuming no power`,
                    device_id: device.id
                });
            }
        });

        return anomalies;
    }

    /**
     * Calculate efficiency trends
     */
    calculateEfficiencyTrends() {
        if (this.analysisHistory.length < 2) {
            return { trend: 'insufficient_data' };
        }

        const recent = this.analysisHistory.slice(-5);
        const efficiencyScores = recent
            .filter(a => a.ai_insights && a.ai_insights.efficiency_score)
            .map(a => a.ai_insights.efficiency_score);

        if (efficiencyScores.length < 2) {
            return { trend: 'insufficient_data' };
        }

        const firstScore = efficiencyScores[0];
        const lastScore = efficiencyScores[efficiencyScores.length - 1];
        const change = lastScore - firstScore;

        let trend = 'stable';
        if (change > 0.05) trend = 'improving';
        else if (change < -0.05) trend = 'declining';

        return {
            trend: trend,
            change_percent: Math.round(change * 100),
            current_score: Math.round(lastScore * 100),
            data_points: efficiencyScores.length
        };
    }

    /**
     * Generate monitoring-specific recommendations
     */
    generateMonitoringRecommendations(aiAnalysis) {
        const recommendations = [];

        // Add recommendations based on AI insights
        if (aiAnalysis.potential_issues) {
            aiAnalysis.potential_issues.forEach(issue => {
                recommendations.push({
                    type: 'maintenance',
                    priority: 'medium',
                    description: issue,
                    action: 'schedule_maintenance'
                });
            });
        }

        // Add efficiency recommendations
        if (aiAnalysis.efficiency_score < 0.7) {
            recommendations.push({
                type: 'efficiency',
                priority: 'high',
                description: 'Overall system efficiency is below optimal',
                action: 'review_settings'
            });
        }

        return recommendations;
    }

    /**
     * Get expected base usage for device type
     */
    getBaseUsage(deviceType) {
        const baseUsages = {
            hvac: 3000,
            water_heater: 4000,
            lighting: 200,
            appliance: 1500
        };
        return baseUsages[deviceType] || 1000;
    }

    /**
     * Get current analysis data
     */
    getCurrentAnalysis() {
        return this.lastAnalysis;
    }

    /**
     * Get analysis history
     */
    getAnalysisHistory() {
        return this.analysisHistory;
    }

    /**
     * Health check for the monitor agent
     */
    async healthCheck() {
        const watsonxHealth = await this.watsonx.healthCheck();
        
        return {
            status: watsonxHealth.status,
            message: `Monitor Agent: ${watsonxHealth.message}`,
            last_analysis: this.lastAnalysis ? this.lastAnalysis.timestamp : 'none',
            analysis_count: this.analysisHistory.length
        };
    }
}

module.exports = EnergyMonitorAgent; 