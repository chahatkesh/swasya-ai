#!/bin/bash
# Quick script to check processing results

PATIENT_ID=$1

if [ -z "$PATIENT_ID" ]; then
    echo "Usage: ./check-results.sh PAT_XXXXX"
    echo ""
    echo "Showing all patients..."
    aws dynamodb scan \
        --table-name Patients \
        --region eu-north-1 \
        --output table
    exit 1
fi

echo "🔍 Checking results for Patient: $PATIENT_ID"
echo ""

echo "📋 Patient Info:"
aws dynamodb get-item \
    --table-name Patients \
    --key "{\"patient_id\": {\"S\": \"$PATIENT_ID\"}}" \
    --region eu-north-1 \
    --output json | jq '.Item'

echo ""
echo "🩺 SOAP Notes:"
aws dynamodb query \
    --table-name PatientNotes \
    --key-condition-expression "patient_id = :pid" \
    --expression-attribute-values "{\":pid\":{\"S\":\"$PATIENT_ID\"}}" \
    --region eu-north-1 \
    --output json | jq '.Items'

echo ""
echo "📁 S3 Files:"
AUDIO_BUCKET=$(aws cloudformation describe-stacks --stack-name phc-backend --region eu-north-1 --query "Stacks[0].Outputs[?OutputKey=='AudioBucketName'].OutputValue" --output text)
IMAGE_BUCKET=$(aws cloudformation describe-stacks --stack-name phc-backend --region eu-north-1 --query "Stacks[0].Outputs[?OutputKey=='ImageBucketName'].OutputValue" --output text)

echo "Audio files:"
aws s3 ls "s3://$AUDIO_BUCKET/$PATIENT_ID/" --region eu-north-1 || echo "No audio files found"

echo ""
echo "Image files:"
aws s3 ls "s3://$IMAGE_BUCKET/$PATIENT_ID/" --region eu-north-1 || echo "No image files found"
