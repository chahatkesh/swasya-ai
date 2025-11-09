"""
Patient Report Generation Routes
Comprehensive medical reports for PDF generation
"""

from fastapi import APIRouter, HTTPException, Query
from app.services.mongodb_storage import mongodb_storage
from datetime import datetime
from typing import Optional, Dict, List
import json

router = APIRouter(prefix="/report", tags=["Reports"])


@router.get("", response_model=dict)
async def generate_patient_report(uhid: str = Query(..., description="Patient's UHID")):
    """
    Generate comprehensive patient medical report for PDF generation
    
    **Query Parameters:**
    - uhid: Patient's Government Health ID (REQUIRED)
    
    **Returns:**
    Detailed patient analysis including:
    - Complete demographic information
    - Full medical history timeline
    - All SOAP notes with trends
    - Prescription history and medication patterns
    - Visit frequency analysis
    - Health risk indicators
    - Symptom patterns
    
    **Use Case:**
    Frontend calls this endpoint to get all data needed for a beautiful PDF report
    """
    
    # Step 1: Get patient by UHID
    patient = await mongodb_storage.get_patient_by_uhid(uhid)
    if not patient:
        raise HTTPException(
            status_code=404, 
            detail=f"Patient with UHID {uhid} not found in system"
        )
    
    patient_id = patient['patient_id']
    print(f"📋 Generating comprehensive report for {patient['name']} (UHID: {uhid})")
    
    # Step 2: Get all medical data
    notes = await mongodb_storage.get_patient_notes(patient_id)
    history = await mongodb_storage.get_patient_history(patient_id)
    queue = await mongodb_storage.get_queue()
    
    # Step 3: Calculate actual visit count (notes are the source of truth)
    actual_visit_count = len(notes)
    last_visit_date = notes[-1].get('created_at') if notes else patient.get('last_visit')
    
    # Step 4: Analyze and structure the report
    report = {
        "report_generated_at": datetime.now().isoformat(),
        "report_id": f"REPORT_{patient_id}_{int(datetime.now().timestamp())}",
        
        # === PATIENT DEMOGRAPHICS ===
        "patient_info": {
            "uhid": patient['uhid'],
            "patient_id": patient['patient_id'],
            "name": patient['name'],
            "phone": patient.get('phone', 'Not provided'),
            "age": patient.get('age', 'Not provided'),
            "gender": patient.get('gender', 'Not specified'),
            "registration_date": patient.get('created_at'),
            "status": patient.get('status', 'active'),
            "total_visits": actual_visit_count,  # Use actual notes count
            "last_visit": last_visit_date
        },
        
        # === VISIT STATISTICS ===
        "statistics": _calculate_statistics(patient, notes, history),
        
        # === COMPLETE MEDICAL TIMELINE ===
        "medical_timeline": _build_medical_timeline(notes, history),
        
        # === SOAP NOTES ANALYSIS ===
        "clinical_summary": _analyze_soap_notes(notes),
        
        # === PRESCRIPTION & MEDICATION HISTORY ===
        "medication_history": _analyze_medications(history),
        
        # === HEALTH TRENDS & PATTERNS ===
        "health_patterns": _identify_health_patterns(notes),
        
        # === CURRENT STATUS ===
        "current_status": _get_current_status(patient_id, queue, notes),
        
        # === RAW DATA (for detailed PDF sections) ===
        "raw_data": {
            "all_notes": notes,
            "all_prescriptions": history,
            "notes_count": len(notes),
            "prescriptions_count": len(history)
        }
    }
    
    print(f"✅ Report generated successfully - {len(notes)} notes, {len(history)} prescriptions")
    
    return {
        "success": True,
        "uhid": uhid,
        "patient_name": patient['name'],
        "report": report
    }


def _calculate_statistics(patient: Dict, notes: List[Dict], history: List[Dict]) -> Dict:
    """Calculate visit and treatment statistics"""
    
    # Parse dates
    try:
        registration = datetime.fromisoformat(patient.get('created_at', ''))
        days_registered = (datetime.now() - registration).days
        visit_frequency = len(notes) / max(days_registered / 30, 1)  # Visits per month
    except:
        days_registered = 0
        visit_frequency = 0
    
    return {
        "total_visits": len(notes),
        "total_prescriptions": len(history),
        "days_as_patient": days_registered,
        "average_visits_per_month": round(visit_frequency, 2),
        "first_visit_date": notes[0].get('created_at') if notes else None,
        "most_recent_visit": notes[-1].get('created_at') if notes else None,
        "visit_dates": [note.get('created_at') for note in notes]
    }


