# Implementation Summary - Queue Workflow Updates

## ✅ Completed Changes

### Phase 1: Backend Updates (DONE)

#### 1. Updated Queue Status Enum (`app/models/schemas.py`)
```python
class QueueStatus(str, Enum):
    WAITING = "waiting"                    # Patient just registered
    NURSE_COMPLETED = "nurse_completed"    # NEW: Nurse finished
    READY_FOR_DOCTOR = "ready_for_doctor"  # NEW: Timeline ready
    IN_CONSULTATION = "in_consultation"    # Renamed from IN_PROGRESS
    COMPLETED = "completed"
    CANCELLED = "cancelled"
```

#### 2. Auto-Queue on Registration (`app/routes/patients.py`)
- **Changed**: `POST /patients` now automatically adds patient to queue
- **Returns**: `queue_id` in response (needed for nurse app)
- **Initial Status**: `waiting`

```python
# Auto-creates queue entry with:
- queue_id: "Q_XXXXXXXX"
- status: WAITING
- token_number: auto-assigned
```

#### 3. Added Nurse Complete Endpoint (`app/routes/queue.py`)
- **New Endpoint**: `POST /queue/{queue_id}/nurse-complete`
- **Status Flow**: `waiting` → `nurse_completed`
- **Called By**: Nurse app when clicking "Send to Doctor"

#### 4. Updated Existing Endpoints
- `GET /queue`: Now returns stats for all 6 statuses
- `GET /queue/current`: Uses `IN_CONSULTATION` instead of `IN_PROGRESS`
- `POST /queue/{queue_id}/start`: Uses `IN_CONSULTATION`, expects `ready_for_doctor`

### Phase 2: Mobile App Updates (DONE)

#### 1. Store queue_id After Registration
**File**: `lib/screens/patient_registration_screen.dart`

```dart
// NEW PATIENT
final queueId = response['queue_id'];
await prefs.setString('current_queue_id', queueId);

// RETURNING PATIENT
final queueId = response['queue_entry']['queue_id'];
await prefs.setString('current_queue_id', queueId);
```

#### 2. Added API Method
**File**: `lib/services/api_service.dart`

```dart
static Future<Map<String, dynamic>> nurseCompletePatient(String queueId) async {
  final response = await http.post(
    Uri.parse('${Config.apiBaseUrl}/queue/$queueId/nurse-complete'),
  );
  return jsonDecode(response.body);
}
```

#### 3. Added "Send to Doctor" Button
**File**: `lib/screens/patient_detail_screen.dart`

- New button with accent color (orange)
- Icon: `Icons.send_rounded`
- Calls `_sendToDoctor()` method
- Shows success dialog with next steps
- Navigates back to home screen

```dart
Future<void> _sendToDoctor() async {
  final queueId = prefs.getString('current_queue_id');
  await ApiService.nurseCompletePatient(queueId);
  // Show success dialog
  // Navigate to HomeScreen
}
```

### Phase 3: Documentation Updates (DONE)

#### Updated Files:
1. **`docs/MEDICAL_TIMELINE_API.md`**
   - Added workflow overview with status flow diagram
   - Documented new queue statuses
   - Added "Patient Registration (Auto-Queue)" section
   - Added "Nurse Complete Patient" endpoint
   - Updated all queue status examples
   - Updated integration examples for nurse app and doctor dashboard
   - Renumbered endpoints (now 0-9)

2. **`docs/QUEUE_WORKFLOW_ANALYSIS.md`**
   - Comprehensive analysis of issues
   - Detailed implementation plan
   - Migration path and testing checklist

---

## 🎯 Current Status Flow

```
┌─────────────────────┐
│ Nurse Registers     │  ← POST /patients
│ Patient             │
└──────┬──────────────┘
       │ Auto-queued
       ↓
┌─────────────────────┐
│ Status: waiting     │  ← Patient in queue, nurse working
│                     │
└──────┬──────────────┘
       │ Nurse clicks "Send to Doctor"
       ↓
┌─────────────────────┐
│ Status:             │  ← POST /queue/{id}/nurse-complete
│ nurse_completed     │     Timeline generating
└──────┬──────────────┘
       │ Timeline ready (auto-update)
       ↓
┌─────────────────────┐
│ Status:             │  ← POST /documents/{id}/complete-batch
│ ready_for_doctor    │     (Will be added in next phase)
└──────┬──────────────┘
       │ Doctor clicks "Start"
       ↓
┌─────────────────────┐
│ Status:             │  ← POST /queue/{id}/start
│ in_consultation     │
└──────┬──────────────┘
       │ Doctor clicks "Complete"
       ↓
┌─────────────────────┐
│ Status: completed   │  ← POST /queue/{id}/complete
└─────────────────────┘
```

