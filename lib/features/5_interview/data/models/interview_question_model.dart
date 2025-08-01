class InterviewQuestionModel {
  final String id;
  final String jobRoleId;
  final String questionText;
  final String questionType; // technical, behavioral, situational, general
  final String difficultyLevel; // easy, medium, hard
  final List<String>? expectedAnswerKeywords;
  final String? sampleAnswer;
  final Map<String, dynamic>? evaluationCriteria;
  final int? timeLimitSeconds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  InterviewQuestionModel({
    required this.id,
    required this.jobRoleId,
    required this.questionText,
    required this.questionType,
    required this.difficultyLevel,
    this.expectedAnswerKeywords,
    this.sampleAnswer,
    this.evaluationCriteria,
    this.timeLimitSeconds = 120,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InterviewQuestionModel.fromJson(Map<String, dynamic> json) {
    return InterviewQuestionModel(
      id: json['id'],
      jobRoleId: json['job_role_id'],
      questionText: json['question_text'],
      questionType: json['question_type'],
      difficultyLevel: json['difficulty_level'],
      expectedAnswerKeywords: json['expected_answer_keywords'] != null
          ? List<String>.from(json['expected_answer_keywords'])
          : null,
      sampleAnswer: json['sample_answer'],
      evaluationCriteria: json['evaluation_criteria'],
      timeLimitSeconds: json['time_limit_seconds'] ?? 120,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_role_id': jobRoleId,
      'question_text': questionText,
      'question_type': questionType,
      'difficulty_level': difficultyLevel,
      'expected_answer_keywords': expectedAnswerKeywords,
      'sample_answer': sampleAnswer,
      'evaluation_criteria': evaluationCriteria,
      'time_limit_seconds': timeLimitSeconds,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}