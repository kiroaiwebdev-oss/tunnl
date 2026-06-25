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
    final lower = url.toLowerCase().split('?').first;

    // A direct video file is ALWAYS a local upload — regardless of whatever
    // platform label is stored (older rows may wrongly say "youtube").
    final isDirectVideo = lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.m3u8');

    String platform = (j['platform'] ?? '').toString().toUpperCase();
    if (isDirectVideo) {
      platform = 'LOCAL';
    } else if (platform.isEmpty || platform == 'LOCAL') {
      // Empty (or mislabeled LOCAL on a non-file URL) → sniff from the URL.
      final l = url.toLowerCase();
      if (l.contains('instagram')) {
        platform = 'INSTAGRAM';
      } else if (l.contains('facebook') || l.contains('fb.watch')) {
        platform = 'FACEBOOK';
      } else if (l.contains('t.me') || l.contains('telegram')) {
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
