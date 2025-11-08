# Backend MVP Plan - Step-by-Step Guide

## **What We're Building:**
A serverless backend that:
1. Stores patient data
2. Processes audio recordings into medical notes
3. Processes scanned documents into medication lists
4. Makes everything available via API

---

## **MVP Task 1: Setup Your AWS Account & Tools** ⏱️ 30 mins

### **What You're Doing:**
Getting your computer ready to talk to AWS.

### **Steps:**

#### 1.1 Create AWS Account
- Go to https://aws.amazon.com
- Click "Create an AWS Account"
- You'll get $300 free credits (perfect for hackathon!)
- **Important:** Enable MFA (security) on your root account

#### 1.2 Install AWS CLI (Command Line Tool)
```bash
# On macOS
brew install awscli

# Verify installation
aws --version
# Should show: aws-cli/2.x.x
```

**What is AWS CLI?** 
It's a tool that lets you control AWS from your terminal instead of clicking in the website.

#### 1.3 Configure AWS CLI with Your Credentials
```bash
aws configure
```
It will ask you for:
- **AWS Access Key ID:** Get this from AWS Console → IAM → Users → Create User → Security Credentials
- **AWS Secret Access Key:** You'll see this only once when creating the user
- **Default region:** Use `ap-south-1` (Mumbai - closest to India)
- **Default output format:** Type `json`

**Test it works:**
```bash
aws sts get-caller-identity
# Should show your account info
```

#### 1.4 Install SAM CLI (Serverless Application Model)
```bash
# On macOS
brew install aws-sam-cli

# Verify
sam --version
```

**What is SAM?**
It's a tool that makes deploying Lambda functions SUPER easy. Instead of clicking 100 times in AWS Console, you write one config file and SAM does everything.

#### 1.5 Install Python Dependencies (for Lambda functions)
```bash
# Make sure you have Python 3.11+
python3 --version

# Install boto3 (AWS SDK for Python)
pip3 install boto3 google-generativeai
```

---

## **MVP Task 2: Create DynamoDB Tables** ⏱️ 20 mins

### **What You're Doing:**
Creating 3 "Excel-like tables" in the cloud to store patient data.

### **Why DynamoDB and not regular SQL?**
- **Speed:** Returns data in milliseconds (critical for live updates)
- **Serverless:** No database server to manage
- **Scalable:** Can handle millions of patients automatically

### **Table 1: Patients Table**

**Purpose:** Store basic patient info (name, phone)

**Structure:**
| patient_id (Primary Key) | name | phone | created_at |
|-------------------------|------|-------|------------|
| PAT_12345 | Ram Kumar | 9876543210 | 1699401600 |

```bash
aws dynamodb create-table \
  --table-name Patients \
  --attribute-definitions \
    AttributeName=patient_id,AttributeType=S \
  --key-schema \
    AttributeName=patient_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

**Explanation:**
- `--table-name Patients` → Name of your table
- `AttributeName=patient_id,AttributeType=S` → "S" means String (text)
- `KeyType=HASH` → This is your PRIMARY KEY (unique ID)
- `--billing-mode PAY_PER_REQUEST` → You only pay for what you use (perfect for hackathon)

**Verify it worked:**
```bash
aws dynamodb describe-table --table-name Patients --region ap-south-1
# Should show table status as "ACTIVE"
```

### **Table 2: PatientNotes Table**

**Purpose:** Store AI-generated SOAP notes from audio recordings

**Structure:**
| patient_id (Partition Key) | timestamp (Sort Key) | soap_note | audio_url | status |
|---------------------------|---------------------|-----------|-----------|--------|
| PAT_12345 | 1699401600 | {...} | s3://... | completed |

```bash
aws dynamodb create-table \
  --table-name PatientNotes \
  --attribute-definitions \
    AttributeName=patient_id,AttributeType=S \
    AttributeName=timestamp,AttributeType=N \
  --key-schema \
    AttributeName=patient_id,KeyType=HASH \
    AttributeName=timestamp,KeyType=RANGE \
  --stream-specification StreamEnabled=true,StreamViewType=NEW_IMAGE \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

**New Concepts:**
- `AttributeType=N` → "N" means Number (for timestamp)
- `KeyType=RANGE` → Sort key (lets you query "all notes for this patient, ordered by time")
- `--stream-specification` → **THIS IS MAGIC!** Every time a new note is added, DynamoDB will trigger an event. We'll use this for real-time updates later!

