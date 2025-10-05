import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfService {
  static const String _appName = 'AI Voice Interview App';

  /// Generates and saves a PDF report of the resume analysis
  static Future<String?> generateAnalysisReport({
    required Map<String, dynamic> analysisData,
    required String resumeFileName,
  }) async {
    try {
      debugPrint('Starting PDF generation...');
      debugPrint('Analysis data keys: ${analysisData.keys.toList()}');
      debugPrint('Resume file name: $resumeFileName');

      // Request storage permission for Android
      if (Platform.isAndroid) {
        debugPrint('Requesting Android storage permission...');
        try {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            final manageStatus = await Permission.manageExternalStorage
                .request();
            if (!manageStatus.isGranted) {
              debugPrint(
                'Storage permission denied, trying to save without permission',
              );
            }
          }
        } catch (e) {
          debugPrint(
            'Permission request failed: $e, continuing without permission',
          );
        }
        debugPrint('Storage permission handling completed');
      }

      // Create PDF document
      debugPrint('Creating PDF document...');
      final pdf = pw.Document();

      // Add pages to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            // List of all possible sections
            final List<pw.Widget> allSections = [
              _buildHeader(resumeFileName),
              _buildAutoDetectedProfile(analysisData),
              _buildOverallScore(analysisData),
              _buildExecutiveSummary(analysisData),
              _buildDetectedStrengths(analysisData),
              _buildCriticalImprovements(analysisData),
              _buildCompetencyGapAnalysis(analysisData),
              _buildSkillsSection(analysisData),
              _buildExperienceSection(analysisData),
              _buildExperienceOptimization(analysisData),
              _buildResumeStructureRecommendations(analysisData),
              _buildMarketPositioning(analysisData),
              _buildActionPlan(analysisData),
              _buildInterviewPreparation(analysisData),
              _buildCompetitiveAnalysis(analysisData),
              _buildIndustryInsights(analysisData),
              _buildConfidenceLevels(analysisData),
              // LEGACY SECTIONS (for backwards compatibility)
              _buildStrengthsSection(analysisData),
              _buildImprovementsSection(analysisData),
              _buildInterviewTipsSection(analysisData),
              _buildJobRecommendationsSection(analysisData),
              _buildFooter(),
            ];

            // Filter out empty sections (which return an empty SizedBox)
            final List<pw.Widget> visibleSections = allSections.where((
              section,
            ) {
              // An empty section is represented by a SizedBox with no dimensions.
              if (section is pw.SizedBox) {
                return section.width != null || section.height != null;
              }
              return true;
            }).toList();

            // Build the final list of widgets with spacers in between
            final List<pw.Widget> finalList = [];
            for (int i = 0; i < visibleSections.length; i++) {
              finalList.add(visibleSections[i]);
              // Add a spacer after each section except the last one
              if (i < visibleSections.length - 1) {
                finalList.add(pw.SizedBox(height: 20));
              }
            }
            return finalList;
          },
        ),
      );

      // Get the downloads directory
      debugPrint('Getting downloads directory...');
      Directory? downloadDir;

      try {
        if (Platform.isAndroid) {
          downloadDir = Directory('/storage/emulated/0/Download');
          if (!await downloadDir.exists()) {
            downloadDir = await getExternalStorageDirectory();
            if (downloadDir != null) {
              downloadDir = Directory('${downloadDir.path}/Download');
              if (!await downloadDir.exists()) {
                await downloadDir.create(recursive: true);
              }
            }
          }
        } else if (Platform.isIOS) {
          downloadDir = await getApplicationDocumentsDirectory();
        } else {
          downloadDir = await getDownloadsDirectory();
        }
      } catch (e) {
        debugPrint('Error getting downloads directory: $e');
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) {
        debugPrint('Could not access downloads directory');
        throw Exception('Could not access downloads directory');
      }
      debugPrint('Downloads directory: ${downloadDir.path}');

      // Create file name with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'Resume_Analysis_${resumeFileName.replaceAll(RegExp(r'[^\w\s-]'), '')}_$timestamp.pdf';
      final file = File('${downloadDir.path}/$fileName');
      debugPrint('Target file path: ${file.path}');

      // Save PDF to file
      debugPrint('Saving PDF to file...');
      final pdfBytes = await pdf.save();
      debugPrint('PDF bytes generated: ${pdfBytes.length} bytes');
      await file.writeAsBytes(pdfBytes);
      debugPrint('PDF file saved successfully');

      return file.path;
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      return null;
    }
  }

  static pw.Widget _buildHeader(String resumeFileName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resume Analysis Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated by $_appName',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                'Resume: $resumeFileName',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated on: ${DateTime.now().toString().substring(0, 19)}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildOverallScore(Map<String, dynamic> analysisData) {
    final rawScore =
        analysisData['overall_score'] ?? analysisData['overallScore'] ?? 0.0;

    final overallScore = rawScore.toDouble() > 10.0
        ? rawScore.toDouble() / 10.0
        : rawScore.toDouble();

    final normalizedScore = overallScore / 10.0;
    final overallFeedback =
        analysisData['overall_feedback']?.toString() ??
        analysisData['overallFeedback']?.toString() ??
        'Analysis completed successfully';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Overall Score'),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _getPdfScoreColor(normalizedScore),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    '${overallScore.toStringAsFixed(1)}/10',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Text(
                      _getScoreMessage(normalizedScore),
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.white),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                overallFeedback,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSkillsSection(Map<String, dynamic> analysisData) {
    final skills =
        analysisData['skills'] as Map<String, dynamic>? ??
        {'technical': analysisData['extracted_skills'] ?? []};

    if (skills.values.every((list) => (list as List).isEmpty)) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Skills Analysis'),
        pw.SizedBox(height: 12),
        ...skills.entries.map(
          (entry) => _buildSkillCategory(
            entry.key,
            List<String>.from(entry.value ?? []),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSkillCategory(String title, List<String> skills) {
    if (skills.isEmpty) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Wrap(
            spacing: 6,
            runSpacing: 4,
            children: skills
                .map(
                  (skill) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(skill, style: pw.TextStyle(fontSize: 10)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildExperienceSection(Map<String, dynamic> analysisData) {
    final experience =
        analysisData['experience'] as Map<String, dynamic>? ?? {};
    final yearsOfExperience =
        (experience['yearsOfExperience'] ??
                analysisData['extracted_experience_years'])
            ?.toString();

    if (experience.isEmpty &&
        (yearsOfExperience == null || yearsOfExperience == '0')) {
      return pw.SizedBox();
    }

    final summary =
        experience['summary']?.toString() ??
        'Experience information not available';
    final keyAchievements = List<String>.from(
      experience['keyAchievements'] ?? [],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Experience Analysis'),
        pw.SizedBox(height: 12),
        if (yearsOfExperience != null && yearsOfExperience != '0') ...[
          _buildInfoCard('Years of Experience', yearsOfExperience),
          pw.SizedBox(height: 8),
        ],
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Summary',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(summary, style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        if (keyAchievements.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Key Achievements',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 4),
          ...keyAchievements.map(
            (achievement) => _buildBulletPoint(achievement, PdfColors.green),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildStrengthsSection(Map<String, dynamic> analysisData) {
    final strengths = List<String>.from(analysisData['strengths'] ?? []);
    if (strengths.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Key Strengths'),
        pw.SizedBox(height: 12),
        ...strengths.map(
          (strength) => _buildBulletPoint(strength, PdfColors.green),
        ),
      ],
    );
  }

  static pw.Widget _buildImprovementsSection(
    Map<String, dynamic> analysisData,
  ) {
    final improvements = List<String>.from(
      analysisData['improvements'] ??
          analysisData['improvement_suggestions'] ??
          [],
    );
    if (improvements.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Areas for Improvement'),
        pw.SizedBox(height: 12),
        ...improvements.map(
          (improvement) => _buildBulletPoint(improvement, PdfColors.orange),
        ),
      ],
    );
  }

  static pw.Widget _buildInterviewTipsSection(
    Map<String, dynamic> analysisData,
  ) {
    final tips = List<String>.from(analysisData['interviewTips'] ?? []);
    if (tips.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Interview Tips'),
        pw.SizedBox(height: 12),
        ...tips.map((tip) => _buildBulletPoint(tip, PdfColors.blue)),
      ],
    );
  }

  static pw.Widget _buildJobRecommendationsSection(
    Map<String, dynamic> analysisData,
  ) {
    final recommendations = List<String>.from(
      analysisData['jobRecommendations'] ??
          analysisData['recommended_job_roles'] ??
          [],
    );
    if (recommendations.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Job Recommendations'),
        pw.SizedBox(height: 12),
        ...recommendations.map(
          (recommendation) =>
              _buildBulletPoint(recommendation, PdfColors.purple),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.indigo900,
      ),
    );
  }

  static pw.Widget _buildInfoCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  static pw.Widget _buildBulletPoint(String text, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 6, right: 8),
            width: 4,
            height: 4,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  // ========== NEW ENHANCED SECTION BUILDERS ==========

  static pw.Widget _buildAutoDetectedProfile(
    Map<String, dynamic> analysisData,
  ) {
    final profile =
        analysisData['auto_detected_profile'] as Map<String, dynamic>? ??
        analysisData['autoDetectedProfile'] as Map<String, dynamic>? ??
        {};

    if (profile.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🎯 Auto-Detected Profile'),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: PdfColors.blue200, width: 1),
          ),
          child: pw.Column(
            children: [
              _buildProfileRow(
                'Identified Role',
                profile['identified_role_type']?.toString() ?? 'Not specified',
              ),
              _buildProfileRow(
                'Industry/Sector',
                profile['industry_sector']?.toString() ?? 'Not specified',
              ),
              _buildProfileRow(
                'Career Level',
                profile['career_level']?.toString() ?? 'Not specified',
              ),
              _buildProfileRow(
                'Years of Experience',
                profile['years_of_experience']?.toString() ?? 'Not specified',
              ),
              _buildProfileRow(
                'Target Position',
                profile['likely_target_position']?.toString() ??
                    'Not specified',
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildProfileRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Container(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
          ),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  static pw.Widget _buildExecutiveSummary(Map<String, dynamic> analysisData) {
    final summary =
        analysisData['executive_summary']?.toString() ??
        analysisData['executiveSummary']?.toString() ??
        '';

    if (summary.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📋 Executive Summary'),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.amber50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.amber200),
          ),
          child: pw.Text(
            summary,
            style: pw.TextStyle(fontSize: 12, height: 1.5),
            textAlign: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDetectedStrengths(Map<String, dynamic> analysisData) {
    final strengths = List<String>.from(
      analysisData['detected_strengths'] ??
          analysisData['detectedStrengths'] ??
          [],
    );

    if (strengths.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('💪 Detected Strengths'),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.green200),
          ),
          child: pw.Column(
            children: strengths
                .map(
                  (strength) => _buildEnhancedBulletPoint(
                    strength,
                    PdfColors.green700,
                    '✓',
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCriticalImprovements(
    Map<String, dynamic> analysisData,
  ) {
    final improvements =
        analysisData['critical_improvements'] as List<dynamic>? ??
        analysisData['criticalImprovements'] as List<dynamic>? ??
        [];

    if (improvements.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('⚠️ Critical Improvements Needed'),
        pw.SizedBox(height: 12),
        ...improvements.map((item) {
          final improvement = item as Map<String, dynamic>;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.orange300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  improvement['area']?.toString() ?? 'Improvement Area',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColors.orange900,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildLabeledText(
                  'Issue',
                  improvement['current_issue']?.toString() ??
                      improvement['issue']?.toString() ??
                      'Not specified',
                ),
                _buildLabeledText(
                  'Impact',
                  improvement['industry_impact']?.toString() ??
                      improvement['impact']?.toString() ??
                      'Not specified',
                ),
                _buildLabeledText(
                  'Recommendation',
                  improvement['recommendation']?.toString() ?? 'Not specified',
                ),
                if (improvement['implementation'] != null)
                  _buildLabeledText(
                    'Implementation',
                    improvement['implementation'].toString(),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildCompetencyGapAnalysis(
    Map<String, dynamic> analysisData,
  ) {
    final gapAnalysis =
        analysisData['competency_gap_analysis'] as Map<String, dynamic>? ??
        analysisData['competencyGapAnalysis'] as Map<String, dynamic>? ??
        {};

    if (gapAnalysis.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📊 Competency Gap Analysis'),
        pw.SizedBox(height: 12),

        if (gapAnalysis['essential_missing_skills'] != null ||
            gapAnalysis['essentialMissingSkills'] != null)
          _buildGapSubsection(
            'Essential Missing Skills',
            _ensureList(
              gapAnalysis['essential_missing_skills'] ??
                  gapAnalysis['essentialMissingSkills'],
            ),
            PdfColors.red,
          ),

        if (gapAnalysis['recommended_skills'] != null ||
            gapAnalysis['recommendedSkills'] != null)
          _buildGapSubsection(
            'Recommended Skills',
            _ensureList(
              gapAnalysis['recommended_skills'] ??
                  gapAnalysis['recommendedSkills'],
            ),
            PdfColors.blue,
          ),

        if (gapAnalysis['certifications'] != null)
          _buildGapSubsection(
            'Valuable Certifications',
            _ensureList(gapAnalysis['certifications']),
            PdfColors.purple,
          ),
      ],
    );
  }

  static pw.Widget _buildGapSubsection(
    String title,
    List<String> items,
    PdfColor color,
  ) {
    if (items.isEmpty) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color.shade(0.3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
          pw.SizedBox(height: 6),
          ...items.map((item) => _buildEnhancedBulletPoint(item, color, '•')),
        ],
      ),
    );
  }

  static pw.Widget _buildExperienceOptimization(
    Map<String, dynamic> analysisData,
  ) {
    final expOptimization =
        analysisData['experience_optimization'] as Map<String, dynamic>? ??
        analysisData['experienceOptimization'] as Map<String, dynamic>? ??
        {};

    if (expOptimization.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🎯 Experience Optimization'),
        pw.SizedBox(height: 12),

        if (expOptimization['quantification_opportunities'] != null ||
            expOptimization['quantificationOpportunities'] != null)
          _buildOptimizationSubsection(
            'Quantification Opportunities',
            _ensureList(
              expOptimization['quantification_opportunities'] ??
                  expOptimization['quantificationOpportunities'],
            ),
          ),

        if (expOptimization['industry_specific_improvements'] != null ||
            expOptimization['industrySpecificImprovements'] != null)
          _buildOptimizationSubsection(
            'Industry-Specific Improvements',
            _ensureList(
              expOptimization['industry_specific_improvements'] ??
                  expOptimization['industrySpecificImprovements'],
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildOptimizationSubsection(
    String title,
    List<String> items,
  ) {
    if (items.isEmpty) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 6),
          ...items.map(
            (item) => _buildEnhancedBulletPoint(item, PdfColors.blue700, '→'),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildResumeStructureRecommendations(
    Map<String, dynamic> analysisData,
  ) {
    final recommendations =
        analysisData['resume_structure_recommendations']
            as Map<String, dynamic>? ??
        analysisData['resumeStructureRecommendations']
            as Map<String, dynamic>? ??
        {};

    if (recommendations.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📝 Resume Structure Recommendations'),
        pw.SizedBox(height: 12),

        if (recommendations['format_optimization'] != null ||
            recommendations['formatOptimization'] != null)
          _buildRecommendationCard(
            'Format Optimization',
            _ensureList(
              recommendations['format_optimization'] ??
                  recommendations['formatOptimization'],
            ),
            PdfColors.indigo,
          ),

        if (recommendations['ats_optimization'] != null ||
            recommendations['atsOptimization'] != null)
          _buildRecommendationCard(
            'ATS Optimization',
            _ensureList(
              recommendations['ats_optimization'] ??
                  recommendations['atsOptimization'],
            ),
            PdfColors.teal,
          ),

        if (recommendations['missing_elements'] != null ||
            recommendations['missingElements'] != null)
          _buildRecommendationCard(
            'Missing Elements',
            _ensureList(
              recommendations['missing_elements'] ??
                  recommendations['missingElements'],
            ),
            PdfColors.red,
          ),
      ],
    );
  }

  static pw.Widget _buildRecommendationCard(
    String title,
    List<String> items,
    PdfColor color,
  ) {
    if (items.isEmpty) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color.shade(0.3)),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
          pw.SizedBox(height: 6),
          ...items.map((item) => _buildEnhancedBulletPoint(item, color, '○')),
        ],
      ),
    );
  }

  static pw.Widget _buildMarketPositioning(Map<String, dynamic> analysisData) {
    final positioning =
        analysisData['market_positioning'] as Map<String, dynamic>? ??
        analysisData['marketPositioning'] as Map<String, dynamic>? ??
        {};

    if (positioning.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📈 Market Positioning Assessment'),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.purple50,
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: PdfColors.purple200),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (positioning['market_competitiveness'] != null ||
                  positioning['marketCompetitiveness'] != null)
                _buildMarketRow(
                  'Market Competitiveness',
                  (positioning['market_competitiveness'] ??
                          positioning['marketCompetitiveness'])
                      .toString(),
                ),

              if (positioning['suitable_positions'] != null ||
                  positioning['suitablePositions'] != null)
                _buildMarketListRow(
                  'Suitable Positions',
                  _ensureList(
                    positioning['suitable_positions'] ??
                        positioning['suitablePositions'],
                  ),
                ),

              if (positioning['salary_range'] != null ||
                  positioning['salaryRange'] != null)
                _buildMarketRow(
                  'Estimated Salary Range',
                  (positioning['salary_range'] ?? positioning['salaryRange'])
                      .toString(),
                ),

              if (positioning['career_trajectory'] != null ||
                  positioning['careerTrajectory'] != null)
                ..._buildCareerTrajectory(
                  positioning['career_trajectory'] ??
                      positioning['careerTrajectory'],
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMarketRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildMarketListRow(String label, List<String> items) {
    if (items.isEmpty) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          ...items.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12, top: 2),
              child: pw.Text('• $item', style: pw.TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildCareerTrajectory(dynamic trajectory) {
    if (trajectory is! Map<String, dynamic>) return [];

    return [
      pw.SizedBox(height: 8),
      pw.Text(
        'Career Trajectory:',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
      if (trajectory['natural_next_step'] != null ||
          trajectory['naturalNextStep'] != null)
        pw.Text(
          '  Next Step: ${(trajectory['natural_next_step'] ?? trajectory['naturalNextStep']).toString()}',
          style: pw.TextStyle(fontSize: 10),
        ),
      if (trajectory['stretch_positions'] != null ||
          trajectory['stretchPositions'] != null)
        ..._ensureList(
          trajectory['stretch_positions'] ?? trajectory['stretchPositions'],
        ).map(
          (pos) =>
              pw.Text('  Stretch: $pos', style: pw.TextStyle(fontSize: 10)),
        ),
    ];
  }

  static pw.Widget _buildActionPlan(Map<String, dynamic> analysisData) {
    final actionPlan =
        analysisData['action_plan'] as Map<String, dynamic>? ??
        analysisData['actionPlan'] as Map<String, dynamic>? ??
        {};

    if (actionPlan.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🎯 Tailored Action Plan'),
        pw.SizedBox(height: 12),

        if (actionPlan['immediate_fixes'] != null ||
            actionPlan['immediateFixes'] != null)
          _buildActionCard(
            'Immediate Fixes (This Week)',
            _ensureList(
              actionPlan['immediate_fixes'] ?? actionPlan['immediateFixes'],
            ),
            PdfColors.red,
            '🔴',
          ),

        if (actionPlan['short_term'] != null || actionPlan['shortTerm'] != null)
          _buildActionCard(
            'Short-term Development (1-3 months)',
            _ensureList(actionPlan['short_term'] ?? actionPlan['shortTerm']),
            PdfColors.orange,
            '🟡',
          ),

        if (actionPlan['strategic_goals'] != null ||
            actionPlan['strategicGoals'] != null)
          _buildActionCard(
            'Strategic Goals (3-6 months)',
            _ensureList(
              actionPlan['strategic_goals'] ?? actionPlan['strategicGoals'],
            ),
            PdfColors.green,
            '🟢',
          ),
      ],
    );
  }

  static pw.Widget _buildActionCard(
    String title,
    List<String> items,
    PdfColor color,
    String emoji,
  ) {
    if (items.isEmpty) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.05),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color.shade(0.3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$emoji $title',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
          pw.SizedBox(height: 6),
          ...items.asMap().entries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '${entry.key + 1}. ${entry.value}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInterviewPreparation(
    Map<String, dynamic> analysisData,
  ) {
    final interviewPrep =
        analysisData['interview_preparation'] as Map<String, dynamic>? ??
        analysisData['interviewPreparation'] as Map<String, dynamic>? ??
        {};

    if (interviewPrep.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🎤 Interview Preparation'),
        pw.SizedBox(height: 12),

        if (interviewPrep['likely_questions'] != null ||
            interviewPrep['likelyQuestions'] != null)
          _buildInterviewCard(
            'Likely Questions',
            _ensureList(
              interviewPrep['likely_questions'] ??
                  interviewPrep['likelyQuestions'],
            ),
            PdfColors.blue,
          ),

        if (interviewPrep['areas_of_scrutiny'] != null ||
            interviewPrep['areasOfScrutiny'] != null)
          _buildInterviewCard(
            'Areas of Scrutiny',
            _ensureList(
              interviewPrep['areas_of_scrutiny'] ??
                  interviewPrep['areasOfScrutiny'],
            ),
            PdfColors.orange,
          ),
      ],
    );
  }

  static pw.Widget _buildInterviewCard(
    String title,
    List<String> items,
    PdfColor color,
  ) {
    if (items.isEmpty) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color.shade(0.3)),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
          pw.SizedBox(height: 6),
          ...items.map((item) => _buildEnhancedBulletPoint(item, color, '?')),
        ],
      ),
    );
  }

  static pw.Widget _buildCompetitiveAnalysis(
    Map<String, dynamic> analysisData,
  ) {
    final competitive =
        analysisData['competitive_analysis'] as Map<String, dynamic>? ??
        analysisData['competitiveAnalysis'] as Map<String, dynamic>? ??
        {};

    if (competitive.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('⚔️ Competitive Analysis'),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (competitive['unique_advantages'] != null ||
                  competitive['uniqueAdvantages'] != null)
                _buildCompetitiveSection(
                  'Unique Advantages',
                  _ensureList(
                    competitive['unique_advantages'] ??
                        competitive['uniqueAdvantages'],
                  ),
                  PdfColors.green,
                ),

              if (competitive['competitive_gaps'] != null ||
                  competitive['competitiveGaps'] != null)
                _buildCompetitiveSection(
                  'Competitive Gaps',
                  _ensureList(
                    competitive['competitive_gaps'] ??
                        competitive['competitiveGaps'],
                  ),
                  PdfColors.red,
                ),

              if (competitive['positioning_strategy'] != null ||
                  competitive['positioningStrategy'] != null)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Positioning Strategy:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      (competitive['positioning_strategy'] ??
                              competitive['positioningStrategy'])
                          .toString(),
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCompetitiveSection(
    String title,
    List<String> items,
    PdfColor color,
  ) {
    if (items.isEmpty) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$title:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: color,
            ),
          ),
          ...items.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8, top: 2),
              child: pw.Text('• $item', style: pw.TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildIndustryInsights(Map<String, dynamic> analysisData) {
    final insights =
        analysisData['industry_insights']?.toString() ??
        analysisData['industryInsights']?.toString() ??
        '';

    if (insights.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🏢 Industry-Specific Insights'),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.cyan50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.cyan200),
          ),
          child: pw.Text(
            insights,
            style: pw.TextStyle(fontSize: 11, height: 1.5),
            textAlign: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildConfidenceLevels(Map<String, dynamic> analysisData) {
    final confidence =
        analysisData['confidence_levels'] as Map<String, dynamic>? ??
        analysisData['confidenceLevels'] as Map<String, dynamic>? ??
        {};

    if (confidence.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📊 Confidence Levels'),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _buildConfidenceRow(
                'Role Detection',
                confidence['role_detection']?.toString() ??
                    confidence['roleDetection']?.toString() ??
                    'N/A',
              ),
              _buildConfidenceRow(
                'Industry Identification',
                confidence['industry_identification']?.toString() ??
                    confidence['industryIdentification']?.toString() ??
                    'N/A',
              ),
              _buildConfidenceRow(
                'Career Level Assessment',
                confidence['career_level']?.toString() ??
                    confidence['careerLevel']?.toString() ??
                    'N/A',
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildConfidenceRow(String label, String level) {
    PdfColor color;
    if (level.toLowerCase().contains('high')) {
      color = PdfColors.green;
    } else if (level.toLowerCase().contains('medium')) {
      color = PdfColors.orange;
    } else {
      color = PdfColors.red;
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text('$label:', style: pw.TextStyle(fontSize: 10)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: pw.BoxDecoration(
              color: color.shade(0.2),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              level,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEnhancedBulletPoint(
    String text,
    PdfColor color,
    String bullet,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 2, right: 8),
            child: pw.Text(
              bullet,
              style: pw.TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  static pw.Widget _buildLabeledText(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  static List<String> _ensureList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  // ========== END OF NEW SECTION BUILDERS ==========

  static pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated by $_appName - Your AI Interview Co-Pilot',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static PdfColor _getPdfScoreColor(double score) {
    if (score >= 0.8) {
      return PdfColors.green;
    } else if (score >= 0.6) {
      return PdfColors.orange;
    } else {
      return PdfColors.red;
    }
  }

  static String _getScoreMessage(double score) {
    if (score >= 0.9) {
      return 'Outstanding! Your resume demonstrates exceptional qualifications.';
    } else if (score >= 0.8) {
      return 'Excellent! Your resume shows strong qualifications with minor areas for enhancement.';
    } else if (score >= 0.7) {
      return 'Good! Your resume has solid foundations with room for improvement.';
    } else if (score >= 0.6) {
      return 'Fair. Your resume shows potential but needs significant improvements.';
    } else {
      return 'Needs Work. Consider major revisions to strengthen your resume.';
    }
  }
}
