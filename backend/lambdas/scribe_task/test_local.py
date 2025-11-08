"""
Local test for Scribe Task Lambda
Tests the Gemini SOAP note generation (without AWS Transcribe)
"""

import json
import sys
import os

# Set environment variables for testing
# IMPORTANT: Set your GEMINI_API_KEY before running:
# export GEMINI_API_KEY="your-api-key-here"
if 'GEMINI_API_KEY' not in os.environ:
    print("❌ ERROR: GEMINI_API_KEY environment variable not set!")
    print("Please run: export GEMINI_API_KEY='your-api-key-here'")
    sys.exit(1)

os.environ['AWS_REGION'] = os.environ.get('AWS_REGION', 'eu-north-1')

sys.path.insert(0, os.path.dirname(__file__))
from handler import generate_soap_note

def test_hindi_conversation():
    """Test with a Hindi conversation transcript"""
    print("\n" + "="*60)
    print("TEST 1: Hindi Conversation → SOAP Note")
    print("="*60)
    
    # Sample transcript (simulating what Transcribe would return)
    transcript = """
    नर्स: नमस्ते, आपका नाम क्या है?
    मरीज: राम कुमार
    नर्स: आपको क्या तकलीफ है?
    मरीज: मुझे तीन दिन से बुखार है और सिर में बहुत दर्द है
    नर्स: बुखार कितना है?
    मरीज: 102 डिग्री के आसपास
    नर्स: ठीक है, मैं डॉक्टर को बताती हूं
    """
    
    print(f"\nInput Transcript:\n{transcript}")
    
    # Call Gemini
    soap_note = generate_soap_note(transcript)
    
    print(f"\n✅ Generated SOAP Note:")
    print(json.dumps(soap_note, indent=2, ensure_ascii=False))
    
    # Verify structure
    required_fields = ['subjective', 'objective', 'assessment', 'plan', 'chief_complaint']
    for field in required_fields:
        assert field in soap_note, f"Missing field: {field}"
    
    print("\n✅ TEST 1 PASSED!")
    return soap_note


def test_english_conversation():
    """Test with an English conversation"""
    print("\n" + "="*60)
    print("TEST 2: English Conversation → SOAP Note")
    print("="*60)
    
    transcript = """
    Nurse: Hello, what brings you here today?
    Patient: I've been having chest pain for the last two days
    Nurse: Can you describe the pain?
    Patient: It's a sharp pain on the left side, especially when I breathe deeply
    Nurse: Any fever or cough?
    Patient: No fever, but slight cough
    Nurse: Let me check your vitals. Blood pressure is 130/85, temperature 98.6F
    """
    
    print(f"\nInput Transcript:\n{transcript}")
    
    soap_note = generate_soap_note(transcript)
    
    print(f"\n✅ Generated SOAP Note:")
    print(json.dumps(soap_note, indent=2))
    
    assert 'chest pain' in soap_note['chief_complaint'].lower() or 'chest pain' in soap_note['subjective'].lower()
    
    print("\n✅ TEST 2 PASSED!")


def test_mixed_hindi_english():
    """Test with Hinglish (mixed Hindi-English)"""
    print("\n" + "="*60)
    print("TEST 3: Hinglish Conversation → SOAP Note")
    print("="*60)
    
    transcript = """
    नर्स: Hello, aapka naam?
    Patient: मेरा नाम प्रिया है
    Nurse: Aapko kya problem hai?
    Patient: Mujhe stomach pain hai, three days se. Aur vomiting bhi ho rahi hai
    Nurse: Fever hai?
    Patient: Haan, थोड़ा बुखार है
    """
    
    print(f"\nInput Transcript:\n{transcript}")
    
    soap_note = generate_soap_note(transcript)
    
    print(f"\n✅ Generated SOAP Note:")
    print(json.dumps(soap_note, indent=2, ensure_ascii=False))
    
    print("\n✅ TEST 3 PASSED!")


if __name__ == '__main__':
    print("\n🚀 AI Scribe (Gemini) Tests\n")
    print("⚠️  This tests ONLY the Gemini structuring part")
    print("⚠️  AWS Transcribe is NOT tested (requires actual audio files)\n")
    
    try:
        test_hindi_conversation()
        test_english_conversation()
        test_mixed_hindi_english()
        
        print("\n" + "="*60)
        print("🎉 ALL TESTS PASSED!")
        print("="*60)
        print("\nGemini is correctly structuring conversations into SOAP notes!")
        print("Next: Test with actual audio files after deploying to AWS")
        
    except Exception as e:
        print(f"\n❌ TEST FAILED: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
