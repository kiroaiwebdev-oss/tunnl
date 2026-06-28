// lib/core/models/trick_model.dart

class TrickModel {
  final int id;
  final int chapterNumber;
  final String title;
  final String subtitle;
  final String category;
  final String difficulty;
  final bool hasVideo;
  final String videoUrl;
  final int videoDurationSeconds;
  final bool hasArticle;
  final String articleContent;
  final int readDurationMinutes;
  final bool isNew;
  final bool isPremium;
  final String imageUrl;
  final List<Map<String, dynamic>> articleBlocks;
  final String articleHtml;
  final int practiceSetId;

  TrickModel({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.difficulty,
    required this.hasVideo,
    required this.videoUrl,
    required this.videoDurationSeconds,
    required this.hasArticle,
    required this.articleContent,
    required this.readDurationMinutes,
    required this.isNew,
    this.isPremium = false,
    this.imageUrl = '',
    this.articleBlocks = const [],
    this.articleHtml = '',
    this.practiceSetId = 0,
  });

  String get durationLabel {
    final parts = <String>[];
    if (hasArticle && readDurationMinutes > 0) {
      parts.add('$readDurationMinutes min read');
    }
    if (hasVideo && videoDurationSeconds > 0) {
      final m = (videoDurationSeconds / 60).ceil();
      parts.add('$m min video');
    }
    return parts.join(' • ');
  }

  factory TrickModel.fromJson(Map<String, dynamic> j) => TrickModel(
        id: (j['id'] as num?)?.toInt() ?? 0,
        chapterNumber: (j['chapter_number'] as num?)?.toInt() ?? 0,
        title: (j['title'] ?? '').toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
        category: (j['category'] ?? '').toString().toUpperCase(),
        difficulty: (j['difficulty'] ?? 'Beginner').toString(),
        hasVideo: j['has_video'] == 1 || j['has_video'] == true,
        videoUrl: (j['video_url'] ?? '').toString(),
        videoDurationSeconds: (j['video_duration'] as num?)?.toInt() ?? 0,
        hasArticle: j['has_article'] == 1 || j['has_article'] == true,
        articleContent: (j['article_content'] ?? '').toString(),
        readDurationMinutes: (j['read_duration'] as num?)?.toInt() ?? 0,
        isNew: j['is_new'] == 1 || j['is_new'] == true,
        isPremium: j['is_premium'] == 1 || j['is_premium'] == true,
        imageUrl: (j['image_url'] ?? '').toString(),
        articleBlocks: (j['article_blocks'] is List)
            ? (j['article_blocks'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : const [],
        articleHtml: (j['article_html'] ?? '').toString(),
        practiceSetId: (j['practice_set_id'] as num?)?.toInt() ?? 0,
      );
}
