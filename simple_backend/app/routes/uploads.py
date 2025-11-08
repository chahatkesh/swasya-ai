"""
Upload and processing routes (Audio and Images)
"""

from fastapi import APIRouter, File, UploadFile, HTTPException, BackgroundTasks
from app.services.storage_service import storage
from app.services.ai_service import transcribe_audio, generate_soap_note, extract_prescription
import uuid
import os
from datetime import datetime
from typing import Optional

router = APIRouter(prefix="/upload", tags=["Uploads & Processing"])

UPLOADS_DIR = "/app/data/uploads"
os.makedirs(UPLOADS_DIR, exist_ok=True)


@router.post("/audio/{patient_id}", response_model=dict)
async def upload_audio(patient_id: str, file: UploadFile = File(...)):
    """
    Upload audio recording and generate SOAP note
    
    **Process:**
    1. Save audio file
    2. Transcribe using Groq Whisper
    3. Generate structured SOAP note using Gemini
    4. Save to patient's notes
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    
    **File Upload:**
    - Supported formats: mp3, m4a, wav, ogg
    - Max size: 25MB
    
    **Returns:**
    - note_id: Unique identifier for this note
    - transcript: Full transcribed text
    - soap_note: Structured medical note
    """
    
    # Verify patient exists
    patient = storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Validate file type
    allowed_types = ['audio/mpeg', 'audio/mp4', 'audio/wav', 'audio/ogg', 'audio/x-m4a']
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid file type. Allowed: mp3, m4a, wav, ogg"
        )
    
    try:
        # Save audio file
        file_extension = file.filename.split('.')[-1]
        audio_filename = f"{patient_id}_audio_{uuid.uuid4().hex[:8]}.{file_extension}"
        audio_path = os.path.join(UPLOADS_DIR, audio_filename)
        
        with open(audio_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        print(f"📁 Saved audio: {audio_filename}")
        
        # Step 1: Transcribe audio
        transcript = await transcribe_audio(audio_path)
        
        if transcript.startswith("[Transcription failed"):
            raise HTTPException(status_code=500, detail="Transcription failed")
        
        # Step 2: Generate SOAP note
        soap_note = await generate_soap_note(transcript)
        
        # Step 3: Save to notes
        note_id = f"NOTE_{uuid.uuid4().hex[:8].upper()}"
        note_data = {
            "note_id": note_id,
            "patient_id": patient_id,
            "created_at": datetime.now().isoformat(),
            "audio_file": audio_filename,
            "transcript": transcript,
            "soap_note": soap_note
        }
        
        storage.add_note(patient_id, note_data)
        
        print(f"✅ SOAP note created: {note_id}")
        
        return {
            "success": True,
            "message": "Audio processed successfully",
            "note_id": note_id,
            "transcript": transcript,
            "soap_note": soap_note,
            "audio_file": audio_filename
        }
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error processing audio: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to process audio: {str(e)}")


@router.post("/image/{patient_id}", response_model=dict)
async def upload_prescription_image(patient_id: str, file: UploadFile = File(...)):
    """
    Upload prescription image and extract details
    
    **Process:**
    1. Save image file
    2. Extract text using Gemini Vision OCR
    3. Structure into medication timeline
    4. Save to patient's history
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    
    **File Upload:**
    - Supported formats: jpg, jpeg, png
    - Max size: 10MB
    
    **Returns:**
    - history_id: Unique identifier for this prescription
    - prescription_data: Extracted medications and details
    """
    
    # Verify patient exists
    patient = storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Validate file type
    allowed_types = ['image/jpeg', 'image/png', 'image/jpg']
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: jpg, jpeg, png"
        )
    
    try:
        # Save image file
        file_extension = file.filename.split('.')[-1]
        image_filename = f"{patient_id}_prescription_{uuid.uuid4().hex[:8]}.{file_extension}"
        image_path = os.path.join(UPLOADS_DIR, image_filename)
        
        with open(image_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        print(f"📁 Saved image: {image_filename}")
        
        # Extract prescription details
        prescription_data = await extract_prescription(image_path)
        
        # Save to history
        history_id = f"HIST_{uuid.uuid4().hex[:8].upper()}"
        history_entry = {
            "history_id": history_id,
            "patient_id": patient_id,
            "created_at": datetime.now().isoformat(),
            "image_file": image_filename,
            "prescription_data": prescription_data,
            "type": "prescription"
        }
        
        storage.add_history(patient_id, history_entry)
        
        print(f"✅ Prescription extracted: {history_id}")
        
        return {
            "success": True,
            "message": "Prescription processed successfully",
            "history_id": history_id,
            "prescription_data": prescription_data,
            "image_file": image_filename
        }
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error processing image: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to process image: {str(e)}")


@router.post("/test-audio", response_model=dict)
async def test_audio_transcription(file: UploadFile = File(...)):
    """
    Test audio transcription without saving to patient record
    
    Useful for testing Groq Whisper integration
    """
    
    try:
        # Save temp file
        temp_path = f"/tmp/test_audio_{uuid.uuid4().hex[:8]}.mp3"
        with open(temp_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        # Transcribe
        transcript = await transcribe_audio(temp_path)
        
        # Clean up
        os.remove(temp_path)
        
        return {
            "success": True,
            "transcript": transcript,
            "length": len(transcript)
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/test-image", response_model=dict)
async def test_image_extraction(file: UploadFile = File(...)):
    """
    Test image OCR without saving to patient record
    
    Useful for testing Gemini Vision integration
    """
    
    try:
        # Save temp file
        temp_path = f"/tmp/test_image_{uuid.uuid4().hex[:8]}.jpg"
        with open(temp_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        # Extract
        prescription_data = await extract_prescription(temp_path)
        
        # Clean up
        os.remove(temp_path)
        
        return {
            "success": True,
            "prescription_data": prescription_data
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
