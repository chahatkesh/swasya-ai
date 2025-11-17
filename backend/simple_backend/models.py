"""Data models for PHC AI Co-Pilot Backend"""

from pydantic import BaseModel
from enum import Enum
from typing import Optional


class QueueStatus(str, Enum):
    WAITING = "waiting"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class PatientCreate(BaseModel):
    name: str
    phone: str
    age: Optional[int] = None
    gender: Optional[str] = None


class QueueEntry(BaseModel):
    patient_id: str
    priority: Optional[str] = "normal"  # normal, urgent
