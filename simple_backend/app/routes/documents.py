"""
Document scanning and timeline generation routes
"""

from fastapi import APIRouter, File, UploadFile, HTTPException, BackgroundTasks
from app.services.mongodb_storage import mongodb_storage
from app.services.ai_service import extract_prescription
from app.services.mongo_service import mongo_service
from app.services.timeline_service import generate_comprehensive_timeline
import uuid
import os
from datetime import datetime
from typing import Optional

router = APIRouter(prefix="/documents", tags=["Document Scanning & Timeline"])

UPLOADS_DIR = "/app/data/uploads"
os.makedirs(UPLOADS_DIR, exist_ok=True)


@router.post("/{patient_id}/start-batch", response_model=dict)
async def start_document_batch(patient_id: str):
    """
    Start a new document scanning batch for a patient
    
    Call this when nurse starts scanning multiple documents.
    Returns a batch_id to use for subsequent uploads.
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    # Verify patient exists
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Check if there's already an active batch
    existing_batch = await mongo_service.get_active_batch(patient_id)
    if existing_batch:
        return {
            "success": True,
            "message": "Batch already active",
            "batch_id": existing_batch['batch_id'],
            "document_count": len(existing_batch.get('document_ids', []))
        }
    
    # Create new batch
    batch_id = f"BATCH_{uuid.uuid4().hex[:8].upper()}"
    batch_data = {
        "batch_id": batch_id,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "document_ids": [],
        "status": "pending",
        "created_at": datetime.now().isoformat(),
        "completed_at": None
    }
    
    await mongo_service.create_batch(batch_data)
    
    print(f"📋 Started document batch: {batch_id} for {patient['name']}")
    
    return {
        "success": True,
        "message": "Document batch started",
        "batch_id": batch_id,
        "patient_id": patient_id,
        "patient_name": patient['name']
    }


@router.post("/{patient_id}/upload", response_model=dict)
async def upload_document_to_batch(
    patient_id: str,
    file: UploadFile = File(...),
    batch_id: Optional[str] = None
):
    """
    Upload a single document to patient's scanning batch
    
    Each document is processed individually and added to the batch.
    Documents are processed in the background.
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    
    **Query Parameters:**
    - batch_id: Optional batch ID (will create new if not provided)
    
    **File Upload:**
    - Supported formats: jpg, jpeg, png, pdf
    - Max size: 10MB
    """
    
    print(f"\n🔍 [UPLOAD] Received upload request:")
    print(f"   Patient ID: {patient_id}")
    print(f"   Batch ID param: {batch_id}")
    print(f"   Filename: {file.filename}")
    
    # Verify patient exists
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Get or create batch
    if not batch_id:
        print(f"⚠️ [UPLOAD] No batch_id provided, looking for active batch...")
        # Try to get active batch
        existing_batch = await mongo_service.get_active_batch(patient_id)
        if existing_batch:
            batch_id = existing_batch['batch_id']
            print(f"✅ [UPLOAD] Found active batch: {batch_id}")
        else:
            # Create new batch
            batch_id = f"BATCH_{uuid.uuid4().hex[:8].upper()}"
            batch_data = {
                "batch_id": batch_id,
                "patient_id": patient_id,
                "patient_name": patient['name'],
                "document_ids": [],
                "status": "pending",
                "created_at": datetime.now().isoformat()
            }
            await mongo_service.create_batch(batch_data)
            print(f"🆕 [UPLOAD] Created new batch: {batch_id}")
    else:
        print(f"✅ [UPLOAD] Using provided batch_id: {batch_id}")
    
    # Validate file type
    file_extension = file.filename.split('.')[-1].lower()
    allowed_extensions = ['jpg', 'jpeg', 'png', 'pdf']
    allowed_types = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf']
    
    if file_extension not in allowed_extensions and file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: jpg, jpeg, png, pdf"
        )
    
    try:
        # Save image file
        document_id = f"DOC_{uuid.uuid4().hex[:8].upper()}"
        image_filename = f"{patient_id}_{document_id}.{file_extension}"
        image_path = os.path.join(UPLOADS_DIR, image_filename)
        
        print("\n" + "🟢" * 40)
        print(f"📤 NEW DOCUMENT UPLOAD")
        print(f"   Document ID: {document_id}")
        print(f"   Patient: {patient['name']} ({patient_id})")
        print(f"   Batch ID: {batch_id}")
        print(f"   Filename: {file.filename}")
        print(f"   Saved as: {image_filename}")
        print("🟢" * 40 + "\n")
        
        with open(image_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        print(f"✅ File saved to disk: {image_path}")
        
        # Create document record
        document_data = {
            "document_id": document_id,
            "patient_id": patient_id,
            "batch_id": batch_id,
            "image_file": image_filename,
            "image_path": image_path,
            "status": "processing",
            "uploaded_at": datetime.now().isoformat(),
            "extracted_data": None
        }
        
        await mongo_service.save_document(document_data)
        await mongo_service.add_document_to_batch(batch_id, document_id)
        
        # Extract prescription data (async in background)
        try:
            prescription_data = await extract_prescription(image_path)
            await mongo_service.update_document_status(
                document_id, 
                "completed", 
                prescription_data
            )
            print(f"✅ Document processed: {document_id}")
        except Exception as e:
            await mongo_service.update_document_status(document_id, "failed")
            print(f"❌ Document processing failed: {e}")
            prescription_data = {"error": str(e)}
        
        # Get updated batch info
        batch = await mongo_service.get_batch(batch_id)
        
        return {
            "success": True,
            "message": "Document uploaded and processed",
            "document_id": document_id,
            "batch_id": batch_id,
            "document_number": len(batch.get('document_ids', [])),
            "extracted_data": prescription_data
        }
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error uploading document: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to process document: {str(e)}")


@router.post("/{patient_id}/complete-batch", response_model=dict)
async def complete_batch_and_generate_timeline(patient_id: str, batch_id: Optional[str] = None):
    """
    Complete document scanning and generate comprehensive timeline
    
    Call this when nurse has finished scanning all documents.
    This will:
    1. Mark batch as completed
    2. Gather all extracted data
    3. Generate comprehensive medical timeline using Gemini
    4. Save timeline to MongoDB
    5. Store summary in patient history
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    
    **Query Parameters:**
    - batch_id: Optional batch ID (will use active batch if not provided)
    """
    
    # Verify patient exists
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Get batch
    if not batch_id:
        batch = await mongo_service.get_active_batch(patient_id)
        if not batch:
            raise HTTPException(status_code=404, detail="No active document batch found")
        batch_id = batch['batch_id']
    else:
        batch = await mongo_service.get_batch(batch_id)
        if not batch:
            raise HTTPException(status_code=404, detail=f"Batch {batch_id} not found")
    
    try:
        # Get all documents in batch
        documents = await mongo_service.get_batch_documents(batch_id)
        
        if not documents:
            raise HTTPException(status_code=400, detail="No documents in batch")
        
        print("\n" + "🔵" * 40)
        print(f"📊 BATCH COMPLETION - Starting timeline generation")
        print(f"   Patient: {patient['name']} ({patient_id})")
        print(f"   Batch ID: {batch_id}")
        print(f"   Documents in batch: {len(documents)}")
        for i, doc in enumerate(documents, 1):
            print(f"   Doc {i}: {doc.get('document_id')} - uploaded at {doc.get('uploaded_at', 'unknown')}")
            print(f"           Has extracted_data: {bool(doc.get('extracted_data'))}")
        print("🔵" * 40 + "\n")
        
        # Update batch status
        await mongo_service.update_batch_status(batch_id, "processing")
        
        # Generate comprehensive timeline
        timeline_data = await generate_comprehensive_timeline(documents, patient)
        
        # Save timeline to MongoDB
        timeline_record = {
            "patient_id": patient_id,
            "patient_name": patient['name'],
            "batch_id": batch_id,
            "generated_at": datetime.now().isoformat(),
            "total_documents": len(documents),
            **timeline_data
        }
        
        await mongo_service.save_timeline(timeline_record)
        
        # Also save summary to JSON storage (for backwards compatibility)
        history_id = f"TIMELINE_{uuid.uuid4().hex[:8].upper()}"
        history_entry = {
            "history_id": history_id,
            "patient_id": patient_id,
            "created_at": datetime.now().isoformat(),
            "batch_id": batch_id,
            "type": "comprehensive_timeline",
            "document_count": len(documents),
            "timeline_summary": timeline_data.get('summary'),
            "event_count": len(timeline_data.get('timeline_events', [])),
            "current_medications_count": len(timeline_data.get('current_medications', []))
        }
        
        await mongodb_storage.add_history(patient_id, history_entry)
        
        # Mark batch as completed
        await mongo_service.update_batch_status(batch_id, "completed")
        
        print(f"✅ Timeline generated and saved!")
        
        return {
            "success": True,
            "message": "Timeline generated successfully",
            "batch_id": batch_id,
            "timeline_id": history_id,
            "statistics": {
                "documents_processed": len(documents),
                "timeline_events": len(timeline_data.get('timeline_events', [])),
                "current_medications": len(timeline_data.get('current_medications', [])),
                "chronic_conditions": len(timeline_data.get('chronic_conditions', []))
            },
            "timeline": timeline_data
        }
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Timeline generation error: {e}")
        await mongo_service.update_batch_status(batch_id, "failed")
        raise HTTPException(status_code=500, detail=f"Failed to generate timeline: {str(e)}")


@router.get("/{patient_id}/timeline", response_model=dict)
async def get_patient_timeline(patient_id: str):
    """
    Get patient's AI-generated medical timeline
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    timeline = await mongo_service.get_patient_timeline(patient_id)
    
    if not timeline:
        return {
            "success": True,
            "message": "No timeline generated yet",
            "timeline": None
        }
    
    # Remove MongoDB _id field
    timeline.pop('_id', None)
    
    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "timeline": timeline
    }


@router.get("/{patient_id}/documents", response_model=dict)
async def get_patient_documents(patient_id: str):
    """
    Get all scanned documents for a patient
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    documents = await mongo_service.get_patient_documents(patient_id)
    
    # Remove MongoDB _id fields
    for doc in documents:
        doc.pop('_id', None)
    
    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "document_count": len(documents),
        "documents": documents
    }


@router.get("/{patient_id}/batches", response_model=dict)
async def get_patient_batches(patient_id: str):
    """
    Get all document batches for a patient
    
    **Path Parameters:**
    - patient_id: Patient's unique identifier
    """
    
    patient = await mongodb_storage.get_patient(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found")
    
    # Get all batches from MongoDB
    all_batches = await mongo_service.db.batches.find(
        {"patient_id": patient_id}
    ).sort("created_at", -1).to_list(length=None)
    
    # Remove MongoDB _id fields
    for batch in all_batches:
        batch.pop('_id', None)
    
    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": patient['name'],
        "batch_count": len(all_batches),
        "batches": all_batches
    }
