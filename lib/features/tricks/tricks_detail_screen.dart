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

  // Dummy article content — Admin se aayega
  final List<Map<String, dynamic>> _articleContent = [
    {
      'type': 'heading',
      'text': 'What is this Trick?',
    },
    {
      'type': 'text',
      'text':
          'This powerful Vedic Math technique allows you to multiply two 2-digit numbers in just a few seconds without using a calculator. Once mastered, you can solve problems 5x faster than traditional methods.',
    },
    {
      'type': 'heading',
      'text': 'How it Works',
    },
    {
      'type': 'text',
      'text':
          'The method involves three simple steps:\n\n1. Multiply the units digits\n2. Cross multiply and add\n3. Multiply the tens digits',
    },
    {
      'type': 'example',
      'problem': '23 × 14 = ?',
      'steps': [
        'Step 1: 3 × 4 = 12 (write 2, carry 1)',
        'Step 2: (2×4) + (3×1) + 1 = 12 (write 2, carry 1)',
        'Step 3: 2 × 1 + 1 = 3',
        'Answer: 322 ✓',
      ],
    },
    {
      'type': 'heading',
      'text': 'Practice Examples',
    },
    {
      'type': 'text',
      'text': 'Try these on your own:\n• 32 × 21\n• 45 × 13\n• 67 × 24\n• 89 × 32',
    },
    {
      'type': 'tip',
      'text':
          '💡 Pro Tip: Practice this method daily for 10 minutes. Within a week, you\'ll be solving these mentally!',
    },
  ];

  // Dummy video — Admin se YouTube link aayega
  final String _videoUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
  final String _videoThumbnail = '';
  final String _videoDuration = '5:24';

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
    final uri = Uri.parse(_videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = widget.data['hasVideo'] == true;
    final hasArticle = widget.data['hasArticle'] == true;

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
                  child: _selectedTab == 0
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

  // ── APP BAR ───────────────────────────────────────
  Widget _buildAppBar() {
    final Color diffColor = widget.data['diffColor'] as Color;

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
                  'CHAPTER ${widget.data['chapter']}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.neonCyan,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.data['title'],
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
              widget.data['difficulty'],
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

  // ── ARTICLE CONTENT ───────────────────────────────
  Widget _buildArticle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration chip
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                widget.data['duration'],
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Article blocks
          ..._articleContent.map((block) {
            switch (block['type']) {
              case 'heading':
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    block['text'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                );

              case 'text':
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    block['text'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                );

              case 'example':
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.neonCyan.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Problem
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          block['problem'],
                          style: GoogleFonts.orbitron(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neonCyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Steps
                      ...(block['steps'] as List<String>).map(
                        (step) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(
                                    top: 6, right: 8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.neonCyan,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  step,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );

              case 'tip':
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.yellow.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    block['text'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.yellow,
                      height: 1.5,
                    ),
                  ),
                );

              default:
                return const SizedBox();
            }
          }),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── VIDEO SECTION ─────────────────────────────────
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
                  // Background gradient
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

                  // Play button center
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

                  // Duration chip
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

                  // Tap to open label
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
                  widget.data['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.data['subtitle'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
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
            ),
          ),

          const SizedBox(height: 16),

          // Open in YouTube button
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
                    'OPEN IN YOUTUBE',
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