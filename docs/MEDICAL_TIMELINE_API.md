# Medical Timeline API Documentation

This document describes the endpoints for generating and retrieving AI-powered medical timelines, as well as managing patient queue status with the new nurse workflow.

## Table of Contents
- [Timeline Endpoints](#timeline-endpoints)
- [Queue Management Endpoints](#queue-management-endpoints)
- [Data Models](#data-models)
- [Workflow Overview](#workflow-overview)

---

## Workflow Overview

### Complete Patient Journey

```
1. Registration (Nurse)
   ↓ Auto-adds to queue with status: "waiting"
   
2. Nurse Records Data
   ↓ Records audio, scans documents
   
3. Nurse Clicks "Send to Doctor"
   ↓ POST /queue/{queue_id}/nurse-complete
   ↓ Status changes to: "nurse_completed"
   
4. Timeline Generation (Automatic)
   ↓ POST /documents/{patient_id}/complete-batch
   ↓ Status auto-updates to: "ready_for_doctor"
   
5. Doctor Starts Consultation
   ↓ POST /queue/{queue_id}/start
   ↓ Status changes to: "in_consultation"
   
6. Doctor Completes
   ↓ POST /queue/{queue_id}/complete
   ↓ Status changes to: "completed"
```

### Queue Status Flow

- **`waiting`**: Patient just registered, nurse hasn't started work
- **`nurse_completed`**: Nurse finished, timeline generating
- **`ready_for_doctor`**: Timeline ready, waiting for doctor
- **`in_consultation`**: Doctor actively reviewing patient
- **`completed`**: Consultation finished
- **`cancelled`**: Queue entry cancelled

---

## Timeline Endpoints

### 1. Generate Medical Timeline

**Endpoint:** `POST /documents/{patient_id}/complete-batch`

**Description:** Processes all uploaded documents in a batch and generates a comprehensive medical timeline using AI. This endpoint is called after the nurse finishes scanning/recording all documents for a patient visit.

**Path Parameters:**
- `patient_id` (string, required): Unique identifier for the patient

**Query Parameters:**
- `batch_id` (string, required): Batch identifier for the upload session

**Request Example:**
```bash
POST /documents/PT_123abc/complete-batch?batch_id=BATCH_xyz789
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Timeline generated successfully",
  "patient_id": "PT_123abc",
  "batch_id": "BATCH_xyz789",
  "timeline_id": "TIMELINE_pt123_20240115_143022",
  "statistics": {
    "documents_processed": 5,
    "timeline_events": 12,
    "medications": 3,
    "conditions": 2
  }
}
```

**Processing Flow:**
1. Retrieves all documents in the batch
2. Waits for all uploads to complete
3. Sends document data to AI for analysis
4. Generates structured timeline with:
   - Chronological events (visits, diagnoses, procedures)
   - Current medications
   - Chronic conditions
   - Known allergies
   - Medical summary
5. Saves timeline to MongoDB and JSON storage
6. Returns statistics

**Error Responses:**
- `404 Not Found`: Patient not found
- `400 Bad Request`: Missing batch_id or no documents in batch
- `500 Internal Server Error`: AI processing failed

---

### 2. Retrieve Medical Timeline

**Endpoint:** `GET /documents/{patient_id}/timeline`

**Description:** Retrieves the most recent medical timeline for a patient. Returns the complete timeline with all events, medications, conditions, and summary.

**Path Parameters:**
- `patient_id` (string, required): Unique identifier for the patient

**Request Example:**
```bash
GET /documents/PT_123abc/timeline
```

**Response (200 OK) - Timeline Exists:**
```json
{
  "success": true,
  "patient_id": "PT_123abc",
  "patient_name": "Rajesh Kumar",
  "timeline": {
    "timeline_id": "TIMELINE_pt123_20240115_143022",
    "patient_id": "PT_123abc",
    "generated_at": "2024-01-15T14:30:22",
    "timeline_events": [
      {
        "date": "2024-01-15",
        "event_type": "visit",
        "description": "Routine checkup for hypertension follow-up",
        "details": {
          "bp": "140/90",
          "weight": "72kg",
          "complaints": "Occasional headaches"
        }
      },
      {
        "date": "2023-12-10",
        "event_type": "diagnosis",
        "description": "Diagnosed with Type 2 Diabetes",
        "details": {
          "hba1c": "7.2%",
          "fasting_glucose": "156 mg/dL"
        }
      }
    ],
    "current_medications": [
      {
        "name": "Metformin",
        "dosage": "500mg",
        "frequency": "Twice daily",
        "started": "2023-12-10"
      },
      {
        "name": "Amlodipine",
        "dosage": "5mg",
        "frequency": "Once daily",
        "started": "2023-08-15"
      }
    ],
    "chronic_conditions": [
      {
        "condition": "Type 2 Diabetes Mellitus",
        "diagnosed_date": "2023-12-10",
        "status": "controlled"
      },
      {
        "condition": "Essential Hypertension",
        "diagnosed_date": "2023-08-15",
        "status": "managed"
      }
    ],
    "known_allergies": [
      {
        "allergen": "Penicillin",
        "reaction": "Rash",
        "severity": "moderate"
      }
    ],
    "summary": "52-year-old male with controlled Type 2 Diabetes and Essential Hypertension. Currently on Metformin and Amlodipine. Known penicillin allergy. Recent visit shows BP slightly elevated, patient reports occasional headaches. Recommend continued monitoring and possible medication adjustment."
  }
}
```

**Response (200 OK) - No Timeline:**
```json
{
  "success": true,
  "patient_id": "PT_123abc",
  "patient_name": "Rajesh Kumar",
  "timeline": null
}
```

**Error Responses:**
- `404 Not Found`: Patient not found
- `500 Internal Server Error`: Database retrieval failed

---

## Queue Management Endpoints

These endpoints manage the patient queue and consultation status flow.

### 0. Patient Registration (Auto-Queue)

**Endpoint:** `POST /patients`

**Description:** Register a new patient. **NEW**: Automatically adds patient to queue with status `waiting`.

**Request Body:**
```json
{
  "uhid": "GH123456789",
  "name": "Ram Kumar",
  "phone": "9876543210",
  "age": 45,
  "gender": "male"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "patient_id": "PAT_123ABC",
  "queue_id": "Q_A1B2C3D4",
  "uhid": "GH123456789",
  "message": "Patient Ram Kumar registered and added to queue"
}
```

**✨ Key Changes:**
- **NEW**: Auto-adds patient to queue (no separate `/queue` call needed)
- **NEW**: Returns `queue_id` in response (nurse app stores this)
- Initial queue status: `waiting`
- Token number assigned automatically

---

### 3. Get Queue Status

**Endpoint:** `GET /queue`

**Description:** Retrieves current queue status with all patients and statistics.

**Request Example:**
```bash
GET /queue
```

**Response (200 OK):**
```json
{
  "success": true,
  "stats": {
    "waiting": 3,
    "nurse_completed": 2,
    "ready_for_doctor": 1,
    "in_consultation": 1,
    "completed": 5,
    "total": 12
  },
  "queue": [
    {
      "queue_id": "Q_A1B2C3D4",
      "patient_id": "PT_123abc",
      "patient_name": "Rajesh Kumar",
      "token_number": 1,
      "priority": "normal",
      "status": "in_progress",
      "added_at": "2024-01-15T09:00:00",
      "started_at": "2024-01-15T09:15:00",
      "completed_at": null
    },
    {
      "queue_id": "Q_E5F6G7H8",
      "patient_id": "PT_456def",
      "patient_name": "Priya Sharma",
      "token_number": 2,
      "priority": "urgent",
      "status": "waiting",
      "added_at": "2024-01-15T09:30:00",
      "started_at": null,
      "completed_at": null
    }
  ]
}
```

---

### 4. Add Patient to Queue

**Endpoint:** `POST /queue`

**Description:** Adds a patient to the consultation queue. Automatically assigns token number.

**Request Body:**
```json
{
  "patient_id": "PT_123abc",
  "priority": "normal"
}
```

Or use UHID instead:
```json
{
  "uhid": "GH123456789",
  "priority": "urgent"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Patient added to queue",
  "queue_entry": {
    "queue_id": "Q_A1B2C3D4",
    "patient_id": "PT_123abc",
    "patient_name": "Rajesh Kumar",
    "token_number": 4,
    "priority": "normal",
    "status": "waiting",
    "added_at": "2024-01-15T10:00:00",
    "started_at": null,
    "completed_at": null
  }
}
```

**Error Responses:**
- `400 Bad Request`: Must provide either patient_id or uhid
- `400 Bad Request`: Patient already in queue
- `404 Not Found`: Patient not found

---

### 5. Nurse Complete Patient ✨ NEW

**Endpoint:** `POST /queue/{queue_id}/nurse-complete`

**Description:** Nurse marks patient as completed after recording audio/scanning documents. This triggers timeline generation automatically.

**Path Parameters:**
- `queue_id` (string, required): Queue entry identifier

**Status Flow:**
- `waiting` → `nurse_completed`

**Request Example:**
```bash
POST /queue/Q_A1B2C3D4/nurse-complete
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Patient ready for timeline generation",
  "queue_entry": {
    "queue_id": "Q_A1B2C3D4",
    "patient_id": "PT_123abc",
    "patient_name": "Rajesh Kumar",
    "status": "nurse_completed",
    "nurse_completed_at": "2024-01-15T10:10:00"
  }
}
```

**What Happens Next:**
1. Status changes to `nurse_completed`
2. Timeline generation starts automatically
3. When timeline is ready, status auto-updates to `ready_for_doctor`
4. Doctor can then see patient in their queue

**Nurse App Usage:**
- Called when nurse clicks "Send to Doctor" button
- Nurse can immediately proceed to next patient
- Timeline processes in background

**Error Responses:**
- `404 Not Found`: Queue entry not found

---

### 6. Start Consultation

**Endpoint:** `POST /queue/{queue_id}/start`

**Description:** Doctor starts consultation with patient. Changes status from `ready_for_doctor` to `in_consultation`.

**Path Parameters:**
- `queue_id` (string, required): Queue entry identifier

**Status Flow:**
- `ready_for_doctor` → `in_consultation`

**Request Example:**
```bash
POST /queue/Q_A1B2C3D4/start
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Consultation started",
  "queue_entry": {
    "queue_id": "Q_A1B2C3D4",
    "patient_id": "PT_123abc",
    "patient_name": "Rajesh Kumar",
    "status": "in_consultation",
    "started_at": "2024-01-15T10:15:00"
  }
}
```

**Error Responses:**
- `400 Bad Request`: Another patient is already in consultation
- `404 Not Found`: Queue entry not found

---

### 7. Complete Consultation

**Endpoint:** `POST /queue/{queue_id}/complete`

**Description:** Doctor marks consultation as completed after finishing treatment.

**Path Parameters:**
- `queue_id` (string, required): Queue entry identifier

**Status Flow:**
- `in_consultation` → `completed`

**Request Example:**
```bash
POST /queue/Q_A1B2C3D4/complete
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Consultation completed",
  "queue_entry": {
    "queue_id": "Q_A1B2C3D4",
    "patient_id": "PT_123abc",
    "patient_name": "Rajesh Kumar",
    "status": "completed",
    "completed_at": "2024-01-15T10:45:00"
  }
}
```

**Error Responses:**
- `404 Not Found`: Queue entry not found

---

### 8. Get Waiting Patients

**Endpoint:** `GET /queue/waiting`

**Description:** Returns only patients currently in waiting status. Useful for waiting room displays.

**Response (200 OK):**
```json
{
  "success": true,
  "count": 3,
  "patients": [
    {
      "queue_id": "Q_E5F6G7H8",
      "patient_name": "Priya Sharma",
      "token_number": 2,
      "status": "waiting"
    }
  ]
}
```

---

### 9. Get Current Patient

**Endpoint:** `GET /queue/current`

**Description:** Returns the patient currently in consultation. Useful for doctor's dashboard.

**Response (200 OK) - Patient in Progress:**
```json
{
  "success": true,
  "queue_entry": {
    "queue_id": "Q_A1B2C3D4",
    "patient_name": "Rajesh Kumar",
    "token_number": 1,
    "status": "in_progress"
  },
  "patient": {
    "patient_id": "PT_123abc",
    "name": "Rajesh Kumar",
    "age": 52,
    "gender": "Male",
    "uhid": "GH123456789"
  }
}
```

**Response (200 OK) - No Patient:**
```json
{
  "success": true,
  "message": "No patient currently in consultation",
  "patient": null
}
```

---

## Data Models

### Queue Status Enum ✨ UPDATED
- `waiting`: Patient just registered, nurse hasn't started work
- `nurse_completed`: ✨ **NEW** - Nurse finished, timeline generating
- `ready_for_doctor`: ✨ **NEW** - Timeline ready, waiting for doctor review
- `in_consultation`: Currently with doctor (renamed from `in_progress`)
- `completed`: Consultation finished
- `cancelled`: Queue entry cancelled

### Priority Enum
- `normal`: Standard priority
- `urgent`: High priority (emergency cases)

### Timeline Event Types
- `visit`: Regular consultation or checkup
- `diagnosis`: New condition diagnosed
- `procedure`: Medical procedure performed
- `lab_result`: Laboratory test results
- `prescription`: Medication prescribed
- `referral`: Referred to specialist

---

## Integration Examples

### Nurse App Flow ✨ UPDATED
```dart
// 1. Register patient - AUTO-ADDS TO QUEUE
final response = await ApiService.registerPatient(
  uhid: uhid,
  name: name,
  phone: phone,
  age: age,
  gender: gender,
);
final patientId = response['patient_id'];
final queueId = response['queue_id'];  // NEW: Store this!

// Store queue_id in SharedPreferences for later use
await prefs.setString('current_queue_id', queueId);

// 2. Upload audio/documents with batch_id
final batchId = uploadQueueManager.currentBatchId;
await uploadQueueManager.uploadAudio(patientId, audioFile);
await uploadQueueManager.uploadDocument(patientId, imageFile);

// 3. Nurse clicks "Send to Doctor" button
await ApiService.nurseCompletePatient(queueId);
// Status: waiting → nurse_completed

// 4. Timeline generates automatically in background
// (Upload queue manager handles this via completeBatch)
// Status auto-updates: nurse_completed → ready_for_doctor

// 5. Nurse can immediately proceed to next patient
Navigator.pushReplacement(context, HomeScreen());
```

### Doctor Dashboard Flow ✨ UPDATED
```javascript
// 1. Get current queue status
const queue = await fetch('/queue').then(r => r.json());

// 2. Filter patients by status
const readyForDoctor = queue.queue.filter(p => p.status === 'ready_for_doctor');
const inConsultation = queue.queue.filter(p => p.status === 'in_consultation');

// Display only ready_for_doctor patients to doctor
console.log(`${readyForDoctor.length} patients ready for review`);

// 3. Doctor clicks on patient to start consultation
const patient = readyForDoctor[0];
await fetch(`/queue/${patient.queue_id}/start`, { method: 'POST' });
// Status: ready_for_doctor → in_consultation

// 4. Get patient's medical timeline
const timeline = await fetch(`/documents/${patient.patient_id}/timeline`)
  .then(r => r.json());

// 5. Display timeline in UI
displayTimeline(timeline);

// 6. Doctor provides treatment and clicks "Complete"
await fetch(`/queue/${patient.queue_id}/complete`, { method: 'POST' });
// Status: in_consultation → completed

// 7. Patient automatically removed from active queue
refreshQueue();
```

---

## Storage

### MongoDB Collections
- `timelines`: Stores generated medical timelines
- `patients`: Patient demographic data
- `queue`: Queue entries (optional, can use in-memory)

### JSON Backup Storage
- Location: `data/notes.json`
- Timeline entries prefixed with: `TIMELINE_*`
- Format: `TIMELINE_{patient_id}_{timestamp}`

---

## Notes

1. **Timeline Generation**: May take 10-30 seconds depending on document count and AI processing time
2. **Queue Management**: Only one patient can be `in_progress` at a time
3. **Completed Entries**: Use `/queue/cleanup` endpoint to periodically remove old completed entries
4. **Real-time Updates**: Consider using WebSocket or polling for queue status updates in doctor dashboard
5. **Timeline Updates**: Timeline is regenerated each time batch is completed, new timeline replaces old one

---

## Support

For API issues or questions:
- Check logs in `simple_backend/` directory
- Review MongoDB connection in `app/services/mongo_service.py`
- Verify AI service configuration in environment variables
