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

  // Upload file from bytes
  Future<String?> uploadFile({
    required String bucketName,
    required String fileName,
    required Uint8List fileBytes,
    bool upsert = false,
  }) async {
    try {
      // Ensure the file name is valid
      if (fileName.isEmpty) {
        throw Exception('File name cannot be empty');
      }

      // Upload the file
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getContentType(path.extension(fileName)),
              upsert: upsert,
            ),
          );

      // Get the public URL
      final String fileUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);
      debugPrint('File uploaded successfully: $fileUrl');
      return fileUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // Upload file from file path
  Future<String?> uploadFileFromPath({
    required String bucketName,
    required String filePath,
    required String destinationPath,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Upload the file
      await _supabase.storage
          .from(bucketName)
          .upload(
            destinationPath,
            file,
            fileOptions: FileOptions(
              contentType: _getContentType(path.extension(filePath)),
              upsert: false,
            ),
          );

      // Get the public URL
      final String fileUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(destinationPath);
      debugPrint('File uploaded successfully: $fileUrl');
      return fileUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // Delete file
  Future<bool> deleteFile({
    required String bucketName,
    required String fileUrl,
  }) async {
    try {
      // Extract the path from the URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // The path should be something like: storage/v1/object/public/bucket-name/path/to/file.ext
      // We need to extract just the path/to/file.ext part
      final filePath = pathSegments
          .sublist(pathSegments.indexOf(bucketName) + 1)
          .join('/');

      await _supabase.storage.from(bucketName).remove([filePath]);
      debugPrint('File deleted successfully: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // Generate a unique filename with UUID
  String generateUniqueFileName(String originalFileName) {
    final uuid = const Uuid().v4();
    final extension = path.extension(originalFileName);
    final baseName = path.basenameWithoutExtension(originalFileName);
    return '${baseName}_$uuid$extension';
  }

  // Helper method to get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.wav':
        return 'audio/wav';
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
        return 'audio/m4a';
      default:
        return 'application/octet-stream'; // Default binary
    }
  }
}
