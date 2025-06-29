/**
 * IBM watsonx.ai Configuration
 * 
 * Set these environment variables in your .env file:
 */

module.exports = {
    // Required Environment Variables for watsonx.ai Integration:
    
    // WATSONX_API_KEY=t5WWW8061PtZtviQxU-NyfTHHYSai1RZYcxiafrwg2Vr
    // WATSONX_PROJECT_ID=f2dfbf53-c0b1-4e14-b0ed-03635ee8211f
    // WATSONX_URL=https://us-south.ml.cloud.ibm.com
    // WATSONX_MODEL_ID=ibm/granite-3-8b-instruct
    
    // Default configuration values
    defaults: {
        apiKey: process.env.WATSONX_API_KEY,
        projectId: process.env.WATSONX_PROJECT_ID,
        baseUrl: process.env.WATSONX_URL || 'https://us-south.ml.cloud.ibm.com',
        modelId: process.env.WATSONX_MODEL_ID || 'ibm/granite-3-8b-instruct',
        
        // AI Generation Parameters
        defaultParameters: {
            max_new_tokens: 500,
            temperature: 0.7,
            top_p: 0.9,
            repetition_penalty: 1.1,
            stop_sequences: ["\n\n", "###", "---"]
        },
        
        // Agent Update Intervals (in milliseconds)
        intervals: {
            deviceUpdate: 30 * 1000,      // 30 seconds
            monitorAnalysis: 5 * 60 * 1000,  // 5 minutes
            predictions: 5 * 60 * 1000,      // 5 minutes
            optimization: 10 * 60 * 1000,    // 10 minutes
            healthCheck: 5 * 60 * 1000       // 5 minutes
        }
    },
    
    // Validation function
    validateConfig() {
        const required = ['WATSONX_API_KEY', 'WATSONX_PROJECT_ID'];
        const missing = required.filter(key => !process.env[key]);
        
        if (missing.length > 0) {
            console.warn(`⚠️ Missing required environment variables: ${missing.join(', ')}`);
            console.warn('⚠️ watsonx.ai service will run in fallback mode');
            return false;
        }
        
        console.log('✅ watsonx.ai configuration validated');
        return true;
    }
}; 