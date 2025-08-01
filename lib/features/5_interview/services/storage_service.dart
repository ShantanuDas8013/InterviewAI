import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'interview-audio';

  // Upload audio file from bytes
  Future<String?> uploadAudioBytes({
    required Uint8List audioBytes,
    required String userId,
    required String sessionId,
    required String questionId,
  }) async {
    try {
      // Generate a unique filename
      final uuid = const Uuid().v4();
      final fileName = '$userId/$sessionId/${questionId}_$uuid.wav';

      // Upload the file
      await _supabase.storage.from(_bucketName).uploadBinary(
            fileName,
            audioBytes,
            fileOptions: const FileOptions(
              contentType: 'audio/wav',
              upsert: false,
            ),
          );

      // Get the public URL
      final String audioUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      debugPrint('Audio uploaded successfully: $audioUrl');
      return audioUrl;
    } catch (e) {
      debugPrint('Error uploading audio: $e');
      return null;
    }
  }

  // Upload audio file from file path
  Future<String?> uploadAudioFile({
    required String filePath,
    required String userId,
    required String sessionId,
    required String questionId,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist: $filePath');
      }

      // Generate a unique filename
      final uuid = const Uuid().v4();
      final extension = path.extension(filePath).toLowerCase();
      final fileName = '$userId/$sessionId/${questionId}_$uuid$extension';

      // Upload the file
      await _supabase.storage.from(_bucketName).upload(
            fileName,
            file,
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: false,
            ),
          );

      // Get the public URL
      final String audioUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      debugPrint('Audio uploaded successfully: $audioUrl');
      return audioUrl;
    } catch (e) {
      debugPrint('Error uploading audio file: $e');
      return null;
    }
  }

  // Delete audio file
  Future<bool> deleteAudio(String audioUrl) async {
    try {
      // Extract the path from the URL
      final uri = Uri.parse(audioUrl);
      final pathSegments = uri.pathSegments;
      
      // The path should be something like: storage/v1/object/public/interview-audio/path/to/file.wav
      // We need to extract just the path/to/file.wav part
      final filePath = pathSegments.sublist(pathSegments.indexOf(_bucketName) + 1).join('/');
      
      await _supabase.storage.from(_bucketName).remove([filePath]);
      debugPrint('Audio deleted successfully: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error deleting audio: $e');
      return false;
    }
  }

  // Helper method to get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.wav':
        return 'audio/wav';
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
        return 'audio/m4a';
      default:
        return 'audio/wav'; // Default to WAV
    }
  }
}