**Why do we need streams?**
Imagine: Nurse records audio → Lambda processes it → Saves to this table → **Stream event fires** → Another Lambda sends it to the doctor's dashboard in REAL-TIME.

### **Table 3: PatientHistory Table**

**Purpose:** Store digitized medication data from scanned documents

**Structure:**
| patient_id | timestamp | medications | document_url | extracted_text |
|-----------|-----------|-------------|--------------|----------------|
| PAT_12345 | 1699401600 | [...] | s3://... | "Paracetamol..." |

```bash
aws dynamodb create-table \
  --table-name PatientHistory \
  --attribute-definitions \
    AttributeName=patient_id,AttributeType=S \
    AttributeName=timestamp,AttributeType=N \
  --key-schema \
    AttributeName=patient_id,KeyType=HASH \
    AttributeName=timestamp,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

**List all your tables:**
```bash
aws dynamodb list-tables --region ap-south-1
# Should show: Patients, PatientNotes, PatientHistory
```

---

## **MVP Task 3: Create S3 Buckets (File Storage)** ⏱️ 15 mins

### **What You're Doing:**
Creating 2 "cloud folders" to store audio files and images.

### **Why S3?**
- Can store ANY file type
- Automatically triggers Lambda when new file is uploaded (this is how the pipeline starts!)
- Cheap ($0.023 per GB)

### **Bucket 1: Audio Uploads**
```bash
# Replace <your-name> with something unique (S3 bucket names must be globally unique)
aws s3 mb s3://phc-audio-uploads-rishi-hackcbs --region ap-south-1

# Enable versioning (so you don't accidentally delete files)
aws s3api put-bucket-versioning \
  --bucket phc-audio-uploads-rishi-hackcbs \
  --versioning-configuration Status=Enabled \
  --region ap-south-1
```

**What is `mb`?** 
"Make bucket" (like `mkdir` for directories)

### **Bucket 2: Image Uploads**
```bash
aws s3 mb s3://phc-image-uploads-rishi-hackcbs --region ap-south-1

aws s3api put-bucket-versioning \
  --bucket phc-image-uploads-rishi-hackcbs \
  --versioning-configuration Status=Enabled \
  --region ap-south-1
```

**List your buckets:**
```bash
aws s3 ls
# Should show both buckets
```

**Test uploading a file:**
```bash
echo "test" > test.txt
aws s3 cp test.txt s3://phc-audio-uploads-rishi-hackcbs/
# Should say: upload: ./test.txt to s3://...
```

---

## **MVP Task 4: Setup Gemini API** ⏱️ 10 mins

### **What You're Doing:**
Getting your API key to use Google's Gemini AI.

### **Steps:**

1. Go to https://aistudio.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key (looks like: `AIzaSyC...`)

**Save it as an environment variable:**
```bash
# Add to your ~/.zshrc file
echo 'export GEMINI_API_KEY="AIzaSyC..."' >> ~/.zshrc
source ~/.zshrc

# Verify
echo $GEMINI_API_KEY
```

**Test Gemini API:**
```python
# Create a test file: test_gemini.py
import google.generativeai as genai
import os

genai.configure(api_key=os.environ['GEMINI_API_KEY'])
model = genai.GenerativeModel('gemini-pro')

response = model.generate_content("Say hello!")
print(response.text)
```

```bash
python3 test_gemini.py
# Should print: "Hello! 👋..."
```

---

## **MVP Task 5: Create Lambda Function #1 - Patient Registration API** ⏱️ 1 hour

### **What You're Doing:**
Creating your FIRST serverless function! This will handle patient registration from the mobile app.

### **What is Lambda?**
Imagine you have a Python function:
```python
def register_patient(name, phone):
    # Save to database
    return patient_id
```

Lambda lets you run this function in the cloud:
- ✅ No server to set up
- ✅ Only runs when called (via API)
- ✅ Automatically scales (can handle 1 request or 1000)
- ✅ You only pay for execution time (first 1M requests/month are FREE!)

### **Project Structure:**
```
backend/
├── lambdas/
│   └── patient_registration/
│       ├── handler.py          ← Your Lambda function code
│       ├── requirements.txt    ← Python dependencies
│       └── test_local.py       ← Test before deploying
├── template.yaml               ← SAM config (defines all Lambda functions)
└── README.md
```

### **Step 5.1: Create the Lambda Function**

**File: `backend/lambdas/patient_registration/handler.py`**

```python
import json
import boto3
import uuid
from datetime import datetime

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb', region_name='ap-south-1')
patients_table = dynamodb.Table('Patients')

