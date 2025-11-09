"""Configuration and constants for the application"""

import os

# Storage paths
BASE_DIR = "/app/data"
PATIENTS_FILE = f"{BASE_DIR}/patients.json"
QUEUE_FILE = f"{BASE_DIR}/queue.json"
NOTES_FILE = f"{BASE_DIR}/notes.json"
HISTORY_FILE = f"{BASE_DIR}/history.json"
UPLOADS_DIR = f"{BASE_DIR}/uploads"

# API Keys
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')
GROQ_API_KEY = os.environ.get('GROQ_API_KEY')
