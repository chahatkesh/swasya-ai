"""
Migration Script: JSON Files → MongoDB
Copies all data from patients.json, queue.json, notes.json, history.json to MongoDB
"""

import asyncio
import json
import os
from pathlib import Path
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient


# MongoDB connection
MONGODB_URL = os.environ.get('MONGODB_URL', 'mongodb://admin:phc2024@mongodb:27017/phc?authSource=admin')
DATA_DIR = Path("/app/data")


async def migrate_data():
    """Main migration function"""
    
    print("🚀 Starting MongoDB migration...")
    print(f"📂 Reading from: {DATA_DIR}")
    print(f"🔗 MongoDB URL: {MONGODB_URL}")
    
    # Connect to MongoDB
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client.phc
    
    try:
        # Test connection
        await db.command('ping')
        print("✅ MongoDB connected")
        
        # Migrate Patients
        await migrate_patients(db)
        
        # Migrate Queue
        await migrate_queue(db)
        
        # Migrate Notes
        await migrate_notes(db)
        
        # Migrate History
        await migrate_history(db)
        
        print("\n" + "="*60)
        print("✅ Migration completed successfully!")
        print("="*60)
        
        # Print summary
        await print_summary(db)
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        raise
    finally:
        client.close()


async def migrate_patients(db):
    """Migrate patients.json → patients collection"""
    print("\n📋 Migrating Patients...")
    
    patients_file = DATA_DIR / "patients.json"
    if not patients_file.exists():
        print("   ⚠️  patients.json not found, skipping")
        return
    
    with open(patients_file, 'r') as f:
        patients_dict = json.load(f)
    
    if not patients_dict:
        print("   ℹ️  No patients to migrate")
        return
    
    # Clear existing data
    await db.patients.delete_many({})
    
    # Convert dict to list and add metadata
    patients_list = []
    for patient_id, patient_data in patients_dict.items():
        patient_data['patient_id'] = patient_id
        patient_data['created_at'] = patient_data.get('created_at', datetime.now().isoformat())
        patient_data['updated_at'] = datetime.now().isoformat()
        patients_list.append(patient_data)
    
    # Insert
    if patients_list:
        result = await db.patients.insert_many(patients_list)
        print(f"   ✅ Migrated {len(result.inserted_ids)} patients")
    else:
        print("   ℹ️  No patients to migrate")


async def migrate_queue(db):
    """Migrate queue.json → queue collection"""
    print("\n🔄 Migrating Queue...")
    
    queue_file = DATA_DIR / "queue.json"
    if not queue_file.exists():
        print("   ⚠️  queue.json not found, skipping")
        return
    
    with open(queue_file, 'r') as f:
        queue_list = json.load(f)
    
    if not queue_list:
        print("   ℹ️  No queue entries to migrate")
        return
    
    # Clear existing data
    await db.queue.delete_many({})
    
    # Insert
    if queue_list:
        result = await db.queue.insert_many(queue_list)
        print(f"   ✅ Migrated {len(result.inserted_ids)} queue entries")
        
        # Show status breakdown
        statuses = {}
        for entry in queue_list:
            status = entry.get('status', 'unknown')
            statuses[status] = statuses.get(status, 0) + 1
        print(f"   📊 Status breakdown: {statuses}")
    else:
        print("   ℹ️  No queue entries to migrate")


async def migrate_notes(db):
    """Migrate notes.json → notes collection"""
    print("\n📝 Migrating Notes...")
    
    notes_file = DATA_DIR / "notes.json"
    if not notes_file.exists():
        print("   ⚠️  notes.json not found, skipping")
        return
    
    with open(notes_file, 'r') as f:
        notes_dict = json.load(f)
    
    if not notes_dict:
        print("   ℹ️  No notes to migrate")
        return
    
    # Clear existing data
    await db.notes.delete_many({})
    
    # Convert dict to flat list
    notes_list = []
    for patient_id, patient_notes in notes_dict.items():
        for note in patient_notes:
            note['patient_id'] = patient_id
            note['created_at'] = note.get('created_at', datetime.now().isoformat())
            note['updated_at'] = datetime.now().isoformat()
            
            # Generate note_id if missing
            if 'note_id' not in note:
                import uuid
                note['note_id'] = f"NOTE_{uuid.uuid4().hex[:8].upper()}"
            
            notes_list.append(note)
    
    # Insert
    if notes_list:
        result = await db.notes.insert_many(notes_list)
        print(f"   ✅ Migrated {len(result.inserted_ids)} notes")
        print(f"   📊 Across {len(notes_dict)} patients")
    else:
        print("   ℹ️  No notes to migrate")


async def migrate_history(db):
    """Migrate history.json → history collection"""
    print("\n📜 Migrating History...")
    
    history_file = DATA_DIR / "history.json"
    if not history_file.exists():
        print("   ⚠️  history.json not found, skipping")
        return
    
    with open(history_file, 'r') as f:
        history_dict = json.load(f)
    
    if not history_dict:
        print("   ℹ️  No history to migrate")
        return
    
    # Clear existing data
    await db.history.delete_many({})
    
    # Convert dict to flat list
    history_list = []
    for patient_id, patient_history in history_dict.items():
        for entry in patient_history:
            entry['patient_id'] = patient_id
            entry['created_at'] = entry.get('created_at', datetime.now().isoformat())
            entry['updated_at'] = datetime.now().isoformat()
            
            # Generate history_id if missing
            if 'history_id' not in entry:
                import uuid
                entry['history_id'] = f"HIST_{uuid.uuid4().hex[:8].upper()}"
            
            history_list.append(entry)
    
    # Insert
    if history_list:
        result = await db.history.insert_many(history_list)
        print(f"   ✅ Migrated {len(result.inserted_ids)} history entries")
        print(f"   📊 Across {len(history_dict)} patients")
    else:
        print("   ℹ️  No history to migrate")


async def print_summary(db):
    """Print migration summary"""
    print("\n📊 Migration Summary:")
    print("-" * 60)
    
    patients_count = await db.patients.count_documents({})
    queue_count = await db.queue.count_documents({})
    notes_count = await db.notes.count_documents({})
    history_count = await db.history.count_documents({})
    
    print(f"   Patients:  {patients_count:4d} documents")
    print(f"   Queue:     {queue_count:4d} documents")
    print(f"   Notes:     {notes_count:4d} documents")
    print(f"   History:   {history_count:4d} documents")
    print("-" * 60)
    print(f"   TOTAL:     {patients_count + queue_count + notes_count + history_count:4d} documents")
    print("-" * 60)


if __name__ == "__main__":
    asyncio.run(migrate_data())
