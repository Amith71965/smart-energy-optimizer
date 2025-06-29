/**
 * Real Energy Optimization Agent - Powered by IBM watsonx.ai
 * Replaces mock optimization with actual AI recommendations
 */

const WatsonxService = require('../services/watsonx-service');

class EnergyOptimizationAgent {
    constructor() {
        this.watsonx = new WatsonxService();
        this.recommendations = [];
        this.appliedRecommendations = [];
        this.optimizationHistory = [];
        this.lastUpdate = null;
        this.savingsTracked = 0;
        
        console.log('💡 Energy Optimization Agent initialized with AI');
        
        // Generate initial recommendations immediately
        setTimeout(() => {
            this.generateInitialRecommendations();
        }, 2000); // Wait 2 seconds for devices to be available
    }

    /**
     * Start continuous optimization service
     */
    async startOptimization(devices, getPredictions, getHistoricalData, onRecommendationsUpdate) {
        this.devices = devices;
        this.getPredictions = getPredictions;
        this.getHistoricalData = getHistoricalData;
        this.onRecommendationsUpdate = onRecommendationsUpdate;

        // Generate initial recommendations
        await this.generateRecommendations();

        // Schedule recommendation updates every 10 minutes
        setInterval(async () => {
            await this.generateRecommendations();
        }, 10 * 60 * 1000);

        console.log('💡 Energy optimization service started with AI');
    }

    /**
     * Generate smart optimization recommendations using AI
     */
    async generateRecommendations() {
        try {
            const predictions = this.getPredictions();
            const currentHour = new Date().getHours();
            
            console.log('💡 Generating AI-powered optimization recommendations...');

            // Always generate recommendations, even without predictions
            let aiRecommendations;
            
            if (!predictions || predictions.length === 0) {
                console.log('⏳ No predictions available, generating immediate recommendations...');
                aiRecommendations = await this.generateImmediateRecommendations(currentHour);
            } else {
                // Get AI optimization recommendations with predictions
                aiRecommendations = await this.watsonx.generateOptimizationRecommendations(
                    this.devices,
                    predictions,
                    currentHour
                );
            }

            // Enhance AI recommendations with additional analysis
            const enhancedRecommendations = this.enhanceRecommendations(aiRecommendations, currentHour);

            // Prioritize and validate recommendations
            this.recommendations = this.prioritizeRecommendations(enhancedRecommendations);

            // Track optimization opportunities
            this.trackOptimizationOpportunities();

            this.lastUpdate = new Date().toISOString();

            // Notify listeners
            this.notifyUpdate();

            console.log('✅ AI optimization recommendations generated');
            console.log(`💡 Generated ${this.recommendations.length} recommendations`);
            
            const highPriorityCount = this.recommendations.filter(r => r.priority === 'high').length;
            if (highPriorityCount > 0) {
                console.log(`🚨 ${highPriorityCount} high-priority recommendations available`);
            }

        } catch (error) {
            console.error('❌ AI optimization generation failed:', error.message);
            
            // Fallback to rule-based recommendations
            this.recommendations = this.generateRuleBasedRecommendations();
            this.lastUpdate = new Date().toISOString();
            this.notifyUpdate();
        }
    }

    /**
     * Generate immediate recommendations without predictions
     */
    async generateImmediateRecommendations(currentHour) {
        const activeDevices = this.devices.filter(d => d.isOn);
        const totalUsage = this.devices.reduce((sum, d) => sum + d.currentPower, 0);
        
        const prompt = `You are a smart home energy optimization expert. Generate immediate actionable recommendations based on current device status.

CURRENT SITUATION:
- Time: ${currentHour}:00
- Total Usage: ${totalUsage.toFixed(0)}W
- Active Devices: ${activeDevices.length}/${this.devices.length}

DEVICE STATUS:
${this.devices.map(d => `- ${d.name} (${d.type}): ${d.currentPower}W, ${d.isOn ? 'ON' : 'OFF'}${d.targetTemp ? `, Target: ${d.targetTemp}°F` : ''}${d.brightness ? `, Brightness: ${d.brightness}%` : ''}`).join('\n')}

TIME CONTEXT:
${this.getTimeContext(currentHour)}

Generate 2-4 immediate optimization recommendations in this exact JSON format (no other text):
{
  "recommendations": [
    {
      "id": "immediate_001",
      "title": "Optimize High-Usage Device",
      "description": "Reduce energy consumption of the highest usage device",
      "category": "immediate",
      "potentialSavings": 0.85,
      "priority": "medium",
      "difficulty": "easy",
      "estimatedTime": "2 minutes",
      "devices": ["device_id"],
      "action": "optimize",
      "value": "auto"
    }
  ]
}`;

        try {
            const response = await this.watsonx.generateText(prompt, { temperature: 0.5 });
            const parsed = this.watsonx.parseJsonResponse(response, null);
            
            if (parsed && parsed.recommendations && Array.isArray(parsed.recommendations)) {
                return parsed.recommendations;
            }
            throw new Error('Invalid recommendations format');
        } catch (error) {
            console.warn('⚠️ AI immediate recommendations failed, using smart fallback');
            return this.generateSmartFallbackRecommendations(currentHour);
        }
    }

