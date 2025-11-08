import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

enum UploadStatus { pending, uploading, completed, failed, paused }

class UploadTask {
  final String id;
  final String patientId;
  final String batchId;
  final File file;
  final String fileName;
  UploadStatus status;
  double progress;
  String? error;
  DateTime createdAt;
  DateTime? completedAt;

  UploadTask({
    required this.id,
    required this.patientId,
    required this.batchId,
    required this.file,
    required this.fileName,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.error,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'batchId': batchId,
        'fileName': fileName,
        'status': status.toString(),
        'progress': progress,
        'error': error,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };
}

class BatchInfo {
  final String batchId;
  final String patientId;
  final List<UploadTask> tasks;
  final DateTime createdAt;
  bool isCompleted;
  String? timelineId;

  BatchInfo({
    required this.batchId,
    required this.patientId,
    required this.tasks,
    DateTime? createdAt,
    this.isCompleted = false,
    this.timelineId,
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalTasks => tasks.length;
  int get completedTasks =>
      tasks.where((t) => t.status == UploadStatus.completed).length;
  int get failedTasks =>
      tasks.where((t) => t.status == UploadStatus.failed).length;
  int get pendingTasks => tasks.where((t) =>
      t.status == UploadStatus.pending || t.status == UploadStatus.paused).length;
  double get overallProgress =>
      tasks.isEmpty ? 0.0 : tasks.fold(0.0, (sum, t) => sum + t.progress) / tasks.length;
}

class UploadQueueManager extends ChangeNotifier {
  static final UploadQueueManager _instance = UploadQueueManager._internal();
  factory UploadQueueManager() => _instance;
  UploadQueueManager._internal();

  final Map<String, BatchInfo> _batches = {};
  final List<UploadTask> _queue = [];
  bool _isProcessing = false;
  bool _isPaused = false;
  int _concurrentUploads = 1; // Process one at a time for now

  // Getters
  List<BatchInfo> get allBatches => _batches.values.toList();
  List<UploadTask> get queue => List.unmodifiable(_queue);
  bool get isProcessing => _isProcessing;
  bool get isPaused => _isPaused;
  int get totalPending => _queue.where((t) => t.status == UploadStatus.pending).length;
  int get totalUploading => _queue.where((t) => t.status == UploadStatus.uploading).length;

  BatchInfo? getBatch(String batchId) => _batches[batchId];

  /// Start a new batch for a patient
  Future<String> startBatch(String patientId) async {
    _log('🚀 Starting new batch for patient: $patientId');
    
    try {
      final response = await ApiService.startDocumentBatch(patientId);
      final batchId = response['batch_id'];
      
      _batches[batchId] = BatchInfo(
        batchId: batchId,
        patientId: patientId,
        tasks: [],
      );
      
      _log('✅ Batch created successfully: $batchId');
      notifyListeners();
      return batchId;
    } catch (e) {
      _log('❌ Failed to start batch: $e');
      rethrow;
    }
  }

  /// Add a document to the upload queue
  String addToQueue({
    required String patientId,
    required String batchId,
    required File file,
  }) {
    final taskId = 'TASK_${DateTime.now().millisecondsSinceEpoch}_${_queue.length}';
    final fileName = file.path.split('/').last;
    
    final task = UploadTask(
      id: taskId,
      patientId: patientId,
      batchId: batchId,
      file: file,
      fileName: fileName,
    );

    _queue.add(task);
    
    final batch = _batches[batchId];
    if (batch != null) {
      batch.tasks.add(task);
    }

    _log('📝 Added to queue: $fileName (Task: $taskId, Batch: $batchId)');
    _log('📊 Queue status: ${_queue.length} total, $totalPending pending, $totalUploading uploading');
    
    notifyListeners();
    
    // Start processing if not already running
    if (!_isProcessing && !_isPaused) {
      _processQueue();
    }

    return taskId;
  }

  /// Process the upload queue in background
  Future<void> _processQueue() async {
    if (_isProcessing) {
      _log('⚠️ Already processing queue, skipping...');
      return;
    }

    _isProcessing = true;
    _log('⚙️ Started queue processor');

    while (_queue.isNotEmpty && !_isPaused) {
      final pendingTasks = _queue.where((t) => t.status == UploadStatus.pending).toList();
      
      if (pendingTasks.isEmpty) {
        _log('✨ No more pending tasks');
        break;
      }

      // Process tasks concurrently (currently set to 1)
      final batch = pendingTasks.take(_concurrentUploads).toList();
      await Future.wait(batch.map((task) => _uploadTask(task)));
    }

    _isProcessing = false;
    _log('🏁 Queue processor finished. isPaused: $_isPaused, remaining: ${_queue.length}');
    notifyListeners();
  }

  /// Upload a single task
  Future<void> _uploadTask(UploadTask task) async {
    _log('📤 Starting upload: ${task.fileName} (${task.id})');
    
    task.status = UploadStatus.uploading;
    task.progress = 0.0;
    notifyListeners();

    try {
      // Simulate progress updates (since we can't get real progress from http package easily)
      final progressTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
        if (task.status == UploadStatus.uploading && task.progress < 0.9) {
          task.progress += 0.1;
          notifyListeners();
          _log('📊 Upload progress: ${task.fileName} - ${(task.progress * 100).toStringAsFixed(0)}%');
        }
      });

      // Read file bytes
      final fileBytes = await task.file.readAsBytes();
      
      // Actual upload
      final response = await ApiService.uploadDocumentToBatch(
        patientId: task.patientId,
        batchId: task.batchId,
        fileBytes: fileBytes,
        fileName: task.fileName,
      );

      progressTimer.cancel();
      
      task.status = UploadStatus.completed;
      task.progress = 1.0;
      task.completedAt = DateTime.now();
      
      final duration = task.completedAt!.difference(task.createdAt).inSeconds;
      _log('✅ Upload completed: ${task.fileName} in ${duration}s');
      _log('📄 Document ID: ${response['document_id']}');
      
      notifyListeners();
    } catch (e) {
      task.status = UploadStatus.failed;
      task.error = e.toString();
      _log('❌ Upload failed: ${task.fileName}');
      _log('💥 Error: $e');
      notifyListeners();
    }
  }

