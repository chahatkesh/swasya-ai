"""
Patient management routes
"""

from fastapi import APIRouter, HTTPException
from app.models.schemas import (
    PatientCreate, 
    PatientResponse, 
    SuccessResponse,
    QueueStatus
)
from app.services.mongodb_storage import mongodb_storage
import uuid
from datetime import datetime
from typing import List

router = APIRouter(prefix="/patients", tags=["Patients"])



@router.get("/check-uhid/{uhid}", response_model=dict)
async def check_uhid(uhid: str):
    """
    Check if a UHID (Unified Health ID) exists in the system
    
    **Use Case:**
    - Nurse enters UHID on registration screen
    - Backend checks if patient already exists
    - If exists: Return patient data for auto-fill
    - If not exists: Allow new registration
    
    **Path Parameters:**
    - uhid: Government-issued Unified Health ID
    
    **Returns:**
    - exists: Boolean indicating if UHID is found
    - patient: Patient data if found (null if not found)
    """
    
    patient = await mongodb_storage.get_patient_by_uhid(uhid)
    
    if patient:
        print(f"✅ UHID {uhid} found - Patient: {patient.get('name')}")
        return {
            "success": True,
            "exists": True,
            "patient": patient,
            "message": f"Welcome back, {patient.get('name')}!"
        }
    else:
        print(f"ℹ️ UHID {uhid} not found - New patient")
        return {
            "success": True,
            "exists": False,
            "patient": None,
            "message": "New patient - please complete registration"
        }


@router.post("", response_model=dict)
async def register_patient(patient: PatientCreate):
    """
    Register a new patient with UHID (Unified Health ID)
    
    **Request Body:**
    - uhid: Government-issued Unified Health ID (REQUIRED)
    - name: Patient's full name
    - phone: 10-digit mobile number
    - age: Optional age
    - gender: Optional gender (male/female/other)
    
    **Business Logic:**
    1. Check if UHID already exists
    2. If exists: Return error (409 Conflict)
    3. If not exists: Create new patient record
    
    **Returns:**
    - patient_id: Unique internal identifier
    - uhid: Government Health ID
    - message: Success message
    """
    
    # Check if UHID already exists
    existing_patient = await mongodb_storage.get_patient_by_uhid(patient.uhid)
    if existing_patient:
        print(f"❌ UHID {patient.uhid} already registered - Patient: {existing_patient.get('name')}")
        raise HTTPException(
            status_code=409,  # 409 Conflict
            detail={
                "error": "Patient already registered",
                "message": f"UHID {patient.uhid} is already registered to {existing_patient.get('name')}",
                "patient": existing_patient
            }
        )
    
    # Generate unique internal patient ID
    patient_id = f"PAT_{uuid.uuid4().hex[:8].upper()}"
    
    # Create patient data
    patient_data = {
        "patient_id": patient_id,
        "uhid": patient.uhid,  # Government Health ID (PRIMARY KEY)
        "name": patient.name,
        "phone": patient.phone,
        "age": patient.age,
        "gender": patient.gender,
        "created_at": datetime.now().isoformat(),
        "last_visit": datetime.now().isoformat(),
        "visit_count": 1,
        "status": "active"
    }
    
    # Save to storage
    await mongodb_storage.create_patient(patient_id, patient_data)
    
    print(f"✅ Registered: {patient_id} - UHID: {patient.uhid} - {patient.name}")
    
    # NEW: Auto-add to queue
    queue_id = f"Q_{uuid.uuid4().hex[:8].upper()}"
    queue = await mongodb_storage.get_queue()
    active_queue = [q for q in queue if q['status'] != 'completed']
    token_number = len(active_queue) + 1
    
    queue_entry = {
        "queue_id": queue_id,
        "patient_id": patient_id,
        "patient_name": patient.name,
        "token_number": token_number,
        "priority": "normal",
        "status": QueueStatus.WAITING,
        "added_at": datetime.now().isoformat(),
        "started_at": None,
        "completed_at": None,
        "nurse_completed_at": None,
        "timeline_ready_at": None
    }
    
    await mongodb_storage.add_to_queue(queue_entry)
    
    print(f"✅ Added to queue: Token #{token_number} - {patient.name}")
    
    return {
        "success": True,
        "patient_id": patient_id,
        "queue_id": queue_id,  # NEW: Return queue_id for nurse app
        "uhid": patient.uhid,
        "message": f"Patient {patient.name} registered and added to queue"
    }


@router.get("", response_model=dict)
async def list_patients():
    """
    Get list of all registered patients
    
    **Returns:**
    - count: Total number of patients
    - patients: List of all patient records
    """
    import time
    start = time.time()
    print(f"📋 [API] GET /patients - Request received")
    
    patients = await mongodb_storage.get_all_patients()
    
    elapsed = (time.time() - start) * 1000
    print(f"📋 [API] GET /patients - Returning {len(patients)} patients in {elapsed:.2f}ms")
    
    return {
        "success": True,
        "count": len(patients),
        "patients": list(patients.values())
    }


@router.get("/{patient_id}", response_model=dict)
async def get_patient_details(patient_id: str):
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
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Get related data
    notes = await mongodb_storage.get_patient_notes(patient_id)
    history = await mongodb_storage.get_patient_history(patient_id)
    
    # Check queue status
    queue = await mongodb_storage.get_queue()
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
async def get_patient_complete_record(patient_id: str):
    """
    Get COMPLETE patient record with all notes and history
    
    Use this for the doctor's dashboard view
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    # Get patient
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Get all data
    notes = await mongodb_storage.get_patient_notes(patient_id)
    history = await mongodb_storage.get_patient_history(patient_id)
    
    return {
        "success": True,
        "patient": patient,
        "notes": notes,
        "history": history
    }


@router.put("/{patient_id}", response_model=dict)
async def update_patient(patient_id: str, updates: dict):
    """
    Update patient information
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    
    **Request Body:**
    - Any patient fields to update (name, phone, age, gender)
    """
    
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Update patient
    updated_patient = await mongodb_storage.update_patient(patient_id, updates)
    
    return {
        "success": True,
        "message": "Patient updated successfully",
        "patient": updated_patient
    }
