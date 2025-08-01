import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/theme.dart';
import '../../../../core/api/gemini_service.dart';
import '../../data/models/job_role_model.dart';
import '../../data/models/interview_session_model.dart';
import '../../data/models/interview_question_model.dart';
import '../../data/models/interview_result_model.dart';
import '../../services/speech_to_text_service.dart';
import '../../services/text_to_speech_service.dart';
import '../../services/database_service.dart';
import 'interview_result_screen.dart';

class InterviewScreen extends StatefulWidget {
  final JobRoleModel jobRole;
  final String? resumeId;
  final String difficultyLevel;
  final int totalQuestions;

  const InterviewScreen({
    super.key,
    required this.jobRole,
    this.resumeId,
    this.difficultyLevel = 'medium',
    this.totalQuestions = 10,
  });

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _rotationAnimation;

  // Services
  final SpeechToTextService _speechService = SpeechToTextService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final DatabaseService _databaseService = DatabaseService();
  final GeminiService _geminiService = GeminiService();

  // Interview state
  InterviewSessionModel? _currentSession;
  List<InterviewQuestionModel> _questions = [];
  int _currentQuestionIndex = 0;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  bool _isInterviewStarted = false;
  bool _isInterviewEnded = false;
  String _currentTranscript = '';
  String _finalTranscript = '';
  Timer? _listeningTimer;
  Timer? _interviewTimer;
  Duration _interviewDuration = Duration.zero;
  List<Map<String, dynamic>> _userResponses = [];

