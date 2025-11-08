#!/bin/bash

# PHC AI Co-Pilot - FAST Sync Script for Development
# Use this during hackathon for quick updates (10-30 seconds instead of 3-5 minutes!)

set -e

echo "⚡ PHC AI Co-Pilot - FAST Sync Mode"
echo "======================================"
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

# Get unique suffix for bucket names
UNIQUE_SUFFIX=$(date +%s)

echo "⚡ Starting sync mode (watch for changes)..."
echo "   This will:"
echo "   - Deploy ONLY changed Lambda code (10-30 seconds)"
echo "   - Skip unchanged infrastructure (DynamoDB, S3, etc.)"
echo "   - Auto-watch for file changes"
echo ""
echo "💡 TIP: Keep this running and edit your Lambda code!"
echo "   Changes will auto-deploy in seconds."
echo ""

# Use sam sync for fast updates
sam sync \
  --stack-name phc-backend \
  --region eu-north-1 \
  --parameter-overrides \
    GeminiApiKey="${GEMINI_API_KEY}" \
    AudioBucketName="phc-audio-uploads-${UNIQUE_SUFFIX}" \
    ImageBucketName="phc-image-uploads-${UNIQUE_SUFFIX}" \
  --watch

# Note: --watch will keep running and auto-deploy on file changes
# Press Ctrl+C to stop
