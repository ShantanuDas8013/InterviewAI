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
        // For Android 13+ (API 33+) we don't need storage permission for saving to Downloads
        // For older versions, request storage permission

        try {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            // Try with manage external storage permission for Android 11+
            final manageStatus = await Permission.manageExternalStorage
                .request();
            if (!manageStatus.isGranted) {
              debugPrint(
                'Storage permission denied, trying to save without permission',
              );
              // We'll continue anyway as newer Android versions don't require permission for Downloads folder
            }
          }
        } catch (e) {
          debugPrint(
            'Permission request failed: $e, continuing without permission',
          );
          // Continue anyway as the permission might not be needed on newer Android versions
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
            return [
              _buildHeader(resumeFileName),
              pw.SizedBox(height: 20),
              _buildOverallScore(analysisData),
              pw.SizedBox(height: 20),
              _buildSkillsSection(analysisData),
              pw.SizedBox(height: 20),
              _buildExperienceSection(analysisData),
              pw.SizedBox(height: 20),
              _buildStrengthsSection(analysisData),
              pw.SizedBox(height: 20),
              _buildImprovementsSection(analysisData),
              pw.SizedBox(height: 20),
              _buildInterviewTipsSection(analysisData),
              pw.SizedBox(height: 20),
              _buildJobRecommendationsSection(analysisData),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ];
          },
        ),
      );

      // Get the downloads directory
      debugPrint('Getting downloads directory...');
      Directory? downloadDir;

      try {
        if (Platform.isAndroid) {
          // First try the public Downloads directory
          downloadDir = Directory('/storage/emulated/0/Download');
          if (!await downloadDir.exists()) {
            // Fall back to app-specific external storage
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
        // Fall back to application documents directory
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
    final overallScore =
        analysisData['overall_score'] ?? analysisData['overallScore'] ?? 0.0;
    final normalizedScore = overallScore.toDouble() / 10.0;
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
    // Handle both new and old data structures
    final skills =
        analysisData['skills'] as Map<String, dynamic>? ??
        {'technical': analysisData['extracted_skills'] ?? []};

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
    final summary =
        experience['summary']?.toString() ??
        'Experience information not available';
    final yearsOfExperience =
        (experience['yearsOfExperience'] ??
                analysisData['extracted_experience_years'])
            ?.toString() ??
        'Not specified';
    final keyAchievements = List<String>.from(
      experience['keyAchievements'] ?? [],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Experience Analysis'),
        pw.SizedBox(height: 12),
        _buildInfoCard('Years of Experience', yearsOfExperience),
        pw.SizedBox(height: 8),
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
