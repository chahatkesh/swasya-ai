"""
Local test for Presigned URL Generator Lambda
"""

import json
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from handler import lambda_handler

def test_audio_url():
    """Test generating presigned URL for audio upload"""
    print("\n" + "="*60)
    print("TEST 1: Generate Audio Upload URL")
    print("="*60)
    
    test_event = {
        'body': json.dumps({
            'patient_id': 'PAT_12345',
            'file_type': 'audio',
            'file_extension': 'mp3'
        })
    }
    
    response = lambda_handler(test_event, None)
    
    print(f"\nStatus Code: {response['statusCode']}")
    body = json.loads(response['body'])
    print(f"Response: {json.dumps(body, indent=2)}")
    
    assert response['statusCode'] == 200
    assert 'upload_url' in body
    assert 'PAT_12345' in body['file_key']
    
    print("\n✅ TEST 1 PASSED!")


def test_image_url():
    """Test generating presigned URL for image upload"""
    print("\n" + "="*60)
    print("TEST 2: Generate Image Upload URL")
    print("="*60)
    
    test_event = {
        'body': json.dumps({
            'patient_id': 'PAT_67890',
            'file_type': 'image',
            'file_extension': 'jpg'
        })
    }
    
    response = lambda_handler(test_event, None)
    
    print(f"\nStatus Code: {response['statusCode']}")
    body = json.loads(response['body'])
    print(f"Response: {json.dumps(body, indent=2)}")
    
    assert response['statusCode'] == 200
    assert 'upload_url' in body
    
    print("\n✅ TEST 2 PASSED!")


def test_missing_fields():
    """Test validation"""
    print("\n" + "="*60)
    print("TEST 3: Missing Required Fields (Should Fail)")
    print("="*60)
    
    test_event = {
        'body': json.dumps({
            'patient_id': 'PAT_12345'
            # file_type is missing
        })
    }
    
    response = lambda_handler(test_event, None)
    
    print(f"\nStatus Code: {response['statusCode']}")
    print(f"Response: {json.dumps(json.loads(response['body']), indent=2)}")
    
    assert response['statusCode'] == 400
    
    print("\n✅ TEST 3 PASSED!")


if __name__ == '__main__':
    print("\n🚀 Presigned URL Generator Tests\n")
    
    try:
        test_audio_url()
        test_image_url()
        test_missing_fields()
        
        print("\n🎉 ALL TESTS PASSED!")
    except Exception as e:
        print(f"\n❌ TEST FAILED: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
