# Queue Workflow Analysis & Recommendations

## Current Issues

### Issue #1: New Patients Not Added to Queue ❌

**Current Behavior:**
```
Nurse registers NEW patient → Patient created in DB with status "active"
→ Timeline generated → Patient NEVER enters queue
→ Doctor has no way to see this patient
```

**Problem:** Only RETURNING patients (who come back) are added to queue via `_addToQueue()`. New patients skip the queue entirely.

**Evidence:**
- `patient_registration_screen.dart` line 108-132: New patient registration does NOT call `addToQueue()`
- `patient_registration_screen.dart` line 148-176: Only existing patients call `_addToQueue()`

---

### Issue #2: Missing Intermediate Status ❌

**Current Queue Status Flow:**
```
waiting → in_progress → completed
```

**Problem:** This flow assumes:
1. Patient joins queue BEFORE nurse does anything (but new patients don't!)
2. Doctor starts consultation BEFORE timeline is ready (but timeline generates async!)
3. No status for "nurse finished, waiting for doctor"

**What's Actually Happening:**
1. Nurse registers patient → `patients` table (not in queue)
2. Nurse records audio/scans → uploads happen
3. Nurse clicks "Finish" → Timeline generates (10-30 sec)
4. **No status to show "ready for doctor to review"**
5. Doctor somehow magically knows to review?

---

### Issue #3: Completed Entries Never Removed ❌

**Current Behavior:**
```
Doctor clicks "Complete" → Status = "completed"
→ Entry stays in queue table forever
→ Queue gets cluttered with old entries
```

**Problem:** 
- Backend has `/queue/cleanup` endpoint to remove completed entries
- But it's NEVER called by frontend
- Queue display will show completed patients indefinitely

---

## Recommended Solution

### New Status Flow

```
┌─────────────────────┐
│ Nurse registers     │
│ new patient         │
└──────┬──────────────┘
       │
       ↓
┌─────────────────────┐
│ Status: waiting     │ ← Patient immediately enters queue
│ Queue Table         │
└──────┬──────────────┘
       │
       ↓ Nurse scans/records
       │
┌─────────────────────┐
│ Status:             │ ← Nurse clicks "Send to Doctor"
│ nurse_completed     │    Timeline generated
└──────┬──────────────┘
       │
       ↓ Timeline ready
       │
┌─────────────────────┐
│ Status:             │ ← Auto-transition when timeline ready
│ ready_for_doctor    │    Doctor can now see patient
└──────┬──────────────┘
       │
       ↓ Doctor clicks "Start"
       │
┌─────────────────────┐
│ Status:             │ ← Doctor reviewing patient
│ in_consultation     │
└──────┬──────────────┘
       │
       ↓ Doctor clicks "Complete"
       │
┌─────────────────────┐
│ Status: completed   │ ← Auto-cleanup after 5 minutes
│ (Removed from queue)│
└─────────────────────┘
```

### Detailed Status Definitions

| Status | Description | Who Sets It | Next Action |
|--------|-------------|-------------|-------------|
| `waiting` | Patient just registered, nurse hasn't started work | System (auto on registration) | Nurse starts scanning/recording |
| `nurse_completed` | Nurse finished, timeline generating | Nurse (clicks "Send to Doctor") | Wait for timeline generation |
| `ready_for_doctor` | Timeline ready, waiting for doctor | System (auto when timeline ready) | Doctor starts consultation |
| `in_consultation` | Doctor actively reviewing patient | Doctor (clicks "Start") | Doctor completes treatment |
| `completed` | Consultation finished | Doctor (clicks "Complete") | Auto-cleanup after delay |

---

## Implementation Changes

### 1. Backend Changes

#### A. Update QueueStatus Enum
**File:** `simple_backend/app/models/schemas.py`

```python
class QueueStatus(str, Enum):
    """Queue status options"""
    WAITING = "waiting"                    # NEW: Just registered
    NURSE_COMPLETED = "nurse_completed"    # NEW: Nurse clicked "Send to Doctor"
    READY_FOR_DOCTOR = "ready_for_doctor"  # NEW: Timeline ready for review
    IN_CONSULTATION = "in_consultation"    # RENAMED: from "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
```

#### B. Update Patient Registration to Auto-Queue
**File:** `simple_backend/app/routes/patients.py`

```python
@router.post("", response_model=dict)
def register_patient(patient: PatientCreate):
    # ... existing registration code ...
    
    # NEW: Auto-add to queue
    queue_id = f"Q_{uuid.uuid4().hex[:8].upper()}"
    queue = storage.get_queue()
    active_queue = [q for q in queue if q['status'] != 'completed']
    token_number = len(active_queue) + 1
    
    queue_entry = {
        "queue_id": queue_id,
        "patient_id": patient_id,
        "patient_name": patient.name,
        "token_number": token_number,
        "priority": "normal",
        "status": QueueStatus.WAITING,
        "added_at": datetime.now().isoformat(),
    }
    
    storage.add_to_queue(queue_entry)
    
    return {
        "success": True,
        "patient_id": patient_id,
        "queue_id": queue_id,  # NEW: Return queue_id
        "message": f"Patient registered and added to queue"
    }
```

#### C. Add "Send to Doctor" Endpoint
**File:** `simple_backend/app/routes/queue.py`

```python
@router.post("/{queue_id}/nurse-complete", response_model=dict)
def nurse_complete_patient(queue_id: str):
    """
    Nurse marks patient as completed (timeline will be generated)
    
    Changes status from 'waiting' → 'nurse_completed'
    """
    
    updated = storage.update_queue_status(
        queue_id,
        QueueStatus.NURSE_COMPLETED,
        nurse_completed_at=datetime.now().isoformat()
    )
    
    if not updated:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    print(f"✅ Nurse completed: {updated['patient_name']}")
    
    return {
        "success": True,
        "message": "Patient ready for timeline generation",
        "queue_entry": updated
    }
```

#### D. Update Timeline Generation to Set Ready Status
**File:** `simple_backend/app/routes/documents.py`

After timeline generation succeeds, update queue status:

```python
@router.post("/{patient_id}/complete-batch")
async def complete_batch_and_generate_timeline(...):
    # ... existing timeline generation ...
    
    # NEW: Update queue status to ready_for_doctor
    queue = storage.get_queue()
    patient_queue = next(
        (q for q in queue if q['patient_id'] == patient_id and q['status'] == QueueStatus.NURSE_COMPLETED), 
        None
    )
    
    if patient_queue:
        storage.update_queue_status(
            patient_queue['queue_id'],
            QueueStatus.READY_FOR_DOCTOR,
            timeline_ready_at=datetime.now().isoformat()
        )
        print(f"✅ Patient {patient_id} ready for doctor review")
    
    return response
```

#### E. Rename "start" to match new status
**File:** `simple_backend/app/routes/queue.py`

```python
@router.post("/{queue_id}/start", response_model=dict)
def start_consultation(queue_id: str):
    """
    Doctor starts consultation
    
    Changes status from 'ready_for_doctor' → 'in_consultation'
    """
    
    # Check if another consultation is in progress
    in_progress = storage.get_queue_by_status(QueueStatus.IN_CONSULTATION)
    if in_progress:
        raise HTTPException(
            status_code=400, 
            detail=f"Another patient is already in consultation"
        )
    
    updated = storage.update_queue_status(
        queue_id, 
        QueueStatus.IN_CONSULTATION,
        started_at=datetime.now().isoformat()
    )
    
    if not updated:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    return {
        "success": True,
        "message": "Consultation started",
        "queue_entry": updated
    }
```

#### F. Auto-Cleanup Completed Entries
**File:** `simple_backend/app/routes/queue.py`

Add background task or modify complete endpoint:

```python
@router.post("/{queue_id}/complete", response_model=dict)
def complete_consultation(queue_id: str, auto_cleanup: bool = True):
    """
    Mark consultation as completed
    
    Optionally removes from queue after delay
    """
    
    updated = storage.update_queue_status(
        queue_id,
        QueueStatus.COMPLETED,
        completed_at=datetime.now().isoformat()
    )
    
    if not updated:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    print(f"✅ Consultation completed: {updated['patient_name']}")
    
    # NEW: Schedule cleanup if enabled
    if auto_cleanup:
        # In production, use background task or celery
        # For MVP, can cleanup immediately or after short delay
        pass
    
    return {
        "success": True,
        "message": "Consultation completed",
        "queue_entry": updated
    }
```

---

### 2. Frontend Changes (Nurse App)

#### A. Store queue_id with patient
**File:** `mobile/nurse_app/lib/screens/patient_registration_screen.dart`

```dart
Future<void> _registerPatient() async {
  // ... existing code ...
  
  final response = await ApiService.registerPatient(...);
  final patientId = response['patient_id'];
  final queueId = response['queue_id'];  // NEW
  
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_patient_id', patientId);
  await prefs.setString('current_queue_id', queueId);  // NEW
  // ... rest of code ...
}
```

#### B. Add "Send to Doctor" Button
**File:** `mobile/nurse_app/lib/screens/patient_detail_screen.dart`

Add new action button:

```dart
// NEW ACTION BUTTON
_ActionButton(
  icon: Icons.send,
  label: 'Send to Doctor',
  color: AppColors.accent,
  description: 'Complete processing & send to doctor',
  onPressed: _sendToDoctor,
),

// NEW METHOD
Future<void> _sendToDoctor() async {
  final prefs = await SharedPreferences.getInstance();
  final queueId = prefs.getString('current_queue_id');
  
  if (queueId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Queue ID not found')),
    );
    return;
  }
  
  try {
    await ApiService.nurseCompletePatient(queueId);
    
    // Show success message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Patient Sent to Doctor'),
        content: Text('Timeline is being generated. Doctor will be notified when ready.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

#### C. Add API Method
**File:** `mobile/nurse_app/lib/services/api_service.dart`

```dart
/// Nurse marks patient as complete (ready for doctor)
static Future<Map<String, dynamic>> nurseCompletePatient(String queueId) async {
  try {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/queue/$queueId/nurse-complete'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to mark patient complete: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error marking patient complete: $e');
  }
}
```

---

### 3. Frontend Changes (Doctor Dashboard)

#### A. Display Queue by Status

```javascript
// GET /queue returns all patients with their status
const queue = await fetch('/queue').then(r => r.json());

