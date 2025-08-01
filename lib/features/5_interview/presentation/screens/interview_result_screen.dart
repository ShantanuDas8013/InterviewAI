import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../../core/constants/theme.dart';
import '../../data/models/interview_result_model.dart';

class InterviewResultScreen extends StatefulWidget {
  final InterviewResultModel result;

  const InterviewResultScreen({super.key, required this.result});

  @override
  State<InterviewResultScreen> createState() => _InterviewResultScreenState();
}

class _InterviewResultScreenState extends State<InterviewResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Delay progress animation for dramatic effect
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildOverallScore(),
                    const SizedBox(height: 30),
                    _buildDetailedScores(),
                    const SizedBox(height: 30),
                    _buildAISummary(),
                    const SizedBox(height: 30),
                    _buildQuestionAnswerPairs(),
                    const SizedBox(height: 30),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getScoreColor(
                  widget.result.overallScore,
                ).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getScoreColor(
                    widget.result.overallScore,
                  ).withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getScoreIcon(widget.result.overallScore),
                    color: _getScoreColor(widget.result.overallScore),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getScoreLabel(widget.result.overallScore),
                    style: TextStyle(
                      color: _getScoreColor(widget.result.overallScore),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        const Text(
          'Interview Complete! 🎉',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Interview for ${widget.result.jobRoleTitle}',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
        ),

        const SizedBox(height: 4),

        Text(
          'Completed on ${_formatDate(widget.result.completedAt)}',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildOverallScore() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            'Overall Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CircularPercentIndicator(
                radius: 80.0,
                lineWidth: 12.0,
                animation: true,
                animationDuration: 1500,
                percent:
                    (widget.result.overallScore / 10) *
                    _progressAnimation.value,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(widget.result.overallScore * _progressAnimation.value).toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      '/ 10',
                      style: TextStyle(fontSize: 14.0, color: Colors.white70),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: _getScoreColor(widget.result.overallScore),
                backgroundColor: Colors.white.withOpacity(0.1),
              );
            },
          ),

          const SizedBox(height: 16),

          Text(
            _getScoreDescription(widget.result.overallScore),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedScores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Breakdown',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        _buildScoreCategory(
          'Technical Skills',
          widget.result.technicalScore,
          Icons.code,
          Colors.blue,
        ),

        const SizedBox(height: 12),

        _buildScoreCategory(
          'Communication',
          widget.result.communicationScore,
          Icons.chat,
          Colors.green,
        ),

        const SizedBox(height: 12),

        _buildScoreCategory(
          'Problem Solving',
          widget.result.problemSolvingScore,
          Icons.psychology,
          Colors.orange,
        ),

        const SizedBox(height: 12),

        _buildScoreCategory(
          'Confidence',
          widget.result.confidenceScore,
          Icons.emoji_emotions,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildScoreCategory(
    String title,
    double score,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearPercentIndicator(
                      width: MediaQuery.of(context).size.width - 140,
                      animation: true,
                      lineHeight: 6.0,
                      animationDuration: 1500,
                      percent: (score / 10) * _progressAnimation.value,
                      barRadius: const Radius.circular(3),
                      progressColor: color,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    );
                  },
                ),
              ],
            ),
          ),

          Text(
            '${score.toStringAsFixed(1)}/10',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            widget.result.aiSummary,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStrengthsWeaknesses(
                  'Strengths',
                  widget.result.strengthsAnalysis,
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStrengthsWeaknesses(
                  'Areas to Improve',
                  widget.result.areasForImprovement,
                  Colors.orange,
                  Icons.trending_down,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsWeaknesses(
    String title,
    String content,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionAnswerPairs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Question by Question Analysis',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        ...widget.result.questionAnswerPairs.asMap().entries.map((entry) {
          final index = entry.key;
          final pair = entry.value;
          return _buildQuestionAnswerCard(index + 1, pair);
        }).toList(),
      ],
    );
  }

  Widget _buildQuestionAnswerCard(int questionNumber, QuestionAnswerPair pair) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white.withOpacity(0.7),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getScoreColor(pair.score).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$questionNumber',
                  style: TextStyle(
                    color: _getScoreColor(pair.score),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pair.questionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getScoreColor(pair.score).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${pair.score.toStringAsFixed(1)}/10',
                style: TextStyle(
                  color: _getScoreColor(pair.score),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [_buildAnswerComparison(pair)],
      ),
    );
  }

  Widget _buildAnswerComparison(QuestionAnswerPair pair) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User's Answer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Your Answer',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (pair.audioUrl != null)
                    Icon(
                      Icons.volume_up,
                      color: Colors.blue.withOpacity(0.7),
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pair.userAnswer.isNotEmpty
                    ? pair.userAnswer
                    : 'No answer provided',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Ideal Answer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Ideal Answer',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pair.idealAnswer,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Feedback
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.feedback, color: Colors.purple, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Feedback',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pair.feedback,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Share Results Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _shareResults,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text(
              'Share Results',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Practice Again Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _practiceAgain,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Practice Again',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Back to Home Button
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _backToHome,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: Icon(Icons.home, color: Colors.white.withOpacity(0.7)),
            label: Text(
              'Back to Home',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score >= 8.0) return Icons.emoji_emotions;
    if (score >= 6.0) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String _getScoreLabel(double score) {
    if (score >= 8.0) return 'Excellent';
    if (score >= 6.0) return 'Good';
    return 'Needs Improvement';
  }

  String _getScoreDescription(double score) {
    if (score >= 8.0) {
      return 'Outstanding performance! You demonstrated excellent knowledge and communication skills.';
    } else if (score >= 6.0) {
      return 'Good performance! You show solid understanding with room for improvement.';
    } else {
      return 'Keep practicing! Focus on the areas for improvement to enhance your interview skills.';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _shareResults() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Results shared successfully!'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  void _practiceAgain() {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _backToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
