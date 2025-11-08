# PHC AI Co-Pilot - Backend

## Overview
Serverless backend for the PHC AI Co-Pilot using AWS Lambda functions.

## Architecture
```
Mobile App → API Gateway → Lambda Functions → DynamoDB
                ↓
            S3 Buckets → Lambda (Scribe/Digitize) → Gemini API → DynamoDB
```

## Lambda Functions

1. **patient_registration** - Register new patients (API: POST /patients)
2. **presigned_url** - Generate S3 upload URLs (API: POST /upload-url)
3. **scribe_task** - Audio → Transcribe → Gemini → SOAP notes (S3 trigger)
4. **digitize_task** - Image → Textract → Gemini → Medication history (S3 trigger)

## Quick Start

### 1. Setup Environment
```bash
# Run the setup script (creates .venv and installs dependencies)
./setup.sh

# Or manually:
python3 -m venv .venv
source .venv/bin/activate
pip install boto3 google-generativeai
```

### 2. Test Locally
```bash
source .venv/bin/activate

# Test patient registration
cd lambdas/patient_registration
python3 test_local.py

# Test scribe (Gemini SOAP note generation)
cd ../scribe_task
python3 test_local.py

# Test digitizer (Gemini medical data extraction)
cd ../digitize_task
python3 test_local.py
```

### 3. Deploy to AWS
```bash
# Install SAM CLI
brew install aws-sam-cli

# Build and deploy
sam build
sam deploy --guided
```

## Environment Variables

Gemini API Key is hardcoded in the Lambda functions:
```python
GEMINI_API_KEY = 'AIzaSyBXdNN1Z0lk9JOvNuC-bIv5sMrkaPU0Fws'
```

For production, use AWS Secrets Manager or environment variables.

## Project Structure
```
backend/
├── .venv/                          # Virtual environment (not committed)
├── lambdas/
│   ├── patient_registration/
│   │   ├── handler.py
│   │   ├── requirements.txt
│   │   └── test_local.py
│   ├── presigned_url/
│   │   ├── handler.py
│   │   ├── requirements.txt
│   │   └── test_local.py
│   ├── scribe_task/
│   │   ├── handler.py              # Audio → Transcribe → Gemini
│   │   ├── requirements.txt
│   │   └── test_local.py
│   └── digitize_task/
│       ├── handler.py              # Image → Textract → Gemini
│       ├── requirements.txt
│       └── test_local.py
├── template.yaml                   # SAM template (coming next)
├── setup.sh                        # Setup script
└── README.md
```

## Testing Strategy

### Local Testing (No AWS)
- Tests Lambda function logic
- Tests Gemini API integration
- Fast feedback loop
- Run: `python3 test_local.py` in each Lambda folder

### AWS Testing (After Deployment)
- Test actual S3 triggers
- Test Transcribe and Textract
- Test DynamoDB writes
- Use: curl commands or mobile app

## Common Commands

```bash
# Activate venv
source .venv/bin/activate

# Test all functions
for dir in lambdas/*/; do
    echo "Testing $dir..."
    cd "$dir" && python3 test_local.py && cd -
done

# Deploy updates
sam build && sam deploy

# View Lambda logs
sam logs -n PatientRegistrationFunction --tail

# Delete everything
sam delete
```

## Next Steps

1. ✅ Lambda functions created
2. ⏳ Create SAM template (`template.yaml`)
3. ⏳ Create DynamoDB tables
4. ⏳ Create S3 buckets
5. ⏳ Deploy and test

See [BACKEND_MVP_PLAN.md](../BACKEND_MVP_PLAN.md) for detailed setup guide.
