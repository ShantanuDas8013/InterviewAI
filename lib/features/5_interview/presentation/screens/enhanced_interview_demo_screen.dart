import 'package:flutter/material.dart';

import '../../data/models/interview_question_model.dart';
import '../../services/enhanced_interview_service.dart';

/// Demo screen showcasing the enhanced interview capabilities
/// with improved AssemblyAI transcription and Gemini AI evaluation
class EnhancedInterviewDemoScreen extends StatefulWidget {
  const EnhancedInterviewDemoScreen({super.key});

  @override
  State<EnhancedInterviewDemoScreen> createState() =>
      _EnhancedInterviewDemoScreenState();
}

class _EnhancedInterviewDemoScreenState
    extends State<EnhancedInterviewDemoScreen> {
  final EnhancedInterviewService _enhancedService = EnhancedInterviewService();

  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isProcessing = false;

  String _currentStatus = 'Initializing...';
  Map<String, dynamic>? _lastEvaluationResult;
  double _recordingAmplitude = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      setState(
        () => _currentStatus = 'Initializing enhanced interview service...',
      );

      final success = await _enhancedService.initialize();

      setState(() {
        _isInitialized = success;
        _currentStatus = success
            ? 'Ready for enhanced interview demo!'
            : 'Failed to initialize service';
      });
    } catch (e) {
      setState(() {
        _currentStatus = 'Initialization error: $e';
      });
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized || _isRecording) return;

    try {
      setState(() {
        _isRecording = true;
        _currentStatus = 'Recording your answer...';
      });

      // Create a demo question
      final demoQuestion = InterviewQuestionModel(
        id: 'demo_question_1',
        jobRoleId: 'demo_role',
        questionText:
            'Tell me about a challenging project you worked on and how you overcame the obstacles.',
        questionType: 'behavioral',
        difficultyLevel: 'medium',
        expectedAnswerKeywords: [
          'challenge',
          'project',
          'problem-solving',
          'teamwork',
          'solution',
          'results',
          'communication',
          'leadership',
        ],
        evaluationCriteria: {
          'structure': 'Uses STAR method or clear structure',
          'specificity': 'Provides specific examples and details',
          'impact': 'Demonstrates measurable results',
          'skills': 'Shows relevant technical or soft skills',
        },
        timeLimitSeconds: 180,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sampleAnswer:
            'A comprehensive answer should include the situation, task, action taken, and results achieved, demonstrating problem-solving skills and teamwork.',
      );

      // Start recording with enhanced service
      await _enhancedService.recordAndEvaluateAnswer(
        question: demoQuestion,
        sessionId: 'demo_session_123',
        userId: 'demo_user_456',
        questionOrder: 1,
        jobTitle: 'Software Developer',
        jobCategory: 'Technology',
        maxRecordingSeconds: 180,
      );

      // Start amplitude monitoring
      _startAmplitudeMonitoring();
    } catch (e) {
      setState(() {
        _isRecording = false;
        _currentStatus = 'Error starting recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _currentStatus = 'Processing your answer with AI...';
      });

      // Create the same demo question
      final demoQuestion = InterviewQuestionModel(
        id: 'demo_question_1',
        jobRoleId: 'demo_role',
        questionText:
            'Tell me about a challenging project you worked on and how you overcame the obstacles.',
        questionType: 'behavioral',
        difficultyLevel: 'medium',
        expectedAnswerKeywords: [
          'challenge',
          'project',
          'problem-solving',
          'teamwork',
          'solution',
          'results',
          'communication',
          'leadership',
        ],
        evaluationCriteria: {
          'structure': 'Uses STAR method or clear structure',
          'specificity': 'Provides specific examples and details',
          'impact': 'Demonstrates measurable results',
          'skills': 'Shows relevant technical or soft skills',
        },
        timeLimitSeconds: 180,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sampleAnswer:
            'A comprehensive answer should include the situation, task, action taken, and results achieved, demonstrating problem-solving skills and teamwork.',
      );

      // Stop recording and get evaluation
      final result = await _enhancedService.stopRecordingAndEvaluate(
        question: demoQuestion,
        sessionId: 'demo_session_123',
        userId: 'demo_user_456',
        questionOrder: 1,
        jobTitle: 'Software Developer',
        jobCategory: 'Technology',
      );

      setState(() {
        _isProcessing = false;
        _lastEvaluationResult = result;
        _currentStatus =
            'Analysis complete! Score: ${result['overall_score']?.toStringAsFixed(1)}/10';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _currentStatus = 'Error processing answer: $e';
      });
    }
  }

  void _startAmplitudeMonitoring() {
    // Monitor recording amplitude for visual feedback
    Future.doWhile(() async {
      if (!_isRecording) return false;

      try {
        final amplitude = await _enhancedService.getRecordingAmplitude();
        setState(() => _recordingAmplitude = amplitude);
      } catch (e) {
        // Continue monitoring even if amplitude fails
      }

      await Future.delayed(const Duration(milliseconds: 100));
      return _isRecording;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Interview Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.indigo],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildRecordingSection(),
                const SizedBox(height: 30),
                if (_lastEvaluationResult != null) _buildResultsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enhanced Interview System',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This demo showcases the improved interview system with:',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...const [
              '• Enhanced AssemblyAI transcription with sentiment analysis',
              '• Comprehensive Gemini AI answer evaluation',
              '• Real-time confidence scoring and feedback',
              '• Technical accuracy and communication assessment',
              '• Detailed improvement recommendations',
            ].map(
              (feature) => Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 5),
                child: Text(
                  feature,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Demo Question',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Tell me about a challenging project you worked on and how you overcame the obstacles.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _currentStatus,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_isRecording) _buildAmplitudeVisualizer(),
            const SizedBox(height: 20),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmplitudeVisualizer() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Container(
          height: 30,
          width: _recordingAmplitude * 200,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _isInitialized && !_isRecording && !_isProcessing
              ? _startRecording
              : null,
          icon: const Icon(Icons.mic),
          label: const Text('Start Recording'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isRecording ? _stopRecording : null,
          icon: const Icon(Icons.stop),
          label: const Text('Stop & Analyze'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    final result = _lastEvaluationResult!;
    final evaluation = result['evaluation'] as Map<String, dynamic>;

    return Expanded(
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Analysis Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _buildScoreGrid(evaluation),
              const SizedBox(height: 15),
              _buildFeedbackSection(evaluation),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreGrid(Map<String, dynamic> evaluation) {
    final scores = [
      ('Overall', evaluation['overall_score']),
      ('Technical', evaluation['technical_accuracy']),
      ('Communication', evaluation['communication_clarity']),
      ('Relevance', evaluation['relevance_score']),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: scores.length,
      itemBuilder: (context, index) {
        final score = scores[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                score.$1,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${score.$2?.toStringAsFixed(1) ?? '0.0'}/10',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackSection(Map<String, dynamic> evaluation) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Feedback:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                evaluation['detailed_feedback'] ?? 'No feedback available',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 15),
            if (evaluation['strengths'] != null) ...[
              const Text(
                'Strengths:',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              ...List<String>.from(evaluation['strengths']).map(
                (strength) => Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 3),
                  child: Text(
                    '• $strength',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (evaluation['areas_for_improvement'] != null) ...[
              const Text(
                'Areas for Improvement:',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              ...List<String>.from(evaluation['areas_for_improvement']).map(
                (improvement) => Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 3),
                  child: Text(
                    '• $improvement',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
