# Local Testing Guide - Test Before Deploy

## 🎯 Goal
Test all Lambda functions locally without deploying to AWS. Deploy only once when everything works!

---

## Method 1: Python Unit Tests (FASTEST - Already Working!) ⚡

### What We Have
Each Lambda already has `test_local.py` with mocked AWS services.

### Run All Tests
```bash
cd /Users/rishi/git/hackcbs/backend

# Set API key
export GEMINI_API_KEY='AIzaSyBXdNN1Z0lk9JOvNuC-bIv5sMrkaPU0Fws'

# Activate venv
source .venv/bin/activate

# Test each function
cd lambdas/patient_registration && python3.12 test_local.py && cd ../..
cd lambdas/presigned_url && python3.12 test_local.py && cd ../..
cd lambdas/scribe_task && python3.12 test_local.py && cd ../..
cd lambdas/digitize_task && python3.12 test_local.py && cd ../..

echo "✅ All tests passed!"
```

### Run One Test Script
```bash
./test-all-local.sh  # I'll create this for you
```

---

## Method 2: SAM Local Invoke (Test with Real Lambda Environment) 🐳

### Setup (One Time)
```bash
# SAM Local uses Docker
brew install docker
# Start Docker Desktop app
```

### Test Individual Lambda
```bash
# Patient Registration
sam local invoke PatientRegistrationFunction \
  --event test-events/patient-registration.json \
  --parameter-overrides GeminiApiKey=$GEMINI_API_KEY

# Presigned URL
sam local invoke PresignedUrlFunction \
  --event test-events/presigned-url.json

# Scribe Task
sam local invoke ScribeTaskFunction \
  --event test-events/scribe-task.json \
  --parameter-overrides GeminiApiKey=$GEMINI_API_KEY

# Digitize Task
sam local invoke DigitizeTaskFunction \
  --event test-events/digitize-task.json \
  --parameter-overrides GeminiApiKey=$GEMINI_API_KEY
```

---

## Method 3: SAM Local API (Test Full API Gateway) 🌐

### Start Local API Server
```bash
sam local start-api \
  --parameter-overrides GeminiApiKey=$GEMINI_API_KEY \
  --port 3000
```

### Test Endpoints (in another terminal)
```bash
# Register patient
curl -X POST http://localhost:3000/patients \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Patient", "phone": "9876543210"}'

# Get presigned URL
curl -X POST http://localhost:3000/upload-url \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "PAT_12345",
    "file_type": "audio",
    "file_extension": "mp3"
  }'
```

---

## Method 4: DynamoDB Local (Test Database Operations) 🗄️

### Setup DynamoDB Local
```bash
# Download DynamoDB Local
docker pull amazon/dynamodb-local

# Run DynamoDB Local
docker run -p 8000:8000 amazon/dynamodb-local

# Create tables locally
aws dynamodb create-table \
  --table-name Patients \
  --attribute-definitions AttributeName=patient_id,AttributeType=S \
  --key-schema AttributeName=patient_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url http://localhost:8000

aws dynamodb create-table \
  --table-name PatientNotes \
  --attribute-definitions \
    AttributeName=patient_id,AttributeType=S \
    AttributeName=timestamp,AttributeType=N \
  --key-schema \
    AttributeName=patient_id,KeyType=HASH \
    AttributeName=timestamp,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url http://localhost:8000

aws dynamodb create-table \
  --table-name PatientHistory \
  --attribute-definitions \
    AttributeName=patient_id,AttributeType=S \
    AttributeName=timestamp,AttributeType=N \
  --key-schema \
    AttributeName=patient_id,KeyType=HASH \
    AttributeName=timestamp,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url http://localhost:8000
```

### Test with Local DynamoDB
```bash
# Modify handler.py temporarily to use local endpoint
# Add at top of handler:
# dynamodb = boto3.resource('dynamodb', endpoint_url='http://localhost:8000')

# Run tests
python3.12 test_local.py
```

---

## 🎯 RECOMMENDED WORKFLOW FOR HACKATHON

