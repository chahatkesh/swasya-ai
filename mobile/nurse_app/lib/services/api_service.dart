import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  // Register a new patient
  static Future<Map<String, dynamic>> registerPatient({
    required String name,
    required String phone,
    int? age,
    String? gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Config.patientEndpoint),
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

  // Upload audio file directly
  static Future<Map<String, dynamic>> uploadAudio({
    required String patientId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.apiBaseUrl}/upload/audio/$patientId'),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
      
      print('📤 Uploading audio to: ${Config.apiBaseUrl}/upload/audio/$patientId');
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📊 Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading audio: $e');
    }
  }

  // Upload image file directly
  static Future<Map<String, dynamic>> uploadImage({
    required String patientId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.apiBaseUrl}/upload/image/$patientId'),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
      
      print('� Uploading image to: ${Config.apiBaseUrl}/upload/image/$patientId');
      
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

  // Get patient notes
  static Future<Map<String, dynamic>> getPatientNotes(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/notes/$patientId'),
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

  // Get all patients
  static Future<Map<String, dynamic>> getAllPatients() async {
    try {
      final response = await http.get(
        Uri.parse(Config.patientEndpoint),
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
}
