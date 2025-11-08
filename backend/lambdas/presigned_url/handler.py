"""
Lambda Function: Generate S3 Presigned URLs
Purpose: Generate secure upload URLs for mobile app to upload audio/images directly to S3
Trigger: API Gateway POST /upload-url

Why presigned URLs?
- Mobile app doesn't need AWS credentials
- Direct upload to S3 (faster, no Lambda size limits)
- Secure (URLs expire after 5 minutes)
"""

import json
import boto3
import os
from datetime import datetime

# Get configuration from environment variables
AWS_REGION = os.environ.get('AWS_REGION', 'eu-north-1')
AUDIO_BUCKET = os.environ.get('AUDIO_BUCKET', 'phc-audio-uploads')
IMAGE_BUCKET = os.environ.get('IMAGE_BUCKET', 'phc-image-uploads')

# Initialize S3 client
s3_client = boto3.client('s3', region_name=AWS_REGION)

def lambda_handler(event, context):
    """
    Generate a presigned URL for the mobile app to upload files
    
    Request format:
    {
        "patient_id": "PAT_12345",
        "file_type": "audio" or "image",
        "file_extension": "mp3" or "jpg"
    }
    
    Returns:
    {
        "upload_url": "https://s3.amazonaws.com/...",
        "file_key": "PAT_12345/audio_1699401600.mp3",
        "expires_in": 300
    }
    """
    
    print(f"Received event: {json.dumps(event)}")
    
    try:
        # Step 1: Parse request
        body = json.loads(event['body'])
        patient_id = body.get('patient_id')
        file_type = body.get('file_type')  # 'audio' or 'image'
        file_extension = body.get('file_extension', 'mp3')  # default to mp3
        
        # Step 2: Validate input
        if not patient_id or not file_type:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'patient_id and file_type are required',
                    'example': {
                        'patient_id': 'PAT_12345',
                        'file_type': 'audio',
                        'file_extension': 'mp3'
                    }
                })
            }
        
        if file_type not in ['audio', 'image']:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'error': 'file_type must be "audio" or "image"'
                })
            }
        
        # Step 3: Choose the correct bucket
        bucket_name = AUDIO_BUCKET if file_type == 'audio' else IMAGE_BUCKET
        
        # Step 4: Generate unique file key (S3 path)
        # Format: PAT_12345/audio_1699401600.mp3
        timestamp = int(datetime.now().timestamp())
        file_key = f"{patient_id}/{file_type}_{timestamp}.{file_extension}"
        
        # Step 5: Generate presigned URL
        # This URL allows the mobile app to upload directly to S3
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket_name,
                'Key': file_key,
                'ContentType': get_content_type(file_extension)
            },
            ExpiresIn=300  # URL expires in 5 minutes (300 seconds)
        )
        
        print(f"Generated presigned URL for {file_key}")
        
        # Step 6: Return the URL to mobile app
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': True,
                'upload_url': presigned_url,
                'file_key': file_key,
                'bucket': bucket_name,
                'expires_in': 300,
                'instructions': 'Use PUT method to upload file to this URL'
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'Failed to generate upload URL',
                'details': str(e)
            })
        }


def get_content_type(file_extension):
    """
    Helper function: Get MIME type based on file extension
    """
    content_types = {
        'mp3': 'audio/mpeg',
        'wav': 'audio/wav',
        'm4a': 'audio/mp4',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'pdf': 'application/pdf'
    }
    return content_types.get(file_extension.lower(), 'application/octet-stream')