  /// Pause the upload queue
  void pauseQueue() {
    _log('⏸️ Pausing upload queue');
    _isPaused = true;
    
    // Mark uploading tasks as paused (they'll continue current upload but won't start new ones)
    for (var task in _queue) {
      if (task.status == UploadStatus.pending) {
        task.status = UploadStatus.paused;
      }
    }
    
    notifyListeners();
  }

  /// Resume the upload queue
  void resumeQueue() {
    _log('▶️ Resuming upload queue');
    _isPaused = false;
    
    // Unpause tasks
    for (var task in _queue) {
      if (task.status == UploadStatus.paused) {
        task.status = UploadStatus.pending;
      }
    }
    
    notifyListeners();
    
    if (!_isProcessing) {
      _processQueue();
    }
  }

  /// Retry a failed task
  Future<void> retryTask(String taskId) async {
    final task = _queue.firstWhere((t) => t.id == taskId);
    
    _log('🔄 Retrying task: ${task.fileName}');
    task.status = UploadStatus.pending;
    task.progress = 0.0;
    task.error = null;
    
    notifyListeners();
    
    if (!_isProcessing && !_isPaused) {
      _processQueue();
    }
  }

  /// Complete batch and generate timeline
  Future<void> completeBatch(String batchId) async {
    _log('🎯 Marking batch for completion: $batchId');
    
    final batch = _batches[batchId];
    if (batch == null) {
      _log('❌ Batch not found: $batchId');
      throw Exception('Batch not found');
    }

    _log('📊 Batch status: ${batch.completedTasks}/${batch.totalTasks} completed, ${batch.pendingTasks} pending');
    
    // Mark batch as ready for completion (timeline will generate after uploads finish)
    batch.isCompleted = true;
    notifyListeners();
    
    // Start background timeline generation
    _generateTimelineWhenReady(batchId);
  }