def _build_medical_timeline(notes: List[Dict], history: List[Dict]) -> List[Dict]:
    """Create chronological medical timeline combining notes and prescriptions"""
    
    timeline = []
    
    # Add SOAP notes
    for note in notes:
        soap = note.get('soap_note', {})
        # Get timestamp or parse from created_at, fallback to 0
        timestamp = note.get('timestamp')
        if timestamp is None and note.get('created_at'):
            try:
                timestamp = int(datetime.fromisoformat(note.get('created_at')).timestamp())
            except:
                timestamp = 0
        elif timestamp is None:
            timestamp = 0
            
        timeline.append({
            "type": "consultation",
            "date": note.get('created_at'),
            "timestamp": timestamp,
            "chief_complaint": soap.get('chief_complaint', 'Not documented'),
            "assessment": soap.get('assessment', 'Not documented'),
            "plan": soap.get('plan', 'Not documented'),
            "medications": soap.get('medications', []),
            "language": soap.get('language', 'unknown'),
            "full_soap": soap
        })
    
    # Add prescription history
    for entry in history:
        prescription = entry.get('prescription_data', {})
        # Get timestamp or parse from created_at, fallback to 0
        timestamp = entry.get('timestamp')
        if timestamp is None and entry.get('created_at'):
            try:
                timestamp = int(datetime.fromisoformat(entry.get('created_at')).timestamp())
            except:
                timestamp = 0
        elif timestamp is None:
            timestamp = 0
            
        timeline.append({
            "type": "prescription",
            "date": entry.get('created_at'),
            "timestamp": timestamp,
            "doctor": prescription.get('doctor_name', 'Unknown'),
            "diagnosis": prescription.get('diagnosis', 'Not specified'),
            "medications": prescription.get('medications', []),
            "image_url": entry.get('image_url')
        })
    
    # Sort by timestamp (newest first) - all timestamps are now integers
    timeline.sort(key=lambda x: x['timestamp'], reverse=True)
    
    return timeline


def _analyze_soap_notes(notes: List[Dict]) -> Dict:
    """Analyze SOAP notes for patterns and insights"""
    
    if not notes:
        return {
            "total_consultations": 0,
            "common_complaints": [],
            "assessments_made": [],
            "treatment_approaches": []
        }
    
    # Extract all fields
    complaints = []
    assessments = []
    plans = []
    all_medications = []
    
    for note in notes:
        soap = note.get('soap_note', {})
        
        if soap.get('chief_complaint'):
            complaints.append(soap['chief_complaint'])
        
        if soap.get('assessment'):
            assessments.append(soap['assessment'])
        
        if soap.get('plan'):
            plans.append(soap['plan'])
        
        if soap.get('medications'):
            all_medications.extend(soap['medications'])
    
    # Find most common items
    from collections import Counter
    
    return {
        "total_consultations": len(notes),
        "common_complaints": _get_top_items(complaints, 5),
        "common_assessments": _get_top_items(assessments, 5),
        "treatment_approaches": _get_top_items(plans, 3),
        "medications_prescribed": _get_top_items(all_medications, 10),
        "latest_complaint": complaints[-1] if complaints else "No recent visits",
        "latest_assessment": assessments[-1] if assessments else "No recent assessment",
        "language_breakdown": _count_languages(notes)
    }


def _analyze_medications(history: List[Dict]) -> Dict:
    """Analyze medication patterns from prescription history"""
    
    if not history:
        return {
            "total_prescriptions": 0,
            "unique_medications": [],
            "medication_frequency": {},
            "prescribing_doctors": []
        }
    
    all_meds = []
    doctors = []
    
    for entry in history:
        prescription = entry.get('prescription_data', {})
        
        meds = prescription.get('medications', [])
        all_meds.extend([m.get('name', str(m)) for m in meds if m])
        
        doctor = prescription.get('doctor_name')
        if doctor and doctor != 'Unknown':
            doctors.append(doctor)
    
    from collections import Counter
    med_counter = Counter(all_meds)
    
    return {
        "total_prescriptions": len(history),
        "unique_medications": list(set(all_meds)),
        "unique_medication_count": len(set(all_meds)),
        "most_prescribed": [{"medication": med, "times_prescribed": count} 
                           for med, count in med_counter.most_common(10)],
        "prescribing_doctors": list(set(doctors)),
        "doctor_visits": dict(Counter(doctors))
    }


