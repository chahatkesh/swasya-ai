"""
Service layer for storage operations (JSON file-based database)
"""

import json
import os
from typing import Dict, List, Optional
from datetime import datetime


class StorageService:
    """Handles all file-based data storage"""
    
    def __init__(self, base_dir: str = "/app/data"):
        self.base_dir = base_dir
        self.patients_file = f"{base_dir}/patients.json"
        self.queue_file = f"{base_dir}/queue.json"
        self.notes_file = f"{base_dir}/notes.json"
        self.history_file = f"{base_dir}/history.json"
        self.uploads_dir = f"{base_dir}/uploads"
        
        # Initialize storage
        self._init_storage()
    
    def _init_storage(self):
        """Create directories and files if they don't exist"""
        os.makedirs(self.base_dir, exist_ok=True)
        os.makedirs(self.uploads_dir, exist_ok=True)
        
        for file_path in [self.patients_file, self.notes_file, self.history_file]:
            if not os.path.exists(file_path):
                with open(file_path, 'w') as f:
                    json.dump({}, f)
        
        # Queue is a list, not dict
        if not os.path.exists(self.queue_file):
            with open(self.queue_file, 'w') as f:
                json.dump([], f)
    
    def load_json(self, file_path: str):
        """Load JSON file"""
        with open(file_path, 'r') as f:
            return json.load(f)
    
    def save_json(self, file_path: str, data):
        """Save JSON file"""
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)
    
    # ==================== PATIENTS ====================
    
    def get_all_patients(self) -> Dict:
        """Get all patients"""
        return self.load_json(self.patients_file)
    
    def get_patient(self, patient_id: str) -> Optional[Dict]:
        """Get single patient by ID"""
        patients = self.get_all_patients()
        return patients.get(patient_id)
    
    def get_patient_by_uhid(self, uhid: str) -> Optional[Dict]:
        """Get patient by UHID (Government Health ID)"""
        patients = self.get_all_patients()
        for patient_id, patient_data in patients.items():
            if patient_data.get('uhid') == uhid:
                return patient_data
        return None
    
    def create_patient(self, patient_id: str, patient_data: Dict) -> Dict:
        """Create new patient"""
        patients = self.get_all_patients()
        patients[patient_id] = patient_data
        self.save_json(self.patients_file, patients)
        return patient_data
    
    def update_patient(self, patient_id: str, updates: Dict) -> Optional[Dict]:
        """Update patient data"""
        patients = self.get_all_patients()
        if patient_id not in patients:
            return None
        patients[patient_id].update(updates)
        self.save_json(self.patients_file, patients)
        return patients[patient_id]
    
    # ==================== QUEUE ====================
    
    def get_queue(self) -> List[Dict]:
        """Get all queue entries"""
        return self.load_json(self.queue_file)
    
    def add_to_queue(self, queue_entry: Dict) -> Dict:
        """Add entry to queue"""
        queue = self.get_queue()
        queue.append(queue_entry)
        self.save_json(self.queue_file, queue)
        return queue_entry
    
    def update_queue_status(self, queue_id: str, status: str, **kwargs) -> Optional[Dict]:
        """Update queue entry status"""
        queue = self.get_queue()
        for entry in queue:
            if entry['queue_id'] == queue_id:
                entry['status'] = status
                entry.update(kwargs)
                self.save_json(self.queue_file, queue)
                return entry
        return None
    
    def get_queue_by_status(self, status: str) -> List[Dict]:
        """Get queue entries by status"""
        queue = self.get_queue()
        return [q for q in queue if q['status'] == status]
    
    def clear_completed_queue(self):
        """Remove completed entries from queue"""
        queue = self.get_queue()
        active_queue = [q for q in queue if q['status'] != 'completed']
        self.save_json(self.queue_file, active_queue)
    
    # ==================== NOTES ====================
    
    def get_all_notes(self) -> Dict:
        """Get all notes (organized by patient_id)"""
        return self.load_json(self.notes_file)
    
    def get_patient_notes(self, patient_id: str) -> List[Dict]:
        """Get all notes for a patient"""
        notes = self.get_all_notes()
        return notes.get(patient_id, [])
    
    def add_note(self, patient_id: str, note: Dict) -> Dict:
        """Add note for patient"""
        notes = self.get_all_notes()
        if patient_id not in notes:
            notes[patient_id] = []
        notes[patient_id].append(note)
        self.save_json(self.notes_file, notes)
        return note
    
    # ==================== HISTORY ====================
    
    def get_all_history(self) -> Dict:
        """Get all history (organized by patient_id)"""
        return self.load_json(self.history_file)
    
    def get_patient_history(self, patient_id: str) -> List[Dict]:
        """Get all history for a patient"""
        history = self.get_all_history()
        return history.get(patient_id, [])
    
    def add_history(self, patient_id: str, history_entry: Dict) -> Dict:
        """Add history entry for patient"""
        history = self.get_all_history()
        if patient_id not in history:
            history[patient_id] = []
        history[patient_id].append(history_entry)
        self.save_json(self.history_file, history)
        return history_entry


# Singleton instance
storage = StorageService()
