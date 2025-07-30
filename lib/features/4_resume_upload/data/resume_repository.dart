import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResumeRepository {
  static final ResumeRepository _instance = ResumeRepository._internal();
  factory ResumeRepository() => _instance;
  ResumeRepository._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's active resume
  Future<Map<String, dynamic>?> getUserResume(String userId) async {
    try {
      final response = await _supabase
          .from('resumes')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching user resume: $e');
      return null;
    }
  }

  /// Upload resume file to storage and create database record
  Future<Map<String, dynamic>> uploadResume({
    required String userId,
    required String fileName,
    required String filePath,
    required int fileSize,
  }) async {
    try {
      // Deactivate existing resume if any
      await _supabase
          .from('resumes')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('is_active', true);

      // Upload file to storage
      final storagePath = '$userId/$fileName';
      final file = File(filePath);

      await _supabase.storage.from('resumes').upload(storagePath, file);

      // Create database record
      final resumeData = {
        'user_id': userId,
        'file_name': fileName,
        'file_path': storagePath,
        'file_size_bytes': fileSize,
        'is_active': true,
        'is_analyzed': false,
      };

      final response = await _supabase
          .from('resumes')
          .insert(resumeData)
          .select()
          .single();

      debugPrint('Resume uploaded successfully for user: $userId');
      return response;
    } catch (e) {
      debugPrint('Error uploading resume: $e');
      rethrow;
    }
  }

  /// Delete resume from storage and database
  Future<void> deleteResume(String resumeId, String filePath) async {
    try {
      // Delete from storage
      await _supabase.storage.from('resumes').remove([filePath]);

      // Delete from database
      await _supabase.from('resumes').delete().eq('id', resumeId);

      debugPrint('Resume deleted successfully: $resumeId');
    } catch (e) {
      debugPrint('Error deleting resume: $e');
      rethrow;
    }
  }

  /// Get resume analysis if available
  Future<Map<String, dynamic>?> getResumeAnalysis(String resumeId) async {
    try {
      final response = await _supabase
          .from('resume_analysis')
          .select()
          .eq('resume_id', resumeId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching resume analysis: $e');
      return null;
    }
  }

  /// Update resume analysis status
  Future<void> updateResumeAnalysisStatus(
    String resumeId,
    bool isAnalyzed,
  ) async {
    try {
      await _supabase
          .from('resumes')
          .update({'is_analyzed': isAnalyzed})
          .eq('id', resumeId);

      debugPrint('Resume analysis status updated: $resumeId');
    } catch (e) {
      debugPrint('Error updating resume analysis status: $e');
      rethrow;
    }
  }

  /// Get all resumes for a user (including inactive ones)
  Future<List<Map<String, dynamic>>> getUserAllResumes(String userId) async {
    try {
      final response = await _supabase
          .from('resumes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user resumes: $e');
      return [];
    }
  }

  /// Save resume analysis results
  Future<Map<String, dynamic>> saveResumeAnalysis({
    required String resumeId,
    required String userId,
    required Map<String, dynamic> analysisData,
  }) async {
    try {
      // Extract and process all data from Gemini analysis
      final skillsData = analysisData['skills'] as Map<String, dynamic>?;
      final experienceData =
          analysisData['experience'] as Map<String, dynamic>?;
      final educationData = analysisData['education'] as Map<String, dynamic>?;
      final atsOptimization =
          analysisData['atsOptimization'] as Map<String, dynamic>?;
      final keywordAnalysis =
          analysisData['keywordAnalysis'] as Map<String, dynamic>?;

      // Extract technical skills for the extracted_skills field
      List<String> extractedSkills = [];
      if (skillsData != null) {
        if (skillsData['technical'] is List) {
          extractedSkills.addAll(List<String>.from(skillsData['technical']));
        }
        if (skillsData['soft'] is List) {
          extractedSkills.addAll(List<String>.from(skillsData['soft']));
        }
        if (skillsData['domain'] is List) {
          extractedSkills.addAll(List<String>.from(skillsData['domain']));
        }
      }

      // Extract companies and job titles
      List<String> companies = [];
      List<String> jobTitles = [];
      if (experienceData != null) {
        if (experienceData['companies'] is List) {
          companies.addAll(List<String>.from(experienceData['companies']));
        }
        if (experienceData['jobTitles'] is List) {
          jobTitles.addAll(List<String>.from(experienceData['jobTitles']));
        }
      }

      // Extract keywords
      List<String> relevantKeywords = [];
      List<String> missingKeywords = [];
      if (keywordAnalysis != null) {
        if (keywordAnalysis['relevantKeywords'] is List) {
          relevantKeywords.addAll(
            List<String>.from(keywordAnalysis['relevantKeywords']),
          );
        }
        if (keywordAnalysis['missingKeywords'] is List) {
          missingKeywords.addAll(
            List<String>.from(keywordAnalysis['missingKeywords']),
          );
        }
      }

      // Extract ATS issues
      List<String> atsIssues = [];
      if (atsOptimization != null && atsOptimization['issues'] is List) {
        atsIssues.addAll(List<String>.from(atsOptimization['issues']));
      }

      final analysisRecord = {
        'resume_id': resumeId,
        'user_id': userId,
        'overall_score': _normalizeScore(analysisData['overallScore']),
        'overall_feedback':
            analysisData['overallFeedback']?.toString() ??
            'AI analysis completed successfully',
        'contact_info_score': null, // Will be calculated in future versions
        'summary_score': null, // Will be calculated in future versions
        'experience_score': null, // Will be calculated in future versions
        'education_score': null, // Will be calculated in future versions
        'skills_score': null, // Will be calculated in future versions
        'projects_score': null, // Will be calculated in future versions
        'extracted_skills': extractedSkills,
        'extracted_experience_years': _safeConvertToInt(
          experienceData?['yearsOfExperience'],
        ),
        'extracted_education_level': educationData?['educationLevel']
            ?.toString(),
        'extracted_companies': companies.isNotEmpty ? companies : null,
        'extracted_job_titles': jobTitles.isNotEmpty ? jobTitles : null,
        'missing_sections': null, // Will be implemented in future versions
        'improvement_suggestions': analysisData['improvements'] is List
            ? List<String>.from(analysisData['improvements'])
            : null,
        'recommended_job_roles': analysisData['jobRecommendations'] is List
            ? List<String>.from(analysisData['jobRecommendations'])
            : null,
        'relevant_keywords': relevantKeywords.isNotEmpty
            ? relevantKeywords
            : null,
        'missing_keywords': missingKeywords.isNotEmpty ? missingKeywords : null,
        'keyword_density': keywordAnalysis?['keywordDensity'] != null
            ? {'density': keywordAnalysis!['keywordDensity']}
            : null,
        'ats_score': atsOptimization?['score'] is num
            ? _normalizeScore(atsOptimization!['score'])
            : null,
        'ats_issues': atsIssues.isNotEmpty ? atsIssues : null,
        'gemini_analysis_raw': analysisData,
      };

      // Delete any existing analysis for this resume first
      await _supabase
          .from('resume_analysis')
          .delete()
          .eq('resume_id', resumeId);

      // Insert new analysis record
      final response = await _supabase
          .from('resume_analysis')
          .insert(analysisRecord)
          .select()
          .single();

      debugPrint('Resume analysis saved successfully: $resumeId');
      return response;
    } catch (e) {
      debugPrint('Error saving resume analysis: $e');
      rethrow;
    }
  }

  /// Get resume file download URL
  Future<String?> getResumeDownloadUrl(String filePath) async {
    try {
      final response = await _supabase.storage
          .from('resumes')
          .createSignedUrl(filePath, 60); // 60 seconds expiry

      return response;
    } catch (e) {
      debugPrint('Error getting resume download URL: $e');
      return null;
    }
  }

  /// Normalize score to 0-10 range
  double _normalizeScore(dynamic score) {
    if (score == null) return 0.0;

    double normalizedScore = 0.0;
    if (score is num) {
      normalizedScore = score.toDouble();
    } else if (score is String) {
      normalizedScore = double.tryParse(score) ?? 0.0;
    }

    // Ensure score is within 0-10 range
    if (normalizedScore > 10.0) {
      normalizedScore =
          normalizedScore / 10.0; // Convert from 100-scale to 10-scale
    }

    return normalizedScore.clamp(0.0, 10.0);
  }

  /// Safely convert dynamic value to integer
  int? _safeConvertToInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    } else if (value is double) {
      return value.round();
    } else if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed.round();
      }
    }

    // If value is a num but not specifically int or double
    if (value is num) {
      return value.round();
    }

    return null;
  }
}
