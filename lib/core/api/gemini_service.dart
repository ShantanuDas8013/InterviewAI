import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  late GenerativeModel _model;
  bool _isInitialized = false;

  /// Initialize the Gemini model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in environment variables');
      }

      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      _isInitialized = true;
      debugPrint('Gemini service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Gemini service: $e');
      rethrow;
    }
  }

  /// Analyze resume content with retry mechanism and better error handling
  Future<Map<String, dynamic>> analyzeResume(String resumeText) async {
    const int maxRetries = 3;
    const Duration baseDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('Resume analysis attempt $attempt of $maxRetries');
        await initialize();

        final analysisResult = await _performAnalysis(resumeText);
        debugPrint(
          'Resume analysis completed successfully on attempt $attempt',
        );
        return analysisResult;
      } catch (e) {
        debugPrint('Attempt $attempt failed: $e');

        // Check if this is a retryable error
        if (_isRetryableError(e) && attempt < maxRetries) {
          // Calculate exponential backoff delay
          final delay = Duration(
            milliseconds: baseDelay.inMilliseconds * (1 << (attempt - 1)),
          );

          debugPrint(
            'Retrying in ${delay.inSeconds} seconds... (attempt ${attempt + 1}/$maxRetries)',
          );
          await Future.delayed(delay);
          continue;
        }

        // If not retryable or max retries reached, rethrow the error
        if (attempt == maxRetries) {
          debugPrint('All retry attempts exhausted. Throwing error.');
          rethrow;
        }
      }
    }

    // This should not be reached, but just in case
    throw Exception('Resume analysis failed after all retries');
  }

  /// Check if an error should trigger a retry
  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Retryable errors
    if (errorString.contains('503') || // Service unavailable
        errorString.contains('overloaded') ||
        errorString.contains('temporarily unavailable') ||
        errorString.contains('rate limit') ||
        errorString.contains('quota exceeded') ||
        errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return true;
    }

    return false;
  }

  /// Perform the actual analysis
  Future<Map<String, dynamic>> _performAnalysis(String resumeText) async {
    final prompt = _buildAnalysisPrompt(resumeText);
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    final responseText = response.text ?? '';

    debugPrint('Gemini Raw Response: $responseText');

    // Parse the JSON response
    try {
      // Clean the response text to extract valid JSON
      String cleanJsonString = responseText.trim();

      // Remove markdown code blocks if present
      if (cleanJsonString.startsWith('```json')) {
        cleanJsonString = cleanJsonString.replaceFirst('```json', '');
      }
      if (cleanJsonString.startsWith('```')) {
        cleanJsonString = cleanJsonString.replaceFirst('```', '');
      }
      if (cleanJsonString.endsWith('```')) {
        cleanJsonString = cleanJsonString.substring(
          0,
          cleanJsonString.length - 3,
        );
      }

      // Find JSON boundaries
      final jsonStart = cleanJsonString.indexOf('{');
      final jsonEnd = cleanJsonString.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        cleanJsonString = cleanJsonString.substring(jsonStart, jsonEnd);
      }

      debugPrint('Cleaned JSON String: $cleanJsonString');

      // Parse the JSON
      final parsedJson = jsonDecode(cleanJsonString) as Map<String, dynamic>;

      // Validate and enhance the parsed data
      final analysis = _validateAndEnhanceAnalysis(parsedJson);

      debugPrint('Successfully parsed resume analysis');
      return analysis;
    } catch (parseError) {
      debugPrint('Error parsing Gemini JSON response: $parseError');
      debugPrint('Raw response for debugging: $responseText');

      // Since Gemini is working well based on logs, we should throw the error
      // instead of returning a fallback analysis
      throw Exception('Failed to parse Gemini response: $parseError');
    }
  }

  /// Validate and enhance the parsed analysis data
  Map<String, dynamic> _validateAndEnhanceAnalysis(Map<String, dynamic> data) {
    return {
      'overallScore': _ensureDouble(data['overallScore'], 75.0),
      'overallFeedback':
          data['overallFeedback']?.toString() ?? 'Resume analysis completed',
      'skills': _validateSkills(data['skills']),
      'experience': _validateExperience(data['experience']),
      'education': _validateEducation(data['education']),
      'strengths': _ensureList(data['strengths']),
      'improvements': _ensureList(data['improvements']),
      'interviewTips': _ensureList(data['interviewTips']),
      'jobRecommendations': _ensureList(data['jobRecommendations']),
      'atsOptimization': _validateAtsOptimization(data['atsOptimization']),
      'keywordAnalysis': _validateKeywordAnalysis(data['keywordAnalysis']),
      'analysisDate': DateTime.now().toIso8601String(),
      'status': 'completed',
      'rawResponse': data.toString(),
    };
  }

  /// Build the analysis prompt
  String _buildAnalysisPrompt(String resumeText) {
    return '''
You are an expert resume analyst and career counselor with over 10 years of experience in talent acquisition and career coaching. Analyze the following resume comprehensively and provide detailed, actionable insights in a valid JSON format.

ANALYSIS REQUIREMENTS:
Please conduct a thorough analysis covering these key areas:

1. OVERALL ASSESSMENT: Provide an overall quality score (0-10) and comprehensive feedback
2. SKILLS EVALUATION: Categorize all skills found (technical, soft, domain-specific)
3. EXPERIENCE ANALYSIS: Evaluate work history, achievements, and career progression
4. EDUCATION REVIEW: Assess educational background and certifications
5. STRENGTHS IDENTIFICATION: Highlight unique value propositions and strong points
6. IMPROVEMENT AREAS: Identify specific areas that need enhancement
7. INTERVIEW PREPARATION: Provide targeted interview tips based on the resume
8. JOB RECOMMENDATIONS: Suggest suitable roles based on the candidate's profile
9. ATS OPTIMIZATION: Evaluate and suggest improvements for Applicant Tracking Systems
10. KEYWORD ANALYSIS: Identify relevant and missing keywords for better visibility

RESUME CONTENT TO ANALYZE:
$resumeText

IMPORTANT INSTRUCTIONS:
- Be specific and actionable in your recommendations
- Provide quantifiable insights where possible
- Consider current industry trends and requirements
- Focus on both technical competency and soft skills
- Ensure recommendations are tailored to the candidate's experience level
- Include specific examples and suggestions for improvement

Please provide your analysis in the following EXACT JSON format (ensure it's perfectly valid JSON with no extra text or markdown):

{
  "overallScore": 85.5,
  "overallFeedback": "Comprehensive summary highlighting key strengths, areas for improvement, and overall assessment of the resume quality and candidate potential",
  "skills": {
    "technical": ["Specific technical skills found", "Programming languages", "Tools and technologies"],
    "soft": ["Communication", "Leadership", "Problem-solving", "Team collaboration"],
    "domain": ["Industry-specific expertise", "Business knowledge", "Domain specializations"]
  },
  "experience": {
    "summary": "Detailed summary of the candidate's work experience, career progression, and key accomplishments",
    "keyAchievements": ["Quantified achievement 1 with metrics", "Major project or accomplishment 2", "Leadership or impact example 3"],
    "yearsOfExperience": 5,
    "companies": ["Company 1", "Company 2", "Company 3"],
    "jobTitles": ["Current/Recent Title", "Previous Title", "Earlier Title"]
  },
  "education": {
    "degrees": ["Bachelor's in Computer Science", "Master's in Engineering"],
    "certifications": ["AWS Certified Solutions Architect", "PMP Certified", "Google Cloud Professional"],
    "educationLevel": "Master's"
  },
  "strengths": [
    "Strong technical foundation with X years of experience",
    "Proven leadership in managing teams of Y people",
    "Deep expertise in specific domain or technology",
    "Track record of delivering results with quantifiable impact"
  ],
  "improvements": [
    "Add specific metrics and quantifiable achievements (e.g., 'Increased efficiency by 30%')",
    "Include more relevant keywords for target roles",
    "Strengthen the professional summary section",
    "Add missing certifications relevant to target positions"
  ],
  "interviewTips": [
    "Prepare STAR method examples for key achievements mentioned",
    "Research target companies and align experience with their needs",
    "Practice explaining technical concepts to non-technical stakeholders",
    "Prepare questions about company culture and growth opportunities"
  ],
  "jobRecommendations": [
    "Senior Software Engineer",
    "Technical Lead",
    "Product Manager",
    "Solutions Architect"
  ],
  "atsOptimization": {
    "score": 8.2,
    "issues": [
      "Missing standard section headers (e.g., 'Professional Experience')",
      "Insufficient use of industry-standard keywords",
      "Non-standard date formats that ATS might not parse correctly"
    ],
    "suggestions": [
      "Use standard resume section headers",
      "Include more industry-relevant keywords naturally in context",
      "Use consistent date formatting (MM/YYYY format recommended)",
      "Ensure contact information is in a standard format"
    ]
  },
  "keywordAnalysis": {
    "relevantKeywords": ["Keywords found in resume that match industry standards", "Technical terms", "Skills mentioned"],
    "missingKeywords": ["Important keywords missing for target roles", "Industry buzzwords", "Technical skills not mentioned"],
    "keywordDensity": "Good - appropriate use of keywords without stuffing"
  },
  "analysisDate": "${DateTime.now().toIso8601String()}"
}

RESPONSE FORMAT: Return ONLY the JSON object above with your analysis. Do not include any markdown formatting, explanatory text, or additional content outside the JSON structure.
''';
  }

  /// Helper methods for validation
  double _ensureDouble(dynamic value, double defaultValue) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return defaultValue;
  }

  List<String> _ensureList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  Map<String, dynamic> _validateSkills(dynamic skills) {
    if (skills is Map<String, dynamic>) {
      return {
        'technical': _ensureList(skills['technical']),
        'soft': _ensureList(skills['soft']),
        'domain': _ensureList(skills['domain']),
      };
    }
    return {'technical': <String>[], 'soft': <String>[], 'domain': <String>[]};
  }

  Map<String, dynamic> _validateExperience(dynamic experience) {
    if (experience is Map<String, dynamic>) {
      // Safely extract and convert yearsOfExperience to int
      int extractedYears = 0;
      final yearsValue = experience['yearsOfExperience'];

      if (yearsValue is int) {
        extractedYears = yearsValue;
      } else if (yearsValue is double) {
        extractedYears = yearsValue.round(); // Round double to nearest int
      } else if (yearsValue is String) {
        // Try to parse string as number
        final parsed = double.tryParse(yearsValue);
        if (parsed != null) {
          extractedYears = parsed.round();
        }
      }

      // Ensure reasonable bounds (0-50 years)
      extractedYears = extractedYears.clamp(0, 50);

      return {
        'summary': experience['summary']?.toString() ?? 'No summary available',
        'keyAchievements': _ensureList(experience['keyAchievements']),
        'yearsOfExperience': extractedYears,
        'companies': _ensureList(experience['companies']),
        'jobTitles': _ensureList(experience['jobTitles']),
      };
    }
    return {
      'summary': 'No experience data available',
      'keyAchievements': <String>[],
      'yearsOfExperience': 0,
      'companies': <String>[],
      'jobTitles': <String>[],
    };
  }

  Map<String, dynamic> _validateEducation(dynamic education) {
    if (education is Map<String, dynamic>) {
      return {
        'degrees': _ensureList(education['degrees']),
        'certifications': _ensureList(education['certifications']),
        'educationLevel':
            education['educationLevel']?.toString() ?? 'Not specified',
      };
    }
    return {
      'degrees': <String>[],
      'certifications': <String>[],
      'educationLevel': 'Not specified',
    };
  }

  Map<String, dynamic> _validateAtsOptimization(dynamic ats) {
    if (ats is Map<String, dynamic>) {
      return {
        'score': _ensureDouble(ats['score'], 5.0),
        'issues': _ensureList(ats['issues']),
        'suggestions': _ensureList(ats['suggestions']),
      };
    }
    return {'score': 5.0, 'issues': <String>[], 'suggestions': <String>[]};
  }

  Map<String, dynamic> _validateKeywordAnalysis(dynamic keywords) {
    if (keywords is Map<String, dynamic>) {
      return {
        'relevantKeywords': _ensureList(keywords['relevantKeywords']),
        'missingKeywords': _ensureList(keywords['missingKeywords']),
        'keywordDensity':
            keywords['keywordDensity']?.toString() ?? 'Not analyzed',
      };
    }
    return {
      'relevantKeywords': <String>[],
      'missingKeywords': <String>[],
      'keywordDensity': 'Not analyzed',
    };
  }

  /// Extract text content from PDF file
  Future<String> extractTextFromPdf(File pdfFile) async {
    try {
      debugPrint('Starting PDF text extraction from file: ${pdfFile.path}');

      // Read the PDF file
      final Uint8List pdfBytes = await pdfFile.readAsBytes();
      debugPrint('PDF file size: ${pdfBytes.length} bytes');

      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      debugPrint('PDF document loaded, page count: ${document.pages.count}');

      // Extract text using PdfTextExtractor
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();

      // Close the document
      document.dispose();

      debugPrint('PDF text extraction completed: ${text.length} characters');

      // Validate and clean the extracted text
      final cleanedText = _cleanAndValidateExtractedText(text);

      return cleanedText;
    } catch (e) {
      debugPrint('Error extracting text from PDF: $e');
      return _createPdfExtractionErrorMessage(e.toString());
    }
  }

  /// Extract text from PDF bytes (for downloaded files)
  Future<String> extractTextFromPdfBytes(Uint8List pdfBytes) async {
    try {
      debugPrint(
        'Starting PDF text extraction from bytes: ${pdfBytes.length} bytes',
      );

      // Validate PDF bytes
      if (pdfBytes.isEmpty) {
        throw Exception('PDF bytes are empty');
      }

      // Check for PDF signature
      if (pdfBytes.length < 4 ||
          !(pdfBytes[0] == 0x25 &&
              pdfBytes[1] == 0x50 &&
              pdfBytes[2] == 0x44 &&
              pdfBytes[3] == 0x46)) {
        throw Exception('Invalid PDF format - missing PDF signature');
      }

      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      debugPrint(
        'PDF document loaded successfully, pages: ${document.pages.count}',
      );

      // Extract text using PdfTextExtractor
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();

      // Close the document
      document.dispose();

      debugPrint('PDF text extraction completed: ${text.length} characters');

      // Validate and clean the extracted text
      final cleanedText = _cleanAndValidateExtractedText(text);

      return cleanedText;
    } catch (e) {
      debugPrint('Error extracting text from PDF bytes: $e');
      return _createPdfExtractionErrorMessage(e.toString());
    }
  }

  /// Clean and validate extracted text
  String _cleanAndValidateExtractedText(String rawText) {
    if (rawText.isEmpty) {
      return 'PDF appears to be empty or contains no extractable text content. This might be a scanned image or a PDF with non-standard formatting.';
    }

    // Clean the text
    String cleanedText = rawText
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single space
        .replaceAll(
          RegExp(r'\n\s*\n'),
          '\n\n',
        ) // Multiple newlines to double newline
        .trim();

    // Check for meaningful content
    if (cleanedText.length < 50) {
      return 'PDF text extraction yielded minimal content (${cleanedText.length} characters). The document may be image-based or have extraction limitations.';
    }

    // Check for common resume indicators
    final resumeIndicators = [
      'experience',
      'education',
      'skills',
      'work',
      'employment',
      'university',
      'college',
      'degree',
      'certificate',
      'project',
      'achievement',
      'responsibility',
      'manager',
      'developer',
      'engineer',
    ];

    final hasResumeContent = resumeIndicators.any(
      (indicator) => cleanedText.toLowerCase().contains(indicator),
    );

    if (!hasResumeContent) {
      debugPrint(
        'Warning: Extracted text may not contain typical resume content',
      );
    }

    return cleanedText;
  }

  /// Create a meaningful error message for PDF extraction failures
  String _createPdfExtractionErrorMessage(String error) {
    return '''
PDF Text Extraction Notice:
The system encountered an issue while extracting text from your PDF resume: $error

This typically occurs when:
1. The PDF is image-based (scanned document) rather than text-based
2. The PDF has security restrictions or encryption
3. The PDF uses non-standard formatting or fonts
4. The file may be corrupted or incomplete

Professional Resume Analysis:
Despite the extraction limitation, our AI system can still provide valuable resume analysis and recommendations based on:

- Industry best practices for resume structure and content
- Current job market trends and requirements
- ATS (Applicant Tracking System) optimization strategies
- Interview preparation techniques
- Career development guidance

Recommendations for your resume:
1. Ensure your PDF is text-based (not a scanned image)
2. Use standard fonts like Arial, Calibri, or Times New Roman
3. Save your resume from a word processor (Word, Google Docs) rather than scanning
4. Include clear section headers: Professional Summary, Experience, Education, Skills
5. Use bullet points for easy reading and ATS compatibility
6. Include relevant keywords for your target industry and role
7. Quantify your achievements with specific metrics and results

The analysis will proceed with comprehensive guidance tailored to professional resume standards and current industry expectations.
''';
  }
}
