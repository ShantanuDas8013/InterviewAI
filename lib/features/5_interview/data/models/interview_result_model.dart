import 'dart:convert';

class InterviewResultModel {
  final String? id;
  final String interviewSessionId;
  final String userId;
  final String jobRoleId;
  final String jobRoleTitle;
  final double overallScore;
  final double technicalScore;
  final double communicationScore;
  final double problemSolvingScore;
  final double confidenceScore;
  final String strengthsAnalysis;
  final String areasForImprovement;
  final String aiSummary;
  final DateTime? completedAt;
  final DateTime? createdAt;

  InterviewResultModel({
    this.id,
    required this.interviewSessionId,
    required this.userId,
    required this.jobRoleId,
    required this.jobRoleTitle,
    required this.overallScore,
    required this.technicalScore,
    required this.communicationScore,
    required this.problemSolvingScore,
    required this.confidenceScore,
    required this.strengthsAnalysis,
    required this.areasForImprovement,
    required this.aiSummary,
    this.completedAt,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'interview_session_id': interviewSessionId,
      'user_id': userId,
      'job_role_id': jobRoleId,
      'job_role_title': jobRoleTitle,
      'overall_score': overallScore,
      'technical_score': technicalScore,
      'communication_score': communicationScore,
      'problem_solving_score': problemSolvingScore,
      'confidence_score': confidenceScore,
      'strengths_analysis': strengthsAnalysis,
      'areas_for_improvement': areasForImprovement,
      'ai_summary': aiSummary,
      'completed_at': (completedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory InterviewResultModel.fromMap(Map<String, dynamic> map) {
    return InterviewResultModel(
      id: map['id'],
      interviewSessionId: map['interview_session_id'],
      userId: map['user_id'],
      jobRoleId: map['job_role_id'],
      jobRoleTitle: map['job_role_title'],
      overallScore: (map['overall_score'] as num).toDouble(),
      technicalScore: (map['technical_score'] as num).toDouble(),
      communicationScore: (map['communication_score'] as num).toDouble(),
      problemSolvingScore: (map['problem_solving_score'] as num).toDouble(),
      confidenceScore: (map['confidence_score'] as num).toDouble(),
      strengthsAnalysis: map['strengths_analysis'],
      areasForImprovement: map['areas_for_improvement'],
      aiSummary: map['ai_summary'],
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory InterviewResultModel.fromJson(String source) =>
      InterviewResultModel.fromMap(json.decode(source));

  // Legacy method for backward compatibility
  Map<String, dynamic> toJsonMap() => toMap();

  factory InterviewResultModel.fromJsonMap(Map<String, dynamic> json) =>
      InterviewResultModel.fromMap(json);
}
