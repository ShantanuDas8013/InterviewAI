class JobRoleModel {
  final String id;
  final String title;
  final String category;
  final String? description;
  final List<String> requiredSkills;
  final List<String>? experienceLevels;
  final String? industry;
  final String? averageSalaryRange;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobRoleModel({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    required this.requiredSkills,
    this.experienceLevels,
    this.industry,
    this.averageSalaryRange,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobRoleModel.fromJson(Map<String, dynamic> json) {
    return JobRoleModel(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      description: json['description'],
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      experienceLevels: json['experience_levels'] != null
          ? List<String>.from(json['experience_levels'])
          : null,
      industry: json['industry'],
      averageSalaryRange: json['average_salary_range'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'required_skills': requiredSkills,
      'experience_levels': experienceLevels,
      'industry': industry,
      'average_salary_range': averageSalaryRange,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}