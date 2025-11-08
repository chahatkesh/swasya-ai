"""
Patient management routes
"""

from fastapi import APIRouter, HTTPException
from app.models.schemas import (
    PatientCreate, 
    PatientResponse, 
    SuccessResponse
)
from app.services.storage_service import storage
import uuid
from datetime import datetime
from typing import List

router = APIRouter(prefix="/patients", tags=["Patients"])


@router.post("", response_model=dict)
def register_patient(patient: PatientCreate):
    """
    Register a new patient
    
    **Request Body:**
    - name: Patient's full name
    - phone: 10-digit mobile number
    - age: Optional age
    - gender: Optional gender (male/female/other)
    
    **Returns:**
    - patient_id: Unique identifier for the patient
    - message: Success message
    """
    
    # Generate unique patient ID
    patient_id = f"PAT_{uuid.uuid4().hex[:8].upper()}"
    
    # Create patient data
    patient_data = {
        "patient_id": patient_id,
        "name": patient.name,
        "phone": patient.phone,
        "age": patient.age,
        "gender": patient.gender,
        "created_at": datetime.now().isoformat(),
        "status": "active"
    }
    
    # Save to storage
    storage.create_patient(patient_id, patient_data)
    
    print(f"✅ Registered: {patient_id} - {patient.name}")
    
    return {
        "success": True,
        "patient_id": patient_id,
        "message": f"Patient {patient.name} registered successfully"
    }


@router.get("", response_model=dict)
def list_patients():
    """
    Get list of all registered patients
    
    **Returns:**
    - count: Total number of patients
    - patients: List of all patient records
    """
    patients = storage.get_all_patients()
    
    return {
        "success": True,
        "count": len(patients),
        "patients": list(patients.values())
    }


@router.get("/{patient_id}", response_model=dict)
def get_patient_details(patient_id: str):
    """
    Get detailed information about a specific patient
    
    Includes:
    - Basic patient info
    - All medical notes
    - Prescription history
    - Current queue status
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    # Get patient
    patient = storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Get related data
    notes = storage.get_patient_notes(patient_id)
    history = storage.get_patient_history(patient_id)
    
    # Check queue status
    queue = storage.get_queue()
    queue_entry = next((q for q in queue if q['patient_id'] == patient_id), None)
    
    return {
        "success": True,
        "patient": patient,
        "notes_count": len(notes),
        "history_count": len(history),
        "latest_notes": notes[-3:] if notes else [],  # Last 3 notes
        "latest_history": history[-3:] if history else [],  # Last 3 prescriptions
        "queue_status": queue_entry['status'] if queue_entry else None
    }


@router.get("/{patient_id}/complete", response_model=dict)
def get_patient_complete_record(patient_id: str):
    """
    Get COMPLETE patient record with all notes and history
    
    Use this for the doctor's dashboard view
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    # Get patient
    patient = storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Get all data
    notes = storage.get_patient_notes(patient_id)
    history = storage.get_patient_history(patient_id)
    
    return {
        "success": True,
        "patient": patient,
        "notes": notes,
        "history": history
    }


@router.put("/{patient_id}", response_model=dict)
def update_patient(patient_id: str, updates: dict):
    """
    Update patient information
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    
    **Request Body:**
    - Any patient fields to update (name, phone, age, gender)
    """
    
    patient = storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Update patient
    updated_patient = storage.update_patient(patient_id, updates)
    
    return {
        "success": True,
        "message": "Patient updated successfully",
        "patient": updated_patient
    }