    /**
     * Generate smart fallback recommendations
     */
    generateSmartFallbackRecommendations(currentHour) {
        const recommendations = [];
        const activeDevices = this.devices.filter(d => d.isOn);
        const totalUsage = this.devices.reduce((sum, d) => sum + d.currentPower, 0);

        // High usage optimization
        if (totalUsage > 3000) {
            const highUsageDevice = this.devices.reduce((max, device) => 
                device.currentPower > max.currentPower ? device : max
            );

            if (highUsageDevice && highUsageDevice.currentPower > 2000) {
                recommendations.push({
                    id: 'smart_high_usage',
                    title: 'Reduce High Energy Device',
                    description: `${highUsageDevice.name} is using ${highUsageDevice.currentPower}W. Consider optimizing its settings.`,
                    category: highUsageDevice.type,
                    potentialSavings: 1.5,
                    priority: 'high',
                    difficulty: 'easy',
                    estimatedTime: '3 minutes',
                    devices: [highUsageDevice.id],
                    action: this.getOptimizationAction(highUsageDevice),
                    value: this.getOptimizationValue(highUsageDevice),
                    source: 'smart_fallback'
                });
            }
        }

        // Time-based optimizations
        if (currentHour >= 17 && currentHour <= 19) {
            // Peak hours - pre-cooling
            const hvacDevice = this.devices.find(d => d.type === 'hvac' && d.isOn);
            if (hvacDevice && hvacDevice.targetTemp > 70) {
                recommendations.push({
                    id: 'smart_peak_precool',
                    title: 'Pre-cool Before Peak Rates',
                    description: 'Lower thermostat now to avoid higher peak electricity rates',
                    category: 'hvac',
                    potentialSavings: 1.8,
                    priority: 'high',
                    difficulty: 'easy',
                    estimatedTime: '1 minute',
                    devices: [hvacDevice.id],
                    action: 'set_temperature',
                    value: String(hvacDevice.targetTemp - 3),
                    source: 'smart_fallback'
                });
            }
        }

        if (currentHour >= 20) {
            // Late evening - appliance scheduling
            const appliance = this.devices.find(d => d.type === 'appliance' && !d.isOn);
            if (appliance) {
                recommendations.push({
                    id: 'smart_late_schedule',
                    title: 'Schedule for Off-Peak Hours',
                    description: 'Run appliances after 11 PM for significant savings',
                    category: 'appliances',
                    potentialSavings: 0.95,
                    priority: 'medium',
                    difficulty: 'easy',
                    estimatedTime: '2 minutes',
                    devices: [appliance.id],
                    action: 'schedule',
                    value: '23:00',
                    source: 'smart_fallback'
                });
            }
        }

        // Lighting optimization
        const brightLights = this.devices.filter(d => 
            d.type === 'lighting' && d.isOn && d.brightness && d.brightness > 85
        );
        
        if (brightLights.length > 0) {
            brightLights.forEach(light => {
                recommendations.push({
                    id: `smart_light_${light.id}`,
                    title: 'Optimize Lighting Efficiency',
                    description: 'Reduce brightness slightly for energy savings with minimal impact',
                    category: 'lighting',
                    potentialSavings: 0.4,
                    priority: 'low',
                    difficulty: 'easy',
                    estimatedTime: '30 seconds',
                    devices: [light.id],
                    action: 'set_brightness',
                    value: '75',
                    source: 'smart_fallback'
                });
            });
        }

        // Always provide at least one recommendation
        if (recommendations.length === 0) {
            recommendations.push({
                id: 'smart_general',
                title: 'System Running Efficiently',
                description: 'Your energy system is well-optimized. Monitor for new opportunities.',
                category: 'general',
                potentialSavings: 0.25,
                priority: 'low',
                difficulty: 'easy',
                estimatedTime: '1 minute',
                devices: [],
                action: 'monitor',
                value: 'continue',
                source: 'smart_fallback'
            });
        }

        return recommendations;
    }