  /// Generate timeline in background after all uploads complete
  Future<void> _generateTimelineWhenReady(String batchId) async {
    final batch = _batches[batchId];
    if (batch == null) {
      _log('❌ Batch not found for timeline generation: $batchId');
      return;
    }

    _log('⏳ Waiting for uploads to complete before generating timeline...');
    
    // Wait for ALL uploads to complete (check every second)
    // Count tasks that are NOT completed (pending, uploading, paused, or failed)
    int waitCount = 0;
    int notCompleted = batch.totalTasks - batch.completedTasks;
    
    while (notCompleted > 0 && waitCount < 60) {  // Max 60 seconds wait
      await Future.delayed(Duration(seconds: 1));
      waitCount++;
      notCompleted = batch.totalTasks - batch.completedTasks;
      
      if (waitCount % 5 == 0) {
        final uploading = batch.tasks.where((t) => t.status == UploadStatus.uploading).length;
        _log('⏳ Still waiting... ${notCompleted} uploads not completed (${waitCount}s) - Pending: ${batch.pendingTasks}, Uploading: ${uploading}');
      }
    }

    if (notCompleted > 0) {
      _log('⚠️ Timeout waiting for uploads. Generating timeline with ${batch.completedTasks} documents anyway.');
    }

    // Check if all tasks are completed
    final incompleteTasksList = batch.tasks.where((t) => t.status != UploadStatus.completed).toList();
    if (incompleteTasksList.isNotEmpty) {
      _log('⚠️ Batch has ${incompleteTasksList.length} incomplete tasks');
      _log('   Pending: ${batch.pendingTasks}, Failed: ${batch.failedTasks}');
    }

    try {
      _log('🧠 Generating timeline with AI for ${batch.completedTasks} documents...');
      final timeline = await ApiService.completeBatchAndGenerateTimeline(
        patientId: batch.patientId,
        batchId: batchId,
      );
      
      batch.timelineId = timeline['timeline_id'];
      
      _log('✅ Timeline generated successfully!');
      _log('📋 Timeline ID: ${timeline['timeline_id']}');
      _log('📅 Events: ${timeline['timeline']?['timeline_events']?.length ?? 0}');
      _log('💊 Medications: ${timeline['timeline']?['current_medications']?.length ?? 0}');
      _log('🏥 Conditions: ${timeline['timeline']?['chronic_conditions']?.length ?? 0}');
      
      notifyListeners();
    } catch (e) {
      _log('❌ Failed to generate timeline: $e');
      // Don't rethrow - this is background processing
    }
  }

  /// Clear completed tasks from queue
  void clearCompleted() {
    final beforeCount = _queue.length;
    _queue.removeWhere((t) => t.status == UploadStatus.completed);
    final removedCount = beforeCount - _queue.length;
    
    _log('🧹 Cleared $removedCount completed tasks from queue');
    notifyListeners();
  }

  /// Get batch statistics
  Map<String, dynamic> getBatchStats(String batchId) {
    final batch = _batches[batchId];
    if (batch == null) return {};

    return {
      'total': batch.totalTasks,
      'completed': batch.completedTasks,
      'failed': batch.failedTasks,
      'pending': batch.pendingTasks,
      'progress': batch.overallProgress,
      'isCompleted': batch.isCompleted,
    };
  }

  /// Detailed logging helper
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].substring(0, 12);
    debugPrint('[$timestamp] [UploadQueue] $message');
  }

  /// Clear all data (for testing/debugging)
  void clearAll() {
    _log('🗑️ Clearing all batches and queue');
    _batches.clear();
    _queue.clear();
    _isProcessing = false;
    _isPaused = false;
    notifyListeners();
  }
}
