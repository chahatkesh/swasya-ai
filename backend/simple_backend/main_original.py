# PHC AI Co-Pilot Backend - Production Ready
# Features: Queue Management, Groq Whisper, Gemini Vision, Real-time Updates

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from enum import Enum
import uuid
import json
import os
from datetime import datetime
from typing import Optional, List
from dotenv import load_dotenv
import google.generativeai as genai
from groq import Groq
from PIL import Image
import io

# Load environment variables
load_dotenv()

# Initialize FastAPI
app = FastAPI(
    title="PHC AI Co-Pilot Backend",
    description="Complete backend with queue management, Whisper transcription, and Gemini Vision OCR",
    version="2.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure APIs
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')
GROQ_API_KEY = os.environ.get('GROQ_API_KEY')

if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found")
if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY not found")

genai.configure(api_key=GEMINI_API_KEY)
gemini_model = genai.GenerativeModel('gemini-2.0-flash-exp')
groq_client = Groq(api_key=GROQ_API_KEY)

# Storage paths
BASE_DIR = "/app/data"
PATIENTS_FILE = f"{BASE_DIR}/patients.json"
QUEUE_FILE = f"{BASE_DIR}/queue.json"
NOTES_FILE = f"{BASE_DIR}/notes.json"
HISTORY_FILE = f"{BASE_DIR}/history.json"
UPLOADS_DIR = f"{BASE_DIR}/uploads"

# Create directories
os.makedirs(BASE_DIR, exist_ok=True)
os.makedirs(UPLOADS_DIR, exist_ok=True)

# Initialize storage
for file_path in [PATIENTS_FILE, QUEUE_FILE, NOTES_FILE, HISTORY_FILE]:
    if not os.path.exists(file_path):
        with open(file_path, 'w') as f:
            json.dump({} if file_path != QUEUE_FILE else [], f)


# ==================== MODELS ====================

class QueueStatus(str, Enum):
    WAITING = "waiting"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class PatientCreate(BaseModel):
    name: str
    phone: str
    age: Optional[int] = None
    gender: Optional[str] = None


class QueueEntry(BaseModel):
    patient_id: str
    priority: Optional[str] = "normal"  # normal, urgent


# ==================== STORAGE HELPERS ====================

def load_json(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)

def save_json(file_path, data):
    with open(file_path, 'w') as f:
        json.dump(data, f, indent=2)


# ==================== AI HELPERS ====================

async def transcribe_audio(file_path: str) -> str:
    """Use Groq Whisper to transcribe audio"""
    try:
        print(f"🎙️ Transcribing with Groq Whisper...")
        
        with open(file_path, "rb") as audio_file:
            transcription = groq_client.audio.transcriptions.create(
                file=audio_file,
                model="whisper-large-v3-turbo",
                response_format="json",
                language="hi"  # Hindi
            )
        
        transcript = transcription.text
        print(f"✅ Transcribed: {len(transcript)} chars")
        return transcript
    
    except Exception as e:
        print(f"❌ Transcription error: {e}")
        return f"[Transcription failed: {str(e)}]"


async def generate_soap_note(transcript: str) -> dict:
    """Use Gemini to convert transcript to SOAP note"""
    
    prompt = f"""You are a medical scribe at a Primary Healthcare Center in India.

Convert this conversation into a structured SOAP note in JSON format.

CONVERSATION:
{transcript}

Return ONLY valid JSON (no markdown):
{{
    "subjective": "Patient's main complaints",
    "objective": "Vitals and observations",
    "assessment": "Diagnosis",
    "plan": "Treatment plan",
    "chief_complaint": "Main issue",
    "medications": ["List medications if mentioned"],
    "language": "hindi/english"
}}
"""
    
    try:
        response = gemini_model.generate_content(prompt)
        text = response.text.strip()
        
        if text.startswith('```'):
            text = text.split('```')[1]
            if text.startswith('json'):
                text = text[4:]
            text = text.strip()
        
        return json.loads(text)
    except Exception as e:
        return {
            "subjective": transcript[:200],
            "objective": "Pending",
            "assessment": "Requires review",
            "plan": "TBD",
            "chief_complaint": "See transcript",
            "medications": [],
            "language": "unknown",
            "error": str(e)
        }


async def extract_prescription(image_path: str) -> dict:
    """Use Gemini Vision to extract prescription details"""
    
    try:
        print(f"📸 Extracting prescription with Gemini Vision...")
        
        # Upload image to Gemini
        image_file = genai.upload_file(image_path)
        
        prompt = """Extract all information from this medical prescription image.

Return ONLY valid JSON (no markdown):
{
    "doctor_name": "Doctor's name",
    "date": "Date if visible",
    "medications": [
        {
            "name": "Medicine name",
            "dosage": "500mg",
            "frequency": "TDS/BD/OD",
            "duration": "3 days"
        }
    ],
    "diagnosis": "Condition if mentioned",
    "instructions": "Special instructions"
}
"""
        
        response = gemini_model.generate_content([prompt, image_file])
        text = response.text.strip()
        
        if text.startswith('```'):
            text = text.split('```')[1]
            if text.startswith('json'):
                text = text[4:]
            text = text.strip()
        
        return json.loads(text)
    
    except Exception as e:
        return {
            "doctor_name": "Unknown",
            "date": "Unknown",
            "medications": [],
            "diagnosis": "Could not extract",
            "instructions": "",
            "error": str(e)
        }


# ==================== ROUTES ====================

@app.get("/")
def root():
    """API Info with real-time stats"""
    patients = load_json(PATIENTS_FILE)
    queue = load_json(QUEUE_FILE)
    notes = load_json(NOTES_FILE)
    
    queue_stats = {
        "waiting": len([q for q in queue if q['status'] == 'waiting']),
        "in_progress": len([q for q in queue if q['status'] == 'in_progress']),
        "completed_today": len([q for q in queue if q['status'] == 'completed'])
    }
    
    return {
        "service": "PHC AI Co-Pilot",
        "version": "2.0.0",
        "status": "running",
        "features": [
            "Queue Management",
            "Groq Whisper Transcription",
            "Gemini Vision OCR",
            "Real-time SOAP Notes"
        ],
        "stats": {
            "total_patients": len(patients),
            "queue": queue_stats,
            "total_notes": sum(len(v) for v in notes.values())
        }
    }


@app.post("/patients")
def register_patient(patient: PatientCreate):
    """Register new patient"""
    
    patient_id = f"PAT_{uuid.uuid4().hex[:8].upper()}"
    
    patients = load_json(PATIENTS_FILE)
    patients[patient_id] = {
        "patient_id": patient_id,
        "name": patient.name,
        "phone": patient.phone,
        "age": patient.age,
        "gender": patient.gender,
        "created_at": datetime.now().isoformat(),
        "status": "active"
    }
    save_json(PATIENTS_FILE, patients)
    
    print(f"✅ Registered: {patient_id} - {patient.name}")
    
    return {
        "success": True,
        "patient_id": patient_id,
        "message": f"Patient {patient.name} registered"
    }


@app.get("/patients")
def list_patients():
    """List all patients"""
    patients = load_json(PATIENTS_FILE)
    return {
        "success": True,
        "count": len(patients),
        "patients": list(patients.values())
    }


@app.get("/patients/{patient_id}")
def get_patient(patient_id: str):
    """Get patient details with history"""
    patients = load_json(PATIENTS_FILE)
    notes = load_json(NOTES_FILE)
    
    if patient_id not in patients:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    patient_notes = notes.get(patient_id, [])
    
    return {
        "success": True,
        "patient": patients[patient_id],
        "notes_count": len(patient_notes),
        "latest_visit": patient_notes[-1] if patient_notes else None
    }


# ==================== QUEUE MANAGEMENT ====================

@app.post("/queue/add")
def add_to_queue(entry: QueueEntry):
    """Add patient to queue"""
    
    patients = load_json(PATIENTS_FILE)
    if entry.patient_id not in patients:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    queue = load_json(QUEUE_FILE)
    
    # Check if already in queue
    if any(q['patient_id'] == entry.patient_id and q['status'] in ['waiting', 'in_progress'] for q in queue):
        raise HTTPException(status_code=400, detail="Patient already in queue")
    
    queue_entry = {
        "queue_id": f"Q_{uuid.uuid4().hex[:6].upper()}",
        "patient_id": entry.patient_id,
        "patient_name": patients[entry.patient_id]['name'],
        "priority": entry.priority,
        "status": QueueStatus.WAITING,
        "added_at": datetime.now().isoformat(),
        "position": len([q for q in queue if q['status'] == 'waiting']) + 1
    }
    
    queue.append(queue_entry)
    save_json(QUEUE_FILE, queue)
    
    print(f"📋 Added to queue: {entry.patient_id}")
    
    return {
        "success": True,
        "queue_entry": queue_entry,
        "message": "Added to queue"
    }


@app.get("/queue")
def get_queue():
    """Get current queue status"""
    queue = load_json(QUEUE_FILE)
    
    # Update positions
    waiting = [q for q in queue if q['status'] == 'waiting']
    for i, q in enumerate(waiting, 1):
        q['position'] = i
    
    return {
        "success": True,
        "queue": {
            "waiting": waiting,
            "in_progress": [q for q in queue if q['status'] == 'in_progress'],
            "completed": [q for q in queue if q['status'] == 'completed'][-10:]  # Last 10
        },
        "stats": {
            "waiting_count": len(waiting),
            "estimated_wait_time": f"{len(waiting) * 10} min"  # Assuming 10 min per patient
        }
    }


@app.post("/queue/{queue_id}/start")
def start_consultation(queue_id: str):
    """Start consultation (move to in_progress)"""
    queue = load_json(QUEUE_FILE)
    
    entry = next((q for q in queue if q['queue_id'] == queue_id), None)
    if not entry:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    entry['status'] = QueueStatus.IN_PROGRESS
    entry['started_at'] = datetime.now().isoformat()
    
    save_json(QUEUE_FILE, queue)
    
    print(f"🩺 Started consultation: {queue_id}")
    
    return {
        "success": True,
        "message": "Consultation started",
        "patient_id": entry['patient_id']
    }


@app.post("/queue/{queue_id}/complete")
def complete_consultation(queue_id: str):
    """Complete consultation"""
    queue = load_json(QUEUE_FILE)
    
    entry = next((q for q in queue if q['queue_id'] == queue_id), None)
    if not entry:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    entry['status'] = QueueStatus.COMPLETED
    entry['completed_at'] = datetime.now().isoformat()
    
    save_json(QUEUE_FILE, queue)
    
    print(f"✅ Completed consultation: {queue_id}")
    
    return {
        "success": True,
        "message": "Consultation completed"
    }


# ==================== AUDIO UPLOAD WITH WHISPER ====================

@app.post("/upload/audio/{patient_id}")
async def upload_audio(patient_id: str, file: UploadFile = File(...)):
    """Upload audio, transcribe with Whisper, generate SOAP note"""
    
    patients = load_json(PATIENTS_FILE)
    if patient_id not in patients:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    print(f"\n📤 Audio upload: {patient_id} - {file.filename}")
    
    # Save audio file
    timestamp = int(datetime.now().timestamp())
    file_ext = file.filename.split('.')[-1]
    file_path = f"{UPLOADS_DIR}/{patient_id}_audio_{timestamp}.{file_ext}"
    
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)
    
    print(f"💾 Saved: {len(content)} bytes")
    
    # Transcribe with Groq Whisper
    transcript = await transcribe_audio(file_path)
    
    # Generate SOAP note with Gemini
    print(f"🤖 Generating SOAP note...")
    soap_note = await generate_soap_note(transcript)
    
    # Save note
    notes = load_json(NOTES_FILE)
    if patient_id not in notes:
        notes[patient_id] = []
    
    note = {
        "note_id": f"NOTE_{timestamp}",
        "patient_id": patient_id,
        "timestamp": timestamp,
        "created_at": datetime.now().isoformat(),
        "type": "audio_consultation",
        "soap_note": soap_note,
        "transcript": transcript,
        "audio_file": file_path
    }
    
    notes[patient_id].append(note)
    save_json(NOTES_FILE, notes)
    
    print(f"✅ SOAP note saved\n")
    
    return {
        "success": True,
        "message": "Audio processed successfully",
        "patient_id": patient_id,
        "transcript": transcript,
        "soap_note": soap_note
    }


