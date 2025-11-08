# API Endpoints Documentation

## 🚀 Deployed Backend - PHC AI Co-Pilot

**Base URL:** `https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod`

**Region:** `eu-north-1` (Stockholm)

**Deployment Date:** 2025-11-08

---

## 📋 Available Endpoints

### 1. Patient Registration API

**Endpoint:** `POST /patients`

**Full URL:** `https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod/patients`

**Purpose:** Register a new patient and get a unique patient ID

**Request:**
```bash
curl -X POST https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod/patients \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ram Kumar",
    "phone": "9876543210",
    "age": 45,
    "gender": "M"
  }'
```

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | ✅ Yes | Patient full name |
| phone | string | ✅ Yes | Phone number (10 digits) |
| age | integer | ❌ No | Patient age |
| gender | string | ❌ No | M/F/Other |

**Success Response (200):**
```json
{
  "success": true,
  "patient_id": "PAT_A6C5DC51",
  "name": "Ram Kumar",
  "phone": "9876543210",
  "message": "Patient registered successfully",
  "timestamp": "2025-11-08T10:45:10.539229"
}
```

**Error Response (400):**
```json
{
  "error": "Name and phone are required"
}
```

**Mobile App Integration:**
```dart
// Flutter example
final response = await http.post(
  Uri.parse('https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod/patients'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'name': 'Ram Kumar',
    'phone': '9876543210',
    'age': 45,
    'gender': 'M'
  }),
);

final data = jsonDecode(response.body);
final patientId = data['patient_id']; // Save this!
```

---

### 2. Presigned URL Generator API

**Endpoint:** `POST /upload-url`

**Full URL:** `https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod/upload-url`

**Purpose:** Get a secure S3 presigned URL to upload audio/image files directly from mobile app

**Why use presigned URLs?**
- ✅ Mobile app doesn't need AWS credentials
- ✅ Upload directly to S3 (faster, no backend bottleneck)
- ✅ URL expires in 5 minutes (secure)
- ✅ Automatically triggers Lambda processing

**Request:**
```bash
curl -X POST https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod/upload-url \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "PAT_A6C5DC51",
    "file_type": "audio",
    "file_extension": "mp3"
  }'
```

**Request Body:**
| Field | Type | Required | Values | Description |
|-------|------|----------|--------|-------------|
| patient_id | string | ✅ Yes | PAT_XXXXX | Patient ID from registration |
| file_type | string | ✅ Yes | "audio" or "image" | Type of file to upload |
| file_extension | string | ✅ Yes | mp3, wav, m4a, jpg, png, pdf | File extension |

**Success Response (200):**
```json
{
  "upload_url": "https://phc-audio-uploads-1762597760.s3.eu-north-1.amazonaws.com/PAT_A6C5DC51/audio_1699401600.mp3?X-Amz-Algorithm=...",
  "file_key": "PAT_A6C5DC51/audio_1699401600.mp3",
  "bucket": "phc-audio-uploads-1762597760",
  "expires_in": 300
}
```

**Mobile App Integration:**
```dart
// Step 1: Get presigned URL
final urlResponse = await http.post(
  Uri.parse('https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod/upload-url'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'patient_id': patientId,
    'file_type': 'audio',
    'file_extension': 'mp3'
  }),
);

final uploadData = jsonDecode(urlResponse.body);
final uploadUrl = uploadData['upload_url'];

// Step 2: Upload file directly to S3
final file = File('/path/to/recording.mp3');
final fileBytes = await file.readAsBytes();

await http.put(
  Uri.parse(uploadUrl),
  headers: {'Content-Type': 'audio/mp3'},
  body: fileBytes,
);

// Done! Lambda will automatically process the file
```

---

### 3. AI Scribe Pipeline (Automatic - S3 Trigger)

**Trigger:** When audio file is uploaded to S3 bucket

**Bucket:** `phc-audio-uploads-1762597760`

**Process Flow:**
```
Mobile App uploads audio.mp3
    ↓
S3 Bucket receives file
    ↓
Lambda Function (ScribeTask) triggered automatically
    ↓
AWS Transcribe converts audio → text
    ↓
Gemini AI structures text → SOAP note
    ↓
Saves to DynamoDB (PatientNotes table)
```

**No API call needed** - happens automatically!

**Expected Processing Time:** 15-30 seconds

**How to Check Results:**
```bash
# Query DynamoDB for patient's SOAP notes
aws dynamodb query \
  --table-name PatientNotes \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values '{":pid":{"S":"PAT_A6C5DC51"}}' \
  --region eu-north-1
```

