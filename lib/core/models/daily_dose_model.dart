class DailyDoseModel {
  final int    id;
  final String title;
  final String content;
  final String imageUrl;
  final String category;
  final String doseDate;

  DailyDoseModel({
    required this.id, required this.title, required this.content,
    required this.imageUrl, required this.category, required this.doseDate,
  });

  factory DailyDoseModel.fromJson(Map<String, dynamic> j) => DailyDoseModel(
    id:       j['id']        ?? 0,
    title:    j['title']     ?? '',
    content:  j['content']   ?? '',
    imageUrl: j['image_url'] ?? '',
    category: j['category']  ?? '',
    doseDate: j['dose_date'] ?? '',
  );
}
