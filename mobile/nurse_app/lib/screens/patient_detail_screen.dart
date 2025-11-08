import 'package:flutter/material.dart';
import '../core/core.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.patientName,
          style: AppTypography.h3Card.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              print('🔄 [PatientDetail] Manual refresh');
              _loadPatientData();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Info Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          widget.patientName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'ID: ${widget.patientId}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppSpacing.xxl),

                  // Existing Data Section
                  if (hasNotes || hasHistory) ...[
                    Text(
                      'Patient Records',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),

                    // SOAP Notes Card
                    if (hasNotes)
                      Container(
                        margin: EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.note_alt_outlined,
                              color: AppColors.success,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'SOAP Notes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          subtitle: Text(
                            '${_patientData!['notes_count']} note(s) available',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: _viewNotes,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                            child: const Text(
                              'View',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),

                    // Medical Timeline Card
                    if (hasHistory)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.timeline_outlined,
                              color: AppColors.success,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'Medical Timeline',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          subtitle: Text(
                            '${_patientData!['history_count']} timeline(s) available',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: _viewTimeline,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                            child: const Text(
                              'View',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: AppSpacing.xxl),
                  ],

                  // Action Buttons Section
                  Text(
                    (hasNotes || hasHistory) ? 'Record New Data' : 'Start Recording',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),

                  // AI Scribe Button
                  Container(
                    width: double.infinity,
                    height: 96,
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    child: ElevatedButton(
                      onPressed: _navigateToScribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.secondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(AppSpacing.lg),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.mic_outlined,
                              size: 28,
                              color: AppColors.secondary,
                            ),
                          ),
                          SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'AI Scribe',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.xs - 2),
                                Text(
                                  'Record audio consultation',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondary.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                            color: AppColors.secondary.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // AI Digitizer Button
                  Container(
                    width: double.infinity,
                    height: 96,
                    child: ElevatedButton(
                      onPressed: _navigateToDigitize,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.secondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(AppSpacing.lg),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.document_scanner_outlined,
                              size: 28,
                              color: AppColors.secondary,
                            ),
                          ),
                          SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'AI Digitizer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.xs - 2),
                                Text(
                                  'Scan prescription documents',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondary.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                            color: AppColors.secondary.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error Warning
                  if (_error != null) ...[
                    SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_outlined,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Some data may not be loaded',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w500,
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
