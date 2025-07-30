class InterviewSessionModel {
  final String id;
  final String userId;
  final String jobRoleId;
  final String? resumeId;
  final String sessionName;
  final String sessionType;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? durationSeconds;
  final int totalQuestions;
  final int questionsAnswered;
  final String difficultyLevel;
  final double? overallScore;
  final double? technicalScore;
  final double? communicationScore;
  final double? confidenceScore;
  final DateTime createdAt;

  InterviewSessionModel({
    required this.id,
    required this.userId,
    required this.jobRoleId,
    this.resumeId,
    required this.sessionName,
    required this.sessionType,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.durationSeconds,
    required this.totalQuestions,
    required this.questionsAnswered,
    required this.difficultyLevel,
    this.overallScore,
    this.technicalScore,
    this.communicationScore,
    this.confidenceScore,
    required this.createdAt,
  });

  factory InterviewSessionModel.fromJson(Map<String, dynamic> json) {
    return InterviewSessionModel(
      id: json['id'],
      userId: json['user_id'],
      jobRoleId: json['job_role_id'],
      resumeId: json['resume_id'],
      sessionName: json['session_name'],
      sessionType: json['session_type'],
      status: json['status'],
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      durationSeconds: json['duration_seconds'],
      totalQuestions: json['total_questions'],
      questionsAnswered: json['questions_answered'],
      difficultyLevel: json['difficulty_level'],
      overallScore: json['overall_score']?.toDouble(),
      technicalScore: json['technical_score']?.toDouble(),
      communicationScore: json['communication_score']?.toDouble(),
      confidenceScore: json['confidence_score']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'job_role_id': jobRoleId,
      'resume_id': resumeId,
      'session_name': sessionName,
      'session_type': sessionType,
      'status': status,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'total_questions': totalQuestions,
      'questions_answered': questionsAnswered,
      'difficulty_level': difficultyLevel,
      'overall_score': overallScore,
      'technical_score': technicalScore,
      'communication_score': communicationScore,
      'confidence_score': confidenceScore,
      'created_at': createdAt.toIso8601String(),
    };
  }
}