# ==================== IMAGE UPLOAD WITH GEMINI VISION ====================

@app.post("/upload/image/{patient_id}")
async def upload_image(patient_id: str, file: UploadFile = File(...)):
    """Upload prescription image, extract with Gemini Vision"""
    
    patients = load_json(PATIENTS_FILE)
    if patient_id not in patients:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    print(f"\n📤 Image upload: {patient_id} - {file.filename}")
    
    # Save image file
    timestamp = int(datetime.now().timestamp())
    file_ext = file.filename.split('.')[-1]
    file_path = f"{UPLOADS_DIR}/{patient_id}_image_{timestamp}.{file_ext}"
    
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)
    
    print(f"💾 Saved: {len(content)} bytes")
    
    # Extract with Gemini Vision
    prescription_data = await extract_prescription(file_path)
    
    # Save note
    notes = load_json(NOTES_FILE)
    if patient_id not in notes:
        notes[patient_id] = []
    
    note = {
        "note_id": f"NOTE_{timestamp}",
        "patient_id": patient_id,
        "timestamp": timestamp,
        "created_at": datetime.now().isoformat(),
        "type": "prescription",
        "prescription": prescription_data,
        "image_file": file_path
    }
    
    notes[patient_id].append(note)
    save_json(NOTES_FILE, notes)
    
    print(f"✅ Prescription extracted\n")
    
    return {
        "success": True,
        "message": "Prescription extracted successfully",
        "patient_id": patient_id,
        "prescription": prescription_data
    }


@app.get("/notes/{patient_id}")
def get_patient_notes(patient_id: str):
    """Get all notes for a patient"""
    
    patients = load_json(PATIENTS_FILE)
    if patient_id not in patients:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    notes = load_json(NOTES_FILE)
    patient_notes = notes.get(patient_id, [])
    
    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": patients[patient_id]['name'],
        "count": len(patient_notes),
        "notes": patient_notes
    }


@app.get("/health")
def health_check():
    """Health check"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "services": {
            "groq_whisper": "configured",
            "gemini_vision": "configured"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
