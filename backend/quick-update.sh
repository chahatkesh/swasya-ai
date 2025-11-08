#!/bin/bash

# PHC AI Co-Pilot - Quick Lambda Update Script
# Updates ONLY Lambda code without rebuilding infrastructure (10-20 seconds!)

set -e

echo "⚡ Quick Lambda Update"
echo "======================"
echo ""

if [ -z "$1" ]; then
    echo "Usage: ./quick-update.sh <function-name>"
    echo ""
    echo "Available functions:"
    echo "  - patient_registration"
    echo "  - presigned_url"
    echo "  - scribe_task"
    echo "  - digitize_task"
    echo ""
    echo "Example: ./quick-update.sh scribe_task"
    exit 1
fi

FUNCTION=$1
FUNCTION_DIR="lambdas/${FUNCTION}"

if [ ! -d "$FUNCTION_DIR" ]; then
    echo "❌ Function directory not found: $FUNCTION_DIR"
    exit 1
fi

echo "📦 Packaging ${FUNCTION}..."
cd "$FUNCTION_DIR"

# Create deployment package
zip -q -r /tmp/${FUNCTION}.zip . -x "*.pyc" -x "__pycache__/*" -x "test_*.py"

echo "⬆️  Uploading to AWS..."

# Get the full function name from CloudFormation
STACK_NAME="phc-backend"
FULL_FUNCTION_NAME=$(aws cloudformation describe-stack-resources \
  --stack-name $STACK_NAME \
  --region eu-north-1 \
  --query "StackResources[?contains(LogicalResourceId, '${FUNCTION^}')].PhysicalResourceId" \
  --output text | head -1)

if [ -z "$FULL_FUNCTION_NAME" ]; then
    echo "❌ Could not find deployed function"
    exit 1
fi

# Update Lambda function code
aws lambda update-function-code \
  --function-name "$FULL_FUNCTION_NAME" \
  --zip-file fileb:///tmp/${FUNCTION}.zip \
  --region eu-north-1 \
  --output json \
  > /dev/null

echo "✅ Updated ${FUNCTION} successfully!"
echo "   Function: $FULL_FUNCTION_NAME"
echo ""

# Clean up
rm /tmp/${FUNCTION}.zip

cd ../..
