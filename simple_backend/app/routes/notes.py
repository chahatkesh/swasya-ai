"""
Notes and History routes
"""

from fastapi import APIRouter, HTTPException
from app.services.storage_service import storage

router = APIRouter(tags=["Notes & History"])


@router.get("/notes/{patient_id}", response_model=dict)
def get_patient_notes(patient_id: str):
    """
    Get all medical notes for a patient
    
    Returns all SOAP notes generated from audio recordings
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    # Verify patient exists
    patient = storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    notes = storage.get_patient_notes(patient_id)
    
    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "count": len(notes),
        "notes": notes
    }


@router.get("/notes/{patient_id}/latest", response_model=dict)
def get_latest_note(patient_id: str):
    """
    Get most recent note for a patient
    
    Useful for displaying current consultation notes
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    patient = storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    notes = storage.get_patient_notes(patient_id)
    
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
def get_patient_history(patient_id: str):
    """
    Get all prescription history for a patient
    
    Returns all extracted prescription data from images
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    patient = storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    history = storage.get_patient_history(patient_id)
    
    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "count": len(history),
        "history": history
    }


@router.get("/history/{patient_id}/medications", response_model=dict)
def get_all_medications(patient_id: str):
    """
    Get comprehensive medication timeline for a patient
    
    Aggregates all medications from prescription history
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    patient = storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    history = storage.get_patient_history(patient_id)
    
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
def get_patient_summary(patient_id: str):
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
    
    patient = storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    notes = storage.get_patient_notes(patient_id)
    history = storage.get_patient_history(patient_id)
    
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
 