# Doctor Dashboard API Documentation

Base URL: `http://192.168.0.7:8000`

All responses follow this format:
```json
{
  "success": true,
  "data": {...}
}
```

---

## IMPORTANT NOTES

### Queue Management
- Queue will be empty initially. Patients must be added to queue via nurse app or POST endpoint.
- Use `POST /queue` to add patients before testing queue endpoints.
- Queue IDs are generated dynamically (format: `Q_XXXXXXXX`).

### HTTP Methods
- GET endpoints: Retrieve data (no body needed)
- POST endpoints: Create/update (requires JSON body)
- Use `-X POST` with curl for POST requests

### Common Issues
1. **Empty queue response**: No patients in queue yet. Add patient first with `POST /queue`.
2. **Method Not Allowed**: Using GET instead of POST, or vice versa.
3. **404 Not Found**: Patient ID or Queue ID doesn't exist in system.

---

## Patient Management

### 1. List All Patients
**Endpoint:** `GET /patients`

**Response:**
```json
{
  "success": true,
  "count": 25,
  "patients": [
    {
      "patient_id": "PAT_A6C5DC51",
      "uhid": "UHID123456789",
      "name": "Ram Kumar",
      "phone": "9876543210",
      "age": 45,
      "gender": "male",
      "created_at": "2025-11-08T10:30:00",
      "last_visit": "2025-11-08T14:20:00",
      "visit_count": 3,
      "status": "active"
    }
  ]
}
```

**Use for:** Patient list view, search functionality

---

### 2. Get Patient Details
**Endpoint:** `GET /patients/{patient_id}`

**Response:**
```json
{
  "success": true,
  "patient": {
    "patient_id": "PAT_A6C5DC51",
    "name": "Ram Kumar",
    "phone": "9876543210",
    "age": 45,
    "gender": "male",
    "created_at": "2025-11-08T10:30:00"
  },
  "notes_count": 5,
  "history_count": 3,
  "latest_notes": [...],
  "latest_history": [...],
  "queue_status": "waiting"
}
```

**Use for:** Patient profile view with quick summary

---

### 3. Get Complete Patient Record
**Endpoint:** `GET /patients/{patient_id}/complete`

**Response:**
```json
{
  "success": true,
  "patient": {...},
  "notes": [
    {
      "note_id": "NOTE_12AB34CD",
      "created_at": "2025-11-08T14:20:00",
      "transcript": "Patient reports fever and headache...",
      "soap_note": {
        "subjective": "Patient complains of fever...",
        "objective": "Temperature: 101°F, BP: 120/80",
        "assessment": "Viral fever suspected",
        "plan": "Paracetamol 500mg TDS for 3 days",
        "chief_complaint": "Fever and headache"
      },
      "audio_file": "PAT_A6C5DC51_audio_1234.m4a"
    }
  ],
  "history": [
    {
      "history_id": "HIST_56EF78GH",
      "created_at": "2025-11-08T11:00:00",
      "prescription_data": {
        "doctor_name": "Dr. Sharma",
        "date": "2025-11-08",
        "diagnosis": "Hypertension",
        "medications": [
          {
            "name": "Amlodipine",
            "dosage": "5mg",
            "frequency": "Once daily",
            "duration": "30 days"
          }
        ]
      },
      "image_file": "PAT_A6C5DC51_doc_5678.jpg"
    }
  ]
}
```

**Use for:** Full patient history view, detailed consultation screen

---

### 4. Get Patient Summary (Recommended for Quick View)
**Endpoint:** `GET /summary/{patient_id}`

**Response:**
```json
{
  "success": true,
  "patient": {
    "id": "PAT_A6C5DC51",
    "name": "Ram Kumar",
    "phone": "9876543210",
    "age": 45,
    "gender": "male"
  },
  "statistics": {
    "total_visits": 5,
    "prescriptions_on_file": 3,
    "member_since": "2025-10-15T08:00:00"
  },
  "latest_visit": {
    "note_id": "NOTE_12AB34CD",
    "created_at": "2025-11-08T14:20:00",
    "soap_note": {...}
  },
  "chief_complaints": [
    {
      "complaint": "Fever and headache",
      "date": "2025-11-08T14:20:00"
    },
    {
      "complaint": "High blood pressure",
      "date": "2025-11-05T10:30:00"
    }
  ],
  "recent_medications": ["Paracetamol", "Amlodipine", "Aspirin"]
}
```

