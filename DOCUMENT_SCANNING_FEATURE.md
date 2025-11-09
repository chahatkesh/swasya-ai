# Multi-Document Scanning & Timeline Generation

## 🎯 Feature Overview

This feature allows nurses to scan **multiple prescription documents** for a patient, process them individually, and then generate a **comprehensive medical timeline** using AI.

## 📋 Workflow

```
1. START BATCH → Begin scanning session
2. UPLOAD DOCS → Scan 1, 2, 3... N documents (one by one)
3. COMPLETE BATCH → Generate comprehensive timeline
4. VIEW TIMELINE → See chronological medical history
```

## 🔄 How It Works

### Step 1: Start Document Batch
```bash
POST /documents/{patient_id}/start-batch
```
- Creates a new "scanning session"
- Returns `batch_id`
- Patient can have only ONE active batch at a time

### Step 2: Upload Documents (Multiple Times)
```bash
POST /documents/{patient_id}/upload?batch_id=BATCH_XXX
```
- Upload document images one by one
- Each document is **processed immediately** using Gemini Vision
- Extracted data stored in MongoDB
- Can upload 1, 5, 10, or any number of documents

**Background Processing:**
- Document saved → MongoDB
- Gemini Vision → Extract prescription details
- Status updated: `processing` → `completed`/`failed`

### Step 3: Complete Batch & Generate Timeline
```bash
POST /documents/{patient_id}/complete-batch?batch_id=BATCH_XXX
```

**What happens:**
1. ✅ Gather all processed documents
2. 🤖 Send ALL extracted data to Gemini 2.0 Flash
3. 📊 AI generates comprehensive timeline:
   - Chronological events
   - Current medications
   - Chronic conditions
   - Drug allergies
   - Medical summary
4. 💾 Save timeline to MongoDB
5. 📝 Add summary to patient history

### Step 4: View Timeline
```bash
GET /documents/{patient_id}/timeline
```
Returns complete medical timeline with:
- **Timeline Events**: All visits/prescriptions chronologically
- **Current Medications**: Active drugs patient should be taking
- **Chronic Conditions**: Recurring health issues
- **Allergies**: Known drug allergies
- **Summary**: AI-generated health overview

## 🗄️ Data Storage

### MongoDB Collections

#### 1. `documents`
```json
{
  "document_id": "DOC_ABC123",
  "patient_id": "PAT_123",
  "batch_id": "BATCH_XYZ",
  "image_file": "prescription_1.jpg",
  "status": "completed",
  "uploaded_at": "2025-11-08T10:30:00",
  "extracted_data": {
    "doctor_name": "Dr. Smith",
    "date": "2025-11-05",
    "medications": [...]
  }
}
```

#### 2. `batches`
```json
{
  "batch_id": "BATCH_XYZ",
  "patient_id": "PAT_123",
  "patient_name": "Ram Kumar",
  "document_ids": ["DOC_1", "DOC_2", "DOC_3"],
  "status": "completed",
  "created_at": "2025-11-08T10:00:00",
  "completed_at": "2025-11-08T10:45:00"
}
```

#### 3. `timelines`
```json
{
  "patient_id": "PAT_123",
  "batch_id": "BATCH_XYZ",
  "generated_at": "2025-11-08T10:45:00",
  "total_documents": 5,
  "timeline_events": [...],
  "current_medications": [...],
  "chronic_conditions": ["Hypertension", "Diabetes"],
  "allergies": ["Penicillin"],
  "summary": "Patient has chronic hypertension managed with..."
}
```

## 🔧 API Endpoints

### Document Management

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/documents/{patient_id}/start-batch` | POST | Start new scanning session |
| `/documents/{patient_id}/upload` | POST | Upload single document to batch |
| `/documents/{patient_id}/complete-batch` | POST | Finish scanning & generate timeline |
| `/documents/{patient_id}/timeline` | GET | Get comprehensive timeline |
| `/documents/{patient_id}/documents` | GET | Get all scanned documents |
| `/documents/{patient_id}/batches` | GET | Get all batches |

## 📱 Mobile App Integration

### Camera Screen Update Required

```dart
// New workflow in camera_screen.dart

// 1. On screen entry - Start batch
final batchResponse = await ApiService.startDocumentBatch(patientId);
final batchId = batchResponse['batch_id'];

// 2. For each photo taken
await ApiService.uploadDocumentToBatch(
  patientId: patientId,
  batchId: batchId,
  fileBytes: imageBytes,
  fileName: fileName,
);

// Show: "Document 1 of ? uploaded"
// Button: "Scan Another" or "Complete Scanning"

// 3. When user clicks "Complete Scanning"
final timelineResponse = await ApiService.completeBatch(
  patientId: patientId,
  batchId: batchId,
);

