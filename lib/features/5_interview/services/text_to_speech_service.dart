import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  Completer<void>? _speakingCompleter;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure TTS settings
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.8); // Slightly slower for clarity
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakingCompleter?.complete();
        _speakingCompleter = null;
      });

      // Set error handler
      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isSpeaking = false;
        _speakingCompleter?.completeError(Exception('TTS Error: $msg'));
        _speakingCompleter = null;
      });

      // Set start handler
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _isInitialized = true;
      debugPrint('Text-to-Speech service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      rethrow;
    }
  }

  Future<void> speak(String text, {double? rate}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Stop any current speech
      await stop();
      
      // Set speech rate if provided
      if (rate != null) {
        await _flutterTts.setSpeechRate(rate);
      }

      // Create completer for this speech
      _speakingCompleter = Completer<void>();

      // Start speaking
      await _flutterTts.speak(text);

      // Wait for completion
      await _speakingCompleter!.future;
      
      // Reset to default rate if custom rate was used
      if (rate != null) {
        await _flutterTts.setSpeechRate(0.8); // Reset to default rate
      }
    } catch (e) {
      debugPrint('Error speaking text: $e');
      _isSpeaking = false;
      _speakingCompleter = null;
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
      _speakingCompleter?.complete();
      _speakingCompleter = null;
    }
  }

  Future<void> pause() async {
    if (_isSpeaking) {
      await _flutterTts.pause();
    }
  }

  void dispose() {
    _flutterTts.stop();
    _isSpeaking = false;
    _speakingCompleter = null;
  }

  // Get available languages
  Future<List<String>> getLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      debugPrint('Error getting languages: $e');
      return ['en-US']; // Default fallback
    }
  }

  // Get available voices
  Future<List<Map<String, String>>> getVoices() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(voices);
    } catch (e) {
      debugPrint('Error getting voices: $e');
      return []; // Empty fallback
    }
  }

  // Set voice (optional)
  Future<void> setVoice({required String name, required String locale}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _flutterTts.setVoice({'name': name, 'locale': locale});
    } catch (e) {
      debugPrint('Error setting voice: $e');
    }
  }

  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      debugPrint('Error setting speech rate: $e');
    }
  }

  // Set pitch
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      debugPrint('Error setting pitch: $e');
    }
  }
}