**Use for:** Doctor's quick patient overview before consultation

---

## Queue Management

### 5. Get Current Queue
**Endpoint:** `GET /queue`

**Response:**
```json
{
  "success": true,
  "stats": {
    "waiting": 5,
    "in_progress": 1,
    "completed": 12,
    "total": 18
  },
  "queue": [
    {
      "queue_id": "Q_9A8B7C6D",
      "patient_id": "PAT_A6C5DC51",
      "patient_name": "Ram Kumar",
      "token_number": 1,
      "priority": "normal",
      "status": "waiting",
      "added_at": "2025-11-08T09:00:00",
      "started_at": null,
      "completed_at": null
    },
    {
      "queue_id": "Q_1E2F3G4H",
      "patient_id": "PAT_B7D8E9F0",
      "patient_name": "Sita Devi",
      "token_number": 2,
      "priority": "urgent",
      "status": "in_progress",
      "added_at": "2025-11-08T09:15:00",
      "started_at": "2025-11-08T09:30:00",
      "completed_at": null
    }
  ]
}
```

**Use for:** Main queue display, short polling every 5-10 seconds

---

### 6. Get Waiting Patients Only
**Endpoint:** `GET /queue/waiting`

**Response:**
```json
{
  "success": true,
  "count": 5,
  "patients": [
    {
      "queue_id": "Q_9A8B7C6D",
      "patient_id": "PAT_A6C5DC51",
      "patient_name": "Ram Kumar",
      "token_number": 1,
      "priority": "normal",
      "status": "waiting",
      "added_at": "2025-11-08T09:00:00"
    }
  ]
}
```

**Use for:** Waiting room display screen

---

### 7. Get Current Patient (In Consultation)
**Endpoint:** `GET /queue/current`

**Response:**
```json
{
  "success": true,
  "queue_entry": {
    "queue_id": "Q_1E2F3G4H",
    "patient_id": "PAT_B7D8E9F0",
    "patient_name": "Sita Devi",
    "token_number": 2,
    "priority": "urgent",
    "status": "in_progress",
    "started_at": "2025-11-08T09:30:00"
  },
  "patient": {
    "patient_id": "PAT_B7D8E9F0",
    "uhid": "UHID987654321",
    "name": "Sita Devi",
    "phone": "9123456789",
    "age": 52,
    "gender": "female"
  }
}
```

**Use for:** Doctor's active consultation screen

---

### 8. Start Consultation
**Endpoint:** `POST /queue/{queue_id}/start`

**Response:**
```json
{
  "success": true,
  "message": "Consultation started",
  "queue_entry": {
    "queue_id": "Q_9A8B7C6D",
    "status": "in_progress",
    "started_at": "2025-11-08T10:00:00"
  }
}
```

**Use for:** When doctor clicks "Start Consultation" button

---

### 9. Complete Consultation
**Endpoint:** `POST /queue/{queue_id}/complete`

**Response:**
```json
{
  "success": true,
  "message": "Consultation completed",
  "queue_entry": {
    "queue_id": "Q_9A8B7C6D",
    "status": "completed",
    "completed_at": "2025-11-08T10:30:00"
  }
}
```

**Use for:** When doctor finishes consultation

---

## Medical Notes

### 10. Get All Patient Notes
**Endpoint:** `GET /notes/{patient_id}`

**Response:**
```json
{
  "success": true,
  "patient_id": "PAT_A6C5DC51",
  "patient_name": "Ram Kumar",
  "count": 5,
  "notes": [
    {
      "note_id": "NOTE_12AB34CD",
      "patient_id": "PAT_A6C5DC51",
      "created_at": "2025-11-08T14:20:00",
      "audio_file": "PAT_A6C5DC51_audio_1234.m4a",
      "transcript": "Patient reports fever for 2 days...",
      "soap_note": {
        "subjective": "Patient complains of fever and body ache for 2 days",
        "objective": "Temperature: 101°F, Pulse: 88/min, BP: 120/80",
        "assessment": "Viral fever",
        "plan": "Paracetamol 500mg TDS, rest, increase fluid intake",
        "chief_complaint": "Fever and body ache"
      }
    }
  ]
}
```

**Use for:** Medical history timeline view

---

### 11. Get Latest Note Only
**Endpoint:** `GET /notes/{patient_id}/latest`

