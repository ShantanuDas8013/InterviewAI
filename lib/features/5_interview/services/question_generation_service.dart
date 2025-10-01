import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/gemini_service.dart';
import '../data/models/job_role_model.dart';
import '../data/models/interview_question_model.dart';
import 'database_service.dart';

/// Service to handle dynamic interview question generation using Gemini AI
class QuestionGenerationService {
  static final QuestionGenerationService _instance =
      QuestionGenerationService._internal();
  factory QuestionGenerationService() => _instance;
  QuestionGenerationService._internal();

  final GeminiService _geminiService = GeminiService();
  final DatabaseService _databaseService = DatabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  /// Generate and cache interview questions for a specific job role
  Future<List<InterviewQuestionModel>> generateQuestionsForRole({
    required JobRoleModel jobRole,
    required String difficultyLevel,
    required int questionCount,
    String? experienceLevel,
    bool useCache = true,
  }) async {
    try {
      // Step 1: Check if we have existing questions in the database
      debugPrint(
        '🔍 Checking for existing questions for ${jobRole.title} ($difficultyLevel level)',
      );

      final existingQuestions = await _databaseService.fetchQuestionsForJobRole(
        jobRole.id,
        difficultyLevel: difficultyLevel,
        limit: questionCount,
      );

      if (existingQuestions.length >= questionCount) {
        debugPrint(
          '🎯 SUCCESS: Found ${existingQuestions.length} existing questions in database for ${jobRole.title}',
        );
        debugPrint(
          '📋 Using EXISTING questions from database - NO AI generation needed',
        );
        return existingQuestions.take(questionCount).toList();
      }

      // Step 2: If we don't have enough questions, check for any difficulty level
      if (existingQuestions.length < questionCount) {
        debugPrint(
          '📊 Found ${existingQuestions.length} questions for specific difficulty, checking for any difficulty level',
        );

        final allQuestionsForRole = await _databaseService
            .fetchQuestionsForJobRole(jobRole.id, limit: questionCount);

        if (allQuestionsForRole.length >= questionCount) {
          debugPrint(
            '🎯 SUCCESS: Found ${allQuestionsForRole.length} questions (mixed difficulty) for ${jobRole.title}',
          );
          debugPrint(
            '📋 Using EXISTING questions from database - NO AI generation needed',
          );
          return allQuestionsForRole.take(questionCount).toList();
        }

        // Step 3: If we have some questions but not enough, supplement with AI
        if (allQuestionsForRole.isNotEmpty) {
          final remainingCount = questionCount - allQuestionsForRole.length;
          debugPrint(
            '🤖 HYBRID: Found ${allQuestionsForRole.length} existing questions, generating $remainingCount more with AI',
          );
          debugPrint(
            '📋 Using COMBINATION of existing questions + AI-generated questions',
          );

          try {
            final aiQuestions = await _generateQuestionsWithAI(
              jobRole,
              difficultyLevel,
              remainingCount,
              experienceLevel,
            );

            // Combine existing and new questions
            final combinedQuestions = [...allQuestionsForRole, ...aiQuestions];
            return combinedQuestions.take(questionCount).toList();
          } catch (aiError) {
            debugPrint(
              '⚠️ AI generation failed, using ${allQuestionsForRole.length} existing questions: $aiError',
            );
            return allQuestionsForRole;
          }
        }
      }

      // Step 4: No existing questions found, generate all with AI
      debugPrint(
        '🤖 AI GENERATION: No existing questions found, generating all $questionCount questions with AI for ${jobRole.title}',
      );
      debugPrint(
        '📋 Using ONLY AI-generated questions - no existing questions in database',
      );
      return await _generateQuestionsWithAI(
        jobRole,
        difficultyLevel,
        questionCount,
        experienceLevel,
      );
    } catch (e) {
      debugPrint('❌ Error in question generation process: $e');

      // Fallback: Try to get any existing questions
      try {
        final fallbackQuestions = await _databaseService
            .fetchQuestionsForJobRole(jobRole.id, limit: questionCount);

        if (fallbackQuestions.isNotEmpty) {
          debugPrint(
            '🔄 Using ${fallbackQuestions.length} fallback questions from database',
          );
          return fallbackQuestions;
        }
      } catch (fallbackError) {
        debugPrint('❌ Fallback also failed: $fallbackError');
      }

      rethrow;
    }
  }

