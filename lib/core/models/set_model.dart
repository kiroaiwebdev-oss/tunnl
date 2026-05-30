// lib/core/models/set_model.dart

class SetModel {
  final int id;
  final String category;
  final String title;
  final String examName;
  final String level;
  final int totalQuestions;
  final int questionCount;
  final bool isLocked;
  final bool isPremium;
  final bool canAccess;
  final int setNumber;

  SetModel({
    required this.id,
    required this.category,
    required this.title,
    required this.examName,
    required this.level,
    required this.totalQuestions,
    required this.questionCount,
    required this.isLocked,
    required this.isPremium,
    required this.canAccess,
    required this.setNumber,
  });

  factory SetModel.fromJson(Map<String, dynamic> j) => SetModel(
        id: (j['id'] as num?)?.toInt() ?? 0,
        category: (j['category'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        examName: (j['exam_name'] ?? '').toString(),
        level: (j['level'] ?? 'beginner').toString(),
        totalQuestions: (j['total_questions'] as num?)?.toInt() ?? 0,
        questionCount: (j['question_count'] as num?)?.toInt() ??
            (j['total_questions'] as num?)?.toInt() ??
            0,
        isLocked: j['is_locked'] == 1 || j['is_locked'] == true,
        isPremium: j['is_premium'] == 1 || j['is_premium'] == true,
        canAccess: j['can_access'] == null
            ? true
            : (j['can_access'] == 1 || j['can_access'] == true),
        setNumber: (j['set_number'] as num?)?.toInt() ?? 0,
      );
}
