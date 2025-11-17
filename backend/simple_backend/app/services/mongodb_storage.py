"""
MongoDB Storage Service for Patients, Queue, Notes, and History
Replaces JSON file-based storage with MongoDB collections
"""

import os
from typing import Dict, List, Optional
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import ASCENDING, DESCENDING


class MongoDBStorage:
    """MongoDB storage service for all application data"""
    
    def __init__(self):
        self.client = None
        self.db = None
        self.mongodb_url = os.environ.get('MONGODB_URL', 'mongodb://admin:phc2024@mongodb:27017/phc?authSource=admin')
        
    async def connect(self):
        """Connect to MongoDB and create indexes"""
        if self.client is None:
            self.client = AsyncIOMotorClient(self.mongodb_url)
            self.db = self.client.phc
            await self._create_indexes()
            print("✅ MongoDB Storage connected (patients, queue, notes, history)")
    
    async def disconnect(self):
        """Disconnect from MongoDB"""
        if self.client:
            self.client.close()
            print("🔌 MongoDB Storage disconnected")
    
    async def _create_indexes(self):
        """Create database indexes for efficient queries"""
        # Patients collection
        await self.db.patients.create_index([("patient_id", ASCENDING)], unique=True)
        await self.db.patients.create_index([("uhid", ASCENDING)], unique=True, sparse=True)
        await self.db.patients.create_index([("created_at", DESCENDING)])
        
        # Queue collection
        await self.db.queue.create_index([("queue_id", ASCENDING)], unique=True)
        await self.db.queue.create_index([("patient_id", ASCENDING)])
        await self.db.queue.create_index([("status", ASCENDING)])
        await self.db.queue.create_index([("added_at", DESCENDING)])
        
        # Notes collection
        await self.db.notes.create_index([("note_id", ASCENDING)], unique=True)
        await self.db.notes.create_index([("patient_id", ASCENDING)])
        await self.db.notes.create_index([("created_at", DESCENDING)])
        
        # History collection
        await self.db.history.create_index([("history_id", ASCENDING)], unique=True)
        await self.db.history.create_index([("patient_id", ASCENDING)])
        await self.db.history.create_index([("date", DESCENDING)])
    
    # ==================== PATIENTS ====================
    
    async def get_all_patients(self) -> Dict:
        """Get all patients as dict (for compatibility with JSON storage)"""
        cursor = self.db.patients.find({}, {"_id": 0}).sort("created_at", DESCENDING)
        patients_list = await cursor.to_list(length=None)
        # Convert to dict format for compatibility with old JSON structure
        return {p['patient_id']: p for p in patients_list}
    
    async def get_patient(self, patient_id: str) -> Optional[Dict]:
        """Get single patient by ID"""
        return await self.db.patients.find_one({"patient_id": patient_id}, {"_id": 0})
    
    async def get_patient_by_uhid(self, uhid: str) -> Optional[Dict]:
        """Get patient by UHID"""
        return await self.db.patients.find_one({"uhid": uhid}, {"_id": 0})
    
    async def create_patient(self, patient_id: str, patient_data: Dict) -> Dict:
        """Create new patient"""
        patient_data['patient_id'] = patient_id
        patient_data['created_at'] = patient_data.get('created_at', datetime.now().isoformat())
        patient_data['updated_at'] = datetime.now().isoformat()
        
        await self.db.patients.insert_one(patient_data)
        return patient_data
    
    async def update_patient(self, patient_id: str, updates: Dict) -> Optional[Dict]:
        """Update patient data"""
        updates['updated_at'] = datetime.now().isoformat()
        
        result = await self.db.patients.find_one_and_update(
            {"patient_id": patient_id},
            {"$set": updates},
            return_document=True
        )
        
        if result:
            result.pop('_id', None)
        return result
    
    # ==================== QUEUE ====================
    
    async def get_queue(self) -> List[Dict]:
        """Get all queue entries"""
        cursor = self.db.queue.find({}, {"_id": 0}).sort("added_at", ASCENDING)
        return await cursor.to_list(length=None)
    
    async def add_to_queue(self, queue_entry: Dict) -> Dict:
        """Add entry to queue"""
        await self.db.queue.insert_one(queue_entry)
        return queue_entry
    
    async def update_queue_status(self, queue_id: str, status: str, **kwargs) -> Optional[Dict]:
        """Update queue entry status"""
        updates = {"status": status}
        updates.update(kwargs)
        
        result = await self.db.queue.find_one_and_update(
            {"queue_id": queue_id},
            {"$set": updates},
            return_document=True
        )
        
        if result:
            result.pop('_id', None)
        return result
    
    async def get_queue_by_status(self, status: str) -> List[Dict]:
        """Get queue entries by status"""
        cursor = self.db.queue.find({"status": status}, {"_id": 0})
        return await cursor.to_list(length=None)
    
    async def clear_completed_queue(self):
        """Remove completed entries from queue"""
        result = await self.db.queue.delete_many({"status": "completed"})
        return result.deleted_count
    
    # ==================== NOTES ====================
    
    async def get_all_notes(self) -> Dict:
        """Get all notes organized by patient_id (for compatibility)"""
        cursor = self.db.notes.find({}, {"_id": 0})
        all_notes = await cursor.to_list(length=None)
        
        # Organize by patient_id
        notes_by_patient = {}
        for note in all_notes:
            patient_id = note['patient_id']
            if patient_id not in notes_by_patient:
                notes_by_patient[patient_id] = []
            notes_by_patient[patient_id].append(note)
        
        return notes_by_patient
    
    async def get_patient_notes(self, patient_id: str) -> List[Dict]:
        """Get all notes for a patient"""
        cursor = self.db.notes.find(
            {"patient_id": patient_id}, 
            {"_id": 0}
        ).sort("created_at", DESCENDING)
        return await cursor.to_list(length=None)
    
    async def add_note(self, patient_id: str, note: Dict) -> Dict:
        """Add note for patient"""
        note['patient_id'] = patient_id
        note['created_at'] = note.get('created_at', datetime.now().isoformat())
        note['updated_at'] = datetime.now().isoformat()
        
        # Generate note_id if not provided
        if 'note_id' not in note:
            import uuid
            note['note_id'] = f"NOTE_{uuid.uuid4().hex[:8].upper()}"
        
        await self.db.notes.insert_one(note)
        return note
    
    # ==================== HISTORY ====================
    
    async def get_all_history(self) -> Dict:
        """Get all history organized by patient_id (for compatibility)"""
        cursor = self.db.history.find({}, {"_id": 0})
        all_history = await cursor.to_list(length=None)
        
        # Organize by patient_id
        history_by_patient = {}
        for entry in all_history:
            patient_id = entry['patient_id']
            if patient_id not in history_by_patient:
                history_by_patient[patient_id] = []
            history_by_patient[patient_id].append(entry)
        
        return history_by_patient
    
    async def get_patient_history(self, patient_id: str) -> List[Dict]:
        """Get all history for a patient"""
        cursor = self.db.history.find(
            {"patient_id": patient_id}, 
            {"_id": 0}
        ).sort("date", DESCENDING)
        return await cursor.to_list(length=None)
    
    async def add_history(self, patient_id: str, history_entry: Dict) -> Dict:
        """Add history entry for patient"""
        history_entry['patient_id'] = patient_id
        history_entry['created_at'] = history_entry.get('created_at', datetime.now().isoformat())
        history_entry['updated_at'] = datetime.now().isoformat()
        
        # Generate history_id if not provided
        if 'history_id' not in history_entry:
            import uuid
            history_entry['history_id'] = f"HIST_{uuid.uuid4().hex[:8].upper()}"
        
        await self.db.history.insert_one(history_entry)
        return history_entry


# Singleton instance
mongodb_storage = MongoDBStorage()
