import 'package:flutter/material.dart';
import '../core/services/pdf_service.dart';

/// Example demonstrating how to use the enhanced PDF generation service
/// with the new comprehensive analysis data structure
class EnhancedPdfGenerationExample {
  /// Example analysis data with all new fields from the enhanced prompt
  static Map<String, dynamic> getSampleAnalysisData() {
    return {
      // Auto-Detected Profile
      'auto_detected_profile': {
        'identified_role_type': 'Senior Software Engineer',
        'industry_sector': 'Technology / SaaS',
        'career_level': 'Senior',
        'years_of_experience': 7,
        'likely_target_position': 'Technical Lead / Engineering Manager',
      },

      // Overall Score (existing)
      'overall_score': 8.5,
      'overall_feedback':
          'Strong technical profile with excellent career progression and modern tech stack expertise.',

      // Executive Summary
      'executive_summary':
          'This candidate demonstrates exceptional technical capabilities with 7+ years of progressive experience in software engineering. '
          'Their profile reveals strong expertise in cloud-native architectures, microservices, and full-stack development. '
          'The candidate shows clear career growth from junior to senior positions with increasing responsibilities. '
          'Key differentiators include contributions to open-source projects, mentoring experience, and proven track record of delivering scalable solutions.',

      // Detected Strengths
      'detected_strengths': [
        'Comprehensive full-stack development experience with modern frameworks (React, Node.js, Python)',
        'Strong cloud expertise (AWS, Docker, Kubernetes) with demonstrated DevOps capabilities',
        'Proven leadership through mentoring junior developers and leading technical initiatives',
        'Excellent problem-solving skills evidenced by architectural decisions and optimization projects',
        'Active in tech community through open-source contributions and conference speaking',
        'Strong communication skills with experience in stakeholder management',
        'Continuous learning mindset with recent certifications in cloud technologies',
      ],

      // Critical Improvements
      'critical_improvements': [
        {
          'area': 'Quantifiable Impact Metrics',
          'current_issue':
              'Several projects lack specific performance metrics or business impact numbers',
          'industry_impact':
              'Tech recruiters specifically look for quantified achievements (latency improvements, cost savings, user growth)',
          'recommendation':
              'Add metrics: "Reduced API response time by 60% through caching optimization" instead of "Improved API performance"',
          'implementation':
              'Review each project and add: speed improvements, cost savings, user metrics, or efficiency gains',
        },
        {
          'area': 'Leadership Scope Clarity',
          'current_issue':
              'Mentions mentoring but unclear about team sizes and leadership responsibilities',
          'industry_impact':
              'Senior roles require proven leadership experience with clear scope',
          'recommendation':
              'Specify: "Mentored team of 4 junior developers" or "Led technical direction for 3-person squad"',
          'implementation':
              'Quantify all leadership mentions with team sizes, project scope, and duration',
        },
        {
          'area': 'Modern Architecture Keywords',
          'current_issue':
              'Missing buzzwords for ATS systems like "event-driven", "CQRS", "DDD"',
          'industry_impact':
              'These keywords are critical for passing ATS filters in senior engineering roles',
          'recommendation':
              'Add architectural patterns you\'ve used: microservices, event-driven, domain-driven design',
          'implementation':
              'Create an "Architecture & Patterns" subsection under technical skills',
        },
      ],

      // Competency Gap Analysis
      'competency_gap_analysis': {
        'essential_missing_skills': [
          'System Design at scale - Document experience with high-traffic systems (millions of users)',
          'Security best practices - Add any security audits, OWASP compliance, or security certifications',
          'Machine Learning/AI integration - Increasingly expected for senior roles in 2025',
        ],
        'recommended_skills': [
          'GraphQL API design - Growing industry standard',
          'Terraform/Infrastructure as Code - Critical for senior cloud positions',
          'Performance testing frameworks (k6, JMeter) - Shows proactive quality approach',
        ],
        'certifications': [
          'AWS Solutions Architect Professional - Industry gold standard',
          'Certified Kubernetes Administrator (CKA) - Validates container orchestration expertise',
          'Google Professional Cloud Architect - Valuable for multi-cloud roles',
        ],
      },

      // Skills (existing with enhancement)
      'skills': {
        'technical': [
          'JavaScript/TypeScript',
          'React',
          'Node.js',
          'Python',
          'Java',
          'AWS',
          'Docker',
          'Kubernetes',
          'MongoDB',
          'PostgreSQL',
          'REST APIs',
          'GraphQL',
          'Microservices',
          'CI/CD',
        ],
        'soft': [
          'Team Leadership',
          'Agile/Scrum',
          'Technical Mentoring',
          'Code Review',
          'Stakeholder Communication',
          'Problem Solving',
        ],
        'domain': [
          'Cloud Architecture',
          'System Design',
          'Database Design',
          'Performance Optimization',
          'DevOps',
          'Security Best Practices',
        ],
      },

      // Experience Optimization
      'experience_optimization': {
        'quantification_opportunities': [
          'Current: "Developed payment processing system" → Add: Processing volume, transaction value, or uptime metrics',
          'Current: "Optimized database queries" → Add: Specific % improvement in query time or cost savings',
          'Current: "Led migration to microservices" → Add: Number of services, team size, timeline, impact on deployment frequency',
        ],
        'industry_specific_improvements': [
          'For SaaS: Emphasize uptime/availability (99.9% SLA), scalability (handles X concurrent users)',
          'For Tech: Highlight deployment frequency, CI/CD automation, test coverage percentages',
          'For Cloud: Add infrastructure cost optimizations, resource efficiency gains',
        ],
      },

      // Experience (existing)
      'experience': {
        'summary':
            '7+ years of progressive experience in software engineering, specializing in full-stack development and cloud architecture.',
        'yearsOfExperience': 7,
        'keyAchievements': [
          'Led migration of monolithic application to microservices architecture',
          'Architected and implemented real-time analytics dashboard serving 10K+ users',
          'Mentored 5+ junior developers, 3 promoted to mid-level positions',
        ],
        'companies': [
          'Tech Startup Inc.',
          'Enterprise Corp',
          'Innovation Labs',
        ],
        'jobTitles': [
          'Senior Software Engineer',
          'Software Engineer',
          'Junior Developer',
        ],
      },

      // Resume Structure Recommendations
      'resume_structure_recommendations': {
        'format_optimization': [
          'Move technical skills section above experience for tech roles (recruiters scan for tech stack first)',
          'Add a brief "Career Highlights" section at the top with 3-4 key achievements',
          'Use reverse chronological order (most recent first) which is industry standard',
        ],
        'ats_optimization': [
          'Missing keywords: "event-driven architecture", "observability", "SRE practices"',
          'Overused: "responsible for" (24 times) - replace with action verbs',
          'Add industry-standard acronyms: SOLID principles, REST, gRPC, CI/CD pipeline',
        ],
        'missing_elements': [
          'GitHub profile link - Critical for engineering roles to showcase code',
          'Technical blog or portfolio website - Shows thought leadership',
          'Notable open-source contributions section - Differentiates senior candidates',
        ],
      },

      // Market Positioning Assessment
      'market_positioning': {
        'market_competitiveness':
            'High - Profile is competitive for senior engineering roles at most tech companies',
        'suitable_positions': [
          'Senior Software Engineer (Full-Stack)',
          'Technical Lead',
          'Engineering Manager',
          'Solutions Architect',
          'Staff Engineer',
        ],
        'salary_range':
            '\$130,000 - \$180,000 USD (varies by location and company size)',
        'career_trajectory': {
          'natural_next_step': 'Technical Lead or Senior Staff Engineer',
          'stretch_positions': [
            'Engineering Manager with people management responsibilities',
            'Principal Engineer with company-wide technical influence',
          ],
          'alternative_paths': [
            'Solutions Architect (client-facing technical leadership)',
            'DevOps/SRE Lead (infrastructure specialization)',
          ],
        },
      },

      // Tailored Action Plan
      'action_plan': {
        'immediate_fixes': [
          'Add quantifiable metrics to top 5 achievements (2-3 hours)',
          'Include GitHub profile URL and ensure it shows recent activity',
          'Add "Architecture & Design Patterns" skill subsection',
          'Update LinkedIn to match resume exactly',
        ],
        'short_term': [
          'Complete AWS Solutions Architect Professional certification (1-2 months)',
          'Write 2-3 technical blog posts about recent projects for portfolio',
          'Document system design case study from a major project',
          'Request LinkedIn recommendations from managers and peers',
        ],
        'strategic_goals': [
          'Build presence in tech community: conference talks or tech meetups',
          'Contribute to major open-source project (create PR track record)',
          'Develop expertise in emerging tech (AI/ML, serverless, edge computing)',
          'Prepare for technical leadership: read books on engineering management',
        ],
      },

      // Interview Preparation
      'interview_preparation': {
        'likely_questions': [
          'Describe your most complex system design. What were the tradeoffs?',
          'Tell me about a time you had to make a critical architectural decision under pressure',
          'How do you approach code reviews and mentoring junior developers?',
          'Explain a production incident you handled. What did you learn?',
          'How do you stay current with rapidly changing technology?',
        ],
        'areas_of_scrutiny': [
          'Gap in resume between 2020-2021 (be prepared to explain)',
          'Limited experience with ML/AI (growing expectation for senior roles)',
          'Transition from individual contributor to technical lead (assess readiness)',
        ],
      },

      // Competitive Analysis
      'competitive_analysis': {
        'unique_advantages': [
          'Strong combination of full-stack AND DevOps capabilities (rare blend)',
          'Proven mentoring track record with measurable outcomes',
          'Public speaking and community involvement shows communication skills',
        ],
        'competitive_gaps': [
          'Many senior candidates have 10+ years experience vs your 7 years',
          'Limited experience with AI/ML which is increasingly table-stakes',
          'No formal people management experience for EM roles',
        ],
        'positioning_strategy':
            'Position yourself as a "technical leader without the title" - emphasize mentoring, '
            'technical decision-making, and cross-team collaboration. For pure IC roles, highlight '
            'depth of technical expertise and ability to solve complex problems independently.',
      },

      // Industry-Specific Insights
      'industry_insights':
          'The software engineering market in 2025 shows strong demand for senior engineers with cloud-native expertise. '
          'Companies are prioritizing candidates who can work across the full stack and have DevOps mindset. '
          'AI/ML integration is becoming expected knowledge even for non-ML roles. Remote work is standard, '
          'expanding your market to global opportunities. Salary trends show 15-20% premium for cloud + '
          'Kubernetes expertise. Certifications still matter, especially AWS and Kubernetes. '
          'Technical leadership skills (mentoring, system design) are differentiating factors for senior roles.',

      // Confidence Levels
      'confidence_levels': {
        'role_detection': 'High',
        'industry_identification': 'High',
        'career_level': 'High',
      },

      // Legacy fields for backwards compatibility
      'strengths': [
        'Strong technical foundation',
        'Good career progression',
        'Modern technology stack',
      ],
      'improvements': [
        'Add more quantifiable achievements',
        'Strengthen leadership examples',
      ],
      'interviewTips': [
        'Prepare STAR method examples',
        'Practice system design problems',
      ],
      'jobRecommendations': [
        'Senior Software Engineer',
        'Technical Lead',
        'Engineering Manager',
      ],
      'atsOptimization': {
        'score': 7.5,
        'issues': ['Missing keywords', 'Inconsistent formatting'],
        'suggestions': [
          'Add more industry terms',
          'Use standard section headings',
        ],
      },
      'keywordAnalysis': {
        'relevantKeywords': ['microservices', 'cloud', 'agile'],
        'missingKeywords': ['observability', 'event-driven'],
        'keywordDensity': 'Moderate',
      },
    };
  }

  /// Generate a sample PDF with enhanced data
  static Future<void> generateSamplePdf() async {
    try {
      final sampleData = getSampleAnalysisData();

      final pdfPath = await PdfService.generateAnalysisReport(
        analysisData: sampleData,
        resumeFileName: 'John_Doe_Resume.pdf',
      );

      if (pdfPath != null) {
        debugPrint('✅ Enhanced PDF generated successfully: $pdfPath');
      } else {
        debugPrint('❌ Failed to generate PDF');
      }
    } catch (e) {
      debugPrint('❌ Error generating sample PDF: $e');
    }
  }

  /// Generate PDF from actual analysis result
  static Future<String?> generateFromAnalysis({
    required Map<String, dynamic> analysisResult,
    required String resumeFileName,
  }) async {
    try {
      return await PdfService.generateAnalysisReport(
        analysisData: analysisResult,
        resumeFileName: resumeFileName,
      );
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      return null;
    }
  }
}
