// lib/core/models/short_model.dart
//
// Admin shorts.php returns:
// {
//   "id":1,
//   "title":"...",
//   "youtube_url":"...",
//   "video_id":"abc123",
//   "thumbnail":"https://img.youtube.com/...",
//   "category":"...",
//   "duration":58,
//   "created_at":"..."
// }

class ShortModel {
  final int id;
  final String title;
  final String url;
  final String videoId;
  final String thumbnailUrl;
  final String category;
  final String platform;
  final int durationSeconds;
  final String createdAt;

  ShortModel({
    required this.id,
    required this.title,
    required this.url,
    required this.videoId,
    required this.thumbnailUrl,
    required this.category,
    required this.platform,
    required this.durationSeconds,
    required this.createdAt,
  });

  String get durationLabel {
    if (durationSeconds <= 0) return '';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  factory ShortModel.fromJson(Map<String, dynamic> j) {
    final url = (j['youtube_url'] ?? j['url'] ?? '').toString();
    String platform = (j['platform'] ?? '').toString().toUpperCase();
    if (platform.isEmpty) {
      final lower = url.toLowerCase();
      if (lower.contains('instagram')) {
        platform = 'INSTAGRAM';
      } else if (lower.contains('facebook') || lower.contains('fb.watch')) {
        platform = 'FACEBOOK';
      } else if (lower.contains('t.me') || lower.contains('telegram')) {
        platform = 'TELEGRAM';
      } else {
        platform = 'YOUTUBE';
      }
    }

    return ShortModel(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: (j['title'] ?? '').toString(),
      url: url,
      videoId: (j['video_id'] ?? '').toString(),
      thumbnailUrl: (j['thumbnail'] ?? j['thumbnail_url'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      platform: platform,
      durationSeconds: (j['duration'] as num?)?.toInt() ?? 0,
      createdAt: (j['created_at'] ?? '').toString(),
    );
  }
}
