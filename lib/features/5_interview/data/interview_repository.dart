import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InterviewRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all available job roles
  Future<List<Map<String, dynamic>>> getJobRoles() async {
    try {
      final response = await _supabase
          .from('job_roles')
          .select()
          .eq('is_active', true)
          .order('title');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching job roles: $e');
      rethrow;
    }
  }

  /// Create a new interview session
  Future<Map<String, dynamic>> createInterviewSession({
    required String userId,
    required String jobRoleId,
    String? resumeId,
    String? sessionName,
    int totalQuestions = 5,
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
            'status': 'scheduled',
            'total_questions': totalQuestions,
            'difficulty_level': difficultyLevel,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Error creating interview session: $e');
      rethrow;
    }
  }

  /// Get interview questions for a job role
  Future<List<Map<String, dynamic>>> getInterviewQuestions({
    required String jobRoleId,
    required String difficultyLevel,
    required int limit,
  }) async {
    try {
      final response = await _supabase
          .from('interview_questions')
          .select()
          .eq('job_role_id', jobRoleId)
          .eq('is_active', true)
          .eq('difficulty_level', difficultyLevel)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching interview questions: $e');
      rethrow;
    }
  }

  /// Save a single interview answer to the database
  Future<void> saveAnswer({
    required String sessionId,
    required String questionId,
    required String answerText,
  }) async {
    try {
      await _supabase.from('interview_answers').insert({
        'session_id': sessionId,
        'question_id': questionId,
        'answer_text': answerText,
      });
    } catch (e) {
      debugPrint('Error saving answer: $e');
      rethrow;
    }
  }

  /// Get the full transcript of an interview session
  Future<List<Map<String, dynamic>>> getInterviewTranscript(
    String sessionId,
  ) async {
    try {
      final response = await _supabase
          .from('interview_answers')
          .select('*, question:interview_questions(question_text)')
          .eq('session_id', sessionId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching interview transcript: $e');
      rethrow;
    }
  }
}