    /**
     * Get time context description
     */
    getTimeContext(hour) {
        if (hour >= 6 && hour <= 9) return "Morning peak hours - high energy rates expected";
        if (hour >= 10 && hour <= 16) return "Daytime normal hours - standard energy rates";
        if (hour >= 17 && hour <= 21) return "Evening peak hours - highest energy rates";
        if (hour >= 22 && hour <= 23) return "Late evening - transitioning to off-peak rates";
        return "Overnight hours - lowest energy rates available";
    }

    /**
     * Get optimization action for device
     */
    getOptimizationAction(device) {
        switch (device.type) {
            case 'hvac':
                return 'set_temperature';
            case 'lighting':
                return 'set_brightness';
            case 'water_heater':
                return 'set_temperature';
            case 'appliance':
                return 'schedule';
            default:
                return 'optimize';
        }
    }

    /**
     * Get optimization value for device
     */
    getOptimizationValue(device) {
        switch (device.type) {
            case 'hvac':
                return device.targetTemp ? String(device.targetTemp - 2) : '70';
            case 'lighting':
                return device.brightness ? String(Math.max(50, device.brightness - 20)) : '75';
            case 'water_heater':
                return '115'; // Safe water heater temperature
            case 'appliance':
                return '23:00'; // Off-peak time
            default:
                return 'auto';
        }
    }

    /**
     * Enhance AI recommendations with additional context
     */
    enhanceRecommendations(aiRecommendations, currentHour) {
        return aiRecommendations.map(rec => {
            const enhancedRec = {
                ...rec,
                id: rec.id || `opt_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`,
                generated_at: new Date().toISOString(),
                current_hour: currentHour,
                urgency_score: this.calculateUrgencyScore(rec, currentHour),
                feasibility_score: this.calculateFeasibilityScore(rec),
                impact_category: this.categorizeImpact(rec.potentialSavings),
                comfort_impact: this.assessComfortImpact(rec),
                automation_level: this.determineAutomationLevel(rec),
                prerequisites: this.getPrerequisites(rec),
                estimated_implementation_time: rec.estimatedTime || this.estimateImplementationTime(rec)
            };

            // Add device-specific context
            if (rec.devices && rec.devices.length > 0) {
                enhancedRec.affected_devices = rec.devices.map(deviceId => {
                    const device = this.devices.find(d => d.id === deviceId);
                    return device ? {
                        id: device.id,
                        name: device.name,
                        type: device.type,
                        current_power: device.currentPower,
                        is_on: device.isOn
                    } : null;
                }).filter(Boolean);
            }

            return enhancedRec;
        });
    }

    /**
     * Prioritize recommendations based on multiple factors
     */
    prioritizeRecommendations(recommendations) {
        // Calculate composite scores for each recommendation
        const scoredRecommendations = recommendations.map(rec => ({
            ...rec,
            composite_score: this.calculateCompositeScore(rec)
        }));

        // Sort by composite score (highest first)
        const sortedRecommendations = scoredRecommendations.sort((a, b) => b.composite_score - a.composite_score);

        // Apply priority levels based on scores
        return sortedRecommendations.map((rec, index) => {
            let priority = 'low';
            if (rec.composite_score > 0.8) priority = 'high';
            else if (rec.composite_score > 0.6) priority = 'medium';

            return {
                ...rec,
                priority: rec.priority || priority, // Keep original priority if specified
                rank: index + 1,
                recommendation_strength: this.getRecommendationStrength(rec.composite_score)
            };
        });
    }

