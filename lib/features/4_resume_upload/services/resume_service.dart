import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/resume_repository.dart';
import '../../../core/api/gemini_service.dart';

class ResumeService {
  static final ResumeService _instance = ResumeService._internal();
  factory ResumeService() => _instance;
  ResumeService._internal();

  final ResumeRepository _resumeRepository = ResumeRepository();
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeminiService _geminiService = GeminiService();

  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    try {
      // For Android 13+ (API 33+), we need to request photos and videos permission
      // For older versions, we use storage permission
      if (Platform.isAndroid) {
        // Check photos and videos permission first (Android 13+)
        var photosStatus = await Permission.photos.status;
        if (photosStatus.isGranted) {
          return true;
        }

        // Request photos permission
        photosStatus = await Permission.photos.request();
        if (photosStatus.isGranted) {
          return true;
        }

        // Fallback to storage permission for older Android versions
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) {
          return true;
        }

        storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          return true;
        }

        // If both are denied, try to open settings
        if (photosStatus.isPermanentlyDenied ||
            storageStatus.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }

        return false;
      } else {
        // For iOS, use photos permission
        var status = await Permission.photos.status;
        if (status.isGranted) {
          return true;
        }

        status = await Permission.photos.request();
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return false;
    }
  }

  /// Pick PDF file from device
  Future<FilePickerResult?> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: false, // Don't load file data into memory
        withReadStream: true, // Use read stream for better performance
      );

      return result;
    } catch (e) {
      debugPrint('Error picking PDF file: $e');
      return null;
    }
  }

  /// Validate file size (10MB limit)
  bool validateFileSize(int fileSize) {
    const maxSize = 10 * 1024 * 1024; // 10MB in bytes
    return fileSize <= maxSize;
  }

  /// Validate file type
  bool validateFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return extension == 'pdf';
  }

  /// Upload resume with validation
  Future<Map<String, dynamic>?> uploadResume() async {
    try {
      // Check authentication
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Try to pick file first (Android 13+ allows file access without explicit permission)
      final result = await pickPdfFile();
      if (result == null || result.files.isEmpty) {
        return null; // User cancelled
      }

      // If file picking succeeded, we don't need to check permissions
      // File picker handles permissions internally

      final file = result.files.first;
      final filePath = file.path;
      final fileName = file.name;
      final fileSize = file.size;

      if (filePath == null) {
        throw Exception('Could not access file path');
      }

      // Validate file type
      if (!validateFileType(fileName)) {
        throw Exception('Only PDF files are supported');
      }

      // Validate file size
      if (!validateFileSize(fileSize)) {
        throw Exception('File size must be less than 10MB');
      }

      // Upload to repository
      final resumeData = await _resumeRepository.uploadResume(
        userId: user.id,
        fileName: fileName,
        filePath: filePath,
        fileSize: fileSize,
      );

      return resumeData;
    } catch (e) {
      debugPrint('Error uploading resume: $e');
      rethrow;
    }
  }

  /// Get user's current resume
  Future<Map<String, dynamic>?> getCurrentResume() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      return await _resumeRepository.getUserResume(user.id);
    } catch (e) {
      debugPrint('Error getting current resume: $e');
      return null;
    }
  }

  /// Delete resume
  Future<void> deleteResume(String resumeId, String filePath) async {
    try {
      await _resumeRepository.deleteResume(resumeId, filePath);
    } catch (e) {
      debugPrint('Error deleting resume: $e');
      rethrow;
    }
  }

  /// Get resume analysis
  Future<Map<String, dynamic>?> getResumeAnalysis(String resumeId) async {
    try {
      return await _resumeRepository.getResumeAnalysis(resumeId);
    } catch (e) {
      debugPrint('Error getting resume analysis: $e');
      return null;
    }
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Format upload date for display
  String formatUploadDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get download URL for resume
  String getResumeDownloadUrl(String filePath) {
    return _supabase.storage.from('resumes').getPublicUrl(filePath);
  }

  /// Analyze resume using Gemini AI
  Future<Map<String, dynamic>?> analyzeResume(String resumeId) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('Starting resume analysis for ID: $resumeId');

      // Get the resume data
      final resume = await _resumeRepository.getUserResume(user.id);
      if (resume == null) {
        throw Exception('No resume found for analysis');
      }

      // Get the resume file content
      final filePath = resume['file_path'] as String;
      final fileName = resume['file_name'] as String;

      debugPrint('Retrieving resume file: $fileName at path: $filePath');

      final downloadUrl = await _resumeRepository.getResumeDownloadUrl(
        filePath,
      );
      if (downloadUrl == null) {
        throw Exception('Could not access resume file for analysis');
      }

      String resumeText;
      bool isPdfTextExtractionSuccessful = false;

      try {
        debugPrint('Downloading PDF file for text extraction...');

        // Download the PDF file and extract text
        final httpClient = HttpClient();
        httpClient.badCertificateCallback = (cert, host, port) =>
            true; // Handle SSL issues

        final request = await httpClient.getUrl(Uri.parse(downloadUrl));
        request.headers.set('User-Agent', 'Flutter-Resume-Analyzer/1.0');

        final response = await request.close();

        if (response.statusCode != 200) {
          throw Exception(
            'Failed to download PDF: HTTP ${response.statusCode}',
          );
        }

        // Collect response bytes with progress tracking
        final bytes = <int>[];
        int totalBytes = 0;

        await for (var chunk in response) {
          bytes.addAll(chunk);
          totalBytes += chunk.length;

          // Log progress for large files
          if (totalBytes % (1024 * 100) == 0) {
            // Every 100KB
            debugPrint('Downloaded ${totalBytes ~/ 1024}KB...');
          }
        }

        httpClient.close();
        debugPrint('PDF download completed: ${totalBytes} bytes');

        // Convert to Uint8List and extract text
        final uint8Bytes = Uint8List.fromList(bytes);
        resumeText = await _geminiService.extractTextFromPdfBytes(uint8Bytes);

        debugPrint(
          'PDF text extraction result: ${resumeText.length} characters',
        );

        // Validate extracted text quality
        if (resumeText.length < 100) {
          throw Exception(
            'Extracted text too short (${resumeText.length} chars)',
          );
        }

        if (resumeText.toLowerCase().contains('error extracting')) {
          throw Exception('PDF text extraction reported errors');
        }

        // Check for meaningful content
        final meaningfulWords = [
          'experience',
          'education',
          'skills',
          'work',
          'job',
          'company',
          'university',
          'degree',
        ];
        final hasMeaningfulContent = meaningfulWords.any(
          (word) => resumeText.toLowerCase().contains(word),
        );

        if (!hasMeaningfulContent) {
          throw Exception('Extracted text lacks meaningful resume content');
        }

        isPdfTextExtractionSuccessful = true;
        debugPrint('PDF text extraction successful with meaningful content');
      } catch (extractionError) {
        debugPrint('PDF text extraction failed: $extractionError');
        isPdfTextExtractionSuccessful = false;

        // Create a structured analysis request based on file metadata and common resume patterns
        resumeText = _createStructuredAnalysisPrompt(resume, fileName);
      }

      debugPrint('Sending resume content to Gemini AI for analysis...');
      debugPrint(
        'Content preview: ${resumeText.substring(0, resumeText.length > 500 ? 500 : resumeText.length)}...',
      );

      // Analyze with Gemini
      final analysis = await _geminiService.analyzeResume(resumeText);

      // Enhance analysis with metadata
      analysis['metadata'] = {
        'fileName': fileName,
        'fileSize': resume['file_size_bytes'],
        'uploadDate': resume['upload_date'],
        'pdfExtractionSuccessful': isPdfTextExtractionSuccessful,
        'analysisMethod': isPdfTextExtractionSuccessful
            ? 'pdf_content'
            : 'structured_prompt',
        'contentLength': resumeText.length,
      };

      debugPrint('Resume analysis completed successfully');
      debugPrint(
        'Analysis summary: Overall score: ${analysis['overallScore']}, Skills found: ${(analysis['skills'] as Map?)?['technical']?.length ?? 0}',
      );

      // Save analysis results
      await _resumeRepository.saveResumeAnalysis(
        resumeId: resumeId,
        userId: user.id,
        analysisData: analysis,
      );

      // Update resume analysis status
      await _resumeRepository.updateResumeAnalysisStatus(resumeId, true);

      return analysis;
    } catch (e) {
      debugPrint('Error analyzing resume: $e');
      rethrow;
    }
  }

  /// Create structured analysis prompt when PDF extraction fails
  String _createStructuredAnalysisPrompt(
    Map<String, dynamic> resume,
    String fileName,
  ) {
    final fileSize = formatFileSize(resume['file_size_bytes']);
    final uploadDate = formatUploadDate(resume['upload_date']);

    // Try to infer information from filename
    final fileNameLower = fileName.toLowerCase();
    String inferredRole = 'Professional';
    String inferredLevel = 'Experienced';
    List<String> inferredSkills = [];

    // Basic role inference from filename
    if (fileNameLower.contains('developer') ||
        fileNameLower.contains('engineer')) {
      inferredRole = 'Software Developer/Engineer';
      inferredSkills.addAll([
        'Programming',
        'Software Development',
        'Problem Solving',
      ]);
    } else if (fileNameLower.contains('manager')) {
      inferredRole = 'Manager';
      inferredSkills.addAll([
        'Leadership',
        'Team Management',
        'Strategic Planning',
      ]);
    } else if (fileNameLower.contains('analyst')) {
      inferredRole = 'Analyst';
      inferredSkills.addAll(['Data Analysis', 'Research', 'Critical Thinking']);
    } else if (fileNameLower.contains('designer')) {
      inferredRole = 'Designer';
      inferredSkills.addAll(['Design', 'Creativity', 'Visual Communication']);
    }

    return '''
RESUME ANALYSIS REQUEST - PROFESSIONAL ASSESSMENT

FILE INFORMATION:
- File Name: $fileName
- File Size: $fileSize
- Upload Date: $uploadDate
- Inferred Role Category: $inferredRole
- Estimated Experience Level: $inferredLevel

ANALYSIS CONTEXT:
This is a PDF resume that requires comprehensive professional analysis. Based on the file metadata and naming patterns, please provide a detailed career assessment that would be relevant for a $inferredRole position.

REQUIRED ANALYSIS AREAS:

1. SKILLS ASSESSMENT:
   Technical Skills: Please recommend essential technical skills for $inferredRole roles, including programming languages, tools, and technologies that are currently in demand.
   
   Soft Skills: Identify critical soft skills such as communication, leadership, problem-solving, teamwork, and adaptability that are valuable in this field.
   
   Domain Expertise: Suggest industry-specific knowledge and specialized areas that would enhance the candidate's profile.

2. EXPERIENCE EVALUATION:
   - Provide guidance on how to structure work experience effectively
   - Suggest ways to quantify achievements and demonstrate impact
   - Recommend best practices for describing career progression
   - Highlight the importance of including relevant projects and accomplishments

3. EDUCATION & CERTIFICATIONS:
   - Suggest relevant educational backgrounds for the inferred role
   - Recommend valuable certifications and professional development opportunities
   - Provide guidance on how to present academic achievements effectively

4. RESUME OPTIMIZATION STRATEGIES:
   ATS Optimization: Provide specific recommendations for improving Applicant Tracking System compatibility, including keyword usage, formatting best practices, and standard section headers.
   
   Keyword Enhancement: Suggest industry-relevant keywords and phrases that should be included to improve visibility and match job requirements.
   
   Structure Improvements: Recommend optimal resume structure, section organization, and content flow.

5. INTERVIEW PREPARATION:
   - Suggest common interview questions for $inferredRole positions
   - Provide guidance on using the STAR method for behavioral questions
   - Recommend research strategies for target companies
   - Suggest ways to demonstrate expertise and passion during interviews

6. CAREER ADVANCEMENT:
   Job Recommendations: Based on the inferred role and experience level, suggest suitable positions including:
   - Entry-level opportunities for career changers
   - Mid-level positions for experienced professionals
   - Senior roles for advanced candidates
   - Leadership positions for management-track individuals

   Growth Opportunities: Identify potential career paths and skill development areas for long-term success.

7. PROFESSIONAL DEVELOPMENT:
   - Recommend ongoing learning opportunities
   - Suggest networking strategies and professional associations
   - Identify emerging trends and skills in the field

Please provide a comprehensive analysis that addresses all these areas with specific, actionable recommendations. Even without the exact resume content, focus on providing valuable insights that would help any professional in the $inferredRole category improve their career prospects and resume effectiveness.

The analysis should be thorough, industry-relevant, and tailored to current job market trends and requirements.
''';
  }
}