def lambda_handler(event, context):
    """
    This function is called when the API receives a request.
    
    What it does:
    1. Receives patient name and phone from mobile app
    2. Generates a unique patient ID
    3. Saves to DynamoDB
    4. Returns the patient ID
    
    Args:
        event: Contains the HTTP request data (body, headers, etc.)
        context: AWS Lambda runtime info (we don't need this usually)
    """
    
    try:
        # Step 1: Parse the incoming request
        # The mobile app sends JSON like: {"name": "Ram Kumar", "phone": "9876543210"}
        body = json.loads(event['body'])
        name = body.get('name')
        phone = body.get('phone')
        
        # Step 2: Validate input
        if not name or not phone:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'Name and phone are required'})
            }
        
        # Step 3: Generate unique patient ID
        patient_id = f"PAT_{uuid.uuid4().hex[:8].upper()}"
        
        # Step 4: Save to DynamoDB
        patients_table.put_item(
            Item={
                'patient_id': patient_id,
                'name': name,
                'phone': phone,
                'created_at': int(datetime.now().timestamp()),
                'created_by': 'NURSE_001'  # Hardcoded for hackathon
            }
        )
        
        # Step 5: Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # Allow mobile app to call this
            },
            'body': json.dumps({
                'patient_id': patient_id,
                'name': name,
                'message': 'Patient registered successfully'
            })
        }
        
    except Exception as e:
        # If anything goes wrong, return error
        print(f"Error: {str(e)}")  # This shows up in CloudWatch Logs
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'Internal server error'})
        }
```

**Explanation of Key Concepts:**

**1. `boto3` - AWS SDK for Python**
```python
dynamodb = boto3.resource('dynamodb')
```
This creates a connection to DynamoDB. Think of it as `import mysql.connector` but for AWS.

**2. `lambda_handler` - The Entry Point**
Every Lambda function MUST have a function named `lambda_handler`. AWS calls this function when your API is hit.

**3. `event` - The Request Data**
```python
event = {
    'body': '{"name": "Ram Kumar", "phone": "9876543210"}',
    'headers': {...},
    'httpMethod': 'POST'
}
```

**4. Return Format - MUST be specific**
```python
return {
    'statusCode': 200,        # HTTP status code
    'headers': {...},          # HTTP headers
    'body': json.dumps({...})  # MUST be a JSON string!
}
```

### **Step 5.2: Create Dependencies File**

**File: `backend/lambdas/patient_registration/requirements.txt`**
```
boto3==1.34.0
```

### **Step 5.3: Test Locally (Before Deploying)**

**File: `backend/lambdas/patient_registration/test_local.py`**
```python
import json
from handler import lambda_handler

# Simulate an API request from the mobile app
test_event = {
    'body': json.dumps({
        'name': 'Ram Kumar',
        'phone': '9876543210'
    })
}

# Call the function
response = lambda_handler(test_event, None)

# Print the result
print("Status Code:", response['statusCode'])
print("Response:", json.loads(response['body']))
```

**Run the test:**
```bash
cd backend/lambdas/patient_registration
python3 test_local.py
```

**Expected output:**
```
Status Code: 200
Response: {'patient_id': 'PAT_A3F5B2C1', 'name': 'Ram Kumar', 'message': 'Patient registered successfully'}
```

---

## **MVP Task 6: Create SAM Template (Deploy Everything)** ⏱️ 30 mins

### **What You're Doing:**
Creating ONE config file that defines your entire backend infrastructure.

### **What is SAM Template?**
It's like a recipe that tells AWS:
- "Create these Lambda functions"
- "Create these API endpoints"
- "Connect them to these databases"
- "Set these permissions"

Without SAM, you'd have to click through the AWS Console for HOURS. With SAM, you type `sam deploy` and it does everything!

**File: `backend/template.yaml`**
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: PHC AI Co-Pilot Backend

# Global settings for all functions
Globals:
  Function:
    Timeout: 30
    Runtime: python3.11
    Environment:
      Variables:
        REGION: ap-south-1

Resources:
  # Lambda Function: Patient Registration
  PatientRegistrationFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: lambdas/patient_registration/
      Handler: handler.lambda_handler
      Policies:
        - DynamoDBCrudPolicy:
            TableName: Patients
      Events:
        RegisterPatient:
          Type: Api
          Properties:
            Path: /patients
            Method: post

  # We'll add more functions here later...

# Outputs - These are the API URLs you'll use in your mobile app
Outputs:
  ApiEndpoint:
    Description: "API Gateway endpoint URL"
    Value: !Sub "https://${ServerlessRestApi}.execute-api.${AWS::Region}.amazonaws.com/Prod/"
  
  PatientRegistrationApi:
    Description: "POST /patients endpoint"
    Value: !Sub "https://${ServerlessRestApi}.execute-api.${AWS::Region}.amazonaws.com/Prod/patients"
```

