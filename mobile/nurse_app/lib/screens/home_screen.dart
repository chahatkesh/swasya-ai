import 'package:flutter/material.dart';
import '../core/core.dart';
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
  bool _isRefreshing = false; // Track silent background refresh
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

  Future<void> _loadTodaysPatients({bool silent = false}) async {
    // Silent mode: refresh in background without showing loading spinner
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      // Show subtle refresh indicator for silent updates
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final startTime = DateTime.now();
      print('📥 [HomeScreen] Fetching today\'s patient queue... ${silent ? "(silent background refresh)" : ""}');
      print('   ⏱️ Request started at: ${startTime.hour}:${startTime.minute}:${startTime.second}');
      
      // Fetch active queue (patients waiting for nurse or doctor)
      final response = await ApiService.getQueue();
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('   ⏱️ Response received at: ${endTime.hour}:${endTime.minute}:${endTime.second}');
      print('   ⏱️ API call took: ${duration.inSeconds}s ${duration.inMilliseconds % 1000}ms');
      
      if (!mounted) return; // Check if widget is still mounted
      
      // Filter for active queue entries only (nurse's queue)
      // Only show patients still waiting for nurse to work on them
      final queue = List<Map<String, dynamic>>.from(response['queue'] ?? []);
      final activeQueue = queue.where((entry) {
        final status = entry['status'] as String?;
        // Only show: waiting (patients nurse needs to work on)
        // Exclude: nurse_completed (handed to doctor), ready_for_doctor (with doctor),
        //          in_consultation (with doctor), completed, cancelled
        return status == 'waiting';
      }).toList();
      
      // Convert queue entries to patient format (add queue_id to each)
      final patients = activeQueue.map((queueEntry) {
        return {
          'patient_id': queueEntry['patient_id'],
          'name': queueEntry['patient_name'],
          'queue_id': queueEntry['queue_id'],
          'queue_status': queueEntry['status'],
          'token_number': queueEntry['token_number'],
          'priority': queueEntry['priority'],
          // Add empty counts so UI doesn't show "No additional info"
          'notes_count': 0,
          'history_count': 0,
        };
      }).toList();
      
      setState(() {
        _patients = patients;
        _isLoading = false;
        _isRefreshing = false;
      });
      
      print('✅ [HomeScreen] Loaded ${_patients.length} active patients in queue');
      
      // Debug: print patient IDs
      if (_patients.isNotEmpty) {
        for (var patient in _patients) {
          print('   - ${patient['name']} (ID: ${patient['patient_id']})');
        }
      }
    } catch (e) {
      print('❌ [HomeScreen] Failed to load patients: $e');
      if (!mounted) return; // Check if widget is still mounted
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isRefreshing = false;
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
        return AppColors.success;
      case 'generating':
        return AppColors.accent;
      case 'uploading':
        return AppColors.primary;
      case 'processing':
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }

  void _navigateToPatientDetail(Map<String, dynamic> patient, {int? queuePosition}) {
    print('👤 [HomeScreen] Navigating to patient detail: ${patient['patient_id']} (Queue Position: $queuePosition)');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(
          patientId: patient['patient_id'],
          patientName: patient['name'],
          queuePosition: queuePosition,
          queueId: patient['queue_id'],  // NEW: Pass queue_id
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
      // Use silent=true to keep showing current list while refreshing
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          print('🔁 [HomeScreen] Performing silent background refresh of patient list');
          _loadTodaysPatients(silent: true);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        title: Text(
          AppConstants.appName,
          style: AppTypography.h3Card.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              print('🔄 [HomeScreen] Manual refresh triggered');
              _loadTodaysPatients();
            },
            tooltip: 'Refresh',
          ),
          SizedBox(width: AppSpacing.xs),
        ],
        // Show subtle progress bar when refreshing silently in background
        bottom: _isRefreshing
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3.0),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.secondary,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Loading today\'s patients...',
                    style: AppTypography.bodyRegular,
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: AppSpacing.iconXLarge + 16,
                          color: AppColors.error,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          'Failed to load patients',
                          style: AppTypography.h3Card,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xxl),
                        ElevatedButton.icon(
                          onPressed: _loadTodaysPatients,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
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
                          Icon(
                            Icons.people_outline,
                            size: AppSpacing.iconXLarge + 32,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(height: AppSpacing.lg),
                          Text(
                            'No patients today',
                            style: AppTypography.h3Card.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Register a new patient to get started',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadTodaysPatients();
                      },
                      child: Column(
                        children: [
                          // Header Banner
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.xl,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryHover],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Today\'s Queue',
                                      style: AppTypography.h2Section.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '${_patients.length} patient${_patients.length != 1 ? 's' : ''} registered',
                                      style: AppTypography.bodyRegular.copyWith(
                                        color: AppColors.secondary.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                  ),
                                  child: Text(
                                    '${_patients.length}',
                                    style: AppTypography.h1Hero.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Patient list - chronological order (newest at bottom)
                          Expanded(
                            child: ListView.builder(
                              itemCount: _patients.length,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              itemBuilder: (context, index) {
                                // Direct index (newest patients appear at bottom)
                                final patient = _patients[index];
                                final queuePosition = index + 1; // Position in queue (1-based)
                                final status = _getPatientStatus(patient);
                                final patientName = patient['name'] ?? 'Unknown Patient';
                                final queueStatus = patient['queue_status'] ?? 'waiting';
                                final tokenNumber = patient['token_number'];
                                
                                // Build secondary info line from queue data
                                final List<String> infoItems = [];
                                if (tokenNumber != null) {
                                  infoItems.add('Token #$tokenNumber');
                                }
                                // Show queue status in readable format
                                String statusText = '';
                                switch (queueStatus) {
                                  case 'waiting':
                                    statusText = 'Waiting for nurse';
                                    break;
                                  case 'nurse_completed':
                                    statusText = 'Notes ready';
                                    break;
                                  case 'ready_for_doctor':
                                    statusText = 'Ready for doctor';
                                    break;
                                  default:
                                    statusText = queueStatus;
                                }
                                if (statusText.isNotEmpty) {
                                  infoItems.add(statusText);
                                }
                                final secondaryInfo = infoItems.isNotEmpty 
                                    ? infoItems.join(' • ') 
                                    : 'In queue';
                                
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 400 + (index * 50)),
                                  curve: Curves.easeOut,
                                  builder: (context, animValue, child) {
                                    return Opacity(
                                      opacity: animValue,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - animValue)),
                                        child: Container(
                                          margin: EdgeInsets.only(bottom: AppSpacing.md),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Queue position with connecting line
                                              SizedBox(
                                                width: 50,
                                                child: Column(
                                                  children: [
                                                    // Position badge
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: queuePosition == 1
                                                              ? [AppColors.accent, AppColors.accent.withOpacity(0.8)]
                                                              : [AppColors.primary, AppColors.primaryHover],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: AppColors.secondary,
                                                          width: 2.5,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: (queuePosition == 1 ? AppColors.accent : AppColors.primary)
                                                                .withOpacity(0.3),
                                                            blurRadius: 8,
                                                            spreadRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '$queuePosition',
                                                          style: TextStyle(
                                                            fontSize: queuePosition == 1 ? 18 : 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.secondary,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Connecting line (not for last item)
                                                    if (index < _patients.length - 1)
                                                      Container(
                                                        width: 3,
                                                        height: 50,
                                                        margin: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              AppColors.primary.withOpacity(0.4),
                                                              AppColors.primary.withOpacity(0.1),
                                                            ],
                                                            begin: Alignment.topCenter,
                                                            end: Alignment.bottomCenter,
                                                          ),
                                                          borderRadius: BorderRadius.circular(2),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Patient card
                                              Expanded(
                                                child: Container(
                                                  height: 88,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.secondary,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: queuePosition == 1
                                                          ? AppColors.accent.withOpacity(0.3)
                                                          : AppColors.primary.withOpacity(0.15),
                                                      width: queuePosition == 1 ? 2 : 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.04),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () => _navigateToPatientDetail(patient, queuePosition: queuePosition),
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Padding(
                                                        padding: EdgeInsets.all(AppSpacing.md),
                                                        child: Row(
                                                          children: [
                                                            // Status indicator
                                                            Container(
                                                              width: 48,
                                                              height: 48,
                                                              decoration: BoxDecoration(
                                                                color: _getStatusColor(status).withOpacity(0.12),
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              child: status == 'uploading' || status == 'generating'
                                                                  ? Center(
                                                                      child: SizedBox(
                                                                        width: 24,
                                                                        height: 24,
                                                                        child: CircularProgressIndicator(
                                                                          strokeWidth: 2.5,
                                                                          valueColor: AlwaysStoppedAnimation<Color>(
                                                                            _getStatusColor(status),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    )
                                                                  : Icon(
                                                                      _getStatusIcon(status),
                                                                      color: _getStatusColor(status),
                                                                      size: 24,
                                                                    ),
                                                            ),
                                                            SizedBox(width: AppSpacing.md),
                                                            
                                                            // Patient details
                                                            Expanded(
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  // Queue badge + name
                                                                  Row(
                                                                    children: [
                                                                      if (queuePosition == 1)
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal: 6,
                                                                            vertical: 2,
                                                                          ),
                                                                          decoration: BoxDecoration(
                                                                            color: AppColors.accent,
                                                                            borderRadius: BorderRadius.circular(4),
                                                                          ),
                                                                          child: Text(
                                                                            'NEXT',
                                                                            style: TextStyle(
                                                                              fontSize: 9,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: AppColors.secondary,
                                                                              letterSpacing: 0.5,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      if (queuePosition == 1)
                                                                        const SizedBox(width: 6),
                                                                      Expanded(
                                                                        child: Text(
                                                                          patientName,
                                                                          style: TextStyle(
                                                                            fontSize: 15,
                                                                            fontWeight: queuePosition == 1 
                                                                                ? FontWeight.bold 
                                                                                : FontWeight.w600,
                                                                            color: const Color(0xFF2C3E50),
                                                                            letterSpacing: -0.2,
                                                                            height: 1.2,
                                                                          ),
                                                                          maxLines: 1,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(height: 4),
                                                                  
                                                                  // Secondary info
                                                                  Text(
                                                                    secondaryInfo,
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: AppColors.textSecondary,
                                                                      letterSpacing: -0.1,
                                                                      height: 1.2,
                                                                    ),
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            
                                                            // Arrow icon
                                                            Icon(
                                                              Icons.arrow_forward_ios,
                                                              size: 16,
                                                              color: AppColors.textTertiary,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PatientRegistrationScreen(),
            ),
          ).then((_) {
            _loadTodaysPatients(); // Reload list after registration
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('New Patient'),
      ),
    );
  }
}
