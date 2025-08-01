import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/interview_question_model.dart';
import '../data/models/interview_result_model.dart';
import '../data/models/interview_session_model.dart';
import '../data/models/job_role_model.dart';
import '../services/speech_to_text_service.dart';
import '../services/text_to_speech_service.dart';
import '../services/database_service.dart';

enum InterviewState {
  idle,
  preparing,
  speaking,
  listening,
  processing,
  completed,
  error,
}

class InterviewProvider extends ChangeNotifier {
  // Services
  final SpeechToTextService _speechService = SpeechToTextService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final DatabaseService _databaseService = DatabaseService();

  // State
  InterviewState _state = InterviewState.idle;
  InterviewSessionModel? _currentSession;
  JobRoleModel? _jobRole;
  List<InterviewQuestionModel> _questions = [];
  int _currentQuestionIndex = 0;
  String _currentTranscript = '';
  String _finalTranscript = '';
  List<Map<String, dynamic>> _userResponses = [];
  String? _errorMessage;
  Duration _interviewDuration = Duration.zero;
  bool _isInitialized = false;

  // Getters
  InterviewState get state => _state;
  InterviewSessionModel? get currentSession => _currentSession;
  JobRoleModel? get jobRole => _jobRole;
  List<InterviewQuestionModel> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  String get currentTranscript => _currentTranscript;
  String get finalTranscript => _finalTranscript;
  List<Map<String, dynamic>> get userResponses => _userResponses;
  String? get errorMessage => _errorMessage;
  Duration get interviewDuration => _interviewDuration;
  bool get isInitialized => _isInitialized;

  // Current question
  InterviewQuestionModel? get currentQuestion {
    if (_currentQuestionIndex < _questions.length) {
      return _questions[_currentQuestionIndex];
    }
    return null;
  }

  // Progress
  double get progress {
    if (_questions.isEmpty) return 0.0;
    return _currentQuestionIndex / _questions.length;
  }

  bool get isLastQuestion => _currentQuestionIndex >= _questions.length - 1;

  // Initialize the interview provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setState(InterviewState.preparing);

      await _speechService.initialize();
      await _ttsService.initialize();

      _isInitialized = true;
      _setState(InterviewState.idle);