    /**
     * Calculate composite score for recommendation prioritization
     */
    calculateCompositeScore(rec) {
        const weights = {
            savings: 0.3,
            urgency: 0.25,
            feasibility: 0.2,
            comfort: 0.15,
            implementation: 0.1
        };

        const scores = {
            savings: Math.min(1.0, (rec.potentialSavings || 0) / 2.0), // Normalize to max $2 savings
            urgency: rec.urgency_score || 0.5,
            feasibility: rec.feasibility_score || 0.7,
            comfort: 1.0 - (rec.comfort_impact || 0.3), // Lower comfort impact = higher score
            implementation: 1.0 - Math.min(1.0, (this.parseTimeToMinutes(rec.estimated_implementation_time) || 5) / 30) // Normalize to 30 min max
        };

        return Object.entries(weights).reduce((total, [key, weight]) => {
            return total + (scores[key] * weight);
        }, 0);
    }

    /**
     * Calculate urgency score based on time and conditions
     */
    calculateUrgencyScore(rec, currentHour) {
        let urgency = 0.5; // Base urgency

        // Time-based urgency
        if (rec.category === 'hvac' && (currentHour >= 16 && currentHour <= 18)) {
            urgency += 0.3; // Pre-peak cooling
        }

        if (rec.category === 'appliances' && (currentHour >= 21 && currentHour <= 23)) {
            urgency += 0.2; // Off-peak scheduling window
        }

        // Savings-based urgency
        if (rec.potentialSavings > 1.0) urgency += 0.2;

        // Device state urgency
        if (rec.affected_devices) {
            const highUsageDevices = rec.affected_devices.filter(d => d.current_power > 3000);
            if (highUsageDevices.length > 0) urgency += 0.2;
        }

        return Math.min(1.0, urgency);
    }

    /**
     * Calculate feasibility score
     */
    calculateFeasibilityScore(rec) {
        let feasibility = 0.8; // Base feasibility

        // Implementation complexity
        if (rec.difficulty === 'easy') feasibility += 0.2;
        else if (rec.difficulty === 'hard') feasibility -= 0.3;

        // Device availability
        if (rec.affected_devices) {
            const unavailableDevices = rec.affected_devices.filter(d => !d.is_on && rec.action !== 'turn_on');
            if (unavailableDevices.length > 0) feasibility -= 0.2;
        }

        return Math.max(0.1, Math.min(1.0, feasibility));
    }

    /**
     * Categorize impact based on potential savings
     */
    categorizeImpact(savings) {
        if (savings >= 2.0) return 'high';
        if (savings >= 1.0) return 'medium';
        if (savings >= 0.5) return 'low';
        return 'minimal';
    }

    /**
     * Assess comfort impact
     */
    assessComfortImpact(rec) {
        const comfortImpacts = {
            'hvac': 0.7, // Temperature changes affect comfort significantly
            'lighting': 0.3, // Lighting changes have moderate impact
            'appliances': 0.1, // Appliance scheduling has minimal impact
            'water_heater': 0.4 // Hot water availability affects comfort
        };

        return comfortImpacts[rec.category] || 0.3;
    }

    /**
     * Determine automation level
     */
    determineAutomationLevel(rec) {
        if (rec.action === 'schedule') return 'automatic';
        if (rec.action === 'set_temperature' || rec.action === 'set_brightness') return 'semi_automatic';
        return 'manual';
    }

    /**
     * Get prerequisites for recommendation
     */
    getPrerequisites(rec) {
        const prerequisites = [];

        if (rec.category === 'hvac') {
            prerequisites.push('Ensure HVAC system is operational');
            prerequisites.push('Check current temperature settings');
        }

        if (rec.automation_level === 'automatic') {
            prerequisites.push('Smart scheduling capability required');
        }

        return prerequisites;
    }

    /**
     * Estimate implementation time
     */
    estimateImplementationTime(rec) {
        const timeEstimates = {
            'set_temperature': '2 minutes',
            'set_brightness': '1 minute',
            'schedule': '5 minutes',
            'turn_off': '30 seconds',
            'turn_on': '30 seconds'
        };

        return timeEstimates[rec.action] || '5 minutes';
    }

