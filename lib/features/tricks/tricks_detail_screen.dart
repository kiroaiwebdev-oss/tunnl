import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';

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

  String get _videoDuration => (widget.data['duration'] ?? '').toString();

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
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _openVideo() async {
    if (_videoUrl.isEmpty) return;
    final uri = Uri.parse(_videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.darkCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: Text('Could not open video link!',
              style: GoogleFonts.poppins(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = widget.data['hasVideo'] == true && _videoUrl.isNotEmpty;
    final hasArticle =
        widget.data['hasArticle'] == true && _articleContent.trim().isNotEmpty;

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
            Text('No content yet',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Admin will publish this trick soon.',
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
                  'CHAPTER ${widget.data['chapter'] ?? ''}',
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
              color: diffColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: diffColor.withOpacity(0.3),
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
            color: AppColors.textMuted.withOpacity(0.15),
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
                        'ARTICLE',
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
                        'VIDEO',
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── VIDEO SECTION (admin-driven) ──────────────────
  Widget _buildVideoSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Video thumbnail card
          GestureDetector(
            onTap: _openVideo,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1A0A0A),
                          Color(0xFF2A1515),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF6B6B),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B)
                                .withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  if (_videoDuration.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _videoDuration,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'TAP TO WATCH',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                color: AppColors.textMuted.withOpacity(0.1),
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
                        'Duration: $_videoDuration',
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

          const SizedBox(height: 16),

          // Open video button
          GestureDetector(
            onTap: _openVideo,
            child: Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000).withOpacity(0.1),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFFFF0000).withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_rounded,
                    color: Color(0xFFFF0000),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WATCH VIDEO',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF0000),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
