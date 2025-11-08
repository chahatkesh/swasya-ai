import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';

/// Debug screen to test backend connectivity
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _status = 'Not tested';
  Color _statusColor = Colors.grey;
  bool _isTesting = false;
  String? _errorDetails;

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _status = 'Testing...';
      _statusColor = Colors.orange;
      _errorDetails = null;
    });

    try {
      // Test health endpoint
      final isHealthy = await ApiService.checkHealth();
      
      if (isHealthy) {
        setState(() {
          _status = 'Connected ✓';
          _statusColor = Colors.green;
        });
      } else {
        setState(() {
          _status = 'Backend not responding';
          _statusColor = Colors.red;
          _errorDetails = 'Health check returned false';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Connection Failed';
        _statusColor = Colors.red;
        _errorDetails = e.toString();
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testPatientRegistration() async {
    setState(() {
      _isTesting = true;
      _status = 'Testing patient registration...';
      _statusColor = Colors.orange;
      _errorDetails = null;
    });

    try {
      final response = await ApiService.registerPatient(
        name: 'Test Patient ${DateTime.now().millisecondsSinceEpoch}',
        phone: '9876543210',
        age: 30,
        gender: 'male', uhid: 'test-uhid',
      );

      setState(() {
        _status = 'Registration successful! ✓';
        _statusColor = Colors.green;
        _errorDetails = 'Patient ID: ${response['patient_id']}';
      });
    } catch (e) {
      setState(() {
        _status = 'Registration Failed';
        _statusColor = Colors.red;
        _errorDetails = e.toString();
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connectivity Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Configuration
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      'Base URL: ${Config.apiBaseUrl}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      'Patients: ${Config.patientsEndpoint}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Card
            Card(
              color: _statusColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_statusColor == Colors.green 
                          ? Icons.check_circle 
                          : _statusColor == Colors.red 
                            ? Icons.error 
                            : Icons.info,
                          color: _statusColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _status,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_errorDetails != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _errorDetails!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find),
                label: const Text('Test Health Check'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testPatientRegistration,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add),
                label: const Text('Test Patient Registration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instructions
            const Card(
              color: Colors.amber,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.black87),
                        SizedBox(width: 8),
                        Text(
                          'Troubleshooting Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Ensure your phone and computer are on the same WiFi\n'
                      '2. Check that Docker backend is running:\n'
                      '   docker-compose ps\n'
                      '3. Verify your IP in lib/config.dart matches:\n'
                      '   192.168.0.7 (your current IP)\n'
                      '4. Test backend in browser:\n'
                      '   http://192.168.0.7:8000/docs',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
