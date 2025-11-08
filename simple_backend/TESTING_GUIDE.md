# API Testing Guide

Quick reference for testing all endpoints of the PHC AI Co-Pilot Backend.

## Prerequisites

```bash
# Start the server
cd simple_backend
python main.py

# Or with Docker
docker-compose up -d
```

Base URL: `http://localhost:8000`

## Health & Info Endpoints

### 1. Get API Info
```bash
curl http://localhost:8000/
```

**Response:**
```json
{
  "service": "PHC AI Co-Pilot",
  "version": "2.0.0",
  "status": "running",
  "features": [...],
  "stats": {
    "total_patients": 0,
    "queue": {...},
    "total_notes": 0
  }
}
```

### 2. Health Check
```bash
curl http://localhost:8000/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00",
  "services": {
    "groq_whisper": "configured",
    "gemini_vision": "configured"
  }
}
```

## Patient Management Endpoints

### 3. Register New Patient
```bash
curl -X POST http://localhost:8000/patients \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "phone": "9876543210",
    "age": 45,
    "gender": "Male"
  }'
```

**Response:**
```json
{
  "success": true,
  "patient_id": "PAT_A1B2C3D4",
  "message": "Patient John Doe registered"
}
```

**💡 Save the `patient_id` for next steps!**

### 4. List All Patients
```bash
curl http://localhost:8000/patients
```

**Response:**
```json
{
  "success": true,
  "count": 1,
  "patients": [
    {
      "patient_id": "PAT_A1B2C3D4",
      "name": "John Doe",
      "phone": "9876543210",
      "age": 45,
      "gender": "Male",
      "created_at": "2024-01-01T00:00:00",
      "status": "active"
    }
  ]
}
```

### 5. Get Patient Details
```bash
# Replace PAT_A1B2C3D4 with actual patient_id
curl http://localhost:8000/patients/PAT_A1B2C3D4
```

**Response:**
```json
{
  "success": true,
  "patient": {...},
  "notes_count": 0,
  "latest_visit": null
}
```

## Queue Management Endpoints

### 6. Add Patient to Queue
```bash
curl -X POST http://localhost:8000/queue/add \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "PAT_A1B2C3D4",
    "priority": "normal"
  }'
```

**Response:**
```json
{
  "success": true,
  "queue_entry": {
    "queue_id": "Q_ABC123",
    "patient_id": "PAT_A1B2C3D4",
    "patient_name": "John Doe",
    "priority": "normal",
    "status": "waiting",
    "added_at": "2024-01-01T00:00:00",
    "position": 1
  },
  "message": "Added to queue"
}
```

**💡 Save the `queue_id` for next steps!**

### 7. Get Queue Status
```bash
curl http://localhost:8000/queue
```

**Response:**
```json
{
  "success": true,
  "queue": {
    "waiting": [...],
    "in_progress": [...],
    "completed": [...]
  },
  "stats": {
    "waiting_count": 1,
    "estimated_wait_time": "10 min"
  }
}
```

### 8. Start Consultation
```bash
# Replace Q_ABC123 with actual queue_id
curl -X POST http://localhost:8000/queue/Q_ABC123/start
```

**Response:**
```json
{
  "success": true,
  "message": "Consultation started",
  "patient_id": "PAT_A1B2C3D4"
}
```

### 9. Complete Consultation
```bash
# Replace Q_ABC123 with actual queue_id
curl -X POST http://localhost:8000/queue/Q_ABC123/complete
```

**Response:**
```json
{
  "success": true,
  "message": "Consultation completed"
}
```

## Upload & AI Processing Endpoints

### 10. Upload Audio (with Groq Whisper Transcription)
```bash
# Replace PAT_A1B2C3D4 with actual patient_id
curl -X POST http://localhost:8000/upload/audio/PAT_A1B2C3D4 \
  -F "file=@/path/to/audio.mp3"
```

**Response:**
```json
{
  "success": true,
  "message": "Audio processed successfully",
  "patient_id": "PAT_A1B2C3D4",
  "transcript": "Patient complains of fever and headache...",
  "soap_note": {
    "subjective": "Patient complains of...",
    "objective": "Temperature: 101°F...",
    "assessment": "Viral fever",
    "plan": "Rest and fluids...",
    "chief_complaint": "Fever",
    "medications": ["Paracetamol 500mg"],
    "language": "hindi"
  }
}
```

### 11. Upload Prescription Image (with Gemini Vision OCR)
```bash
# Replace PAT_A1B2C3D4 with actual patient_id
curl -X POST http://localhost:8000/upload/image/PAT_A1B2C3D4 \
  -F "file=@/path/to/prescription.jpg"
```