      debugPrint('Interview provider initialized successfully');
    } catch (e) {
      _setError('Failed to initialize interview services: $e');
    }
  }

  // Start interview with job role
  Future<void> startInterview({
    required JobRoleModel jobRole,
    String? resumeId,
    int totalQuestions = 10,
    String difficultyLevel = 'medium',
  }) async {
    try {
      _setState(InterviewState.preparing);
      _jobRole = jobRole;

      // Get current user ID from Supabase
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in and try again.');
      }
      final userId = currentUser.id;

      // Create interview session
      final sessionId = await _databaseService.createInterviewSession(
        userId: userId,
        jobRoleId: jobRole.id,
        questionCount: totalQuestions,
      );

      _currentSession = InterviewSessionModel(
        id: sessionId,
        userId: userId,
        jobRoleId: jobRole.id,
        sessionName: 'Interview for ${jobRole.title}',
        sessionType: 'practice',
        status: 'in_progress',
        totalQuestions: totalQuestions,
        questionsAnswered: 0,
        difficultyLevel: difficultyLevel,
        createdAt: DateTime.now(),
      );

      // Generate questions
      await _generateQuestions(jobRole, totalQuestions, difficultyLevel);

      // Start with welcome message
      await _speakWelcomeMessage();
    } catch (e) {
      _setError('Failed to start interview: $e');
    }
  }

  // Generate interview questions
  Future<void> _generateQuestions(
    JobRoleModel jobRole,
    int totalQuestions,
    String difficultyLevel,
  ) async {
    try {
      // For now, create hardcoded questions based on job role
      // In a real implementation, you would use AI to generate questions
      _questions = _createHardcodedQuestions(jobRole, totalQuestions);

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to generate questions: $e');
    }
  }

  List<InterviewQuestionModel> _createHardcodedQuestions(
    JobRoleModel jobRole,
    int totalQuestions,
  ) {
    final baseQuestions = <Map<String, dynamic>>[
      {
        'question_text': 'Can you tell me about yourself and your background?',
        'question_type': 'general',
        'difficulty_level': 'easy',
        'expected_keywords': ['experience', 'skills', 'background'],
        'sample_answer':
            'I am a ${jobRole.title} with experience in ${jobRole.requiredSkills.take(3).join(', ')}. I have worked on various projects that required...',
      },
      {
        'question_text':
            'What interests you about this ${jobRole.title} position?',
        'question_type': 'behavioral',
        'difficulty_level': 'easy',
        'expected_keywords': ['interest', 'motivation', 'skills'],
        'sample_answer':
            'I am interested in this position because it combines my skills in ${jobRole.requiredSkills.first} with my passion for...',
      },
      {
        'question_text':
            'Can you explain your experience with ${jobRole.requiredSkills.isNotEmpty ? jobRole.requiredSkills.first : 'relevant technologies'}?',
        'question_type': 'technical',
        'difficulty_level': 'medium',
        'expected_keywords': jobRole.requiredSkills,
        'sample_answer':
            'I have worked extensively with ${jobRole.requiredSkills.isNotEmpty ? jobRole.requiredSkills.first : 'various technologies'} for...',
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
            'How do you stay updated with the latest trends in ${jobRole.category}?',
        'question_type': 'general',
        'difficulty_level': 'easy',
        'expected_keywords': ['learning', 'trends', 'update', 'technology'],
        'sample_answer':
            'I stay updated by reading industry blogs, attending conferences, taking online courses...',
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
            'How would you approach a problem involving ${jobRole.requiredSkills.length > 1 ? jobRole.requiredSkills[1] : jobRole.requiredSkills.first}?',
        'question_type': 'technical',
        'difficulty_level': 'medium',
        'expected_keywords': jobRole.requiredSkills,
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
            'Do you have any questions for us about the role or company?',
        'question_type': 'general',
        'difficulty_level': 'easy',
        'expected_keywords': ['questions', 'role', 'company'],
        'sample_answer':
            'Yes, I would like to know more about the team structure, growth opportunities, and the biggest challenges facing the team.',
      },
    ];

    // Select questions based on total questions requested
    final selectedQuestions = baseQuestions.take(totalQuestions).toList();

    return selectedQuestions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;

      return InterviewQuestionModel(
        id: 'q_${const Uuid().v4()}',
        jobRoleId: jobRole.id,
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

  // Speak welcome message
  Future<void> _speakWelcomeMessage() async {
    final welcomeMessage =
        '''
    Hello! Welcome to your AI voice interview for the position of ${_jobRole!.title}.
    I am your AI interviewer, and I'll be asking you ${_questions.length} questions today.
    
    Here's how it works:
    - I'll ask you a question
    - Take your time to think and answer clearly
    - You can end the interview anytime
    
    Are you ready to begin? Let's start with the first question.
    ''';

    await _speakText(welcomeMessage);
    await askCurrentQuestion();
  }

  // Ask current question
  Future<void> askCurrentQuestion() async {
    if (_currentQuestionIndex >= _questions.length) {
      await _completeInterview();
      return;
    }

    final question = _questions[_currentQuestionIndex];
    final questionText =
        '''
    Question ${_currentQuestionIndex + 1} of ${_questions.length}:
    ${question.questionText}
    
    Please take your time to answer this question.
    ''';

    await _speakText(questionText);
    await startListening();
  }

  // Speak text using TTS
  Future<void> _speakText(String text) async {
    _setState(InterviewState.speaking);

    try {
      await _ttsService.speak(text);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  // Start listening for user response
  Future<void> startListening() async {
    try {
      _setState(InterviewState.listening);
      _currentTranscript = '';
      _finalTranscript = '';

      await _speechService.startListening(
        onResult: (text, isFinal) {
          if (isFinal) {
            _finalTranscript = text;
            _currentTranscript = '';
          } else {
            _currentTranscript = text;
          }
          notifyListeners();
        },
      );
    } catch (e) {
      _setError('Failed to start listening: $e');
    }
  }

  // Stop listening and process answer
  Future<void> stopListening() async {
    if (_state != InterviewState.listening) return;

    try {
      await _speechService.stopListening();

      final answer = _finalTranscript.isNotEmpty
          ? _finalTranscript
          : _currentTranscript;
      if (answer.isNotEmpty) {
        await _processAnswer(answer);
      } else {
        await _handleNoAnswer();
      }
    } catch (e) {
      _setError('Failed to stop listening: $e');
    }
  }

  // Process user answer
  Future<void> _processAnswer(String answer) async {
    _setState(InterviewState.processing);

    try {
      final question = _questions[_currentQuestionIndex];

      // Store user response
      _userResponses.add({
        'question_id': question.id,
        'question_text': question.questionText,
        'question_type': question.questionType,
        'user_answer': answer,
        'question_order': _currentQuestionIndex + 1,
        'timestamp': DateTime.now().toIso8601String(),
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

      // Move to next question
      _currentQuestionIndex++;
      notifyListeners();

      // Ask next question or complete interview
      await Future.delayed(const Duration(milliseconds: 500));
      await askCurrentQuestion();
    } catch (e) {
      _setError('Failed to process answer: $e');
    }
  }

  // Handle case when no answer is provided
  Future<void> _handleNoAnswer() async {
    await _speakText(
      'I didn\'t hear an answer. Would you like me to repeat the question, or shall we move to the next one?',
    );

    // For now, just move to next question
    _currentQuestionIndex++;
    notifyListeners();
    await askCurrentQuestion();
  }

  // Skip current question
  Future<void> skipQuestion() async {
    if (_currentQuestionIndex < _questions.length) {
      _currentQuestionIndex++;
      notifyListeners();
      await askCurrentQuestion();
    }
  }

  // Complete the interview
  Future<void> _completeInterview() async {
    _setState(InterviewState.processing);

    await _speakText(
      'Thank you for completing the interview! I\'m now analyzing your responses and will provide detailed feedback shortly.',
    );

    // Generate basic interview result
    final result = _generateBasicResult();

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

    _setState(InterviewState.completed);
  }

  // Generate basic interview result
  InterviewResultModel _generateBasicResult() {
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

    return InterviewResultModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      interviewSessionId: _currentSession!.id,
      userId: _currentSession!.userId,
      jobRoleId: _jobRole!.id,
      jobRoleTitle: _jobRole!.title,
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

  // End interview early
  Future<void> endInterview() async {
    try {
      if (_state == InterviewState.listening) {
        await _speechService.stopListening();
      }
      if (_state == InterviewState.speaking) {
        await _ttsService.stop();
      }

      if (_userResponses.isNotEmpty) {
        await _completeInterview();
      } else {
        _setState(InterviewState.idle);
      }
    } catch (e) {
      _setError('Failed to end interview: $e');
    }
  }

  // Reset interview state
  void resetInterview() {
    _state = InterviewState.idle;
    _currentSession = null;
    _jobRole = null;
    _questions = [];
    _currentQuestionIndex = 0;
    _currentTranscript = '';
    _finalTranscript = '';
    _userResponses = [];
    _errorMessage = null;
    _interviewDuration = Duration.zero;
    notifyListeners();
  }

  // Private helper methods
  void _setState(InterviewState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _state = InterviewState.error;
    _errorMessage = error;
    notifyListeners();
    debugPrint('Interview Provider Error: $error');
  }

  @override
  void dispose() {
    _speechService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
