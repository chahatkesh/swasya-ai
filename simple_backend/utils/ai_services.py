"""AI service integrations for Whisper transcription and Gemini Vision"""

import json
from typing import Dict
import google.generativeai as genai
from groq import Groq
from config import GEMINI_API_KEY, GROQ_API_KEY

# Initialize AI clients
if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found")
if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY not found")

genai.configure(api_key=GEMINI_API_KEY)
gemini_model = genai.GenerativeModel('gemini-2.0-flash-exp')
groq_client = Groq(api_key=GROQ_API_KEY)


async def transcribe_audio(file_path: str) -> str:
    """Use Groq Whisper to transcribe audio"""
    try:
        # Validate file exists and is within expected directory
        import os
        if not os.path.exists(file_path):
            raise ValueError("File not found")
        
        print(f"🎙️ Transcribing with Groq Whisper...")
        
        with open(file_path, "rb") as audio_file:
            transcription = groq_client.audio.transcriptions.create(
                file=audio_file,
                model="whisper-large-v3-turbo",
                response_format="json",
                language="hi"  # Hindi
            )
        
        transcript = transcription.text
        print(f"✅ Transcribed: {len(transcript)} chars")
        return transcript
    
    except Exception as e:
        print(f"❌ Transcription error: {e}")
        return f"[Transcription failed: {str(e)}]"


async def generate_soap_note(transcript: str) -> Dict:
    """Use Gemini to convert transcript to SOAP note"""
    
    prompt = f"""You are a medical scribe at a Primary Healthcare Center in India.

Convert this conversation into a structured SOAP note in JSON format.

CONVERSATION:
{transcript}

Return ONLY valid JSON (no markdown):
{{
    "subjective": "Patient's main complaints",
    "objective": "Vitals and observations",
    "assessment": "Diagnosis",
    "plan": "Treatment plan",
    "chief_complaint": "Main issue",
    "medications": ["List medications if mentioned"],
    "language": "hindi/english"
}}
"""
    
    try:
        response = gemini_model.generate_content(prompt)
        text = response.text.strip()
        
        if text.startswith('```'):
            text = text.split('```')[1]
            if text.startswith('json'):
                text = text[4:]
            text = text.strip()
        
        return json.loads(text)
    except Exception as e:
        print(f"Error generating SOAP note: {e}")
        return {
            "subjective": transcript[:200],
            "objective": "Pending",
            "assessment": "Requires review",
            "plan": "TBD",
            "chief_complaint": "See transcript",
            "medications": [],
            "language": "unknown",
            "error": "Failed to generate structured note"
        }


async def extract_prescription(image_path: str) -> Dict:
    """Use Gemini Vision to extract prescription details"""
    
    try:
        print(f"📸 Extracting prescription with Gemini Vision...")
        
        # Upload image to Gemini
        image_file = genai.upload_file(image_path)
        
        prompt = """Extract all information from this medical prescription image.

Return ONLY valid JSON (no markdown):
{
    "doctor_name": "Doctor's name",
    "date": "Date if visible",
    "medications": [
        {
            "name": "Medicine name",
            "dosage": "500mg",
            "frequency": "TDS/BD/OD",
            "duration": "3 days"
        }
    ],
    "diagnosis": "Condition if mentioned",
    "instructions": "Special instructions"
}
"""
        
        response = gemini_model.generate_content([prompt, image_file])
        text = response.text.strip()
        
        if text.startswith('```'):
            text = text.split('```')[1]
            if text.startswith('json'):
                text = text[4:]
            text = text.strip()
        
        return json.loads(text)
    
    except Exception as e:
        print(f"Error extracting prescription: {e}")
        return {
            "doctor_name": "Unknown",
            "date": "Unknown",
            "medications": [],
            "diagnosis": "Could not extract",
            "instructions": "",
            "error": "Failed to extract prescription details"
        }
