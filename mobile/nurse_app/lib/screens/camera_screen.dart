import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/core.dart';
import '../services/upload_queue_manager.dart';

class CameraScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const CameraScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final UploadQueueManager _queueManager = UploadQueueManager();
  
  XFile? _imageFile;
  String? _batchId;
  int _documentCount = 0;
  bool _isCompletingBatch = false;
  bool _isUploading = false; // Prevent double-click uploads

  @override
  void initState() {
    super.initState();
    _startBatch();
    
    // Listen to queue updates for live UI refresh
    _queueManager.addListener(_onQueueUpdate);
    
    print('🎬 [CameraScreen] Initialized for patient: ${widget.patientId}');
  }
  
  @override
  void dispose() {
    _queueManager.removeListener(_onQueueUpdate);
    print('🛑 [CameraScreen] Disposed');
    super.dispose();
  }
  
  void _onQueueUpdate() {
    if (mounted) {
      setState(() {}); // Rebuild when queue changes
    }
  }

  Future<void> _startBatch() async {
    try {
      print('🚀 [CameraScreen] Starting batch for patient: ${widget.patientId}');
      
      final batchId = await _queueManager.startBatch(widget.patientId);
      
      setState(() {
        _batchId = batchId;
      });
      
      print('✅ [CameraScreen] Batch started: $batchId');
    } catch (e) {
      print('❌ [CameraScreen] Failed to start batch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start scanning session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    print('📸 [CameraScreen] Opening camera...');
    
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        print('📷 [CameraScreen] Picture captured: ${photo.path}');
        
        setState(() {
          _imageFile = photo;
        });
      } else {
        print('⚠️ [CameraScreen] No photo captured (user cancelled)');
      }
    } catch (e) {
      print('❌ [CameraScreen] Camera error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null || _batchId == null) {
      print('⚠️ [CameraScreen] Cannot upload: imageFile=${_imageFile != null}, batchId=${_batchId != null}');
      return;
    }

    // Prevent double-click uploads
    if (_isUploading) {
      print('⚠️ [CameraScreen] Upload already in progress, ignoring double-click');
      return;
    }

    _isUploading = true;
    final imagePath = _imageFile!.path;
    final imageFileName = imagePath.split('/').last;
    
    print('📤 [CameraScreen] Auto-queuing image for upload...');
    print('   Image file: $imageFileName');
    print('   Batch ID: $_batchId');
    
    try {
      final file = File(imagePath);
      
      if (!await file.exists()) {
        print('❌ [CameraScreen] File does not exist: $imagePath');
        throw Exception('Image file not found');
      }
      
      // Add to queue automatically
      final taskId = _queueManager.addToQueue(
        patientId: widget.patientId,
        batchId: _batchId!,
        file: file,
      );

      print('✅ [CameraScreen] Auto-queued with task ID: $taskId');

      setState(() {
        _documentCount++;
        _imageFile = null; // Clear for next scan
        _isUploading = false;
      });

      if (!mounted) return;

      // Show brief success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document $_documentCount queued ✓'),
          backgroundColor: AppColors.success,
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            left: 20,
            right: 20,
          ),
        ),
      );
      
      print('🎯 [CameraScreen] Ready for next document');
    } catch (e) {
      print('❌ [CameraScreen] Failed to queue: $e');
      setState(() {
        _isUploading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to queue: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _completeScanning() async {
    if (_batchId == null || _documentCount == 0) {
      print('⚠️ [CameraScreen] Cannot complete: batchId=${_batchId != null}, documentCount=$_documentCount');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan at least one document'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('✅ [CameraScreen] Nurse completed scanning. Processing will continue in background.');
    print('📋 [CameraScreen] Batch $_batchId with $_documentCount documents marked for background processing');
    
    // Mark batch as ready for timeline generation (will happen after uploads complete)
    try {
      await _queueManager.completeBatch(_batchId!);
      print('✅ [CameraScreen] Batch marked for completion');
    } catch (e) {
      print('⚠️ [CameraScreen] Error marking batch complete (uploads will still continue): $e');
    }

    if (!mounted) return;

    // Show confirmation and return immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Processing Started')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents will be processed in the background.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Text(
              '✓ $_documentCount document(s) queued',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              '✓ Timeline will be generated automatically',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              '✓ You can continue with next patient',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Patient will show "Processing" status on home screen',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              print('✅ [CameraScreen] Returning to home screen');
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batch = _batchId != null ? _queueManager.getBatch(_batchId!) : null;
    final isUploading = _queueManager.isProcessing;
    final totalUploaded = batch?.completedTasks ?? 0;
    final totalPending = batch?.pendingTasks ?? 0;
    
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
          'AI Digitizer',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Patient header
            Container(
              margin: EdgeInsets.all(AppSpacing.lg),
              padding: EdgeInsets.all(AppSpacing.lg),
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
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs - 2),
                        Text(
                          'Document Scanning Session',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_documentCount',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Upload status (if any documents)
            if (_documentCount > 0) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isUploading
                      ? AppColors.info.withOpacity(0.08)
                      : AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUploading
                        ? AppColors.info.withOpacity(0.3)
                        : AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUploading ? Icons.cloud_upload : Icons.check_circle,
                      color: isUploading ? AppColors.info : AppColors.success,
                      size: 20,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUploading ? 'Uploading documents...' : 'All uploads complete',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isUploading ? AppColors.info : AppColors.success,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs - 2),
                          Text(
                            '✓ $totalUploaded uploaded • ⏳ $totalPending pending',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],
            
            Expanded(
              child: Center(
                child: _imageFile == null
                    ? _buildScanPrompt()
                    : _buildImagePreview(),
              ),
            ),
            
            // Action buttons at bottom
            Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_documentCount > 0)
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      margin: EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Tap "Finish" when done to generate timeline',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _takePicture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.secondary,
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt, size: 24, color: Colors.white),
                          label: Text(
                            _imageFile == null ? 'Scan Document' : 'Scan Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (_documentCount > 0) ...[
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isCompletingBatch ? null : _completeScanning,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.secondary,
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: AppColors.textTertiary,
                            ),
                            icon: _isCompletingBatch
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: AppColors.secondary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle, size: 20),
                            label: Text(
                              _isCompletingBatch ? 'Processing' : 'Finish',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanPrompt() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.document_scanner_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Text(
                  _documentCount == 0
                      ? 'Start Scanning'
                      : 'Scan Next Document',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  _documentCount == 0
                      ? 'Tap the button below to begin'
                      : '$_documentCount document${_documentCount != 1 ? "s" : ""} scanned so far',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 28,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Text(
                        'Document Captured!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Icon(
                  Icons.cloud_queue,
                  size: 80,
                  color: AppColors.accent,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Auto-queuing for upload...',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).also((_) {
      // Auto-queue after animation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _imageFile != null) {
          _uploadImage();
        }
      });
    });
  }
}

extension _WidgetExtension on Widget {
  Widget also(void Function(Widget) action) {
    action(this);
    return this;
  }
}
