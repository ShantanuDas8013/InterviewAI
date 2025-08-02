# AI-Powered Interview Question Generation

## Overview

The AI Voice Interview App now uses Google's Gemini AI to dynamically generate professional, real-world interview questions instead of relying on hardcoded questions. This provides a more personalized and varied interview experience.

## How It Works

### 1. Dynamic Question Generation

- **AI-Powered**: Uses Google Gemini AI to generate contextual questions
- **Role-Specific**: Questions are tailored to specific job roles and their requirements
- **Intelligent Caching**: Generated questions are cached for performance while allowing fresh generation when needed
- **Fallback System**: Multiple layers of fallback ensure questions are always available

### 2. Question Types Generated

- **Technical Questions (40%)**: Role-specific technical knowledge and problem-solving
- **Behavioral Questions (30%)**: STAR method scenarios, leadership, teamwork
- **Situational Questions (20%)**: Hypothetical scenarios and decision-making
- **General Questions (10%)**: Motivation, career goals, company fit

### 3. Difficulty Levels

- **Easy**: Basic concepts, fundamental knowledge
- **Medium**: Practical application, moderate complexity
- **Hard**: Advanced scenarios, complex problem-solving

## Implementation Details

### Key Components

#### 1. GeminiService Enhancement

- **Location**: `lib/core/api/gemini_service.dart`
- **New Method**: `generateInterviewQuestions()`
- **Features**:
  - Retry mechanism for reliability
  - Error handling and validation
  - Token usage tracking
  - Response parsing and cleaning

#### 2. QuestionGenerationService

- **Location**: `lib/features/5_interview/services/question_generation_service.dart`
- **Features**:
  - Intelligent caching system
  - Database integration
  - Fallback question generation
  - Statistics tracking
  - Cache management

#### 3. Enhanced Interview Provider

- **Location**: `lib/features/5_interview/logic/interview_provider.dart`
- **Updates**:
  - Integration with AI question generation
  - Question regeneration capability
  - Statistics retrieval
  - Enhanced error handling

### Database Integration

#### New Table Usage

The system utilizes the existing `gemini_api_logs` table to track:

- API usage and performance
- Token consumption
- Request/response payloads
- Success/failure rates

#### Question Caching

Generated questions are stored in the `interview_questions` table with:

- Job role association
- Difficulty level categorization
- Active/inactive status for cache management
- Creation timestamps for freshness tracking

## Features

### 1. Smart Caching

- **Performance Optimization**: Cached questions for faster loading
- **Variety Control**: Can clear cache to get fresh questions
- **Statistics Tracking**: Monitor cache hit rates and question quality

### 2. Fallback System

1. **Primary**: AI-generated questions from Gemini
2. **Secondary**: Recently cached questions for the role
3. **Tertiary**: Category-based fallback questions
4. **Ultimate**: Basic generic interview questions

### 3. Question Quality

- **Industry-Relevant**: Questions match job requirements and industry standards
- **Real-World Scenarios**: Based on actual interview practices
- **Proper Difficulty**: Scaled according to experience level
- **Evaluation Criteria**: Each question includes assessment guidelines

## Usage Examples

### Basic Question Generation

```dart
final questionService = QuestionGenerationService();
final questions = await questionService.generateQuestionsForRole(
  jobRole: selectedJobRole,
  difficultyLevel: 'medium',
  questionCount: 10,
  useCache: true,
);
```

### Fresh Question Generation

```dart
// Clear cache and generate fresh questions
await questionService.clearCachedQuestions(jobRoleId);
final freshQuestions = await questionService.generateQuestionsForRole(
  jobRole: selectedJobRole,
  difficultyLevel: 'hard',
  questionCount: 8,
  useCache: false,
);
```

### Question Statistics

```dart
final stats = await questionService.getQuestionStats(jobRoleId);
print('Total cached questions: ${stats['total']}');
print('By difficulty: ${stats['by_difficulty']}');
print('By type: ${stats['by_type']}');
```

## Demo Screen

A demo screen has been created to test the question generation functionality:

- **Location**: `lib/question_generation_demo_screen.dart`
- **Route**: `/question-demo`
- **Features**:
  - Test different job roles
  - Adjust difficulty levels
  - Control question count
  - View generated questions with metadata
  - Real-time generation testing

## Configuration

### Environment Variables

Ensure your `.env` file includes:

```env
GEMINI_API_KEY=your_gemini_api_key_here
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### API Limits

- Monitor Gemini API usage through the logs table
- Implement rate limiting if needed
- Consider caching strategies for production use

## Benefits

### For Users

- **Fresh Content**: Never see the same questions repeatedly
- **Relevant Questions**: Job-specific and industry-appropriate
- **Realistic Practice**: Questions mirror real interview scenarios
- **Adaptive Difficulty**: Questions match experience level

### For Developers

- **Scalable**: Easy to add new job roles without manual question creation
- **Maintainable**: AI handles question updates and improvements
- **Trackable**: Comprehensive logging and analytics
- **Reliable**: Multiple fallback layers ensure system availability

## Monitoring and Analytics

### API Usage Tracking

The system logs all Gemini API calls with:

- Request/response payloads
- Processing time
- Token usage
- Success/failure status
- Error messages

### Question Quality Metrics

- Cache hit rates
- Question type distribution
- Difficulty level balance
- User feedback integration potential

## Future Enhancements

### Planned Features

1. **User Feedback Integration**: Learn from user ratings to improve question quality
2. **Interview Performance Analysis**: Correlate question types with user performance
3. **Adaptive Questioning**: Adjust difficulty based on user responses
4. **Role-Specific Customization**: Fine-tune prompts for specific industries
5. **Multi-language Support**: Generate questions in different languages

### Potential Improvements

1. **Question Templates**: Pre-defined structures for consistent quality
2. **Industry Benchmarking**: Compare questions against industry standards
3. **A/B Testing**: Test different question generation approaches
4. **Performance Optimization**: Further caching and optimization strategies

## Troubleshooting

### Common Issues

1. **API Key Errors**: Ensure GEMINI_API_KEY is correctly set
2. **Generation Failures**: Check internet connectivity and API limits
3. **Empty Results**: Verify job role data and required skills
4. **Cache Issues**: Clear cache if questions seem outdated

### Debug Information

Enable debug logging to see:

- Generation attempts and retries
- Cache hit/miss information
- API response details
- Error stack traces

## Security Considerations

### Data Privacy

- User data is not sent to Gemini API
- Only job role information is used for generation
- API logs can be configured for retention policies

### API Security

- API keys are stored securely in environment variables
- Request/response logging for audit trails
- Error handling prevents sensitive information leakage

## Performance Considerations

### Optimization Strategies

1. **Intelligent Caching**: Balance freshness with performance
2. **Batch Generation**: Generate multiple questions in single API calls
3. **Background Processing**: Pre-generate questions for popular roles
4. **Rate Limiting**: Prevent API quota exhaustion

### Monitoring

- Track API response times
- Monitor cache hit rates
- Measure user experience impact
- Alert on generation failures

This AI-powered question generation system provides a significant upgrade to the interview experience, offering dynamic, relevant, and high-quality questions that adapt to each user's specific role and requirements.
