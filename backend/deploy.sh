#!/bin/bash

# PHC AI Co-Pilot - Deployment Script
# This script deploys the entire backend to AWS

set -e  # Exit on error

echo "PHC AI Co-Pilot - Backend Deployment"
echo "========================================"
echo ""

# Check if GEMINI_API_KEY is set
if [ -z "$GEMINI_API_KEY" ]; then
    echo "❌ ERROR: GEMINI_API_KEY environment variable is not set!"
    echo ""
    echo "Please set it first:"
    echo "  export GEMINI_API_KEY='your-api-key-here'"
    echo ""
    exit 1
fi

echo "✅ GEMINI_API_KEY is set"
echo ""

# Get unique suffix for bucket names (to avoid conflicts)
UNIQUE_SUFFIX=$(date +%s)

echo "📝 Deployment Configuration:"
echo "   Region: eu-north-1"
echo "   Audio Bucket: phc-audio-uploads-${UNIQUE_SUFFIX}"
echo "   Image Bucket: phc-image-uploads-${UNIQUE_SUFFIX}"
echo ""

# Build Lambda functions
echo "🔨 Building Lambda functions..."
sam build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build complete!"
echo ""

# Deploy
echo "Deploying to AWS..."
echo ""

sam deploy \
  --stack-name phc-backend \
  --region eu-north-1 \
  --capabilities CAPABILITY_IAM \
  --resolve-s3 \
  --parameter-overrides \
    GeminiApiKey="${GEMINI_API_KEY}" \
    AudioBucketName="phc-audio-uploads-${UNIQUE_SUFFIX}" \
    ImageBucketName="phc-image-uploads-${UNIQUE_SUFFIX}" \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Get API endpoint: sam list stack-outputs --stack-name phc-backend"
    echo "   2. Test endpoints with curl or Postman"
    echo "   3. Configure mobile app with the API endpoint"
    echo ""
else
    echo ""
    echo "❌ Deployment failed!"
    exit 1
fi
