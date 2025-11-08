"""
Lambda Function: AI Digitizer Task
Purpose: Extract text from scanned documents and structure into medication history
Trigger: S3 upload to image bucket

Pipeline:
Image File → Amazon Textract (OCR) → Gemini API (Structure) → DynamoDB
"""

import json
import boto3
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
textract_client = boto3.client('textract', region_name=AWS_REGION)
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
history_table = dynamodb.Table('PatientHistory')

# Configure Gemini API
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-2.5-flash')  # Latest Gemini 2.5 Flash model


def lambda_handler(event, context):
    """
    Main handler - triggered when image is uploaded to S3
    
    Event structure (S3 trigger):
    {
        'Records': [{
            's3': {
                'bucket': {'name': 'phc-image-uploads-...'},
                'object': {'key': 'PAT_12345/doc_1699401600.jpg'}
            }
        }]
    }
    """
    
    print(f"Received S3 event: {json.dumps(event)}")
    
    try:
        # Step 1: Extract S3 info from event
        record = event['Records'][0]
        bucket_name = record['s3']['bucket']['name']
        file_key = record['s3']['object']['key']
        
        print(f"Processing image: s3://{bucket_name}/{file_key}")
        
        # Extract patient_id from file path
        patient_id = file_key.split('/')[0]
        
        # Step 2: Use Textract to extract text from image
        print("Starting Amazon Textract analysis...")
        extracted_text = extract_text_from_image(bucket_name, file_key)
        
        if not extracted_text:
            raise Exception("Textract returned no text")
        
        print(f"Text extracted. Length: {len(extracted_text)} characters")
        print(f"Preview: {extracted_text[:300]}...")
        
        # Step 3: Send to Gemini to structure into medication history
        print("Sending to Gemini for structuring...")
        medication_data = structure_medical_data(extracted_text)
        
        print(f"Structured data: {json.dumps(medication_data, indent=2)}")
        
        # Step 4: Save to DynamoDB
        timestamp = int(datetime.now().timestamp())
        history_table.put_item(
            Item={
                'patient_id': patient_id,
                'timestamp': timestamp,
                'medications': medication_data.get('medications', []),
                'diagnoses': medication_data.get('diagnoses', []),
                'dates': medication_data.get('dates', []),
                'extracted_text': extracted_text,
                'image_url': f"s3://{bucket_name}/{file_key}",
                'status': 'completed',
                'created_at': datetime.now().isoformat()
            }
        )
        
        print(f"✅ Successfully saved medical history for {patient_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'success': True,
                'patient_id': patient_id,
                'message': 'Medical document digitized successfully'
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


def extract_text_from_image(bucket_name, file_key):
    """
    Use Amazon Textract to extract text from image
    
    Textract can read:
    - Printed text
    - Handwritten text (with HANDWRITING feature)
    - Forms and tables
    """
    
    print(f"Calling Textract for s3://{bucket_name}/{file_key}")
    
    try:
        # Call Textract with handwriting detection enabled
        response = textract_client.analyze_document(
            Document={
                'S3Object': {
                    'Bucket': bucket_name,
                    'Name': file_key
                }
            },
            FeatureTypes=['FORMS', 'TABLES']  # Extract forms and tables too
        )
        
        # Extract all text blocks
        text_blocks = []
        
        for block in response['Blocks']:
            if block['BlockType'] == 'LINE':  # Each line of text
                text_blocks.append(block['Text'])
        
        # Combine all text
        full_text = '\n'.join(text_blocks)
        
        print(f"✅ Textract extracted {len(text_blocks)} lines of text")
        
        return full_text
        
    except Exception as e:
        print(f"❌ Textract error: {str(e)}")
        raise


def structure_medical_data(extracted_text):
    """
    Use Gemini to convert messy OCR text into structured medical data
    
    Goal: Extract medications, diagnoses, and dates from prescriptions/reports
    """
    
    prompt = f"""You are a medical data extraction specialist.

Extract structured information from this medical document OCR text.

EXTRACTED TEXT:
{extracted_text}

Return ONLY valid JSON in this exact format (no markdown, no code blocks):
{{
    "medications": [
        {{
            "name": "Medication name",
            "dosage": "Dosage (e.g., 500mg)",
            "frequency": "How often (e.g., twice daily)",
            "duration": "How long (e.g., 5 days)"
        }}
    ],
    "diagnoses": [
        "Diagnosis 1",
        "Diagnosis 2"
    ],
    "dates": [
        "Date found in document (YYYY-MM-DD format if possible)"
    ],
    "doctor_name": "Doctor's name if mentioned",
    "hospital_name": "Hospital/clinic name if mentioned",
    "document_type": "prescription" or "lab_report" or "diagnosis" or "other"
}}

If any field is not found, use an empty array [] or "Not found".
Be conservative - only extract information you're confident about.
"""
    
    try:
        print("Calling Gemini API for structuring...")
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        
        # Remove markdown code blocks if present
        if response_text.startswith('```'):
            response_text = response_text.split('```')[1]
            if response_text.startswith('json'):
                response_text = response_text[4:]
            response_text = response_text.strip()
        
        # Parse JSON
        medical_data = json.loads(response_text)
        
        print("✅ Gemini successfully structured medical data")
        return medical_data
        
    except json.JSONDecodeError as e:
        print(f"❌ Gemini returned invalid JSON: {response_text}")
        # Return fallback structure
        return {
            "medications": [],
            "diagnoses": ["Requires manual review"],
            "dates": [],
            "raw_text": extracted_text[:500],
            "error": "Failed to structure data",
            "raw_gemini_response": response_text[:500]
        }
    
    except Exception as e:
        print(f"❌ Gemini API error: {str(e)}")
        raise
