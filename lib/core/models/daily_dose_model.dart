// lib/core/models/daily_dose_model.dart

class DailyDoseModel {
  final int id;
  final String title;
  final String content;
  final String type;
  final String example;
  final String tip;
  final String doseDate;
  final bool hasVideo;
  final String videoUrl;
  final String imageUrl;
  final String category;

  DailyDoseModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.example,
    required this.tip,
    required this.doseDate,
    required this.hasVideo,
    required this.videoUrl,
    required this.imageUrl,
    required this.category,
  });

  factory DailyDoseModel.fromJson(Map<String, dynamic> j) => DailyDoseModel(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: (j['title'] ?? '').toString(),
        content: (j['content'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        example: (j['example'] ?? '').toString(),
        tip: (j['tip'] ?? '').toString(),
        doseDate: (j['dose_date'] ?? '').toString(),
        hasVideo: j['has_video'] == 1 || j['has_video'] == true,
        videoUrl: (j['video_url'] ?? '').toString(),
        imageUrl: (j['image_url'] ?? '').toString(),
        category: (j['category'] ?? j['type'] ?? '').toString(),
      );
}
