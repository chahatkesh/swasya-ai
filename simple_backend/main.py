"""PHC AI Co-Pilot Backend - Refactored Modular Version
Features: Queue Management, Groq Whisper, Gemini Vision, Real-time Updates
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import json
import os

# Import configuration
from config import (
    BASE_DIR, PATIENTS_FILE, QUEUE_FILE, NOTES_FILE, 
    HISTORY_FILE, UPLOADS_DIR
)

# Import routers
from routes import health, patients, queue, uploads

# Load environment variables
load_dotenv()

# Initialize FastAPI
app = FastAPI(
    title="PHC AI Co-Pilot Backend",
    description="Complete backend with queue management, Whisper transcription, and Gemini Vision OCR",
    version="2.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create directories
os.makedirs(BASE_DIR, exist_ok=True)
os.makedirs(UPLOADS_DIR, exist_ok=True)

# Initialize storage
for file_path in [PATIENTS_FILE, QUEUE_FILE, NOTES_FILE, HISTORY_FILE]:
    if not os.path.exists(file_path):
        with open(file_path, 'w') as f:
            json.dump({} if file_path != QUEUE_FILE else [], f)

# Register routers
app.include_router(health.router)
app.include_router(patients.router)
app.include_router(queue.router)
app.include_router(uploads.router)

# Also register the /notes endpoint at the root level for backward compatibility
@app.get("/notes/{patient_id}")
def get_notes_compat(patient_id: str):
    """Backward compatibility endpoint - redirects to uploads.get_patient_notes"""
    from routes.uploads import get_patient_notes
    return get_patient_notes(patient_id)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
