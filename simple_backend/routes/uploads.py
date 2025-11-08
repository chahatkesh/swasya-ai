"""Upload routes for audio and image processing"""

from fastapi import APIRouter, File, UploadFile, HTTPException
from datetime import datetime
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


@router.post("/image/{patient_id}")
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
