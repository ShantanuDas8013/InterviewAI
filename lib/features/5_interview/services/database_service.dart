import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ai_voice_interview_app/features/5_interview/data/models/interview_question_model.dart';
import 'package:ai_voice_interview_app/features/5_interview/data/models/interview_result_model.dart';
import 'package:ai_voice_interview_app/features/5_interview/data/models/job_role_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user profile by user ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Get user's active resume
  Future<Map<String, dynamic>?> getUserResume(String userId) async {
    try {
      final response = await _supabase
          .from('resumes')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('upload_date', ascending: false)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching user resume: $e');
      return null;
    }
  }

  /// Get all active job roles
  Future<List<Map<String, dynamic>>> getJobRoles({
    bool activeOnly = true,
  }) async {
    try {
      var query = _supabase.from('job_roles').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('title');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching job roles: $e');
      return [];
    }
  }

  // Create a new interview session
  Future<String> createInterviewSession({
    required String userId,
    required String jobRoleId,
    required int questionCount,
    String? resumeId,
    String? sessionName,
    String sessionType = 'practice',
    String difficultyLevel = 'medium',
  }) async {
    try {
      final response = await _supabase
          .from('interview_sessions')
          .insert({
            'user_id': userId,
            'job_role_id': jobRoleId,
            'resume_id': resumeId,
            'session_name': sessionName ?? 'Interview Session',
            'session_type': sessionType,
            'total_questions': questionCount,
            'questions_answered': 0,
            'difficulty_level': difficultyLevel,
            'status': 'in_progress',
            'started_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating interview session: $e');
      rethrow;
    }
  }

  // Fetch questions for a job role
  Future<List<InterviewQuestionModel>> fetchQuestionsForJobRole(
    String jobRoleId, {
    int limit = 5,
    String? difficultyLevel,
    String? questionType,
  }) async {
    try {
      var query = _supabase
          .from('interview_questions')
          .select()
          .eq('job_role_id', jobRoleId)
          .eq('is_active', true);

      // Add difficulty filter if specified
      if (difficultyLevel != null) {
        query = query.eq('difficulty_level', difficultyLevel);
      }

      // Add question type filter if specified
      if (questionType != null) {
        query = query.eq('question_type', questionType);
      }

      final response = await query.limit(limit);

      debugPrint(
        'Found ${(response as List).length} existing questions for job role $jobRoleId',
      );

      return (response as List)
          .map((data) => InterviewQuestionModel.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching questions for job role: $e');
      return [];
    }
  }

  // Count existing questions for a job role
  Future<int> countQuestionsForJobRole(
    String jobRoleId, {
    String? difficultyLevel,
  }) async {
    try {
      var query = _supabase
          .from('interview_questions')
          .select('id')
          .eq('job_role_id', jobRoleId)
          .eq('is_active', true);

      if (difficultyLevel != null) {
        query = query.eq('difficulty_level', difficultyLevel);
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      debugPrint('Error counting questions for job role: $e');
      return 0;
    }
  }

  // Save a generated question to the database
  Future<String> saveQuestion({
    required String jobRoleId,
    required String questionText,
    required String questionType,
    required String difficultyLevel,
    List<String>? expectedAnswerKeywords,
    String? sampleAnswer,
    Map<String, dynamic>? evaluationCriteria,
    int? timeLimitSeconds,
  }) async {
    try {
      final response = await _supabase
          .from('interview_questions')
          .insert({
            'job_role_id': jobRoleId,
            'question_text': questionText,
            'question_type': questionType,
            'difficulty_level': difficultyLevel,
            'expected_answer_keywords': expectedAnswerKeywords,
            'sample_answer': sampleAnswer,
            'evaluation_criteria': evaluationCriteria,
            'time_limit_seconds': timeLimitSeconds ?? 120,
            'is_active': true,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error saving question: $e');
      rethrow;
    }
  }

  // Save a user's response to a question
  Future<void> saveResponse({
    required String sessionId,
    required String questionId,
    required String userId,
    required int questionOrder,
    required String userResponse,
    required double score,
    String? audioUrl,
    int? responseDurationSeconds,
    double? technicalAccuracy,
    double? communicationClarity,
    double? relevanceScore,
    String? aiFeedback,
    List<String>? keywordsMentioned,
    List<String>? missingKeywords,
    String? suggestedImprovement,
    String? idealAnswerComparison,
    double? speechPace,
    int? fillerWordsCount,
    double? confidenceLevel,
    Map<String, dynamic>? geminiAnalysisRaw,
  }) async {
    try {
      await _supabase.from('interview_responses').insert({
        'interview_session_id': sessionId,
        'question_id': questionId,
        'user_id': userId,
        'question_order': questionOrder,
        'transcribed_text': userResponse,
        'response_score': score,
        'audio_file_path': audioUrl,
        'response_duration_seconds': responseDurationSeconds,
        'technical_accuracy': technicalAccuracy,
        'communication_clarity': communicationClarity,
        'relevance_score': relevanceScore,
        'ai_feedback': aiFeedback,
        'keywords_mentioned': keywordsMentioned,
        'missing_keywords': missingKeywords,
        'suggested_improvement': suggestedImprovement,
        'ideal_answer_comparison': idealAnswerComparison,
        'speech_pace': speechPace,
        'filler_words_count': fillerWordsCount ?? 0,
        'confidence_level': confidenceLevel,
        'gemini_analysis_raw': geminiAnalysisRaw,
        'answered_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving response: $e');
      rethrow;
    }
  }

  // Save the final interview result
  Future<String> saveInterviewResult({
    required String sessionId,
    required InterviewResultModel result,
  }) async {
    try {
      // First update the session status
      await _supabase
          .from('interview_sessions')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      // Then save the result
      final response = await _supabase
          .from('interview_results')
          .insert({
            'interview_session_id': sessionId,
            'user_id': result.userId,
            'job_role_id': result.jobRoleId,
            'job_role_title': result.jobRoleTitle,
            'overall_score': result.overallScore,
            'technical_score': result.technicalScore,
            'communication_score': result.communicationScore,
            'problem_solving_score': result.problemSolvingScore,
            'confidence_score': result.confidenceScore,
            'ai_summary': result.aiSummary,
            'strengths_analysis': result.strengthsAnalysis,
            'areas_for_improvement': result.areasForImprovement,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error saving interview result: $e');
      rethrow;
    }
  }

  // Update session status (e.g., when ending early)
  Future<void> updateSessionStatus(String sessionId, String status) async {
    try {
      await _supabase
          .from('interview_sessions')
          .update({
            'status': status,
            if (status == 'completed')
              'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    } catch (e) {
      debugPrint('Error updating session status: $e');
      rethrow;
    }
  }

  // Fetch job role details
  Future<JobRoleModel?> fetchJobRole(String jobRoleId) async {
    try {
      final response = await _supabase
          .from('job_roles')
          .select()
          .eq('id', jobRoleId)
          .single();

      return JobRoleModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching job role: $e');
      return null;
    }
  }

  // Log Gemini API usage
  Future<void> logGeminiApiUsage({
    required String userId,
    required String requestType,
    required Map<String, dynamic> requestPayload,
    required Map<String, dynamic> responsePayload,
    required String status,
    String? errorMessage,
    int? tokensUsed,
    int? processingTimeMs,
  }) async {
    try {
      await _supabase.from('gemini_api_logs').insert({
        'user_id': userId,
        'api_endpoint': 'gemini-pro',
        'request_type': requestType,
        'request_payload': requestPayload,
        'response_payload': responsePayload,
        'tokens_used': tokensUsed,
        'processing_time_ms': processingTimeMs,
        'status': status,
        'error_message': errorMessage,
      });
    } catch (e) {
      // Just log the error but don't throw, as this is not critical
      debugPrint('Error logging Gemini API usage: $e');
    }
  }

  // Get interview sessions for a user
  Future<List<Map<String, dynamic>>> getUserInterviewSessions({
    required String userId,
    int? limit,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('interview_sessions')
          .select('*, job_roles!inner(title, category)')
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final orderedQuery = query.order('created_at', ascending: false);

      final finalQuery = limit != null
          ? orderedQuery.limit(limit)
          : orderedQuery;

      final response = await finalQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user interview sessions: $e');
      return [];
    }
  }

  // Get interview results for a user
  Future<List<Map<String, dynamic>>> getUserInterviewResults({
    required String userId,
    int? limit,
  }) async {
    try {
      var query = _supabase
          .from('interview_results')
          .select('*, interview_sessions!inner(session_name, completed_at)')
          .eq('user_id', userId);

      final orderedQuery = query.order('created_at', ascending: false);

      final finalQuery = limit != null
          ? orderedQuery.limit(limit)
          : orderedQuery;

      final response = await finalQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user interview results: $e');
      return [];
    }
  }

  // Get interview responses for a session
  Future<List<Map<String, dynamic>>> getInterviewResponses(
    String sessionId,
  ) async {
    try {
      final response = await _supabase
          .from('interview_responses')
          .select('*, interview_questions!inner(question_text, question_type)')
          .eq('interview_session_id', sessionId)
          .order('question_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching interview responses: $e');
      return [];
    }
  }

  // Update session with final scores
  Future<void> updateSessionScores({
    required String sessionId,
    required double overallScore,
    required double technicalScore,
    required double communicationScore,
    required double problemSolvingScore,
    required double confidenceScore,
    String? aiFeedback,
    List<String>? strengths,
    List<String>? areasForImprovement,
    List<String>? recommendations,
  }) async {
    try {
      await _supabase
          .from('interview_sessions')
          .update({
            'overall_score': overallScore,
            'technical_score': technicalScore,
            'communication_score': communicationScore,
            'problem_solving_score': problemSolvingScore,
            'confidence_score': confidenceScore,
            'ai_feedback': aiFeedback,
            'strengths': strengths,
            'areas_for_improvement': areasForImprovement,
            'recommendations': recommendations,
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    } catch (e) {
      debugPrint('Error updating session scores: $e');
      rethrow;
    }
  }

  // Update questions answered count
  Future<void> updateQuestionsAnswered(String sessionId, int count) async {
    try {
      await _supabase
          .from('interview_sessions')
          .update({'questions_answered': count})
          .eq('id', sessionId);
    } catch (e) {
      debugPrint('Error updating questions answered: $e');
      rethrow;
    }
  }
}
