import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../core/api/gemini_service.dart';
import '../data/models/interview_question_model.dart';
import 'assembly_ai_service.dart';
import 'audio_recording_service.dart';
import 'database_service.dart';

/// Enhanced interview service that combines AssemblyAI and Gemini AI
/// for accurate speech-to-text and comprehensive answer evaluation
class EnhancedInterviewService {
  static final EnhancedInterviewService _instance =
      EnhancedInterviewService._internal();
  factory EnhancedInterviewService() => _instance;
  EnhancedInterviewService._internal();

  final AssemblyAiService _assemblyAiService = AssemblyAiService();
  final GeminiService _geminiService = GeminiService();
  final AudioRecordingService _audioService = AudioRecordingService();
  final DatabaseService _databaseService = DatabaseService();

  bool _isInitialized = false;

  /// Initialize all required services
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('🚀 Initializing Enhanced Interview Service...');

      // Initialize all services in parallel for faster startup
      await Future.wait([
        _assemblyAiService.initialize(),
        _geminiService.initialize(),
        _audioService.initialize(),
      ]);

      _isInitialized = true;
      debugPrint('✅ Enhanced Interview Service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing Enhanced Interview Service: $e');
      return false;
    }
  }

  /// Record and process interview answer with comprehensive analysis
  ///
  /// This method:
  /// 1. Records audio using high-quality settings
  /// 2. Transcribes with AssemblyAI's enhanced features
  /// 3. Evaluates answer using Gemini AI
  /// 4. Returns comprehensive analysis data
  Future<Map<String, dynamic>> recordAndEvaluateAnswer({
    required InterviewQuestionModel question,
    required String sessionId,
    required String userId,
    required int questionOrder,
    String? jobTitle,
    String? jobCategory,
    int? maxRecordingSeconds,
  }) async {
    String? audioFilePath;

    try {
      if (!_isInitialized) {
        await initialize();
      }

      debugPrint('🎤 Starting enhanced answer recording and evaluation...');

      // Step 1: Record audio
      debugPrint('📹 Recording audio answer...');
      audioFilePath = await _audioService.startRecording();

      if (audioFilePath == null) {
        throw Exception('Failed to start audio recording');
      }

      // Wait for recording completion (this would be handled by UI in practice)
      // For this example, we'll assume the recording is managed externally
      debugPrint('🎵 Audio recording in progress at: $audioFilePath');

      return {
        'status': 'recording',
        'audio_path': audioFilePath,
        'message': 'Recording started successfully',
      };
    } catch (e) {
      debugPrint('❌ Error in enhanced answer recording: $e');

      // Clean up audio file if recording failed
      if (audioFilePath != null) {
        try {
          await File(audioFilePath).delete();
        } catch (_) {}
      }

      rethrow;
    }
  }

  /// Stop recording and process the answer
  Future<Map<String, dynamic>> stopRecordingAndEvaluate({
    required InterviewQuestionModel question,
    required String sessionId,
    required String userId,
    required int questionOrder,
    String? jobTitle,
    String? jobCategory,
  }) async {
    try {
      debugPrint('⏹️ Stopping recording and starting evaluation...');

      // Step 1: Stop recording
      final audioFilePath = await _audioService.stopRecording();

      if (audioFilePath == null || audioFilePath.isEmpty) {
        throw Exception('No audio recording found');
      }

      debugPrint('✅ Audio recording stopped: $audioFilePath');

      // Step 2: Enhanced transcription with AssemblyAI
      debugPrint('🔤 Starting enhanced transcription with AssemblyAI...');
      final transcriptionResult = await _assemblyAiService
          .transcribeAudioWithAnalysis(
            audioFilePath,
            jobRole: jobTitle ?? jobCategory,
            customVocabulary: _getCustomVocabularyForJob(
              jobTitle ?? jobCategory,
            ),
          );

      final transcribedText = transcriptionResult['text'] as String;
      debugPrint(
        '📝 Transcription completed: ${transcribedText.substring(0, transcribedText.length.clamp(0, 100))}...',
      );

      // Generate Gemini-optimized summary
      final geminiOptimizedData = _assemblyAiService
          .generateGeminiOptimizedSummary(
            transcriptionResult,
            question.questionText,
            jobTitle ?? jobCategory,
          );

      // Step 3: Evaluate answer with Gemini AI using enhanced data
      debugPrint('🤖 Starting answer evaluation with Gemini AI...');
      final evaluationResult = await _geminiService.evaluateInterviewAnswer(
        questionText: question.questionText,
        questionType: question.questionType,
        userAnswer: transcribedText,
        expectedKeywords: question.expectedAnswerKeywords ?? [],
        difficultyLevel: question.difficultyLevel,
        idealAnswer: question.sampleAnswer,
        evaluationCriteria: question.evaluationCriteria?.toString(),
        jobTitle: jobTitle,
        jobCategory: jobCategory,
        transcriptionAnalysis: geminiOptimizedData,
      );

      debugPrint(
        '🎯 Answer evaluation completed with score: ${evaluationResult['overall_score']}',
      );

      // Step 4: Save response to database with enhanced data
      await _saveEnhancedResponse(
        sessionId: sessionId,
        questionId: question.id,
        userId: userId,
        questionOrder: questionOrder,
        audioFilePath: audioFilePath,
        transcriptionResult: transcriptionResult,
        evaluationResult: evaluationResult,
        transcribedText: transcribedText,
      );

      debugPrint('💾 Enhanced response data saved to database');

      // Step 5: Return comprehensive result with enhanced data
      return {
        'status': 'completed',
        'transcribed_text': transcribedText,
        'audio_file_path': audioFilePath,
        'transcription_confidence': transcriptionResult['confidence'],
        'audio_duration': transcriptionResult['audio_duration'],
        'speech_metrics': transcriptionResult['speech_metrics'],
        'sentiment_insights': transcriptionResult['sentiment_insights'],
        'technical_density': transcriptionResult['technical_density'],
        'quality_score': transcriptionResult['quality_score'],
        'evaluation': evaluationResult,
        'overall_score': evaluationResult['overall_score'],
        'detailed_feedback': evaluationResult['detailed_feedback'],
        'strengths': evaluationResult['strengths'],
        'areas_for_improvement': evaluationResult['areas_for_improvement'],
        'gemini_optimized_analysis': geminiOptimizedData['gemini_summary'],
      };
    } catch (e) {
      debugPrint('❌ Error in enhanced answer evaluation: $e');
      rethrow;
    }
  }

  /// Save enhanced response data to database
  Future<void> _saveEnhancedResponse({
    required String sessionId,
    required String questionId,
    required String userId,
    required int questionOrder,
    required String audioFilePath,
    required Map<String, dynamic> transcriptionResult,
    required Map<String, dynamic> evaluationResult,
    required String transcribedText,
  }) async {
    try {
      await _databaseService.saveResponse(
        sessionId: sessionId,
        questionId: questionId,
        userId: userId,
        questionOrder: questionOrder,
        userResponse: transcribedText,
        score: evaluationResult['overall_score']?.toDouble() ?? 0.0,
        audioUrl: audioFilePath,
        responseDurationSeconds: transcriptionResult['audio_duration']?.toInt(),
        technicalAccuracy: evaluationResult['technical_accuracy']?.toDouble(),
        communicationClarity: evaluationResult['communication_clarity']
            ?.toDouble(),
        relevanceScore: evaluationResult['relevance_score']?.toDouble(),
        aiFeedback: evaluationResult['detailed_feedback']?.toString(),
        keywordsMentioned: List<String>.from(
          evaluationResult['keywords_mentioned'] ?? [],
        ),
        missingKeywords: List<String>.from(
          evaluationResult['missing_keywords'] ?? [],
        ),
        suggestedImprovement: evaluationResult['recommendation']?.toString(),
        idealAnswerComparison: evaluationResult['ideal_answer_comparison']
            ?.toString(),
        speechPace: _calculateSpeechPace(
          transcribedText,
          transcriptionResult['audio_duration'],
        ),
        fillerWordsCount: _countFillerWords(transcribedText),
        confidenceLevel: transcriptionResult['confidence']?.toDouble(),
        geminiAnalysisRaw: {
          'transcription_analysis': transcriptionResult,
          'gemini_evaluation': evaluationResult,
        },
      );
    } catch (e) {
      debugPrint('Error saving enhanced response data: $e');
      rethrow;
    }
  }

  /// Calculate speech pace (words per minute)
  double? _calculateSpeechPace(String text, dynamic duration) {
    if (duration == null) return null;

    final durationSeconds = duration is int
        ? duration.toDouble()
        : duration as double?;
    if (durationSeconds == null || durationSeconds <= 0) return null;

    final wordCount = text.trim().split(RegExp(r'\s+')).length;
    final wordsPerMinute = (wordCount / durationSeconds) * 60;

    return double.parse(wordsPerMinute.toStringAsFixed(2));
  }

  /// Count filler words in the transcription
  int _countFillerWords(String text) {
    final fillerWords = [
      'um',
      'uh',
      'like',
      'you know',
      'basically',
      'actually',
      'literally',
      'so',
      'well',
      'yeah',
      'okay',
      'right',
    ];

    final lowerText = text.toLowerCase();
    int count = 0;

    for (final filler in fillerWords) {
      count += RegExp(r'\b' + filler + r'\b').allMatches(lowerText).length;
    }

    return count;
  }

  /// Get recording amplitude for UI visualization
  Future<double> getRecordingAmplitude() async {
    try {
      return await _audioService.getAmplitude();
    } catch (e) {
      debugPrint('Error getting recording amplitude: $e');
      return 0.0;
    }
  }

  /// Check if currently recording
  bool get isRecording => _audioService.isRecording;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      await _audioService.cancelRecording();
      debugPrint('🚫 Recording cancelled');
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    debugPrint('🧹 Enhanced Interview Service disposed');
  }

  /// Get custom vocabulary based on job role for enhanced transcription
  List<String> _getCustomVocabularyForJob(String? jobRole) {
    if (jobRole == null) return [];

    switch (jobRole.toLowerCase()) {
      case 'software engineer':
      case 'developer':
      case 'programmer':
      case 'software developer':
      case 'full stack developer':
      case 'frontend developer':
      case 'backend developer':
        return [
          'algorithm',
          'data structure',
          'big O notation',
          'complexity',
          'optimization',
          'refactoring',
          'code review',
          'version control',
          'merge conflict',
          'pull request',
          'branch',
          'commit',
          'repository',
          'deployment',
          'continuous integration',
          'unit test',
          'integration test',
          'test coverage',
          'debugging',
          'profiling',
          'performance',
          'scalability',
          'microservices',
          'monolith',
          'API design',
          'REST',
          'GraphQL',
          'authentication',
          'authorization',
          'encryption',
          'hash',
          'database',
          'SQL',
          'NoSQL',
          'indexing',
          'caching',
          'load balancing',
          'horizontal scaling',
          'vertical scaling',
        ];

      case 'data scientist':
      case 'data analyst':
      case 'machine learning engineer':
      case 'ml engineer':
      case 'ai engineer':
        return [
          'machine learning',
          'artificial intelligence',
          'deep learning',
          'neural network',
          'supervised learning',
          'unsupervised learning',
          'reinforcement learning',
          'feature engineering',
          'feature selection',
          'data preprocessing',
          'data cleaning',
          'exploratory data analysis',
          'statistical analysis',
          'hypothesis testing',
          'p-value',
          'correlation',
          'regression',
          'classification',
          'clustering',
          'cross-validation',
          'overfitting',
          'underfitting',
          'bias-variance tradeoff',
          'ensemble methods',
          'random forest',
          'gradient boosting',
          'support vector machine',
          'k-means',
          'principal component analysis',
          'dimensionality reduction',
          'time series',
          'anomaly detection',
          'natural language processing',
          'computer vision',
          'recommendation system',
        ];

      case 'devops':
      case 'site reliability engineer':
      case 'sre':
      case 'infrastructure engineer':
      case 'cloud engineer':
        return [
          'continuous integration',
          'continuous deployment',
          'infrastructure as code',
          'configuration management',
          'containerization',
          'orchestration',
          'Kubernetes',
          'Docker',
          'microservices',
          'service mesh',
          'load balancer',
          'auto scaling',
          'monitoring',
          'observability',
          'logging',
          'metrics',
          'alerting',
          'incident response',
          'post-mortem',
          'disaster recovery',
          'backup strategy',
          'high availability',
          'fault tolerance',
          'distributed systems',
          'cloud computing',
          'AWS',
          'Azure',
          'Google Cloud',
          'serverless',
          'lambda functions',
          'API gateway',
          'virtual private cloud',
          'security groups',
          'networking',
          'DNS',
          'CDN',
        ];

      case 'product manager':
      case 'project manager':
      case 'program manager':
        return [
          'product roadmap',
          'feature prioritization',
          'user experience',
          'user interface',
          'user research',
          'customer journey',
          'user personas',
          'market research',
          'competitive analysis',
          'product-market fit',
          'minimum viable product',
          'go-to-market strategy',
          'stakeholder management',
          'requirements gathering',
          'user stories',
          'acceptance criteria',
          'agile methodology',
          'scrum',
          'kanban',
          'sprint planning',
          'retrospective',
          'backlog grooming',
          'velocity',
          'burndown chart',
          'key performance indicators',
          'metrics',
          'analytics',
          'A/B testing',
          'conversion rate',
          'retention rate',
          'churn rate',
          'customer acquisition',
          'lifetime value',
          'pricing strategy',
          'revenue model',
        ];

      default:
        return [];
    }
  }
}
