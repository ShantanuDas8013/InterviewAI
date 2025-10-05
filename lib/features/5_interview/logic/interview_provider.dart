import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/interview_question_model.dart';
import '../data/models/interview_session_model.dart';
import '../data/models/job_role_model.dart';
import '../services/assembly_ai_service.dart';
import '../services/audio_recording_service.dart';
import '../services/text_to_speech_service.dart';
import '../services/database_service.dart';
import '../services/question_generation_service.dart';

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
  final AssemblyAiService _transcriptionService = AssemblyAiService();
  final AudioRecordingService _audioService = AudioRecordingService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final DatabaseService _databaseService = DatabaseService();
  final QuestionGenerationService _questionGenerationService =
      QuestionGenerationService();

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

      await _transcriptionService.initialize();
      await _audioService.initialize();
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
    int totalQuestions = 5,
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

  // Generate interview questions using AI
  Future<void> _generateQuestions(
    JobRoleModel jobRole,
    int totalQuestions,
    String difficultyLevel,
  ) async {
    try {
      debugPrint(
        'Generating questions for ${jobRole.title} - $totalQuestions questions at $difficultyLevel level',
      );

      // Use the AI-powered question generation service
      _questions = await _questionGenerationService.generateQuestionsForRole(
        jobRole: jobRole,
        difficultyLevel: difficultyLevel,
        questionCount: totalQuestions,
        experienceLevel: difficultyLevel == 'easy'
            ? 'Junior'
            : difficultyLevel == 'hard'
            ? 'Senior'
            : 'Mid-level',
        useCache:
            true, // Use cached questions when available for better performance
      );

      debugPrint('Successfully generated ${_questions.length} questions');

      if (_questions.isEmpty) {
        throw Exception('No questions could be generated for this role');
      }

      _currentQuestionIndex = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error generating questions: $e');

      // Fallback to basic questions if AI generation fails
      _questions = _generateBasicFallbackQuestions(
        jobRole,
        totalQuestions,
        difficultyLevel,
      );
      _currentQuestionIndex = 0;
      notifyListeners();

      if (_questions.isEmpty) {
        throw Exception('Failed to generate interview questions: $e');
      }
    }
  }

  // Fallback questions when AI generation completely fails
  List<InterviewQuestionModel> _generateBasicFallbackQuestions(
    JobRoleModel jobRole,
    int totalQuestions,
    String difficultyLevel,
  ) {
    const uuid = Uuid();
    final List<InterviewQuestionModel> fallbackQuestions = [
      InterviewQuestionModel(
        id: uuid.v4(),
        jobRoleId: jobRole.id,
        questionText: 'Tell me about yourself and your background.',
        questionType: 'general',
        difficultyLevel: difficultyLevel,
        expectedAnswerKeywords: [
          'background',
          'experience',
          'skills',
          'passion',
        ],
        timeLimitSeconds: 120,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      InterviewQuestionModel(
        id: uuid.v4(),
        jobRoleId: jobRole.id,
        questionText:
            'Why are you interested in this ${jobRole.title} position?',
        questionType: 'general',
        difficultyLevel: difficultyLevel,
        expectedAnswerKeywords: [
          'motivation',
          'interest',
          'career goals',
          'company',
        ],
        timeLimitSeconds: 120,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      InterviewQuestionModel(
        id: uuid.v4(),
        jobRoleId: jobRole.id,
        questionText:
            'Describe a challenging situation you faced and how you handled it.',
        questionType: 'behavioral',
        difficultyLevel: difficultyLevel,
        expectedAnswerKeywords: [
          'challenge',
          'problem-solving',
          'solution',
          'result',
        ],
        timeLimitSeconds: 180,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      InterviewQuestionModel(
        id: uuid.v4(),
        jobRoleId: jobRole.id,
        questionText:
            'What are your strengths and how do they relate to this role?',
        questionType: 'general',
        difficultyLevel: difficultyLevel,
        expectedAnswerKeywords: [
          'strengths',
          'skills',
          'relevance',
          'examples',
        ],
        timeLimitSeconds: 120,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      InterviewQuestionModel(
        id: uuid.v4(),
        jobRoleId: jobRole.id,
        questionText: 'Where do you see yourself in 5 years?',
        questionType: 'general',
        difficultyLevel: difficultyLevel,
        expectedAnswerKeywords: ['career goals', 'growth', 'ambition', 'plan'],
        timeLimitSeconds: 120,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    return fallbackQuestions.take(totalQuestions).toList();
  }

  // Regenerate questions with fresh AI content
  Future<void> regenerateQuestions({bool clearCache = true}) async {
    if (_jobRole == null) {
      _setError('No job role selected');
      return;
    }

    try {
      _setState(InterviewState.preparing);

      if (clearCache) {
        // Clear cached questions for this role to get fresh AI-generated questions
        await _questionGenerationService.clearCachedQuestions(_jobRole!.id);
      }

      // Generate new questions
      await _generateQuestions(
        _jobRole!,
        _currentSession?.totalQuestions ?? 5,
        _currentSession?.difficultyLevel ?? 'medium',
      );

      // Reset to first question
      _currentQuestionIndex = 0;

      _setState(InterviewState.idle);
      debugPrint('Questions regenerated successfully');
    } catch (e) {
      _setError('Failed to regenerate questions: $e');
    }
  }

  // Get statistics about generated questions
  Future<Map<String, dynamic>> getQuestionStatistics() async {
    if (_jobRole == null) return {};

    try {
      return await _questionGenerationService.getQuestionStats(_jobRole!.id);
    } catch (e) {
      debugPrint('Error getting question statistics: $e');
      return {};
    }
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

      // Start audio recording for AssemblyAI transcription
      final recordingPath = await _audioService.startRecording();
      if (recordingPath == null) {
        throw Exception('Failed to start audio recording');
      }
    } catch (e) {
      _setError('Failed to start listening: $e');
    }
  }

  // Stop listening and process answer
  Future<void> stopListening() async {
    if (_state != InterviewState.listening) return;

    try {
      _setState(InterviewState.processing);

      // Stop audio recording and get the recorded file path
      final recordingPath = await _audioService.stopRecording();

      if (recordingPath != null) {
        // Transcribe the audio using AssemblyAI
        final transcribedText = await _transcriptionService.transcribeAudio(
          recordingPath,
        );
        _finalTranscript = transcribedText;

        if (_finalTranscript.isNotEmpty) {
          await _processAnswer(_finalTranscript);
        } else {
          await _handleNoAnswer();
        }
      } else {
        await _handleNoAnswer();
      }
    } catch (e) {
      _setError('Failed to process audio: $e');
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

    // Update session status to completed
    await _databaseService.updateSessionStatus(
      _currentSession!.id,
      'completed',
    );

    _setState(InterviewState.completed);
  }

  // End interview early
  Future<void> endInterview() async {
    try {
      if (_state == InterviewState.listening) {
        await _audioService.cancelRecording();
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
    _audioService.dispose();
    _transcriptionService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