// Show timeline summary dialog
// Navigate to dashboard or show timeline screen
```

### New API Service Methods Needed

```dart
class ApiService {
  static Future<Map<String, dynamic>> startDocumentBatch(String patientId) async {
    final response = await http.post(
      Uri.parse('${Config.apiBaseUrl}/documents/$patientId/start-batch'),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> uploadDocumentToBatch({
    required String patientId,
    required String batchId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${Config.apiBaseUrl}/documents/$patientId/upload?batch_id=$batchId'),
    );
    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );
    var response = await http.Response.fromStream(await request.send());
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> completeBatch({
    required String patientId,
    required String batchId,
  }) async {
    final response = await http.post(
      Uri.parse('${Config.apiBaseUrl}/documents/$patientId/complete-batch?batch_id=$batchId'),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPatientTimeline(String patientId) async {
    final response = await http.get(
      Uri.parse('${Config.apiBaseUrl}/documents/$patientId/timeline'),
    );
    return jsonDecode(response.body);
  }
}
```

## 🎨 UI Flow Suggestions

### Enhanced Camera Screen

```
┌─────────────────────────────────┐
│  Scan Documents - Ram Kumar     │
├─────────────────────────────────┤
│                                 │
│   [Camera Preview or Image]     │
│                                 │
├─────────────────────────────────┤
│ Batch ID: BATCH_AE52F766        │
│ Documents Scanned: 3            │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │  📷 Capture Document    │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │  ✅ Complete Scanning   │   │
│  └─────────────────────────┘   │
│                                 │
│  Documents in this batch:       │
│  • Document 1 ✓ Processed       │
│  • Document 2 ✓ Processed       │
│  • Document 3 ⏳ Processing      │
│                                 │
└─────────────────────────────────┘
```

### Timeline View Screen (New)

```
┌─────────────────────────────────┐
│  Medical Timeline - Ram Kumar   │
├─────────────────────────────────┤
│                                 │
│  📊 Summary                     │
│  5 documents processed          │
│  12 medications identified      │
│  2 chronic conditions           │
│                                 │
│  ────────────────────────────   │
│                                 │
│  📅 Timeline Events             │
│                                 │
│  2025-11-05                     │
│  🏥 Prescription - Dr. Smith    │
│  • Metformin 500mg TDS          │
│  • Amlodipine 5mg OD            │
│                                 │
│  2025-10-20                     │
│  🏥 Prescription - Dr. Kumar    │
│  • Paracetamol 650mg SOS        │
│                                 │
│  💊 Current Medications         │
│  • Metformin 500mg TDS          │
│  • Amlodipine 5mg OD            │
│                                 │
│  ⚠️ Chronic Conditions          │
│  • Type 2 Diabetes              │
│  • Hypertension                 │
│                                 │
└─────────────────────────────────┘
```

## 🧪 Testing

### Test Full Workflow

```bash
# 1. Register patient
curl -X POST http://localhost:8000/patients \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Patient","phone":"9876543210"}'

# 2. Start batch
curl -X POST "http://localhost:8000/documents/PAT_XXX/start-batch"

# 3. Upload multiple documents
for i in {1..3}; do
  curl -X POST "http://localhost:8000/documents/PAT_XXX/upload?batch_id=BATCH_YYY" \
    -F "file=@prescription_$i.jpg"
done

# 4. Complete batch and generate timeline
curl -X POST "http://localhost:8000/documents/PAT_XXX/complete-batch?batch_id=BATCH_YYY"

# 5. View timeline
curl "http://localhost:8000/documents/PAT_XXX/timeline" | jq
```

## 🎯 Benefits

1. **No Data Loss**: Each document stored permanently
2. **Individual Processing**: Each prescription analyzed separately
3. **Comprehensive View**: AI combines all data into timeline
4. **Chronological**: Events sorted by date automatically
5. **Smart Analysis**: Identifies current meds, chronic conditions
6. **MongoDB Storage**: Fast queries, scalable
7. **Async Processing**: Upload multiple docs quickly

## 🚀 Next Steps

1. ✅ Backend implemented
2. 📱 Update Flutter camera screen
3. 🎨 Create timeline view screen
4. 🧪 Test with real prescription images
5. 📊 Add analytics dashboard
6. 🔄 Add re-scan capability
7. 📤 Export timeline as PDF

## 💡 Future Enhancements

- **Real-time Progress**: WebSocket updates during processing
- **Image Quality Check**: Warn if image is blurry
- **Duplicate Detection**: AI detects same prescription uploaded twice
- **Drug Interaction Warnings**: Check for dangerous combinations
- **Prescription Reminders**: Notify when medication needs refill
- **Multi-language Support**: Process documents in Hindi, Tamil, etc.
