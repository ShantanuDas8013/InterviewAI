import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new user profile entry in the profiles table
  Future<Map<String, dynamic>?> createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    String? phoneNumber,
    String? location,
    String experienceLevel = 'entry',
    String subscriptionType = 'free',
  }) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .insert({
            'id': userId,
            'email': email,
            'full_name': fullName,
            'phone_number': phoneNumber,
            'location': location,
            'experience_level': experienceLevel,
            'subscription_type': subscriptionType,
          })
          .select()
          .single();

      debugPrint('User profile created successfully for user: $userId');
      return response;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

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

  /// Update user profile
  Future<Map<String, dynamic>?> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? location,
    String? bio,
    String? experienceLevel,
    String? currentCompany,
    String? currentPosition,
    String? linkedinUrl,
    String? githubUrl,
    String? portfolioUrl,
    String? profilePictureUrl,
    List<String>? preferredJobRoles,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (location != null) updateData['location'] = location;
      if (bio != null) updateData['bio'] = bio;
      if (experienceLevel != null)
        updateData['experience_level'] = experienceLevel;
      if (currentCompany != null)
        updateData['current_company'] = currentCompany;
      if (currentPosition != null)
        updateData['current_position'] = currentPosition;
      if (linkedinUrl != null) updateData['linkedin_url'] = linkedinUrl;
      if (githubUrl != null) updateData['github_url'] = githubUrl;
      if (portfolioUrl != null) updateData['portfolio_url'] = portfolioUrl;
      if (profilePictureUrl != null)
        updateData['profile_picture_url'] = profilePictureUrl;
      // Note: preferredJobRoles would need ARRAY type support in the table

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final response = await _supabase
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      debugPrint('User profile updated successfully for user: $userId');
      return response;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Update user interview statistics
  Future<void> updateUserInterviewStats({
    required String userId,
    required int totalInterviews,
    required double averageScore,
  }) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({
            'total_interviews_taken': totalInterviews,
            'average_interview_score': averageScore,
          })
          .eq('id', userId);

      debugPrint('User interview stats updated for user: $userId');
    } catch (e) {
      debugPrint('Error updating user interview stats: $e');
      rethrow;
    }
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking user profile existence: $e');
      return false;
    }
  }

  /// Get all active job roles
  Future<List<Map<String, dynamic>>> getJobRoles({bool activeOnly = true}) async {
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
}
