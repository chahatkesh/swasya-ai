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

    final batch = _queueManager.getBatch(_batchId!);
    if (batch == null) {
      print('❌ [CameraScreen] Batch not found: $_batchId');
      return;
    }

    // Check if uploads are still pending
    if (batch.pendingTasks > 0 || _queueManager.isProcessing) {
      print('⚠️ [CameraScreen] Uploads still in progress: pending=${batch.pendingTasks}, processing=${_queueManager.isProcessing}');
      
      final shouldWait = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.upload, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('Uploads in Progress')),
            ],
          ),
          content: Text(
            '${batch.pendingTasks} document(s) are still uploading.\n\n'
            'Would you like to wait for completion?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('👤 [CameraScreen] User chose to wait');
                Navigator.pop(context, true);
              },
              child: const Text('Wait'),
            ),
            TextButton(
              onPressed: () {
                print('👤 [CameraScreen] User chose to complete anyway');
                Navigator.pop(context, false);
              },
              child: const Text('Complete Anyway'),
            ),
          ],
        ),
      );
      
      if (shouldWait == null) return; // Dialog dismissed
      
      if (shouldWait) {
        // Show waiting indicator
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Waiting for uploads to complete...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
        
        // Wait for uploads to complete (max 30 seconds)
        int waitCount = 0;
        while (batch.pendingTasks > 0 && waitCount < 30) {
          await Future.delayed(Duration(seconds: 1));
          waitCount++;
          print('⏳ [CameraScreen] Waiting... ${batch.pendingTasks} remaining (${waitCount}s)');
        }
      }
    }

    setState(() {
      _isCompletingBatch = true;
    });

    try {
      print('🎯 [CameraScreen] Completing batch and generating timeline...');
      print('📊 [CameraScreen] Batch stats: ${batch.completedTasks}/${batch.totalTasks} completed, ${batch.failedTasks} failed');

      final response = await _queueManager.completeBatch(_batchId!);

      setState(() {
        _isCompletingBatch = false;
      });

      print('✅ [CameraScreen] Timeline generated successfully!');

      if (!mounted) return;

      // Show timeline summary
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.timeline, color: Colors.blue, size: 32),
              SizedBox(width: 8),
              Expanded(child: Text('Timeline Generated!')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient: ${widget.patientName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildStat('Documents Processed', '${response['statistics']['documents_processed']}'),
                _buildStat('Timeline Events', '${response['statistics']['timeline_events']}'),
                _buildStat('Current Medications', '${response['statistics']['current_medications']}'),
                _buildStat('Chronic Conditions', '${response['statistics']['chronic_conditions']}'),
                const SizedBox(height: 16),
                if (response['timeline']?['summary'] != null) ...[
                  const Text(
                    'Summary:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    response['timeline']['summary'],
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                print('✅ [CameraScreen] User completed workflow, returning to home');
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ [CameraScreen] Failed to complete batch: $e');
      setState(() {
        _isCompletingBatch = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate timeline: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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
                                  '✓ $totalUploaded | ⏳ $totalPending' + 
                                  (totalFailed > 0 ? ' | ✗ $totalFailed' : ''),
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
