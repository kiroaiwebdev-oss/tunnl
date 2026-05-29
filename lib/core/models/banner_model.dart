// lib/core/models/banner_model.dart

class BannerModel {
  final int id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String actionValue;

  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.actionValue,
  });

  factory BannerModel.fromJson(Map<String, dynamic> j) {
    return BannerModel(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: (j['title'] ?? '').toString(),
      subtitle: (j['subtitle'] ?? '').toString(),
      imageUrl: (j['image_url'] ?? '').toString(),
      actionValue: (j['action_value'] ?? 'mcq').toString(),
    );
  }

  @override
  String toString() => 'BannerModel(id:$id, title:$title, action:$actionValue)';
}
