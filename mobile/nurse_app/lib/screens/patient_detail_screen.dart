import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'camera_screen.dart';
import 'record_audio_screen.dart';
import 'timeline_view_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
    print('👤 [PatientDetail] Initialized for ${widget.patientId}');
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📥 [PatientDetail] Loading patient data...');
      
      // Fetch patient details (notes count, history count, etc.)
      final notesResponse = await ApiService.getSoapNotes(widget.patientId);
      final historyResponse = await ApiService.getPatientHistory(widget.patientId);
      
      if (!mounted) return; // Check if widget is still mounted before setState
      
      setState(() {
        _patientData = {
          'patient_id': widget.patientId,
          'name': widget.patientName,
          'notes_count': notesResponse['notes']?.length ?? 0,
          'history_count': historyResponse['history']?.length ?? 0,
          'notes': notesResponse['notes'] ?? [],
          'history': historyResponse['history'] ?? [],
        };
        _isLoading = false;
      });
      
      print('✅ [PatientDetail] Loaded: ${_patientData!['notes_count']} notes, ${_patientData!['history_count']} history items');
    } catch (e) {
      print('❌ [PatientDetail] Failed to load: $e');
      
      if (!mounted) return; // Check if widget is still mounted before setState
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Set basic data even on error
        _patientData = {
          'patient_id': widget.patientId,
          'name': widget.patientName,
          'notes_count': 0,
          'history_count': 0,
        };
      });
    }
  }

  void _navigateToScribe() {
    print('🎤 [PatientDetail] Starting Scribe (Audio Recording)');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordAudioScreen(
          patientId: widget.patientId,
          patientName: widget.patientName,
        ),
      ),
    ).then((_) {
      print('🔄 [PatientDetail] Returned from Scribe, refreshing...');
      _loadPatientData();
    });
  }

  void _navigateToDigitize() {
    print('📄 [PatientDetail] Starting Digitize (Document Scanning)');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          patientId: widget.patientId,
          patientName: widget.patientName,
        ),
      ),
    ).then((_) {
      print('🔄 [PatientDetail] Returned from Digitize, refreshing...');
      _loadPatientData();
    });
  }

  void _viewTimeline() {
    print('📊 [PatientDetail] Viewing Timeline');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimelineViewScreen(
          patientId: widget.patientId,
          patientName: widget.patientName,
        ),
      ),
    );
  }

  void _viewNotes() {
    print('📝 [PatientDetail] Viewing SOAP Notes');
    
    if (_patientData == null || _patientData!['notes_count'] == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No SOAP notes available yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show notes dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.note_alt, color: Colors.blue),
            const SizedBox(width: 8),
            const Expanded(child: Text('SOAP Notes')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _patientData!['notes'].length,
            itemBuilder: (context, index) {
              final note = _patientData!['notes'][index];
              final soapNote = note['soap_note'] ?? {};
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Note ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            note['created_at']?.toString().substring(0, 10) ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Chief Complaint
                      if (soapNote['chief_complaint'] != null && soapNote['chief_complaint'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.medical_services, size: 14, color: Colors.red),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  soapNote['chief_complaint'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Subjective
                      if (soapNote['subjective'] != null && soapNote['subjective'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'S: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  soapNote['subjective'],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Assessment
                      if (soapNote['assessment'] != null && soapNote['assessment'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  soapNote['assessment'],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Plan
                      if (soapNote['plan'] != null && soapNote['plan'].toString().isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'P: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                soapNote['plan'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNotes = _patientData != null && _patientData!['notes_count'] > 0;
    final hasHistory = _patientData != null && _patientData!['history_count'] > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 [PatientDetail] Manual refresh');
              _loadPatientData();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Info Card
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue[100],
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.patientName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${widget.patientId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Existing Data Section (Optional - shows what's available)
                  if (hasNotes || hasHistory) ...[
                    const Text(
                      'Existing Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // SOAP Notes Card
                    if (hasNotes)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(Icons.note_alt, color: Colors.green),
                          ),
                          title: const Text('SOAP Notes (AI Scribe)'),
                          subtitle: Text(
                            '${_patientData!['notes_count']} note(s) available',
                            style: TextStyle(color: Colors.green[700]),
                          ),
                          trailing: TextButton(
                            onPressed: _viewNotes,
                            child: const Text('View'),
                          ),
                        ),
                      ),

                    if (hasNotes) const SizedBox(height: 8),

                    // Medical History Card
                    if (hasHistory)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(Icons.timeline, color: Colors.green),
                          ),
                          title: const Text('Medical Timeline (AI Digitizer)'),
                          subtitle: Text(
                            '${_patientData!['history_count']} timeline(s) available',
                            style: TextStyle(color: Colors.green[700]),
                          ),
                          trailing: TextButton(
                            onPressed: _viewTimeline,
                            child: const Text('View'),
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],

                  // Action Buttons Section - ALWAYS VISIBLE
                  Text(
                    (hasNotes || hasHistory) ? 'Add More Data' : 'Record Patient Data',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // AI Scribe Button
                  SizedBox(
                    width: double.infinity,
                    height: 100,
                    child: ElevatedButton(
                      onPressed: _navigateToScribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'AI Scribe',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Record audio consultation',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // AI Digitizer Button
                  SizedBox(
                    width: double.infinity,
                    height: 100,
                    child: ElevatedButton(
                      onPressed: _navigateToDigitize,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.document_scanner, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'AI Digitizer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan prescription documents',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Some data may not be loaded',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
