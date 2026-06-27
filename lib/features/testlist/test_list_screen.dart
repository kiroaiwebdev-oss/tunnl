// lib/features/testlist/test_list_screen.dart
//
// Lists "Free practice MCQ tests" (sets) coming from admin/sets.php

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/app_strings.dart';
import '../../core/services/content_service.dart';
import '../../core/models/set_model.dart';
import '../question/question_screen.dart';
import '../result/set_solution_screen.dart';
import '../result/set_leaderboard_screen.dart';
import '../../core/widgets/score_dialog.dart';
import '../premium/premium_screen.dart';

class TestListScreen extends StatefulWidget {
  final String category;

  const TestListScreen({
    super.key,
    this.category = 'mcq',
  });

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;

  List<SetModel> _sets = [];
  Set<int> _completedIds = {};
  bool _isLoading = true;

  String get _completedKey => 'completed_sets_${widget.category.toLowerCase()}';

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
    _loadAll();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_completedKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _completedIds = list.map((e) => (e as num).toInt()).toSet();
      } catch (_) {}
    }

    final sets = await ContentService.getSets(
      widget.category,
      ungrouped: widget.category == 'mcq',
      page: 1,
      perPage: 50,
    );

    if (!mounted) return;
    setState(() {
      _sets = sets;
      _isLoading = false;
    });
  }

  int get _completedCount =>
      _sets.where((s) => _completedIds.contains(s.id)).length;
  int get _totalQuestions =>
      _sets.fold<int>(0, (sum, s) => sum + s.totalQuestions);

  Future<void> _markComplete(int setId) async {
    _completedIds.add(setId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_completedKey, jsonEncode(_completedIds.toList()));
    if (mounted) setState(() {});
  }

  Future<void> _startTest(SetModel s, int i) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          mode: 'free_mcq',
          category: widget.category,
          setId: s.id,
          setNumber: s.setNumber > 0 ? s.setNumber : i + 1,
          totalQuestions: s.totalQuestions > 0 ? s.totalQuestions : 50,
          onSetCompleted: () => _markComplete(s.id),
        ),
      ),
    );
  }

  void _viewSolution(SetModel s, int i) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SetSolutionScreen(
          setId: s.id,
          title: s.title.isNotEmpty
              ? s.title
              : '${tr('Test')} ${i + 1}',
          setNumber: s.setNumber > 0 ? s.setNumber : i + 1,
        ),
      ),
    );
  }

  void _viewLeaderboard(SetModel s, int i) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SetLeaderboardScreen(
          setId: s.id,
          title: s.title.isNotEmpty ? s.title : '${tr('Test')} ${i + 1}',
        ),
      ),
    );
  }

  void _showSetChooser(SetModel s, int i) {
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
              Text(
                s.title.isNotEmpty ? s.title : '${tr('Test')} ${i + 1}',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 16),
              _chooserButton(
                icon: Icons.replay_rounded,
                label: tr('Retest'),
                color: AppColors.neonCyan,
                filled: true,
                onTap: () { Navigator.pop(ctx); _startTest(s, i); },
              ),
              const SizedBox(height: 12),
              _chooserButton(
                icon: Icons.lightbulb_rounded,
                label: tr('View Solution'),
                color: AppColors.yellow,
                filled: false,
                onTap: () { Navigator.pop(ctx); _viewSolution(s, i); },
              ),
              const SizedBox(height: 12),
              _chooserButton(
                icon: Icons.emoji_events_rounded,
                label: tr('View Leaderboard'),
                color: AppColors.orange,
                filled: false,
                onTap: () { Navigator.pop(ctx); _viewLeaderboard(s, i); },
              ),
              const SizedBox(height: 12),
              _chooserButton(
                icon: Icons.bar_chart_rounded,
                label: tr('View Score'),
                color: AppColors.neonCyan,
                filled: false,
                onTap: () {
                  Navigator.pop(ctx);
                  showSetScoreDialog(context,
                      setId: s.id,
                      title: s.title.isNotEmpty
                          ? s.title
                          : '${tr('Test')} ${i + 1}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chooserButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54, width: double.infinity,
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
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: filled ? AppColors.darkBg : color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashBg),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                _buildHeader(),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.neonCyan))
                      : _sets.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: AppColors.neonCyan,
                              backgroundColor: const Color(0xFF0D2233),
                              onRefresh: _loadAll,
                              child: ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                itemCount: _sets.length,
                                itemBuilder: (_, i) {
                                  final s = _sets[i];
                                  final isCompleted =
                                      _completedIds.contains(s.id);
                                  final unlockedByPrev = i == 0 ||
                                      _completedIds.contains(_sets[i - 1].id);
                                  final premiumBlocked = !s.canAccess;
                                  final isLocked = !isCompleted &&
                                      (premiumBlocked || !unlockedByPrev);

                                  return _TestSetCard(
                                    setNumber: s.setNumber > 0
                                        ? s.setNumber
                                        : i + 1,
                                    title: s.title.isNotEmpty
                                        ? s.title
                                        : '${tr('Test')} ${i + 1}',
                                    questionCount: s.totalQuestions,
                                    isLocked: isLocked,
                                    isPremiumLocked: premiumBlocked,
                                    isCompleted: isCompleted,
                                    onTap: () async {
                                      if (premiumBlocked) {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const PremiumScreen()),
                                        );
                                        if (mounted) _loadAll();
                                        return;
                                      }
                                      if (isLocked) {
                                        _showLockedDialog();
                                        return;
                                      }
                                      if (_completedIds.contains(s.id)) {
                                        _showSetChooser(s, i);
                                      } else {
                                        await _startTest(s, i);
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
          Text(tr('PRACTICE TESTS'),
              style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan,
                  letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Practice Tests'),
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            _isLoading
                ? tr('Loading sets…')
                : '${_sets.length} ${tr('sets')} • ${_sets.isNotEmpty ? _sets.first.totalQuestions : 0} ${tr('questions each')}',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.15), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                    label: tr('TOTAL SETS'),
                    value: '${_sets.length}',
                    color: Colors.white),
                _divider(),
                _SummaryItem(
                    label: tr('COMPLETED'),
                    value: '$_completedCount',
                    color: AppColors.success),
                _divider(),
                _SummaryItem(
                    label: tr('QUESTIONS'),
                    value: '$_totalQuestions',
                    color: AppColors.neonCyan),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 30, color: AppColors.textMuted.withValues(alpha: 0.3));

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_rounded,
                color: AppColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text(tr('No tests available'),
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(tr('Admin will publish practice sets soon.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
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
              onPressed: _loadAll,
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side:
                BorderSide(color: AppColors.orange.withValues(alpha: 0.4), width: 1)),
        title: Text('🔒 ${tr('Set Locked')}',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(tr('Complete previous sets to unlock this one.'),
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('OK'),
                  style: GoogleFonts.poppins(color: AppColors.neonCyan))),
        ],
      ),
    );
  }
}

