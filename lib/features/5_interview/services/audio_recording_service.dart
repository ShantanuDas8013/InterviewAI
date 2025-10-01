import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for recording audio to files for AssemblyAI transcription
///
/// This service handles:
/// - Microphone permissions
/// - Audio recording to file
/// - File management for recorded audio
class AudioRecordingService {
  static final AudioRecordingService _instance =
      AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isInitialized = false;
  bool _isRecording = false;
  String? _currentRecordingPath;

  /// Initialize the recording service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();

      if (permissionStatus != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // Check if recorder is available
      final isSupported = await _recorder.hasPermission();
      if (!isSupported) {
        debugPrint('Audio recording not supported on this device');
        return false;
      }

      _isInitialized = true;
      debugPrint('Audio recording service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing audio recording service: $e');
      return false;
    }
  }

  /// Start recording audio to a file
  ///
  /// Returns the file path where audio is being recorded
  Future<String?> startRecording() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception('Failed to initialize audio recording service');
        }
      }

      if (_isRecording) {
        debugPrint('Already recording, stopping previous recording first');
        await stopRecording();
      }

      // Generate unique file path for this recording
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'interview_audio_$timestamp.wav';
      _currentRecordingPath = '${directory.path}/$fileName';

      // Configure recording settings for optimal AssemblyAI compatibility
      const config = RecordConfig(
        encoder: AudioEncoder.wav, // WAV format for best compatibility
        bitRate: 128000, // 128 kbps
        sampleRate: 44100, // 44.1 kHz sample rate
        numChannels: 1, // Mono audio
        autoGain: true, // Enable automatic gain control
        echoCancel: true, // Enable echo cancellation
        noiseSuppress: true, // Enable noise suppression
      );

      await _recorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;

      debugPrint('Audio recording started: $_currentRecordingPath');
      return _currentRecordingPath;
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      rethrow;
    }
  }

  /// Stop recording and return the recorded file path
  ///
  /// Returns the path to the recorded audio file, or null if no recording was in progress
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        debugPrint('No recording in progress');
        return null;
      }

      final recordingPath = await _recorder.stop();
      _isRecording = false;

      if (recordingPath != null && recordingPath == _currentRecordingPath) {
        final file = File(recordingPath);
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint(
            'Audio recording stopped: $recordingPath ($fileSize bytes)',
          );

          // Validate minimum file size (at least 1KB to ensure we have actual audio)
          if (fileSize < 1024) {
            debugPrint(
              'Warning: Recorded file is very small ($fileSize bytes)',
            );
          }

          return recordingPath;
        } else {
          debugPrint('Error: Recorded file does not exist at expected path');
          return null;
        }
      } else {
        debugPrint('Error: Recording path mismatch or null');
        return null;
      }
    } catch (e) {
      debugPrint('Error stopping audio recording: $e');
      _isRecording = false;
      return null;
    } finally {
      _currentRecordingPath = null;
    }
  }

  /// Cancel current recording without saving
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;

        // Delete the incomplete recording file
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint(
              'Cancelled recording file deleted: $_currentRecordingPath',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error cancelling audio recording: $e');
    } finally {
      _currentRecordingPath = null;
      _isRecording = false;
    }
  }

  /// Get recording amplitude/level for UI visualization
  ///
  /// Returns amplitude value between 0.0 and 1.0
  Future<double> getAmplitude() async {
    try {
      if (_isRecording) {
        final amplitude = await _recorder.getAmplitude();
        // Convert to 0.0 - 1.0 range for UI
        return amplitude.current.clamp(0.0, 1.0);
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error getting recording amplitude: $e');
      return 0.0;
    }
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get current recording file path (if recording)
  String? get currentRecordingPath => _currentRecordingPath;

  /// Clean up old recording files to save storage space
  ///
  /// [olderThanHours] - Delete files older than this many hours (default: 24)
  Future<void> cleanupOldRecordings({int olderThanHours = 24}) async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();
      final cutoffTime = DateTime.now().subtract(
        Duration(hours: olderThanHours),
      );

      int deletedCount = 0;
      for (final file in files) {
        if (file is File && file.path.contains('interview_audio_')) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint('Cleaned up $deletedCount old recording files');
      }
    } catch (e) {
      debugPrint('Error cleaning up old recordings: $e');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await cancelRecording();
      }
      await _recorder.dispose();
      debugPrint('Audio recording service disposed');
    } catch (e) {
      debugPrint('Error disposing audio recording service: $e');
    }
  }
}
