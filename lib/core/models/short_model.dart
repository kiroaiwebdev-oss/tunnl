class ShortModel {
  final int    id;
  final String platform;
  final String title;
  final String url;
  final String thumbnailUrl;

  ShortModel({
    required this.id, required this.platform,
    required this.title, required this.url, required this.thumbnailUrl,
  });

  factory ShortModel.fromJson(Map<String, dynamic> j) => ShortModel(
    id:           j['id']            ?? 0,
    platform:     j['platform']      ?? 'youtube',
    title:        j['title']         ?? '',
    url:          j['url']           ?? '',
    thumbnailUrl: j['thumbnail_url'] ?? '',
  );
}
