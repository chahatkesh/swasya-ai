# Storage Migration Analysis: JSON → MongoDB

## 📊 Current State Analysis

### What's Already in MongoDB ✅
- **Documents** (via `mongo_service.py`)
  - Patient document uploads (images, PDFs)
  - Document metadata and processing status
  - Used by: `/documents` routes
  
- **Batches** (via `mongo_service.py`)
  - Document upload batches
  - Batch processing status tracking
  - Used by: `/documents` routes
  
- **Timelines** (via `mongo_service.py`)
  - AI-generated medical timelines
  - Generated from document batches
  - Used by: `/documents` routes

### What's Still in JSON Files ❌
- **Patients** (`patients.json`)
  - Patient registration data (name, UHID, age, gender, phone)
  - Used by: `/patients` routes, patient registration
  
- **Queue** (`queue.json`)
  - Patient queue management
  - Queue status tracking (waiting, nurse_completed, ready_for_doctor, etc.)
  - Used by: `/queue` routes, nurse workflow
  
- **Notes** (`notes.json`)
  - SOAP notes from nurse-patient interactions
  - Organized by patient_id
  - Used by: `/notes` routes
  
- **History** (`history.json`)
  - Patient medical history entries
  - Prescriptions, previous visits
  - Used by: `/patients` routes

---

## 🎯 Why Migrate to MongoDB?

### Current Problems with JSON:
1. **Race Conditions**: Multiple writes can corrupt data
2. **No Transactions**: Can't ensure data consistency across operations
3. **Poor Performance**: Entire file loaded for every operation
4. **No Indexing**: Slow lookups as data grows
5. **No Relationships**: Can't query across patient + queue + notes efficiently
6. **Manual Backups**: No built-in backup/restore

### MongoDB Benefits:
1. **ACID Transactions**: Guaranteed data integrity
2. **Indexing**: Fast queries even with millions of records
3. **Relationships**: Can reference patients in queue entries
4. **Scalability**: Handles growth automatically
5. **Real-time**: Change streams for live updates (MQTT alternative!)
6. **Backups**: Automatic snapshots and point-in-time recovery

---

## 🏗️ Migration Strategy

### Phase 1: Create MongoDB Collections (30 min)
Create new collections matching current JSON structure:
- `patients` collection
- `queue` collection  
- `notes` collection
- `history` collection

### Phase 2: Implement MongoDB Storage Class (1 hour)
Create hybrid storage class that reads from MongoDB, falls back to JSON

### Phase 3: Migrate Existing Data (15 min)
Write script to copy JSON data → MongoDB

### Phase 4: Update Routes (30 min)
Switch routes to use MongoDB storage

### Phase 5: Test & Deploy (30 min)
Verify all endpoints work with MongoDB

---

## 📝 Detailed Implementation Plan

### Collection Schemas

#### Patients Collection
```javascript
{
  _id: ObjectId("..."),
  patient_id: "PAT_72D90B86",  // Keep existing IDs for compatibility
  uhid: "123456789",
  name: "John Doe",
  age: 45,
  gender: "M",
  phone: "+919876543210",
  created_at: ISODate("2024-11-08T..."),
  updated_at: ISODate("2024-11-08T...")
}

// Indexes:
// - patient_id (unique)
// - uhid (unique)
```

#### Queue Collection
```javascript
{
  _id: ObjectId("..."),
  queue_id: "Q_722CC780",  // Keep existing IDs
  patient_id: "PAT_31A6F86D",  // Reference to patients
  patient_name: "Rishi Ahuja",
  token_number: 3,
  priority: "normal",
  status: "waiting",  // enum: waiting, nurse_completed, ready_for_doctor, in_consultation, completed, cancelled
  added_at: ISODate("..."),
  started_at: ISODate("..."),
  nurse_completed_at: ISODate("..."),
  timeline_ready_at: ISODate("..."),
  completed_at: ISODate("...")
}

// Indexes:
// - queue_id (unique)
// - patient_id
// - status
// - added_at (for ordering)
```

#### Notes Collection
```javascript
{
  _id: ObjectId("..."),
  note_id: "NOTE_ABC123",  // New unique ID
  patient_id: "PAT_72D90B86",  // Reference to patients
  type: "SOAP",  // or "audio_transcription", "manual"
  content: {
    subjective: "Patient complains of...",
    objective: "Vitals: BP 120/80...",
    assessment: "Diagnosis: Hypertension",
    plan: "Prescribe medication..."
  },
  audio_file_url: "s3://bucket/...",  // If from audio
  created_by: "nurse_rekha",
  created_at: ISODate("..."),
  updated_at: ISODate("...")
}

// Indexes:
// - patient_id
// - created_at (for timeline)
```

#### History Collection
```javascript
{
  _id: ObjectId("..."),
  history_id: "HIST_XYZ789",  // New unique ID
  patient_id: "PAT_72D90B86",  // Reference to patients
  type: "prescription",  // or "diagnosis", "visit", "lab_result"
  date: ISODate("2024-01-15T..."),
  content: {
    medications: ["Paracetamol 500mg", "..."],
    diagnoses: ["Fever", "..."],
    doctor: "Dr. Priya",
    notes: "Follow up in 2 weeks"
  },
  source: "digitizer",  // or "manual", "import"
  document_id: "DOC_123",  // Reference to documents if digitized
  created_at: ISODate("..."),
  updated_at: ISODate("...")
}

// Indexes:
// - patient_id
// - date (for timeline sorting)
// - type
```

---

## 🔧 Implementation Files

### File 1: `/simple_backend/app/services/mongodb_storage.py`
Complete MongoDB storage service with:
- Connection management
- CRUD operations for all 4 collections
- Index creation
- Query helpers

### File 2: `/simple_backend/app/services/migration_script.py`
One-time script to:
- Read all JSON files
- Transform data to MongoDB schema
- Insert into collections
- Verify migration success

### File 3: Update existing routes
- `/app/routes/patients.py` - Use MongoDB storage
- `/app/routes/queue.py` - Use MongoDB storage
- `/app/routes/notes.py` - Use MongoDB storage

---

## ⚡ Quick Start: Best Migration Approach

### Option 1: **Hybrid Approach** (RECOMMENDED - Safest)
1. Keep JSON files as backup
2. Implement MongoDB storage
3. Write to BOTH MongoDB and JSON
4. Read from MongoDB, fallback to JSON
5. After 1 week of testing, remove JSON writes

**Pros:** Zero-downtime, easy rollback
**Cons:** Double writes (temporary)

### Option 2: **Clean Migration** (Faster but riskier)
1. Take backup of JSON files
2. Migrate all data at once
3. Switch to MongoDB immediately
4. Keep JSON as emergency backup

**Pros:** Clean codebase immediately
**Cons:** Need downtime, harder to rollback

---

## 🎯 Recommended Next Steps

1. **Implement `mongodb_storage.py`** (the new storage class)
2. **Create migration script** to copy JSON → MongoDB
3. **Update one route at a time** (start with patients)
4. **Test thoroughly**
5. **Repeat for queue, notes, history**

Would you like me to:
1. ✅ Implement the complete `mongodb_storage.py` file?
2. ✅ Create the migration script?
3. ✅ Update routes to use MongoDB?

Let me know and I'll start coding!
