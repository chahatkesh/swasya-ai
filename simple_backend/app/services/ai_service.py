"""
Service layer for AI operations (Transcription and OCR)
"""

import json
import os
from groq import Groq
import google.generativeai as genai
from typing import Dict

# Initialize clients
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')
GROQ_API_KEY = os.environ.get('GROQ_API_KEY')

if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found in environment")
if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY not found in environment")

genai.configure(api_key=GEMINI_API_KEY)
gemini_model = genai.GenerativeModel('gemini-2.5-flash')
groq_client = Groq(api_key=GROQ_API_KEY)


async def transcribe_audio(file_path: str) -> str:
    """
    Use Groq Whisper to transcribe audio file
    
    Args:
        file_path: Path to audio file (mp3, m4a, wav)
    
    Returns:
        Transcribed text
    """
    try:
        print(f"🎙️ Transcribing audio with Groq Whisper...")
        
        with open(file_path, "rb") as audio_file:
            transcription = groq_client.audio.transcriptions.create(
                file=audio_file,
                model="whisper-large-v3-turbo",
                response_format="json",
                language="hi"  # Hindi
            )
        
        transcript = transcription.text
        print(f"✅ Transcription complete: {len(transcript)} characters")
        return transcript
    
    except Exception as e:
        print(f"❌ Transcription error: {e}")
        return f"[Transcription failed: {str(e)}]"


async def generate_soap_note(transcript: str) -> Dict:
    """
    Convert transcript to structured SOAP note using Gemini
    
    Args:
        transcript: Transcribed conversation text
    
    Returns:
        Dictionary containing SOAP note fields
    """
    
    prompt = f"""You are a medical scribe at a Primary Healthcare Center in India.

Convert this conversation between nurse and patient into a structured SOAP note.

CONVERSATION:
{transcript}

Return ONLY valid JSON (no markdown, no code blocks):
{{
    "subjective": "Patient's main complaints and symptoms in their own words",
    "objective": "Observable facts: vitals, physical examination findings",
    "assessment": "Likely diagnosis or medical assessment",
    "plan": "Treatment plan, medications, follow-up instructions",
    "chief_complaint": "Primary reason for visit (one sentence)",
    "medications": ["List any medications mentioned"],
    "language": "hindi/english/mixed"
}}

Be concise and professional. Extract only medical information.
"""
    
    try:
        print(f"🤖 Generating SOAP note with Gemini...")
        response = gemini_model.generate_content(prompt)
        text = response.text.strip()
        
        # Clean markdown code blocks if present
        if text.startswith('```'):
            text = text.split('```')[1]
            if text.startswith('json'):
                text = text[4:]
            text = text.strip()
        
        soap_note = json.loads(text)
        print(f"✅ SOAP note generated successfully")
        return soap_note
    
    except Exception as e:
        print(f"⚠️ SOAP generation error: {e}")
        # Return fallback structure
        return {
            "subjective": transcript[:200] + "...",
            "objective": "Pending examination",
            "assessment": "Requires physician review",
            "plan": "To be determined by doctor",
            "chief_complaint": "See full transcript",
            "medications": [],
            "language": "unknown",
            "error": str(e)
        }


async def extract_prescription(image_path: str) -> Dict:
    """
    Extract prescription details from image using Gemini Vision
    
    Args:
        image_path: Path to prescription image
    
    Returns:
        Dictionary containing extracted prescription data
    """
    
    try:
        print(f"📸 Extracting prescription with Gemini Vision...")
        
        # Upload image to Gemini
        image_file = genai.upload_file(image_path)
        
        prompt = """You are extracting information from a medical prescription image.
This may be handwritten or printed, possibly in Hindi or English.

Extract ALL visible information and return ONLY valid JSON (no markdown):
{
    "doctor_name": "Doctor's name if visible",
    "date": "Prescription date if visible (DD/MM/YYYY format)",
    "medications": [
        {
            "name": "Medicine name",
            "dosage": "e.g., 500mg, 10ml",
            "frequency": "e.g., TDS (3x/day), BD (2x/day), OD (1x/day)",
            "duration": "e.g., 5 days, 1 week"
        }
    ],
    "diagnosis": "Condition/disease mentioned",
    "instructions": "Special instructions (e.g., take after food)"
}

If information is not clearly visible, use "Not visible" or leave empty array.
"""
        
        response = gemini_model.generate_content([prompt, image_file])
        text = response.text.strip()
        
        # Clean markdown code blocks
        if text.startswith('```'):
            text = text.split('```')[1]
            if text.startswith('json'):
                text = text[4:]
            text = text.strip()
        
        prescription_data = json.loads(text)
        print(f"✅ Prescription extracted: {len(prescription_data.get('medications', []))} medications found")
        return prescription_data
    
    except Exception as e:
        print(f"❌ Prescription extraction error: {e}")
        return {
            "doctor_name": "Unknown",
            "date": "Unknown",
            "medications": [],
            "diagnosis": "Could not extract",
            "instructions": "",
            "error": str(e)
        }
