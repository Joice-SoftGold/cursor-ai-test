#!/bin/bash

# Complete Automated Setup Script
# This combines everything - run this after uploading component.txt to the VM

set -e

echo "=========================================="
echo "🚀 Complete Frontend Deployment"
echo "=========================================="

PROJECT_DIR=~/frontend-project
APP_NAME=my-app

# Create project directory
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Create Vite React project
echo "⚛️  Creating React project..."
npm create vite@latest $APP_NAME -- --template react

cd $APP_NAME

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Install Tailwind CSS
echo "🎨 Installing Tailwind CSS..."
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Configure Tailwind
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

# Update index.css
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

# Check if component.txt exists in home directory
if [ -f ~/component.txt ]; then
    echo "📄 Found component.txt, converting to App.jsx..."
    cp ~/component.txt src/App.jsx
    echo "✅ Component file installed!"
else
    echo "⚠️  Warning: component.txt not found in home directory"
    echo "   Please copy it to ~/component.txt and run this script again"
    exit 1
fi

# Update main.jsx to remove strict mode (optional, but prevents double renders)
cat > src/main.jsx << 'EOF'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
EOF

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "To start the development server:"
echo "  cd $PROJECT_DIR/$APP_NAME"
echo "  npm run dev -- --host 0.0.0.0"
echo ""
echo "Then access it at: http://YOUR_VM_PUBLIC_IP:5173"
echo ""
