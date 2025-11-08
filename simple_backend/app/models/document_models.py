"""
Document and Timeline Models
"""

from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime


class DocumentUploadResponse(BaseModel):
    """Response for single document upload"""
    document_id: str
    patient_id: str
    status: str  # 'processing', 'completed', 'failed'
    extracted_data: Optional[dict] = None
    uploaded_at: str


class MedicationEntry(BaseModel):
    """Single medication entry"""
    name: str
    dosage: Optional[str] = None
    frequency: Optional[str] = None
    duration: Optional[str] = None
    prescribed_date: Optional[str] = None
    doctor: Optional[str] = None


class TimelineEvent(BaseModel):
    """Single event in patient timeline"""
    date: Optional[str] = None
    event_type: str  # 'prescription', 'diagnosis', 'visit'
    description: str
    medications: List[MedicationEntry] = []
    doctor: Optional[str] = None
    notes: Optional[str] = None


class MedicalTimeline(BaseModel):
    """Complete medical timeline for patient"""
    patient_id: str
    generated_at: str
    total_documents: int
    timeline_events: List[TimelineEvent]
    current_medications: List[MedicationEntry]
    chronic_conditions: List[str] = []
    allergies: List[str] = []
    summary: str


class DocumentBatch(BaseModel):
    """Batch of documents for processing"""
    batch_id: str
    patient_id: str
    document_ids: List[str]
    status: str  # 'pending', 'processing', 'completed'
    created_at: str
    completed_at: Optional[str] = None
