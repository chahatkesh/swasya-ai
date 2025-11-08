"""Patient management routes"""

from fastapi import APIRouter, HTTPException
from datetime import datetime
import uuid
from models import PatientCreate
from utils.storage import load_json, save_json
from config import PATIENTS_FILE, NOTES_FILE

router = APIRouter(prefix="/patients", tags=["patients"])


@router.post("")
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
    
    print(f"✅ Registered new patient")
    
    return {
        "success": True,
        "patient_id": patient_id,
        "message": f"Patient {patient.name} registered"
    }


@router.get("")
def list_patients():
    """List all patients"""
    patients = load_json(PATIENTS_FILE)
    return {
        "success": True,
        "count": len(patients),
        "patients": list(patients.values())
    }


@router.get("/{patient_id}")
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
