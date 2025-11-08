# Medical Timeline API Documentation

This document describes the endpoints for generating and retrieving AI-powered medical timelines, as well as managing patient queue status.

## Table of Contents
- [Timeline Endpoints](#timeline-endpoints)
- [Queue Management Endpoints](#queue-management-endpoints)
- [Data Models](#data-models)

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
    "in_progress": 1,
    "completed": 5,
    "total": 9
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

### 5. Start Consultation

**Endpoint:** `POST /queue/{queue_id}/start`

**Description:** Marks a consultation as started. Changes status from `waiting` to `in_progress`.

**Path Parameters:**
- `queue_id` (string, required): Queue entry identifier

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
    "status": "in_progress",
    "started_at": "2024-01-15T10:15:00"
  }
}
```

**Error Responses:**
- `400 Bad Request`: Another patient is already in consultation
- `404 Not Found`: Queue entry not found

---

### 6. Complete Consultation

**Endpoint:** `POST /queue/{queue_id}/complete`

**Description:** Marks a consultation as completed. This indicates the doctor has finished seeing the patient.

**Path Parameters:**
- `queue_id` (string, required): Queue entry identifier

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

### 7. Get Waiting Patients

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

### 8. Get Current Patient

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

### Queue Status Enum
- `waiting`: Patient in waiting room
- `in_progress`: Currently with doctor
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

### Nurse App Flow
```dart
// 1. Register patient and get patient_id
final patientId = await apiService.registerPatient(patientData);

// 2. Upload audio/documents with batch_id
final batchId = uploadQueueManager.currentBatchId;
await uploadQueueManager.uploadAudio(patientId, audioFile);
await uploadQueueManager.uploadDocument(patientId, imageFile);

// 3. Complete batch and generate timeline
final result = await apiService.completeBatchAndGenerateTimeline(
  patientId: patientId,
  batchId: batchId,
);

// 4. Add to doctor's queue (optional - can be automatic)
await apiService.addToQueue(patientId: patientId, priority: 'normal');
```

### Doctor Dashboard Flow
```javascript
// 1. Get current queue status
const queue = await fetch('/queue').then(r => r.json());

// 2. Start consultation with next patient
const queueId = queue.queue[0].queue_id;
await fetch(`/queue/${queueId}/start`, { method: 'POST' });

// 3. Get patient's medical timeline
const patientId = queue.queue[0].patient_id;
const timeline = await fetch(`/documents/${patientId}/timeline`).then(r => r.json());

// 4. Review timeline and provide treatment
// ... doctor interaction ...

// 5. Mark consultation as complete
await fetch(`/queue/${queueId}/complete`, { method: 'POST' });
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
