import 'package:flutter/material.dart';
import '../features/5_interview/presentation/screens/interview_screen.dart';
import '../features/5_interview/presentation/screens/interview_setup_screen.dart';
import '../features/5_interview/data/models/job_role_model.dart';
import '../core/constants/theme.dart';

class InterviewDemoScreen extends StatelessWidget {
  const InterviewDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        title: const Text(
          'Interview Demo',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Voice Interview Demo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Test the AI-powered voice interview system with different job roles.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Interview Setup Button
                _buildDemoCard(
                  title: 'Interview Setup',
                  description:
                      'Configure your interview preferences and select a job role',
                  icon: Icons.settings,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const InterviewSetupScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Quick Demo Buttons for different roles
                _buildDemoCard(
                  title: 'Frontend Developer Interview',
                  description:
                      'Direct interview for Frontend Developer position',
                  icon: Icons.web,
                  onTap: () =>
                      _startQuickInterview(context, _createFrontendJobRole()),
                ),

                const SizedBox(height: 16),

                _buildDemoCard(
                  title: 'Backend Developer Interview',
                  description:
                      'Direct interview for Backend Developer position',
                  icon: Icons.storage,
                  onTap: () =>
                      _startQuickInterview(context, _createBackendJobRole()),
                ),

                const SizedBox(height: 16),

                _buildDemoCard(
                  title: 'Data Scientist Interview',
                  description: 'Direct interview for Data Scientist position',
                  icon: Icons.analytics,
                  onTap: () => _startQuickInterview(
                    context,
                    _createDataScienceJobRole(),
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Note: Make sure your microphone permissions are enabled for voice interview functionality.',
                          style: TextStyle(
                            color: Colors.orange.shade300,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _startQuickInterview(BuildContext context, JobRoleModel jobRole) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InterviewScreen(
          jobRole: jobRole,
          difficultyLevel: 'medium',
          totalQuestions: 5, // Shorter demo
        ),
      ),
    );
  }

  JobRoleModel _createFrontendJobRole() {
    return JobRoleModel(
      id: 'frontend_demo',
      title: 'Frontend Developer',
      category: 'Technology',
      description:
          'Develop user-facing web applications using modern frameworks',
      requiredSkills: [
        'HTML',
        'CSS',
        'JavaScript',
        'React',
        'Vue.js',
        'TypeScript',
      ],
      experienceLevels: ['entry', 'mid', 'senior'],
      industry: 'Technology',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  JobRoleModel _createBackendJobRole() {
    return JobRoleModel(
      id: 'backend_demo',
      title: 'Backend Developer',
      category: 'Technology',
      description: 'Develop server-side applications and APIs',
      requiredSkills: [
        'Node.js',
        'Python',
        'Java',
        'SQL',
        'REST APIs',
        'MongoDB',
      ],
      experienceLevels: ['entry', 'mid', 'senior'],
      industry: 'Technology',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  JobRoleModel _createDataScienceJobRole() {
    return JobRoleModel(
      id: 'data_science_demo',
      title: 'Data Scientist',
      category: 'Technology',
      description: 'Analyze data and build predictive models',
      requiredSkills: [
        'Python',
        'R',
        'SQL',
        'Machine Learning',
        'Statistics',
        'Pandas',
      ],
      experienceLevels: ['entry', 'mid', 'senior'],
      industry: 'Technology',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
