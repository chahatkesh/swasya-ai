"""
Basic endpoint tests for PHC AI Co-Pilot Backend

These tests verify that all endpoints are accessible and return expected response structures.
They use mock data and don't require actual API keys for basic structure validation.
"""

import pytest
from fastapi.testclient import TestClient
import os
import json
import tempfile
import shutil

# Setup test environment before importing app
test_dir = tempfile.mkdtemp()
os.environ['GEMINI_API_KEY'] = 'test_key'
os.environ['GROQ_API_KEY'] = 'test_key'

# Mock the config module before importing
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Create a test config
test_config = f"""
import os
BASE_DIR = "{test_dir}"
PATIENTS_FILE = "{test_dir}/patients.json"
QUEUE_FILE = "{test_dir}/queue.json"
NOTES_FILE = "{test_dir}/notes.json"
HISTORY_FILE = "{test_dir}/history.json"
UPLOADS_DIR = "{test_dir}/uploads"
GEMINI_API_KEY = "test_key"
GROQ_API_KEY = "test_key"
"""

with open(os.path.join(os.path.dirname(__file__), 'config_test.py'), 'w') as f:
    f.write(test_config)

# Replace config import in modules
import config
config.BASE_DIR = test_dir
config.PATIENTS_FILE = f"{test_dir}/patients.json"
config.QUEUE_FILE = f"{test_dir}/queue.json"
config.NOTES_FILE = f"{test_dir}/notes.json"
config.HISTORY_FILE = f"{test_dir}/history.json"
config.UPLOADS_DIR = f"{test_dir}/uploads"

# Now import the app
from main_refactored import app

client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_and_teardown():
    """Setup and teardown for each test"""
    # Setup: Create necessary directories and files
    os.makedirs(config.UPLOADS_DIR, exist_ok=True)
    for file_path in [config.PATIENTS_FILE, config.QUEUE_FILE, config.NOTES_FILE, config.HISTORY_FILE]:
        if not os.path.exists(file_path):
            with open(file_path, 'w') as f:
                json.dump({} if file_path != config.QUEUE_FILE else [], f)
    
    yield
    
    # Teardown: Clean up test files
    if os.path.exists(test_dir):
        shutil.rmtree(test_dir)
        os.makedirs(test_dir)


def test_root_endpoint():
    """Test the root endpoint returns service info"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "PHC AI Co-Pilot"
    assert data["version"] == "2.0.0"
    assert "stats" in data
    assert "features" in data


def test_health_check():
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "services" in data


def test_register_patient():
    """Test patient registration"""
    patient_data = {
        "name": "Test Patient",
        "phone": "9876543210",
        "age": 30,
        "gender": "Male"
    }
    response = client.post("/patients", json=patient_data)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "patient_id" in data
    assert data["patient_id"].startswith("PAT_")


def test_list_patients():
    """Test listing patients"""
    # First register a patient
    patient_data = {
        "name": "Test Patient",
        "phone": "9876543210"
    }
    client.post("/patients", json=patient_data)
    
    # Then list patients
    response = client.get("/patients")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "patients" in data
    assert data["count"] >= 1


def test_get_patient():
    """Test getting patient details"""
    # First register a patient
    patient_data = {
        "name": "Test Patient",
        "phone": "9876543210"
    }
    reg_response = client.post("/patients", json=patient_data)
    patient_id = reg_response.json()["patient_id"]
    
    # Then get patient details
    response = client.get(f"/patients/{patient_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["patient"]["patient_id"] == patient_id


def test_get_nonexistent_patient():
    """Test getting a non-existent patient returns 404"""
    response = client.get("/patients/PAT_INVALID")
    assert response.status_code == 404


def test_add_to_queue():
    """Test adding patient to queue"""
    # First register a patient
    patient_data = {
        "name": "Test Patient",
        "phone": "9876543210"
    }
    reg_response = client.post("/patients", json=patient_data)
    patient_id = reg_response.json()["patient_id"]
    
    # Add to queue
    queue_data = {
        "patient_id": patient_id,
        "priority": "normal"
    }
    response = client.post("/queue/add", json=queue_data)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "queue_entry" in data


def test_get_queue():
    """Test getting queue status"""
    response = client.get("/queue")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "queue" in data
    assert "stats" in data


def test_queue_operations():
    """Test full queue workflow: add -> start -> complete"""
    # Register patient
    patient_data = {
        "name": "Test Patient",
        "phone": "9876543210"
    }
    reg_response = client.post("/patients", json=patient_data)
    patient_id = reg_response.json()["patient_id"]
    
    # Add to queue
    queue_data = {"patient_id": patient_id}
    add_response = client.post("/queue/add", json=queue_data)
    queue_id = add_response.json()["queue_entry"]["queue_id"]
    
    # Start consultation
    start_response = client.post(f"/queue/{queue_id}/start")
    assert start_response.status_code == 200
    assert start_response.json()["success"] is True
    
    # Complete consultation
    complete_response = client.post(f"/queue/{queue_id}/complete")
    assert complete_response.status_code == 200
    assert complete_response.json()["success"] is True


def test_duplicate_queue_entry():
    """Test that adding same patient twice to queue fails"""
    # Register patient
    patient_data = {
        "name": "Test Patient",
        "phone": "9876543210"
    }
    reg_response = client.post("/patients", json=patient_data)
    patient_id = reg_response.json()["patient_id"]
    
    # Add to queue first time
    queue_data = {"patient_id": patient_id}
    client.post("/queue/add", json=queue_data)
    
    # Try to add again - should fail
    response = client.post("/queue/add", json=queue_data)
    assert response.status_code == 400


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
