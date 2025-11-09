"""
Document processing and timeline generation service
"""

import google.generativeai as genai
from typing import List, Dict
import json


async def generate_comprehensive_timeline(documents: List[Dict], patient_info: Dict) -> Dict:
    """
    Generate comprehensive medical timeline from multiple documents
    
    Args:
        documents: List of processed document data
        patient_info: Patient basic information
    
    Returns:
        Comprehensive medical timeline with chronological events
    """
    
    # Combine all extracted data
    all_prescriptions = []
    for doc in documents:
        if doc.get('extracted_data'):
            all_prescriptions.append(doc['extracted_data'])
    
    print("=" * 80)
    print("📋 TIMELINE GENERATION - INPUT DATA")
    print("=" * 80)
    print(f"Patient: {patient_info.get('name')} (Age: {patient_info.get('age')})")
    print(f"Total documents: {len(documents)}")
    print(f"Documents with extracted data: {len(all_prescriptions)}")
    print("\n🔍 EXTRACTED PRESCRIPTIONS:")
    for i, presc in enumerate(all_prescriptions, 1):
        print(f"\n--- Prescription {i} ---")
        print(f"  Doctor: {presc.get('doctor_name', 'Unknown')}")
        print(f"  Date: {presc.get('date', 'Unknown')}")
        print(f"  Diagnosis: {presc.get('diagnosis', 'Unknown')}")
        print(f"  Medications: {len(presc.get('medications', []))}")
        for med in presc.get('medications', []):
            print(f"    - {med.get('name')}: {med.get('dosage')} {med.get('frequency')}")
    print("=" * 80)
    
    # Create comprehensive prompt for Gemini
    prompt = f"""You are a medical data analyst. Analyze these prescription documents and create a comprehensive medical timeline.

PATIENT: {patient_info.get('name', 'Unknown')} (Age: {patient_info.get('age', 'Unknown')})

PRESCRIPTION DOCUMENTS:
{json.dumps(all_prescriptions, indent=2)}

Create a structured medical timeline with the following:

1. **Timeline Events**: Chronological list of all medical visits/prescriptions
2. **Current Medications**: Active medications the patient should be taking
3. **Chronic Conditions**: Any recurring health issues mentioned
4. **Medication History**: All medications prescribed over time
5. **Important Notes**: Drug allergies, special instructions, patterns

Return ONLY valid JSON (no markdown):
{{
    "timeline_events": [
        {{
            "date": "YYYY-MM-DD or approximate",
            "event_type": "prescription|diagnosis|visit",
            "description": "Brief description",
            "medications": [
                {{
                    "name": "Medicine name",
                    "dosage": "Dosage",
                    "frequency": "TDS/BD/OD",
                    "duration": "Duration",
                    "prescribed_date": "Date",
                    "doctor": "Doctor name"
                }}
            ],
            "doctor": "Doctor name",
            "notes": "Additional notes"
        }}
    ],
    "current_medications": [
        {{
            "name": "Active medicine",
            "dosage": "Dosage",
            "frequency": "Frequency",
            "duration": "Ongoing",
            "prescribed_date": "Latest date",
            "doctor": "Latest doctor"
        }}
    ],
    "chronic_conditions": ["Condition 1", "Condition 2"],
    "allergies": ["Known allergies if mentioned"],
    "summary": "2-3 sentence comprehensive medical summary of the patient's health history"
}}

Important:
- Sort timeline events chronologically (oldest to newest)
- Identify currently active medications
- Note any concerning patterns or drug interactions
- If dates are unclear, estimate based on context
"""
    
    try:
        print("\n" + "=" * 80)
        print("🤖 SENDING TO GEMINI - FULL PROMPT")
        print("=" * 80)
        print(prompt)
        print("=" * 80)
        print("\n🔄 Calling Gemini API...")
        
        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        response = model.generate_content(prompt)
        text = response.text.strip()
        
        print("\n" + "=" * 80)
        print("📥 GEMINI RESPONSE - RAW TEXT")
        print("=" * 80)
        print(text[:1000])  # First 1000 chars
        if len(text) > 1000:
            print(f"\n... (response truncated, total {len(text)} chars)")
        print("=" * 80)
        
        # Clean markdown if present
        if text.startswith('```'):
            text = text.split('```')[1]
            if text.startswith('json'):
                text = text[4:]
            text = text.strip()
        
        timeline_data = json.loads(text)
        
        print("\n" + "=" * 80)
        print("✅ PARSED TIMELINE DATA")
        print("=" * 80)
        print(f"Timeline events: {len(timeline_data.get('timeline_events', []))}")
        print(f"Current medications: {len(timeline_data.get('current_medications', []))}")
        print(f"Chronic conditions: {len(timeline_data.get('chronic_conditions', []))}")
        print(f"Allergies: {len(timeline_data.get('allergies', []))}")
        print(f"Has summary: {bool(timeline_data.get('summary'))}")
        print("=" * 80 + "\n")
        
        return timeline_data
    
    except Exception as e:
        print(f"❌ Timeline generation error: {e}")
        # Return fallback structure
        return {
            "timeline_events": [
                {
                    "date": "Unknown",
                    "event_type": "prescription",
                    "description": f"Document {i+1}",
                    "medications": doc.get('extracted_data', {}).get('medications', []),
                    "doctor": doc.get('extracted_data', {}).get('doctor_name'),
                    "notes": "Extracted from scanned document"
                }
                for i, doc in enumerate(documents)
                if doc.get('extracted_data')
            ],
            "current_medications": [],
            "chronic_conditions": [],
            "allergies": [],
            "summary": f"Patient has {len(documents)} prescription documents on file. Individual analysis completed.",
            "error": str(e)
        }