  /// Generate questions using AI and save them to database
  Future<List<InterviewQuestionModel>> _generateQuestionsWithAI(
    JobRoleModel jobRole,
    String difficultyLevel,
    int questionCount,
    String? experienceLevel,
  ) async {
    try {
      // Generate new questions using Gemini
      final generatedQuestions = await _geminiService
          .generateInterviewQuestions(
            jobTitle: jobRole.title,
            jobCategory: jobRole.category,
            requiredSkills: jobRole.requiredSkills,
            difficultyLevel: difficultyLevel,
            questionCount: questionCount,
            jobDescription: jobRole.description,
            industry: jobRole.industry,
            experienceLevel: experienceLevel,
          );

      // Convert to InterviewQuestionModel and save to database
      final questionModels = <InterviewQuestionModel>[];

      for (int i = 0; i < generatedQuestions.length; i++) {
        final questionData = generatedQuestions[i];
        final questionModel = InterviewQuestionModel(
          id: _uuid.v4(),
          jobRoleId: jobRole.id,
          questionText: questionData['questionText'],
          questionType: questionData['questionType'],
          difficultyLevel: questionData['difficultyLevel'],
          expectedAnswerKeywords: List<String>.from(
            questionData['expectedAnswerKeywords'] ?? [],
          ),
          evaluationCriteria: questionData['evaluationCriteria'],
          timeLimitSeconds: questionData['timeLimitSeconds'] ?? 120,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        questionModels.add(questionModel);

        // Save to database for caching
        await _saveQuestionToDatabase(questionModel);
      }

      // Log the generation to Gemini API logs
      await _logQuestionGeneration(
        jobRole: jobRole,
        difficultyLevel: difficultyLevel,
        questionCount: questionCount,
        generatedQuestions: generatedQuestions,
      );

      debugPrint(
        'Generated and cached ${questionModels.length} questions for ${jobRole.title}',
      );
      return questionModels;
    } catch (e) {
      debugPrint('Error generating questions for ${jobRole.title}: $e');

      // Fallback to cached questions if generation fails
      final cachedQuestions = await _getCachedQuestions(
        jobRoleId: jobRole.id,
        difficultyLevel: difficultyLevel,
        limit: questionCount,
      );

      if (cachedQuestions.isNotEmpty) {
        debugPrint(
          'Falling back to ${cachedQuestions.length} cached questions',
        );
        return cachedQuestions;
      }

      // If no cached questions available, generate fallback questions
      return _generateFallbackQuestions(
        jobRole,
        difficultyLevel,
        questionCount,
      );
    }
  }

  /// Get cached questions from database
  Future<List<InterviewQuestionModel>> _getCachedQuestions({
    required String jobRoleId,
    required String difficultyLevel,
    required int limit,
  }) async {
    try {
      final response = await _supabase
          .from('interview_questions')
          .select()
          .eq('job_role_id', jobRoleId)
          .eq('difficulty_level', difficultyLevel)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit * 2); // Get more than needed for variety

      final questions = response
          .map((json) => InterviewQuestionModel.fromJson(json))
          .toList();

      // Shuffle for variety
      questions.shuffle();

      return questions;
    } catch (e) {
      debugPrint('Error fetching cached questions: $e');
      return [];
    }
  }

  /// Save question to database
  Future<void> _saveQuestionToDatabase(InterviewQuestionModel question) async {
    try {
      await _supabase.from('interview_questions').insert(question.toJson());
    } catch (e) {
      debugPrint('Error saving question to database: $e');
      // Don't throw here to avoid interrupting the question generation process
    }
  }

