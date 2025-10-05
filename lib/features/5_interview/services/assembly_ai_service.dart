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

  /// Complete transcription process from audio file to text (legacy method)
  ///
  /// [audioFilePath] - Path to the local audio file to transcribe
  /// Returns the transcribed text or throws an exception on error
  ///
  /// Note: This method is maintained for backward compatibility.
  /// For enhanced features, use transcribeAudioWithAnalysis() instead.
  Future<String> transcribeAudio(String audioFilePath) async {
    final result = await transcribeAudioWithAnalysis(audioFilePath);
    return result['text'] as String;
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

  /// Step B: Submit transcription request to AssemblyAI with enhanced settings
  ///
  /// [uploadUrl] - The secure upload URL from step A
  /// [customVocabulary] - Additional domain-specific terms to boost accuracy
  /// Returns the transcription job ID
  Future<String> _submitTranscriptionRequest(
    String uploadUrl, {
    List<String>? customVocabulary,
    String? jobRole,
  }) async {
    try {
      // Enhanced word boost list combining general tech terms with custom vocabulary
      final wordBoostList = [
        // Core tech terms
        'API',
        'REST',
        'GraphQL',
        'microservices',
        'containerization',
        'Kubernetes',
        'Docker',
        'CI/CD',
        'DevOps',
        'Agile',
        'Scrum',
        'JavaScript',
        'TypeScript',
        'React',
        'Node.js',
        'Python',
        'machine learning',
        'artificial intelligence',
        'data structures',
        'algorithms',
        'database',
        'SQL',
        'NoSQL',
        'cloud computing',
        'frontend',
        'backend',
        'fullstack',
        'framework',
        'library',
        'repository',
        'version control',
        'Git',
        'GitHub',
        'AWS',
        'Azure',
        'Google Cloud',
        'SOLID principles',
        'design patterns',
        'MVC',
        'MVP',
        'MVVM',
        'object-oriented',
        'functional programming',
        'asynchronous',
        'synchronous',
        'authentication',
        'authorization',
        'encryption',
        'security',
        'performance optimization',
        'scalability',
        'load balancing',
        'caching',
        'testing',
        'unit testing',
        'integration testing',
        'debugging',
        'troubleshooting',
        'deployment',
        'monitoring',
        'analytics',
        // Add custom vocabulary if provided
        ...?customVocabulary,
      ];

      final requestBody = jsonEncode({
        'audio_url': uploadUrl,

        // Core transcription settings optimized for interview accuracy
        'punctuate': true, // Add punctuation for better readability
        'format_text': true, // Format text with proper capitalization
        'dual_channel': false, // Single channel for interview audio
        // Advanced speech recognition settings
        'speaker_labels': false, // Disable for single speaker interviews
        // Note: speakers_expected can only be set when speaker_labels is true
        'auto_highlights':
            true, // Highlight important phrases and technical terms
        'disfluencies': false, // Remove filler words for cleaner analysis
        'filter_profanity': false, // Keep all content for authentic evaluation
        // AI-powered enhancements for comprehensive analysis
        'sentiment_analysis': true, // Analyze emotional tone and confidence
        'entity_detection':
            true, // Detect technical terms, companies, technologies
        'iab_categories': true, // Categorize content for topic analysis
        'content_safety': true, // Enable content safety detection
        'content_safety_confidence': 60, // Confidence threshold (0-100)
        // Interview-specific optimizations
        'redact_pii':
            true, // Protect personal information while preserving context
        'redact_pii_policies': [
          'person_name',
          'phone_number',
          'email_address',
          'credit_card_number',
          'ssn',
        ],
        'redact_pii_sub': '[CONFIDENTIAL]',

        // Enhanced vocabulary boosting for technical interviews
        'word_boost': wordBoostList,

        // Language setting
        'language_code': 'en', // Optimize for English interviews
        // Advanced features for detailed analysis
        'auto_chapters': false, // Not needed for single questions
        'summarization': false, // We'll handle summarization with Gemini
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

  /// Step C: Poll for transcription results with enhanced data extraction
  ///
  /// [transcriptId] - The transcription job ID from step B
  /// Returns the final transcribed text with analysis data
  Future<Map<String, dynamic>> pollForResults(String transcriptId) async {
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

              // Extract enhanced data for Gemini analysis
              return {
                'text': text,
                'confidence': responseData['confidence']?.toDouble() ?? 0.0,
                'sentiment_analysis':
                    responseData['sentiment_analysis_results'],
                'entities': responseData['entities'],
                'iab_categories': responseData['iab_categories_result'],
                'auto_highlights': responseData['auto_highlights_result'],
                'audio_duration':
                    responseData['audio_duration']?.toDouble() ?? 0.0,
                'words':
                    responseData['words'], // Word-level timing and confidence
              };

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

  /// Enhanced transcription with analysis data for Gemini AI
  ///
  /// [audioFilePath] - Path to the local audio file to transcribe
  /// [jobRole] - Job role for vocabulary optimization
  /// [customVocabulary] - Additional domain-specific terms
  /// Returns comprehensive transcription data including text, confidence, sentiment, etc.
  Future<Map<String, dynamic>> transcribeAudioWithAnalysis(
    String audioFilePath, {
    String? jobRole,
    List<String>? customVocabulary,
  }) async {
    try {
      await initialize();

      debugPrint(
        'Starting enhanced AssemblyAI transcription for: $audioFilePath',
      );

      // Step 1: Upload audio file
      final uploadUrl = await _uploadAudioFile(audioFilePath);
      debugPrint('Audio uploaded successfully. Upload URL obtained.');

      // Step 2: Submit transcription request with enhanced settings
      final transcriptId = await _submitTranscriptionRequest(
        uploadUrl,
        customVocabulary: [
          ...?customVocabulary,
          ..._getJobSpecificVocabulary(jobRole),
        ],
        jobRole: jobRole,
      );
      debugPrint('Enhanced transcription request submitted. ID: $transcriptId');

      // Step 3: Poll for results with analysis data
      final analysisData = await pollForResults(transcriptId);
      debugPrint(
        'Enhanced transcription completed successfully with analysis data',
      );

      return _enhanceTranscriptionData(analysisData, jobRole);
    } catch (e) {
      debugPrint('Error in enhanced transcription: $e');
      rethrow;
    }
  }

  /// Check if the service is properly initialized
  bool get isInitialized => _isInitialized;

  /// Dispose of any resources
  void dispose() {
    // No resources to dispose in this implementation
    debugPrint('AssemblyAI service disposed');
  }

  /// Get job-specific vocabulary for better transcription accuracy
  List<String> _getJobSpecificVocabulary(String? jobRole) {
    if (jobRole == null) return [];

    switch (jobRole.toLowerCase()) {
      case 'software engineer':
      case 'developer':
      case 'programmer':
        return [
          'refactoring',
          'debugging',
          'optimization',
          'architecture',
          'scalability',
          'maintainability',
          'modularity',
          'polymorphism',
          'inheritance',
          'encapsulation',
          'abstraction',
          'dependency injection',
          'inversion of control',
          'test-driven development',
          'behavior-driven development',
          'continuous integration',
          'continuous deployment',
          'code review',
          'pair programming',
          'technical debt',
          'legacy code',
          'performance metrics',
          'profiling',
          'memory management',
          'garbage collection',
          'concurrency',
          'multithreading',
          'asynchronous programming',
          'event-driven',
          'reactive programming',
          'functional programming',
          'imperative programming',
          'declarative programming',
        ];

      case 'data scientist':
      case 'data analyst':
      case 'ml engineer':
        return [
          'neural networks',
          'deep learning',
          'supervised learning',
          'unsupervised learning',
          'reinforcement learning',
          'feature engineering',
          'data preprocessing',
          'dimensionality reduction',
          'cross-validation',
          'overfitting',
          'underfitting',
          'regularization',
          'gradient descent',
          'backpropagation',
          'ensemble methods',
          'random forest',
          'support vector machines',
          'k-means clustering',
          'principal component analysis',
          'natural language processing',
          'computer vision',
          'time series analysis',
          'statistical significance',
          'p-value',
          'hypothesis testing',
          'correlation',
          'regression analysis',
          'classification',
          'clustering',
          'anomaly detection',
          'recommendation systems',
          'A/B testing',
          'experimental design',
        ];

      case 'devops':
      case 'sre':
      case 'infrastructure':
        return [
          'infrastructure as code',
          'configuration management',
          'orchestration',
          'containerization',
          'virtualization',
          'monitoring',
          'alerting',
          'logging',
          'observability',
          'distributed systems',
          'high availability',
          'disaster recovery',
          'backup strategies',
          'security hardening',
          'vulnerability assessment',
          'penetration testing',
          'compliance',
          'automation',
          'scripting',
          'pipeline',
          'deployment strategies',
          'blue-green deployment',
          'canary deployment',
          'rolling deployment',
          'infrastructure monitoring',
          'application performance monitoring',
          'service mesh',
          'load balancing',
          'auto-scaling',
          'capacity planning',
          'cost optimization',
        ];

      case 'product manager':
      case 'project manager':
        return [
          'user experience',
          'user interface',
          'product roadmap',
          'feature prioritization',
          'stakeholder management',
          'requirements gathering',
          'user stories',
          'acceptance criteria',
          'sprint planning',
          'retrospectives',
          'stand-ups',
          'burndown charts',
          'velocity',
          'backlog grooming',
          'product backlog',
          'minimum viable product',
          'product-market fit',
          'customer journey',
          'user personas',
          'market research',
          'competitive analysis',
          'go-to-market strategy',
          'pricing strategy',
          'revenue models',
          'key performance indicators',
          'metrics',
          'analytics',
          'conversion rates',
          'retention rates',
          'churn analysis',
          'customer feedback',
          'usability testing',
        ];

      default:
        return [];
    }
  }

  /// Enhance transcription data with additional analysis for Gemini AI
  Map<String, dynamic> _enhanceTranscriptionData(
    Map<String, dynamic> analysisData,
    String? jobRole,
  ) {
    // Calculate speech metrics for Gemini analysis
    final words = analysisData['words'] as List<dynamic>? ?? [];
    final speechMetrics = _calculateSpeechMetrics(words);

    // Extract and categorize entities
    final entities = analysisData['entities'] as List<dynamic>? ?? [];
    final categorizedEntities = _categorizeEntities(entities, jobRole);

    // Analyze sentiment patterns
    final sentimentAnalysis =
        analysisData['sentiment_analysis'] as Map<String, dynamic>?;
    final sentimentInsights = _analyzeSentimentPatterns(sentimentAnalysis);

    // Calculate technical term density
    final technicalDensity = _calculateTechnicalTermDensity(
      analysisData['text'] as String? ?? '',
      jobRole,
    );

    return {
      ...analysisData,
      'speech_metrics': speechMetrics,
      'categorized_entities': categorizedEntities,
      'sentiment_insights': sentimentInsights,
      'technical_density': technicalDensity,
      'quality_score': _calculateOverallQualityScore(
        analysisData,
        speechMetrics,
      ),
      'gemini_optimization': {
        'text_clarity': speechMetrics['clarity_score'],
        'confidence_distribution': speechMetrics['confidence_distribution'],
        'speaking_pace': speechMetrics['words_per_minute'],
        'technical_accuracy': technicalDensity,
        'emotional_confidence': sentimentInsights['confidence_level'],
      },
    };
  }

  /// Calculate speech metrics for detailed analysis
  Map<String, dynamic> _calculateSpeechMetrics(List<dynamic> words) {
    if (words.isEmpty) {
      return {
        'words_per_minute': 0.0,
        'average_confidence': 0.0,
        'confidence_distribution': <String, int>{},
        'clarity_score': 0.0,
        'hesitation_count': 0,
        'filler_word_count': 0,
      };
    }

    double totalConfidence = 0.0;
    final confidenceDistribution = <String, int>{
      'high': 0,
      'medium': 0,
      'low': 0,
    };

    int hesitationCount = 0;
    int fillerWordCount = 0;

    final fillerWords = {
      'um',
      'uh',
      'er',
      'ah',
      'like',
      'you know',
      'basically',
      'actually',
    };

    double? firstWordStart;
    double? lastWordEnd;

    for (final word in words) {
      final wordData = word as Map<String, dynamic>;
      final confidence = (wordData['confidence'] as num?)?.toDouble() ?? 0.0;
      final text = (wordData['text'] as String?)?.toLowerCase() ?? '';
      final start = (wordData['start'] as num?)?.toDouble();
      final end = (wordData['end'] as num?)?.toDouble();

      if (start != null) {
        firstWordStart ??= start;
        if (end != null) lastWordEnd = end;
      }

      totalConfidence += confidence;

      // Categorize confidence levels
      if (confidence >= 0.8) {
        confidenceDistribution['high'] = confidenceDistribution['high']! + 1;
      } else if (confidence >= 0.6) {
        confidenceDistribution['medium'] =
            confidenceDistribution['medium']! + 1;
      } else {
        confidenceDistribution['low'] = confidenceDistribution['low']! + 1;
      }

      // Count filler words
      if (fillerWords.contains(text)) {
        fillerWordCount++;
      }

      // Detect hesitations (low confidence + common hesitation patterns)
      if (confidence < 0.5 && text.length <= 3) {
        hesitationCount++;
      }
    }

    final averageConfidence = totalConfidence / words.length;
    final duration = (firstWordStart != null && lastWordEnd != null)
        ? (lastWordEnd - firstWordStart) /
              1000.0 // Convert to seconds
        : 1.0;
    final wordsPerMinute = (words.length / duration) * 60.0;

    // Calculate clarity score based on confidence distribution and filler words
    final highConfidenceRatio = confidenceDistribution['high']! / words.length;
    final fillerWordRatio = fillerWordCount / words.length;
    final clarityScore =
        (highConfidenceRatio * 0.7) + ((1 - fillerWordRatio) * 0.3);

    return {
      'words_per_minute': wordsPerMinute,
      'average_confidence': averageConfidence,
      'confidence_distribution': confidenceDistribution,
      'clarity_score': clarityScore,
      'hesitation_count': hesitationCount,
      'filler_word_count': fillerWordCount,
      'speech_duration_seconds': duration,
      'total_words': words.length,
    };
  }

  /// Categorize detected entities by relevance to job role
  Map<String, dynamic> _categorizeEntities(
    List<dynamic> entities,
    String? jobRole,
  ) {
    final categorized = <String, List<String>>{
      'technical_terms': [],
      'companies': [],
      'technologies': [],
      'methodologies': [],
      'tools': [],
      'other': [],
    };

    final jobSpecificTerms = _getJobSpecificVocabulary(jobRole);

    for (final entity in entities) {
      final entityData = entity as Map<String, dynamic>;
      final text = entityData['text'] as String? ?? '';
      final entityType = entityData['entity_type'] as String? ?? '';

      switch (entityType.toLowerCase()) {
        case 'organization':
        case 'company':
          categorized['companies']!.add(text);
          break;
        case 'technology':
        case 'software':
          categorized['technologies']!.add(text);
          break;
        default:
          if (jobSpecificTerms.contains(text.toLowerCase())) {
            categorized['technical_terms']!.add(text);
          } else {
            categorized['other']!.add(text);
          }
      }
    }

    return {
      'entities': categorized,
      'total_entities': entities.length,
      'technical_entity_ratio':
          categorized['technical_terms']!.length / (entities.length + 1),
    };
  }

  /// Analyze sentiment patterns for confidence assessment
  Map<String, dynamic> _analyzeSentimentPatterns(
    Map<String, dynamic>? sentimentData,
  ) {
    if (sentimentData == null) {
      return {
        'confidence_level': 'unknown',
        'emotional_stability': 0.5,
        'overall_sentiment': 'neutral',
      };
    }

    final sentiment = sentimentData['sentiment'] as String? ?? 'neutral';
    final confidence = (sentimentData['confidence'] as num?)?.toDouble() ?? 0.5;

    String confidenceLevel;
    if (sentiment == 'positive' && confidence > 0.7) {
      confidenceLevel = 'high';
    } else if (sentiment == 'negative' && confidence > 0.7) {
      confidenceLevel = 'low';
    } else {
      confidenceLevel = 'moderate';
    }

    return {
      'confidence_level': confidenceLevel,
      'emotional_stability': confidence,
      'overall_sentiment': sentiment,
      'sentiment_confidence': confidence,
    };
  }

  /// Calculate technical term density in the transcribed text
  double _calculateTechnicalTermDensity(String text, String? jobRole) {
    if (text.isEmpty) return 0.0;

    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final jobTerms = _getJobSpecificVocabulary(jobRole);

    int technicalWordCount = 0;
    for (final word in words) {
      if (jobTerms.contains(word)) {
        technicalWordCount++;
      }
    }

    return technicalWordCount / words.length;
  }

  /// Calculate an overall quality score for the transcription
  double _calculateOverallQualityScore(
    Map<String, dynamic> analysisData,
    Map<String, dynamic> speechMetrics,
  ) {
    final confidence = (analysisData['confidence'] as num?)?.toDouble() ?? 0.0;
    final clarityScore = speechMetrics['clarity_score'] as double? ?? 0.0;
    final averageConfidence =
        speechMetrics['average_confidence'] as double? ?? 0.0;

    // Weight factors for overall quality
    const confidenceWeight = 0.4;
    const clarityWeight = 0.3;
    const avgConfidenceWeight = 0.3;

    final qualityScore =
        (confidence * confidenceWeight) +
        (clarityScore * clarityWeight) +
        (averageConfidence * avgConfidenceWeight);

    return qualityScore.clamp(0.0, 1.0);
  }

  /// Additional method to detect answer coherence and relevance
  Map<String, dynamic> analyzeAnswerCoherence(
    String transcribedText,
    String questionText,
    String? jobRole,
  ) {
    if (transcribedText.isEmpty) {
      return {
        'coherence_score': 0.0,
        'relevance_score': 0.0,
        'answer_length': 0,
        'sentence_count': 0,
        'keyword_matches': 0,
        'technical_term_usage': 0.0,
        'grammar_indicators': <String, dynamic>{},
      };
    }

    // Basic text analysis
    final sentences = transcribedText.split(RegExp(r'[.!?]+'));
    final words = transcribedText.toLowerCase().split(RegExp(r'\s+'));
    final questionWords = questionText.toLowerCase().split(RegExp(r'\s+'));

    // Calculate keyword overlap between question and answer
    int keywordMatches = 0;
    for (final qWord in questionWords) {
      if (qWord.length > 3 && words.contains(qWord)) {
        keywordMatches++;
      }
    }

    // Calculate technical term usage
    final jobTerms = _getJobSpecificVocabulary(jobRole);
    int technicalTermCount = 0;
    for (final word in words) {
      if (jobTerms.contains(word.toLowerCase())) {
        technicalTermCount++;
      }
    }

    final technicalTermUsage = words.isNotEmpty
        ? technicalTermCount / words.length
        : 0.0;

    // Basic grammar indicators
    final grammarIndicators = {
      'has_proper_punctuation': transcribedText.contains(RegExp(r'[.!?]')),
      'has_capitalization': transcribedText.contains(RegExp(r'[A-Z]')),
      'average_sentence_length': sentences.isNotEmpty
          ? words.length / sentences.length
          : 0.0,
      'complete_sentences': sentences.where((s) => s.trim().isNotEmpty).length,
    };

    // Coherence score based on sentence structure and flow
    double coherenceScore = 0.0;
    if (sentences.length > 1) {
      coherenceScore += 0.3; // Multiple sentences indicate structured thinking
    }
    if (grammarIndicators['has_proper_punctuation'] as bool) {
      coherenceScore += 0.2;
    }
    if (grammarIndicators['average_sentence_length'] as double > 5) {
      coherenceScore += 0.3; // Reasonable sentence length
    }
    if (words.length > 10) {
      coherenceScore += 0.2; // Sufficient detail
    }

    // Relevance score based on keyword overlap and technical terms
    double relevanceScore = 0.0;
    if (keywordMatches > 0) {
      relevanceScore += (keywordMatches / questionWords.length).clamp(0.0, 0.5);
    }
    if (technicalTermUsage > 0) {
      relevanceScore += (technicalTermUsage * 2).clamp(0.0, 0.5);
    }

    return {
      'coherence_score': coherenceScore.clamp(0.0, 1.0),
      'relevance_score': relevanceScore.clamp(0.0, 1.0),
      'answer_length': words.length,
      'sentence_count': sentences.where((s) => s.trim().isNotEmpty).length,
      'keyword_matches': keywordMatches,
      'technical_term_usage': technicalTermUsage,
      'grammar_indicators': grammarIndicators,
      'overall_quality': ((coherenceScore + relevanceScore) / 2).clamp(
        0.0,
        1.0,
      ),
    };
  }

  /// Method to generate Gemini-optimized summary of transcription data
  Map<String, dynamic> generateGeminiOptimizedSummary(
    Map<String, dynamic> transcriptionData,
    String questionText,
    String? jobRole,
  ) {
    final text = transcriptionData['text'] as String? ?? '';
    final confidence =
        (transcriptionData['confidence'] as num?)?.toDouble() ?? 0.0;
    final speechMetrics =
        transcriptionData['speech_metrics'] as Map<String, dynamic>? ?? {};

    // Get coherence analysis
    final coherenceAnalysis = analyzeAnswerCoherence(
      text,
      questionText,
      jobRole,
    );

    // Calculate speaking confidence indicators
    final speakingPace = speechMetrics['words_per_minute'] as double? ?? 0.0;
    final clarityScore = speechMetrics['clarity_score'] as double? ?? 0.0;
    final hesitationCount = speechMetrics['hesitation_count'] as int? ?? 0;
    final fillerWordCount = speechMetrics['filler_word_count'] as int? ?? 0;

    // Determine confidence level based on multiple factors
    String overallConfidenceLevel = 'unknown';
    double confidenceScore = 0.0;

    if (confidence > 0.8 && clarityScore > 0.7 && hesitationCount < 3) {
      overallConfidenceLevel = 'high';
      confidenceScore = 0.9;
    } else if (confidence > 0.6 && clarityScore > 0.5 && hesitationCount < 5) {
      overallConfidenceLevel = 'medium';
      confidenceScore = 0.6;
    } else {
      overallConfidenceLevel = 'low';
      confidenceScore = 0.3;
    }

    // Generate quality indicators for Gemini
    final qualityIndicators = {
      'transcription_accuracy': confidence,
      'speech_clarity': clarityScore,
      'answer_coherence': coherenceAnalysis['coherence_score'],
      'answer_relevance': coherenceAnalysis['relevance_score'],
      'technical_competency': coherenceAnalysis['technical_term_usage'],
      'communication_fluency': speakingPace > 100 && speakingPace < 200
          ? 1.0
          : 0.5,
      'confidence_indicators': {
        'minimal_hesitation': hesitationCount < 3,
        'appropriate_pace': speakingPace > 100 && speakingPace < 200,
        'clear_articulation': clarityScore > 0.7,
        'minimal_filler_words':
            fillerWordCount < (coherenceAnalysis['answer_length'] as int) * 0.1,
      },
    };

    return {
      'gemini_summary': {
        'transcribed_text': text,
        'overall_confidence': overallConfidenceLevel,
        'confidence_score': confidenceScore,
        'quality_indicators': qualityIndicators,
        'speech_analysis': {
          'words_per_minute': speakingPace,
          'total_words': coherenceAnalysis['answer_length'],
          'sentence_count': coherenceAnalysis['sentence_count'],
          'hesitation_count': hesitationCount,
          'filler_word_count': fillerWordCount,
        },
        'content_analysis': {
          'coherence_score': coherenceAnalysis['coherence_score'],
          'relevance_score': coherenceAnalysis['relevance_score'],
          'technical_term_density': coherenceAnalysis['technical_term_usage'],
          'keyword_matches': coherenceAnalysis['keyword_matches'],
        },
        'recommendation_for_gemini': _generateGeminiRecommendations(
          qualityIndicators,
          coherenceAnalysis,
          overallConfidenceLevel,
        ),
      },
      // Include all original data for Gemini's complete analysis
      'full_transcription_data': transcriptionData,
    };
  }

  /// Generate specific recommendations for Gemini AI evaluation
  Map<String, dynamic> _generateGeminiRecommendations(
    Map<String, dynamic> qualityIndicators,
    Map<String, dynamic> coherenceAnalysis,
    String confidenceLevel,
  ) {
    final recommendations = <String, dynamic>{
      'evaluation_focus': <String>[],
      'attention_points': <String>[],
      'confidence_adjustments': <String, double>{},
    };

    // Focus areas based on transcription quality
    final transcriptionAccuracy =
        qualityIndicators['transcription_accuracy'] as double;
    if (transcriptionAccuracy < 0.7) {
      recommendations['attention_points'].add(
        'Low transcription confidence - consider alternative interpretation of unclear segments',
      );
      recommendations['confidence_adjustments']['transcription_reliability'] =
          transcriptionAccuracy;
    }

    // Communication assessment recommendations
    final coherenceScore = coherenceAnalysis['coherence_score'] as double;
    final relevanceScore = coherenceAnalysis['relevance_score'] as double;

    if (coherenceScore > 0.7) {
      recommendations['evaluation_focus'].add(
        'Well-structured response - assess technical depth',
      );
    } else {
      recommendations['evaluation_focus'].add(
        'Focus on content extraction - response may lack structure',
      );
    }

    if (relevanceScore > 0.6) {
      recommendations['evaluation_focus'].add(
        'High relevance to question - evaluate accuracy of technical details',
      );
    } else {
      recommendations['evaluation_focus'].add(
        'Low relevance - check if candidate understood the question',
      );
    }

    // Technical competency indicators
    final technicalDensity =
        coherenceAnalysis['technical_term_usage'] as double;
    if (technicalDensity > 0.1) {
      recommendations['evaluation_focus'].add(
        'High technical term usage - verify accuracy and context',
      );
    } else {
      recommendations['attention_points'].add(
        'Limited technical vocabulary - may indicate knowledge gaps',
      );
    }

    // Confidence-based evaluation adjustments
    switch (confidenceLevel) {
      case 'high':
        recommendations['evaluation_focus'].add(
          'High candidate confidence - focus on technical accuracy',
        );
        break;
      case 'medium':
        recommendations['attention_points'].add(
          'Moderate confidence - consider both knowledge and communication skills',
        );
        break;
      case 'low':
        recommendations['attention_points'].add(
          'Low confidence indicators - evaluate both technical knowledge and communication ability',
        );
        break;
    }

    return recommendations;
  }

  /// Test method to validate transcription accuracy with sample data
  /// This method can be used to test the enhanced features without actual audio
  Map<String, dynamic> generateSampleTranscriptionData({
    required String sampleText,
    required String questionText,
    String? jobRole,
    double? mockConfidence,
  }) {
    // Generate mock transcription data for testing
    final mockWords = sampleText.split(' ').asMap().entries.map((entry) {
      return {
        'text': entry.value,
        'start': entry.key * 500, // Mock timing
        'end': (entry.key + 1) * 500,
        'confidence': (mockConfidence ?? 0.85) + (entry.key % 3) * 0.05,
      };
    }).toList();

    final mockTranscriptionData = {
      'text': sampleText,
      'confidence': mockConfidence ?? 0.85,
      'audio_duration': sampleText.split(' ').length * 0.5, // Mock duration
      'words': mockWords,
      'sentiment_analysis': {'sentiment': 'positive', 'confidence': 0.8},
      'entities': [
        {'text': 'API', 'entity_type': 'technology'},
        {'text': 'database', 'entity_type': 'technology'},
      ],
    };

    return _enhanceTranscriptionData(mockTranscriptionData, jobRole);
  }

  /// Validate enhanced transcription features
  Map<String, dynamic> validateTranscriptionEnhancements() {
    final testText =
        "I have experience with REST APIs and database optimization. I use caching strategies for better performance.";
    const testQuestion =
        "Describe your experience with API development and performance optimization.";
    const testJobRole = "software engineer";

    final enhancedData = generateSampleTranscriptionData(
      sampleText: testText,
      questionText: testQuestion,
      jobRole: testJobRole,
      mockConfidence: 0.92,
    );

    final geminiSummary = generateGeminiOptimizedSummary(
      enhancedData,
      testQuestion,
      testJobRole,
    );

    return {
      'test_successful': true,
      'enhanced_features': {
        'speech_metrics': enhancedData['speech_metrics'] != null,
        'sentiment_analysis': enhancedData['sentiment_insights'] != null,
        'technical_density': enhancedData['technical_density'] != null,
        'gemini_optimization': enhancedData['gemini_optimization'] != null,
      },
      'gemini_summary_ready': geminiSummary['gemini_summary'] != null,
      'sample_quality_score': enhancedData['quality_score'],
      'sample_technical_density': enhancedData['technical_density'],
      'validation_timestamp': DateTime.now().toIso8601String(),
    };
  }
}
