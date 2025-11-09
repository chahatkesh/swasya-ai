"""Health check and root routes"""

from fastapi import APIRouter
from datetime import datetime
from utils.storage import load_json
from config import PATIENTS_FILE, QUEUE_FILE, NOTES_FILE

router = APIRouter(tags=["health"])


@router.get("/")
def root():
    """API Info with real-time stats"""
    patients = load_json(PATIENTS_FILE)
    queue = load_json(QUEUE_FILE)
    notes = load_json(NOTES_FILE)
    
    queue_stats = {
        "waiting": len([q for q in queue if q['status'] == 'waiting']),
        "in_progress": len([q for q in queue if q['status'] == 'in_progress']),
        "completed_today": len([q for q in queue if q['status'] == 'completed'])
    }
    
    return {
        "service": "PHC AI Co-Pilot",
        "version": "2.0.0",
        "status": "running",
        "features": [
            "Queue Management",
            "Groq Whisper Transcription",
            "Gemini Vision OCR",
            "Real-time SOAP Notes"
        ],
        "stats": {
            "total_patients": len(patients),
            "queue": queue_stats,
            "total_notes": sum(len(v) for v in notes.values())
        }
    }


@router.get("/health")
def health_check():
    """Health check"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "services": {
            "groq_whisper": "configured",
            "gemini_vision": "configured"
        }
    }
