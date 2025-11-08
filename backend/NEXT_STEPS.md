# Backend Next Steps - Priority Plan

## ✅ Current Status (What's Done)

1. ✅ **All Lambda functions created** (4 functions)
   - Patient Registration
   - Presigned URL Generator  
   - Scribe Task (Audio → Transcribe → Gemini → SOAP)
   - Digitize Task (Image → Textract → Gemini → Medications)

2. ✅ **All local tests passing**
   - Mocked AWS services working
   - Gemini API integration tested
   - Business logic validated

3. ✅ **SAM template complete**
   - Infrastructure as code ready
   - DynamoDB tables defined
   - S3 buckets configured
   - API Gateway setup

4. ⏳ **Deployment in progress**
   - Currently uploading to AWS

---

## 🎯 Next Steps (After Deployment Completes)

### Priority 1: TEST DEPLOYED BACKEND (30 mins) ⚡ CRITICAL

**Goal:** Verify everything works on AWS, not just locally

**Tasks:**

#### 1.1 Get API Endpoints
```bash
sam list stack-outputs --stack-name phc-backend --region eu-north-1
```

Save these URLs:
- `ApiEndpoint` - Base URL
- `PatientRegistrationUrl` - POST /patients
- `PresignedUrlEndpoint` - POST /upload-url
- `AudioBucket` - S3 bucket name
- `ImageBucket` - S3 bucket name

#### 1.2 Test Patient Registration API
```bash
curl -X POST https://YOUR-API-ID.execute-api.eu-north-1.amazonaws.com/Prod/patients \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Patient", "phone": "9876543210", "age": 45, "gender": "M"}'
```

**Expected:** `{"patient_id": "PAT_XXXXX", ...}`

#### 1.3 Test Presigned URL Generator
```bash
curl -X POST https://YOUR-API-ID.execute-api.eu-north-1.amazonaws.com/Prod/upload-url \
  -H "Content-Type: application/json" \
  -d '{"patient_id": "PAT_12345", "file_type": "audio", "file_extension": "mp3"}'
```

**Expected:** `{"upload_url": "https://...", "file_key": "..."}`

#### 1.4 Test FULL Scribe Pipeline (Audio → SOAP)
```bash
# Create a test audio file
say "Patient complains of fever and headache for two days" -o test_audio.mp3

# Get presigned URL
UPLOAD_URL=$(curl -X POST ... | jq -r '.upload_url')

# Upload audio file
curl -X PUT "$UPLOAD_URL" \
  --upload-file test_audio.mp3 \
  -H "Content-Type: audio/mp3"

# Wait 30 seconds for processing
sleep 30

# Check DynamoDB for SOAP note
aws dynamodb query \
  --table-name PatientNotes \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values '{":pid":{"S":"PAT_12345"}}' \
  --region eu-north-1
```

**Expected:** SOAP note with Subjective, Objective, Assessment, Plan fields

#### 1.5 Test FULL Digitize Pipeline (Image → Medications)
```bash
# Create a test prescription image (or use a real one)
# Upload via presigned URL (similar to audio)

# Check DynamoDB for medication data
aws dynamodb query \
  --table-name PatientHistory \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values '{":pid":{"S":"PAT_12345"}}' \
  --region eu-north-1
```

**Expected:** Structured medication list with dosages, dates

---

### Priority 2: ADD MISSING LAMBDA - RAG Timeline (1 hour) 🚀 HIGH PRIORITY

**Why:** Requirements doc says you need a RAG function for doctor dashboard

**What it does:** 
- Input: `patient_id`
- Output: AI-generated timeline of entire patient history
- Trigger: API call from doctor dashboard

**Create:** `backend/lambdas/rag_task/handler.py`

```python
import json
import boto3
import os
import google.generativeai as genai
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
history_table = dynamodb.Table('PatientHistory')
notes_table = dynamodb.Table('PatientNotes')

genai.configure(api_key=os.environ.get('GEMINI_API_KEY'))
model = genai.GenerativeModel('gemini-2.5-flash')

def lambda_handler(event, context):
    """
    RAG Task: Retrieval-Augmented Generation
    
    Retrieves all patient data and generates a comprehensive timeline
    """
    try:
        # Parse patient_id from API Gateway
        patient_id = event['pathParameters']['patient_id']
        
        # RETRIEVE: Get all history records
        history_response = history_table.query(
            KeyConditionExpression='patient_id = :pid',
            ExpressionAttributeValues={':pid': patient_id}
        )
        
        # RETRIEVE: Get all notes
        notes_response = notes_table.query(
            KeyConditionExpression='patient_id = :pid',
            ExpressionAttributeValues={':pid': patient_id}
        )
        
        # AUGMENT: Build context for Gemini
        context = f"""
        Patient ID: {patient_id}
        
        Medical History Documents ({len(history_response['Items'])} records):
        {json.dumps(history_response['Items'], indent=2, default=str)}
        
        Recent Clinical Notes ({len(notes_response['Items'])} notes):
        {json.dumps(notes_response['Items'], indent=2, default=str)}
        """
        
        # GENERATE: Create timeline with Gemini
        prompt = f"""
        You are a medical analyst creating a comprehensive patient timeline.
        
        Analyze this patient's complete medical history and create:
        1. A chronological timeline of all events
        2. Key diagnoses and treatments
        3. Current medications
        4. Risk factors and concerns
        
        Patient Data:
        {context}
        
        Return a clean, structured JSON with this format:
        {{
          "timeline": [
            {{"date": "2024-01-15", "event": "Diagnosed with hypertension", "source": "clinic_visit"}},
            ...
          ],
          "current_medications": ["Amlodipine 5mg daily", ...],
          "diagnoses": ["Hypertension", "Type 2 Diabetes"],
          "risk_factors": ["Family history of heart disease", ...],
          "summary": "Brief 2-3 sentence summary"
        }}
        """
        
        response = model.generate_content(prompt)
        timeline_data = json.loads(response.text)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(timeline_data)
        }
        
    except Exception as e:
        print(f"Error in RAG task: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': str(e)})
        }
```

