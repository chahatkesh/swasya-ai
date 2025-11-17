"""
Pydantic Models for Request/Response Validation
"""

from pydantic import BaseModel, Field
from enum import Enum
from typing import Optional, List
from datetime import datetime


class QueueStatus(str, Enum):
    """Queue status options"""
    WAITING = "waiting"                    # Patient registered, nurse hasn't started work
    NURSE_COMPLETED = "nurse_completed"    # Nurse finished, timeline generating
    READY_FOR_DOCTOR = "ready_for_doctor"  # Timeline ready, waiting for doctor
    IN_CONSULTATION = "in_consultation"    # Doctor actively reviewing patient
    COMPLETED = "completed"                # Consultation finished
    CANCELLED = "cancelled"                # Queue entry cancelled


class Priority(str, Enum):
    """Priority levels"""
    NORMAL = "normal"
    URGENT = "urgent"


# ==================== PATIENT MODELS ====================

class PatientCreate(BaseModel):
    """Request model for patient registration"""
    uhid: str = Field(..., min_length=1, max_length=50, description="Unified Health ID (Government issued)")
    name: str = Field(..., min_length=1, max_length=100)
    phone: str = Field(..., pattern=r'^\d{10}$')
    age: Optional[int] = Field(None, ge=0, le=120)
    gender: Optional[str] = Field(None, pattern=r'^(male|female|other)$')

    class Config:
        json_schema_extra = {
            "example": {
                "uhid": "UHID123456789",
                "name": "Ram Kumar",
                "phone": "9876543210",
                "age": 45,
                "gender": "male"
            }
        }


class PatientResponse(BaseModel):
    """Response model for patient data"""
    patient_id: str
    uhid: str
    name: str
    phone: str
    age: Optional[int]
    gender: Optional[str]
    created_at: str
    status: str
    last_visit: Optional[str] = None
    visit_count: int = 0


# ==================== QUEUE MODELS ====================

class QueueEntry(BaseModel):
    """Request model for adding to queue"""
    patient_id: Optional[str] = None  # Can use patient_id OR uhid
    uhid: Optional[str] = None        # Can use patient_id OR uhid
    priority: Priority = Priority.NORMAL
    
    class Config:
        json_schema_extra = {
            "example": {
                "uhid": "UHID123456789",
                "priority": "normal"
            }
        }


class QueueItemResponse(BaseModel):
    """Response model for queue item"""
    queue_id: str
    patient_id: str
    patient_name: str
    token_number: int
    priority: str
    status: QueueStatus
    added_at: str
    started_at: Optional[str] = None
    completed_at: Optional[str] = None


# ==================== NOTES MODELS ====================

class SOAPNote(BaseModel):
    """SOAP note structure"""
    subjective: str
    objective: str
    assessment: str
    plan: str
    chief_complaint: str
    medications: List[str] = []
    language: str = "hindi"


class NoteResponse(BaseModel):
    """Response model for a patient note"""
    note_id: str
    patient_id: str
    created_at: str
    soap_note: SOAPNote
    audio_file: Optional[str] = None
    transcript: Optional[str] = None


# ==================== PRESCRIPTION MODELS ====================

class Medication(BaseModel):
    """Single medication detail"""
    name: str
    dosage: Optional[str] = None
    frequency: Optional[str] = None  # TDS, BD, OD
    duration: Optional[str] = None


class PrescriptionData(BaseModel):
    """Extracted prescription data"""
    doctor_name: Optional[str] = None
    date: Optional[str] = None
    medications: List[Medication] = []
    diagnosis: Optional[str] = None
    instructions: Optional[str] = None


class PrescriptionResponse(BaseModel):
    """Response model for prescription upload"""
    history_id: str
    patient_id: str
    created_at: str
    prescription_data: PrescriptionData
    image_file: str


# ==================== GENERIC RESPONSES ====================

class SuccessResponse(BaseModel):
    """Generic success response"""
    success: bool = True
    message: str


class ErrorResponse(BaseModel):
    """Generic error response"""
    success: bool = False
    error: str
    detail: Optional[str] = None


class StatsResponse(BaseModel):
    """API statistics response"""
    service: str
    version: str
    status: str
    features: List[str]
    stats: dict