    /**
     * Parse time string to minutes
     */
    parseTimeToMinutes(timeStr) {
        if (!timeStr) return 5;
        
        const match = timeStr.match(/(\d+)\s*(minute|min|second|sec)/i);
        if (match) {
            const value = parseInt(match[1]);
            const unit = match[2].toLowerCase();
            return unit.startsWith('sec') ? Math.ceil(value / 60) : value;
        }
        
        return 5; // Default fallback
    }

    /**
     * Get recommendation strength description
     */
    getRecommendationStrength(score) {
        if (score > 0.8) return 'strongly_recommended';
        if (score > 0.6) return 'recommended';
        if (score > 0.4) return 'consider';
        return 'optional';
    }

    /**
     * Generate rule-based recommendations as fallback
     */
    generateRuleBasedRecommendations() {
        const recommendations = [];
        const currentHour = new Date().getHours();
        const predictions = this.getPredictions() || [];

        // Find peak usage predictions
        const peakPredictions = predictions.filter(p => p.peak_probability > 0.7);

        // HVAC optimization
        const hvacDevice = this.devices.find(d => d.type === 'hvac' && d.isOn);
        if (hvacDevice && peakPredictions.length > 0) {
            recommendations.push({
                id: 'rule_hvac_opt',
                title: 'Optimize HVAC for Peak Hours',
                description: 'Adjust thermostat to reduce usage during predicted peak hours',
                category: 'hvac',
                potentialSavings: 1.5,
                priority: 'high',
                difficulty: 'easy',
                estimatedTime: '2 minutes',
                devices: [hvacDevice.id],
                action: 'set_temperature',
                value: hvacDevice.targetTemp - 2,
                source: 'rule_based'
            });
        }

        // Lighting optimization
        const lightingDevices = this.devices.filter(d => d.type === 'lighting' && d.isOn);
        if (lightingDevices.length > 0) {
            lightingDevices.forEach(device => {
                if (device.brightness > 80) {
                    recommendations.push({
                        id: `rule_light_${device.id}`,
                        title: 'Reduce Lighting Brightness',
                        description: 'Dim lights to save energy with minimal impact',
                        category: 'lighting',
                        potentialSavings: 0.3,
                        priority: 'low',
                        difficulty: 'easy',
                        estimatedTime: '30 seconds',
                        devices: [device.id],
                        action: 'set_brightness',
                        value: '75',
                        source: 'rule_based'
                    });
                }
            });
        }

        return recommendations;
    }

    /**
     * Track optimization opportunities
     */
    trackOptimizationOpportunities() {
        const totalPotentialSavings = this.recommendations.reduce((sum, rec) => sum + (rec.potentialSavings || 0), 0);
        
        const opportunityRecord = {
            timestamp: new Date().toISOString(),
            total_recommendations: this.recommendations.length,
            high_priority_count: this.recommendations.filter(r => r.priority === 'high').length,
            total_potential_savings: totalPotentialSavings,
            categories: this.getRecommendationsByCategory(),
            average_composite_score: this.recommendations.reduce((sum, r) => sum + (r.composite_score || 0), 0) / this.recommendations.length
        };

        this.optimizationHistory.push(opportunityRecord);

        // Keep only last 100 records
        if (this.optimizationHistory.length > 100) {
            this.optimizationHistory = this.optimizationHistory.slice(-100);
        }
    }

    /**
     * Get recommendations grouped by category
     */
    getRecommendationsByCategory() {
        const categories = {};
        
        this.recommendations.forEach(rec => {
            const category = rec.category || 'general';
            if (!categories[category]) {
                categories[category] = {
                    count: 0,
                    total_savings: 0,
                    avg_priority_score: 0
                };
            }
            
            categories[category].count++;
            categories[category].total_savings += rec.potentialSavings || 0;
        });

        return categories;
    }