**Add to template.yaml:**
```yaml
  RAGTaskFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: lambdas/rag_task/
      Handler: handler.lambda_handler
      Timeout: 60
      MemorySize: 512
      Policies:
        - DynamoDBReadPolicy:
            TableName: !Ref PatientHistoryTable
        - DynamoDBReadPolicy:
            TableName: !Ref PatientNotesTable
      Events:
        GetTimeline:
          Type: Api
          Properties:
            Path: /timeline/{patient_id}
            Method: get
            RestApiId: !Ref ApiGateway
```

**Deploy update:**
```bash
sam build && sam deploy --no-confirm-changeset
```

---

### Priority 3: ADD REAL-TIME PUSH (Lambda 5 - PushTask) (1.5 hours) 🔥 HIGH PRIORITY

**Why:** Requirements say "Live Typewriter" effect - data must push to dashboard in real-time

**What it does:**
- Trigger: DynamoDB Streams on PatientNotes table
- Action: Pushes new notes to AWS IoT Core (MQTT)
- Result: Doctor dashboard updates instantly

**Create:** `backend/lambdas/push_task/handler.py`

```python
import json
import boto3
import os

iot_client = boto3.client('iot-data')

def lambda_handler(event, context):
    """
    Push Task: Real-time notifications via AWS IoT Core
    
    Triggered by DynamoDB Streams when new SOAP note is saved
    """
    try:
        for record in event['Records']:
            if record['eventName'] == 'INSERT':
                # Get new note data
                new_note = record['dynamodb']['NewImage']
                patient_id = new_note['patient_id']['S']
                
                # Convert DynamoDB format to regular JSON
                note_data = {
                    'patient_id': patient_id,
                    'timestamp': int(new_note['timestamp']['N']),
                    'soap_note': json.loads(new_note['soap_note']['S']),
                    'type': 'new_soap_note'
                }
                
                # Publish to IoT Core MQTT topic
                topic = f"patient/{patient_id}/updates"
                
                iot_client.publish(
                    topic=topic,
                    qos=1,
                    payload=json.dumps(note_data)
                )
                
                print(f"Published to {topic}: {note_data}")
        
        return {'statusCode': 200}
        
    except Exception as e:
        print(f"Error in push task: {str(e)}")
        return {'statusCode': 500}
```

**Add to template.yaml:**
```yaml
  PushTaskFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: lambdas/push_task/
      Handler: handler.lambda_handler
      Policies:
        - Statement:
          - Effect: Allow
            Action:
              - iot:Publish
            Resource: !Sub 'arn:aws:iot:${AWS::Region}:${AWS::AccountId}:topic/patient/*'
      Events:
        Stream:
          Type: DynamoDB
          Properties:
            Stream: !GetAtt PatientNotesTable.StreamArn
            StartingPosition: LATEST
            BatchSize: 1
```

---

### Priority 4: TEST WITH REAL AUDIO/IMAGES (30 mins) 🧪 CRITICAL

**Why:** Must verify Transcribe (Hindi) and Textract (handwriting) work

**Tasks:**

#### 4.1 Test Hindi Audio → Transcribe
```bash
# Record 10-second Hindi audio: "Mujhe bukhar hai do din se"
# Upload to S3
# Check CloudWatch Logs for Transcribe output
# Verify SOAP note in DynamoDB
```

#### 4.2 Test Handwritten Prescription → Textract
```bash
# Take photo of real prescription (even your own)
# Upload to S3
# Check CloudWatch Logs for Textract output
# Verify medications extracted correctly
```

---

### Priority 5: INTEGRATE WITH MOBILE APP (2 hours) 📱 HIGH PRIORITY

**Why:** Backend is useless without frontend

**Tasks:**

#### 5.1 Update Mobile App with API URLs
Edit `mobile/lib/config.dart`:
```dart
class Config {
  static const String apiBaseUrl = 'https://YOUR-API-ID.execute-api.eu-north-1.amazonaws.com/Prod';
  static const String patientEndpoint = '$apiBaseUrl/patients';
  static const String uploadEndpoint = '$apiBaseUrl/upload-url';
  static const String timelineEndpoint = '$apiBaseUrl/timeline';
}
```

