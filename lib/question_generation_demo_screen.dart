import 'package:flutter/material.dart';
import '../features/5_interview/data/models/job_role_model.dart';
import '../features/5_interview/services/question_generation_service.dart';
import '../core/constants/theme.dart';

class QuestionGenerationDemoScreen extends StatefulWidget {
  const QuestionGenerationDemoScreen({super.key});

  @override
  State<QuestionGenerationDemoScreen> createState() =>
      _QuestionGenerationDemoScreenState();
}

class _QuestionGenerationDemoScreenState
    extends State<QuestionGenerationDemoScreen> {
  final QuestionGenerationService _questionService =
      QuestionGenerationService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _generatedQuestions = [];
  String _selectedDifficulty = 'medium';
  int _questionCount = 5;

  // Sample job roles for testing
  final List<JobRoleModel> _sampleJobRoles = [
    JobRoleModel(
      id: 'test-1',
      title: 'Senior Flutter Developer',
      category: 'Technology',
      description:
          'Develop cross-platform mobile applications using Flutter framework',
      requiredSkills: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Git'],
      experienceLevels: ['Senior'],
      industry: 'Technology',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    JobRoleModel(
      id: 'test-2',
      title: 'Product Manager',
      category: 'Management',
      description: 'Lead product development and strategy',
      requiredSkills: [
        'Product Strategy',
        'Agile',
        'Data Analysis',
        'Communication',
      ],
      experienceLevels: ['Mid-level', 'Senior'],
      industry: 'Technology',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    JobRoleModel(
      id: 'test-3',
      title: 'Digital Marketing Specialist',
      category: 'Marketing',
      description: 'Execute digital marketing campaigns and strategies',
      requiredSkills: [
        'SEO',
        'Google Analytics',
        'Social Media',
        'Content Marketing',
      ],
      experienceLevels: ['Junior', 'Mid-level'],
      industry: 'Marketing',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  JobRoleModel? _selectedJobRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Question Generation Demo'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Job Role',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<JobRoleModel>(
                      value: _selectedJobRole,
                      hint: const Text('Choose a job role'),
                      isExpanded: true,
                      items: _sampleJobRoles.map((role) {
                        return DropdownMenuItem<JobRoleModel>(
                          value: role,
                          child: Text('${role.title} (${role.category})'),
                        );
                      }).toList(),
                      onChanged: (JobRoleModel? role) {
                        setState(() {
                          _selectedJobRole = role;
                          _generatedQuestions.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Difficulty Level'),
                              DropdownButton<String>(
                                value: _selectedDifficulty,
                                items: ['easy', 'medium', 'hard'].map((level) {
                                  return DropdownMenuItem<String>(
                                    value: level,
                                    child: Text(level.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (String? level) {
                                  setState(() {
                                    _selectedDifficulty = level ?? 'medium';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Number of Questions'),
                              DropdownButton<int>(
                                value: _questionCount,
                                items: [3, 5, 8, 10].map((count) {
                                  return DropdownMenuItem<int>(
                                    value: count,
                                    child: Text(count.toString()),
                                  );
                                }).toList(),
                                onChanged: (int? count) {
                                  setState(() {
                                    _questionCount = count ?? 5;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedJobRole == null || _isLoading
                            ? null
                            : _generateQuestions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Generating Questions...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )
                            : const Text(
                                'Generate Questions',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_generatedQuestions.isNotEmpty) ...[
              const Text(
                'Generated Interview Questions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _generatedQuestions.length,
                  itemBuilder: (context, index) {
                    final question = _generatedQuestions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(
                                      question['questionType'],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    question['questionType']
                                            ?.toString()
                                            .toUpperCase() ??
                                        'GENERAL',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(
                                      question['difficultyLevel'],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    question['difficultyLevel']
                                            ?.toString()
                                            .toUpperCase() ??
                                        'MEDIUM',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Q${index + 1}: ${question['questionText']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (question['expectedAnswerKeywords'] != null &&
                                question['expectedAnswerKeywords']
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children:
                                    (question['expectedAnswerKeywords'] as List)
                                        .map(
                                          (keyword) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              keyword.toString(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Time Limit: ${question['timeLimitSeconds'] ?? 120} seconds',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateQuestions() async {
    if (_selectedJobRole == null) return;

    setState(() {
      _isLoading = true;
      _generatedQuestions.clear();
    });

    try {
      final questions = await _questionService.generateQuestionsForRole(
        jobRole: _selectedJobRole!,
        difficultyLevel: _selectedDifficulty,
        questionCount: _questionCount,
        useCache: false, // Always generate fresh questions in demo
      );

      setState(() {
        _generatedQuestions = questions.map((q) => q.toJson()).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generated ${questions.length} questions successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating questions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'technical':
        return Colors.blue;
      case 'behavioral':
        return Colors.green;
      case 'situational':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