**Response:**
```json
{
  "success": true,
  "patient_id": "PAT_A6C5DC51",
  "patient_name": "Ram Kumar",
  "note": {
    "note_id": "NOTE_12AB34CD",
    "created_at": "2025-11-08T14:20:00",
    "soap_note": {...}
  }
}
```

**Use for:** Quick view of most recent visit, short polling for live updates

---

### 12. Get Complete Medical Timeline (RECOMMENDED FOR DOCTOR DASHBOARD)
**Endpoint:** `GET /timeline/{patient_id}`

**Description:** Combines all SOAP notes and prescription history in chronological order

**Response:**
```json
{
  "success": true,
  "patient_id": "PAT_72D90B86",
  "patient_name": "Test Patient",
  "timeline": [
    {
      "type": "note",
      "date": "2025-11-08T15:30:39.547501",
      "timestamp": "2025-11-08T15:30:39.547501",
      "entry": {
        "note_id": "NOTE_410F1325",
        "audio_file": "PAT_72D90B86_audio_06195061.m4a",
        "soap_note": {
          "subjective": "Patient reports fever for four days...",
          "objective": "No objective findings recorded...",
          "assessment": "Fever of unknown origin (4 days duration).",
          "plan": "Further evaluation needed...",
          "chief_complaint": "Fever for four days.",
          "medications": []
        },
        "chief_complaint": "Fever for four days.",
        "assessment": "Fever of unknown origin (4 days duration).",
        "plan": "Further evaluation needed..."
      }
    },
    {
      "type": "prescription",
      "date": "2025-11-08T13:11:41.233184",
      "timestamp": "2025-11-08T13:11:41.233184",
      "entry": {
        "history_id": "TIMELINE_8F4524E3",
        "image_file": "PAT_72D90B86_doc_1234.jpg",
        "doctor_name": "Dr. Sharma",
        "hospital": "City Hospital",
        "diagnosis": "Hypertension",
        "medications": [
          {
            "name": "Amlodipine",
            "dosage": "5mg",
            "frequency": "Once daily"
          }
        ],
        "medication_count": 1
      }
    }
  ],
  "statistics": {
    "total_entries": 4,
    "notes_count": 3,
    "prescriptions_count": 1,
    "date_range": {
      "first_entry": "2025-11-08T13:11:41.233184",
      "latest_entry": "2025-11-08T15:30:39.547501"
    }
  }
}
```

**Use for:** 
- Complete patient history view
- Chronological medical journey
- Doctor's main patient consultation screen
- Single API call for all patient medical data

---

## Prescription History

### 13. Get All Prescription History
**Endpoint:** `GET /history/{patient_id}`

**Response:**
```json
{
  "success": true,
  "patient_id": "PAT_A6C5DC51",
  "patient_name": "Ram Kumar",
  "count": 3,
  "history": [
    {
      "history_id": "HIST_56EF78GH",
      "patient_id": "PAT_A6C5DC51",
      "created_at": "2025-11-08T11:00:00",
      "image_file": "PAT_A6C5DC51_doc_5678.jpg",
      "prescription_data": {
        "doctor_name": "Dr. Sharma",
        "hospital": "City Hospital",
        "date": "2025-11-08",
        "diagnosis": "Hypertension",
        "medications": [
          {
            "name": "Amlodipine",
            "dosage": "5mg",
            "frequency": "Once daily",
            "duration": "30 days"
          }
        ]
      }
    }
  ]
}
```

**Use for:** Prescription history view

---

### 14. Get All Medications Timeline
**Endpoint:** `GET /history/{patient_id}/medications`

**Response:**
```json
{
  "success": true,
  "patient_id": "PAT_A6C5DC51",
  "patient_name": "Ram Kumar",
  "total_medications": 8,
  "medications": [
    {
      "medication": {
        "name": "Amlodipine",
        "dosage": "5mg",
        "frequency": "Once daily"
      },
      "prescription_date": "2025-11-08T11:00:00",
      "doctor": "Dr. Sharma",
      "diagnosis": "Hypertension"
    },
    {
      "medication": {
        "name": "Paracetamol",
        "dosage": "500mg",
        "frequency": "TDS"
      },
      "prescription_date": "2025-11-05T10:00:00",
      "doctor": "Dr. Gupta",
      "diagnosis": "Fever"
    }
  ]
}
```

**Use for:** Comprehensive medication history, drug interaction checking

---

## System Statistics

### 15. Dashboard Statistics
**Endpoint:** `GET /stats`

