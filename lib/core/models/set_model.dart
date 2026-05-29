class SetModel {
  final int    id;
  final String category;
  final String title;
  final String level;
  final int    totalQuestions;
  final bool   isLocked;
  final bool   isPremium;
  final int    setNumber;

  SetModel({
    required this.id, required this.category, required this.title,
    required this.level, required this.totalQuestions,
    required this.isLocked, required this.isPremium, required this.setNumber,
  });

  factory SetModel.fromJson(Map<String, dynamic> j) => SetModel(
    id:             j['id']              ?? 0,
    category:       j['category']        ?? '',
    title:          j['title']           ?? '',
    level:          j['level']           ?? 'beginner',
    totalQuestions: j['total_questions'] ?? 50,
    isLocked:       j['is_locked']       == 1 || j['is_locked'] == true,
    isPremium:      j['is_premium']      == 1 || j['is_premium'] == true,
    setNumber:      j['set_number']      ?? 0,
  );
}
