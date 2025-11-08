"""
Local test for Digitizer Task Lambda
Tests the Gemini structuring (without AWS Textract)
"""

import json
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from handler import structure_medical_data

def test_prescription():
    """Test with a prescription"""
    print("\n" + "="*60)
    print("TEST 1: Prescription → Structured Data")
    print("="*60)
    
    # Sample OCR text (what Textract would return)
    ocr_text = """
    Dr. Amit Sharma
    PHC Saket, Delhi
    Date: 15/10/2024
    
    Patient: Ram Kumar
    Age: 45 years
    
    Diagnosis: Fever, Headache
    
    Rx:
    1. Paracetamol 500mg - 1 tablet twice daily for 3 days
    2. Cetirizine 10mg - 1 tablet at bedtime for 5 days
    3. Rest and drink plenty of fluids
    
    Follow up after 3 days if fever persists
    
    Dr. Amit Sharma
    MBBS, MD
    """
    
    print(f"\nInput OCR Text:\n{ocr_text}")
    
    # Call Gemini
    structured_data = structure_medical_data(ocr_text)
    
    print(f"\n✅ Structured Medical Data:")
    print(json.dumps(structured_data, indent=2))
    
    # Verify
    assert 'medications' in structured_data
    assert len(structured_data['medications']) > 0
    assert 'Paracetamol' in str(structured_data['medications'])
    
    print("\n✅ TEST 1 PASSED!")


def test_lab_report():
    """Test with a lab report"""
    print("\n" + "="*60)
    print("TEST 2: Lab Report → Structured Data")
    print("="*60)
    
    ocr_text = """
    PATHOLOGY REPORT
    Date: 20/10/2024
    
    Patient: Priya Singh
    
    Complete Blood Count (CBC):
    Hemoglobin: 11.2 g/dL (Low)
    WBC Count: 8,500 cells/mcL (Normal)
    Platelet Count: 250,000/mcL (Normal)
    
    Diagnosis: Mild Anemia
    
    Recommendation: Iron supplements
    """
    
    print(f"\nInput OCR Text:\n{ocr_text}")
    
    structured_data = structure_medical_data(ocr_text)
    
    print(f"\n✅ Structured Medical Data:")
    print(json.dumps(structured_data, indent=2))
    
    assert 'diagnoses' in structured_data
    assert structured_data['document_type'] in ['lab_report', 'other']
    
    print("\n✅ TEST 2 PASSED!")


def test_hindi_prescription():
    """Test with Hindi text"""
    print("\n" + "="*60)
    print("TEST 3: Hindi Prescription → Structured Data")
    print("="*60)
    
    ocr_text = """
    डॉ. राजेश कुमार
    प्राथमिक स्वास्थ्य केंद्र
    
    रोगी का नाम: सुनीता देवी
    
    निदान: बुखार और खांसी
    
    दवाइयां:
    1. पैरासिटामोल 500mg - दिन में दो बार
    2. ब्रोंकोडाइलेटर सिरप - 10ml दिन में तीन बार
    
    3 दिन बाद दोबारा आएं
    """
    
    print(f"\nInput OCR Text:\n{ocr_text}")
    
    structured_data = structure_medical_data(ocr_text)
    
    print(f"\n✅ Structured Medical Data:")
    print(json.dumps(structured_data, indent=2, ensure_ascii=False))
    
    print("\n✅ TEST 3 PASSED!")


def test_messy_handwritten():
    """Test with messy/partial text (like bad handwriting)"""
    print("\n" + "="*60)
    print("TEST 4: Messy Handwritten Text → Structured Data")
    print("="*60)
    
    ocr_text = """
    Dr... Sharma
    
    Pat: Mr Kumar
    
    Dx: Fever
    
    Tab Para 500
    2x daily
    5d
    
    Follow up
    """
    
    print(f"\nInput OCR Text (messy):\n{ocr_text}")
    
    structured_data = structure_medical_data(ocr_text)
    
    print(f"\n✅ Structured Medical Data:")
    print(json.dumps(structured_data, indent=2))
    
    # Should still extract something
    assert 'medications' in structured_data
    
    print("\n✅ TEST 4 PASSED!")


if __name__ == '__main__':
    print("\n🚀 AI Digitizer (Gemini) Tests\n")
    print("⚠️  This tests ONLY the Gemini structuring part")
    print("⚠️  AWS Textract is NOT tested (requires actual images)\n")
    
    try:
        test_prescription()
        test_lab_report()
        test_hindi_prescription()
        test_messy_handwritten()
        
        print("\n" + "="*60)
        print("🎉 ALL TESTS PASSED!")
        print("="*60)
        print("\nGemini is correctly structuring medical documents!")
        print("Next: Test with actual scanned images after deploying to AWS")
        
    except Exception as e:
        print(f"\n❌ TEST FAILED: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
