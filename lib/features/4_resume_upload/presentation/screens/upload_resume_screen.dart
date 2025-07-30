import 'package:flutter/material.dart';
import '../../services/resume_service.dart';
import '../../../../core/constants/theme.dart';
import 'analysis_result_screen.dart';

class UploadResumeScreen extends StatefulWidget {
  const UploadResumeScreen({super.key});

  @override
  State<UploadResumeScreen> createState() => _UploadResumeScreenState();
}

class _UploadResumeScreenState extends State<UploadResumeScreen>
    with TickerProviderStateMixin {
  final ResumeService _resumeService = ResumeService();

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _existingResume;
  Map<String, dynamic>? _analysisData;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadExistingResume();
    _initializeAnimations();
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Load existing resume for the current user
  Future<void> _loadExistingResume() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resume = await _resumeService.getCurrentResume();
      Map<String, dynamic>? analysis;

      // If resume exists, check for existing analysis
      if (resume != null) {
        analysis = await _resumeService.getResumeAnalysis(resume['id']);
      }

      setState(() {
        _existingResume = resume;
        _analysisData = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading resume: $e';
        _isLoading = false;
      });
    }
  }

  /// Pick and upload resume file
  Future<void> _pickAndUploadResume() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      final resumeData = await _resumeService.uploadResume();

      if (resumeData != null) {
        setState(() {
          _existingResume = resumeData;
          _isUploading = false;
          _successMessage = 'Resume uploaded successfully!';
        });

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading resume: $e';
        _isUploading = false;
      });
    }
  }

  /// Delete existing resume
  Future<void> _deleteResume() async {
    if (_existingResume == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resumeId = _existingResume!['id'];
      final filePath = _existingResume!['file_path'];

      await _resumeService.deleteResume(resumeId, filePath);

      setState(() {
        _existingResume = null;
        _isLoading = false;
        _successMessage = 'Resume deleted successfully!';
      });

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting resume: $e';
        _isLoading = false;
      });
    }
  }

  /// Analyze resume using AI
  Future<void> _analyzeResume() async {
    if (_existingResume == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final resumeId = _existingResume!['id'];
      debugPrint('Starting resume analysis for resume ID: $resumeId');

      final analysis = await _resumeService.analyzeResume(resumeId);

      if (analysis != null) {
        setState(() {
          _analysisData = analysis;
          _isAnalyzing = false;
        });

        debugPrint('Resume analysis completed successfully');
        debugPrint('Analysis overview: ${analysis['overallFeedback']}');

        // Navigate to analysis result screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalysisResultScreen(
                analysisData: analysis,
                resumeFileName: _existingResume!['file_name'],
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Failed to analyze resume. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('Error in resume analysis: $e');
      setState(() {
        _errorMessage = 'Error analyzing resume: ${e.toString()}';
        _isAnalyzing = false;
      });
    }
  }

  /// Navigate to analysis result screen to view existing analysis
  void _viewAnalysisResult() {
    if (_analysisData != null && _existingResume != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultScreen(
            analysisData: _analysisData!,
            resumeFileName: _existingResume!['file_name'],
          ),
        ),
      );
    }
  }

  /// Get formatted score (convert from 0-100 scale to 0-10 scale if needed)
  String _getFormattedScore(dynamic scoreValue) {
    final rawScore = (scoreValue ?? 0.0).toDouble();
    final score = rawScore > 10 ? rawScore / 10.0 : rawScore;
    return score.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        title: const Text(
          'Upload Resume',
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
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildMessageSection(),
                    const SizedBox(height: 24),
                    _buildMainContent(),
                    const SizedBox(height: 24),
                    _buildProgressSection(),
                  ],
                ),
              ),
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
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentColor, width: 2),
                ),
                child: Icon(
                  Icons.description,
                  color: AppTheme.accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resume Upload',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXLarge,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload your resume in PDF format to get started with AI-powered interview preparation.',
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

  Widget _buildMessageSection() {
    return Column(
      children: [
        // Error Message
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.error,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: AppTheme.fontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red.shade300, size: 20),
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),

        // Success Message
        if (_successMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontSize: AppTheme.fontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.green.shade300,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _successMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.paddingXL),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          border: Border.all(color: AppTheme.borderColor, width: 1),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading resume...',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_existingResume != null) {
      return _buildExistingResumeSection();
    } else {
      return _buildUploadSection();
    }
  }

  Widget _buildExistingResumeSection() {
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
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Icon(Icons.description, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Current Resume',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildResumeInfo(_existingResume!),
          const SizedBox(height: 24),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.upload_file,
                      label: 'Replace Resume',
                      color: Colors.orange,
                      onPressed: _isUploading ? null : _pickAndUploadResume,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.delete,
                      label: 'Delete',
                      color: Colors.red,
                      onPressed: _isUploading ? null : _deleteResume,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(
                  icon: Icons.analytics,
                  label: _analysisData != null
                      ? 'Re-analyze Resume'
                      : 'Analyze Resume',
                  color: AppTheme.accentColor,
                  onPressed: _isAnalyzing ? null : _analyzeResume,
                ),
              ),
              // Show "View Analysis Result" button if analysis exists
              if (_analysisData != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    icon: Icons.visibility,
                    label: 'View Analysis Result',
                    color: Colors.green,
                    onPressed: () => _viewAnalysisResult(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingXL),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.cloud_upload,
              size: 64,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Resume Uploaded',
            style: TextStyle(
              fontSize: AppTheme.fontSizeXLarge,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Upload your resume to get started with AI interview preparation',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildUploadButton(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Requirements',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: AppTheme.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Supported format: PDF only\n• Maximum size: 10MB\n• Secure upload to cloud storage',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor, AppTheme.secondaryAccentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isUploading ? null : _pickAndUploadResume,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Upload Resume',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.fontSizeRegular,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: AppTheme.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    if (!_isUploading && !_isAnalyzing) return const SizedBox.shrink();

    final isUploading = _isUploading;
    final isAnalyzing = _isAnalyzing;

    IconData icon;
    String message;
    String description;

    if (isUploading) {
      icon = Icons.upload;
      message = 'Uploading resume...';
      description = 'Securely uploading your PDF to cloud storage';
    } else {
      icon = Icons.analytics;
      message = 'Analyzing resume with AI...';
      description =
          'Our AI is reviewing your resume and generating detailed insights';
    }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: AppTheme.fontSizeRegular,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: AppTheme.fontSizeSmall,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            backgroundColor: AppTheme.accentColor.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.accentColor,
            ),
          ),
          if (isAnalyzing) ...[
            const SizedBox(height: 12),
            Text(
              'This may take 30-60 seconds depending on resume complexity',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Build resume information widget
  Widget _buildResumeInfo(Map<String, dynamic> resume) {
    final fileName = resume['file_name'] as String;
    final fileSize = resume['file_size_bytes'] as int;
    final uploadDate = resume['upload_date'] as String;
    final isAnalyzed = resume['is_analyzed'] as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppTheme.fontSizeRegular,
                        color: AppTheme.textPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _analysisData != null
                          ? Colors.green.withOpacity(0.2)
                          : (isAnalyzed
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _analysisData != null
                            ? Colors.green.withOpacity(0.5)
                            : (isAnalyzed
                                  ? Colors.blue.withOpacity(0.5)
                                  : Colors.orange.withOpacity(0.5)),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _analysisData != null
                              ? Icons.analytics
                              : (isAnalyzed
                                    ? Icons.check_circle
                                    : Icons.pending),
                          color: _analysisData != null
                              ? Colors.green
                              : (isAnalyzed ? Colors.blue : Colors.orange),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _analysisData != null
                              ? 'Analysis Ready'
                              : (isAnalyzed ? 'Analyzed' : 'Pending'),
                          style: TextStyle(
                            color: _analysisData != null
                                ? Colors.green
                                : (isAnalyzed ? Colors.blue : Colors.orange),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.storage,
                    color: AppTheme.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Size: ${_resumeService.formatFileSize(fileSize)}',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: AppTheme.fontSizeSmall,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppTheme.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Uploaded: ${_resumeService.formatUploadDate(uploadDate)}',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: AppTheme.fontSizeSmall,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Show analysis score if available
              if (_analysisData != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Analysis Score: ${_getFormattedScore(_analysisData!['overallScore'])}/10',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
