class Config {
  // Local FastAPI backend
  static const String apiBaseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String apiBaseUrl = 'http://localhost:8000'; // iOS simulator  
  // static const String apiBaseUrl = 'http://192.168.1.X:8000'; // Real device (replace with your IP)
  
  // API Endpoints
  static const String patientEndpoint = '$apiBaseUrl/patients';
  static const String uploadEndpoint = '$apiBaseUrl/upload-url'; // Not used in simple backend
  
  // App Info
  static const String appName = 'PHC AI Co-Pilot';
  static const String appVersion = '1.0.0';
  static const String nurseName = 'Nurse Rekha';
}
