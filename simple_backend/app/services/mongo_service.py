"""
MongoDB Service for document and timeline storage
"""

import os
from typing import List, Optional, Dict
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import ASCENDING, DESCENDING


class MongoService:
    """MongoDB service for storing documents and timelines"""
    
    def __init__(self):
        self.client = None
        self.db = None
        self.mongodb_url = os.environ.get('MONGODB_URL', 'mongodb://admin:phc2024@mongodb:27017/phc?authSource=admin')
        
    async def connect(self):
        """Connect to MongoDB"""
        if self.client is None:
            self.client = AsyncIOMotorClient(self.mongodb_url)
            self.db = self.client.phc
            
            # Create indexes
            await self._create_indexes()
            print("✅ MongoDB connected")
    
    async def disconnect(self):
        """Disconnect from MongoDB"""
        if self.client:
            self.client.close()
            print("🔌 MongoDB disconnected")
    
    async def _create_indexes(self):
        """Create database indexes for efficient queries"""
        # Documents collection indexes
        await self.db.documents.create_index([("patient_id", ASCENDING)])
        await self.db.documents.create_index([("batch_id", ASCENDING)])
        await self.db.documents.create_index([("uploaded_at", DESCENDING)])
        
        # Timelines collection indexes
        await self.db.timelines.create_index([("patient_id", ASCENDING)])
        await self.db.timelines.create_index([("generated_at", DESCENDING)])
        
        # Batches collection indexes
        await self.db.batches.create_index([("patient_id", ASCENDING)])
        await self.db.batches.create_index([("status", ASCENDING)])
    
    # ==================== DOCUMENT OPERATIONS ====================
    
    async def save_document(self, document_data: Dict) -> str:
        """Save a single document"""
        result = await self.db.documents.insert_one(document_data)
        return str(result.inserted_id)
    
    async def get_document(self, document_id: str) -> Optional[Dict]:
        """Get single document by ID"""
        return await self.db.documents.find_one({"document_id": document_id})
    
    async def get_patient_documents(self, patient_id: str) -> List[Dict]:
        """Get all documents for a patient"""
        cursor = self.db.documents.find({"patient_id": patient_id}).sort("uploaded_at", DESCENDING)
        return await cursor.to_list(length=None)
    
    async def get_batch_documents(self, batch_id: str) -> List[Dict]:
        """Get all documents in a batch"""
        cursor = self.db.documents.find({"batch_id": batch_id}).sort("uploaded_at", ASCENDING)
        return await cursor.to_list(length=None)
    
    async def update_document_status(self, document_id: str, status: str, extracted_data: Optional[Dict] = None):
        """Update document processing status"""
        update_data = {"status": status}
        # Always set extracted_data if provided (allow empty dict)
        if extracted_data is not None:
            update_data["extracted_data"] = extracted_data
        
        await self.db.documents.update_one(
            {"document_id": document_id},
            {"$set": update_data}
        )
    
    # ==================== BATCH OPERATIONS ====================
    
    async def create_batch(self, batch_data: Dict) -> str:
        """Create a new document batch"""
        result = await self.db.batches.insert_one(batch_data)
        return str(result.inserted_id)
    
    async def get_batch(self, batch_id: str) -> Optional[Dict]:
        """Get batch by ID"""
        return await self.db.batches.find_one({"batch_id": batch_id})
    
    async def add_document_to_batch(self, batch_id: str, document_id: str):
        """Add document to existing batch"""
        await self.db.batches.update_one(
            {"batch_id": batch_id},
            {"$push": {"document_ids": document_id}}
        )
    
    async def update_batch_status(self, batch_id: str, status: str):
        """Update batch status"""
        update_data = {"status": status}
        if status == "completed":
            update_data["completed_at"] = datetime.now().isoformat()
        
        await self.db.batches.update_one(
            {"batch_id": batch_id},
            {"$set": update_data}
        )
    
    async def get_active_batch(self, patient_id: str) -> Optional[Dict]:
        """Get active (pending/processing) batch for patient"""
        return await self.db.batches.find_one({
            "patient_id": patient_id,
            "status": {"$in": ["pending", "processing"]}
        })
    
    # ==================== TIMELINE OPERATIONS ====================
    
    async def save_timeline(self, timeline_data: Dict) -> str:
        """Save generated timeline"""
        # Delete old timelines for this patient (keep only latest)
        await self.db.timelines.delete_many({"patient_id": timeline_data["patient_id"]})
        
        # Insert new timeline
        result = await self.db.timelines.insert_one(timeline_data)
        return str(result.inserted_id)
    
    async def get_patient_timeline(self, patient_id: str) -> Optional[Dict]:
        """Get latest timeline for patient"""
        return await self.db.timelines.find_one(
            {"patient_id": patient_id},
            sort=[("generated_at", DESCENDING)]
        )
    
    async def get_all_timelines(self) -> List[Dict]:
        """Get all timelines (for admin view)"""
        cursor = self.db.timelines.find().sort("generated_at", DESCENDING)
        return await cursor.to_list(length=None)


# Singleton instance
mongo_service = MongoService()
