import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ai_voice_interview_app/core/api/gemini_service.dart';
import 'package:ai_voice_interview_app/features/5_interview/data/interview_repository.dart';
import 'package:ai_voice_interview_app/features/5_interview/data/models/job_role_model.dart';
import 'package:ai_voice_interview_app/features/5_interview/services/database_service.dart';

/// Comprehensive interview result screen that provides detailed feedback
/// and learning opportunities for candidates after completing a mock interview.
class InterviewResultScreen extends StatefulWidget {
  final String interviewSessionId;

  const InterviewResultScreen({super.key, required this.interviewSessionId});

  @override
  State<InterviewResultScreen> createState() => _InterviewResultScreenState();
}

class _InterviewResultScreenState extends State<InterviewResultScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final GeminiService _geminiService = GeminiService();
  FlutterSoundPlayer? _audioPlayer;

  // Data storage
  Map<String, dynamic>? _interviewResult;
  List<QuestionResponseData> _questionResponses = [];
  JobRoleModel? _jobRole;
  bool _isLoading = true;
  String? _error;
  String? _currentPlayingAudio;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _loadInterviewData();
  }

  @override
  void dispose() {
    _audioPlayer?.closePlayer();
    super.dispose();
  }

  /// Initialize the audio player for playing interview recordings
  Future<void> _initializeAudioPlayer() async {
    try {
      _audioPlayer = FlutterSoundPlayer();
      await _audioPlayer!.openPlayer();
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  /// Load all interview data including results, responses, and job role details
  Future<void> _loadInterviewData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get an instance of the repository
      final interviewRepository = InterviewRepository();

      // 1. Fetch the full interview transcript
      final transcript = await interviewRepository.getInterviewTranscript(
        widget.interviewSessionId,
      );

      // 2. Fetch job role title from the session
      final sessionData = await Supabase.instance.client
          .from('interview_sessions')
          .select('job_role:job_roles(title)')
          .eq('id', widget.interviewSessionId)
          .single();
      final jobTitle = sessionData['job_role']['title'] as String;

      // 3. Get the summary from Gemini
      final summaryData = await _geminiService.getInterviewSummary(
        transcript: transcript,
        jobTitle: jobTitle,
      );

      // 4. Save the summary to the interview_results table
      await Supabase.instance.client.from('interview_results').insert({
        'interview_session_id': widget.interviewSessionId,
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'job_role_title': jobTitle,
        'overall_score': summaryData['overall_score'],
        'technical_score': summaryData['technical_score'],
        'communication_score': summaryData['communication_score'],
        'problem_solving_score': summaryData['problem_solving_score'],
        'confidence_score': summaryData['confidence_score'],
        'strengths_analysis': summaryData['strengths_analysis'],
        'areas_for_improvement': summaryData['areas_for_improvement'],
        'ai_summary': summaryData['ai_summary'],
      });

      // 5. Fetch the final result to display
      final resultData = await _fetchInterviewResult();

      // 6. Fetch question responses and job role details for UI display
      final responseData = await _fetchQuestionResponses();
      final jobRoleData = await _fetchJobRoleDetails(
        resultData!['job_role_id'],
      );

      setState(() {
        _interviewResult = resultData;
        _questionResponses = responseData;
        _jobRole = jobRoleData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading interview data: $e');
    }
  }

  /// Fetch interview result from database
  Future<Map<String, dynamic>?> _fetchInterviewResult() async {
    try {
      final response = await Supabase.instance.client
          .from('interview_results')
          .select()
          .eq('interview_session_id', widget.interviewSessionId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching interview result: $e');
      return null;
    }
  }

  /// Fetch question responses with joined question data
  Future<List<QuestionResponseData>> _fetchQuestionResponses() async {
    try {
      final response = await Supabase.instance.client
          .from('interview_responses')
          .select('''
            *,
            interview_questions!inner(
              question_text,
              question_type,
              difficulty_level,
              sample_answer,
              expected_answer_keywords
            )
          ''')
          .eq('interview_session_id', widget.interviewSessionId)
          .order('question_order');

      final List<QuestionResponseData> questionResponses = [];

      for (final responseData in response) {
        final questionData = responseData['interview_questions'];

        // Check for missing feedback and generate if needed
        String? idealAnswerComparison = responseData['ideal_answer_comparison'];
        String? suggestedImprovement = responseData['suggested_improvement'];
        String? aiFeedback = responseData['ai_feedback'];

        // Generate missing feedback using Gemini API
        if (_shouldGenerateFallbackFeedback(
          idealAnswerComparison,
          suggestedImprovement,
          aiFeedback,
        )) {
          final fallbackData = await _generateFallbackFeedback(
            questionText: questionData['question_text'],
            userAnswer: responseData['transcribed_text'] ?? '',
            jobTitle: _interviewResult?['job_role_title'] ?? '',
            questionType: questionData['question_type'],
            expectedKeywords: List<String>.from(
              questionData['expected_answer_keywords'] ?? [],
            ),
          );

          idealAnswerComparison ??= fallbackData['ideal_answer_comparison'];
          suggestedImprovement ??= fallbackData['suggested_improvement'];
          aiFeedback ??= fallbackData['ai_feedback'];
        }

        questionResponses.add(
          QuestionResponseData(
            questionId: responseData['question_id'],
            questionText: questionData['question_text'],
            questionType: questionData['question_type'],
            difficultyLevel: questionData['difficulty_level'],
            userAnswer: responseData['transcribed_text'] ?? '',
            audioFileUrl: responseData['audio_file_path'],
            responseScore: (responseData['response_score'] ?? 0.0).toDouble(),
            aiFeedback: aiFeedback ?? 'No feedback available',
            idealAnswerComparison:
                idealAnswerComparison ??
                questionData['sample_answer'] ??
                'No ideal answer available',
            suggestedImprovement:
                suggestedImprovement ??
                'Consider providing more detailed examples and explanations',
            technicalAccuracy: (responseData['technical_accuracy'] ?? 0.0)
                .toDouble(),
            communicationClarity: (responseData['communication_clarity'] ?? 0.0)
                .toDouble(),
            relevanceScore: (responseData['relevance_score'] ?? 0.0).toDouble(),
            keywordsMentioned: List<String>.from(
              responseData['keywords_mentioned'] ?? [],
            ),
            missingKeywords: List<String>.from(
              responseData['missing_keywords'] ?? [],
            ),
            confidenceLevel: (responseData['confidence_level'] ?? 0.0)
                .toDouble(),
            questionOrder: responseData['question_order'],
          ),
        );
      }

      return questionResponses;
    } catch (e) {
      debugPrint('Error fetching question responses: $e');
      return [];
    }
  }

  /// Fetch job role details
  Future<JobRoleModel?> _fetchJobRoleDetails(String jobRoleId) async {
    try {
      return await _databaseService.fetchJobRole(jobRoleId);
    } catch (e) {
      debugPrint('Error fetching job role: $e');
      return null;
    }
  }

  /// Check if fallback feedback generation is needed
  bool _shouldGenerateFallbackFeedback(
    String? idealAnswer,
    String? improvement,
    String? feedback,
  ) {
    return (idealAnswer == null || idealAnswer.isEmpty) ||
        (improvement == null || improvement.isEmpty) ||
        (feedback == null || feedback.isEmpty);
  }

  /// Generate fallback feedback using Gemini API
  Future<Map<String, String>> _generateFallbackFeedback({
    required String questionText,
    required String userAnswer,
    required String jobTitle,
    required String questionType,
    required List<String> expectedKeywords,
  }) async {
    try {
      // Use the existing evaluateInterviewAnswer method for consistency
      final evaluationResult = await _geminiService.evaluateInterviewAnswer(
        questionText: questionText,
        questionType: questionType,
        userAnswer: userAnswer,
        expectedKeywords: expectedKeywords,
        difficultyLevel: 'medium', // Default difficulty
        jobTitle: jobTitle,
      );

      return {
        'ideal_answer_comparison':
            evaluationResult['ideal_answer_comparison']?.toString() ??
            'The response addresses some key points but could be more comprehensive.',
        'suggested_improvement':
            evaluationResult['suggested_improvement']?.toString() ??
            'Consider providing more specific examples and detailed explanations.',
        'ai_feedback':
            evaluationResult['ai_feedback']?.toString() ??
            'Good effort on the response. Focus on being more specific and detailed.',
      };
    } catch (e) {
      debugPrint('Error generating fallback feedback: $e');

      // Return default fallback
      return {
        'ideal_answer_comparison':
            'The response shows understanding but could benefit from more detail.',
        'suggested_improvement':
            'Practice providing more structured and comprehensive answers.',
        'ai_feedback':
            'Continue practicing to improve your interview responses.',
      };
    }
  }

  /// Play audio recording
  Future<void> _playAudio(String? audioUrl) async {
    if (audioUrl == null || _audioPlayer == null) return;

    try {
      // Stop current playback if any
      if (_currentPlayingAudio != null) {
        await _audioPlayer!.stopPlayer();
      }

      // Get signed URL for private storage
      final signedUrl = await Supabase.instance.client.storage
          .from('interview-audio')
          .createSignedUrl(audioUrl, 3600); // 1 hour expiry

      setState(() {
        _currentPlayingAudio = audioUrl;
      });

      await _audioPlayer!.startPlayer(
        fromURI: signedUrl,
        whenFinished: () {
          setState(() {
            _currentPlayingAudio = null;
          });
        },
      );
    } catch (e) {
      debugPrint('Error playing audio: $e');
      // Use post-frame callback to ensure snackbar shows after current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
        }
      });
      setState(() {
        _currentPlayingAudio = null;
      });
    }
  }

  /// Stop audio playback
  Future<void> _stopAudio() async {
    if (_audioPlayer != null && _currentPlayingAudio != null) {
      await _audioPlayer!.stopPlayer();
      setState(() {
        _currentPlayingAudio = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Results'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your interview results...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInterviewData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInterviewData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallPerformanceSummary(),
            const SizedBox(height: 24),
            _buildQuestionBreakdown(),
            const SizedBox(height: 24),
            _buildImprovementPlan(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Build the overall performance summary card
  Widget _buildOverallPerformanceSummary() {
    if (_interviewResult == null) return const SizedBox.shrink();

    final result = _interviewResult!;
    final overallScore = (result['overall_score'] ?? 0.0).toDouble();
    final technicalScore = (result['technical_score'] ?? 0.0).toDouble();
    final communicationScore = (result['communication_score'] ?? 0.0)
        .toDouble();
    final problemSolvingScore = (result['problem_solving_score'] ?? 0.0)
        .toDouble();
    final confidenceScore = (result['confidence_score'] ?? 0.0).toDouble();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Overall Performance Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Job Role
            _buildInfoRow('Job Role', result['job_role_title'] ?? 'Unknown'),

            const SizedBox(height: 16),

            // Overall Score
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Score',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CircularPercentIndicator(
                        radius: 50,
                        lineWidth: 8,
                        percent: overallScore / 10,
                        center: Text(
                          '${overallScore.toStringAsFixed(1)}/10',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        progressColor: _getScoreColor(overallScore),
                        backgroundColor: Colors.grey[300]!,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildScoreBar('Technical', technicalScore),
                      const SizedBox(height: 8),
                      _buildScoreBar('Communication', communicationScore),
                      const SizedBox(height: 8),
                      _buildScoreBar('Problem Solving', problemSolvingScore),
                      const SizedBox(height: 8),
                      _buildScoreBar('Confidence', confidenceScore),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // AI Summary
            if (result['ai_summary'] != null && result['ai_summary'].isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Analysis Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result['ai_summary'],
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build question-by-question breakdown
  Widget _buildQuestionBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.quiz, color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Question-by-Question Analysis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._questionResponses.map((response) => _buildQuestionCard(response)),
      ],
    );
  }

  /// Build individual question analysis card
  Widget _buildQuestionCard(QuestionResponseData response) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          'Question ${response.questionOrder}: ${response.questionType.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          response.questionText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getScoreColor(response.responseScore),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${response.responseScore.toStringAsFixed(1)}/10',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Text
                _buildSectionHeader('Question'),
                Text(
                  response.questionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // User's Answer
                _buildSectionHeader('Your Answer'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    response.userAnswer.isNotEmpty
                        ? response.userAnswer
                        : 'No answer provided',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),

                // Audio Playback
                if (response.audioFileUrl != null)
                  _buildAudioPlayer(response.audioFileUrl!),

                const SizedBox(height: 16),

                // Score Breakdown
                _buildScoreBreakdown(response),
                const SizedBox(height: 16),

                // AI Feedback
                _buildSectionHeader('AI Feedback'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    response.aiFeedback,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),

                // Ideal Answer
                _buildSectionHeader('Ideal Answer Comparison'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    response.idealAnswerComparison,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),

                // Improvement Suggestions
                _buildSectionHeader('Areas for Improvement'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Text(
                    response.suggestedImprovement,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),

                // Keywords Analysis
                if (response.keywordsMentioned.isNotEmpty ||
                    response.missingKeywords.isNotEmpty)
                  _buildKeywordAnalysis(response),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build audio player widget
  Widget _buildAudioPlayer(String audioUrl) {
    final isPlaying = _currentPlayingAudio == audioUrl;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.headphones, color: Colors.purple[600]),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your Recording',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: isPlaying ? _stopAudio : () => _playAudio(audioUrl),
            icon: Icon(
              isPlaying ? Icons.stop : Icons.play_arrow,
              color: Colors.purple[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Build score breakdown for individual question
  Widget _buildScoreBreakdown(QuestionResponseData response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Score Breakdown'),
        const SizedBox(height: 8),
        _buildScoreBar('Technical Accuracy', response.technicalAccuracy),
        const SizedBox(height: 6),
        _buildScoreBar('Communication Clarity', response.communicationClarity),
        const SizedBox(height: 6),
        _buildScoreBar('Relevance', response.relevanceScore),
        const SizedBox(height: 6),
        _buildScoreBar('Confidence', response.confidenceLevel),
      ],
    );
  }

  /// Build keyword analysis section
  Widget _buildKeywordAnalysis(QuestionResponseData response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionHeader('Keyword Analysis'),
        const SizedBox(height: 8),

        if (response.keywordsMentioned.isNotEmpty) ...[
          const Text(
            'Keywords Mentioned:',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.green),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: response.keywordsMentioned
                .map(
                  (keyword) => Chip(
                    label: Text(keyword),
                    backgroundColor: Colors.green[100],
                    labelStyle: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
        ],

        if (response.missingKeywords.isNotEmpty) ...[
          const Text(
            'Missing Keywords:',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: response.missingKeywords
                .map(
                  (keyword) => Chip(
                    label: Text(keyword),
                    backgroundColor: Colors.red[100],
                    labelStyle: TextStyle(color: Colors.red[800], fontSize: 12),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  /// Build actionable improvement plan
  Widget _buildImprovementPlan() {
    if (_interviewResult == null || _jobRole == null) {
      return const SizedBox.shrink();
    }

    final result = _interviewResult!;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Your Learning Plan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Strengths
            if (result['strengths_analysis'] != null &&
                result['strengths_analysis'].isNotEmpty) ...[
              _buildSectionHeader('Your Strengths'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  result['strengths_analysis'],
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Areas for Improvement
            if (result['areas_for_improvement'] != null &&
                result['areas_for_improvement'].isNotEmpty) ...[
              _buildSectionHeader('Focus Areas for Improvement'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  result['areas_for_improvement'],
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Required Skills Analysis
            if (_jobRole!.requiredSkills.isNotEmpty) ...[
              _buildSectionHeader('Required Skills for ${_jobRole!.title}'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _jobRole!.requiredSkills
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          backgroundColor: Colors.blue[100],
                          labelStyle: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareResults(),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Results'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _scheduleNextInterview(),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Practice Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  /// Helper method to build score bars
  Widget _buildScoreBar(String label, double score) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: LinearPercentIndicator(
            padding: EdgeInsets.zero,
            lineHeight: 8,
            percent: score / 10,
            backgroundColor: Colors.grey[300],
            progressColor: _getScoreColor(score),
            barRadius: const Radius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// Get color based on score
  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    if (score >= 4) return Colors.amber;
    return Colors.red;
  }

  /// Share interview results
  void _shareResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  /// Navigate to schedule next interview
  void _scheduleNextInterview() {
    Navigator.of(context).pop(); // Go back to previous screen
  }
}

/// Data model for question response information
class QuestionResponseData {
  final String questionId;
  final String questionText;
  final String questionType;
  final String difficultyLevel;
  final String userAnswer;
  final String? audioFileUrl;
  final double responseScore;
  final String aiFeedback;
  final String idealAnswerComparison;
  final String suggestedImprovement;
  final double technicalAccuracy;
  final double communicationClarity;
  final double relevanceScore;
  final List<String> keywordsMentioned;
  final List<String> missingKeywords;
  final double confidenceLevel;
  final int questionOrder;

  QuestionResponseData({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.difficultyLevel,
    required this.userAnswer,
    this.audioFileUrl,
    required this.responseScore,
    required this.aiFeedback,
    required this.idealAnswerComparison,
    required this.suggestedImprovement,
    required this.technicalAccuracy,
    required this.communicationClarity,
    required this.relevanceScore,
    required this.keywordsMentioned,
    required this.missingKeywords,
    required this.confidenceLevel,
    required this.questionOrder,
  });
}
