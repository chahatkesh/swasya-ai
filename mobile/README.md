# PHC AI Co-Pilot - Nurse Mobile App (Flutter)

## Overview
Mobile app for nurses to register patients, record conversations, and scan documents.

## Features
- ✅ Nurse Dashboard (hardcoded - no login)
- 🔄 Patient Registration
- 🔄 AI Scribe (Audio Recording)
- 🔄 AI Digitizer (Document Scanning)

## Tech Stack
- Flutter 3.x
- Dart 3.x
- Key Packages (to be added):
  - `http` - API calls
  - `flutter_sound` - Audio recording
  - `camera` - Image capture
  - `path_provider` - File storage

## Setup

```bash
# Navigate to the app directory
cd nurse_app

# Get dependencies
flutter pub get

# Run on Android emulator/device
flutter run

# Run on iOS simulator/device
flutter run
```

## Project Structure
```
lib/
├── main.dart              # App entry point
├── screens/
│   ├── dashboard.dart     # Nurse dashboard
│   ├── patient_registration.dart
│   ├── ai_scribe.dart     # Audio recording
│   └── ai_digitizer.dart  # Document scanning
├── services/
│   ├── api_service.dart   # Backend API calls
│   └── s3_service.dart    # S3 uploads
└── models/
    └── patient.dart       # Patient data model
```

## Testing on Physical Device

### Android
```bash
# Enable USB debugging on your Android phone
# Connect via USB
flutter run
```

### iOS
```bash
# Open Xcode, add your Apple Developer account
# Connect iPhone via USB
flutter run
```

## Build APK (for demo/testing)
```bash
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

## Priority Features for Hackathon
1. ✅ Simple dashboard (DONE)
2. Patient registration form
3. Audio recording + S3 upload
4. Image capture + S3 upload

## Environment Variables
Create `lib/config.dart`:
```dart
class Config {
  static const String apiEndpoint = 'https://your-api-gateway-url.com/Prod';
  static const String region = 'ap-south-1';
}
```
