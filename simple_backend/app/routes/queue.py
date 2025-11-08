"""
Queue management routes
"""

from fastapi import APIRouter, HTTPException
from app.models.schemas import QueueEntry, QueueStatus
from app.services.storage_service import storage
import uuid
from datetime import datetime

router = APIRouter(prefix="/queue", tags=["Queue Management"])


@router.get("", response_model=dict)
def get_queue():
    """
    Get current queue status
    
    Shows all patients in queue with their status:
    - waiting: Patient registered, nurse hasn't started
    - nurse_completed: Nurse finished, timeline generating
    - ready_for_doctor: Timeline ready, waiting for doctor
    - in_consultation: Currently with doctor
    - completed: Consultation finished
    """
    
    queue = storage.get_queue()
    
    # Calculate statistics
    stats = {
        "waiting": len([q for q in queue if q['status'] == 'waiting']),
        "nurse_completed": len([q for q in queue if q['status'] == 'nurse_completed']),
        "ready_for_doctor": len([q for q in queue if q['status'] == 'ready_for_doctor']),
        "in_consultation": len([q for q in queue if q['status'] == 'in_consultation']),
        "completed": len([q for q in queue if q['status'] == 'completed']),
        "total": len(queue)
    }
    
    return {
        "success": True,
        "stats": stats,
        "queue": queue
    }


@router.post("", response_model=dict)
def add_to_queue(entry: QueueEntry):
    """
    Add patient to queue
    
    **Request Body:**
    - patient_id: Patient's unique identifier (optional if uhid provided)
    - uhid: Patient's Government Health ID (optional if patient_id provided)
    - priority: "normal" or "urgent"
    
    **Note:** You can provide either patient_id OR uhid. System will lookup the patient.
    
    **Returns:**
    - queue_id: Unique queue entry identifier
    - token_number: Queue position number
    """
    
    # Validate: must provide either patient_id or uhid
    if not entry.patient_id and not entry.uhid:
        raise HTTPException(
            status_code=400, 
            detail="Must provide either patient_id or uhid"
        )
    
    # Lookup patient by uhid if provided
    if entry.uhid:
        patient = storage.get_patient_by_uhid(entry.uhid)
        if not patient:
            raise HTTPException(
                status_code=404, 
                detail=f"Patient with UHID {entry.uhid} not found"
            )
        patient_id = patient['patient_id']
        print(f"✅ Found patient by UHID {entry.uhid}: {patient['name']}")
    else:
        # Use patient_id directly
        patient = storage.get_patient(entry.patient_id)
        if not patient:
            raise HTTPException(
                status_code=404, 
                detail=f"Patient {entry.patient_id} not found"
            )
        patient_id = entry.patient_id
    
    # Check if already in queue
    queue = storage.get_queue()
    existing = next((q for q in queue if q['patient_id'] == patient_id and q['status'] != 'completed'), None)
    if existing:
        raise HTTPException(status_code=400, detail=f"Patient already in queue with status: {existing['status']}")
    
    # Calculate token number (active entries only)
    active_queue = [q for q in queue if q['status'] != 'completed']
    token_number = len(active_queue) + 1
    
    # Create queue entry
    queue_id = f"Q_{uuid.uuid4().hex[:8].upper()}"
    queue_entry = {
        "queue_id": queue_id,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "token_number": token_number,
        "priority": entry.priority,
        "status": QueueStatus.WAITING,
        "added_at": datetime.now().isoformat(),
        "started_at": None,
        "completed_at": None
    }
    
    storage.add_to_queue(queue_entry)
    
    print(f"✅ Added to queue: {patient['name']} - Token #{token_number}")
    
    return {
        "success": True,
        "message": f"Patient added to queue",
        "queue_entry": queue_entry
    }


@router.get("/waiting", response_model=dict)
def get_waiting_patients():
    """
    Get all patients currently waiting
    
    Useful for displaying on waiting room screen
    """
    waiting = storage.get_queue_by_status(QueueStatus.WAITING)
    
    return {
        "success": True,
        "count": len(waiting),
        "patients": waiting
    }