def _identify_health_patterns(notes: List[Dict]) -> Dict:
    """Identify health trends and patterns from visit history"""
    
    if len(notes) < 2:
        return {
            "pattern_analysis": "Insufficient data for pattern analysis (need at least 2 visits)"
        }
    
    # Analyze visit frequency
    dates = []
    for note in notes:
        try:
            date = datetime.fromisoformat(note.get('created_at', ''))
            dates.append(date)
        except:
            pass
    
    dates.sort()
    
    # Calculate gaps between visits
    gaps = []
    for i in range(1, len(dates)):
        gap = (dates[i] - dates[i-1]).days
        gaps.append(gap)
    
    avg_gap = sum(gaps) / len(gaps) if gaps else 0
    
    # Extract subjective symptoms over time
    symptoms_trend = []
    for note in notes:
        soap = note.get('soap_note', {})
        symptoms_trend.append({
            "date": note.get('created_at'),
            "complaint": soap.get('chief_complaint', 'Not documented'),
            "subjective": soap.get('subjective', '')[:100]  # First 100 chars
        })
    
    return {
        "visit_frequency_pattern": "Regular" if avg_gap < 60 else "Occasional",
        "average_days_between_visits": round(avg_gap, 1),
        "total_days_span": (dates[-1] - dates[0]).days if len(dates) > 1 else 0,
        "symptoms_over_time": symptoms_trend[-5:],  # Last 5 visits
        "pattern_insights": _generate_pattern_insights(notes, avg_gap)
    }


def _get_current_status(patient_id: str, queue: List[Dict], notes: List[Dict]) -> Dict:
    """Get patient's current status in the system"""
    
    # Check if in queue
    queue_entry = next((q for q in queue if q['patient_id'] == patient_id), None)
    
    # Get last visit
    last_visit = notes[-1] if notes else None
    last_visit_date = None
    if last_visit:
        try:
            last_visit_date = datetime.fromisoformat(last_visit.get('created_at', ''))
            days_since = (datetime.now() - last_visit_date).days
        except:
            days_since = None
    else:
        days_since = None
    
    return {
        "in_queue": queue_entry is not None,
        "queue_status": queue_entry.get('status') if queue_entry else None,
        "queue_token": queue_entry.get('token_number') if queue_entry else None,
        "last_visit_date": last_visit_date.isoformat() if last_visit_date else None,
        "days_since_last_visit": days_since,
        "follow_up_due": days_since > 30 if days_since else False
    }


def _get_top_items(items: List[str], top_n: int) -> List[Dict]:
    """Get top N most common items with counts"""
    from collections import Counter
    counter = Counter(items)
    return [{"item": item, "count": count} for item, count in counter.most_common(top_n)]


def _count_languages(notes: List[Dict]) -> Dict:
    """Count language distribution in consultations"""
    from collections import Counter
    languages = [note.get('soap_note', {}).get('language', 'unknown') for note in notes]
    return dict(Counter(languages))


def _generate_pattern_insights(notes: List[Dict], avg_gap: float) -> str:
    """Generate natural language insights about health patterns"""
    
    insights = []
    
    if avg_gap < 15:
        insights.append("Frequent visits indicate ongoing health monitoring or chronic condition management.")
    elif avg_gap < 60:
        insights.append("Regular check-ups suggest proactive health management.")
    else:
        insights.append("Occasional visits for acute conditions.")
    
    if len(notes) >= 3:
        # Check for recurring complaints
        complaints = [note.get('soap_note', {}).get('chief_complaint', '') for note in notes[-3:]]
        if len(set(complaints)) == 1:
            insights.append("Recurring complaint may indicate chronic condition requiring specialist referral.")
    
    return " ".join(insights)
