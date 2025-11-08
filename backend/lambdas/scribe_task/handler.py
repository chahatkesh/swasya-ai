"""
Lambda Function: AI Scribe Task
Purpose: Convert audio recordings into structured SOAP notes
Trigger: S3 upload to audio bucket

Pipeline:
Audio File → Amazon Transcribe (Speech-to-Text) → Gemini API (Structure) → DynamoDB
"""

import json
import boto3
import time
import os
import google.generativeai as genai
from datetime import datetime

# Get configuration from environment variables
AWS_REGION = os.environ.get('AWS_REGION', 'eu-north-1')
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')

if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY environment variable is required")

# Initialize AWS clients
s3_client = boto3.client('s3', region_name=AWS_REGION)
transcribe_client = boto3.client('transcribe', region_name=AWS_REGION)
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
notes_table = dynamodb.Table('PatientNotes')

# Configure Gemini API
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-2.5-flash')  # Latest Gemini 2.5 Flash model


def lambda_handler(event, context):
    """
    Main handler - triggered when audio file is uploaded to S3
    
    Event structure (S3 trigger):
    {
        'Records': [{
            's3': {
                'bucket': {'name': 'phc-audio-uploads-...'},
                'object': {'key': 'PAT_12345/audio_1699401600.mp3'}
            }
        }]
    }
    """
    
    print(f"Received S3 event: {json.dumps(event)}")
    
    try:
        # Step 1: Extract S3 bucket and file info from event
        record = event['Records'][0]
        bucket_name = record['s3']['bucket']['name']
        file_key = record['s3']['object']['key']  # e.g., PAT_12345/audio_1699401600.mp3
        
        print(f"Processing audio file: s3://{bucket_name}/{file_key}")
        
        # Extract patient_id from file path
        patient_id = file_key.split('/')[0]  # PAT_12345
        
        # Step 2: Start transcription job
        print("Starting Amazon Transcribe job...")
        transcript_text = transcribe_audio(bucket_name, file_key)
        
        if not transcript_text:
            raise Exception("Transcription failed or returned empty text")
        
        print(f"Transcription completed. Length: {len(transcript_text)} characters")
        print(f"Transcript preview: {transcript_text[:200]}...")
        
        # Step 3: Send to Gemini to structure into SOAP note
        print("Sending to Gemini for structuring...")
        soap_note = generate_soap_note(transcript_text)
        
        print(f"SOAP note generated: {json.dumps(soap_note, indent=2)}")
        
        # Step 4: Save to DynamoDB
        timestamp = int(datetime.now().timestamp())
        notes_table.put_item(
            Item={
                'patient_id': patient_id,
                'timestamp': timestamp,
                'soap_note': soap_note,
                'raw_transcript': transcript_text,
                'audio_url': f"s3://{bucket_name}/{file_key}",
                'status': 'completed',
                'created_at': datetime.now().isoformat()
            }
        )
        
        print(f"✅ Successfully saved SOAP note for {patient_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'success': True,
                'patient_id': patient_id,
                'message': 'SOAP note generated successfully'
            })
        }
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }


def transcribe_audio(bucket_name, file_key):
    """
    Use Amazon Transcribe to convert audio to text
    
    Supports: Hindi, English, and Indian English
    """
    
    # Create unique job name
    job_name = f"transcribe_{int(time.time())}_{file_key.replace('/', '_')}"
    
    # S3 URI for the audio file
    audio_uri = f"s3://{bucket_name}/{file_key}"
    
    print(f"Starting transcription job: {job_name}")
    print(f"Audio URI: {audio_uri}")
    
    try:
        # Start transcription job
        transcribe_client.start_transcription_job(
            TranscriptionJobName=job_name,
            Media={'MediaFileUri': audio_uri},
            MediaFormat='mp3',  # Adjust based on your audio format
            LanguageCode='hi-IN',  # Hindi - change to 'en-IN' for English
            Settings={
                'ShowSpeakerLabels': True,  # Identify different speakers
                'MaxSpeakerLabels': 2       # Nurse + Patient
            }
        )
        
        # Wait for job to complete
        print("Waiting for transcription to complete...")
        max_wait_time = 300  # 5 minutes
        wait_interval = 5    # Check every 5 seconds
        elapsed_time = 0
        
        while elapsed_time < max_wait_time:
            status = transcribe_client.get_transcription_job(
                TranscriptionJobName=job_name
            )
            
            job_status = status['TranscriptionJob']['TranscriptionJobStatus']
            
            if job_status == 'COMPLETED':
                # Get the transcript
                transcript_uri = status['TranscriptionJob']['Transcript']['TranscriptFileUri']
                
                # Download transcript JSON
                import urllib.request
                with urllib.request.urlopen(transcript_uri) as response:
                    transcript_data = json.loads(response.read())
                
                # Extract just the text
                transcript_text = transcript_data['results']['transcripts'][0]['transcript']
                
                print(f"✅ Transcription completed!")
                return transcript_text
            
            elif job_status == 'FAILED':
                failure_reason = status['TranscriptionJob'].get('FailureReason', 'Unknown')
                raise Exception(f"Transcription failed: {failure_reason}")
            
            # Still in progress
            print(f"Status: {job_status}... waiting {wait_interval}s")
            time.sleep(wait_interval)
            elapsed_time += wait_interval
        
        raise Exception("Transcription timed out")
        
    except Exception as e:
        print(f"Transcription error: {str(e)}")
        raise


