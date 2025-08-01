import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  String _transcribedText = '';
  Uint8List? _audioData;

  // Getters
  bool get isInitialized => _isInitialized;
  String get transcribedText => _transcribedText;
  Uint8List? get audioData => _audioData;

  // Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Wrap in try-catch to handle MissingPluginException
      try {
        _isInitialized = await _speech.initialize(
          onStatus: (status) {
            debugPrint('Speech recognition status: $status');
          },
          onError: (error) {
            debugPrint('Speech recognition error: $error');
          },
          debugLogging: kDebugMode,
        );
      } catch (pluginError) {
        debugPrint('Speech recognition plugin error: $pluginError');
        // Set initialized to false but don't throw an exception
        // This allows the app to continue functioning without speech recognition
        _isInitialized = false;
      }
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  // Start listening for speech
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      throw Exception('Speech recognition not initialized');
    }

    _transcribedText = '';
    _audioData = null;

    await _speech.listen(
      onResult: (result) {
        _transcribedText = result.recognizedWords;
        onResult(_transcribedText, result.finalResult);
      },
      listenFor: const Duration(seconds: 120),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  // Stop listening and return the transcribed text
  Future<String> stopListening() async {
    if (_speech.isListening) {
      _speech.stop();
      
      // Get the audio data from the speech recognition
      // Note: In a real implementation, you would need to capture the actual audio data
      // from the microphone. This is a simplified version that should be replaced with
      // actual audio recording functionality using a package like record or flutter_sound.
      try {
        // This is a placeholder. In a real app, you would get the actual audio bytes here.
        // For testing purposes, we're creating a small dummy WAV file
        // In production, replace this with actual audio capture
        final random = Random();
        final audioSize = 44100 * 2 * 2; // 2 seconds of 44.1kHz 16-bit stereo audio
        final audioBuffer = Uint8List(audioSize);
        
        // Fill with random data to simulate audio
        for (var i = 0; i < audioSize; i++) {
          audioBuffer[i] = random.nextInt(256);
        }
        
        _audioData = audioBuffer;
      } catch (e) {
        debugPrint('Error capturing audio data: $e');
        _audioData = Uint8List(0); // Fallback to empty data
      }
    }
    return _transcribedText;
  }

  // Clean up resources
  void dispose() {
    if (_speech.isListening) {
      _speech.stop();
    }
  }
}