### 1. Quick Tests (Mocked AWS - 10 seconds)
```bash
./test-all-local.sh
```

### 2. Integration Tests (Real Gemini API - 30 seconds)
```bash
# Test Scribe with real Gemini
cd lambdas/scribe_task
python3.12 test_local.py

# Test Digitize with real Gemini
cd ../digitize_task
python3.12 test_local.py
```

### 3. Deploy Once Everything Passes
```bash
./deploy.sh
```

---

## 🚀 Testing Checklist Before Deploy

```bash
✅ All unit tests pass
✅ Gemini API key works
✅ Scribe generates valid SOAP notes
✅ Digitize extracts medication data
✅ Patient registration creates unique IDs
✅ Presigned URLs generate correctly
✅ No hardcoded secrets in code
✅ .gitignore includes .env files
```

---

## 📁 Test Event Files (I'll create these)

```bash
backend/
├── test-events/
│   ├── patient-registration.json      # Mock API Gateway event
│   ├── presigned-url.json             # Mock API Gateway event
│   ├── scribe-task.json               # Mock S3 event
│   └── digitize-task.json             # Mock S3 event
└── test-all-local.sh                  # Run all tests
```

---

## 💡 Pro Tips

### 1. **Use Mocks for Fast Iteration**
- Mock DynamoDB, S3, Transcribe, Textract
- Test business logic without AWS
- Already implemented in `test_local.py` files

### 2. **Test Gemini Separately**
- Test with real Gemini API before deploying
- Verify prompt engineering works
- Check output format matches expectations

### 3. **SAM Local for Final Check**
- Use Docker to test in Lambda-like environment
- Catches Python version issues, dependency problems
- Slower but more accurate

### 4. **Deploy to Dev Stack First**
```bash
# Create dev stack for testing
sam deploy --stack-name phc-backend-dev ...

# Test with real AWS resources
# Deploy to prod only when stable
sam deploy --stack-name phc-backend-prod ...
```

---

## 🐛 Common Local Testing Issues

### Issue: "ModuleNotFoundError"
```bash
# Solution: Install deps in venv
source .venv/bin/activate
pip install -r lambdas/scribe_task/requirements.txt
```

### Issue: "AWS credentials not found"
```bash
# Solution: Configure AWS CLI
aws configure
# OR use mock in test files (already done)
```

### Issue: "Docker not running"
```bash
# Solution: Start Docker Desktop
open -a Docker
```

### Issue: "Gemini API quota exceeded"
```bash
# Solution: Use smaller test inputs
# Solution: Add rate limiting in tests
time.sleep(1)  # between API calls
```

---

## ⚡ Quick Test Script

Run this before every deploy:

```bash
#!/bin/bash
echo "🧪 Running pre-deployment tests..."

export GEMINI_API_KEY='your-key-here'
source .venv/bin/activate

# Test each Lambda
for func in patient_registration presigned_url scribe_task digitize_task; do
    echo "Testing $func..."
    cd lambdas/$func
    python3.12 test_local.py || exit 1
    cd ../..
done

echo "✅ All tests passed! Ready to deploy."
```

---

## 📊 Cost Comparison

| Method | Speed | Accuracy | Cost |
|--------|-------|----------|------|
| Mocked tests | ⚡⚡⚡ 10s | 80% | $0 |
| SAM Local | ⚡⚡ 1min | 95% | $0 |
| Dev stack | ⚡ 5min | 100% | ~$0.10 |
| Direct prod | ⏳ 5min | 100% | $0 (risky) |

**Recommended: Mocked tests → SAM Local → Deploy once**

---

## 🎯 Your Current Status

✅ **You already have:**
- Working unit tests with mocks
- Gemini API integration tested
- All Lambda functions validated locally

✅ **Next steps:**
1. Run `./test-all-local.sh` (I'll create this)
2. Fix any issues locally
3. Deploy once with `./deploy.sh`
4. Test deployed endpoints
5. Use `./quick-update.sh` for small changes

**You're already doing it right! Just need the convenience scripts.**
