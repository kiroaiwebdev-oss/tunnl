class TrickModel {
  final int    id;
  final int    chapterNumber;
  final String title;
  final String subtitle;
  final String category;
  final String difficulty;
  final bool   hasVideo;
  final String videoUrl;
  final bool   hasArticle;
  final String articleContent;
  final bool   isNew;

  TrickModel({
    required this.id, required this.chapterNumber, required this.title,
    required this.subtitle, required this.category, required this.difficulty,
    required this.hasVideo, required this.videoUrl,
    required this.hasArticle, required this.articleContent, required this.isNew,
  });

  factory TrickModel.fromJson(Map<String, dynamic> j) => TrickModel(
    id:             j['id']              ?? 0,
    chapterNumber:  j['chapter_number']  ?? 0,
    title:          j['title']           ?? '',
    subtitle:       j['subtitle']        ?? '',
    category:       j['category']        ?? '',
    difficulty:     j['difficulty']      ?? 'Beginner',
    hasVideo:       j['has_video']       == 1 || j['has_video'] == true,
    videoUrl:       j['video_url']       ?? '',
    hasArticle:     j['has_article']     == 1 || j['has_article'] == true,
    articleContent: j['article_content'] ?? '',
    isNew:          j['is_new']          == 1 || j['is_new'] == true,
  );
}
