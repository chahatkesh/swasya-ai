# Complete End-to-End Flow

## 🎯 Overview
This document explains what happens when you upload an audio file from the mobile app.

## 📱 Mobile App → AWS Pipeline

### Step 1: Patient Registration
**Screen:** `PatientRegistrationScreen`
```
User enters: Name, Phone, Age, Gender
↓
POST /patients
↓
Backend creates patient in DynamoDB
↓
Returns: patient_id (e.g., PAT_97EE42A5)
```

### Step 2: Get Upload URL
**Screen:** `RecordAudioScreen`
```
User picks audio file (MP3/M4A)
↓
POST /upload-url
Body: {
  "patient_id": "PAT_97EE42A5",
  "file_type": "audio",
  "file_extension": "m4a"
}
↓
Lambda: PresignedUrlFunction
↓
Returns: {
  "upload_url": "https://phc-audio-uploads-XXX.s3.amazonaws.com/...",
  "file_key": "PAT_97EE42A5/audio_1762601361.m4a",
  "expires_in": 300
}
```

### Step 3: Upload to S3
```
Mobile app does PUT request
↓
Uploads file bytes directly to S3 (no Lambda involved)
↓
File stored at: s3://phc-audio-uploads-XXX/PAT_97EE42A5/audio_1762601361.m4a
```

---

## 🤖 Automatic Backend Processing (Triggered by S3 Event)

### Step 4: S3 Event Trigger
```
S3 detects new file upload
↓
Automatically invokes: ScribeTaskFunction Lambda
↓
Event contains: bucket_name, file_key
```

### Step 5: AWS Transcribe (Speech → Text)
**Lambda:** `ScribeTaskFunction`
```python
# Lambda receives S3 event
bucket = "phc-audio-uploads-1762597760"
file_key = "PAT_97EE42A5/audio_1762601361.m4a"

# Start transcription job
transcribe_client.start_transcription_job(
    JobName="transcribe_1762601361_...",
    Media={'MediaFileUri': f"s3://{bucket}/{file_key}"},
    LanguageCode='hi-IN',  # Hindi
    Settings={
        'ShowSpeakerLabels': True,
        'MaxSpeakerLabels': 2  # Nurse + Patient
    }
)

# Wait for completion (polls every 5 seconds, max 5 minutes)
while status != 'COMPLETED':
    time.sleep(5)
    check_status()

# Get transcript
transcript_text = "Patient says: मुझे सिर दर्द है और बुखार है..."
```

### Step 6: Gemini AI (Structure SOAP Note)
```python
# Send transcript to Gemini 2.5 Flash
prompt = """
Convert this conversation into SOAP format:
{transcript_text}
"""

gemini_response = {
    "subjective": "Patient complains of headache and fever for 2 days",
    "objective": "Temperature: 101°F, BP: 120/80",
    "assessment": "Viral fever suspected",
    "plan": "Paracetamol 500mg TDS for 3 days, rest, fluids",
    "chief_complaint": "Headache and fever",
    "language_detected": "hindi"
}
```

### Step 7: Save to DynamoDB
```python
# Store in PatientNotes table
notes_table.put_item(
    Item={
        'patient_id': 'PAT_97EE42A5',
        'timestamp': 1762601361,
        'soap_note': gemini_response,
        'raw_transcript': transcript_text,
        'audio_url': 's3://phc-audio-uploads-1762597760/PAT_97EE42A5/audio_1762601361.m4a',
        'status': 'completed',
        'created_at': '2025-11-08T11:29:21'
    }
)
```

---

## ✅ Result

### What Gets Saved:
1. **DynamoDB Tables:**
   - `Patients` → Patient demographics
   - `PatientNotes` → SOAP notes with AI analysis

2. **S3 Buckets:**
   - `phc-audio-uploads-XXX` → Original audio files
   - `phc-image-uploads-XXX` → Prescription images

### How to Verify:

#### Check Lambda Logs:
```bash
cd backend
sam logs -n ScribeTaskFunction --tail
```

#### Check DynamoDB:
```bash
aws dynamodb scan --table-name PatientNotes --region eu-north-1
```

#### Check S3 Files:
```bash
aws s3 ls s3://phc-audio-uploads-1762597760/PAT_97EE42A5/ --region eu-north-1
```

---

## 🔧 Current Issue (307 Redirect)

**Problem:** S3 returning 307 redirect during upload

