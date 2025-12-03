# Frontend Deployment Lab - Complete Guide

## 📋 Task Overview
Deploy a React component with Tailwind CSS on an Azure Virtual Machine.

---

## 🎯 What You'll Do

1. **Create an Azure VM** (Ubuntu Linux)
2. **SSH into the VM** 
3. **Install Node.js & npm**
4. **Create a React project** with Vite
5. **Install Tailwind CSS**
6. **Convert component.txt to App.jsx**
7. **Run the development server**

---

## 📁 Files in This Repository

- **`component.txt`** - React component with Tailwind CSS styling (to be converted to `.jsx`)
- **`setup-vm.sh`** - Installs Node.js and npm on the VM
- **`deploy-project.sh`** - Creates the React project structure
- **`complete-setup.sh`** - All-in-one automated script
- **`README.md`** - This file

---

## 🚀 Step-by-Step Instructions

### Step 1: Create Azure VM (Manual in Azure Portal)

1. Go to [Azure Portal](https://portal.azure.com)
2. Click **"Create a resource"** → **"Virtual Machine"**
3. Configure:
   - **Resource Group:** Create new (e.g., `rg-frontend-lab`)
   - **VM Name:** `vm-frontend-dev`
   - **Region:** East US (or your preferred region)
   - **Image:** Ubuntu Server 22.04 LTS
   - **Size:** Standard_B2s (2 vCPUs, 4 GB RAM)
   - **Authentication:** SSH public key
   - **Username:** `azureuser`
4. **Networking:**
   - Allow ports: **22 (SSH)**, **5173 (Vite dev server)**
5. Click **"Review + Create"** → **"Create"**
6. Wait for deployment (~3-5 minutes)
7. Copy the **Public IP Address**

---

### Step 2: Connect to Your VM via SSH

```bash
# Replace YOUR_VM_IP with the actual public IP from Azure
ssh azureuser@YOUR_VM_IP
```

If prompted, type `yes` to accept the fingerprint.

---

### Step 3: Upload component.txt to the VM

**Option A: Using SCP (from your local machine)**
```bash
scp component.txt azureuser@YOUR_VM_IP:~/component.txt
```

**Option B: Copy-paste manually**
```bash
# On the VM
nano ~/component.txt
# Paste the content, then press Ctrl+X, Y, Enter
```

---

### Step 4: Upload and Run the Setup Script

**Option A: Upload script from your local machine**
```bash
# From your local machine (in the workspace folder)
scp complete-setup.sh azureuser@YOUR_VM_IP:~/complete-setup.sh
```

**Option B: Create script directly on VM**
```bash
# SSH into VM first, then:
nano ~/complete-setup.sh
# Copy the contents of complete-setup.sh and paste
# Press Ctrl+X, Y, Enter to save
```

Make it executable and run:
```bash
chmod +x ~/complete-setup.sh
./complete-setup.sh
```

---

### Step 5: Run the Development Server

```bash
cd ~/frontend-project/my-app
npm run dev -- --host 0.0.0.0
```

**Important:** The `--host 0.0.0.0` flag allows external access!

---

### Step 6: Access Your App

Open your browser and go to:
```
http://YOUR_VM_PUBLIC_IP:5173
```

You should see a beautiful dashboard with:
- A gradient purple/pink/red background
- A counter with +/- buttons
- An Active/Inactive toggle button
- Smooth animations

---

## 🐛 Troubleshooting

### Problem: Cannot connect via SSH
**Solution:** Check Azure NSG (Network Security Group) allows port 22

### Problem: Cannot access port 5173
**Solution:** 
1. Check Azure NSG allows port 5173
2. Make sure you used `--host 0.0.0.0` when running npm dev
3. Check firewall: `sudo ufw status` (if enabled, allow 5173)

### Problem: npm command not found
**Solution:** Run `setup-vm.sh` first to install Node.js

### Problem: Tailwind styles not working
**Solution:** 
1. Check `tailwind.config.js` content paths
2. Make sure `index.css` has the @tailwind directives
3. Restart the dev server

### Problem: Component errors
**Solution:** 
1. Make sure you renamed `component.txt` to `App.jsx`
2. Check if import statement exists in `main.jsx`
3. Look at console errors: `npm run dev` will show them

---

## 📝 Manual Step-by-Step (if scripts don't work)

### 1. Install Node.js
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt-get install -y build-essential
node --version
npm --version
```

### 2. Create React Project
```bash
mkdir -p ~/frontend-project
cd ~/frontend-project
npm create vite@latest my-app -- --template react
cd my-app
npm install
```

### 3. Install Tailwind
```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### 4. Configure Tailwind (tailwind.config.js)
```javascript
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
```

### 5. Update src/index.css
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### 6. Convert component.txt to App.jsx
```bash
cp ~/component.txt ~/frontend-project/my-app/src/App.jsx
```

### 7. Run the app
```bash
cd ~/frontend-project/my-app
npm run dev -- --host 0.0.0.0
```

---

## 🎓 What Each Tool Does

| Tool | Purpose |
|------|---------|
| **npm** | Node Package Manager - installs JavaScript libraries |
| **Vite** | Fast build tool for modern web apps |
| **React** | JavaScript library for building user interfaces |
| **Tailwind CSS** | Utility-first CSS framework for styling |
| **JSX** | JavaScript XML - lets you write HTML in JavaScript |

---

## ✅ Success Checklist

- [ ] Azure VM created and running
- [ ] SSH connection working
- [ ] Node.js and npm installed (`node --version` works)
- [ ] React project created in `~/frontend-project/my-app`
- [ ] Tailwind CSS installed and configured
- [ ] component.txt converted to App.jsx
- [ ] Dev server running on port 5173
- [ ] Can access the app from browser
- [ ] Counter buttons work
- [ ] Active/Inactive toggle works
- [ ] Styles look correct (gradients, colors, animations)

---

## 🔥 Quick Command Reference

```bash
# SSH into VM
ssh azureuser@YOUR_VM_IP

# Check Node.js version
node --version

# Check npm version
npm --version

# Navigate to project
cd ~/frontend-project/my-app

# Install packages
npm install

# Run development server
npm run dev -- --host 0.0.0.0

# Stop the server
Ctrl + C

# Check what's running on port 5173
sudo lsof -i :5173

# View package.json
cat package.json

# Clean and reinstall (if issues)
rm -rf node_modules package-lock.json
npm install
```

---

## 📞 Need Help?

Common issues are listed in the **Troubleshooting** section above.

For Azure-specific issues, check the [Azure Documentation](https://docs.microsoft.com/azure/).

---

**Good luck with your deployment! 🚀**
