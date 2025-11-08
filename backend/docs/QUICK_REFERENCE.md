# 🚀 Quick Reference - PHC AI Co-Pilot APIs

## Base URL
```
https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod
```

## 1. Register Patient
```bash
curl -X POST {BASE_URL}/patients \
  -H "Content-Type: application/json" \
  -d '{"name": "Ram Kumar", "phone": "9876543210"}'
```
**Returns:** `patient_id` (save this!)

## 2. Get Upload URL
```bash
curl -X POST {BASE_URL}/upload-url \
  -H "Content-Type: application/json" \
  -d '{"patient_id": "PAT_XXX", "file_type": "audio", "file_extension": "mp3"}'
```
**Returns:** `upload_url` (expires in 5 mins)

## 3. Upload File to S3
```bash
curl -X PUT "{UPLOAD_URL}" \
  --upload-file myfile.mp3 \
  -H "Content-Type: audio/mp3"
```
**Result:** Lambda auto-processes in 15-30 seconds

## 4. Check Results
```bash
# SOAP Notes
aws dynamodb query --table-name PatientNotes \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values '{":pid":{"S":"PAT_XXX"}}' \
  --region eu-north-1

# Medications
aws dynamodb query --table-name PatientHistory \
  --key-condition-expression "patient_id = :pid" \
  --expression-attribute-values '{":pid":{"S":"PAT_XXX"}}' \
  --region eu-north-1
```

## Resources
- **Audio Bucket:** `phc-audio-uploads-1762597760`
- **Image Bucket:** `phc-image-uploads-1762597760`
- **Region:** `eu-north-1`

## Mobile App Config
```dart
class Config {
  static const apiUrl = 'https://f6c3azplla.execute-api.eu-north-1.amazonaws.com/Prod';
  static const patientEndpoint = '$apiUrl/patients';
  static const uploadEndpoint = '$apiUrl/upload-url';
}
```

## Debug Commands
```bash
# Check logs
sam logs -n ScribeTaskFunction --tail

# List S3 files
aws s3 ls s3://phc-audio-uploads-1762597760/ --recursive

# View all patients
aws dynamodb scan --table-name Patients --region eu-north-1
```

---
Full docs: [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
