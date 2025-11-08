import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';

/// Screen for recording and uploading audio for SOAP note generation
/// This is for the SCRIBE workflow - single audio file, direct upload, SOAP notes
class RecordAudioScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const RecordAudioScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<RecordAudioScreen> createState() => _RecordAudioScreenState();
}

class _RecordAudioScreenState extends State<RecordAudioScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  Timer? _timer;
  
  bool _isRecording = false;
  bool _isUploading = false;
  bool _isRecorderInitialized = false;
  Duration _recordingDuration = Duration.zero;
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _initializeRecorder() async {
    try {
      await _recorder.openRecorder();
      setState(() {
        _isRecorderInitialized = true;
      });
      await _requestPermissions();
    } catch (e) {
      print('❌ Error initializing recorder: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!_isRecorderInitialized) {
        throw Exception('Recorder not initialized');
      }

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDocDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacMP4,
        bitRate: 128000,  // 128 kbps for good quality
        sampleRate: 44100,  // CD quality sample rate
      );

      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        _recordingDuration = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() {
            _recordingDuration = DateTime.now().difference(_recordingStartTime!);
          });
        }
      });

      print('🎤 Started recording: $filePath');
    } catch (e) {
      print('❌ Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final String? path = await _recorder.stopRecorder();
      _timer?.cancel();

      setState(() {
        _isRecording = false;
      });

      print('🛑 Stopped recording: $path');

      if (path != null) {
        await _uploadAudio(path);
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  Future<void> _uploadAudio(String filePath) async {
    try {
      setState(() {
        _isUploading = true;
      });

      print('📤 Uploading audio: $filePath');
      
      final File file = File(filePath);
      final List<int> fileBytes = await file.readAsBytes();
      final String fileName = filePath.split('/').last;

      final response = await ApiService.uploadAudio(
        patientId: widget.patientId,
        fileBytes: fileBytes,
        fileName: fileName,
      );

      print('✅ Audio uploaded successfully: ${response['note_id']}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio uploaded! SOAP note is being generated...'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error uploading audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        final String filePath = result.files.single.path!;
        print('📁 Selected audio file: $filePath');
        await _uploadAudio(filePath);
      }
    } catch (e) {
      print('❌ Error picking audio file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours != '00' ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Audio - ${widget.patientName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _isUploading ? null : _pickAudioFile,
            tooltip: 'Upload audio file',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRecording)
              Column(
                children: [
                  const Icon(
                    Icons.fiber_manual_record,
                    color: Colors.red,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recording...',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else if (_isUploading)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Uploading audio...',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Icon(
                    Icons.mic,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ready to record',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),

            const SizedBox(height: 48),

            GestureDetector(
              onTap: _isUploading
                  ? null
                  : () {
                      if (_isRecording) {
                        _stopRecording();
                      } else {
                        _startRecording();
                      }
                    },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Colors.blue).withAlpha((0.3 * 255).toInt()),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _isRecording
                    ? 'Tap to stop recording'
                    : 'Tap to start recording',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            if (!_isRecording && !_isUploading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Audio will be uploaded and processed in the background. SOAP note will be generated automatically.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
