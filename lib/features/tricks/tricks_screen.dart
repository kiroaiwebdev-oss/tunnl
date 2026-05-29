import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../premium/premium_screen.dart';
import 'tricks_detail_screen.dart';

class TricksScreen extends StatefulWidget {
  final bool isPremium; // ✅ ADD

  const TricksScreen({
    super.key,
    this.isPremium = false, // ✅ default false
  });

  @override
  State<TricksScreen> createState() => _TricksScreenState();
}

class _TricksScreenState extends State<TricksScreen>
    with SingleTickerProviderStateMixin {

  int _selectedCategory = 0;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;

  final List<String> _categories = [
    'ALL', 'MULTIPLICATION', 'DIVISION', 'SQUARES', 'FRACTIONS', 'SHORTCUTS'
  ];

  final List<Map<String, dynamic>> _allTricks = [
    {
      'chapter': '01',
      'title': 'Vedic Multiplication',
      'subtitle': 'Multiply 2-digit numbers in seconds',
      'category': 'MULTIPLICATION',
      'hasVideo': true,
      'hasArticle': true,
      'duration': '8 min read • 5 min video',
      'difficulty': 'Beginner',
      'diffColor': AppColors.success,
      'isNew': true,
    },
    {
      'chapter': '02',
      'title': 'Base Method',
      'subtitle': 'Multiply numbers near base 10, 100',
      'category': 'MULTIPLICATION',
      'hasVideo': true,
      'hasArticle': true,
      'duration': '10 min read • 7 min video',
      'difficulty': 'Beginner',
      'diffColor': AppColors.success,
      'isNew': false,
    },
    {
      'chapter': '03',
      'title': 'Squaring Ending in 5',
      'subtitle': 'Square any number ending with 5 instantly',
      'category': 'SQUARES',
      'hasVideo': true,
      'hasArticle': true,
      'duration': '5 min read • 3 min video',
      'difficulty': 'Beginner',
      'diffColor': AppColors.success,
      'isNew': false,
    },
    {
      'chapter': '04',
      'title': 'Division Shortcuts',
      'subtitle': 'Divide large numbers mentally',
      'category': 'DIVISION',
      'hasVideo': false,
      'hasArticle': true,
      'duration': '12 min read',
      'difficulty': 'Intermediate',
      'diffColor': AppColors.yellow,
      'isNew': false,
    },
    {
      'chapter': '05',
      'title': 'Fraction Simplification',
      'subtitle': 'Simplify complex fractions quickly',
      'category': 'FRACTIONS',
      'hasVideo': true,
      'hasArticle': true,
      'duration': '9 min read • 6 min video',
      'difficulty': 'Intermediate',
      'diffColor': AppColors.yellow,
      'isNew': true,
    },
    {
      'chapter': '06',
      'title': 'Percentage Tricks',
      'subtitle': 'Calculate percentages in 2 seconds',
      'category': 'SHORTCUTS',
      'hasVideo': true,
      'hasArticle': true,
      'duration': '7 min read • 4 min video',
      'difficulty': 'Intermediate',
      'diffColor': AppColors.yellow,
      'isNew': false,
    },
    {
      'chapter': '07',
      'title': 'Cube Root Tricks',
      'subtitle': 'Find cube roots of perfect cubes instantly',
      'category': 'SHORTCUTS',
      'hasVideo': false,
      'hasArticle': true,
      'duration': '15 min read',
      'difficulty': 'Advanced',
      'diffColor': AppColors.error,
      'isNew': false,
    },
    {
      'chapter': '08',
      'title': 'Cross Multiplication',
      'subtitle': 'Solve equations using cross method',
      'category': 'MULTIPLICATION',
      'hasVideo': true,
      'hasArticle': true,
      'duration': '11 min read • 8 min video',
      'difficulty': 'Advanced',
      'diffColor': AppColors.error,
      'isNew': false,
    },
  ];

  // ── Filtered list by category ─────────────────────
  List<Map<String, dynamic>> get _filteredTricks {
    if (_selectedCategory == 0) return _allTricks;
    final cat = _categories[_selectedCategory];
    return _allTricks.where((t) => t['category'] == cat).toList();
  }

  // ── 10% free limit apply ──────────────────────────
  // Free user = sirf pehle 10% tricks open
  // Premium = sab open
  int get _freeLimit {
    final total = _allTricks.length;
    return (total * 0.1).ceil().clamp(1, total); // minimum 1
  }

  bool _isLocked(int originalIndex) {
    if (widget.isPremium) return false;
    return originalIndex >= _freeLimit;
  }

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTricks;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashBg),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildAppBar(),
                _buildCategoryFilter(),

                // ── Free user banner
                if (!widget.isPremium) _buildFreeBanner(),

                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            // Original index — lock check ke liye
                            final originalIndex = _allTricks.indexOf(filtered[i]);
                            final locked = _isLocked(originalIndex);

                            return _TrickCard(
                              data:     filtered[i],
                              isLocked: locked,
                              onTap: () {
                                if (locked) {
                                  // Locked — Premium screen pe bhejo
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const PremiumScreen(),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TricksDetailScreen(
                                        data: filtered[i],
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── FREE BANNER ───────────────────────────────────
  Widget _buildFreeBanner() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_open_rounded,
              color: AppColors.orange,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: '$_freeLimit tricks free ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(text: '— Upgrade for all '),
                    TextSpan(
                      text: '${_allTricks.length} tricks',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '₹50',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────
  Widget _buildAppBar() {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TUNNEL TRICKS',
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Tips & Tricks to master Math',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.neonCyan.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              widget.isPremium
                  ? '${_allTricks.length} Tricks'
                  : '$_freeLimit/${_allTricks.length} Free',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: widget.isPremium
                    ? AppColors.neonCyan
                    : AppColors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CATEGORY FILTER ───────────────────────────────
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final isActive = _selectedCategory == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.neonCyan : AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.neonCyan
                      : AppColors.textMuted.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                _categories[i],
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? AppColors.darkBg
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── EMPTY ─────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Text(
        'No tricks in this category yet!',
        style: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// TRICK CARD
// ─────────────────────────────────────────────────────
class _TrickCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool                 isLocked;
  final VoidCallback         onTap;

  const _TrickCard({
    required this.data,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color diffColor = data['diffColor'] as Color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLocked
                ? AppColors.textMuted.withOpacity(0.08)
                : AppColors.neonCyan.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Chapter number box / Lock icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLocked
                    ? AppColors.textMuted.withOpacity(0.06)
                    : AppColors.neonCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLocked
                      ? AppColors.textMuted.withOpacity(0.1)
                      : AppColors.neonCyan.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: isLocked
                    ? const Icon(
                        Icons.lock_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      )
                    : Text(
                        data['chapter'],
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonCyan,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Title + NEW badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isLocked
                                ? AppColors.textMuted
                                : Colors.white,
                          ),
                        ),
                      ),
                      if (data['isNew'] == true && !isLocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Subtitle / Upgrade text
                  Text(
                    isLocked
                        ? 'Upgrade to Premium — ₹50 only'
                        : data['subtitle'],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isLocked
                          ? AppColors.orange.withOpacity(0.8)
                          : AppColors.textSecondary,
                    ),
                  ),

                  if (!isLocked) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // Difficulty badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: diffColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data['difficulty'],
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: diffColor,
                            ),
                          ),
                        ),

                        if (data['hasVideo'] == true)
                          const _FormatBadge(
                            icon: Icons.play_circle_rounded,
                            label: 'VIDEO',
                            color: Color(0xFFFF6B6B),
                          ),

                        if (data['hasArticle'] == true)
                          const _FormatBadge(
                            icon: Icons.article_rounded,
                            label: 'READ',
                            color: AppColors.neonCyan,
                          ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 3),
                          child: Text(
                            data['duration'],
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Arrow / Premium icon
            Icon(
              isLocked
                  ? Icons.workspace_premium_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: isLocked
                  ? AppColors.orange
                  : AppColors.textSecondary,
              size: isLocked ? 18 : 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// FORMAT BADGE WIDGET
// ─────────────────────────────────────────────────────
class _FormatBadge extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;

  const _FormatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}