class InterviewResultModel {
  final String id;
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
  final DateTime completedAt;
  final DateTime createdAt;
  final List<QuestionAnswerPair> questionAnswerPairs;

  InterviewResultModel({
    required this.id,
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
    required this.completedAt,
    required this.createdAt,
    required this.questionAnswerPairs,
  });

  factory InterviewResultModel.fromJson(Map<String, dynamic> json) {
    return InterviewResultModel(
      id: json['id'],
      interviewSessionId: json['interview_session_id'],
      userId: json['user_id'],
      jobRoleId: json['job_role_id'],
      jobRoleTitle: json['job_role_title'],
      overallScore: json['overall_score'].toDouble(),
      technicalScore: json['technical_score'].toDouble(),
      communicationScore: json['communication_score'].toDouble(),
      problemSolvingScore: json['problem_solving_score'].toDouble(),
      confidenceScore: json['confidence_score'].toDouble(),
      strengthsAnalysis: json['strengths_analysis'],
      areasForImprovement: json['areas_for_improvement'],
      aiSummary: json['ai_summary'],
      completedAt: DateTime.parse(json['completed_at']),
      createdAt: DateTime.parse(json['created_at']),
      questionAnswerPairs:
          (json['question_answer_pairs'] as List?)
              ?.map((pair) => QuestionAnswerPair.fromJson(pair))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'completed_at': completedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'question_answer_pairs': questionAnswerPairs
          .map((pair) => pair.toJson())
          .toList(),
    };
  }
}

class QuestionAnswerPair {
  final String questionId;
  final String questionText;
  final String userAnswer;
  final String idealAnswer;
  final String feedback;
  final double score;
  final String? audioUrl;

  QuestionAnswerPair({
    required this.questionId,
    required this.questionText,
    required this.userAnswer,
    required this.idealAnswer,
    required this.feedback,
    required this.score,
    this.audioUrl,
  });

  factory QuestionAnswerPair.fromJson(Map<String, dynamic> json) {
    return QuestionAnswerPair(
      questionId: json['question_id'],
      questionText: json['question_text'],
      userAnswer: json['user_answer'],
      idealAnswer: json['ideal_answer'],
      feedback: json['feedback'],
      score: json['score'].toDouble(),
      audioUrl: json['audio_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'user_answer': userAnswer,
      'ideal_answer': idealAnswer,
      'feedback': feedback,
      'score': score,
      'audio_url': audioUrl,
    };
  }
}
