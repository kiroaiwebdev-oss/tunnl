import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_strings.dart';
import '../../core/widgets/in_app_video_player.dart';
import '../../core/widgets/score_dialog.dart';
import '../question/question_screen.dart';
import '../result/set_solution_screen.dart';
import '../result/set_leaderboard_screen.dart';

class TricksDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const TricksDetailScreen({super.key, required this.data});

  @override
  State<TricksDetailScreen> createState() => _TricksDetailScreenState();
}

class _TricksDetailScreenState extends State<TricksDetailScreen>
    with SingleTickerProviderStateMixin {

  int _selectedTab = 0; // 0=Article, 1=Video
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;

  // ── Admin-driven content ──────────────────────────
  // The article content comes straight from the admin panel
  // (tricks.article_content). We render it as readable paragraphs so whatever
  // the admin types is exactly what the user sees — no dummy data.
  String get _articleContent =>
      (widget.data['articleContent'] ?? '').toString();

  String get _videoUrl => (widget.data['videoUrl'] ?? '').toString();

  String get _imageUrl => (widget.data['imageUrl'] ?? '').toString();

  String get _videoDuration => (widget.data['duration'] ?? '').toString();

  // Rich content blocks (text / heading / image / video) — admin-built order.
  List<Map<String, dynamic>> get _articleBlocks {
    final b = widget.data['articleBlocks'];
    if (b is List) {
      return b
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  // Practice MCQ set the user takes AFTER reading the article (0 = general).
  int get _practiceSetId =>
      (widget.data['practiceSetId'] as num?)?.toInt() ?? 0;

  // Rich article as HTML (from the admin WYSIWYG editor). Preferred renderer.
  String get _articleHtml => (widget.data['articleHtml'] ?? '').toString();

  // Whether the user already completed this trick's practice set.
  bool _practiceDone = false;

  Future<void> _loadPracticeDone() async {
    if (_practiceSetId <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('completed_sets_tricks');
      if (raw != null) {
        final list = (jsonDecode(raw) as List).map((e) => (e as num).toInt());
        if (mounted) {
          setState(() => _practiceDone = list.contains(_practiceSetId));
        }
      }
    } catch (_) {}
  }

  Future<void> _markPracticeDone() async {
    if (_practiceSetId <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('completed_sets_tricks');
      final set = <int>{};
      if (raw != null) {
        for (final e in (jsonDecode(raw) as List)) {
          set.add((e as num).toInt());
        }
      }
      set.add(_practiceSetId);
      await prefs.setString('completed_sets_tricks', jsonEncode(set.toList()));
      if (mounted) setState(() => _practiceDone = true);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    // Auto select tab based on available content
    if (widget.data['hasArticle'] == true) {
      _selectedTab = 0;
    } else if (widget.data['hasVideo'] == true) {
      _selectedTab = 1;
    }

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _loadPracticeDone();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = widget.data['hasVideo'] == true && _videoUrl.isNotEmpty;
    final hasArticle =
        (widget.data['hasArticle'] == true && _articleContent.trim().isNotEmpty)
            || _imageUrl.isNotEmpty
            || _articleBlocks.isNotEmpty
            || _articleHtml.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashBg),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // ── AppBar
                _buildAppBar(),

                // ── Tab selector (only if both available)
                if (hasVideo && hasArticle) _buildTabSelector(),

                // ── Content
                Expanded(
                  child: !hasArticle && !hasVideo
                      ? _buildEmpty()
                      : (_selectedTab == 0 && hasArticle) || !hasVideo
                          ? _buildArticle()
                          : _buildVideoSection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── EMPTY ─────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(tr('No content yet'),
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(tr('Admin will publish this trick soon.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────
  Widget _buildAppBar() {
    final Color diffColor =
        (widget.data['diffColor'] as Color?) ?? AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.neonCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHAPTER ${widget.data['chapter'] ?? ''}'.replaceFirst('CHAPTER', tr('CHAPTER')),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.neonCyan,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  (widget.data['title'] ?? '').toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: diffColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: diffColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              (widget.data['difficulty'] ?? '').toString(),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: diffColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB SELECTOR ──────────────────────────────────
  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Article tab
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0
                        ? AppColors.neonCyan
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_rounded,
                        size: 14,
                        color: _selectedTab == 0
                            ? AppColors.darkBg
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        tr('ARTICLE'),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _selectedTab == 0
                              ? AppColors.darkBg
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Video tab
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1
                        ? const Color(0xFFFF6B6B)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_rounded,
                        size: 14,
                        color: _selectedTab == 1
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        tr('VIDEO'),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _selectedTab == 1
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ARTICLE CONTENT (admin-driven) ────────────────
  Widget _buildArticle() {
    final subtitle = (widget.data['subtitle'] ?? '').toString();
    final duration = (widget.data['duration'] ?? '').toString();

    // Split the admin article into paragraphs. Lines that look like a short
    // heading (no trailing period and reasonably short) get rendered as a
    // heading for nicer reading — purely presentational, content stays as-is.
    final paragraphs = _articleContent
        .replaceAll('\r\n', '\n')
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (c, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 160,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const CircularProgressIndicator(
                            color: AppColors.neonCyan),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (duration.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.neonCyan,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_articleHtml.trim().isNotEmpty)
            ..._buildHtmlContent()
          else if (_articleBlocks.isNotEmpty)
            ..._buildBlockWidgets()
          else
            ...paragraphs.map((para) {
              final isHeading = para.length <= 60 &&
                  !para.endsWith('.') &&
                  !para.contains('\n');
              return Padding(
                padding: EdgeInsets.only(top: isHeading ? 14 : 0, bottom: 10),
                child: Text(
                  para,
                  style: GoogleFonts.poppins(
                    fontSize: isHeading ? 16 : 13,
                    fontWeight:
                        isHeading ? FontWeight.w700 : FontWeight.w400,
                    color: isHeading ? Colors.white : AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),
          _buildPracticeButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Practice MCQ (taken after reading the article) ──
  Widget _buildPracticeButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.neonCyan.withValues(alpha: 0.10),
          AppColors.neonCyan.withValues(alpha: 0.02),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded,
                  color: AppColors.neonCyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr('Ready? Test what you learnt'),
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(tr('Take a quick practice MCQ — you get a score, full solution and a Hindi/English toggle.'),
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _onPracticeTap,
            child: Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00ACC1)],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_practiceDone ? Icons.more_horiz_rounded : Icons.quiz_rounded,
                      color: AppColors.darkBg, size: 20),
                  const SizedBox(width: 8),
                  Text(_practiceDone ? tr('PRACTICE OPTIONS') : tr('TAKE PRACTICE TEST'),
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBg,
                          letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _practiceTitle =>
      (widget.data['title'] ?? '').toString();

  // First time → start the test. Already attempted → show the same options as
  // every other set: Reattempt · View Solution · View Leaderboard · View Score.
  void _onPracticeTap() {
    if (_practiceDone && _practiceSetId > 0) {
      _showPracticeChooser();
    } else {
      _startPractice();
    }
  }

  Future<void> _startPractice() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuestionScreen(
        mode: 'mcq',
        category: 'tricks',
        setId: _practiceSetId,
        headerLabel: _practiceTitle,
        onSetCompleted: _markPracticeDone,
      ),
    ));
    if (mounted) _loadPracticeDone();
  }

  void _showPracticeChooser() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(_practiceTitle.isNotEmpty ? _practiceTitle : tr('Practice'),
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _chooserBtn(Icons.replay_rounded, tr('Reattempt'),
                  AppColors.neonCyan, true, () {
                Navigator.pop(ctx);
                _startPractice();
              }),
              const SizedBox(height: 12),
              _chooserBtn(Icons.lightbulb_rounded, tr('View Solution'),
                  AppColors.yellow, false, () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SetSolutionScreen(
                      setId: _practiceSetId, title: _practiceTitle),
                ));
              }),
              const SizedBox(height: 12),
              _chooserBtn(Icons.emoji_events_rounded, tr('View Leaderboard'),
                  AppColors.orange, false, () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SetLeaderboardScreen(
                      setId: _practiceSetId, title: _practiceTitle),
                ));
              }),
              const SizedBox(height: 12),
              _chooserBtn(Icons.bar_chart_rounded, tr('View Score'),
                  AppColors.neonCyan, false, () {
                Navigator.pop(ctx);
                showSetScoreDialog(context,
                    setId: _practiceSetId, title: _practiceTitle);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chooserBtn(IconData icon, String label, Color color, bool filled,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: filled ? 1 : 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: filled ? AppColors.darkBg : color),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: filled ? AppColors.darkBg : color)),
          ],
        ),
      ),
    );
  }

  // ── Render the rich article HTML (admin WYSIWYG) — text, inline images,
  //    and any inline videos (split out to play in-app). No external package:
  //    a lightweight parser handles the limited tag set the editor produces. ──
  List<Widget> _buildHtmlContent() {
    final widgets = <Widget>[];
    final html = _articleHtml;
    final re = RegExp(
      r'<div[^>]*class="[^"]*tunnl-video[^"]*"[^>]*data-url="([^"]*)"[^>]*>.*?<\/div>',
      dotAll: true,
      caseSensitive: false,
    );
    int last = 0;
    for (final m in re.allMatches(html)) {
      final before = html.substring(last, m.start);
      if (before.trim().isNotEmpty) widgets.addAll(_htmlToWidgets(before));
      final url = (m.group(1) ?? '').replaceAll('&quot;', '').trim();
      if (url.isNotEmpty && InAppVideoPlayer.canPlayInline(url)) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: InAppVideoPlayer(url: url, autoPlay: false),
        ));
      }
      last = m.end;
    }
    final tail = html.substring(last);
    if (tail.trim().isNotEmpty) widgets.addAll(_htmlToWidgets(tail));
    if (widgets.isEmpty) widgets.addAll(_htmlToWidgets(html));
    return widgets;
  }

  // Minimal HTML → widgets for the editor's tag set: h1-h3, p, li, img, br.
  List<Widget> _htmlToWidgets(String input) {
    final widgets = <Widget>[];
    final s = input.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    final token = RegExp(
      r'<h([1-3])[^>]*>(.*?)<\/h\1>|<li[^>]*>(.*?)<\/li>|<img[^>]*src="([^"]*)"[^>]*>|<p[^>]*>(.*?)<\/p>',
      dotAll: true,
      caseSensitive: false,
    );

    void addText(String raw) {
      final t = _stripTags(raw);
      if (t.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(t,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.7)),
        ));
      }
    }

    int last = 0;
    for (final m in token.allMatches(s)) {
      addText(s.substring(last, m.start));
      if (m.group(2) != null) {
        // heading
        final level = int.tryParse(m.group(1) ?? '2') ?? 2;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Text(_stripTags(m.group(2)!),
              style: GoogleFonts.poppins(
                  fontSize: level == 1 ? 20 : (level == 2 ? 17 : 15),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4)),
        ));
      } else if (m.group(3) != null) {
        // list item
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ',
                  style: TextStyle(color: AppColors.neonCyan, fontSize: 14)),
              Expanded(
                child: Text(_stripTags(m.group(3)!),
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6)),
              ),
            ],
          ),
        ));
      } else if (m.group(4) != null) {
        // image
        final src = (m.group(4) ?? '').trim();
        if (src.isNotEmpty) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                src,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (c, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 150,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const CircularProgressIndicator(
                            color: AppColors.neonCyan),
                      ),
              ),
            ),
          ));
        }
      } else if (m.group(5) != null) {
        // paragraph
        addText(m.group(5)!);
      }
      last = m.end;
    }
    addText(s.substring(last));
    return widgets;
  }

  // Strip remaining HTML tags + decode the few entities the editor emits.
  String _stripTags(String html) {
    var t = html.replaceAll(RegExp(r'<[^>]+>'), '');
    t = t
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return t.trim();
  }

  // ── Render admin-built rich content blocks in order ──
  List<Widget> _buildBlockWidgets() {
    final widgets = <Widget>[];
    for (final b in _articleBlocks) {
      final type = (b['type'] ?? '').toString();
      final text = (b['text'] ?? '').toString();
      final url = (b['url'] ?? '').toString();

      if (type == 'heading' && text.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4)),
        ));
      } else if (type == 'text' && text.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.7)),
        ));
      } else if (type == 'image' && url.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              url,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              loadingBuilder: (c, child, progress) => progress == null
                  ? child
                  : Container(
                      height: 160,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const CircularProgressIndicator(
                          color: AppColors.neonCyan),
                    ),
            ),
          ),
        ));
      } else if (type == 'video' && url.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InAppVideoPlayer.canPlayInline(url)
              ? InAppVideoPlayer(url: url, autoPlay: false)
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.textMuted.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.videocam_off_rounded,
                          color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(tr('Video unavailable'),
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
        ));
      }
    }
    return widgets;
  }

  // ── VIDEO SECTION (admin-driven, plays IN-APP) ───
  Widget _buildVideoSection() {
    final inline = InAppVideoPlayer.canPlayInline(_videoUrl);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Inline player (YouTube embed or uploaded MP4) — never leaves app.
          if (inline)
            InAppVideoPlayer(url: _videoUrl, autoPlay: false)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.videocam_off_rounded,
                      color: AppColors.textMuted, size: 40),
                  const SizedBox(height: 10),
                  Text(tr('No playable video set'),
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(tr('Admin can add a YouTube link or upload a video.'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Video info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textMuted.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (widget.data['title'] ?? '').toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if ((widget.data['subtitle'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    (widget.data['subtitle'] ?? '').toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (_videoDuration.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${tr('Duration:')} $_videoDuration',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