**SOAP Note Structure:**
```json
{
  "patient_id": "PAT_A6C5DC51",
  "timestamp": 1699401600,
  "soap_note": {
    "subjective": "Patient complains of fever and headache for 2 days",
    "objective": "Temperature 101°F, appears fatigued",
    "assessment": "Likely viral fever",
    "plan": "Rest, fluids, Paracetamol 500mg TID for 3 days"
  },
  "audio_url": "s3://phc-audio-uploads-1762597760/PAT_A6C5DC51/audio_1699401600.mp3",
  "transcription": "Full transcribed text...",
  "language": "hi-IN",
  "status": "completed"
}
```

---

### 4. AI Digitizer Pipeline (Automatic - S3 Trigger)

**Trigger:** When image file is uploaded to S3 bucket

**Bucket:** `phc-image-uploads-1762597760`

**Process Flow:**
```
Mobile App uploads prescription.jpg
    ↓
S3 Bucket receives file
    ↓
Lambda Function (DigitizeTask) triggered automatically
    ↓
AWS Textract extracts text from image (OCR)
    ↓
Gemini AI structures data → Medications list
    ↓
Saves to DynamoDB (PatientHistory table)
```

**No API call needed** - happens automatically!

**Expected Processing Time:** 10-20 seconds

**How to Check Results:**
```bash
# Query DynamoDB for patient's history
aws dynamodb query \
  --table-name PatientHistory \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values '{":pid":{"S":"PAT_A6C5DC51"}}' \
  --region eu-north-1
```

**Medication Data Structure:**
```json
{
  "patient_id": "PAT_A6C5DC51",
  "timestamp": 1699401600,
  "medications": [
    {
      "name": "Paracetamol",
      "dosage": "500mg",
      "frequency": "Three times daily",
      "duration": "3 days"
    },
    {
      "name": "Amoxicillin",
      "dosage": "250mg",
      "frequency": "Twice daily",
      "duration": "5 days"
    }
  ],
  "diagnoses": ["Bacterial infection", "Fever"],
  "doctor_name": "Dr. R. Kumar",
  "prescription_date": "2025-11-08",
  "image_url": "s3://phc-image-uploads-1762597760/PAT_A6C5DC51/doc_1699401600.jpg",
  "raw_text": "Full extracted text from Textract...",
  "status": "completed"
}
```

---

## 🗄️ DynamoDB Tables

### Patients Table
**Table Name:** `Patients`
**Primary Key:** `patient_id` (String)

**Sample Item:**
```json
{
  "patient_id": "PAT_A6C5DC51",
  "name": "Ram Kumar",
  "phone": "9876543210",
  "age": 45,
  "gender": "M",
  "created_at": 1699401600,
  "created_by": "NURSE_001"
}
```

### PatientNotes Table
**Table Name:** `PatientNotes`
**Primary Key:** `patient_id` (String), `timestamp` (Number)

**Query by patient:**
```bash
aws dynamodb query \
  --table-name PatientNotes \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values '{":pid":{"S":"PAT_A6C5DC51"}}' \
  --region eu-north-1
```

### PatientHistory Table
**Table Name:** `PatientHistory`
**Primary Key:** `patient_id` (String), `timestamp` (Number)

**Query by patient:**
```bash
aws dynamodb query \
  --table-name PatientHistory \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values '{":pid":{"S":"PAT_A6C5DC51"}}' \
  --region eu-north-1
```

---

## 📦 S3 Buckets

### Audio Uploads Bucket
**Bucket Name:** `phc-audio-uploads-1762597760`
**Purpose:** Store audio recordings
**Trigger:** ScribeTask Lambda

**List files:**
```bash
aws s3 ls s3://phc-audio-uploads-1762597760/ --recursive --region eu-north-1
```

### Image Uploads Bucket
**Bucket Name:** `phc-image-uploads-1762597760`
**Purpose:** Store prescription scans
**Trigger:** DigitizeTask Lambda

**List files:**
```bash
aws s3 ls s3://phc-image-uploads-1762597760/ --recursive --region eu-north-1
```

---

## 🧪 Testing Guide

### Test 1: Register Patient
```bash
RESPONSE=$(curl -s -X POST https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod/patients \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Patient", "phone": "9999999999"}')

echo $RESPONSE | jq '.'

# Extract patient_id for next tests
PATIENT_ID=$(echo $RESPONSE | jq -r '.patient_id')
echo "Patient ID: $PATIENT_ID"
```

### Test 2: Get Upload URL for Audio
```bash
curl -X POST https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod/upload-url \
  -H "Content-Type: application/json" \
  -d "{\"patient_id\": \"$PATIENT_ID\", \"file_type\": \"audio\", \"file_extension\": \"mp3\"}" \
  | jq '.'
```