  /// Log question generation to Gemini API logs
  Future<void> _logQuestionGeneration({
    required JobRoleModel jobRole,
    required String difficultyLevel,
    required int questionCount,
    required List<Map<String, dynamic>> generatedQuestions,
  }) async {
    try {
      final user = _supabase.auth.currentUser;

      await _supabase.from('gemini_api_logs').insert({
        'user_id': user?.id,
        'api_endpoint': 'generateContent',
        'request_type': 'interview_question_generation',
        'request_payload': {
          'job_role_id': jobRole.id,
          'job_title': jobRole.title,
          'difficulty_level': difficultyLevel,
          'question_count': questionCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'response_payload': {
          'questions_generated': generatedQuestions.length,
          'questions': generatedQuestions,
        },
        'tokens_used': _estimateTokensUsed(generatedQuestions),
        'status': 'success',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging question generation: $e');
    }
  }

  /// Estimate tokens used for logging
  int _estimateTokensUsed(List<Map<String, dynamic>> questions) {
    // Rough estimation: ~4 characters per token
    int totalChars = 0;
    for (final question in questions) {
      totalChars += question.toString().length;
    }
    return (totalChars / 4).round();
  }

  /// Generate fallback questions if AI generation fails
  List<InterviewQuestionModel> _generateFallbackQuestions(
    JobRoleModel jobRole,
    String difficultyLevel,
    int questionCount,
  ) {
    final fallbackQuestions = _getFallbackQuestionsByCategory(
      jobRole.category,
      difficultyLevel,
    );

    final questions = <InterviewQuestionModel>[];
    for (int i = 0; i < questionCount && i < fallbackQuestions.length; i++) {
      final fallback = fallbackQuestions[i];
      questions.add(
        InterviewQuestionModel(
          id: _uuid.v4(),
          jobRoleId: jobRole.id,
          questionText: fallback['question'],
          questionType: fallback['type'],
          difficultyLevel: difficultyLevel,
          expectedAnswerKeywords: List<String>.from(fallback['keywords']),
          timeLimitSeconds: 120,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    return questions;
  }

  /// Get fallback questions by job category
  List<Map<String, dynamic>> _getFallbackQuestionsByCategory(
    String category,
    String difficulty,
  ) {
    final Map<String, List<Map<String, dynamic>>> fallbackQuestions = {
      'Technology': [
        {
          'question':
              'Tell me about a challenging technical problem you solved recently.',
          'type': 'technical',
          'keywords': ['problem-solving', 'technical', 'solution', 'debugging'],
        },
        {
          'question':
              'How do you stay updated with the latest technology trends?',
          'type': 'general',
          'keywords': [
            'learning',
            'technology',
            'trends',
            'professional development',
          ],
        },
        {
          'question':
              'Describe a time when you had to work with a difficult team member.',
          'type': 'behavioral',
          'keywords': ['teamwork', 'communication', 'conflict resolution'],
        },
      ],
      'Marketing': [
        {
          'question': 'How do you measure the success of a marketing campaign?',
          'type': 'technical',
          'keywords': ['metrics', 'ROI', 'analytics', 'KPIs'],
        },
        {
          'question':
              'Tell me about a time when a campaign didn\'t perform as expected.',
          'type': 'behavioral',
          'keywords': ['problem-solving', 'adaptation', 'analysis'],
        },
      ],
      'Sales': [
        {
          'question': 'How do you handle rejection from potential clients?',
          'type': 'behavioral',
          'keywords': ['resilience', 'persistence', 'customer relations'],
        },
        {
          'question':
              'What\'s your approach to building relationships with new clients?',
          'type': 'situational',
          'keywords': ['relationship building', 'communication', 'trust'],
        },
      ],
    };

    return fallbackQuestions[category] ?? fallbackQuestions['Technology']!;
  }

  /// Clear cached questions for a job role (useful for refreshing)
  Future<void> clearCachedQuestions(String jobRoleId) async {
    try {
      await _supabase
          .from('interview_questions')
          .update({'is_active': false})
          .eq('job_role_id', jobRoleId);

      debugPrint('Cleared cached questions for job role: $jobRoleId');
    } catch (e) {
      debugPrint('Error clearing cached questions: $e');
    }
  }

  /// Get question statistics for a job role
  Future<Map<String, dynamic>> getQuestionStats(String jobRoleId) async {
    try {
      final response = await _supabase
          .from('interview_questions')
          .select('difficulty_level, question_type')
          .eq('job_role_id', jobRoleId)
          .eq('is_active', true);

      final stats = <String, dynamic>{
        'total': response.length,
        'by_difficulty': <String, int>{},
        'by_type': <String, int>{},
      };

      for (final question in response) {
        final difficulty = question['difficulty_level'] ?? 'medium';
        final type = question['question_type'] ?? 'general';

        stats['by_difficulty'][difficulty] =
            (stats['by_difficulty'][difficulty] ?? 0) + 1;
        stats['by_type'][type] = (stats['by_type'][type] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting question stats: $e');
      return {'total': 0, 'by_difficulty': {}, 'by_type': {}};
    }
  }
}