**Response:**
```json
{
  "success": true,
  "message": "Prescription extracted successfully",
  "patient_id": "PAT_A1B2C3D4",
  "prescription": {
    "doctor_name": "Dr. Smith",
    "date": "2024-01-01",
    "medications": [
      {
        "name": "Amoxicillin",
        "dosage": "500mg",
        "frequency": "TDS",
        "duration": "5 days"
      }
    ],
    "diagnosis": "Bacterial infection",
    "instructions": "Take after meals"
  }
}
```

### 12. Get Patient Notes
```bash
# Replace PAT_A1B2C3D4 with actual patient_id
curl http://localhost:8000/notes/PAT_A1B2C3D4
```

**Response:**
```json
{
  "success": true,
  "patient_id": "PAT_A1B2C3D4",
  "patient_name": "John Doe",
  "count": 2,
  "notes": [
    {
      "note_id": "NOTE_1234567890",
      "patient_id": "PAT_A1B2C3D4",
      "timestamp": 1234567890,
      "created_at": "2024-01-01T00:00:00",
      "type": "audio_consultation",
      "soap_note": {...},
      "transcript": "...",
      "audio_file": "/app/data/uploads/..."
    },
    {
      "note_id": "NOTE_1234567891",
      "type": "prescription",
      "prescription": {...},
      "image_file": "/app/data/uploads/..."
    }
  ]
}
```

## Complete Workflow Test

Here's a complete workflow to test all endpoints:

```bash
# 1. Check health
curl http://localhost:8000/health

# 2. Register patient
RESPONSE=$(curl -s -X POST http://localhost:8000/patients \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","phone":"9876543210"}')

# Extract patient_id (using jq)
PATIENT_ID=$(echo $RESPONSE | jq -r '.patient_id')
echo "Patient ID: $PATIENT_ID"

# 3. Add to queue
QUEUE_RESPONSE=$(curl -s -X POST http://localhost:8000/queue/add \
  -H "Content-Type: application/json" \
  -d "{\"patient_id\":\"$PATIENT_ID\"}")

QUEUE_ID=$(echo $QUEUE_RESPONSE | jq -r '.queue_entry.queue_id')
echo "Queue ID: $QUEUE_ID"

# 4. Check queue
curl http://localhost:8000/queue

# 5. Start consultation
curl -X POST http://localhost:8000/queue/$QUEUE_ID/start

# 6. Upload audio (requires actual audio file)
# curl -X POST http://localhost:8000/upload/audio/$PATIENT_ID \
#   -F "file=@audio.mp3"

# 7. Get patient notes
curl http://localhost:8000/notes/$PATIENT_ID

# 8. Complete consultation
curl -X POST http://localhost:8000/queue/$QUEUE_ID/complete

# 9. Get patient details
curl http://localhost:8000/patients/$PATIENT_ID
```

## Testing with Python

```python
import requests

BASE_URL = "http://localhost:8000"

# Register patient
response = requests.post(f"{BASE_URL}/patients", json={
    "name": "Test Patient",
    "phone": "9876543210",
    "age": 30
})
patient_id = response.json()["patient_id"]
print(f"Patient registered: {patient_id}")

# Add to queue
response = requests.post(f"{BASE_URL}/queue/add", json={
    "patient_id": patient_id
})
queue_id = response.json()["queue_entry"]["queue_id"]
print(f"Added to queue: {queue_id}")

# Start consultation
requests.post(f"{BASE_URL}/queue/{queue_id}/start")
print("Consultation started")

# Upload audio
with open("audio.mp3", "rb") as f:
    files = {"file": f}
    response = requests.post(f"{BASE_URL}/upload/audio/{patient_id}", files=files)
    print("Audio processed:", response.json()["soap_note"])

# Complete
requests.post(f"{BASE_URL}/queue/{queue_id}/complete")
print("Consultation completed")
```

## Error Responses

### 404 - Not Found
```json
{
  "detail": "Patient not found"
}
```

### 400 - Bad Request
```json
{
  "detail": "Patient already in queue"
}
```

### 422 - Validation Error
```json
{
  "detail": [
    {
      "loc": ["body", "name"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

## Interactive API Documentation

FastAPI provides automatic interactive API documentation:

- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

You can test all endpoints directly from the browser!

## Notes

- All file uploads should use `multipart/form-data`
- Audio files: `.mp3`, `.wav`, `.m4a`, `.ogg`
- Image files: `.jpg`, `.jpeg`, `.png`
- Patient IDs start with `PAT_`
- Queue IDs start with `Q_`
- Note IDs start with `NOTE_`
- Requires valid `GEMINI_API_KEY` and `GROQ_API_KEY` in `.env` file for AI features
