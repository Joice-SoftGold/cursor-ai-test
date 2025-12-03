#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  React + Vite + Tailwind Setup${NC}"
echo -e "${BLUE}================================${NC}\n"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed!${NC}"
    echo "Please install Node.js first:"
    echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
    echo "  sudo apt-get install -y nodejs"
    exit 1
fi

echo -e "${GREEN}✓ Node.js version: $(node --version)${NC}"
echo -e "${GREEN}✓ npm version: $(npm --version)${NC}\n"

# Project name
PROJECT_NAME="my-frontend-app"

# Step 1: Create Vite React project
echo -e "${YELLOW}Step 1: Creating Vite React project...${NC}"
npm create vite@latest $PROJECT_NAME -- --template react

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create Vite project${NC}"
    exit 1
fi

cd $PROJECT_NAME

# Step 2: Install dependencies
echo -e "\n${YELLOW}Step 2: Installing dependencies...${NC}"
npm install

# Step 3: Install Tailwind CSS
echo -e "\n${YELLOW}Step 3: Installing Tailwind CSS...${NC}"
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Step 4: Configure Tailwind
echo -e "\n${YELLOW}Step 4: Configuring Tailwind CSS...${NC}"

cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

# Step 5: Update CSS file
echo -e "\n${YELLOW}Step 5: Updating CSS with Tailwind directives...${NC}"

cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
EOF

# Step 6: Copy component.txt and convert to JSX
echo -e "\n${YELLOW}Step 6: Converting component.txt to App.jsx...${NC}"

if [ -f "../component.txt" ]; then
    cp ../component.txt src/App.jsx
    echo -e "${GREEN}✓ Successfully converted component.txt to App.jsx${NC}"
else
    echo -e "${YELLOW}Warning: component.txt not found. Using default App.jsx${NC}"
fi

# Step 7: Update main.jsx to remove default styling
cat > src/main.jsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}  Setup Complete! 🎉${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${BLUE}To run the development server:${NC}"
echo -e "  cd $PROJECT_NAME"
echo -e "  npm run dev"
echo -e "\n${BLUE}To build for production:${NC}"
echo -e "  npm run build"
echo -e "\n${BLUE}To preview production build:${NC}"
echo -e "  npm run preview\n"

echo -e "${YELLOW}Note: The dev server will run on http://localhost:5173${NC}"
echo -e "${YELLOW}To access from outside the VM, use: http://YOUR_VM_IP:5173${NC}\n"
