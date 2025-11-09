"""
Notes and History routes
"""

from fastapi import APIRouter, HTTPException
from app.services.mongodb_storage import mongodb_storage
from datetime import datetime

router = APIRouter(tags=["Notes & History"])


@router.get("/notes/{patient_id}", response_model=dict)
async def get_patient_notes(patient_id: str):
    """
    Get all medical notes for a patient
    
    Returns all SOAP notes generated from audio recordings
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    # Verify patient exists
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    notes = await mongodb_storage.get_patient_notes(patient_id)
    
    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "count": len(notes),
        "notes": notes
    }


@router.get("/notes/{patient_id}/latest", response_model=dict)
async def get_latest_note(patient_id: str):
    """
    Get most recent note for a patient
    
    Useful for displaying current consultation notes
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    notes = await mongodb_storage.get_patient_notes(patient_id)
    
    if not notes:
        return {
            "success": True,
            "message": "No notes found for this patient",
            "note": None
        }
    
    latest_note = notes[-1]  # Last note in list
    
    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "note": latest_note
    }


@router.get("/history/{patient_id}", response_model=dict)
async def get_patient_history(patient_id: str):
    """
    Get all prescription history for a patient
    
    Returns all extracted prescription data from images
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    history = await mongodb_storage.get_patient_history(patient_id)
    
    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "count": len(history),
        "history": history
    }


@router.get("/history/{patient_id}/medications", response_model=dict)
async def get_all_medications(patient_id: str):
    """
    Get comprehensive medication timeline for a patient
    
    Aggregates all medications from prescription history
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    history = await mongodb_storage.get_patient_history(patient_id)
    
    # Extract all medications
    all_medications = []
    for entry in history:
        prescription = entry.get('prescription_data', {})
        medications = prescription.get('medications', [])
        
        for med in medications:
            all_medications.append({
                "medication": med,
                "prescription_date": entry.get('created_at'),
                "doctor": prescription.get('doctor_name', 'Unknown'),
                "diagnosis": prescription.get('diagnosis', 'Not specified')
            })
    
    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "total_medications": len(all_medications),
        "medications": all_medications
    }


@router.get("/summary/{patient_id}", response_model=dict)
async def get_patient_summary(patient_id: str):
    """
    Get complete patient summary
    
    Includes:
    - Patient info
    - Latest SOAP note
    - Recent medications
    - Visit count
    
    **Ideal for doctor's quick view**
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    notes = await mongodb_storage.get_patient_notes(patient_id)
    history = await mongodb_storage.get_patient_history(patient_id)
    
    # Get latest note
    latest_note = notes[-1] if notes else None
    
    # Get recent medications
    recent_meds = []
    if history:
        for entry in history[-3:]:  # Last 3 prescriptions
            prescription = entry.get('prescription_data', {})
            meds = prescription.get('medications', [])
            recent_meds.extend([m.get('name') for m in meds if 'name' in m])
    
    # Get chief complaints from notes
    chief_complaints = []
    for note in notes[-5:]:  # Last 5 visits
        soap = note.get('soap_note', {})
        complaint = soap.get('chief_complaint')
        if complaint:
            chief_complaints.append({
                "complaint": complaint,
                "date": note.get('created_at')
            })
    
    return {
        "success": True,
        "patient": {
            "id": patient['patient_id'],
            "name": patient['name'],
            "phone": patient['phone'],
            "age": patient.get('age'),
            "gender": patient.get('gender')
        },
        "statistics": {
            "total_visits": len(notes),
            "prescriptions_on_file": len(history),
            "member_since": patient['created_at']
        },
        "latest_visit": latest_note,
        "chief_complaints": chief_complaints,
        "recent_medications": list(set(recent_meds))  # Unique medications
    }


@router.get("/timeline/{patient_id}", response_model=dict)
async def get_medical_timeline(patient_id: str):
    """
    Get complete medical timeline for a patient
    
    Combines SOAP notes and prescription history in chronological order.
    Each entry is tagged with type (note/prescription) and timestamp.
    
    **Ideal for doctor dashboard - shows complete patient journey**
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    
    **Returns:**
    Timeline with entries sorted by date (newest first):
    - type: "note" or "prescription"
    - date: ISO timestamp
    - content: Full data object
    """
    
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    notes = await mongodb_storage.get_patient_notes(patient_id)
    history = await mongodb_storage.get_patient_history(patient_id)
    
    # Build timeline
    timeline = []
    
    # Add notes to timeline
    for note in notes:
        timeline.append({
            "type": "note",
            "date": note.get('created_at'),
            "timestamp": note.get('created_at'),
            "entry": {
                "note_id": note.get('note_id'),
                "audio_file": note.get('audio_file'),
                "soap_note": note.get('soap_note', {}),
                "chief_complaint": note.get('soap_note', {}).get('chief_complaint', 'Not specified'),
                "assessment": note.get('soap_note', {}).get('assessment', 'Not specified'),
                "plan": note.get('soap_note', {}).get('plan', 'Not specified')
            }
        })
    
    # Add prescriptions to timeline
    for hist in history:
        prescription = hist.get('prescription_data', {})
        timeline.append({
            "type": "prescription",
            "date": hist.get('created_at'),
            "timestamp": hist.get('created_at'),
            "entry": {
                "history_id": hist.get('history_id'),
                "image_file": hist.get('image_file'),
                "doctor_name": prescription.get('doctor_name', 'Unknown'),
                "hospital": prescription.get('hospital', 'Not specified'),
                "diagnosis": prescription.get('diagnosis', 'Not specified'),
                "medications": prescription.get('medications', []),
                "medication_count": len(prescription.get('medications', []))
            }
        })
    
    # Sort by timestamp (newest first)
    timeline.sort(key=lambda x: x['timestamp'], reverse=True)
    
    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "timeline": timeline,
        "statistics": {
            "total_entries": len(timeline),
            "notes_count": len(notes),
            "prescriptions_count": len(history),
            "date_range": {
                "first_entry": timeline[-1]['date'] if timeline else None,
                "latest_entry": timeline[0]['date'] if timeline else None
            }
        }
    }
 