**Response:**
```json
{
  "patients": {
    "total": 150,
    "active": 145,
    "by_gender": {
      "male": 75,
      "female": 70,
      "other": 5
    }
  },
  "queue": {
    "current_size": 6,
    "waiting": 5,
    "in_progress": 1,
    "completed": 12
  },
  "notes": {
    "total": 450,
    "patients_with_notes": 120
  },
  "history": {
    "total_prescriptions": 280,
    "patients_with_history": 95
  }
}
```

**Use for:** Admin dashboard, overview statistics

---

## Recommended Short Polling Strategy

### Queue Updates (Every 5 seconds)
```javascript
setInterval(() => {
  fetch('http://192.168.0.7:8000/queue')
    .then(res => res.json())
    .then(data => updateQueueDisplay(data.queue))
}, 5000)
```

### Current Patient Updates (Every 10 seconds)
```javascript
setInterval(() => {
  fetch('http://192.168.0.7:8000/queue/current')
    .then(res => res.json())
    .then(data => updateCurrentPatient(data.patient))
}, 10000)
```

### Latest Notes for Active Patient (Every 15 seconds)
```javascript
const patientId = getCurrentPatientId()
setInterval(() => {
  fetch(`http://192.168.0.7:8000/notes/${patientId}/latest`)
    .then(res => res.json())
    .then(data => updateLatestNote(data.note))
}, 15000)
```

---

## Error Responses

All errors follow this format:
```json
{
  "detail": "Error message or detailed error object"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `400` - Bad Request (invalid data)
- `404` - Not Found (patient/queue entry doesn't exist)
- `409` - Conflict (duplicate UHID, patient already in queue)
- `500` - Server Error

---

## CORS Configuration

CORS is enabled for all origins. In production, specify allowed origins.

---

## Notes

1. All timestamps are in ISO 8601 format: `2025-11-08T14:20:00`
2. Patient IDs format: `PAT_XXXXXXXX`
3. Queue IDs format: `Q_XXXXXXXX`
4. Note IDs format: `NOTE_XXXXXXXX`
5. History IDs format: `HIST_XXXXXXXX`
6. UHID is the government-issued Unified Health ID (primary identifier)
7. Audio files are stored as `.m4a` format
8. Image files are stored as `.jpg` format

---

## Testing with cURL

```bash
# Get all patients
curl http://192.168.0.7:8000/patients

# Get queue status
curl http://192.168.0.7:8000/queue

# Add patient to queue (MUST USE -X POST)
curl -X POST http://192.168.0.7:8000/queue \
  -H "Content-Type: application/json" \
  -d '{"patient_id":"PAT_A6C5DC51","priority":"normal"}'

# Get patient details
curl http://192.168.0.7:8000/patients/PAT_A6C5DC51

# Get patient medical timeline (RECOMMENDED)
curl http://192.168.0.7:8000/timeline/PAT_A6C5DC51

# Get latest note
curl http://192.168.0.7:8000/notes/PAT_A6C5DC51/latest

# Start consultation (MUST USE -X POST and valid queue_id)
curl -X POST http://192.168.0.7:8000/queue/Q_9A8B7C6D/start

# Complete consultation (MUST USE -X POST)
curl -X POST http://192.168.0.7:8000/queue/Q_9A8B7C6D/complete

# Get system stats
curl http://192.168.0.7:8000/stats
```

---

## Complete Workflow Example

1. **Check current queue:**
```bash
curl http://192.168.0.7:8000/queue
```

2. **Add patient to queue:**
```bash
curl -X POST http://192.168.0.7:8000/queue \
  -H "Content-Type: application/json" \
  -d '{"patient_id":"PAT_72D90B86","priority":"normal"}'
# Returns: {"queue_id":"Q_57A417A0",...}
```

3. **Start consultation (use queue_id from step 2):**
```bash
curl -X POST http://192.168.0.7:8000/queue/Q_57A417A0/start
```

4. **Get patient timeline:**
```bash
curl http://192.168.0.7:8000/timeline/PAT_72D90B86
```

5. **Complete consultation:**
```bash
curl -X POST http://192.168.0.7:8000/queue/Q_57A417A0/complete
```

---

## Interactive API Documentation

Full interactive API documentation available at:
`http://192.168.0.7:8000/docs`

This provides:
- All endpoint details
- Request/response schemas
- Try-it-out functionality
- Schema validation rules
