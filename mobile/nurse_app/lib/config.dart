class Config {
  // Local FastAPI backend - Backend is running at http://localhost:8000
  // For Android Emulator use 10.0.2.2
  // For iOS Simulator use localhost
  // For Real Device use your computer's IP address
  static const String apiBaseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String apiBaseUrl = 'http://localhost:8000'; // iOS simulator  
  // static const String apiBaseUrl = 'http://192.168.1.X:8000'; // Real device (replace with your IP)
  
  // API Endpoints - Updated for new modular backend
  static const String patientsEndpoint = '$apiBaseUrl/patients';
  static const String queueEndpoint = '$apiBaseUrl/queue';
  static const String uploadAudioEndpoint = '$apiBaseUrl/upload/audio';
  static const String uploadImageEndpoint = '$apiBaseUrl/upload/image';
  static const String notesEndpoint = '$apiBaseUrl/notes';
  static const String historyEndpoint = '$apiBaseUrl/history';
  static const String statsEndpoint = '$apiBaseUrl/stats';
  
  // App Info
  static const String appName = 'PHC AI Co-Pilot';
  static const String appVersion = '1.0.0';
  static const String nurseName = 'Nurse Rekha';
}

