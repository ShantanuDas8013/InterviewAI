import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service for handling AssemblyAI speech-to-text transcription
///
/// This service implements the complete three-step transcription process:
/// 1. Upload audio file to AssemblyAI
/// 2. Submit transcription request
/// 3. Poll for results until completed
class AssemblyAiService {
  static final AssemblyAiService _instance = AssemblyAiService._internal();
  factory AssemblyAiService() => _instance;
  AssemblyAiService._internal();

  // AssemblyAI API endpoints
  static const String _uploadUrl = 'https://api.assemblyai.com/v2/upload';
  static const String _transcriptUrl =
      'https://api.assemblyai.com/v2/transcript';

  late String _apiKey;
  bool _isInitialized = false;

  /// Initialize the service with API key from environment
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final apiKey = dotenv.env['ASSEMBLYAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception(
          'ASSEMBLYAI_API_KEY not found in environment variables',
        );
      }

      _apiKey = apiKey;
      _isInitialized = true;
      debugPrint('AssemblyAI service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AssemblyAI service: $e');
      rethrow;
    }
  }

  /// Complete transcription process from audio file to text
  ///
  /// [audioFilePath] - Path to the local audio file to transcribe
  /// Returns the transcribed text or throws an exception on error
  Future<String> transcribeAudio(String audioFilePath) async {
    try {
      await initialize();

      debugPrint('Starting AssemblyAI transcription for: $audioFilePath');

      // Step 1: Upload audio file
      final uploadUrl = await _uploadAudioFile(audioFilePath);
      debugPrint('Audio uploaded successfully. Upload URL obtained.');

      // Step 2: Submit transcription request
      final transcriptId = await _submitTranscriptionRequest(uploadUrl);
      debugPrint('Transcription request submitted. ID: $transcriptId');

      // Step 3: Poll for results
      final transcribedText = await _pollForResults(transcriptId);
      debugPrint('Transcription completed successfully');

      return transcribedText;
    } catch (e) {
      debugPrint('Error in transcribeAudio: $e');
      rethrow;
    }
  }

  /// Step A: Upload audio file to AssemblyAI
  ///
  /// [audioFilePath] - Path to the local audio file
  /// Returns the secure upload URL for the uploaded file
  Future<String> _uploadAudioFile(String audioFilePath) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $audioFilePath');
      }

      final audioBytes = await file.readAsBytes();

      final response = await http.post(
        Uri.parse(_uploadUrl),
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/octet-stream',
        },
        body: audioBytes,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final uploadUrl = responseData['upload_url'] as String?;

        if (uploadUrl == null || uploadUrl.isEmpty) {
          throw Exception('Upload URL not received from AssemblyAI');
        }

        return uploadUrl;
      } else {
        throw Exception(
          'Failed to upload audio file. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error uploading audio file: $e');
      rethrow;
    }
  }

  /// Step B: Submit transcription request to AssemblyAI
  ///
  /// [uploadUrl] - The secure upload URL from step A
  /// Returns the transcription job ID
  Future<String> _submitTranscriptionRequest(String uploadUrl) async {
    try {
      final requestBody = jsonEncode({
        'audio_url': uploadUrl,
        'language_detection': true, // Enable automatic language detection
        'punctuate': true, // Add punctuation
        'format_text': true, // Format the text
      });

      final response = await http.post(
        Uri.parse(_transcriptUrl),
        headers: {'Authorization': _apiKey, 'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final transcriptId = responseData['id'] as String?;

        if (transcriptId == null || transcriptId.isEmpty) {
          throw Exception('Transcript ID not received from AssemblyAI');
        }

        return transcriptId;
      } else {
        throw Exception(
          'Failed to submit transcription request. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error submitting transcription request: $e');
      rethrow;
    }
  }

  /// Step C: Poll for transcription results
  ///
  /// [transcriptId] - The transcription job ID from step B
  /// Returns the final transcribed text
  Future<String> _pollForResults(String transcriptId) async {
    const int maxPollingAttempts = 60; // Maximum 3 minutes (60 * 3 seconds)
    const Duration pollingInterval = Duration(seconds: 3);

    for (int attempt = 1; attempt <= maxPollingAttempts; attempt++) {
      try {
        debugPrint(
          'Polling attempt $attempt/$maxPollingAttempts for transcript: $transcriptId',
        );

        final response = await http.get(
          Uri.parse('$_transcriptUrl/$transcriptId'),
          headers: {
            'Authorization': _apiKey,
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final status = responseData['status'] as String?;

          if (status == null) {
            throw Exception('Status not found in response');
          }

          debugPrint('Transcription status: $status');

          switch (status) {
            case 'completed':
              final text = responseData['text'] as String?;
              if (text == null || text.isEmpty) {
                throw Exception('Transcribed text is empty');
              }
              return text;

            case 'error':
              final error = responseData['error'] ?? 'Unknown error occurred';
              throw Exception('Transcription failed: $error');

            case 'processing':
            case 'queued':
              // Continue polling
              if (attempt < maxPollingAttempts) {
                await Future.delayed(pollingInterval);
                continue;
              } else {
                throw Exception(
                  'Transcription timed out after ${maxPollingAttempts * pollingInterval.inSeconds} seconds',
                );
              }

            default:
              throw Exception('Unknown transcription status: $status');
          }
        } else {
          throw Exception(
            'Failed to get transcription status. Status: ${response.statusCode}, Body: ${response.body}',
          );
        }
      } catch (e) {
        if (attempt == maxPollingAttempts) {
          debugPrint('Final polling attempt failed: $e');
          rethrow;
        } else {
          debugPrint('Polling attempt $attempt failed, retrying: $e');
          await Future.delayed(pollingInterval);
        }
      }
    }

    throw Exception('Transcription polling exceeded maximum attempts');
  }

  /// Check if the service is properly initialized
  bool get isInitialized => _isInitialized;

  /// Dispose of any resources
  void dispose() {
    // No resources to dispose in this implementation
    debugPrint('AssemblyAI service disposed');
  }
}
