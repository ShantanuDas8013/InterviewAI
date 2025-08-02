# UUID Database Fix - Interview System

## Issue Description

The interview system was failing with the following error:

```
PostgrestException(message: invalid input syntax for type uuid: "q_1754155134987_0", code: 22P02, details: Bad Request, hint: null)
```

## Root Cause

The issue was caused by generating question IDs using timestamp-based strings like `"q_1754155134987_0"` instead of proper UUIDs. The database schema requires UUID format for foreign key relationships:

```sql
CREATE TABLE public.interview_responses (
  ...
  question_id UUID REFERENCES public.interview_questions(id) ON DELETE CASCADE,
  ...
);
```

## Problems Fixed

### 1. Question ID Generation

**Before (Incorrect):**

```dart
// In interview_screen.dart
id: 'q_${DateTime.now().millisecondsSinceEpoch}_$index',

// In interview_provider.dart
id: 'q_${const Uuid().v4()}',
```

**After (Correct):**

```dart
// Both files now use proper UUIDs
id: const Uuid().v4(),
```

### 2. InterviewResult ID Generation

**Before (Incorrect):**

```dart
id: DateTime.now().millisecondsSinceEpoch.toString(),
```

**After (Correct):**

```dart
id: const Uuid().v4(),
```

### 3. Database Integration Issue

**Problem:** Hardcoded questions were created locally but not saved to the database first, causing foreign key constraint violations when trying to save responses.

**Solution:** Modified the question generation process to:

1. Create temporary question objects locally
2. Save each question to the database using `DatabaseService.saveQuestion()`
3. Use the database-generated UUIDs for all subsequent operations

## Changes Made

### 1. DatabaseService Enhancement

Added new method in `database_service.dart`:

```dart
Future<String> saveQuestion({
  required String jobRoleId,
  required String questionText,
  required String questionType,
  required String difficultyLevel,
  List<String>? expectedAnswerKeywords,
  String? sampleAnswer,
  Map<String, dynamic>? evaluationCriteria,
  int? timeLimitSeconds,
}) async {
  // Saves question to database and returns the generated UUID
}
```

### 2. Question Generation Process

Updated both `interview_screen.dart` and `interview_provider.dart` to:

1. Generate temporary questions with local UUIDs
2. Save each question to the database
3. Replace local questions with database-saved versions (with proper UUIDs)
4. Use these database UUIDs for all response saving

### 3. Fixed Files

- `lib/features/5_interview/services/database_service.dart`
- `lib/features/5_interview/presentation/screens/interview_screen.dart`
- `lib/features/5_interview/logic/interview_provider.dart`

## Expected Behavior After Fix

1. ✅ Questions are properly saved to database with UUID primary keys
2. ✅ Interview responses can be saved with valid question_id foreign keys
3. ✅ No more UUID format errors during interview response saving
4. ✅ Proper database referential integrity maintained

## Testing

To verify the fix:

1. Start a new interview session
2. Answer a few questions
3. Check that no UUID errors appear in the logs
4. Verify that responses are successfully saved to the database

## Database Schema Compatibility

This fix maintains full compatibility with the existing database schema defined in:

- `SUPABASE_SETUP_GUIDE.md`
- `database_schema.md`

No database schema changes are required - only application code changes.

## Benefits

1. **Data Integrity:** Proper foreign key relationships maintained
2. **Scalability:** Questions can be reused across multiple interviews
3. **Consistency:** All IDs follow proper UUID format
4. **Database Compliance:** Follows PostgreSQL UUID standards
5. **Future-Proof:** Ready for AI-generated questions and advanced features

---

**Status:** ✅ **FIXED** - UUID format issues resolved, foreign key constraints satisfied.