**Explanation:**

**1. `CodeUri`** - Where your Lambda code lives
```yaml
CodeUri: lambdas/patient_registration/
```
SAM will automatically zip this folder and upload it to AWS.

**2. `Handler`** - Which function to call
```yaml
Handler: handler.lambda_handler
```
Means: "In the file `handler.py`, call the function `lambda_handler`"

**3. `Policies`** - Permissions
```yaml
Policies:
  - DynamoDBCrudPolicy:
      TableName: Patients
```
This gives your Lambda function permission to read/write to the Patients table.

**4. `Events`** - What triggers this function
```yaml
Events:
  RegisterPatient:
    Type: Api
    Properties:
      Path: /patients
      Method: post
```
This creates an API endpoint: `POST /patients`
When someone calls this URL, your Lambda function runs!

---

## **MVP Task 7: Deploy to AWS** ⏱️ 15 mins

### **What You're Doing:**
Uploading your code to AWS and making it live!

```bash
cd backend

# Step 1: Build (SAM prepares your code)
sam build

# Step 2: Deploy (First time - it will ask questions)
sam deploy --guided
```

**It will ask:**
```
Stack Name [sam-app]: phc-backend-dev
AWS Region [us-east-1]: ap-south-1
Confirm changes before deploy [y/N]: y
Allow SAM CLI IAM role creation [Y/n]: Y
Save arguments to configuration file [Y/n]: Y
```

**What's happening behind the scenes:**
1. SAM uploads your code to S3
2. Creates the Lambda function
3. Creates API Gateway (the URL your mobile app will call)
4. Sets up permissions
5. Prints out your API URL!

**After deployment, you'll see:**
```
Outputs:
PatientRegistrationApi = https://abc123xyz.execute-api.ap-south-1.amazonaws.com/Prod/patients
```

**Save this URL!** Your mobile app will use it.

---

## **MVP Task 8: Test Your Live API** ⏱️ 10 mins

```bash
# Test with curl
curl -X POST https://YOUR-API-URL/patients \
  -H "Content-Type: application/json" \
  -d '{"name": "Ram Kumar", "phone": "9876543210"}'
```

**Expected response:**
```json
{
  "patient_id": "PAT_A3F5B2C1",
  "name": "Ram Kumar",
  "message": "Patient registered successfully"
}
```

**Check DynamoDB:**
```bash
aws dynamodb scan --table-name Patients --region ap-south-1
```

You should see your patient data!

---

## **Next Steps (After This Working):**

Once Task 1-8 are done, you have:
✅ A working API that creates patients
✅ Data stored in DynamoDB
✅ A deployed, live backend

Next MVP tasks will be:
- **Task 9:** Lambda function to generate S3 presigned URLs (for mobile to upload files)
- **Task 10:** Lambda function for Audio → Transcribe → Gemini (ScribeTask)
- **Task 11:** Lambda function for Image → Textract → Gemini (DigitizeTask)
- **Task 12:** DynamoDB Streams + Real-time push

---

## **Common Errors & Fixes:**

### Error: "Unable to locate credentials"
**Fix:**
```bash
aws configure
# Enter your Access Key ID and Secret Key again
```

### Error: "Table already exists"
**Fix:**
```bash
# Delete and recreate
aws dynamodb delete-table --table-name Patients --region ap-south-1
# Wait 30 seconds, then run create command again
```

### Error: "Bucket name already exists"
**Fix:**
S3 bucket names are globally unique. Add more random characters:
```bash
aws s3 mb s3://phc-audio-uploads-rishi-$(date +%s)
```

---

## **Useful Commands:**

```bash
# View Lambda logs (when debugging)
sam logs -n PatientRegistrationFunction --tail

# Update code after changes
sam build && sam deploy

# Delete everything (if you want to start over)
sam delete --stack-name phc-backend-dev

# Check DynamoDB table contents
aws dynamodb scan --table-name Patients --region ap-south-1 --max-items 5
```

---

**Ready to start?** Let me know when you've completed Tasks 1-3, and I'll help you with any errors!
