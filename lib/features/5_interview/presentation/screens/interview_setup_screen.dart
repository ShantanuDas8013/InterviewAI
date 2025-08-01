import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../2_home/presentation/widgets/job_role_selector.dart';
import '../../data/models/job_role_model.dart';
import 'interview_screen.dart';

class InterviewSetupScreen extends StatefulWidget {
  const InterviewSetupScreen({super.key});

  @override
  State<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends State<InterviewSetupScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userResume;
  List<String> _jobRoles = [];
  String? _selectedJobRole;
  bool _isLoading = true;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserProfile();
    _loadJobRoles();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final userProfile = await _databaseService.getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Load user's resume information
      final userResume = await _databaseService.getUserResume(userId);

      setState(() {
        _userProfile = userProfile;
        _userResume = userResume;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadJobRoles() async {
    setState(() {
      _isLoading = true;
      _jobRoles = []; // Clear existing job roles while loading
      _selectedJobRole = null; // Reset selected role
    });

    try {
      // Fetch job roles from database using the DatabaseService
      final jobRolesData = await _databaseService.getJobRoles();

      if (jobRolesData.isEmpty) {
        throw Exception('No job roles found in database');
      }

      final roles = jobRolesData
          .map((item) => item['title'].toString())
          .toList();

      setState(() {
        _jobRoles = roles;
        _isLoading = false;
      });

      debugPrint('Loaded ${roles.length} job roles successfully');
    } catch (e) {
      debugPrint('Error loading job roles: $e');
      // Fallback to default job roles if database fetch fails
      setState(() {
        _jobRoles = [
          'Frontend Developer',
          'Backend Developer',
          'Full Stack Developer',
          'Data Scientist',
          'Product Manager',
          'Digital Marketing Specialist',
          'UI/UX Designer',
          'DevOps Engineer',
          'Mobile App Developer',
          'Software Engineer',
        ];
        _isLoading = false;
      });

      debugPrint('Using fallback job roles list');
    }
  }

  void _onJobRoleSelected(String role) {
    setState(() {
      _selectedJobRole = role;
    });
  }

  void _startInterview() async {
    if (_selectedJobRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a job role to continue'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User authentication error. Please log in again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Find the job role from the database instead of creating a new one
      final jobRolesData = await _databaseService.getJobRoles();
      final selectedJobRoleData = jobRolesData.firstWhere(
        (role) => role['title'] == _selectedJobRole,
        orElse: () => throw Exception('Selected job role not found in database'),
      );
      
      // Create a job role model from the database data
      final jobRoleModel = JobRoleModel.fromJson(selectedJobRoleData);

      // Navigate to the interview screen
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InterviewScreen(
            jobRole: jobRoleModel,
            resumeId: _userResume?['id'],
            difficultyLevel: 'medium',
            totalQuestions: 10,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting interview: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> _getSkillsForJobRole(String jobRole) {
    final skillsMap = {
      'Frontend Developer': ['HTML', 'CSS', 'JavaScript', 'React', 'Vue.js'],
      'Backend Developer': ['Node.js', 'Python', 'Java', 'SQL', 'REST APIs'],
      'Full Stack Developer': ['JavaScript', 'React', 'Node.js', 'SQL', 'Git'],
      'Data Scientist': [
        'Python',
        'R',
        'SQL',
        'Machine Learning',
        'Statistics',
      ],
      'Product Manager': [
        'Product Strategy',
        'Analytics',
        'Communication',
        'Leadership',
      ],
      'Digital Marketing Specialist': [
        'SEO',
        'SEM',
        'Social Media',
        'Analytics',
        'Content Marketing',
      ],
      'Mobile Developer': [
        'Flutter',
        'React Native',
        'Swift',
        'Kotlin',
        'Mobile UI/UX',
      ],
      'DevOps Engineer': ['Docker', 'Kubernetes', 'AWS', 'CI/CD', 'Linux'],
      'UI/UX Designer': [
        'Figma',
        'Adobe XD',
        'User Research',
        'Prototyping',
        'Design Systems',
      ],
      'Software Engineer': [
        'Programming',
        'Algorithms',
        'System Design',
        'Testing',
        'Git',
      ],
    };

    return skillsMap[jobRole] ??
        ['Communication', 'Problem Solving', 'Teamwork', 'Technical Skills'];
  }

  // Helper method to format date for display
  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        title: const Text(
          'Interview Setup',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: AppTheme.paddingM),
                _buildUserDetailsCard(),
                const SizedBox(height: AppTheme.paddingL),
                _jobRoles.isEmpty
                    ? _buildEmptyJobRolesMessage()
                    : JobRoleSelector(
                        jobRoles: _jobRoles,
                        selectedRole: _selectedJobRole,
                        onRoleSelected: _onJobRoleSelected,
                      ),
                const SizedBox(height: AppTheme.paddingL),
                _buildStartInterviewButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${_userProfile?['full_name']?.split(' ')[0] ?? 'there'}!',
          style: const TextStyle(
            fontSize: AppTheme.fontSizeXLarge,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let\'s set up your mock interview with Gemini AI',
          style: TextStyle(
            fontSize: AppTheme.fontSizeRegular,
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUserDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingM),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Your Details',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: AppTheme.accentColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _userProfile?['subscription_type'] ?? 'Free',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUserDetailRow(
            'Full Name',
            _userProfile?['full_name'] ?? 'Not provided',
            Icons.badge,
          ),
          _buildUserDetailRow(
            'Email',
            _userProfile?['email'] ?? 'Not provided',
            Icons.email,
          ),
          _buildUserDetailRow(
            'Experience Level',
            _userProfile?['experience_level'] ?? 'Not provided',
            Icons.work_history,
          ),
          _buildUserDetailRow(
            'Current Position',
            _userProfile?['current_position'] ?? 'Not provided',
            Icons.work,
          ),
          _buildUserDetailRow(
            'Resume',
            _userResume != null
                ? '${_userResume?['file_name']} (Uploaded ${_formatDate(_userResume?['upload_date'])})'
                : 'No resume uploaded',
            Icons.description,
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textSecondaryColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeRegular,
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyJobRolesMessage() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingM),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Job Role',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.paddingM),
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[700], size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No job roles available at the moment. Please try again later or contact support if the issue persists.',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeRegular,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loadJobRoles,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.buttonBorderRadius,
                  ),
                ),
              ),
              child: const Text('Retry Loading Job Roles'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartInterviewButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedJobRole != null ? _startInterview : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
          ),
          elevation: 4,
          disabledBackgroundColor: AppTheme.accentColor.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _selectedJobRole != null
                    ? 'Start $_selectedJobRole Interview'
                    : 'Select a Job Role to Continue',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeRegular,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
