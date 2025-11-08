import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

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
  XFile? _imageFile;
  bool _isUploading = false;
  String? _batchId;
  int _documentCount = 0;
  List<Map<String, dynamic>> _uploadedDocuments = [];

  @override
  void initState() {
    super.initState();
    _startBatch();
  }

  Future<void> _startBatch() async {
    try {
      final response = await ApiService.startDocumentBatch(widget.patientId);
      setState(() {
        _batchId = response['batch_id'];
      });
      print('✅ Batch started: $_batchId');
    } catch (e) {
      print('❌ Failed to start batch: $e');
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
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = photo;
        });
      }
    } catch (e) {
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
    if (_imageFile == null || _batchId == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Read file
      final file = File(_imageFile!.path);
      final fileBytes = await file.readAsBytes();
      final fileName = 'prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('📸 Uploading document to batch: $_batchId');

      // Upload to batch
      final response = await ApiService.uploadDocumentToBatch(
        patientId: widget.patientId,
        batchId: _batchId!,
        fileBytes: fileBytes,
        fileName: fileName,
      );

      print('✅ Document uploaded: ${response['document_id']}');

      setState(() {
        _documentCount++;
        _uploadedDocuments.add(response);
        _imageFile = null; // Clear for next photo
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document ${response['document_number']} uploaded!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Upload error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _completeScanning() async {
    if (_batchId == null || _documentCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan at least one document'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      print('🎯 Completing batch and generating timeline...');

      final response = await ApiService.completeBatchAndGenerateTimeline(
        patientId: widget.patientId,
        batchId: _batchId!,
      );

      print('✅ Timeline generated!');

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
      print('❌ Complete error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate timeline: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Document - ${widget.patientName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
              
              // Camera Button
              if (_imageFile == null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      'Capture Prescription',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // Upload Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadImage,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(
                          _isUploading ? 'Uploading...' : 'Upload Document',
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Scan Another Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _takePicture,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text(
                          'Scan Another',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    if (_documentCount > 0) ...[
                      const SizedBox(height: 16),
                      // Complete Scanning Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _completeScanning,
                          icon: const Icon(Icons.check_circle),
                          label: const Text(
                            'Complete & Generate Timeline',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              
              const SizedBox(height: 24),
              
              // Skip button
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Skip & Finish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
