# Before & After: Critical Code Changes

## 1. AssemblyAI Service Fix

### ❌ BEFORE (Line 193-195 - BROKEN)

```dart
'content_safety': true, // Enable content safety detection
'content_safety_confidence': 60, // Confidence threshold (0-100)
```

**Problem:** This causes a `400 Bad Request` error. AssemblyAI doesn't accept these parameters in this format.

### ✅ AFTER (FIXED)

```dart
'content_safety_labels': {
  'confidence_threshold': 0.6
}, // Content safety detection with confidence
```

**Why:** AssemblyAI API requires content safety as a nested object with `confidence_threshold` as a decimal (0.0-1.0).

---

## 2. Interview Screen - Answer Processing

### ❌ BEFORE (BROKEN - saves to wrong table)

```dart
Future<void> _processAnswer(String answer) async {
  setState(() => _isProcessing = true);

  try {
    final question = _questions[_currentQuestionIndex];

    // WRONG: Saves to interview_responses table (doesn't exist)
    await _databaseService.saveResponse(
      sessionId: _currentSession!.id,
      questionId: question.id,
      userId: _currentSession!.userId,
      questionOrder: _currentQuestionIndex + 1,
      userResponse: answer,
      score: 0.0,
    );

    setState(() {
      _currentQuestionIndex++;
      _isProcessing = false;
    });

    await _askNextQuestion();
  } catch (e) {
    setState(() => _isProcessing = false);
    _showErrorDialog('Failed to save your answer: $e');
  }
}
```

### ✅ AFTER (FIXED - saves to correct table)

```dart
Future<void> _processAnswer(String answer) async {
  setState(() => _isProcessing = true);

  try {
    final question = _questions[_currentQuestionIndex];

    // Get an instance of InterviewRepository
    final interviewRepository = InterviewRepository();

    // CORRECT: Save to interview_answers table
    await interviewRepository.saveAnswer(
      sessionId: _currentSession!.id,
      questionId: question.id,
      answerText: answer,
    );

    // Update session questions answered count
    await _databaseService.updateQuestionsAnswered(
      _currentSession!.id,
      _currentQuestionIndex + 1,
    );

    debugPrint(
      'Answer saved successfully for question ${_currentQuestionIndex + 1}',
    );

    setState(() {
      _currentQuestionIndex++;
      _isProcessing = false;
    });

    // Ask the next question
    await Future.delayed(const Duration(milliseconds: 500));
    await _askNextQuestion();
  } catch (e) {
    setState(() => _isProcessing = false);
    _showErrorDialog('Failed to save your answer: $e');
  }
}
```

**Key Changes:**

- Uses `InterviewRepository.saveAnswer()` instead of `DatabaseService.saveResponse()`
- Saves to `interview_answers` table (correct schema)
- Tracks questions answered count
- Added debug logging

---

## 3. Interview Result Screen - Data Loading

### ❌ BEFORE (BROKEN - incomplete orchestration)

```dart
Future<void> _loadInterviewData() async {
  try {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // PROBLEM 1: Just fetches existing results, doesn't generate new ones
    final resultData = await _fetchInterviewResult();

    // PROBLEM 2: Fetches from wrong table (interview_responses)
    final responseData = await _fetchQuestionResponses();

    setState(() {
      _interviewResult = resultData;
      _questionResponses = responseData;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _error = e.toString();
      _isLoading = false;
    });
  }
}
```

### ✅ AFTER (FIXED - complete orchestration)

```dart
Future<void> _loadInterviewData() async {
  try {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Get an instance of the repository
    final interviewRepository = InterviewRepository();

    // 1. Fetch the full interview transcript from interview_answers
    final transcript = await interviewRepository.getInterviewTranscript(
      widget.interviewSessionId,
    );

    // 2. Fetch job role title and ID from the session
    final sessionData = await Supabase.instance.client
        .from('interview_sessions')
        .select('job_role_id, job_role:job_roles(title)')
        .eq('id', widget.interviewSessionId)
        .single();
    final jobTitle = sessionData['job_role']['title'] as String;
    final jobRoleId = sessionData['job_role_id'] as String;

    // 3. Get the summary from Gemini (HOLISTIC EVALUATION)
    final summaryData = await _geminiService.getInterviewSummary(
      transcript: transcript,
      jobTitle: jobTitle,
    );

    // 4. Save the summary to the interview_results table
    await Supabase.instance.client.from('interview_results').insert({
      'interview_session_id': widget.interviewSessionId,
      'user_id': Supabase.instance.client.auth.currentUser!.id,
      'job_role_id': jobRoleId,
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
```

**Key Changes:**

1. Fetches transcript from `interview_answers` table
2. Retrieves both `job_role_id` and title
3. Calls Gemini to generate holistic summary
4. Saves complete results to database
5. Then displays the results

