#!/bin/bash

# DocuMind File Creation Helper
# This script helps you create admin.html and user.html from your text files

echo "=================================================="
echo "  DocuMind - HTML File Creation Helper"
echo "=================================================="
echo ""

# Check if text files exist
if [ ! -f "Admin portal v0.2.txt" ] && [ ! -f "admin_portal_v0.2.txt" ]; then
    echo "❌ Admin portal text file not found."
    echo ""
    echo "Please do ONE of the following:"
    echo ""
    echo "Option 1: Copy the file to this directory"
    echo "  - Name it: 'Admin portal v0.2.txt'"
    echo ""
    echo "Option 2: Create admin.html manually"
    echo "  - Open your 'Admin portal v0.2.txt' file"
    echo "  - Copy ALL the content"
    echo "  - Save it as 'admin.html' in this directory"
    echo ""
else
    echo "✅ Found Admin portal file"
    
    # Try to copy it
    if [ -f "Admin portal v0.2.txt" ]; then
        cp "Admin portal v0.2.txt" admin.html
        echo "✅ Created admin.html"
    else
        cp "admin_portal_v0.2.txt" admin.html  
        echo "✅ Created admin.html"
    fi
fi

echo ""

if [ ! -f "Standard user v0.1.txt" ] && [ ! -f "standard_user_v0.1.txt" ]; then
    echo "❌ Standard user text file not found."
    echo ""
    echo "Please do ONE of the following:"
    echo ""
    echo "Option 1: Copy the file to this directory"
    echo "  - Name it: 'Standard user v0.1.txt'"
    echo ""
    echo "Option 2: Create user.html manually"
    echo "  - Open your 'Standard user v0.1.txt' file"
    echo "  - Copy ALL the content"
    echo "  - Save it as 'user.html' in this directory"
    echo ""
else
    echo "✅ Found Standard user file"
    
    # Try to copy it
    if [ -f "Standard user v0.1.txt" ]; then
        cp "Standard user v0.1.txt" user.html
        echo "✅ Created user.html"
    else
        cp "standard_user_v0.1.txt" user.html
        echo "✅ Created user.html"
    fi
fi

echo ""
echo "=================================================="
echo "  File Status"
echo "=================================================="
echo ""

# Check all required files
for file in "index.html" "login.html" "admin.html" "user.html"; do
    if [ -f "$file" ]; then
        SIZE=$(wc -c < "$file")
        echo "✅ $file (${SIZE} bytes)"
    else
        echo "❌ $file - MISSING"
    fi
done

echo ""
echo "Once all files are ready, use './upload.sh' to deploy!"
echo ""
