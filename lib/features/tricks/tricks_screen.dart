// lib/features/tricks/tricks_screen.dart
//
// Loads tricks from admin/tricks.php

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/app_strings.dart';
import '../../core/services/content_service.dart';
import '../../core/models/trick_model.dart';
import '../premium/premium_screen.dart';
import 'tricks_detail_screen.dart';

class TricksScreen extends StatefulWidget {
  final bool isPremium;

  const TricksScreen({
    super.key,
    this.isPremium = false,
  });

  @override
  State<TricksScreen> createState() => _TricksScreenState();
}

class _TricksScreenState extends State<TricksScreen>
    with SingleTickerProviderStateMixin {

  int _selectedCategory = 0;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;

  List<TrickModel> _allTricks = [];
  bool _isLoading = true;

  // Categories revealed dynamically from API data (plus "ALL")
  List<String> get _categories {
    final cats = _allTricks.map((t) => t.category).where((c) => c.isNotEmpty).toSet();
    return ['ALL', ...cats];
  }

  List<TrickModel> get _filteredTricks {
    if (_selectedCategory == 0) return _allTricks;
    final cat = _categories[_selectedCategory];
    return _allTricks.where((t) => t.category == cat).toList();
  }

  // Premium gating is now per-trick: admin marks a trick "Premium Only".
  int get _freeCount => _allTricks.where((t) => !t.isPremium).length;
  int get _premiumCount => _allTricks.where((t) => t.isPremium).length;

  bool _isLockedTrick(TrickModel t) {
    if (widget.isPremium) return false;
    return t.isPremium;
  }

  Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'beginner':
      case 'easy':
        return AppColors.success;
      case 'intermediate':
      case 'medium':
        return AppColors.yellow;
      case 'advanced':
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.success;
    }
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
    _loadTricks();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTricks() async {
    setState(() => _isLoading = true);
    final tricks = await ContentService.getTricks();
    if (!mounted) return;
    setState(() {
      _allTricks = tricks;
      _isLoading = false;
      if (_selectedCategory >= _categories.length) _selectedCategory = 0;
    });
  }

  Map<String, dynamic> _toDetailMap(TrickModel t) => {
        'chapter': t.chapterNumber.toString().padLeft(2, '0'),
        'title': t.title,
        'subtitle': t.subtitle,
        'category': t.category,
        'hasVideo': t.hasVideo,
        'hasArticle': t.hasArticle,
        'videoUrl': t.videoUrl,
        'articleContent': t.articleContent,
        'duration': t.durationLabel,
        'difficulty': t.difficulty,
        'diffColor': _difficultyColor(t.difficulty),
        'isNew': t.isNew,
      };

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
                if (!widget.isPremium && _premiumCount > 0)
                  _buildFreeBanner(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.neonCyan))
                      : filtered.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: AppColors.neonCyan,
                              backgroundColor: AppColors.darkCard,
                              onRefresh: _loadTricks,
                              child: ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final t = filtered[i];
                                  final locked = _isLockedTrick(t);

                                  return _TrickCard(
                                    trick: t,
                                    diffColor: _difficultyColor(t.difficulty),
                                    isLocked: locked,
                                    onTap: () async {
                                      if (locked) {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const PremiumScreen()),
                                        );
                                        if (mounted) _loadTricks();
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TricksDetailScreen(
                                              data: _toDetailMap(t),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeBanner() {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
        if (mounted) _loadTricks();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.orange.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_open_rounded,
                color: AppColors.orange, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: '$_freeCount ${tr('tricks free')} ',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    TextSpan(text: '— ${tr('Upgrade for')} '),
                    TextSpan(
                      text: '$_premiumCount ${tr('premium tricks')}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange),
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
                  borderRadius: BorderRadius.circular(16)),
              child: Text('₹${AppSettingsService.instance.getInt('premium_price', 50)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.neonCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('TUNNL TRICKS'),
                  style: GoogleFonts.orbitron(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonCyan,
                      letterSpacing: 2)),
              Text(tr('Tips & Tricks to master Math'),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.2), width: 1)),
            child: Text(
              widget.isPremium
                  ? '${_allTricks.length} ${tr('Tricks')}'
                  : '$_freeCount ${tr('Free')}',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: widget.isPremium
                      ? AppColors.neonCyan
                      : AppColors.orange,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final cats = _categories;
    if (cats.length <= 1) return const SizedBox(height: 8);
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final isActive = _selectedCategory == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.neonCyan : AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isActive
                        ? AppColors.neonCyan
                        : AppColors.textMuted.withValues(alpha: 0.2),
                    width: 1),
              ),
              child: Text(cats[i],
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.darkBg
                          : AppColors.textSecondary)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.layers_clear_rounded,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(tr('No tricks yet'),
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(tr('Admin will publish them soon.'),
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, color: AppColors.darkBg),
              label: Text(tr('Retry'),
                  style: GoogleFonts.poppins(
                      color: AppColors.darkBg,
                      fontWeight: FontWeight.w700)),
              onPressed: _loadTricks,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrickCard extends StatelessWidget {
  final TrickModel trick;
  final Color diffColor;
  final bool isLocked;
  final VoidCallback onTap;

  const _TrickCard({
    required this.trick,
    required this.diffColor,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                ? AppColors.textMuted.withValues(alpha: 0.08)
                : AppColors.neonCyan.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLocked
                    ? AppColors.textMuted.withValues(alpha: 0.06)
                    : AppColors.neonCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLocked
                      ? AppColors.textMuted.withValues(alpha: 0.1)
                      : AppColors.neonCyan.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock_rounded,
                        color: AppColors.textMuted, size: 20)
                    : Text(
                        trick.chapterNumber.toString().padLeft(2, '0'),
                        style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neonCyan)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(trick.title,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isLocked
                                    ? AppColors.textMuted
                                    : Colors.white)),
                      ),
                      if (trick.isNew && !isLocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.4),
                                  width: 1)),
                          child: Text('NEW',
                              style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLocked
                        ? '${tr('Upgrade to Premium —')} ₹${AppSettingsService.instance.getInt('premium_price', 50)} ${tr('only')}'
                        : trick.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isLocked
                          ? AppColors.orange.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (!isLocked) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                              color: diffColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(trick.difficulty,
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: diffColor)),
                        ),
                        if (trick.hasVideo)
                          const _FormatBadge(
                              icon: Icons.play_circle_rounded,
                              label: 'VIDEO',
                              color: Color(0xFFFF6B6B)),
                        if (trick.hasArticle)
                          const _FormatBadge(
                              icon: Icons.article_rounded,
                              label: 'READ',
                              color: AppColors.neonCyan),
                        if (trick.durationLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 3),
                            child: Text(trick.durationLabel,
                                style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: AppColors.textMuted)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isLocked
                  ? Icons.workspace_premium_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: isLocked ? AppColors.orange : AppColors.textSecondary,
              size: isLocked ? 18 : 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FormatBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 3),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 8, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
