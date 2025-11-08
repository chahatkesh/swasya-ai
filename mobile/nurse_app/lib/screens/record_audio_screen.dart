import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import '../core/core.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Scribe',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (!_isRecording && !_isUploading)
            IconButton(
              icon: Icon(Icons.upload_file_outlined, color: AppColors.primary),
              onPressed: _pickAudioFile,
              tooltip: 'Upload audio file',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isRecording
                    ? [
                        AppColors.secondary,
                        AppColors.error.withOpacity(0.05),
                        AppColors.accent.withOpacity(0.08),
                      ]
                    : [
                        AppColors.secondary,
                        AppColors.primary.withOpacity(0.03),
                        AppColors.background,
                      ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: AppSpacing.lg),
                
                // Patient name header
                Container(
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
                              'Voice Recording Session',
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
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isRecording 
                              ? AppColors.error.withOpacity(0.12)
                              : _isUploading
                                  ? AppColors.accent.withOpacity(0.12)
                                  : AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isRecording)
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.6, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Icon(
                                      Icons.fiber_manual_record,
                                      color: AppColors.error,
                                      size: 12,
                                    ),
                                  );
                                },
                                onEnd: () {
                                  if (mounted && _isRecording) {
                                    setState(() {}); // Loop animation
                                  }
                                },
                              ),
                            if (_isRecording) const SizedBox(width: 4),
                            Text(
                              _isRecording ? 'REC' : _isUploading ? 'UPLOADING' : 'READY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isRecording 
                                    ? AppColors.error 
                                    : _isUploading 
                                        ? AppColors.accent 
                                        : AppColors.success,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Central area - Recording visualizer or status
                if (_isUploading)
                  _buildUploadingState()
                else if (_isRecording)
                  _buildRecordingState()
                else
                  _buildReadyState(),
                
                const Spacer(),
                
                // Record button
                _buildRecordButton(),
                
                SizedBox(height: AppSpacing.xl),
                
                // Instruction text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Text(
                    _isRecording
                        ? 'Tap to stop and process'
                        : _isUploading
                            ? 'Processing your audio...'
                            : 'Tap to start recording',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                if (!_isRecording && !_isUploading) ...[
                  SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                    child: Text(
                      'AI will automatically generate SOAP notes from your recording',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                
                SizedBox(height: AppSpacing.xxxl + 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ready to Record',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          'Press the button below to begin',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer
        Text(
          _formatDuration(_recordingDuration),
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
            fontFeatures: const [
              FontFeature.tabularFigures(),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        
        // Audio waveform animation
        _AudioWaveform(isRecording: _isRecording),
        
        SizedBox(height: AppSpacing.lg),
        Text(
          'Recording in progress',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 2 * math.pi,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent,
                      AppColors.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: AppColors.accent,
                      size: 40,
                    ),
                  ),
                ),
              ),
            );
          },
          onEnd: () {
            if (mounted && _isUploading) {
              setState(() {}); // Loop animation
            }
          },
        ),
        SizedBox(height: AppSpacing.xl),
        Text(
          'Processing Audio',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Generating SOAP notes with AI',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: _isUploading
            ? null
            : () {
                if (_isRecording) {
                  _stopRecording();
                } else {
                  _startRecording();
                }
              },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing ring when recording
            if (_isRecording)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1.15),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: 1.3 - (value * 0.5),
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.error,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                onEnd: () {
                  if (mounted && _isRecording) {
                    setState(() {}); // Loop animation
                  }
                },
              ),
            
            // Main button
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isRecording
                      ? [AppColors.error, AppColors.error.withOpacity(0.8)]
                      : [AppColors.primary, AppColors.primaryHover],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? AppColors.error : AppColors.primary)
                        .withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic,
                size: 64,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom animated waveform widget
class _AudioWaveform extends StatefulWidget {
  final bool isRecording;

  const _AudioWaveform({required this.isRecording});

  @override
  State<_AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<_AudioWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = List.generate(25, (index) => 0.3);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
        if (widget.isRecording) {
          setState(() {
            // Randomize bar heights for wave effect
            for (int i = 0; i < _barHeights.length; i++) {
              _barHeights[i] = 0.2 + (math.Random().nextDouble() * 0.8);
            }
          });
        }
      });
    
    if (widget.isRecording) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _controller.repeat();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _controller.stop();
      setState(() {
        for (int i = 0; i < _barHeights.length; i++) {
          _barHeights[i] = 0.3;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(25, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: _barHeights[index]),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Container(
                width: 3,
                height: 80 * value,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
