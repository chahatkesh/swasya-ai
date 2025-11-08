"""Upload routes for audio and image processing"""

from fastapi import APIRouter, File, UploadFile, HTTPException
from datetime import datetime
import os
import re
from pathlib import Path
from utils.storage import load_json, save_json
from utils.ai_services import transcribe_audio, generate_soap_note, extract_prescription
from config import PATIENTS_FILE, NOTES_FILE, UPLOADS_DIR

router = APIRouter(prefix="/upload", tags=["uploads"])


@router.post("/audio/{patient_id}")
async def upload_audio(patient_id: str, file: UploadFile = File(...)):
    """Upload audio, transcribe with Whisper, generate SOAP note"""
    
    patients = load_json(PATIENTS_FILE)
    if patient_id not in patients:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    print(f"\n📤 Audio upload received")
    
    # Save audio file
    timestamp = int(datetime.now().timestamp())
    # Sanitize file extension to prevent path traversal
    file_ext = file.filename.split('.')[-1].lower()
    allowed_extensions = ['mp3', 'wav', 'm4a', 'ogg', 'webm']
    if file_ext not in allowed_extensions:
        raise HTTPException(status_code=400, detail="Invalid file format")
    
    # Sanitize patient_id to prevent path injection
    if not re.match(r'^PAT_[A-Z0-9]+$', patient_id):
        raise HTTPException(status_code=400, detail="Invalid patient ID format")
    
    # Construct safe file path
    safe_filename = f"{patient_id}_audio_{timestamp}.{file_ext}"
    file_path = os.path.join(UPLOADS_DIR, safe_filename)
    
    # Verify the path is within UPLOADS_DIR (prevent directory traversal)
    if not Path(file_path).resolve().is_relative_to(Path(UPLOADS_DIR).resolve()):
        raise HTTPException(status_code=400, detail="Invalid file path")
    
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
    
    # Remove error field from response if present (don't expose to user)
    response_soap = {k: v for k, v in soap_note.items() if k != 'error'}
    
    return {
        "success": True,
        "message": "Audio processed successfully",
        "patient_id": patient_id,
        "transcript": transcript,
        "soap_note": response_soap
    }


@router.post("/image/{patient_id}")
async def upload_image(patient_id: str, file: UploadFile = File(...)):
    """Upload prescription image, extract with Gemini Vision"""
    
    patients = load_json(PATIENTS_FILE)
    if patient_id not in patients:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    print(f"\n📤 Image upload received")
    
    # Save image file
    timestamp = int(datetime.now().timestamp())
    # Sanitize file extension to prevent path traversal
    file_ext = file.filename.split('.')[-1].lower()
    allowed_extensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
    if file_ext not in allowed_extensions:
        raise HTTPException(status_code=400, detail="Invalid file format")
    
    # Sanitize patient_id to prevent path injection
    if not re.match(r'^PAT_[A-Z0-9]+$', patient_id):
        raise HTTPException(status_code=400, detail="Invalid patient ID format")
    
    # Construct safe file path
    safe_filename = f"{patient_id}_image_{timestamp}.{file_ext}"
    file_path = os.path.join(UPLOADS_DIR, safe_filename)
    
    # Verify the path is within UPLOADS_DIR (prevent directory traversal)
    if not Path(file_path).resolve().is_relative_to(Path(UPLOADS_DIR).resolve()):
        raise HTTPException(status_code=400, detail="Invalid file path")
    
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
    
    # Remove error field from response if present (don't expose to user)
    response_prescription = {k: v for k, v in prescription_data.items() if k != 'error'}
    
    return {
        "success": True,
        "message": "Prescription extracted successfully",
        "patient_id": patient_id,
        "prescription": response_prescription
    }


@router.get("/notes/{patient_id}")
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