---

## 4. Interview Result Screen - Fetching Responses

### ❌ BEFORE (BROKEN - wrong table)

```dart
Future<List<QuestionResponseData>> _fetchQuestionResponses() async {
  try {
    // WRONG: Queries interview_responses table (doesn't exist in your schema)
    final response = await Supabase.instance.client
        .from('interview_responses')
        .select('''
          *,
          interview_questions!inner(...)
        ''')
        .eq('interview_session_id', widget.interviewSessionId)
        .order('question_order');

    // Complex processing for per-question evaluation...
    return questionResponses;
  } catch (e) {
    return [];
  }
}
```

### ✅ AFTER (FIXED - correct table)

```dart
Future<List<QuestionResponseData>> _fetchQuestionResponses() async {
  try {
    // CORRECT: Queries interview_answers table
    final response = await Supabase.instance.client
        .from('interview_answers')
        .select('''
          *,
          question:interview_questions(
            question_text,
            question_type,
            difficulty_level,
            sample_answer,
            expected_answer_keywords
          )
        ''')
        .eq('session_id', widget.interviewSessionId)
        .order('created_at');

    final List<QuestionResponseData> questionResponses = [];
    int questionOrder = 1;

    for (final answerData in response) {
      final questionData = answerData['question'];

      // Simple mapping - detailed evaluation comes from holistic summary
      questionResponses.add(
        QuestionResponseData(
          questionId: answerData['question_id'],
          questionText: questionData['question_text'],
          questionType: questionData['question_type'],
          difficultyLevel: questionData['difficulty_level'],
          userAnswer: answerData['answer_text'] ?? '',
          audioFileUrl: null,
          responseScore: 0.0,
          aiFeedback: 'Evaluated as part of the complete interview summary.',
          idealAnswerComparison: questionData['sample_answer'] ?? 'No ideal answer available',
          suggestedImprovement: 'See overall interview feedback for improvement suggestions',
          technicalAccuracy: 0.0,
          communicationClarity: 0.0,
          relevanceScore: 0.0,
          keywordsMentioned: [],
          missingKeywords: [],
          confidenceLevel: 0.0,
          questionOrder: questionOrder++,
        ),
      );
    }

    return questionResponses;
  } catch (e) {
    debugPrint('Error fetching question responses: $e');
    return [];
  }
}
```

**Key Changes:**

- Changed table from `interview_responses` to `interview_answers`
- Updated column names (`interview_session_id` → `session_id`)
- Simplified data mapping since holistic evaluation provides the detailed feedback
- Order by `created_at` instead of non-existent `question_order`

---

## Summary of Workflow Changes

### ❌ OLD WORKFLOW (BROKEN)

```
1. Record audio
2. Transcribe with AssemblyAI ❌ (400 error)
3. Save to interview_responses ❌ (table doesn't exist)
4. Evaluate each answer individually
5. Show results (no holistic summary)
```

### ✅ NEW WORKFLOW (FIXED)

```
1. Record audio
2. Transcribe with AssemblyAI ✅ (works)
3. Save to interview_answers ✅ (correct table)
4. After all questions:
   a. Fetch complete transcript
   b. Send to Gemini for holistic evaluation ✅
   c. Save to interview_results ✅
5. Show comprehensive results with AI summary
```

---

## Database Schema Alignment

### Tables Used (Correct Implementation)

**interview_answers** (stores raw answers)

```sql
CREATE TABLE interview_answers (
  id UUID PRIMARY KEY,
  session_id UUID REFERENCES interview_sessions,
  question_id UUID REFERENCES interview_questions,
  answer_text TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**interview_results** (stores final evaluation)

```sql
CREATE TABLE interview_results (
  id UUID PRIMARY KEY,
  interview_session_id UUID REFERENCES interview_sessions,
  user_id UUID,
  job_role_id UUID REFERENCES job_roles,
  job_role_title TEXT,
  overall_score NUMERIC,
  technical_score NUMERIC,
  communication_score NUMERIC,
  problem_solving_score NUMERIC,
  confidence_score NUMERIC,
  strengths_analysis TEXT[],
  areas_for_improvement TEXT[],
  ai_summary TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## Key Takeaways

1. **AssemblyAI API** - Fixed parameter format for content safety
2. **Data Storage** - Changed from `interview_responses` (non-existent) to `interview_answers` (correct)
3. **Evaluation Strategy** - Changed from per-question to holistic batch evaluation
4. **Result Generation** - Now generates results on result screen load, not during interview
5. **Database Alignment** - All queries now match your actual database schema

All fixes ensure the application follows the intended workflow: **Record → Transcribe → Store → Batch Evaluate → Display Summary**.
