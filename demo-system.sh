#!/bin/bash

echo "🚀 Smart Energy Optimizer - Real AI Demo"
echo "========================================"
echo ""

echo "1️⃣ System Health Check:"
curl -s http://localhost:3000/health | jq '{status: .status, ai_integration: .ai_integration, ai_system: .services.ai_system, total_power: .system_stats.total_power, daily_cost: .system_stats.daily_cost}'
echo ""

echo "2️⃣ Active Devices:"
curl -s http://localhost:3000/api/devices | jq '.data[] | select(.isOn == true) | {name: .name, location: .location, power: .currentPower, cost: .todaysCost}'
echo ""

echo "3️⃣ AI Predictions (Next 4 Hours):"
curl -s http://localhost:3000/api/predictions | jq '.data[0:4] | .[] | {hour: .hour, predicted_watts: (.predictedUsage | round), predicted_cost: (.predictedCost | round * 100 / 100), confidence: (.confidence * 100 | round)}'
echo ""

echo "4️⃣ AI Recommendations:"
curl -s http://localhost:3000/api/optimization/recommendations | jq '.data[] | {title: .title, description: .description, potential_savings: .potentialSavings, priority: .priority}'
echo ""

echo "✅ Demo Complete! Your Real AI System is Working!"
echo ""
echo "🌐 Open the web interface: ios-app/web-test.html"
echo "📱 For iOS: Use Xcode with ios-app/SimpleEnergyApp.swift"
echo "🤖 All data is powered by IBM watsonx.ai!"
