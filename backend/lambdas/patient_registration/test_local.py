"""
Local test for Patient Registration Lambda
Run this BEFORE deploying to AWS to catch bugs early!

Usage:
    python3 test_local.py
"""

import json
import sys
import os
from unittest.mock import Mock, patch

# Add parent directory to path so we can import handler
sys.path.insert(0, os.path.dirname(__file__))

# Mock DynamoDB before importing handler
mock_dynamodb = Mock()
mock_table = Mock()
mock_dynamodb.Table.return_value = mock_table

sys.modules['boto3'] = Mock()
sys.modules['boto3'].resource = Mock(return_value=mock_dynamodb)

from handler import lambda_handler

def test_successful_registration():
    """Test Case 1: Valid patient registration"""
    print("\n" + "="*60)
    print("TEST 1: Successful Patient Registration")
    print("="*60)
    
    # Simulate an API Gateway event
    test_event = {
        'body': json.dumps({
            'name': 'Ram Kumar',
            'phone': '9876543210'
        }),
        'headers': {
            'Content-Type': 'application/json'
        }
    }
    
    # Call the Lambda function
    response = lambda_handler(test_event, None)
    
    # Print results
    print(f"\nStatus Code: {response['statusCode']}")
    print(f"Response Body: {json.dumps(json.loads(response['body']), indent=2)}")
    
    # Assertions
    assert response['statusCode'] == 200, "Expected status code 200"
    body = json.loads(response['body'])
    assert 'patient_id' in body, "Expected patient_id in response"
    assert body['patient_id'].startswith('PAT_'), "Patient ID should start with PAT_"
    
    print("\n✅ TEST 1 PASSED!")
    return body['patient_id']


def test_missing_name():
    """Test Case 2: Missing name field"""
    print("\n" + "="*60)
    print("TEST 2: Missing Name (Should Fail)")
    print("="*60)
    
    test_event = {
        'body': json.dumps({
            'phone': '9876543210'
            # name is missing!
        })
    }
    
    response = lambda_handler(test_event, None)
    
    print(f"\nStatus Code: {response['statusCode']}")
    print(f"Response Body: {json.dumps(json.loads(response['body']), indent=2)}")
    
    # Should return 400 (Bad Request)
    assert response['statusCode'] == 400, "Expected status code 400 for missing name"
    
    print("\n✅ TEST 2 PASSED!")


def test_missing_phone():
    """Test Case 3: Missing phone field"""
    print("\n" + "="*60)
    print("TEST 3: Missing Phone (Should Fail)")
    print("="*60)
    
    test_event = {
        'body': json.dumps({
            'name': 'Priya Singh'
            # phone is missing!
        })
    }
    
    response = lambda_handler(test_event, None)
    
    print(f"\nStatus Code: {response['statusCode']}")
    print(f"Response Body: {json.dumps(json.loads(response['body']), indent=2)}")
    
    assert response['statusCode'] == 400, "Expected status code 400 for missing phone"
    
    print("\n✅ TEST 3 PASSED!")


def test_invalid_json():
    """Test Case 4: Invalid JSON"""
    print("\n" + "="*60)
    print("TEST 4: Invalid JSON (Should Fail)")
    print("="*60)
    
    test_event = {
        'body': 'this is not valid JSON'
    }
    
    response = lambda_handler(test_event, None)
    
    print(f"\nStatus Code: {response['statusCode']}")
    print(f"Response Body: {json.dumps(json.loads(response['body']), indent=2)}")
    
    assert response['statusCode'] == 400, "Expected status code 400 for invalid JSON"
    
    print("\n✅ TEST 4 PASSED!")


def test_multiple_patients():
    """Test Case 5: Register multiple patients (check unique IDs)"""
    print("\n" + "="*60)
    print("TEST 5: Multiple Patients (Check Unique IDs)")
    print("="*60)
    
    patients = [
        {'name': 'Amit Sharma', 'phone': '9876543211'},
        {'name': 'Sneha Patel', 'phone': '9876543212'},
        {'name': 'Rajesh Kumar', 'phone': '9876543213'},
    ]
    
    patient_ids = []
    
    for patient in patients:
        test_event = {
            'body': json.dumps(patient)
        }
        
        response = lambda_handler(test_event, None)
        body = json.loads(response['body'])
        patient_id = body['patient_id']
        patient_ids.append(patient_id)
        
        print(f"Registered: {patient['name']} -> {patient_id}")
    
    # Check all IDs are unique
    assert len(patient_ids) == len(set(patient_ids)), "Patient IDs should be unique"
    
    print("\n✅ TEST 5 PASSED! All patient IDs are unique.")


if __name__ == '__main__':
    print("\n" + "🚀"*30)
    print("PHC AI Co-Pilot - Patient Registration Lambda Tests")
    print("🚀"*30)
    
    print("\n⚠️  NOTE: These tests run LOCALLY (not on AWS).")
    print("⚠️  They will NOT actually save to DynamoDB unless you configure AWS credentials.")
    print("⚠️  We're testing the LOGIC, not the database connection.\n")
    
    try:
        # Run all tests
        test_successful_registration()
        test_missing_name()
        test_missing_phone()
        test_invalid_json()
        test_multiple_patients()
        
        print("\n" + "="*60)
        print("🎉 ALL TESTS PASSED! 🎉")
        print("="*60)
        print("\nYour Lambda function logic is correct!")
        print("Next step: Deploy to AWS with `sam build && sam deploy`")
        
    except AssertionError as e:
        print(f"\n❌ TEST FAILED: {str(e)}")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ UNEXPECTED ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
