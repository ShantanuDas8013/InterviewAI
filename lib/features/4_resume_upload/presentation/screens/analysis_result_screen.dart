import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/theme.dart';
import '../../../../core/services/pdf_service.dart';
import '../../services/resume_service.dart';

class AnalysisResultScreen extends StatefulWidget {
  final Map<String, dynamic>? analysisData;
  final String? resumeFileName;
  final String? resumeId;

  const AnalysisResultScreen({
    super.key,
    this.analysisData,
    this.resumeFileName,
    this.resumeId,
  }) : assert(
          (analysisData != null && resumeFileName != null) || resumeId != null,
          'Either provide both analysisData and resumeFileName, or provide resumeId',
        );

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  
  final ResumeService _resumeService = ResumeService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _analysisData;
  String? _resumeFileName;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAnalysisData();
  }

  /// Load analysis data from database if needed
  Future<void> _loadAnalysisData() async {
    // If analysis data is already provided, use it
    if (widget.analysisData != null && widget.resumeFileName != null) {
      setState(() {
        _analysisData = widget.analysisData;
        _resumeFileName = widget.resumeFileName;
      });
      return;
    }
    
    // Otherwise, load from database using resumeId
    if (widget.resumeId != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        // Get resume analysis from database
        final analysis = await _resumeService.getResumeAnalysis(widget.resumeId!);
        
        // Get resume details to get the file name
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final resume = await _resumeService.getCurrentResume();
          
          setState(() {
            _analysisData = analysis;
            _resumeFileName = resume?['file_name'] ?? 'Resume';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'User not authenticated';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error loading analysis data: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();

    // Start progress animation after a slight delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _downloadAnalysisReport() async {
    if (_analysisData == null || _resumeFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis data not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBackgroundColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Generating PDF report...',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: AppTheme.fontSizeRegular,
                ),
              ),
            ],
          ),
        ),
      );

      // Generate PDF
      final filePath = await PdfService.generateAnalysisReport(
        analysisData: _analysisData!,
        resumeFileName: _resumeFileName!,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (filePath != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Analysis report downloaded successfully!\nSaved to: ${filePath.split('/').last}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to generate PDF report. Please try again.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error: ${e.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        title: const Text(
          'Resume Analysis',
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.download, size: 20),
            ),
            onPressed: _downloadAnalysisReport,
            tooltip: 'Download Analysis Report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: _isLoading
            ? _buildLoadingView()
            : _errorMessage != null
                ? _buildErrorView()
                : _analysisData == null
                    ? _buildNoDataView()
                    : _buildAnalysisContent(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading analysis data...',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: AppTheme.fontSizeRegular,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Analysis',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: AppTheme.fontSizeRegular,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadAnalysisData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.amber[300],
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              'No Analysis Data Found',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'We couldn\'t find any analysis data for this resume.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: AppTheme.fontSizeRegular,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisContent() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildHeaderSection(),
                const SizedBox(height: 24),
                _buildOverallScore(),
                const SizedBox(height: 24),
                _buildSkillsSection(),
                const SizedBox(height: 24),
                _buildExperienceSection(),
                const SizedBox(height: 24),
                _buildStrengthsSection(),
                const SizedBox(height: 24),
                _buildImprovementsSection(),
                const SizedBox(height: 24),
                _buildInterviewTipsSection(),
                const SizedBox(height: 24),
                _buildJobRecommendationsSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingL),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentColor,
                      AppTheme.secondaryAccentColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Resume Analysis',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXLarge,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _resumeFileName ?? 'Resume',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScore() {
    final rawScore = (_analysisData?['overallScore'] ?? 85.0).toDouble();
    // Convert from 0-100 scale to 0-10 scale
    final score = rawScore > 10 ? rawScore / 10.0 : rawScore;
    final scoreColor = _getScoreColor(score);

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingL),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          const Text(
            'Overall Score',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),
          // Circular Progress Indicator
          Center(
            child: Container(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scoreColor.withOpacity(0.1),
                          scoreColor.withOpacity(0.05),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scoreColor.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  // Circular progress indicator
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: (score / 10.0) * _progressAnimation.value,
                          strokeWidth: 8,
                          backgroundColor: scoreColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                          strokeCap: StrokeCap.round,
                        ),
                      );
                    },
                  ),
                  // Score text in center
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      final animatedScore = score * _progressAnimation.value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            animatedScore.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            '/ 10',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  // Animated sparkles (optional enhancement)
                  Positioned(
                    top: 20,
                    right: 30,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scoreColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 25,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scoreColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _getScoreMessage(score),
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    final skills = _analysisData?['skills'] ?? {};
    final technicalSkills = List<String>.from(skills['technical'] ?? []);
    final softSkills = List<String>.from(skills['soft'] ?? []);
    final domainSkills = List<String>.from(skills['domain'] ?? []);

    return _buildSection(
      title: 'Skills Assessment',
      icon: Icons.psychology,
      color: Colors.blue,
      children: [
        if (technicalSkills.isNotEmpty) ...[
          _buildSkillCategory('Technical Skills', technicalSkills, Colors.blue),
          const SizedBox(height: 16),
        ],
        if (softSkills.isNotEmpty) ...[
          _buildSkillCategory('Soft Skills', softSkills, Colors.green),
          const SizedBox(height: 16),
        ],
        if (domainSkills.isNotEmpty) ...[
          _buildSkillCategory('Domain Expertise', domainSkills, Colors.orange),
        ],
      ],
    );
  }

  Widget _buildExperienceSection() {
    final experience = _analysisData?['experience'] ?? {};
    final summary = experience['summary'] ?? 'No experience data available';
    final achievements = List<String>.from(experience['keyAchievements'] ?? []);
    final yearsOfExperience = experience['yearsOfExperience'] ?? 0;

    return _buildSection(
      title: 'Experience Summary',
      icon: Icons.work,
      color: Colors.purple,
      children: [
        Text(
          summary,
          style: TextStyle(
            fontSize: AppTheme.fontSizeRegular,
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.schedule, color: AppTheme.textSecondaryColor, size: 16),
            const SizedBox(width: 8),
            Text(
              '$yearsOfExperience years of experience',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (achievements.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Key Achievements:',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ...achievements.map(
            (achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      achievement,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStrengthsSection() {
    final strengths = List<String>.from(_analysisData?['strengths'] ?? []);

    return _buildSection(
      title: 'Key Strengths',
      icon: Icons.star,
      color: Colors.amber,
      children: [
        ...strengths.map(
          (strength) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strength,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImprovementsSection() {
    final improvements = List<String>.from(
      _analysisData?['improvements'] ?? [],
    );

    return _buildSection(
      title: 'Areas for Improvement',
      icon: Icons.trending_up,
      color: Colors.orange,
      children: [
        ...improvements.map(
          (improvement) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    improvement,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterviewTipsSection() {
    final tips = List<String>.from(_analysisData?['interviewTips'] ?? []);

    return _buildSection(
      title: 'Interview Preparation Tips',
      icon: Icons.tips_and_updates,
      color: Colors.teal,
      children: [
        ...tips.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobRecommendationsSection() {
    final recommendations = List<String>.from(
      _analysisData?['jobRecommendations'] ?? [],
    );

    return _buildSection(
      title: 'Recommended Job Roles',
      icon: Icons.business_center,
      color: Colors.indigo,
      children: [
        ...recommendations.map(
          (job) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    color: AppTheme.accentColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      job,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingL),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSkillCategory(String title, List<String> skills, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills
              .map(
                (skill) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage(double score) {
    if (score >= 8.0)
      return 'Excellent! Your resume is well-crafted and professional.';
    if (score >= 6.0)
      return 'Good! Your resume has potential with some improvements.';
    return 'Your resume needs significant improvements to be competitive.';
  }
}
