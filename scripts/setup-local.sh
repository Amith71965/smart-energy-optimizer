#!/bin/bash

echo "🚀 Setting up Smart Energy Optimizer local development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js 18+ and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed. Please install npm and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ npm found: $(npm --version)${NC}"

# Create directory structure
echo -e "${BLUE}📁 Creating directory structure...${NC}"
mkdir -p backend/api/routes backend/agents backend/services backend/models backend/utils backend/tests
mkdir -p simulators/devices simulators/data
mkdir -p mock-services
mkdir -p ios-app
mkdir -p web-dashboard/src/components web-dashboard/src/pages web-dashboard/src/services
mkdir -p database/init database/migrations
mkdir -p deployment/ibm-cloud deployment/docker deployment/scripts
mkdir -p docs
mkdir -p scripts

# Create essential files
echo -e "${BLUE}📄 Creating essential files...${NC}"
touch backend/.env
touch .env
touch .gitignore
touch README.md

# Create .env file
if [ ! -f .env ]; then
    echo -e "${BLUE}⚙️ Creating environment configuration...${NC}"
    cat > .env << EOL
NODE_ENV=development
PORT=3000
MOCK_SERVICES_PORT=3001
BACKEND_URL=http://localhost:3000
MOCK_SERVICES_URL=http://localhost:3001
DATABASE_URL=memory://localhost

# IBM Cloud Services (will be filled when hackathon starts)
IBM_IOT_ORG_ID=your_org_id
IBM_IOT_API_KEY=your_api_key
IBM_IOT_AUTH_TOKEN=your_auth_token
CLOUDANT_URL=your_cloudant_url
CLOUDANT_APIKEY=your_cloudant_key
WATSONX_URL=your_watsonx_url
WATSONX_API_KEY=your_watsonx_key
WATSONX_PROJECT_ID=your_project_id
EOL
fi

# Create .gitignore
if [ ! -f .gitignore ]; then
    echo -e "${BLUE}📝 Creating .gitignore...${NC}"
    cat > .gitignore << EOL
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Build outputs
build/
dist/
*.tgz

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Logs
logs
*.log

# Database
database/data/
*.db
*.sqlite

# IDE
.vscode/
.idea/
*.swp
*.swo

# macOS
.DS_Store

# iOS
ios-app/DerivedData/
ios-app/build/
*.xcuserstate
*.xcworkspace/xcuserdata/

# Temporary files
tmp/
temp/
EOL
fi

# Install dependencies
echo -e "${BLUE}📦 Installing dependencies...${NC}"
npm install

if [ -d "backend" ]; then
    echo -e "${BLUE}📦 Installing backend dependencies...${NC}"
    cd backend && npm install && cd ..
fi

if [ -d "simulators" ]; then
    echo -e "${BLUE}📦 Installing simulator dependencies...${NC}"
    cd simulators && npm install && cd ..
fi

# Create basic README
if [ ! -f README.md ]; then
    echo -e "${BLUE}📖 Creating README...${NC}"
    cat > README.md << EOL
# Smart Energy Optimizer

AI-powered smart home energy optimization system for IBM TechXchange Hackathon.

## Quick Start

\`\`\`bash
# Install dependencies
npm run install-all

# Start development environment
npm run dev

# Start iOS app (open ios-app/SmartEnergyApp.xcodeproj in Xcode)
\`\`\`

## Architecture

- **Backend**: Node.js API with AI agents
- **iOS App**: SwiftUI native application
- **Simulators**: IoT device simulators
- **Mock Services**: Local IBM Cloud service alternatives

## Development

- Backend API: http://localhost:3000
- Mock Services: http://localhost:3001
- WebSocket: ws://localhost:3000

## Deployment

Ready for deployment to IBM Cloud when hackathon begins.
EOL
fi

echo -e "${GREEN}🎉 Setup complete!${NC}"
echo -e "${BLUE}📋 Next steps:${NC}"
echo -e "1. Copy the package.json and code files from the artifacts"
echo -e "2. Run: ${YELLOW}npm run dev${NC}"
echo -e "3. Open iOS app in Xcode: ${YELLOW}ios-app/SmartEnergyApp.xcodeproj${NC}"
echo -e "4. Test API: ${YELLOW}curl http://localhost:3000/health${NC}"

echo -e "${GREEN}✨ Happy coding!${NC}"