import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Comprehensive API Service for PHC AI Co-Pilot Backend
/// Version: 3.0.0 - Integrated with modular FastAPI backend
class ApiService {
  // ==================== PATIENT MANAGEMENT ====================
  
  /// Register a new patient
  static Future<Map<String, dynamic>> registerPatient({
    required String name,
    required String phone,
    int? age,
    String? gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Config.patientsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          if (age != null) 'age': age,
          if (gender != null) 'gender': gender,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register patient: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error registering patient: $e');
    }
  }

  /// Get all patients
  static Future<Map<String, dynamic>> getAllPatients() async {
    try {
      final response = await http.get(
        Uri.parse(Config.patientsEndpoint),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get patients: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting patients: $e');
    }
  }

  /// Get patient details with summary
  static Future<Map<String, dynamic>> getPatient(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.patientsEndpoint}/$patientId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get patient: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting patient: $e');
    }
  }

  // ==================== QUEUE MANAGEMENT ====================
  
  /// Add patient to queue
  static Future<Map<String, dynamic>> addToQueue({
    required String patientId,
    String priority = 'normal', // 'normal' or 'urgent'
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Config.queueEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': patientId,
          'priority': priority,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add to queue: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding to queue: $e');
    }
  }

  /// Get current queue
  static Future<Map<String, dynamic>> getQueue() async {
    try {
      final response = await http.get(
        Uri.parse(Config.queueEndpoint),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get queue: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting queue: $e');
    }
  }

  /// Get waiting patients
  static Future<Map<String, dynamic>> getWaitingPatients() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.queueEndpoint}/waiting'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get waiting patients: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting waiting patients: $e');
    }
  }

  // ==================== FILE UPLOADS ====================
  
  /// Upload audio file and get SOAP note
  static Future<Map<String, dynamic>> uploadAudio({
    required String patientId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.uploadAudioEndpoint}/$patientId'),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
      
      print('Uploading audio to: ${Config.uploadAudioEndpoint}/$patientId');
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading audio: $e');
    }
  }

  /// Upload image file and extract prescription
  static Future<Map<String, dynamic>> uploadImage({
    required String patientId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.uploadImageEndpoint}/$patientId'),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
      
      print('Uploading image to: ${Config.uploadImageEndpoint}/$patientId');
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // ==================== NOTES & HISTORY ====================
  
  /// Get all notes for a patient
  static Future<Map<String, dynamic>> getPatientNotes(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.notesEndpoint}/$patientId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get notes: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting notes: $e');
    }
  }

  /// Get latest note for a patient
  static Future<Map<String, dynamic>> getLatestNote(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.notesEndpoint}/$patientId/latest'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get latest note: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting latest note: $e');
    }
  }

  /// Get prescription history for a patient
  static Future<Map<String, dynamic>> getPatientHistory(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.historyEndpoint}/$patientId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting history: $e');
    }
  }

  /// Get complete patient summary (for dashboard)
  static Future<Map<String, dynamic>> getPatientSummary(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/summary/$patientId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get summary: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting summary: $e');
    }
  }

  // ==================== SYSTEM STATS ====================
  
  /// Get system statistics
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http.get(
        Uri.parse(Config.statsEndpoint),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get stats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting stats: $e');
    }
  }

  /// Health check
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/health'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