### Test 3: Upload Audio File
```bash
# Create test audio
say "Patient has fever" -o /tmp/test.mp3

# Get presigned URL
UPLOAD_DATA=$(curl -s -X POST https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod/upload-url \
  -H "Content-Type: application/json" \
  -d "{\"patient_id\": \"$PATIENT_ID\", \"file_type\": \"audio\", \"file_extension\": \"mp3\"}")

UPLOAD_URL=$(echo $UPLOAD_DATA | jq -r '.upload_url')

# Upload file
curl -X PUT "$UPLOAD_URL" \
  --upload-file /tmp/test.mp3 \
  -H "Content-Type: audio/mp3"

echo "✅ File uploaded! Wait 30 seconds for processing..."
```

### Test 4: Check SOAP Note in DynamoDB
```bash
sleep 30

aws dynamodb query \
  --table-name PatientNotes \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values "{\":pid\":{\"S\":\"$PATIENT_ID\"}}" \
  --region eu-north-1 \
  | jq '.Items[0].soap_note.S | fromjson'
```

---

## 🐛 Debugging

### Check Lambda Logs
```bash
# Scribe Task logs
sam logs -n ScribeTaskFunction --tail --region eu-north-1

# Digitize Task logs
sam logs -n DigitizeTaskFunction --tail --region eu-north-1

# Patient Registration logs
sam logs -n PatientRegistrationFunction --tail --region eu-north-1
```

### Check S3 Upload Events
```bash
# Check if file was uploaded
aws s3 ls s3://phc-audio-uploads-1762597760/ --recursive --region eu-north-1

# Get S3 event notifications
aws s3api get-bucket-notification-configuration \
  --bucket phc-audio-uploads-1762597760 \
  --region eu-north-1
```

### Check DynamoDB Items
```bash
# Scan all patients
aws dynamodb scan --table-name Patients --region eu-north-1 | jq '.Items'

# Scan all notes
aws dynamodb scan --table-name PatientNotes --region eu-north-1 | jq '.Items'

# Scan all history
aws dynamodb scan --table-name PatientHistory --region eu-north-1 | jq '.Items'
```

---

## 🔥 Common Issues

### Issue 1: "Presigned URL expired"
**Cause:** URLs expire in 5 minutes
**Fix:** Get a new presigned URL

### Issue 2: "SOAP note not appearing"
**Check:**
1. Lambda logs: `sam logs -n ScribeTaskFunction --tail`
2. S3 file exists: `aws s3 ls s3://phc-audio-uploads-1762597760/`
3. Transcribe job: `aws transcribe list-transcription-jobs --region eu-north-1`

### Issue 3: "CORS error from mobile app"
**Fix:** CORS is enabled in API Gateway (already configured)

### Issue 4: "Upload fails with 403"
**Check:** Presigned URL not expired, correct Content-Type header

---

## 📱 Mobile App Integration Checklist

- [ ] Save base URL in config: `https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod`
- [ ] Implement patient registration screen
- [ ] Store patient_id in app state (SharedPreferences/SecureStorage)
- [ ] Request presigned URL before each upload
- [ ] Upload audio directly to S3 presigned URL
- [ ] Upload images directly to S3 presigned URL
- [ ] Show loading indicator while processing (~30 seconds)
- [ ] Poll DynamoDB or use WebSocket for real-time updates

---

## 🎯 Next Steps

1. **Test with Mobile App:**
   - Integrate these endpoints
   - Test audio recording → upload
   - Test camera capture → upload

2. **Add Missing Endpoints:**
   - [ ] GET `/patients` - List all patients
   - [ ] GET `/timeline/{patient_id}` - RAG timeline (TODO)
   - [ ] WebSocket/IoT for real-time updates (TODO)

3. **Build Doctor Dashboard:**
   - Display patient list
   - Show SOAP notes with typewriter effect
   - Show medication timeline

4. **Production Improvements:**
   - Add authentication (API keys or Cognito)
   - Add rate limiting
   - Set up CloudWatch alarms
   - Enable AWS X-Ray tracing

---

## 📊 Cost Tracking

Check current costs:
```bash
aws ce get-cost-and-usage \
  --time-period Start=2025-11-08,End=2025-11-09 \
  --granularity DAILY \
  --metrics BlendedCost \
  --region eu-north-1
```

Expected hackathon costs: **~$2-5** (Lambda + DynamoDB + S3 + Transcribe + Textract)

---

**Last Updated:** 2025-11-08
**Deployment Status:** ✅ LIVE
**Region:** eu-north-1 (Stockholm)