  // UI state
  double _microphoneLevel = 0.0;
  bool _showTranscript = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _setupInterview();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);
    _rotationController.repeat();
  }

  Future<void> _initializeServices() async {
    try {
      await _speechService.initialize();
      await _ttsService.initialize();
      await _geminiService.initialize();
    } catch (e) {
      _showErrorDialog('Failed to initialize services: $e');
    }
  }

  Future<void> _setupInterview() async {
    try {
      // Create interview session
      final sessionId = await _databaseService.createInterviewSession(
        userId: Supabase.instance.client.auth.currentUser!.id,
        jobRoleId: widget.jobRole.id,
        questionCount: widget.totalQuestions,
      );

      // Create session model for local use
      _currentSession = InterviewSessionModel(
        id: sessionId,
        userId: Supabase.instance.client.auth.currentUser!.id,
        jobRoleId: widget.jobRole.id,
        sessionName: 'Interview for ${widget.jobRole.title}',
        sessionType: 'practice',
        status: 'in_progress',
        totalQuestions: widget.totalQuestions,
        questionsAnswered: 0,
        difficultyLevel: widget.difficultyLevel,
        createdAt: DateTime.now(),
      );

      // Generate questions using Gemini AI
      await _generateQuestions();

      // Start with welcome message
      await _speakWelcomeMessage();
    } catch (e) {
      _showErrorDialog('Failed to setup interview: $e');
    }
  }

  Future<void> _generateQuestions() async {
    try {
      setState(() => _isProcessing = true);

      // For now, create hardcoded questions based on job role
      // In a real implementation, you would use the Gemini API
      _questions = _createHardcodedQuestions();

      setState(() => _isProcessing = false);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorDialog('Failed to generate questions: $e');
    }
  }

  List<InterviewQuestionModel> _createHardcodedQuestions() {
    final baseQuestions = <Map<String, dynamic>>[
      {
        'question_text': 'Can you tell me about yourself and your background?',
        'question_type': 'general',
        'difficulty_level': 'easy',
        'expected_keywords': ['experience', 'skills', 'background'],
        'sample_answer':
            'I am a ${widget.jobRole.title} with experience in ${widget.jobRole.requiredSkills.take(3).join(', ')}. I have worked on various projects that required...',
      },
      {
        'question_text':
            'What interests you about this ${widget.jobRole.title} position?',
        'question_type': 'behavioral',
        'difficulty_level': 'easy',
        'expected_keywords': ['interest', 'motivation', 'skills'],
        'sample_answer':
            'I am interested in this position because it combines my skills in ${widget.jobRole.requiredSkills.first} with my passion for...',
      },
      {
        'question_text':
            'Can you explain your experience with ${widget.jobRole.requiredSkills.isNotEmpty ? widget.jobRole.requiredSkills.first : 'relevant technologies'}?',
        'question_type': 'technical',
        'difficulty_level': 'medium',
        'expected_keywords': widget.jobRole.requiredSkills,
        'sample_answer':
            'I have worked extensively with ${widget.jobRole.requiredSkills.isNotEmpty ? widget.jobRole.requiredSkills.first : 'various technologies'} for...',
      },
      {
        'question_text':
            'Describe a challenging project you\'ve worked on and how you overcame difficulties.',
        'question_type': 'behavioral',
        'difficulty_level': 'medium',
        'expected_keywords': ['challenge', 'project', 'solution', 'overcome'],
        'sample_answer':
            'I worked on a project where we faced technical challenges with... I overcame this by...',
      },
      {
        'question_text':
            'How do you stay updated with the latest trends in ${widget.jobRole.category}?',
        'question_type': 'general',
        'difficulty_level': 'easy',
        'expected_keywords': ['learning', 'trends', 'update', 'technology'],
        'sample_answer':
            'I stay updated by reading industry blogs, attending conferences, taking online courses...',
      },
    ];

    // Add more technical questions based on job role
    if (widget.jobRole.requiredSkills.length > 1) {
      baseQuestions.addAll([
        {
          'question_text':
              'How would you approach a problem involving ${widget.jobRole.requiredSkills.length > 1 ? widget.jobRole.requiredSkills[1] : widget.jobRole.requiredSkills.first}?',
          'question_type': 'technical',
          'difficulty_level': 'medium',
          'expected_keywords': widget.jobRole.requiredSkills,
          'sample_answer':
              'I would start by analyzing the requirements, then design a solution using best practices...',
        },
        {
          'question_text':
              'Describe your experience working in a team environment.',
          'question_type': 'behavioral',
          'difficulty_level': 'easy',
          'expected_keywords': ['team', 'collaboration', 'communication'],
          'sample_answer':
              'I have extensive experience working in cross-functional teams where I contributed by...',
        },
        {
          'question_text':
              'What are your strengths and how do they relate to this role?',
          'question_type': 'behavioral',
          'difficulty_level': 'easy',
          'expected_keywords': ['strengths', 'skills', 'role'],
          'sample_answer':
              'My key strengths include attention to detail, problem-solving abilities, and strong communication skills which are essential for...',
        },
        {
          'question_text': 'Where do you see yourself in 5 years?',
          'question_type': 'general',
          'difficulty_level': 'easy',
          'expected_keywords': ['career', 'goals', 'growth'],
          'sample_answer':
              'In 5 years, I see myself as a senior professional who has contributed significantly to...',
        },
        {
          'question_text':
              'Do you have any questions for us about the role or company?',
          'question_type': 'general',
          'difficulty_level': 'easy',
          'expected_keywords': ['questions', 'role', 'company'],
          'sample_answer':
              'Yes, I would like to know more about the team structure, growth opportunities, and the biggest challenges facing the team.',
        },
      ]);
    }

    // Select questions based on total questions requested
    final selectedQuestions = baseQuestions
        .take(widget.totalQuestions)
        .toList();

    return selectedQuestions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;

      return InterviewQuestionModel(
        id: 'q_${DateTime.now().millisecondsSinceEpoch}_$index',
        jobRoleId: widget.jobRole.id,
        questionText: question['question_text'],
        questionType: question['question_type'],
        difficultyLevel: question['difficulty_level'],
        expectedAnswerKeywords: List<String>.from(
          question['expected_keywords'] ?? [],
        ),
        sampleAnswer: question['sample_answer'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  Future<void> _speakWelcomeMessage() async {
    // First greeting
    await _speakText(
      'Hello! Welcome to your AI voice interview for the position of ${widget.jobRole.title}.',
      rate: 0.75,
    );

    // Short pause
    await Future.delayed(const Duration(milliseconds: 800));

    // Introduction
    await _speakText(
      'I am your AI interviewer, and I\'ll be asking you ${widget.totalQuestions} questions today to learn more about your experience and skills.',
      rate: 0.75,
    );

    // Longer pause
    await Future.delayed(const Duration(seconds: 1));

    // Instructions
    await _speakText(
      'Here\'s how it works: I\'ll ask you a question, then you\'ll have time to think and answer. Take your time and speak clearly. If you need more time, just keep talking and I\'ll listen.',
      rate: 0.7,
    );

    // Short pause
    await Future.delayed(const Duration(milliseconds: 800));

    // Note about speech recognition
    if (!_speechService.isInitialized) {
      await _speakText(
        'It seems that speech recognition is not available on your device. You can still participate in the interview, but you\'ll need to mentally prepare your answers as we go through the questions.',
        rate: 0.7,
      );
      await Future.delayed(const Duration(seconds: 1));
    }

    // Final instructions
    await _speakText(
      'You can end the interview anytime by tapping the disconnect button. Are you ready to begin? Let\'s start with the first question.',
      rate: 0.75,
    );

    _isInterviewStarted = true;
    _startInterviewTimer();

    // Short pause before first question
    await Future.delayed(const Duration(seconds: 1));
    await _askNextQuestion();
  }

  void _startInterviewTimer() {
    _interviewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _interviewDuration = Duration(seconds: timer.tick);
        });
      }
    });
  }

  Future<void> _askNextQuestion() async {
    if (_currentQuestionIndex >= _questions.length) {
      await _completeInterview();
      return;
    }

    final question = _questions[_currentQuestionIndex];

    // First, just announce the question number with a pause
    await _speakText(
      "Question ${_currentQuestionIndex + 1} of ${_questions.length}:",
      rate: null,
    );

    // Add a short pause before asking the actual question
    await Future.delayed(const Duration(milliseconds: 800));

    // Then ask the actual question
    await _speakText(question.questionText);

    // Add a short pause to simulate thinking
    await Future.delayed(const Duration(milliseconds: 500));

    // Prompt the user to answer
    await _speakText("Please take your time to answer this question.");

    // Start listening after a short pause
    await Future.delayed(const Duration(milliseconds: 500));
    await _startListening();
  }

  Future<void> _speakText(String text, {double? rate}) async {
    setState(() {
      _isSpeaking = true;
    });

    try {
      // Split text into sentences for more natural pauses
      final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));

      for (final sentence in sentences) {
        if (!mounted) break; // Check if widget is still mounted

        // Add a slight pause between sentences for more natural speech
        if (sentences.indexOf(sentence) > 0) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Set a slower speech rate for more human-like speech
        await _ttsService.speak(sentence, rate: rate ?? 0.8);
      }
    } catch (e) {
      debugPrint('TTS Error: $e');
    }

    setState(() {
      _isSpeaking = false;
    });
  }

  Future<void> _startListening() async {
    try {
      // Request microphone permission
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        _showErrorDialog(
          'Microphone permission is required for voice interview',
        );
        return;
      }

      setState(() {
        _isListening = true;
        _currentTranscript = '';
        _finalTranscript = '';
        _showTranscript = true;
      });

      // Check if speech recognition is initialized
      if (!_speechService.isInitialized) {
        _showErrorDialog(
          'Speech recognition service is not available. Please check your device settings and permissions.',
        );
        // If speech recognition failed to initialize, show a message to the user
        // but continue with the interview flow
        setState(() {
          _isListening = false;
          _currentTranscript =
              "[Speech recognition unavailable. Please continue with the interview.]";
        });
        // Don't start a timer, just move on after a delay.
        await Future.delayed(const Duration(seconds: 5));
        await _handleNoAnswer(forceSkip: true);
        return;
      }

      // Start listening with timeout
      await _speechService.startListening(
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() {
            if (isFinal) {
              _finalTranscript = text;
              _currentTranscript = '';

              // If we got a final result with substantial content, update the timer
              // to give the user more time to continue speaking
              if (text.split(' ').length > 5) {
                _resetListeningTimer();
              }
            } else {
              _currentTranscript = text;
            }
          });

          // Update microphone level simulation
          _updateMicrophoneLevel();
        },
      );

      // Set timeout for listening (90 seconds max per question)
      _resetListeningTimer();
    } catch (e) {
      setState(() {
        _isListening = false;
        _currentTranscript =
            "[Speech recognition error. Please continue with the interview.]";
      });
      debugPrint('Failed to start listening: $e');
      await Future.delayed(const Duration(seconds: 5));
      await _handleNoAnswer(forceSkip: true);
    }
  }

  void _resetListeningTimer() {
    // Cancel existing timer if any
    _listeningTimer?.cancel();

    // Set a new timer
    _listeningTimer = Timer(const Duration(seconds: 90), () {
      _stopListening();
    });
  }

  void _updateMicrophoneLevel() {
    setState(() {
      _microphoneLevel = Random().nextDouble() * 0.8 + 0.2;
    });
  }

  Future<void> _stopListening() async {
    _listeningTimer?.cancel();

    if (_isListening) {
      // If speech recognition is initialized, stop it
      if (_speechService.isInitialized) {
        await _speechService.stopListening();
      }

      setState(() {
        _isListening = false;
        _showTranscript = false;
      });

      // Process the answer
      final answer = _finalTranscript.isNotEmpty
          ? _finalTranscript
          : _currentTranscript;

      // Check if the answer contains error messages
      final cleanAnswer =
          answer.contains("[Speech recognition unavailable") ||
              answer.contains("[Speech recognition error")
          ? ""
          : answer;

      if (cleanAnswer.isNotEmpty) {
        await _processAnswer(cleanAnswer);
      } else {
        // No answer provided, ask if they want to skip
        await _handleNoAnswer();
      }
    }
  }

  Future<void> _processAnswer(String answer) async {
    setState(() => _isProcessing = true);

    try {
      final question = _questions[_currentQuestionIndex];

      // Store user response
      _userResponses.add({
        'question_id': question.id,
        'question_text': question.questionText,
        'question_type': question.questionType,
        'user_answer': answer,
        'question_order': _currentQuestionIndex + 1,
        'response_duration': _listeningTimer?.tick ?? 0,
      });

      // Save response to database
      await _databaseService.saveResponse(
        sessionId: _currentSession!.id,
        questionId: question.id,
        userId: _currentSession!.userId,
        questionOrder: _currentQuestionIndex + 1,
        userResponse: answer,
        score: 0.0, // Will be calculated later
      );

      setState(() {
        _currentQuestionIndex++;
        _isProcessing = false;
      });

      // Ask next question or complete interview
      await Future.delayed(const Duration(milliseconds: 500));
      await _askNextQuestion();
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorDialog('Failed to process answer: $e');
    }
  }

  Future<void> _handleNoAnswer({bool forceSkip = false}) async {
    if (!forceSkip) {
      // Speak with a slower rate to sound more understanding
      await _speakText(
        'I didn\'t catch your answer. Let me give you a moment to think.',
        rate: 0.7,
      );

      // Add a pause to give the user time to think
      await Future.delayed(const Duration(seconds: 3));

      await _speakText(
        'Would you like me to repeat the question or shall we move to the next one? I\'ll wait a few seconds and then continue with the next question.',
        rate: 0.75,
      );

      // Add a longer pause to give the user time to respond
      await Future.delayed(const Duration(seconds: 5));
    }

    // Store an empty response
    if (_currentQuestionIndex < _questions.length) {
      final question = _questions[_currentQuestionIndex];

      // Add empty response to local list
      _userResponses.add({
        'question_id': question.id,
        'question_text': question.questionText,
        'question_type': question.questionType,
        'user_answer': '[No response provided]',
        'question_order': _currentQuestionIndex + 1,
        'response_duration': 0,
      });

      // Save empty response to database
      await _databaseService.saveResponse(
        sessionId: _currentSession!.id,
        questionId: question.id,
        userId: _currentSession!.userId,
        questionOrder: _currentQuestionIndex + 1,
        userResponse: '[No response provided]',
        score: 0.0,
      );
    }

    // Move to next question
    setState(() => _currentQuestionIndex++);
    await _askNextQuestion();
  }

  Future<void> _completeInterview() async {
    setState(() => _isInterviewEnded = true);
    _interviewTimer?.cancel();

    await _speakText(
      'Thank you for completing the interview! I\'m now analyzing your responses and will provide detailed feedback shortly.',
    );

    // Generate interview result
    await _generateInterviewResult();
  }

  Future<void> _generateInterviewResult() async {
    setState(() => _isProcessing = true);

    try {
      // For now, create a basic analysis since Gemini integration is complex
      // In a real implementation, you would analyze each response with AI
      final result = _createBasicAnalysis();

      // Save result to database
      await _databaseService.saveInterviewResult(
        sessionId: _currentSession!.id,
        result: result,
      );

      // Update session status
      await _databaseService.updateSessionStatus(
        _currentSession!.id,
        'completed',
      );

      setState(() => _isProcessing = false);

      // Navigate to results screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => InterviewResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorDialog('Failed to generate interview result: $e');
    }
  }

  InterviewResultModel _createBasicAnalysis() {
    // Calculate basic scores based on responses
    final overallScore = _userResponses.isNotEmpty ? 7.5 : 0.0;
    final technicalScore = 7.0;
    final communicationScore = 8.0;
    final problemSolvingScore = 7.5;
    final confidenceScore = 8.0;

    // Create question-answer pairs
    final questionAnswerPairs = _userResponses.map((response) {
      final question = _questions.firstWhere(
        (q) => q.id == response['question_id'],
        orElse: () => _questions.first,
      );

      return QuestionAnswerPair(
        questionId: response['question_id'],
        questionText: response['question_text'],
        userAnswer: response['user_answer'],
        idealAnswer:
            question.sampleAnswer ??
            'A comprehensive answer addressing the key points of the question.',
        feedback:
            'Good response! Consider adding more specific examples and technical details.',
        score: 7.5,
      );
    }).toList();

    // Use a proper UUID for the ID instead of a timestamp
    // This will be replaced by the database-generated UUID when saved
    return InterviewResultModel(
      id: const Uuid().v4(),
      interviewSessionId: _currentSession!.id,
      userId: _currentSession!.userId,
      jobRoleId: widget.jobRole.id,
      jobRoleTitle: widget.jobRole.title,
      overallScore: overallScore,
      technicalScore: technicalScore,
      communicationScore: communicationScore,
      problemSolvingScore: problemSolvingScore,
      confidenceScore: confidenceScore,
      strengthsAnalysis:
          'Strong communication skills and good understanding of core concepts. Shows enthusiasm and willingness to learn.',
      areasForImprovement:
          'Consider providing more specific examples and demonstrating deeper technical knowledge in certain areas.',
      aiSummary:
          'The candidate demonstrated good overall performance with strong communication skills. There are opportunities for improvement in technical depth and providing more concrete examples.',
      completedAt: DateTime.now(),
      createdAt: DateTime.now(),
      questionAnswerPairs: questionAnswerPairs,
    );
  }

  Future<void> _endInterview() async {
    final shouldEnd = await _showEndInterviewDialog();
    if (shouldEnd) {
      _interviewTimer?.cancel();
      _listeningTimer?.cancel();

      if (_isListening) {
        await _speechService.stopListening();
      }
      if (_isSpeaking) {
        await _ttsService.stop();
      }

      if (_userResponses.isNotEmpty) {
        await _generateInterviewResult();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool> _showEndInterviewDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text(
              'End Interview',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              _userResponses.isEmpty
                  ? 'Are you sure you want to end the interview? No answers have been recorded yet.'
                  : 'Are you sure you want to end the interview? You\'ve answered ${_userResponses.length} out of ${_questions.length} questions.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continue Interview'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('End Interview'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _interviewTimer?.cancel();
    _listeningTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _endInterview();
        }
      },
      child: Scaffold(
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
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildMainContent()),
                _buildBottomControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LIVE INTERVIEW',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            _formatDuration(_interviewDuration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20), // Reduced height
          _buildAIAvatar(),
          const SizedBox(height: 20), // Reduced height
          _buildInterviewStatus(),
          const SizedBox(height: 20), // Reduced height
          if (_showTranscript)
            Expanded(
              child: SingleChildScrollView(child: _buildTranscriptDisplay()),
            ),
        ],
      ),
    );
  }

  Widget _buildAIAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse animation
        if (_isSpeaking || _isListening)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isSpeaking
                          ? AppTheme.primaryColor.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),

        // Voice waves
        if (_isListening)
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + (_waveAnimation.value * 0.1 * (index + 1)),
                  child: Container(
                    width: 160 + (index * 20),
                    height: 160 + (index * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green.withOpacity(0.1 - (index * 0.02)),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

        // Main avatar
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _isProcessing ? _rotationAnimation.value : 0,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            );
          },
        ),

        // Microphone level indicator
        if (_isListening)
          Positioned(
            bottom: 10,
            child: Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.white.withOpacity(0.2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _microphoneLevel,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInterviewStatus() {
    String statusText;
    String subText;

    if (_isProcessing) {
      statusText = 'Processing...';
      subText = 'Analyzing your response';
    } else if (_isSpeaking) {
      statusText = 'AI is speaking';
      subText = 'Please listen carefully';
    } else if (_isListening) {
      statusText = 'Listening to your answer';
      subText = 'Speak clearly into your microphone';
    } else if (_isInterviewEnded) {
      statusText = 'Interview completed';
      subText = 'Generating your results...';
    } else if (!_isInterviewStarted) {
      statusText = 'Preparing interview';
      subText = 'Getting ready to start...';
    } else {
      statusText = 'Ready for next question';
      subText = 'Question ${_currentQuestionIndex + 1} of ${_questions.length}';
    }

    return Column(
      children: [
        Text(
          statusText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subText,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (_isInterviewStarted && !_isInterviewEnded)
          LinearProgressIndicator(
            value: _questions.isNotEmpty
                ? _currentQuestionIndex / _questions.length
                : 0,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
      ],
    );
  }

  Widget _buildTranscriptDisplay() {
    final displayText = _finalTranscript.isNotEmpty
        ? _finalTranscript
        : _currentTranscript;

    return Container(
      width: double.infinity,
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
              Icon(
                Icons.mic,
                color: _isListening ? Colors.green : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Answer:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayText.isEmpty ? 'Start speaking...' : displayText,
            style: TextStyle(
              color: displayText.isEmpty
                  ? Colors.white.withOpacity(0.4)
                  : Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Skip question button
          if (_isListening && _isInterviewStarted && !_isInterviewEnded)
            _buildControlButton(
              icon: Icons.skip_next,
              label: 'Skip',
              color: Colors.orange,
              onTap: () async {
                await _stopListening();
                setState(() => _currentQuestionIndex++);
                await _askNextQuestion();
              },
            ),

          // Stop listening button
          if (_isListening)
            _buildControlButton(
              icon: Icons.stop,
              label: 'Done',
              color: Colors.blue,
              onTap: _stopListening,
            ),

          // End interview button
          _buildControlButton(
            icon: Icons.call_end,
            label: 'End Call',
            color: Colors.red,
            onTap: _endInterview,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
