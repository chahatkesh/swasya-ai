"""
Lambda Function: Patient Registration
Purpose: Register new patients from the mobile app
Trigger: API Gateway POST /patients
"""

import json
import boto3
import uuid
import os
from datetime import datetime

# Get region from environment variable
AWS_REGION = os.environ.get('AWS_REGION', 'eu-north-1')

# Initialize DynamoDB client
# This creates a connection to AWS DynamoDB service
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
patients_table = dynamodb.Table('Patients')

def lambda_handler(event, context):
    """
    Main Lambda handler function - AWS calls this when API is hit
    
    What it does:
    1. Receives patient name and phone from mobile app
    2. Generates a unique patient ID
    3. Saves to DynamoDB
    4. Returns the patient ID back to mobile app
    
    Args:
        event: Contains the HTTP request data
               Example: {'body': '{"name": "Ram Kumar", "phone": "9876543210"}'}
        context: AWS Lambda runtime info (we rarely need this)
    
    Returns:
        HTTP response with status code, headers, and body
    """
    
    print(f"Received event: {json.dumps(event)}")  # Log to CloudWatch
    
    try:
        # Step 1: Parse the incoming JSON request body
        # The mobile app sends: {"name": "Ram Kumar", "phone": "9876543210"}
        body = json.loads(event['body'])
        name = body.get('name')
        phone = body.get('phone')
        
        # Step 2: Validate input (make sure we have required fields)
        if not name or not phone:
            return {
                'statusCode': 400,  # 400 = Bad Request
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'  # Allow mobile app
                },
                'body': json.dumps({
                    'error': 'Name and phone are required',
                    'received': {'name': name, 'phone': phone}
                })
            }
        
        # Step 3: Generate unique patient ID
        # Format: PAT_A3F5B2C1 (PAT_ prefix + 8 random hex characters)
        patient_id = f"PAT_{uuid.uuid4().hex[:8].upper()}"
        
        # Step 4: Save to DynamoDB
        # This is like INSERT INTO Patients VALUES (...)
        patients_table.put_item(
            Item={
                'patient_id': patient_id,      # Primary key
                'name': name,
                'phone': phone,
                'created_at': int(datetime.now().timestamp()),  # Unix timestamp
                'created_by': 'NURSE_001',     # Hardcoded for hackathon
                'status': 'active'
            }
        )
        
        print(f"Successfully registered patient: {patient_id}")
        
        # Step 5: Return success response
        return {
            'statusCode': 200,  # 200 = Success
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # CORS header
            },
            'body': json.dumps({
                'success': True,
                'patient_id': patient_id,
                'name': name,
                'phone': phone,
                'message': 'Patient registered successfully',
                'timestamp': datetime.now().isoformat()
            })
        }
        
    except KeyError as e:
        # This happens if 'body' is missing from event
        print(f"KeyError: {str(e)}")
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'Invalid request format',
                'details': f'Missing field: {str(e)}'
            })
        }
    
    except json.JSONDecodeError as e:
        # This happens if body is not valid JSON
        print(f"JSON decode error: {str(e)}")
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'Invalid JSON in request body',
                'details': str(e)
            })
        }
    
    except Exception as e:
        # Catch any other unexpected errors
        print(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,  # 500 = Internal Server Error
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'Internal server error',
                'details': str(e)
            })
        }


def get_patient(patient_id):
    """
    Helper function: Get patient details by ID
    Used for testing and debugging
    """
    try:
        response = patients_table.get_item(Key={'patient_id': patient_id})
        return response.get('Item')
    except Exception as e:
        print(f"Error getting patient: {str(e)}")
        return None
