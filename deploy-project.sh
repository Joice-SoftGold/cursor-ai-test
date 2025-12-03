#!/bin/bash

# Deploy Script - Run this to create the React project and setup the component
# Make sure you've already run setup-vm.sh first!

set -e  # Exit on any error

echo "=========================================="
echo "Creating React + Vite + Tailwind Project"
echo "=========================================="

# Create Vite React project
echo "⚛️  Creating React project with Vite..."
npm create vite@latest my-app -- --template react

# Navigate into project
cd my-app

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Install Tailwind CSS
echo "🎨 Installing Tailwind CSS..."
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Configure Tailwind
echo "⚙️  Configuring Tailwind CSS..."

# Update tailwind.config.js
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

# Update src/index.css with Tailwind directives
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

echo ""
echo "✅ Project created successfully!"
echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo "1. Copy your component.txt file to: ~/frontend-project/my-app/src/"
echo "2. Rename it: mv src/component.txt src/App.jsx"
echo "3. Run: npm run dev -- --host 0.0.0.0"
echo "4. Access it at: http://YOUR_VM_IP:5173"
echo ""
