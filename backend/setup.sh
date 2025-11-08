#!/bin/bash

# PHC AI Co-Pilot - Backend Setup Script
# This script sets up a single Python virtual environment for all Lambda functions

echo "Setting up backend environment..."
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.11 or higher."
    exit 1
fi

echo "✅ Python version: $(python3 --version)"

# Navigate to backend directory
cd "$(dirname "$0")"

# Create virtual environment
echo ""
echo "Creating virtual environment..."
python3 -m venv .venv

# Activate virtual environment
echo "Activating virtual environment..."
source .venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install shared dependencies
echo "Installing dependencies..."
echo ""
pip install boto3==1.34.144
pip install google-generativeai==0.3.2

echo ""
echo "="*60
echo "✅ Backend environment setup complete!"
echo "="*60
echo ""
echo "Next steps:"
echo "   1. Activate the virtual environment:"
echo "      source .venv/bin/activate"
echo ""
echo "   2. Test Lambda functions locally:"
echo "      cd lambdas/patient_registration"
echo "      python3 test_local.py"
echo ""
echo "   3. Install AWS SAM CLI (if not already):"
echo "      brew install aws-sam-cli"
echo ""
echo "   4. Deploy to AWS:"
echo "      sam build"
echo "      sam deploy --guided"
echo ""