class _TestSetCard extends StatelessWidget {
  final int setNumber;
  final String title;
  final int questionCount;
  final bool isLocked;
  final bool isPremiumLocked;
  final bool isCompleted;
  final VoidCallback onTap;

  const _TestSetCard({
    required this.setNumber,
    required this.title,
    required this.questionCount,
    required this.isLocked,
    required this.isPremiumLocked,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.neonCyan.withValues(alpha: 0.2);
    Color accentColor = AppColors.neonCyan;

    if (isPremiumLocked) {
      borderColor = AppColors.orange.withValues(alpha: 0.4);
      accentColor = AppColors.orange;
    } else if (isLocked) {
      borderColor = AppColors.textMuted.withValues(alpha: 0.2);
      accentColor = AppColors.textMuted;
    } else if (isCompleted) {
      borderColor = AppColors.success.withValues(alpha: 0.4);
      accentColor = AppColors.success;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.1),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.4), width: 1.5)),
              child: isPremiumLocked
                  ? const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.orange, size: 22)
                  : isLocked
                      ? const Icon(Icons.lock_rounded,
                          color: AppColors.textMuted, size: 20)
                      : isCompleted
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.success, size: 22)
                          : Center(
                              child: Text('$setNumber',
                                  style: GoogleFonts.orbitron(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isLocked && !isPremiumLocked
                              ? AppColors.textMuted
                              : Colors.white)),
                  const SizedBox(height: 3),
                  Text('$questionCount ${tr('Questions')}  •  ${tr('Speed Math')}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                  if (isPremiumLocked) ...[
                    const SizedBox(height: 6),
                    Text('${tr('Upgrade to unlock —')} ₹${AppSettingsService.instance.getInt('premium_price', 50)} ${tr('only')}',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange)),
                  ],
                ],
              ),
            ),
            Icon(
                isPremiumLocked
                    ? Icons.workspace_premium_rounded
                    : isLocked
                        ? Icons.lock_outline_rounded
                        : Icons.arrow_forward_ios_rounded,
                color: isLocked || isPremiumLocked
                    ? accentColor
                    : accentColor,
                size: 16),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.orbitron(
              fontSize: 20, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 3),
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 9,
              color: AppColors.textSecondary,
              letterSpacing: 1.2)),
    ]);
  }
}