    /**
     * Apply a recommendation
     */
    async applyRecommendation(recommendationId, deviceControlCallback) {
        const recommendation = this.recommendations.find(r => r.id === recommendationId);
        if (!recommendation) {
            return { success: false, message: 'Recommendation not found' };
        }

        try {
            console.log(`🔧 Applying recommendation: ${recommendation.title}`);

            // Execute the recommendation action
            if (deviceControlCallback && recommendation.devices && recommendation.action) {
                for (const deviceId of recommendation.devices) {
                    const result = await deviceControlCallback(deviceId, recommendation.action, recommendation.value);
                    if (!result.success) {
                        throw new Error(`Failed to control device ${deviceId}: ${result.message}`);
                    }
                }
            }

            // Track applied recommendation
            const appliedRec = {
                ...recommendation,
                applied_at: new Date().toISOString(),
                status: 'applied'
            };

            this.appliedRecommendations.push(appliedRec);
            this.savingsTracked += recommendation.potentialSavings || 0;

            // Remove from active recommendations
            this.recommendations = this.recommendations.filter(r => r.id !== recommendationId);

            console.log(`✅ Recommendation applied successfully: ${recommendation.title}`);
            console.log(`💰 Estimated savings: $${recommendation.potentialSavings?.toFixed(2) || '0.00'}`);

            return {
                success: true,
                message: 'Recommendation applied successfully',
                estimated_savings: recommendation.potentialSavings,
                total_tracked_savings: this.savingsTracked
            };

        } catch (error) {
            console.error(`❌ Failed to apply recommendation: ${error.message}`);
            return {
                success: false,
                message: error.message
            };
        }
    }

    /**
     * Notify listeners of recommendation updates
     */
    notifyUpdate() {
        if (this.onRecommendationsUpdate) {
            this.onRecommendationsUpdate({
                recommendations: this.recommendations,
                last_update: this.lastUpdate,
                total_potential_savings: this.recommendations.reduce((sum, r) => sum + (r.potentialSavings || 0), 0),
                high_priority_count: this.recommendations.filter(r => r.priority === 'high').length,
                applied_count: this.appliedRecommendations.length,
                total_tracked_savings: this.savingsTracked
            });
        }
    }

    /**
     * Get current recommendations
     */
    getRecommendations() {
        return this.recommendations;
    }

    /**
     * Get recommendations by priority
     */
    getRecommendationsByPriority(priority) {
        return this.recommendations.filter(r => r.priority === priority);
    }

    /**
     * Get applied recommendations history
     */
    getAppliedRecommendations() {
        return this.appliedRecommendations;
    }

    /**
     * Get optimization statistics
     */
    getOptimizationStats() {
        return {
            total_recommendations: this.recommendations.length,
            applied_recommendations: this.appliedRecommendations.length,
            total_tracked_savings: this.savingsTracked,
            categories: this.getRecommendationsByCategory(),
            last_update: this.lastUpdate,
            optimization_history_count: this.optimizationHistory.length
        };
    }

    /**
     * Health check for the optimization agent
     */
    async healthCheck() {
        const watsonxHealth = await this.watsonx.healthCheck();
        
        return {
            status: watsonxHealth.status,
            message: `Optimization Agent: ${watsonxHealth.message}`,
            last_update: this.lastUpdate,
            recommendations_count: this.recommendations.length,
            applied_count: this.appliedRecommendations.length,
            total_savings: this.savingsTracked
        };
    }

    /**
     * Generate initial recommendations immediately
     */
    async generateInitialRecommendations() {
        try {
            console.log('💡 Generating initial recommendations...');
            const currentHour = new Date().getHours();
            
            if (!this.devices || this.devices.length === 0) {
                console.log('⏳ No devices available yet, will retry...');
                setTimeout(() => this.generateInitialRecommendations(), 5000);
                return;
            }
            
            // Generate smart fallback recommendations immediately
            const recommendations = this.generateSmartFallbackRecommendations(currentHour);
            
            if (recommendations.length > 0) {
                this.recommendations = this.prioritizeRecommendations(recommendations);
                this.lastUpdate = new Date().toISOString();
                this.notifyUpdate();
                
                console.log(`✅ Generated ${this.recommendations.length} initial recommendations`);
                this.recommendations.forEach(rec => {
                    console.log(`   💡 ${rec.title} (${rec.priority} priority, $${rec.potentialSavings.toFixed(2)} savings)`);
                });
            }
        } catch (error) {
            console.error('❌ Failed to generate initial recommendations:', error.message);
        }
    }
}

module.exports = EnergyOptimizationAgent; 