**Cause:** Presigned URL not using correct regional endpoint

**Fix Applied:**
1. Updated `presigned_url/handler.py` to use S3v4 signatures
2. Configured virtual-hosted-style URLs
3. Explicitly set HttpMethod='PUT'

**Redeploy:**
```bash
cd backend
sam build --use-container
sam deploy
```

---

## 🎯 Expected Timeline

| Step | Duration | What Happens |
|------|----------|--------------|
| Patient Registration | 1-2 sec | API call to Lambda → DynamoDB |
| Get Upload URL | 1 sec | Lambda generates presigned URL |
| Upload to S3 | 5-30 sec | Direct upload (depends on file size) |
| **S3 → Lambda Trigger** | **< 1 sec** | **Automatic (no user action)** |
| AWS Transcribe | 30-120 sec | Speech-to-text processing |
| Gemini AI | 3-5 sec | Structure SOAP note |
| Save to DynamoDB | 1 sec | Store results |
| **Total (after upload)** | **~1-2 minutes** | **Fully automated** |

---

## 📊 Architecture Diagram

```
┌─────────────┐
│ Mobile App  │
│  (Flutter)  │
└──────┬──────┘
       │
       │ 1. Register Patient
       ↓
┌─────────────────────┐
│  API Gateway        │
│  /patients          │
└──────┬──────────────┘
       │
       ↓
┌─────────────────────┐      ┌──────────────┐
│ PatientRegistration │ ───> │  DynamoDB    │
│     Lambda          │      │  (Patients)  │
└─────────────────────┘      └──────────────┘
       │
       │ Returns: patient_id
       ↓
┌─────────────┐
│ Mobile App  │
│ Pick Audio  │
└──────┬──────┘
       │
       │ 2. Get Upload URL
       ↓
┌─────────────────────┐
│  PresignedUrl       │
│     Lambda          │
└──────┬──────────────┘
       │
       │ Returns: presigned_url
       ↓
┌─────────────┐
│ Mobile App  │
│ Upload File │
└──────┬──────┘
       │
       │ 3. PUT to S3
       ↓
┌─────────────────────┐
│   S3 Bucket         │
│ phc-audio-uploads   │
└──────┬──────────────┘
       │
       │ 4. S3 Event Trigger (AUTOMATIC)
       ↓
┌─────────────────────┐
│  ScribeTask         │
│     Lambda          │
└──────┬──────────────┘
       │
       │ 5. Start Transcription
       ↓
┌─────────────────────┐
│  AWS Transcribe     │
│  (Speech-to-Text)   │
└──────┬──────────────┘
       │
       │ Returns: transcript_text
       ↓
┌─────────────────────┐
│  Gemini AI          │
│  (2.5 Flash)        │
└──────┬──────────────┘
       │
       │ Returns: SOAP note JSON
       ↓
┌─────────────────────┐
│     DynamoDB        │
│  (PatientNotes)     │
└─────────────────────┘
```

---

## 🚀 Testing the Flow

### 1. Register Patient
```
Open app → Click "Add New Patient"
Enter name, phone → Submit
Note the patient_id returned
```

### 2. Upload Audio
```
Pick an MP3/M4A file
Click "Upload to AWS S3"
Wait for success message
```

### 3. Check Backend Processing
```bash
# Watch Lambda logs in real-time
sam logs -n ScribeTaskFunction --tail

# Check if SOAP note was generated
aws dynamodb query \
  --table-name PatientNotes \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values '{":pid":{"S":"PAT_97EE42A5"}}' \
  --region eu-north-1
```

---

## ✨ What's Working Now

✅ Patient registration API  
✅ Presigned URL generation  
✅ S3 bucket with event trigger configured  
✅ ScribeTask Lambda with Transcribe + Gemini integration  
✅ DynamoDB tables created  
✅ Mobile app UI complete  

⏳ **Currently Fixing:** S3 upload (307 redirect issue)  
⏳ **Next:** Test full pipeline with real audio file  

---

## 🔑 Key Points

1. **Upload is DIRECT** - Mobile → S3 (no Lambda in between)
2. **Processing is AUTOMATIC** - S3 event triggers Lambda
3. **No polling needed** - Backend handles everything asynchronously
4. **Results in DynamoDB** - Query by patient_id to get SOAP notes
5. **Scalable** - Each file upload processes independently