def generate_soap_note(transcript_text):
    """
    Use Gemini to convert messy transcript into structured SOAP note
    
    SOAP format:
    - S (Subjective): What patient says (symptoms, complaints)
    - O (Objective): What nurse observes (vitals, physical exam)
    - A (Assessment): Diagnosis/impression
    - P (Plan): Treatment plan
    """
    
    prompt = f"""You are an expert medical scribe working in a Primary Healthcare Center in India.

IMPORTANT CONTEXT:
- The conversation below is a SPEECH-TO-TEXT TRANSCRIPT from an audio recording between a nurse and a patient
- The transcript may contain errors, mishearings, incomplete sentences, and background noise artifacts
- Medicine names are OFTEN INCORRECT in STT - use your medical knowledge to correct common Indian medicine names
- The conversation may be in Hindi, English, or mixed (Hinglish)
- Infer and extract medical information even from casual, colloquial language

TASK:
Convert this messy nurse-patient conversation into a clean, structured SOAP note.

CONVERSATION TRANSCRIPT (RAW STT OUTPUT):
{transcript_text}

INSTRUCTIONS:
1. **Subjective**: Extract what the PATIENT says about their symptoms, complaints, history. Infer duration, severity, and triggers even if not explicitly stated.
2. **Objective**: Extract what the NURSE observes or measures - vitals (BP, temp, pulse), physical examination findings, visible symptoms. If not mentioned, write "Physical examination pending".
3. **Assessment**: Make a preliminary diagnosis or health assessment based on symptoms. Always provide your best medical inference - never leave empty.
4. **Plan**: Extract treatment recommendations, medicine prescriptions, follow-up instructions. Correct medicine names if they appear garbled (e.g., "Para sit a mole" → "Paracetamol", "met for min" → "Metformin").
5. **Chief Complaint**: One concise sentence summarizing the main medical issue.

MEDICINE NAME CORRECTION EXAMPLES:
- "para sit a mole", "para c tamol" → "Paracetamol"
- "met for min", "metform in" → "Metformin"
- "amal dip in", "a modo pin" → "Amlodipine"
- "see pro flex a sin", "sipro" → "Ciprofloxacin"
- "az throw my sin" → "Azithromycin"
- "d cloud phenac" → "Diclofenac"

Return ONLY valid JSON in this exact format (no markdown, no code blocks):
{{
    "subjective": "Patient's main complaints and symptoms in 1-2 sentences",
    "objective": "Observable findings like vitals, physical examination",
    "assessment": "Preliminary diagnosis or health assessment",
    "plan": "Treatment plan and follow-up instructions",
    "chief_complaint": "One-line summary of main issue",
    "language_detected": "hindi" or "english"
}}

NEVER use "Not documented" - always infer something meaningful from the conversation.
Keep it concise, medically accurate, and professionally worded.
"""
    
    try:
        print("Calling Gemini API...")
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        
        # Remove markdown code blocks if present
        if response_text.startswith('```'):
            response_text = response_text.split('```')[1]
            if response_text.startswith('json'):
                response_text = response_text[4:]
            response_text = response_text.strip()
        
        # Parse JSON
        soap_note = json.loads(response_text)
        
        print("✅ Gemini successfully generated SOAP note")
        return soap_note
        
    except json.JSONDecodeError as e:
        print(f"❌ Gemini returned invalid JSON: {response_text}")
        # Return a fallback structure
        return {
            "subjective": transcript_text[:500],
            "objective": "Not documented",
            "assessment": "Requires doctor review",
            "plan": "To be determined by physician",
            "chief_complaint": "See transcript",
            "error": "Failed to structure note",
            "raw_gemini_response": response_text[:500]
        }
    
    except Exception as e:
        print(f"❌ Gemini API error: {str(e)}")
        raise