@router.get("/current", response_model=dict)
def get_current_patient():
    """
    Get patient currently being treated
    
    Useful for doctor's dashboard
    """
    in_consultation = storage.get_queue_by_status(QueueStatus.IN_CONSULTATION)
    
    if not in_consultation:
        return {
            "success": True,
            "message": "No patient currently in consultation",
            "patient": None
        }
    
    # Should only be one in_consultation at a time
    current = in_consultation[0]
    patient = storage.get_patient(current['patient_id'])
    
    return {
        "success": True,
        "queue_entry": current,
        "patient": patient
    }


@router.post("/{queue_id}/nurse-complete", response_model=dict)
def nurse_complete_patient(queue_id: str):
    """
    Nurse marks patient as completed (timeline will be generated)
    
    **Path Parameters:**
    - queue_id: Queue entry identifier
    
    Changes status from 'waiting' → 'nurse_completed'
    
    **Usage:**
    Nurse clicks "Send to Doctor" button after recording audio/scanning documents.
    Timeline generation will start automatically, and status will update to 
    'ready_for_doctor' when complete.
    """
    
    updated = storage.update_queue_status(
        queue_id,
        QueueStatus.NURSE_COMPLETED,
        nurse_completed_at=datetime.now().isoformat()
    )
    
    if not updated:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    print(f"✅ Nurse completed: {updated['patient_name']}")
    
    return {
        "success": True,
        "message": "Patient ready for timeline generation",
        "queue_entry": updated
    }


@router.post("/{queue_id}/start", response_model=dict)
def start_consultation(queue_id: str):
    """
    Mark consultation as started
    
    **Path Parameters:**
    - queue_id: Queue entry identifier
    
    Changes status from 'ready_for_doctor' -> 'in_consultation'
    """
    
    # Check if another consultation is in progress
    in_consultation = storage.get_queue_by_status(QueueStatus.IN_CONSULTATION)
    if in_consultation:
        raise HTTPException(
            status_code=400, 
            detail=f"Another patient ({in_consultation[0]['patient_name']}) is already in consultation"
        )
    
    # Update status
    updated = storage.update_queue_status(
        queue_id, 
        QueueStatus.IN_CONSULTATION,
        started_at=datetime.now().isoformat()
    )
    
    if not updated:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    print(f"✅ Consultation started: {updated['patient_name']}")
    
    return {
        "success": True,
        "message": "Consultation started",
        "queue_entry": updated
    }


@router.post("/{queue_id}/complete", response_model=dict)
def complete_consultation(queue_id: str):
    """
    Mark consultation as completed
    
    **Path Parameters:**
    - queue_id: Queue entry identifier
    
    Changes status to 'completed'
    """
    
    updated = storage.update_queue_status(
        queue_id,
        QueueStatus.COMPLETED,
        completed_at=datetime.now().isoformat()
    )
    
    if not updated:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    print(f"✅ Consultation completed: {updated['patient_name']}")
    
    return {
        "success": True,
        "message": "Consultation completed",
        "queue_entry": updated
    }


@router.post("/{queue_id}/cancel", response_model=dict)
def cancel_queue_entry(queue_id: str):
    """
    Cancel/remove patient from queue
    
    **Path Parameters:**
    - queue_id: Queue entry identifier
    """
    
    updated = storage.update_queue_status(
        queue_id,
        QueueStatus.CANCELLED,
        cancelled_at=datetime.now().isoformat()
    )
    
    if not updated:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    return {
        "success": True,
        "message": "Queue entry cancelled",
        "queue_entry": updated
    }


@router.delete("/cleanup", response_model=dict)
def cleanup_completed():
    """
    Remove completed entries from queue
    
    Useful for keeping queue display clean
    """
    
    before_count = len(storage.get_queue())
    storage.clear_completed_queue()
    after_count = len(storage.get_queue())
    
    removed = before_count - after_count
    
    return {
        "success": True,
        "message": f"Removed {removed} completed entries",
        "remaining": after_count
    }
