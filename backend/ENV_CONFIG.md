# Environment Variables Configuration

## Overview
All Lambda functions use environment variables for configuration. This keeps secrets secure and makes deployment flexible.

## Required Environment Variables

### All Lambda Functions
```bash
AWS_REGION=eu-north-1
```

### Scribe Task & Digitize Task (Gemini AI)
```bash
GEMINI_API_KEY=your-gemini-api-key-here
```

### Presigned URL Generator
```bash
AUDIO_BUCKET=phc-audio-uploads-your-unique-id
IMAGE_BUCKET=phc-image-uploads-your-unique-id
```

---

## How Serverless Lambda Gets Environment Variables

### Method 1: SAM Template (Recommended)
In `template.yaml`, define environment variables for each function:

```yaml
Resources:
  ScribeTaskFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: lambdas/scribe_task/
      Handler: handler.lambda_handler
      Environment:
        Variables:
          AWS_REGION: eu-north-1
          GEMINI_API_KEY: !Ref GeminiApiKeyParameter
```

### Method 2: AWS Secrets Manager (Production Best Practice)
Store sensitive data in AWS Secrets Manager and reference it:

```yaml
Environment:
  Variables:
    GEMINI_API_KEY: '{{resolve:secretsmanager:phc-gemini-api-key:SecretString:api_key}}'
```

Create secret:
```bash
aws secretsmanager create-secret \
  --name phc-gemini-api-key \
  --secret-string '{"api_key":"AIzaSyBXdNN1Z0lk9JOvNuC-bIv5sMrkaPU0Fws"}' \
  --region eu-north-1
```

### Method 3: AWS Systems Manager Parameter Store
```bash
# Store parameter
aws ssm put-parameter \
  --name /phc/gemini-api-key \
  --value "AIzaSyBXdNN1Z0lk9JOvNuC-bIv5sMrkaPU0Fws" \
  --type SecureString \
  --region eu-north-1

# Reference in SAM template
Environment:
  Variables:
    GEMINI_API_KEY: '{{resolve:ssm-secure:/phc/gemini-api-key}}'
```

---

## Local Testing

### Option 1: Export in Terminal
```bash
export GEMINI_API_KEY="AIzaSyBXdNN1Z0lk9JOvNuC-bIv5sMrkaPU0Fws"
export AWS_REGION="eu-north-1"

python3 test_local.py
```

### Option 2: .env File (for local only)
Create `.env` file (add to .gitignore):
```bash
GEMINI_API_KEY=AIzaSyBXdNN1Z0lk9JOvNuC-bIv5sMrkaPU0Fws
AWS_REGION=eu-north-1
AUDIO_BUCKET=phc-audio-uploads
IMAGE_BUCKET=phc-image-uploads
```

Load with python-dotenv:
```python
from dotenv import load_dotenv
load_dotenv()
```

### Option 3: Set in Code (test files only)
```python
# ONLY for testing - test_local.py already has this
os.environ['GEMINI_API_KEY'] = 'your-key'
os.environ['AWS_REGION'] = 'eu-north-1'
```

---

## Deployment Commands

### Deploy with inline environment variables:
```bash
sam deploy \
  --parameter-overrides \
    GeminiApiKey=AIzaSyBXdNN1Z0lk9JOvNuC-bIv5sMrkaPU0Fws \
    AudioBucket=phc-audio-uploads-unique \
    ImageBucket=phc-image-uploads-unique
```

### View environment variables of deployed Lambda:
```bash
aws lambda get-function-configuration \
  --function-name ScribeTaskFunction \
  --region eu-north-1 \
  --query 'Environment'
```

### Update environment variable after deployment:
```bash
aws lambda update-function-configuration \
  --function-name ScribeTaskFunction \
  --environment "Variables={GEMINI_API_KEY=new-key,AWS_REGION=eu-north-1}" \
  --region eu-north-1
```

---

## Security Best Practices

### ✅ DO:
- Use AWS Secrets Manager for production
- Use Parameter Store for non-sensitive config
- Set IAM permissions to restrict secret access
- Rotate API keys regularly
- Use different keys for dev/staging/prod

### ❌ DON'T:
- Hardcode secrets in code
- Commit .env files to git
- Share API keys in Slack/Email
- Use same key across multiple environments

---

## Why We Use Environment Variables

1. **Security**: Secrets not in code/git history
2. **Flexibility**: Change config without redeploying code
3. **Multiple Environments**: Different keys for dev/staging/prod
4. **AWS Best Practice**: Recommended by AWS Lambda documentation
5. **Easy CI/CD**: GitHub Actions can inject secrets

---

## Current Configuration

```
AWS Region: eu-north-1 (Stockholm)
Gemini Model: gemini-2.5-flash
API Key Source: Environment variable GEMINI_API_KEY
```

## Testing Updated Functions

```bash
# Test with environment variables
cd backend/lambdas/scribe_task
python3.12 test_local.py

cd ../digitize_task
python3.12 test_local.py
```