// Filter by status
const readyForDoctor = queue.queue.filter(p => p.status === 'ready_for_doctor');
const inConsultation = queue.queue.filter(p => p.status === 'in_consultation');
const nurseWorking = queue.queue.filter(p => p.status === 'waiting' || p.status === 'nurse_completed');

// Display in UI
<div className="queue-section">
  <h3>Ready for Review ({readyForDoctor.length})</h3>
  {readyForDoctor.map(patient => <PatientCard patient={patient} />)}
</div>
```

#### B. "Start Consultation" Button

```javascript
async function startConsultation(queueId, patientId) {
  // Update queue status
  await fetch(`/queue/${queueId}/start`, { method: 'POST' });
  
  // Load patient timeline
  const timeline = await fetch(`/documents/${patientId}/timeline`).then(r => r.json());
  
  // Display timeline in UI
  displayTimeline(timeline);
}
```

#### C. "Complete Consultation" Button

```javascript
async function completeConsultation(queueId) {
  await fetch(`/queue/${queueId}/complete`, { method: 'POST' });
  
  // Patient automatically removed from active queue
  // Refresh queue display
  refreshQueue();
}
```

---

## Migration Path

### Phase 1: Backend Updates (Do First)
1. ✅ Update `QueueStatus` enum with new statuses
2. ✅ Modify patient registration to auto-add to queue
3. ✅ Add `/queue/{queue_id}/nurse-complete` endpoint
4. ✅ Update timeline generation to set `ready_for_doctor` status
5. ✅ Test all endpoints with Postman/curl

### Phase 2: Mobile App Updates
1. ✅ Store `queue_id` after registration
2. ✅ Add "Send to Doctor" button in patient detail screen
3. ✅ Add `nurseCompletePatient()` API method
4. ✅ Test full nurse workflow

### Phase 3: Doctor Dashboard
1. ✅ Filter queue by status
2. ✅ Add "Start" button for `ready_for_doctor` patients
3. ✅ Add "Complete" button during consultation
4. ✅ Auto-refresh queue display

---

## Testing Checklist

### Nurse Flow
- [ ] Register new patient → Patient appears in queue with status `waiting`
- [ ] Record audio/scan documents → Status stays `waiting`
- [ ] Click "Send to Doctor" → Status changes to `nurse_completed`
- [ ] Wait for timeline → Status auto-changes to `ready_for_doctor`
- [ ] Return to home → Patient removed from nurse's active list

### Doctor Flow
- [ ] See patient with status `ready_for_doctor`
- [ ] Click "Start" → Status changes to `in_consultation`
- [ ] View timeline → All data visible
- [ ] Click "Complete" → Status changes to `completed`
- [ ] Patient removed from queue display

### Edge Cases
- [ ] Two doctors try to start consultation with same patient
- [ ] Nurse tries to send patient before uploading documents
- [ ] Timeline generation fails → Status doesn't get stuck
- [ ] Patient registration fails → Queue entry rolled back

---

## Summary

**Current Problems:**
1. ❌ New patients never enter queue
2. ❌ No "nurse completed, ready for doctor" status
3. ❌ Completed patients never removed from queue

**Solution:**
1. ✅ Auto-add all patients to queue on registration
2. ✅ Add intermediate statuses: `nurse_completed` → `ready_for_doctor`
3. ✅ Add "Send to Doctor" button for nurse
4. ✅ Auto-update status when timeline ready
5. ✅ Display queue by status in doctor dashboard
6. ✅ Auto-cleanup or manual cleanup of completed entries

**Next Steps:**
1. Review and approve this design
2. Implement backend changes first
3. Update mobile app
4. Create/update doctor dashboard
5. Test end-to-end workflow
