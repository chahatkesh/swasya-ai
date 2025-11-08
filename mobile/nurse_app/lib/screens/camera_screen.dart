import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    print('📤 [CameraScreen] Adding image to upload queue...');
    
    try {
      final file = File(_imageFile!.path);
      
      // Add to queue - this is NON-BLOCKING!
      final taskId = _queueManager.addToQueue(
        patientId: widget.patientId,
        batchId: _batchId!,
        file: file,
      );

      print('✅ [CameraScreen] Added to queue with task ID: $taskId');

      setState(() {
        _documentCount++;
        _imageFile = null; // Clear immediately for next scan
        _isUploading = false; // Re-enable upload button
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_queue, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Document $_documentCount queued for upload')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      print('🎯 [CameraScreen] UI cleared, ready for next document');
    } catch (e) {
      print('❌ [CameraScreen] Failed to add to queue: $e');
      setState(() {
        _isUploading = false; // Re-enable on error
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to queue upload: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batch = _batchId != null ? _queueManager.getBatch(_batchId!) : null;
    final isUploading = _queueManager.isProcessing;
    final isPaused = _queueManager.isPaused;
    final totalUploaded = batch?.completedTasks ?? 0;
    final totalFailed = batch?.failedTasks ?? 0;
    final totalPending = batch?.pendingTasks ?? 0;
    final overallProgress = batch?.overallProgress ?? 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Document - ${widget.patientName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Pause/Resume button
          if (_documentCount > 0 && (isUploading || isPaused))
            IconButton(
              icon: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
              ),
              onPressed: () {
                if (isPaused) {
                  print('▶️ [CameraScreen] Resume uploads');
                  _queueManager.resumeQueue();
                } else {
                  print('⏸️ [CameraScreen] Pause uploads');
                  _queueManager.pauseQueue();
                }
              },
              tooltip: isPaused ? 'Resume' : 'Pause',
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Patient Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.person, size: 48, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text(
                        widget.patientName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${widget.patientId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (_batchId != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Documents Scanned: $_documentCount',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        // Upload status indicator
                        if (_documentCount > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUploading 
                                  ? Colors.blue[50]
                                  : isPaused
                                      ? Colors.orange[50]
                                      : Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isUploading 
                                    ? Colors.blue
                                    : isPaused
                                        ? Colors.orange
                                        : Colors.green,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isUploading
                                          ? Icons.cloud_upload
                                          : isPaused
                                              ? Icons.pause_circle
                                              : Icons.check_circle,
                                      size: 16,
                                      color: isUploading 
                                          ? Colors.blue
                                          : isPaused
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      isUploading
                                          ? 'Uploading...'
                                          : isPaused
                                              ? 'Paused'
                                              : 'All uploads complete',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isUploading 
                                            ? Colors.blue[900]
                                            : isPaused
                                                ? Colors.orange[900]
                                                : Colors.green[900],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '✓ $totalUploaded | ⏳ $totalPending${totalFailed > 0 ? ' | ✗ $totalFailed' : ''}',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                                ),
                                if (overallProgress > 0 && overallProgress < 1) ...[
                                  SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: overallProgress,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isUploading ? Colors.blue : Colors.green,
                                    ),
                                    minHeight: 3,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Image preview or placeholder
              if (_imageFile != null)
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_imageFile!.path),
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.document_scanner, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No image captured',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Main Action Buttons
              Row(
                children: [
                  // Camera Button
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _imageFile == null ? _takePicture : _uploadImage,
                        icon: Icon(_imageFile == null ? Icons.camera_alt : Icons.cloud_queue),
                        label: Text(
                          _imageFile == null ? 'Scan Document' : 'Queue Upload',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _imageFile == null ? Colors.blue : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // Done Button - ALWAYS VISIBLE
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isCompletingBatch 
                            ? null 
                            : (_documentCount > 0 ? _completeScanning : null),
                        icon: _isCompletingBatch
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle, size: 20),
                        label: Text(
                          _isCompletingBatch ? 'Processing...' : 'Done',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Helper text
              if (_documentCount == 0)
                Text(
                  'Tap "Scan Document" to start',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scanned $_documentCount document${_documentCount != 1 ? "s" : ""}. Tap "Done" when finished to generate timeline.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Skip button
              TextButton(
                onPressed: () {
                  print('🔙 [CameraScreen] User skipped, returning to previous screen');
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel & Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