---

## 🧪 Testing Instructions

### Backend Testing

1. **Test Patient Registration Auto-Queue**
```bash
curl -X POST http://localhost:8000/patients \
  -H "Content-Type: application/json" \
  -d '{
    "uhid": "TEST123",
    "name": "Test Patient",
    "phone": "9876543210",
    "age": 30,
    "gender": "male"
  }'

# Should return queue_id in response
# Should create queue entry with status "waiting"
```

2. **Test Nurse Complete**
```bash
curl -X POST http://localhost:8000/queue/Q_XXXXXXXX/nurse-complete

# Should change status from "waiting" to "nurse_completed"
```

3. **Test Queue Stats**
```bash
curl http://localhost:8000/queue

# Should show stats for all 6 statuses:
# - waiting
# - nurse_completed
# - ready_for_doctor
# - in_consultation
# - completed
# - cancelled
```

### Mobile App Testing

1. **Register New Patient**
   - Fill in patient details
   - Click "Register"
   - Check SharedPreferences for `current_queue_id`

2. **Send to Doctor**
   - Open patient detail screen
   - Record audio or scan documents
   - Click "Send to Doctor" button (orange)
   - Should show success dialog
   - Should navigate to home screen

3. **Verify Queue ID**
```dart
final prefs = await SharedPreferences.getInstance();
print(prefs.getString('current_queue_id')); // Should print Q_XXXXXXXX
```

---

## ⚠️ Still TODO (Next Phase)

### 1. Auto-Update to `ready_for_doctor`
**File**: `simple_backend/app/routes/documents.py`

After timeline generation succeeds in `POST /documents/{patient_id}/complete-batch`:
```python
# Update queue status
queue = storage.get_queue()
patient_queue = next(
    (q for q in queue if q['patient_id'] == patient_id 
     and q['status'] == QueueStatus.NURSE_COMPLETED), 
    None
)

if patient_queue:
    storage.update_queue_status(
        patient_queue['queue_id'],
        QueueStatus.READY_FOR_DOCTOR,
        timeline_ready_at=datetime.now().isoformat()
    )
```

### 2. Doctor Dashboard
- Filter queue by `ready_for_doctor` status
- Display only ready patients
- "Start" button → calls `/queue/{queue_id}/start`
- Display timeline
- "Complete" button → calls `/queue/{queue_id}/complete`

### 3. Optional: Auto-Cleanup
- Remove `completed` entries after some time
- Or add manual cleanup button in doctor dashboard
- Uses existing `/queue/cleanup` endpoint

---

## 📝 Key Changes Summary

| Component | What Changed | Status |
|-----------|-------------|--------|
| Queue Statuses | Added 2 new statuses, renamed 1 | ✅ Done |
| Patient Registration | Auto-adds to queue, returns queue_id | ✅ Done |
| Nurse Complete Endpoint | New endpoint for nurse workflow | ✅ Done |
| Mobile App - Registration | Stores queue_id | ✅ Done |
| Mobile App - Detail Screen | "Send to Doctor" button | ✅ Done |
| API Documentation | Complete update with new flow | ✅ Done |
| Timeline Auto-Update | Set `ready_for_doctor` after generation | ⏳ TODO |
| Doctor Dashboard | New UI with status filtering | ⏳ TODO |

---

## 🎉 Benefits

1. **Clear Status Flow**: Every step of patient journey is tracked
2. **No Manual Queue Addition**: Auto-queued on registration
3. **Nurse Efficiency**: Can immediately move to next patient
4. **Doctor Clarity**: Only sees patients ready for review
5. **Background Processing**: Timeline generates without blocking nurse
6. **Better Tracking**: Know exactly where each patient is in the process

---

## 📚 Documentation

All changes are documented in:
- `/docs/MEDICAL_TIMELINE_API.md` - Complete API reference
- `/docs/QUEUE_WORKFLOW_ANALYSIS.md` - Detailed analysis and implementation plan

Backend is running on: `http://localhost:8000`
API Documentation: `http://localhost:8000/docs`
