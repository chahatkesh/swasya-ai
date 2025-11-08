import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/core.dart';
import '../services/api_service.dart';
import '../widgets/soap_notes_sheet.dart';
import 'camera_screen.dart';
import 'record_audio_screen.dart';
import 'timeline_view_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final int? queuePosition;
  final String? queueId;  // NEW: Pass queue_id directly from home screen

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.queuePosition,
    this.queueId,  // NEW
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  String? _queueId;
  bool _isSending = false;
  late AnimationController _animationController;
  late Animation<double> _flyAnimation;
  
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
    
    // Use queue_id passed from home screen if available, otherwise lookup
    if (widget.queueId != null) {
      _queueId = widget.queueId;
      print('📋 [PatientDetail] Using queue_id from navigation: $_queueId');
    } else {
      _loadQueueId();
    }
    
    // Initialize simple animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Simple fly-away animation
    _flyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  // Load queue ID from SharedPreferences OR by patient_id lookup
  Future<void> _loadQueueId() async {
    try {
      print('📋 [PatientDetail] Loading queue_id for patient: ${widget.patientId}');
      
      // First try to get queue_id for this specific patient from the backend
      final response = await ApiService.getQueue();
      print('📋 [PatientDetail] Queue response received');
      
      final queue = response['queue'] as List;
      print('📋 [PatientDetail] Queue has ${queue.length} entries');
      
      // Find this patient's ACTIVE queue entry (not completed)
      // Priority: waiting > nurse_completed > ready_for_doctor > in_consultation
      final activeStatuses = ['waiting', 'nurse_completed', 'ready_for_doctor', 'in_consultation'];
      
      final queueEntry = queue.firstWhere(
        (entry) => entry['patient_id'] == widget.patientId && 
                   activeStatuses.contains(entry['status']),
        orElse: () => null,
      );
      
      if (queueEntry != null) {
        // Try 'queue_id' first, then 'id'
        final foundId = queueEntry['queue_id'] ?? queueEntry['id'];
        setState(() {
          _queueId = foundId;
        });
        print('✅ [PatientDetail] Found active queue_id: $_queueId (status: ${queueEntry['status']})');
      } else {
        print('⚠️ [PatientDetail] No active queue entry found for patient ${widget.patientId}');
        
        // Debug: show all entries for this patient
        final patientEntries = queue.where((e) => e['patient_id'] == widget.patientId).toList();
        if (patientEntries.isNotEmpty) {
          print('   Found ${patientEntries.length} total entries for this patient:');
          for (var entry in patientEntries) {
            print('   - queue_id: ${entry['queue_id']}, status: ${entry['status']}');
          }
        }
      }
    } catch (e) {
      print('❌ [PatientDetail] Failed to load queue_id: $e');
      
      // Fallback: try SharedPreferences (for backward compatibility)
      try {
        final prefs = await SharedPreferences.getInstance();
        final fallbackQueueId = prefs.getString('current_queue_id');
        if (fallbackQueueId != null) {
          setState(() {
            _queueId = fallbackQueueId;
          });
          print('📋 [PatientDetail] Using fallback queue_id from prefs: $_queueId');
        }
      } catch (prefError) {
        print('❌ [PatientDetail] Fallback also failed: $prefError');
      }
    }
  }

  // Get initials from patient name
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'.toUpperCase();
  }

  // Generate color based on name (consistent per name)
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF5C6BC0), // Indigo
      const Color(0xFF26A69A), // Teal
      const Color(0xFFEF5350), // Red
      const Color(0xFF42A5F5), // Blue
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFF7043), // Deep Orange
      const Color(0xFFAB47BC), // Purple
      const Color(0xFF29B6F6), // Light Blue
      const Color(0xFF9CCC65), // Light Green
      const Color(0xFFFFCA28), // Amber
    ];
    
    // Use hash of name to get consistent color
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
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
        SnackBar(
          content: const Text('No SOAP notes available yet'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Properly cast the notes list
    final notes = List<Map<String, dynamic>>.from(
      (_patientData!['notes'] as List).map((note) => Map<String, dynamic>.from(note))
    );
    
    SoapNotesSheet.show(context, notes);
  }

  Future<void> _sendToDoctor() async {
    if (_queueId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Queue ID not found. Please register patient first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Start the animation
    setState(() {
      _isSending = true;
    });
    _animationController.forward();

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      await ApiService.nurseCompletePatient(_queueId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Patient sent to doctor successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to home
      Navigator.pop(context);
    } catch (e) {
      // Reset animation on error
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _animationController.reset();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNotes = _patientData != null && _patientData!['notes_count'] > 0;
    final hasHistory = _patientData != null && _patientData!['history_count'] > 0;

    // Debug: Check button visibility conditions
    print('🔍 [PatientDetail] Button visibility check:');
    print('   - queuePosition: ${widget.queuePosition}');
    print('   - _queueId: $_queueId');
    print('   - Will show button: ${widget.queuePosition == 1 && _queueId != null}');

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
                  // Patient Info Card (subtle design)
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
                        // Patient Avatar with Initials
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getAvatarColor(widget.patientName),
                                _getAvatarColor(widget.patientName).withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getAvatarColor(widget.patientName).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(widget.patientName),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        
                        // Patient Name
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
                        
                        // Patient ID
                        Text(
                          'ID: ${widget.patientId}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        // Show "Send to Doctor" button ONLY if:
                        // 1. Patient is at queue position #1 (top priority)
                        // 2. AND patient has an active queue entry
                        if (widget.queuePosition == 1 && _queueId != null) ...[
                          SizedBox(height: AppSpacing.xl),
                          
                          // Divider
                          Container(
                            height: 1,
                            margin: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                            color: AppColors.primary.withOpacity(0.1),
                          ),

                          SizedBox(height: AppSpacing.xl),

                          // Send to Doctor Button (simple animation)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return OutlinedButton(
                                  onPressed: _isSending ? null : _sendToDoctor,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    disabledForegroundColor: AppColors.accent.withOpacity(0.5),
                                    side: BorderSide(
                                      color: AppColors.accent.withOpacity(_isSending ? 0.3 : 0.5),
                                      width: 1.5,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                      horizontal: AppSpacing.lg,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Animated plane icon that flies away
                                      Transform.translate(
                                        offset: Offset(_flyAnimation.value * 200, 0),
                                        child: Opacity(
                                          opacity: 1 - _flyAnimation.value,
                                          child: Icon(
                                            Icons.send_rounded,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      // Text fades as plane flies
                                      Opacity(
                                        opacity: 1 - (_flyAnimation.value * 0.6),
                                        child: const Text('Send to Doctor'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: AppSpacing.xs),

                          // Helper text
                          Text(
                            '✓ Ready for doctor review',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
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
