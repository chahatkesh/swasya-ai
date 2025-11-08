#!/bin/bash

# PHC AI Co-Pilot - End-to-End Integration Tests
# Tests the FULL pipeline with real AWS services

set -e

echo "🧪 PHC AI Co-Pilot - Integration Tests"
echo "========================================"
echo ""
echo "This will test:"
echo "  1. Patient Registration API"
echo "  2. Presigned URL Generation"
echo "  3. Audio Upload → Transcribe → Gemini → SOAP"
echo "  4. Image Upload → Textract → Gemini → Medications"
echo ""

# Check if deployment is complete
echo "Checking deployment status..."
STACK_STATUS=$(aws cloudformation describe-stacks \
  --stack-name phc-backend \
  --region eu-north-1 \
  --query 'Stacks[0].StackStatus' \
  --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$STACK_STATUS" != "CREATE_COMPLETE" ] && [ "$STACK_STATUS" != "UPDATE_COMPLETE" ]; then
    echo "❌ Stack not deployed or deployment failed!"
    echo "   Current status: $STACK_STATUS"
    echo ""
    echo "   Run ./deploy.sh first"
    exit 1
fi

echo "✅ Stack is deployed: $STACK_STATUS"
echo ""

# Get API endpoints
echo "📡 Fetching API endpoints..."
API_URL=$(aws cloudformation describe-stacks \
  --stack-name phc-backend \
  --region eu-north-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text)

AUDIO_BUCKET=$(aws cloudformation describe-stacks \
  --stack-name phc-backend \
  --region eu-north-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`AudioBucket`].OutputValue' \
  --output text)

IMAGE_BUCKET=$(aws cloudformation describe-stacks \
  --stack-name phc-backend \
  --region eu-north-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ImageBucket`].OutputValue' \
  --output text)

echo "API URL: $API_URL"
echo "Audio Bucket: $AUDIO_BUCKET"
echo "Image Bucket: $IMAGE_BUCKET"
echo ""

# Test 1: Patient Registration
echo "📋 TEST 1: Patient Registration"
echo "================================"
PATIENT_RESPONSE=$(curl -s -X POST "${API_URL}patients" \
  -H "Content-Type: application/json" \
  -d '{"name": "Integration Test Patient", "phone": "9999999999", "age": 35, "gender": "M"}')

echo "Response: $PATIENT_RESPONSE"

PATIENT_ID=$(echo $PATIENT_RESPONSE | jq -r '.patient_id' 2>/dev/null || echo "ERROR")

if [ "$PATIENT_ID" = "ERROR" ] || [ -z "$PATIENT_ID" ]; then
    echo "❌ TEST 1 FAILED: Could not register patient"
    echo "   Response: $PATIENT_RESPONSE"
    exit 1
fi

echo "✅ TEST 1 PASSED: Patient registered with ID: $PATIENT_ID"
echo ""

# Test 2: Generate Presigned URL for Audio
echo "🔗 TEST 2: Presigned URL (Audio)"
echo "================================"
AUDIO_PRESIGNED_RESPONSE=$(curl -s -X POST "${API_URL}upload-url" \
  -H "Content-Type: application/json" \
  -d "{\"patient_id\": \"$PATIENT_ID\", \"file_type\": \"audio\", \"file_extension\": \"mp3\"}")

echo "Response: $AUDIO_PRESIGNED_RESPONSE"

AUDIO_UPLOAD_URL=$(echo $AUDIO_PRESIGNED_RESPONSE | jq -r '.upload_url' 2>/dev/null || echo "ERROR")
AUDIO_FILE_KEY=$(echo $AUDIO_PRESIGNED_RESPONSE | jq -r '.file_key' 2>/dev/null || echo "ERROR")

if [ "$AUDIO_UPLOAD_URL" = "ERROR" ] || [ -z "$AUDIO_UPLOAD_URL" ]; then
    echo "❌ TEST 2 FAILED: Could not get presigned URL"
    exit 1
fi

echo "✅ TEST 2 PASSED: Got presigned URL"
echo "   File will be: $AUDIO_FILE_KEY"
echo ""

# Test 3: Create and Upload Real Audio File
echo "🎤 TEST 3: Audio Upload → Transcribe → Gemini"
echo "=============================================="

# Create a test audio file (English - safer for first test)
echo "Creating test audio file..."
say "Patient complains of fever and headache for two days. Temperature is 101 degrees Fahrenheit." -o /tmp/test_audio.mp3

if [ ! -f /tmp/test_audio.mp3 ]; then
    echo "❌ Failed to create audio file"
    exit 1
fi

echo "✅ Audio file created: /tmp/test_audio.mp3"
echo ""

# Upload to S3 via presigned URL
echo "Uploading audio to S3..."
UPLOAD_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$AUDIO_UPLOAD_URL" \
  --upload-file /tmp/test_audio.mp3 \
  -H "Content-Type: audio/mp3")

HTTP_CODE=$(echo "$UPLOAD_RESPONSE" | tail -1)

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Upload failed with HTTP $HTTP_CODE"
    exit 1
fi

echo "✅ Audio uploaded to S3"
echo "   Key: $AUDIO_FILE_KEY"
echo ""

# Wait for processing
echo "⏳ Waiting for Scribe Lambda to process (30 seconds)..."
echo "   Pipeline: S3 → Lambda → Transcribe → Gemini → DynamoDB"
for i in {30..1}; do
    echo -ne "   $i seconds remaining...\r"
    sleep 1
done
echo ""

# Check DynamoDB for SOAP note
echo "🔍 Checking DynamoDB for SOAP note..."
SOAP_RESULT=$(aws dynamodb query \
  --table-name PatientNotes \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values "{\":pid\":{\"S\":\"$PATIENT_ID\"}}" \
  --region eu-north-1 \
  --output json)

ITEM_COUNT=$(echo "$SOAP_RESULT" | jq '.Items | length')

if [ "$ITEM_COUNT" -eq 0 ]; then
    echo "❌ TEST 3 FAILED: No SOAP note found in DynamoDB"
    echo ""
    echo "Debugging info:"
    echo "1. Check Lambda logs:"
    echo "   sam logs -n ScribeTaskFunction --tail --region eu-north-1"
    echo ""
    echo "2. Check S3 bucket:"
    echo "   aws s3 ls s3://$AUDIO_BUCKET/ --recursive"
    echo ""
    echo "3. Check Transcribe jobs:"
    echo "   aws transcribe list-transcription-jobs --region eu-north-1"
    echo ""
    exit 1
fi

echo "✅ TEST 3 PASSED: SOAP note generated!"
echo ""
echo "SOAP Note:"
echo "$SOAP_RESULT" | jq '.Items[0].soap_note.S' | jq '.'
echo ""

# Test 4: Generate Presigned URL for Image
echo "🖼️  TEST 4: Presigned URL (Image)"
echo "================================"
IMAGE_PRESIGNED_RESPONSE=$(curl -s -X POST "${API_URL}upload-url" \
  -H "Content-Type: application/json" \
  -d "{\"patient_id\": \"$PATIENT_ID\", \"file_type\": \"image\", \"file_extension\": \"jpg\"}")

IMAGE_UPLOAD_URL=$(echo $IMAGE_PRESIGNED_RESPONSE | jq -r '.upload_url' 2>/dev/null || echo "ERROR")
IMAGE_FILE_KEY=$(echo $IMAGE_PRESIGNED_RESPONSE | jq -r '.file_key' 2>/dev/null || echo "ERROR")

if [ "$IMAGE_UPLOAD_URL" = "ERROR" ]; then
    echo "❌ TEST 4 FAILED: Could not get presigned URL"
    exit 1
fi

echo "✅ TEST 4 PASSED: Got presigned URL"
echo "   File will be: $IMAGE_FILE_KEY"
echo ""

# Test 5: Create and Upload Test Image
echo "📄 TEST 5: Image Upload → Textract → Gemini"
echo "============================================"

# Create a simple prescription image
echo "Creating test prescription image..."
cat > /tmp/prescription.txt << 'EOF'
Dr. Kumar's Clinic
Date: 08-11-2025

Rx:
1. Paracetamol 500mg - 1 tablet twice daily for 3 days
2. Amoxicillin 250mg - 1 capsule three times daily for 5 days

Dr. R. Kumar
EOF

# Convert text to image (requires ImageMagick - install with: brew install imagemagick)
if command -v convert &> /dev/null; then
    convert -size 600x400 -background white -fill black \
      -font Courier -pointsize 14 \
      label:@/tmp/prescription.txt \
      /tmp/prescription.jpg
    echo "✅ Prescription image created using ImageMagick"
else
    echo "⚠️  ImageMagick not found - Using placeholder"
    echo "   To create real prescription images: brew install imagemagick"
    echo ""
    echo "   For now, please manually create a test image at:"
    echo "   /tmp/prescription.jpg"
    echo ""
    read -p "   Press Enter when ready, or 's' to skip: " -n 1 skip
    if [ "$skip" = "s" ]; then
        echo ""
        echo "⏭️  Skipping image test"
        echo ""
        echo "📊 SUMMARY"
        echo "=========="
        echo "✅ Patient Registration: PASSED"
        echo "✅ Presigned URL (Audio): PASSED"
        echo "✅ Audio → SOAP Pipeline: PASSED"
        echo "⏭️  Image → Medications Pipeline: SKIPPED"
        exit 0
    fi
fi
echo ""

# Upload image
echo "Uploading prescription image to S3..."
IMAGE_UPLOAD_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$IMAGE_UPLOAD_URL" \
  --upload-file /tmp/prescription.jpg \
  -H "Content-Type: image/jpeg")

IMAGE_HTTP_CODE=$(echo "$IMAGE_UPLOAD_RESPONSE" | tail -1)

if [ "$IMAGE_HTTP_CODE" != "200" ]; then
    echo "❌ Upload failed with HTTP $IMAGE_HTTP_CODE"
    exit 1
fi

echo "✅ Image uploaded to S3"
echo ""

# Wait for processing
echo "⏳ Waiting for Digitize Lambda to process (30 seconds)..."
echo "   Pipeline: S3 → Lambda → Textract → Gemini → DynamoDB"
for i in {30..1}; do
    echo -ne "   $i seconds remaining...\r"
    sleep 1
done
echo ""

# Check DynamoDB for medication data
echo "🔍 Checking DynamoDB for medication data..."
MEDS_RESULT=$(aws dynamodb query \
  --table-name PatientHistory \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values "{\":pid\":{\"S\":\"$PATIENT_ID\"}}" \
  --region eu-north-1 \
  --output json)

MEDS_COUNT=$(echo "$MEDS_RESULT" | jq '.Items | length')

if [ "$MEDS_COUNT" -eq 0 ]; then
    echo "❌ TEST 5 FAILED: No medication data found in DynamoDB"
    echo ""
    echo "Debugging info:"
    echo "1. Check Lambda logs:"
    echo "   sam logs -n DigitizeTaskFunction --tail --region eu-north-1"
    echo ""
    echo "2. Check S3 bucket:"
    echo "   aws s3 ls s3://$IMAGE_BUCKET/ --recursive"
    echo ""
    echo "3. Check Textract async jobs:"
    echo "   aws textract list-document-analysis-jobs --region eu-north-1"
    echo ""
    exit 1
fi

echo "✅ TEST 5 PASSED: Medication data extracted!"
echo ""
echo "Extracted Data:"
echo "$MEDS_RESULT" | jq '.Items[0].medications.S' | jq '.'
echo ""

# Final Summary
echo ""
echo "🎉 ALL TESTS PASSED!"
echo "===================="
echo ""
echo "✅ Patient Registration: WORKING"
echo "✅ Presigned URLs: WORKING"
echo "✅ Audio → Transcribe → Gemini → SOAP: WORKING"
echo "✅ Image → Textract → Gemini → Medications: WORKING"
echo ""
echo "📋 Test Patient ID: $PATIENT_ID"
echo ""
echo "Next steps:"
echo "  1. Connect mobile app to these APIs"
echo "  2. Test with Hindi audio"
echo "  3. Test with real handwritten prescriptions"
echo "  4. Build doctor dashboard"
echo ""