#### 5.2 Implement Patient Registration Screen
- Call `/patients` API
- Save returned `patient_id` in app state

#### 5.3 Implement Audio Recording
- Use `flutter_sound` package
- Get presigned URL from `/upload-url`
- Upload directly to S3

#### 5.4 Implement Camera Capture
- Use `camera` package
- Get presigned URL
- Upload to S3

---

### Priority 6: BUILD DOCTOR DASHBOARD (3 hours) 🖥️ MEDIUM PRIORITY

**Why:** Requirements say "live typewriter effect"

**Tasks:**

#### 6.1 Patient List View
- Fetch from `/patients` (need to add list endpoint)
- Show in sidebar

#### 6.2 RAG Timeline View
- Call `/timeline/{patient_id}`
- Display at top of patient view

#### 6.3 Real-Time Updates (AWS IoT Core)
```javascript
import { PubSub } from '@aws-amplify/pubsub';
import { AWSIoTProvider } from '@aws-amplify/pubsub/lib/Providers';

// Subscribe to patient updates
PubSub.subscribe(`patient/${patientId}/updates`).subscribe({
  next: data => {
    // Add new SOAP note to UI with typewriter effect
    setNotes(prev => [...prev, data]);
  }
});
```

---

## 📊 Timeline Estimate

| Task | Time | Priority | Status |
|------|------|----------|--------|
| Test deployed backend | 30 min | ⚡ CRITICAL | Next |
| Add RAG Lambda | 1 hour | 🚀 HIGH | After deploy |
| Add Push Lambda (IoT) | 1.5 hours | 🔥 HIGH | After RAG |
| Test with real audio/images | 30 min | 🧪 CRITICAL | After Push |
| Integrate mobile app | 2 hours | 📱 HIGH | Parallel |
| Build dashboard | 3 hours | 🖥️ MEDIUM | Parallel |
| Qyrus testing | 1 hour | 🏆 WIN | End |
| Base44 landing page | 30 min | 🏆 WIN | End |

**Total: ~10 hours of focused work**

---

## 🎯 Immediate Action Plan

### Right Now (While Deployment Finishes):
1. ✅ Make scripts executable: `chmod +x *.sh`
2. ✅ Create RAG Lambda function
3. ✅ Create Push Lambda function
4. ✅ Update template.yaml with new functions

### After Deployment Completes:
1. 🔥 Get API URLs
2. 🔥 Test all 4 endpoints with curl
3. 🔥 Upload test audio → verify SOAP note
4. 🔥 Upload test image → verify medications
5. 🔥 Deploy RAG + Push functions

### Then:
1. 📱 Update mobile app config
2. 🖥️ Start dashboard development
3. 🧪 Setup Qyrus tests
4. 🎨 Build Base44 landing page

---

## 🚨 CRITICAL GAPS TO FILL

### Gap 1: List Patients API (Dashboard needs this)
Add to template.yaml:
```yaml
Events:
  ListPatients:
    Type: Api
    Properties:
      Path: /patients
      Method: get
```

### Gap 2: AWS IoT Core Setup (For real-time push)
```bash
# Create IoT policy
aws iot create-policy \
  --policy-name PHCDashboardPolicy \
  --policy-document file://iot-policy.json
```

### Gap 3: Environment Variables for Mobile
Dashboard needs:
- IoT Core endpoint URL
- Cognito identity pool (for IoT auth)

---

## 💡 Pro Tips

1. **Test locally first**: Always run `./test-all-local.sh` before deploying
2. **Use CloudWatch Logs**: `sam logs -n FunctionName --tail` to debug
3. **Quick updates**: Use `./quick-update.sh function_name` for code-only changes
4. **Monitor costs**: Check AWS Billing Dashboard daily
5. **DynamoDB indexes**: If queries are slow, add GSI (Global Secondary Index)

---

## ❓ Decision Points

### Question 1: AWS IoT Core vs API Gateway + WebSockets?
- **IoT Core**: More complex setup, true real-time, better for demo "wow"
- **WebSockets**: Simpler, but need to manage connections
- **Recommendation**: Use IoT Core (requirements doc specifically mentions it)

### Question 2: Store full audio/image in DynamoDB or just S3 URLs?
- **Current**: Storing S3 URLs only (correct!)
- **Why**: DynamoDB has 400KB item size limit

### Question 3: Hindi vs English for demo?
- **Recommendation**: Demo BOTH
  - Show English first (safer)
  - Then show Hindi (wow factor)

---

## 🎬 Demo Script (When Everything Works)

1. **Open mobile app** → Register patient "Ram Kumar"
2. **Record audio** in Hindi: "Mujhe bukhar hai do din se, sir dard bhi hai"
3. **Show dashboard** → Timeline loads (RAG)
4. **Wait 20 seconds** → SOAP note appears with TYPEWRITER EFFECT! 🎉
5. **Take photo** of prescription
6. **Show dashboard** → Medications appear in real-time! 🎉
7. **Show architecture diagram** → Explain 7 AWS services working together

---

**Your backend is 70% done! Focus on deployment testing, RAG, and real-time push next.**
