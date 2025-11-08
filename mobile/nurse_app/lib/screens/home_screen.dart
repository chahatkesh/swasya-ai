import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/upload_queue_manager.dart';
import 'patient_detail_screen.dart';
import 'patient_registration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String? _error;
  final UploadQueueManager _queueManager = UploadQueueManager();

  @override
  void initState() {
    super.initState();
    _queueManager.addListener(_onQueueUpdate);
    _loadTodaysPatients();
    print('🏠 [HomeScreen] Initialized');
  }

  @override
  void dispose() {
    _queueManager.removeListener(_onQueueUpdate);
    super.dispose();
  }

  void _onQueueUpdate() {
    // Rebuild UI when upload queue changes
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadTodaysPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📥 [HomeScreen] Fetching today\'s patient queue...');
      
      // Fetch all patients (queue endpoint might be empty)
      final response = await ApiService.getAllPatients();
      
      setState(() {
        _patients = List<Map<String, dynamic>>.from(response['patients'] ?? []);
        _isLoading = false;
      });
      
      print('✅ [HomeScreen] Loaded ${_patients.length} patients');
      
      // Debug: print patient IDs
      if (_patients.isNotEmpty) {
        for (var patient in _patients) {
          print('   - ${patient['name']} (ID: ${patient['patient_id']})');
        }
      }
    } catch (e) {
      print('❌ [HomeScreen] Failed to load patients: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getPatientStatus(Map<String, dynamic> patient) {
    // Honor optimistic local status when present
    if (patient.containsKey('__local_status')) {
      return patient['__local_status'];
    }
    final patientId = patient['patient_id'];
    
    // Check if patient has active batch being processed
    final activeBatches = _queueManager.allBatches
        .where((b) => b.patientId == patientId && b.isCompleted && b.pendingTasks == 0 && b.timelineId == null)
        .toList();
    
    if (activeBatches.isNotEmpty) {
      return 'generating'; // Timeline being generated
    }
    
    // Check if uploads are in progress
    final uploadingBatches = _queueManager.allBatches
        .where((b) => b.patientId == patientId && !b.isCompleted && (b.pendingTasks > 0 || _queueManager.isProcessing))
        .toList();
    
    if (uploadingBatches.isNotEmpty) {
      return 'uploading'; // Documents being uploaded
    }
    
    // Determine status based on available data
    final hasNotes = patient['notes_count'] != null && patient['notes_count'] > 0;
    final hasHistory = patient['history_count'] != null && patient['history_count'] > 0;
    
    if (hasNotes && hasHistory) return 'completed';
    if (hasNotes || hasHistory) return 'processing';
    return 'pending';
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'generating':
        return Icons.auto_awesome;
      case 'uploading':
        return Icons.cloud_upload;
      case 'processing':
        return Icons.pending;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'generating':
        return Colors.purple;
      case 'uploading':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'generating':
        return 'Generating Timeline';
      case 'uploading':
        return 'Uploading';
      case 'processing':
        return 'In Progress';
      default:
        return 'Pending';
    }
  }

  void _navigateToPatientDetail(Map<String, dynamic> patient) {
    print('👤 [HomeScreen] Navigating to patient detail: ${patient['patient_id']}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(
          patientId: patient['patient_id'],
          patientName: patient['name'],
        ),
      ),
    ).then((_) {
      // Optimistic update: mark patient as processing immediately so nurse isn't blocked by network
      print('🔄 [HomeScreen] Returned from patient detail, applying optimistic status and scheduling refresh...');
      final pid = patient['patient_id'];
      setState(() {
        final idx = _patients.indexWhere((p) => p['patient_id'] == pid);
        if (idx != -1) {
          // Add a lightweight local status to show immediate feedback
          final updated = Map<String, dynamic>.from(_patients[idx]);
          updated['__local_status'] = 'uploading';
          _patients[idx] = updated;
        }
      });

      // Refresh the full list in background after a short delay (won't block UI)
      Future.delayed(const Duration(seconds: 2), () {
        print('🔁 [HomeScreen] Performing background refresh of patient list');
        _loadTodaysPatients();
      });
    });
  }

  void _navigateToRegistration() {
    print('➕ [HomeScreen] Navigating to patient registration');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PatientRegistrationScreen(),
      ),
    ).then((_) {
      // Refresh queue after registration
      _loadTodaysPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PHC AI Co-Pilot'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 [HomeScreen] Manual refresh triggered');
              _loadTodaysPatients();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Loading today\'s patients...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load patients',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadTodaysPatients,
                          icon: Icon(Icons.refresh),
                          label: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _patients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No patients today',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Register a new patient to get started',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTodaysPatients,
                      child: Column(
                        children: [
                          // Header with count
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.blue[200]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Today\'s Queue',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_patients.length} ${_patients.length == 1 ? "patient" : "patients"}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Patient list
                          Expanded(
                            child: ListView.builder(
                              itemCount: _patients.length,
                              padding: const EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                final patient = _patients[index];
                                final status = _getPatientStatus(patient);
                                
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    leading: status == 'uploading' || status == 'generating'
                                        ? SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                _getStatusColor(status),
                                              ),
                                            ),
                                          )
                                        : CircleAvatar(
                                            backgroundColor: _getStatusColor(status),
                                            child: Icon(
                                              _getStatusIcon(status),
                                              color: Colors.white,
                                            ),
                                          ),
                                    title: Text(
                                      patient['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: ${patient['patient_id']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(status).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _getStatusColor(status),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                _getStatusText(status),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusColor(status),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey[400],
                                      size: 16,
                                    ),
                                    onTap: () => _navigateToPatientDetail(patient),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRegistration,
        icon: const Icon(Icons.person_add),
        label: const Text('New Patient'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
