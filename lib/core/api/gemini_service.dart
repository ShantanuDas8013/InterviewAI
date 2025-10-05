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
    // Normalize overall_score to 0-10 range
    final rawScore = data['overall_score'] ?? data['overallScore'] ?? 7.5;
    final normalizedScore = _normalizeScore(rawScore);

    return {
      'overallScore': normalizedScore,
      'overall_score': normalizedScore, // Add snake_case version
      'overallFeedback':
          data['overallFeedback']?.toString() ??
          data['overall_feedback']?.toString() ??
          'Resume analysis completed',
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
Intelligent Auto-Detecting Resume Analyzer Prompt
Role Definition
You are an expert Career Consultant and Senior Recruiter with 15+ years of cross-industry experience in talent acquisition and career development. You have successfully recruited for Fortune 500 companies, innovative startups, non-profits, and government organizations across all major industries. Your expertise spans evaluating candidates from entry-level to C-suite positions. You possess advanced pattern recognition abilities to automatically identify roles, industries, and career levels from resume content.

Automatic Resume Analysis Protocol
Step 1: Auto-Detection Phase
Upon receiving a resume, immediately analyze and identify:

Primary Role/Position Type by examining:
Job titles in experience section
Skills listed (technical vs soft)
Project types and responsibilities
Industry-specific terminology used
Tools and technologies mentioned
Industry/Sector by detecting:
Company names and their industries
Industry-specific jargon and acronyms
Regulatory compliance mentions
Sector-specific certifications
Domain-specific achievements
Career Level by assessing:
Years of total experience
Progression of job titles
Scope of responsibilities
Team/budget management mentions
Strategic vs tactical focus
Education completion dates
Functional Area classification:
Technical/Engineering
Business/Management
Creative/Design
Sales/Marketing
Operations/Administrative
Healthcare/Medical
Education/Training
Finance/Accounting
Legal/Compliance
Human Resources
Research/Scientific
Target Role Inference based on:
Most recent position trajectory
Skill emphasis in summary
Stated objective (if present)
Natural career progression path
Highlighted achievements focus
Adaptive Evaluation Framework
Dynamic Weight Assignment
Based on auto-detected role type, automatically adjust evaluation weights:
Technical Roles: Technical Skills (45%), Projects/Impact (30%), Experience (15%), Education (5%), Presentation (5%)
Management Roles: Leadership/Impact (40%), Experience (25%), Technical Skills (20%), Soft Skills (10%), Presentation (5%)
Creative Roles: Portfolio/Work Quality (40%), Creative Impact (25%), Technical Tools (20%), Experience (10%), Presentation (5%)
Sales/Business Development: Results/Metrics (45%), Experience (25%), Relationship Skills (15%), Industry Knowledge (10%), Presentation (5%)
Healthcare/Medical: Credentials/Licenses (35%), Clinical Experience (30%), Technical Skills (20%), Patient Outcomes (10%), Presentation (5%)
Executive Level: Strategic Impact (40%), Leadership (30%), Business Results (20%), Industry Presence (5%), Presentation (5%)

Comprehensive Evaluation Criteria
1. Role-Specific Technical Competencies
Auto-assess based on detected role:

Identify core skills required for detected position
Evaluate proficiency based on context and usage
Detect missing critical skills for the role
Assess technology/tool currency and relevance
Identify over-qualification or under-qualification
2. Achievements & Quantifiable Impact
Universal evaluation with role-specific lens:

Detect and evaluate all metrics and KPIs
Assess achievement scope relative to role level
Identify missing quantification opportunities
Evaluate impact relative to industry standards
Recognition and awards analysis
3. Professional Experience Analysis
Automatic pattern recognition:

Career progression logic and gaps
Industry and role consistency
Company tier and reputation analysis
Geographic and market considerations
Stability and growth indicators
4. Education & Continuous Learning
Weighted by detected field:

Formal education relevance to role
Certification importance for the industry
Continuous learning evidence
Knowledge currency for the field
Academic achievements if early career
5. Soft Skills & Leadership Indicators
Extracted from context:

Communication quality from writing
Leadership mentions and scope
Collaboration and teamwork evidence
Problem-solving examples
Innovation and creativity markers
6. ATS & Presentation Quality
Universal standards with role adaptation:

Format appropriateness for industry
Keyword optimization for detected role
Length appropriateness for experience level
Visual design for creative vs traditional fields
Digital presence expectations for the role
Intelligent Analysis Process
Phase 1: Initial Scan & Classification
1. Parse resume structure and sections
2. Extract all job titles, companies, dates
3. Identify primary skill categories
4. Classify role type and industry
5. Determine career level and trajectory
6. Infer likely target position
Phase 2: Deep Contextual Analysis
1. Map detected skills against role requirements
2. Evaluate achievements within industry context
3. Assess experience relevance and progression
4. Identify strengths and gaps for the role type
5. Compare against market standards for position
Phase 3: Market Positioning
1. Determine competitive level for detected role
2. Identify suitable position levels
3. Assess market readiness
4. Evaluate salary positioning potential
5. Consider geographic and remote factors
Comprehensive Output Format

Identified Role Type: [Primary role classification]
Industry/Sector: [Detected industry]
Career Level: [Entry/Mid/Senior/Executive]
Years of Experience: [Calculated years]
Likely Target Position: [Inferred next role]
OVERALL RATING: X/10[Based on auto-detected role standards]
EXECUTIVE SUMMARY
[3-4 sentences providing overall assessment based on the automatically identified role type, highlighting market positioning and key differentiators relevant to the detected industry]
DETECTED STRENGTHS (5-7 items)

[Strength relevant to identified role]
[Industry-specific advantages noted]
[Competitive differentiators for position type]
CRITICAL IMPROVEMENTS NEEDED

[Role-Specific Improvement Area]
Current Issue: [Problem for this role type]
Industry Impact: [Why this matters in detected field]
Recommendation: [Specific to role/industry]
Implementation: [Actionable steps]
[Continue for top 4-5 areas based on role...]
COMPETENCY GAP ANALYSIS[For Auto-Detected Role: (Position Title)]
Essential Missing Skills:

[Skill critical for detected role]: Acquisition method
[Industry-standard requirement]: How to obtain
Recommended Skills:

[Enhance competitiveness]: Priority level
Certifications for Your Field:

[Industry-specific certifications detected as valuable]
EXPERIENCE OPTIMIZATION[Based on detected career level and industry norms]
Quantification Opportunities:

[Area]: Add [specific metric type for industry]
[Achievement]: Include [relevant KPI for role]
Industry-Specific Improvements:

Current presentation: [Issue]
Industry-standard approach: [Improvement]
RESUME STRUCTURE RECOMMENDATIONS[Adapted to detected role type and industry]
Format Optimization:

[Industry-appropriate format suggestions]
[Role-specific section ordering]
ATS Optimization for [Detected Role]:

Missing keywords: [Role-specific terms]
Overused terms: [To reduce]
Industry keywords needed: [Specific to field]
MISSING ELEMENTS FOR [ROLE TYPE]

[Industry-standard sections not present]
[Expected information for career level]
[Digital assets expected for role]
MARKET POSITIONING ASSESSMENT
For Detected Role: [Position Type]

Market Competitiveness: [Low/Medium/High]
Suitable Positions: [3-5 specific titles]
Industry Positioning: [Where you fit]
Estimated Salary Range: [Based on detected market]
Career Trajectory Analysis:

Natural Next Step: [Based on progression]
Stretch Positions: [Achievable with improvements]
Alternative Paths: [Related roles to consider]
TAILORED ACTION PLAN[Specific to detected role and career stage]
Immediate Fixes (This week)

[Most critical for your role type]
[Quick wins for your industry]
[Format fixes for your field]
Short-term Development (1-3 months)

[Skills critical for detected role]
[Certifications valuable in your industry]
[Portfolio/samples if relevant to field]
Strategic Goals (3-6 months)

[Advanced competencies for role progression]
[Industry visibility for your field]
[Leadership development for level]
INTERVIEW PREPARATION[For detected role type and level]
Likely Questions for [Role Type]:

[Technical questions for this position]
[Behavioral questions for this level]
[Industry-specific scenarios]
Areas of Scrutiny:

[Common concerns for this role transition]
[Gaps that need explaining]
COMPETITIVE ANALYSIS[Within detected industry and role]
Your Differentiation:

Unique advantages: [Specific to role]
Competitive gaps: [Honest assessment]
Positioning strategy: [How to compete]
INDUSTRY-SPECIFIC INSIGHTS[Auto-generated based on detected field]
[Relevant insights, trends, and recommendations specific to the identified industry, including current market conditions, in-demand skills, and emerging requirements]
CONFIDENCE LEVELS

Role Detection Confidence: [High/Medium/Low]
Industry Identification: [High/Medium/Low]
Career Level Assessment: [High/Medium/Low]
Note: If any detection confidence is low, alternative interpretations will be provided

Intelligent Evaluation Rules
Auto-Adaptation Principles
Adjust language complexity based on detected career level
Apply industry-specific standards automatically
Weight technical vs soft skills based on role type
Consider geographic market from resume location
Adapt formality based on industry norms
Special Detection Cases
Multiple Role Types: Identify primary and secondary roles
Career Changers: Detect transition patterns and advise accordingly
Unclear Industry: Provide multi-industry recommendations
Mixed Level Signals: Address inconsistencies explicitly
International Profiles: Adjust for regional differences
Quality Assurance
Always state what was auto-detected for transparency
Provide confidence levels for detections
Offer alternative interpretations if unclear
Flag any unusual patterns for attention
Validate assumptions through multiple signals
Final Execution Note
Begin every evaluation by clearly stating what you've automatically detected from the resume. This ensures transparency and allows for correction if needed. The entire evaluation should feel personally tailored to the specific role, industry, and career level detected, not generic.
Your goal: Provide an intelligent, customized evaluation that feels like it was written by an expert recruiter who specializes in the candidate's exact field and role type - all through automatic detection and adaptation.

CRITICAL: OUTPUT FORMAT REQUIREMENT
You MUST return your analysis in VALID JSON format ONLY. Do not include any markdown formatting, explanatory text, or code blocks. Return ONLY the JSON object.

Use this EXACT JSON structure:

{
  "auto_detected_profile": {
    "identified_role_type": "string",
    "industry_sector": "string",
    "career_level": "string",
    "years_of_experience": number,
    "likely_target_position": "string"
  },
  "overall_score": number (0-10),
  "overall_feedback": "string",
  "executive_summary": "string (3-4 paragraphs)",
  "detected_strengths": ["string", "string", ...],
  "critical_improvements": [
    {
      "area": "string",
      "current_issue": "string",
      "industry_impact": "string",
      "recommendation": "string",
      "implementation": "string"
    }
  ],
  "competency_gap_analysis": {
    "essential_missing_skills": ["string", ...],
    "recommended_skills": ["string", ...],
    "certifications": ["string", ...]
  },
  "skills": {
    "technical": ["string", ...],
    "soft": ["string", ...],
    "domain": ["string", ...]
  },
  "experience": {
    "summary": "string",
    "yearsOfExperience": number,
    "keyAchievements": ["string", ...],
    "companies": ["string", ...],
    "jobTitles": ["string", ...]
  },
  "experience_optimization": {
    "quantification_opportunities": ["string", ...],
    "industry_specific_improvements": ["string", ...]
  },
  "education": {
    "degrees": ["string", ...],
    "certifications": ["string", ...],
    "educationLevel": "string"
  },
  "resume_structure_recommendations": {
    "format_optimization": ["string", ...],
    "ats_optimization": ["string", ...],
    "missing_elements": ["string", ...]
  },
  "market_positioning": {
    "market_competitiveness": "string (High/Medium/Low)",
    "suitable_positions": ["string", ...],
    "salary_range": "string",
    "career_trajectory": {
      "natural_next_step": "string",
      "stretch_positions": ["string", ...],
      "alternative_paths": ["string", ...]
    }
  },
  "action_plan": {
    "immediate_fixes": ["string", ...],
    "short_term": ["string", ...],
    "strategic_goals": ["string", ...]
  },
  "interview_preparation": {
    "likely_questions": ["string", ...],
    "areas_of_scrutiny": ["string", ...]
  },
  "competitive_analysis": {
    "unique_advantages": ["string", ...],
    "competitive_gaps": ["string", ...],
    "positioning_strategy": "string"
  },
  "industry_insights": "string (comprehensive paragraph)",
  "confidence_levels": {
    "role_detection": "string (High/Medium/Low)",
    "industry_identification": "string (High/Medium/Low)",
    "career_level": "string (High/Medium/Low)"
  },
  "strengths": ["string", ...],
  "improvements": ["string", ...],
  "interviewTips": ["string", ...],
  "jobRecommendations": ["string", ...],
  "atsOptimization": {
    "score": number (0-10),
    "issues": ["string", ...],
    "suggestions": ["string", ...]
  },
  "keywordAnalysis": {
    "relevantKeywords": ["string", ...],
    "missingKeywords": ["string", ...],
    "keywordDensity": "string"
  }
}

RESUME CONTENT TO ANALYZE:
$resumeText

Remember: Return ONLY the JSON object above. No markdown, no explanations, no code blocks. Just pure JSON.
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

  /// Normalize score to 0-10 range
  /// Handles both 0-10 and 0-100 scale inputs
  double _normalizeScore(dynamic value) {
    double score = _ensureDouble(value, 7.5);

    // If score is greater than 10, assume it's on 0-100 scale
    if (score > 10.0) {
      score = score / 10.0;
    }

    // Clamp to 0-10 range
    return score.clamp(0.0, 10.0);
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

  /// Get holistic interview summary by analyzing all answers together
  Future<Map<String, dynamic>> getInterviewSummary({
    required List<Map<String, dynamic>> transcript,
    required String jobTitle,
  }) async {
    try {
      await initialize();

      // Build the complete interview transcript
      final transcriptText = StringBuffer();
      for (var i = 0; i < transcript.length; i++) {
        final item = transcript[i];
        final questionText = item['question']['question_text'];
        final answerText = item['answer_text'];
        transcriptText.writeln('Q${i + 1}: $questionText');
        transcriptText.writeln('A${i + 1}: $answerText');
        transcriptText.writeln();
      }

      // Create the evaluation prompt
      final prompt =
          '''
You are an expert technical interviewer evaluating a complete interview session for a $jobTitle position.

Please analyze the following complete interview transcript and provide a holistic evaluation.

INTERVIEW TRANSCRIPT:
$transcriptText

EVALUATION REQUIREMENTS:
Provide a comprehensive assessment that includes:

1. OVERALL PERFORMANCE SCORE (0-100): Rate the candidate's overall interview performance
2. TECHNICAL COMPETENCY SCORE (0-100): Assess technical knowledge and problem-solving ability
3. COMMUNICATION SCORE (0-100): Evaluate clarity, articulation, and communication skills
4. PROBLEM-SOLVING SCORE (0-100): Rate analytical thinking and approach to problems
5. CONFIDENCE SCORE (0-100): Assess confidence level and professionalism
6. STRENGTHS ANALYSIS: Identify key strengths demonstrated across all answers
7. AREAS FOR IMPROVEMENT: Highlight specific areas needing improvement
8. AI SUMMARY: Provide a comprehensive 2-3 paragraph summary of the interview performance

IMPORTANT: Return ONLY valid JSON in this exact format (no markdown, no extra text):

{
  "overall_score": 8.5,
  "technical_score": 8.2,
  "communication_score": 8.8,
  "problem_solving_score": 8.0,
  "confidence_score": 8.7,
  "strengths_analysis": ["Strength 1 with specific examples", "Strength 2 with details"],
  "areas_for_improvement": ["Area 1 with actionable advice", "Area 2 with suggestions"],
  "ai_summary": "Comprehensive 2-3 paragraph summary analyzing overall performance, key highlights, areas of concern, and final recommendations."
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '';

      debugPrint('Gemini Interview Summary Response: $responseText');

      // Parse the JSON response
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

      final parsedJson = jsonDecode(cleanJsonString) as Map<String, dynamic>;

      // Validate and return the summary (normalize scores to 0-10 range)
      return {
        'overall_score': _normalizeScore(parsedJson['overall_score'] ?? 7.5),
        'technical_score': _normalizeScore(
          parsedJson['technical_score'] ?? 7.5,
        ),
        'communication_score': _normalizeScore(
          parsedJson['communication_score'] ?? 7.5,
        ),
        'problem_solving_score': _normalizeScore(
          parsedJson['problem_solving_score'] ?? 7.5,
        ),
        'confidence_score': _normalizeScore(
          parsedJson['confidence_score'] ?? 7.5,
        ),
        'strengths_analysis': _ensureList(parsedJson['strengths_analysis']),
        'areas_for_improvement': _ensureList(
          parsedJson['areas_for_improvement'],
        ),
        'ai_summary':
            parsedJson['ai_summary']?.toString() ?? 'Summary not available',
      };
    } catch (e) {
      debugPrint('Error generating interview summary: $e');
      rethrow;
    }
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

  /// Generate professional interview questions for a specific job role
  Future<List<Map<String, dynamic>>> generateInterviewQuestions({
    required String jobTitle,
    required String jobCategory,
    required List<String> requiredSkills,
    required String difficultyLevel,
    required int questionCount,
    String? jobDescription,
    String? industry,
    String? experienceLevel,
  }) async {
    const int maxRetries = 3;
    const Duration baseDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint(
          'Interview questions generation attempt $attempt of $maxRetries',
        );
        await initialize();

        final questionsResult = await _performQuestionGeneration(
          jobTitle: jobTitle,
          jobCategory: jobCategory,
          requiredSkills: requiredSkills,
          difficultyLevel: difficultyLevel,
          questionCount: questionCount,
          jobDescription: jobDescription,
          industry: industry,
          experienceLevel: experienceLevel,
        );

        debugPrint(
          'Interview questions generated successfully on attempt $attempt',
        );
        return questionsResult;
      } catch (e) {
        debugPrint('Attempt $attempt failed: $e');

        if (_isRetryableError(e) && attempt < maxRetries) {
          final delay = Duration(
            milliseconds: baseDelay.inMilliseconds * (1 << (attempt - 1)),
          );

          debugPrint(
            'Retrying in ${delay.inSeconds} seconds... (attempt ${attempt + 1}/$maxRetries)',
          );
          await Future.delayed(delay);
          continue;
        }

        if (attempt == maxRetries) {
          debugPrint('All retry attempts exhausted. Throwing error.');
          rethrow;
        }
      }
    }

    throw Exception('Interview questions generation failed after all retries');
  }

  /// Perform the actual question generation
  Future<List<Map<String, dynamic>>> _performQuestionGeneration({
    required String jobTitle,
    required String jobCategory,
    required List<String> requiredSkills,
    required String difficultyLevel,
    required int questionCount,
    String? jobDescription,
    String? industry,
    String? experienceLevel,
  }) async {
    final prompt = _buildQuestionGenerationPrompt(
      jobTitle: jobTitle,
      jobCategory: jobCategory,
      requiredSkills: requiredSkills,
      difficultyLevel: difficultyLevel,
      questionCount: questionCount,
      jobDescription: jobDescription,
      industry: industry,
      experienceLevel: experienceLevel,
    );

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    final responseText = response.text ?? '';

    debugPrint('Gemini Questions Raw Response: $responseText');

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
      final jsonStart = cleanJsonString.indexOf('[');
      final jsonEnd = cleanJsonString.lastIndexOf(']') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        cleanJsonString = cleanJsonString.substring(jsonStart, jsonEnd);
      }

      debugPrint('Cleaned JSON String for questions: $cleanJsonString');

      // Parse the JSON
      final parsedJson = jsonDecode(cleanJsonString) as List<dynamic>;

      // Validate and convert to proper format
      final questions = parsedJson
          .map((q) => _validateQuestionData(q as Map<String, dynamic>))
          .toList();

      debugPrint('Successfully parsed ${questions.length} interview questions');
      return questions;
    } catch (parseError) {
      debugPrint('Error parsing Gemini questions JSON response: $parseError');
      debugPrint('Raw response for debugging: $responseText');
      throw Exception('Failed to parse Gemini questions response: $parseError');
    }
  }

  /// Build the question generation prompt
  String _buildQuestionGenerationPrompt({
    required String jobTitle,
    required String jobCategory,
    required List<String> requiredSkills,
    required String difficultyLevel,
    required int questionCount,
    String? jobDescription,
    String? industry,
    String? experienceLevel,
  }) {
    return '''
You are an expert HR professional and technical interviewer with 15+ years of experience in conducting interviews across various industries. Generate $questionCount professional, real-world interview questions for the following job role.

JOB ROLE DETAILS:
- Position: $jobTitle
- Category: $jobCategory
- Industry: ${industry ?? 'Technology'}
- Experience Level: ${experienceLevel ?? 'Mid-level'}
- Difficulty Level: $difficultyLevel
- Required Skills: ${requiredSkills.join(', ')}
${jobDescription != null ? '- Job Description: $jobDescription' : ''}

QUESTION REQUIREMENTS:
1. Generate a balanced mix of question types:
   - Technical questions (40%): Role-specific technical knowledge and problem-solving
   - Behavioral questions (30%): STAR method scenarios, leadership, teamwork
   - Situational questions (20%): Hypothetical scenarios and decision-making
   - General questions (10%): Motivation, career goals, company fit

2. Difficulty Distribution based on level:
   - Easy: Basic concepts, fundamental knowledge
   - Medium: Practical application, moderate complexity
   - Hard: Advanced scenarios, complex problem-solving

3. Each question should:
   - Be realistic and commonly asked in actual interviews
   - Test relevant skills and competencies for the role
   - Be appropriate for the specified experience level
   - Include context when necessary
   - Be specific to the job category and industry

4. Include evaluation criteria and expected answer keywords for each question

IMPORTANT: Return ONLY a valid JSON array with no additional text or markdown formatting.

Expected JSON format:
[
  {
    "questionText": "Describe a challenging project you worked on and how you overcame the obstacles.",
    "questionType": "behavioral",
    "difficultyLevel": "medium",
    "expectedAnswerKeywords": ["STAR method", "problem-solving", "teamwork", "communication", "results"],
    "evaluationCriteria": {
      "structure": "Uses STAR method or clear structure",
      "specificity": "Provides specific examples and details",
      "impact": "Demonstrates measurable results or learning",
      "skills": "Shows relevant technical or soft skills"
    },
    "timeLimitSeconds": 180,
    "skillsAssessed": ["problem-solving", "communication", "project management"]
  }
]

Generate exactly $questionCount questions following this format, ensuring they are relevant to $jobTitle in the $jobCategory field with $difficultyLevel difficulty level.
''';
  }

  /// Validate and enhance question data
  Map<String, dynamic> _validateQuestionData(Map<String, dynamic> data) {
    return {
      'questionText':
          data['questionText']?.toString() ?? 'Sample interview question',
      'questionType': data['questionType']?.toString() ?? 'general',
      'difficultyLevel': data['difficultyLevel']?.toString() ?? 'medium',
      'expectedAnswerKeywords': _ensureList(data['expectedAnswerKeywords']),
      'evaluationCriteria': data['evaluationCriteria'] ?? {},
      'timeLimitSeconds': data['timeLimitSeconds'] ?? 120,
      'skillsAssessed': _ensureList(data['skillsAssessed']),
    };
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

  /// Evaluate interview answer using Gemini AI for comprehensive analysis
  ///
  /// This method provides detailed analysis of candidate responses including:
  /// - Technical accuracy and depth
  /// - Communication clarity and structure
  /// - Relevance to the question asked
  /// - Professional competency demonstration
  /// - Areas for improvement and feedback
  Future<Map<String, dynamic>> evaluateInterviewAnswer({
    required String questionText,
    required String questionType,
    required String userAnswer,
    required List<String> expectedKeywords,
    required String difficultyLevel,
    String? idealAnswer,
    String? evaluationCriteria,
    String? jobTitle,
    String? jobCategory,
    Map<String, dynamic>? transcriptionAnalysis,
  }) async {
    const int maxRetries = 3;
    const Duration baseDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('Answer evaluation attempt $attempt of $maxRetries');
        await initialize();

        final evaluationResult = await _performAnswerEvaluation(
          questionText: questionText,
          questionType: questionType,
          userAnswer: userAnswer,
          expectedKeywords: expectedKeywords,
          difficultyLevel: difficultyLevel,
          idealAnswer: idealAnswer,
          evaluationCriteria: evaluationCriteria,
          jobTitle: jobTitle,
          jobCategory: jobCategory,
          transcriptionAnalysis: transcriptionAnalysis,
        );

        debugPrint(
          'Answer evaluation completed successfully on attempt $attempt',
        );
        return evaluationResult;
      } catch (e) {
        debugPrint('Answer evaluation attempt $attempt failed: $e');

        if (_isRetryableError(e) && attempt < maxRetries) {
          final delay = Duration(
            milliseconds: baseDelay.inMilliseconds * (1 << (attempt - 1)),
          );
          debugPrint('Retrying in ${delay.inSeconds} seconds...');
          await Future.delayed(delay);
          continue;
        }

        if (attempt == maxRetries) {
          debugPrint('All retry attempts exhausted for answer evaluation.');
          rethrow;
        }
      }
    }

    throw Exception('Answer evaluation failed after all retries');
  }

  /// Perform the actual answer evaluation with enhanced analysis
  Future<Map<String, dynamic>> _performAnswerEvaluation({
    required String questionText,
    required String questionType,
    required String userAnswer,
    required List<String> expectedKeywords,
    required String difficultyLevel,
    String? idealAnswer,
    String? evaluationCriteria,
    String? jobTitle,
    String? jobCategory,
    Map<String, dynamic>? transcriptionAnalysis,
  }) async {
    final prompt = _buildAnswerEvaluationPrompt(
      questionText: questionText,
      questionType: questionType,
      userAnswer: userAnswer,
      expectedKeywords: expectedKeywords,
      difficultyLevel: difficultyLevel,
      idealAnswer: idealAnswer,
      evaluationCriteria: evaluationCriteria,
      jobTitle: jobTitle,
      jobCategory: jobCategory,
      transcriptionAnalysis: transcriptionAnalysis,
    );

    debugPrint('Sending answer evaluation request to Gemini...');
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    final responseText = response.text ?? '';

    debugPrint('Gemini Answer Evaluation Raw Response: $responseText');

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

      debugPrint('Cleaned JSON String for answer evaluation: $cleanJsonString');

      // Parse the JSON
      final parsedJson = jsonDecode(cleanJsonString) as Map<String, dynamic>;

      // Validate and return the evaluation result
      return _validateEvaluationData(parsedJson);
    } catch (parseError) {
      debugPrint(
        'Error parsing Gemini answer evaluation JSON response: $parseError',
      );
      debugPrint('Raw response for debugging: $responseText');

      // Return a fallback evaluation
      return _createFallbackEvaluation(userAnswer, expectedKeywords);
    }
  }

  /// Build the answer evaluation prompt for Gemini AI
  String _buildAnswerEvaluationPrompt({
    required String questionText,
    required String questionType,
    required String userAnswer,
    required List<String> expectedKeywords,
    required String difficultyLevel,
    String? idealAnswer,
    String? evaluationCriteria,
    String? jobTitle,
    String? jobCategory,
    Map<String, dynamic>? transcriptionAnalysis,
  }) {
    // Extract enhanced transcription data if available
    final geminiSummary =
        transcriptionAnalysis?['gemini_summary'] as Map<String, dynamic>?;
    final speechAnalysis =
        geminiSummary?['speech_analysis'] as Map<String, dynamic>?;
    final contentAnalysis =
        geminiSummary?['content_analysis'] as Map<String, dynamic>?;
    final qualityIndicators =
        geminiSummary?['quality_indicators'] as Map<String, dynamic>?;
    final recommendations =
        geminiSummary?['recommendation_for_gemini'] as Map<String, dynamic>?;

    // Build transcription confidence and analysis info
    final confidenceInfo = transcriptionAnalysis != null
        ? '''
TRANSCRIPTION QUALITY ANALYSIS:
- Transcription Accuracy: ${(transcriptionAnalysis['confidence'] as num?)?.toStringAsFixed(2) ?? 'N/A'}%
- Overall Confidence: ${geminiSummary?['overall_confidence'] ?? 'Unknown'}
- Quality Score: ${(geminiSummary?['confidence_score'] as num?)?.toStringAsFixed(2) ?? 'N/A'}'''
        : 'No transcription analysis available';

    final speechAnalysisInfo = speechAnalysis != null
        ? '''
SPEECH DELIVERY ANALYSIS:
- Speaking Pace: ${(speechAnalysis['words_per_minute'] as num?)?.toStringAsFixed(1) ?? 'N/A'} words/minute
- Total Words: ${speechAnalysis['total_words'] ?? 'N/A'}
- Sentence Count: ${speechAnalysis['sentence_count'] ?? 'N/A'}
- Hesitation Count: ${speechAnalysis['hesitation_count'] ?? 'N/A'}
- Filler Words: ${speechAnalysis['filler_word_count'] ?? 'N/A'}'''
        : '';

    final contentAnalysisInfo = contentAnalysis != null
        ? '''
CONTENT ANALYSIS:
- Answer Coherence: ${(contentAnalysis['coherence_score'] as num?)?.toStringAsFixed(2) ?? 'N/A'}
- Question Relevance: ${(contentAnalysis['relevance_score'] as num?)?.toStringAsFixed(2) ?? 'N/A'}
- Technical Term Density: ${(contentAnalysis['technical_term_density'] as num?)?.toStringAsFixed(3) ?? 'N/A'}
- Keyword Matches: ${contentAnalysis['keyword_matches'] ?? 'N/A'}'''
        : '';

    final qualityInfo = qualityIndicators != null
        ? '''
QUALITY INDICATORS:
- Speech Clarity: ${(qualityIndicators['speech_clarity'] as num?)?.toStringAsFixed(2) ?? 'N/A'}
- Technical Competency: ${(qualityIndicators['technical_competency'] as num?)?.toStringAsFixed(2) ?? 'N/A'}
- Communication Fluency: ${(qualityIndicators['communication_fluency'] as num?)?.toStringAsFixed(2) ?? 'N/A'}'''
        : '';

    final evaluationGuidance = recommendations != null
        ? '''
EVALUATION GUIDANCE:
Focus Areas: ${(recommendations['evaluation_focus'] as List<dynamic>?)?.join(', ') ?? 'Standard evaluation'}
Attention Points: ${(recommendations['attention_points'] as List<dynamic>?)?.join(', ') ?? 'None'}'''
        : '';

    return '''
You are an expert interview assessor with 15+ years of experience in evaluating candidate responses across various industries. You have access to advanced speech-to-text analysis data that provides insights into both the content and delivery of the candidate's response. Use this data to provide a comprehensive and accurate evaluation.

INTERVIEW CONTEXT:
- Position: ${jobTitle ?? 'Not specified'}
- Category: ${jobCategory ?? 'General'}
- Question Type: $questionType
- Difficulty Level: $difficultyLevel
- Question: "$questionText"

CANDIDATE RESPONSE:
"$userAnswer"

EVALUATION CRITERIA:
- Expected Keywords: ${expectedKeywords.join(', ')}
${idealAnswer != null ? '- Ideal Answer: "$idealAnswer"' : ''}
${evaluationCriteria != null ? '- Specific Criteria: $evaluationCriteria' : ''}

$confidenceInfo

$speechAnalysisInfo

$contentAnalysisInfo

$qualityInfo

$evaluationGuidance

COMPREHENSIVE EVALUATION REQUIREMENTS:
1. Technical Accuracy (0-10): Assess correctness, depth, and precision of technical knowledge
2. Communication Clarity (0-10): Evaluate clarity, structure, and effectiveness of communication
3. Relevance Score (0-10): Measure how directly the answer addresses the question
4. Completeness (0-10): Assess coverage of all important aspects and thoroughness
5. Professional Competency (0-10): Evaluate demonstration of relevant skills and experience

ANALYSIS CONSIDERATIONS:
- Use transcription confidence to adjust evaluation reliability
- Consider speech delivery metrics for communication assessment
- Factor in technical term usage for competency evaluation
- Account for hesitations and filler words in fluency scoring
- Use coherence scores to validate logical structure
- Apply relevance metrics to ensure question alignment

EVALUATION ADJUSTMENTS BASED ON TRANSCRIPTION DATA:
- If transcription confidence is low (<70%), note potential misinterpretations
- If speaking pace is very fast (>220 wpm) or slow (<80 wpm), consider communication impact
- If hesitation count is high (>5), factor into confidence assessment
- If technical term density is low for technical roles, adjust competency scoring
- If coherence score is low (<0.6), focus on content extraction over structure

IMPORTANT: Return ONLY a valid JSON response with no additional text or markdown formatting.

Expected JSON format:
{
  "overall_score": 8.5,
  "technical_accuracy": 8.0,
  "communication_clarity": 9.0,
  "relevance_score": 8.5,
  "completeness": 7.5,
  "professional_competency": 8.0,
  "transcription_reliability": 0.95,
  "speech_delivery_score": 8.2,
  "keywords_mentioned": ["keyword1", "keyword2"],
  "missing_keywords": ["keyword3", "keyword4"],
  "strengths": [
    "Clear communication with excellent structure",
    "Strong technical knowledge demonstrated",
    "Effective use of specific examples and evidence",
    "Confident delivery with minimal hesitations"
  ],
  "areas_for_improvement": [
    "Could provide more quantifiable results",
    "Consider deeper technical exploration of edge cases"
  ],
  "detailed_feedback": "The candidate provided a well-structured and confident response demonstrating strong technical knowledge. The answer was delivered clearly with good pacing and minimal hesitations, indicating strong communication skills. The content directly addressed the question with relevant technical details.",
  "ideal_answer_comparison": "Response covers 85% of ideal answer points with good depth and relevant examples.",
  "confidence_assessment": "High confidence demonstrated through clear delivery, appropriate technical terminology, and comprehensive coverage of the topic.",
  "transcription_notes": "High quality transcription with excellent accuracy enables reliable evaluation.",
  "communication_analysis": "Excellent speaking pace and minimal filler words indicate strong verbal communication skills.",
  "technical_depth_analysis": "Appropriate use of technical terminology and concepts for the role level.",
  "recommendation": "Strong candidate with excellent communication skills and solid technical foundation. Ready for next interview stage."
}

Provide a thorough, fair, and constructive evaluation that leverages the enhanced transcription analysis for maximum accuracy.
''';
  }

  /// Validate and enhance evaluation data
  Map<String, dynamic> _validateEvaluationData(Map<String, dynamic> data) {
    return {
      'overall_score': _validateScore(data['overall_score']),
      'technical_accuracy': _validateScore(data['technical_accuracy']),
      'communication_clarity': _validateScore(data['communication_clarity']),
      'relevance_score': _validateScore(data['relevance_score']),
      'completeness': _validateScore(data['completeness']),
      'professional_competency': _validateScore(
        data['professional_competency'],
      ),
      'transcription_reliability': _validateScore(
        data['transcription_reliability'],
      ),
      'speech_delivery_score': _validateScore(data['speech_delivery_score']),
      'keywords_mentioned': _ensureList(data['keywords_mentioned']),
      'missing_keywords': _ensureList(data['missing_keywords']),
      'strengths': _ensureList(data['strengths']),
      'areas_for_improvement': _ensureList(data['areas_for_improvement']),
      'detailed_feedback':
          data['detailed_feedback']?.toString() ??
          'Good response with room for improvement.',
      'ideal_answer_comparison':
          data['ideal_answer_comparison']?.toString() ??
          'Response addresses the key points adequately.',
      'confidence_assessment':
          data['confidence_assessment']?.toString() ??
          'Moderate confidence demonstrated.',
      'transcription_notes':
          data['transcription_notes']?.toString() ??
          'Transcription quality is adequate for evaluation.',
      'communication_analysis':
          data['communication_analysis']?.toString() ??
          'Communication skills are appropriate for the role.',
      'technical_depth_analysis':
          data['technical_depth_analysis']?.toString() ??
          'Technical knowledge demonstrates basic understanding.',
      'recommendation':
          data['recommendation']?.toString() ??
          'Continue practicing to enhance interview skills.',
    };
  }

  /// Validate score values to ensure they are within 0-10 range
  double _validateScore(dynamic score) {
    if (score == null) return 5.0;

    double parsedScore = 5.0;
    if (score is num) {
      parsedScore = score.toDouble();
    } else if (score is String) {
      parsedScore = double.tryParse(score) ?? 5.0;
    }

    // Ensure score is within valid range
    return parsedScore.clamp(0.0, 10.0);
  }

  /// Create fallback evaluation when AI analysis fails
  Map<String, dynamic> _createFallbackEvaluation(
    String userAnswer,
    List<String> expectedKeywords,
  ) {
    final answerLength = userAnswer.trim().length;
    final hasContent = answerLength > 20;

    // Basic keyword matching
    final mentionedKeywords = <String>[];
    final missingKeywords = <String>[];

    for (final keyword in expectedKeywords) {
      if (userAnswer.toLowerCase().contains(keyword.toLowerCase())) {
        mentionedKeywords.add(keyword);
      } else {
        missingKeywords.add(keyword);
      }
    }

    final keywordScore = expectedKeywords.isEmpty
        ? 7.0
        : (mentionedKeywords.length / expectedKeywords.length) * 10.0;

    final baseScore = hasContent ? 6.0 : 3.0;
    final adjustedScore = ((baseScore + keywordScore) / 2).clamp(0.0, 10.0);

    return {
      'overall_score': adjustedScore,
      'technical_accuracy': adjustedScore,
      'communication_clarity': hasContent ? 7.0 : 4.0,
      'relevance_score': keywordScore,
      'completeness': hasContent ? 6.0 : 3.0,
      'professional_competency': adjustedScore,
      'keywords_mentioned': mentionedKeywords,
      'missing_keywords': missingKeywords,
      'strengths': hasContent
          ? [
              'Provided a response to the question',
              'Used some relevant terminology',
            ]
          : ['Attempted to answer the question'],
      'areas_for_improvement': [
        'Consider providing more detailed explanations',
        'Include specific examples and evidence',
        'Address all aspects of the question',
      ],
      'detailed_feedback': hasContent
          ? 'The response shows basic understanding but could be enhanced with more detail and specific examples.'
          : 'The response is too brief and lacks sufficient detail. Consider expanding your answer with more information.',
      'ideal_answer_comparison':
          'The response addresses some key points but could be more comprehensive.',
      'confidence_assessment': hasContent
          ? 'Moderate confidence'
          : 'Low confidence',
      'recommendation':
          'Practice providing more detailed and structured responses to interview questions.',
    };
  }
}
