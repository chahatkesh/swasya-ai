"""Queue management routes"""

from fastapi import APIRouter, HTTPException
from datetime import datetime
import uuid
from models import QueueEntry, QueueStatus
from utils.storage import load_json, save_json
from config import PATIENTS_FILE, QUEUE_FILE

router = APIRouter(prefix="/queue", tags=["queue"])


@router.post("/add")
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
    
    print(f"📋 Patient added to queue")
    
    return {
        "success": True,
        "queue_entry": queue_entry,
        "message": "Added to queue"
    }


@router.get("")
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


@router.post("/{queue_id}/start")
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


@router.post("/{queue_id}/complete")
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
