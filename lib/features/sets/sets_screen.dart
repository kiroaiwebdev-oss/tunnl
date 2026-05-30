// lib/features/sets/sets_screen.dart
//
// Lists "sets" coming from admin's sets.php. Each card opens QuestionScreen with
// the actual set_id from the database.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/content_service.dart';
import '../../core/models/set_model.dart';
import '../question/question_screen.dart';
import '../premium/premium_screen.dart';

class SetsScreen extends StatefulWidget {
  final String title;
  final String category;
  final String? subtitle;
  final String? mode;
  final int questionsPerSet;
  final int totalSets;
  final bool showLeaderboard;
  final int? examId;

  const SetsScreen({
    super.key,
    required this.title,
    required this.category,
    this.subtitle,
    this.mode,
    this.questionsPerSet = 50,
    this.totalSets = 100,
    this.showLeaderboard = true,
    this.examId,
  });

  @override
  State<SetsScreen> createState() => _SetsScreenState();
}

class _SetsScreenState extends State<SetsScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;

  List<SetModel> _sets = [];
  Set<int> _completedSetIds = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMsg = '';

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

  // ── Load sets + cached completion ─────────────────
  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await _loadCompletedFromCache();

    try {
      final mappedCategory = _mapCategory(widget.category);
      final sets = await ContentService.getSets(
        mappedCategory,
        examId: widget.examId,
        page: 1,
        perPage: 100,
      );
      if (!mounted) return;
      setState(() {
        _sets = sets;
        _isLoading = false;
        _hasError = sets.isEmpty;
        if (sets.isEmpty) {
          _errorMsg = 'No sets available yet. Admin will add them soon.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMsg = 'Could not load sets. Please retry.';
      });
    }
  }

  String _mapCategory(String c) {
    final s = c.toLowerCase();
    if (s == 'daily' || s == 'daily_practice') return 'mcq';
    if (s == 'pyq' || s == 'previous_year') return 'previous_year';
    if (s == 'simplification') return 'simplification';
    return 'mcq';
  }

  Future<void> _loadCompletedFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_completedKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _completedSetIds = list.map((e) => (e as num).toInt()).toSet();
      } catch (_) {}
    }
  }

  Future<void> _saveCompletedToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_completedKey, jsonEncode(_completedSetIds.toList()));
  }

  Future<void> _markSetCompleted(int setId) async {
    setState(() => _completedSetIds.add(setId));
    await _saveCompletedToCache();
  }

  int get _completedCount {
    if (_sets.isEmpty) return 0;
    return _sets.where((s) => _completedSetIds.contains(s.id)).length;
  }

  bool _isAvailable(int index) {
    if (index == 0) return true;
    final prev = _sets[index - 1];
    return _completedSetIds.contains(prev.id) ||
        _completedSetIds.contains(_sets[index].id);
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
              children: [
                _buildAppBar(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingSkeleton()
                      : (_hasError && _sets.isEmpty)
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: AppColors.neonCyan,
                              backgroundColor: const Color(0xFF0D2233),
                              onRefresh: _loadAll,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    _buildHeader(),
                                    const SizedBox(height: 20),
                                    _buildSetsGrid(),
                                    const SizedBox(height: 30),
                                  ],
                                ),
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
          Expanded(
            child: Text(widget.category.toUpperCase(),
                style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neonCyan,
                    letterSpacing: 2),
                overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
            ),
            child: Text(
              _isLoading
                  ? '— / — Done'
                  : '$_completedCount/${_sets.length} Done',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.neonCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final total = _sets.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.quiz_rounded,
                color: AppColors.neonCyan, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle ??
                      '$total Sets • ${widget.questionsPerSet} Questions each',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? _completedCount / total : 0.0,
                    backgroundColor: AppColors.neonCyan.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_completedCount of $total sets completed',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: _sets.length,
      itemBuilder: (_, i) {
        final s = _sets[i];
        final isCompleted = _completedSetIds.contains(s.id);
        final available = _isAvailable(i);
        final premiumBlocked = !s.canAccess;
        final isLocked = !isCompleted && (premiumBlocked || !available);

        return _SetCard(
          setNumber: s.setNumber > 0 ? s.setNumber : i + 1,
          isCompleted: isCompleted,
          isInProgress: false,
          isLocked: isLocked,
          isPremiumLocked: premiumBlocked,
          progress: isCompleted ? 1.0 : 0.0,
          onTap: () async {
            if (premiumBlocked) {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
              if (mounted) _loadAll();
              return;
            }
            if (!available) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: AppColors.darkCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                content: Text('Complete previous sets first!',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 13)),
              ));
              return;
            }

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuestionScreen(
                  mode: widget.showLeaderboard ? 'mcq' : 'simplification',
                  setId: s.id,
                  setNumber: s.setNumber > 0 ? s.setNumber : i + 1,
                  category: widget.category,
                  totalQuestions:
                      s.questionCount > 0 ? s.questionCount : widget.questionsPerSet,
                  onSetCompleted: () => _markSetCompleted(s.id),
                ),
              ),
            );

            // refresh state
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const _Shimmer(),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: 9,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const _Shimmer(),
            ),
          ),
        ],
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
            const Icon(Icons.inbox_rounded,
                color: AppColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text('Nothing here yet',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(_errorMsg,
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
              label: Text('Retry',
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
}

// ── SHIMMER ───────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  const _Shimmer();
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFF1A2235),
            const Color(0xFF243045),
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ── SET CARD ──────────────────────────────────────────
class _SetCard extends StatefulWidget {
  final int setNumber;
  final bool isCompleted;
  final bool isInProgress;
  final bool isLocked;
  final bool isPremiumLocked;
  final double progress;
  final VoidCallback onTap;

  const _SetCard({
    required this.setNumber,
    required this.isCompleted,
    required this.isInProgress,
    required this.isLocked,
    required this.isPremiumLocked,
    required this.progress,
    required this.onTap,
  });

  @override
  State<_SetCard> createState() => _SetCardState();
}

class _SetCardState extends State<_SetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    Color labelColor;
    IconData stateIcon;
    Color iconColor;

    if (widget.isCompleted) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withOpacity(0.08);
      labelColor = AppColors.success;
      stateIcon = Icons.check_circle_rounded;
      iconColor = AppColors.success;
    } else if (widget.isPremiumLocked) {
      borderColor = AppColors.orange;
      bgColor = AppColors.orange.withOpacity(0.06);
      labelColor = AppColors.orange;
      stateIcon = Icons.workspace_premium_rounded;
      iconColor = AppColors.orange;
    } else if (widget.isLocked) {
      borderColor = AppColors.darkSurface;
      bgColor = AppColors.darkCard;
      labelColor = AppColors.textMuted;
      stateIcon = Icons.lock_rounded;
      iconColor = AppColors.textMuted;
    } else {
      borderColor = AppColors.darkSurface;
      bgColor = AppColors.darkCard;
      labelColor = Colors.white;
      stateIcon = Icons.play_arrow_rounded;
      iconColor = AppColors.neonCyan;
    }

    return GestureDetector(
      onTapDown: (_) => _tapCtrl.reverse(),
      onTapUp: (_) {
        _tapCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _tapCtrl.forward(),
      child: ScaleTransition(
        scale: _tapCtrl,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  borderColor.withOpacity(widget.isLocked ? 0.15 : 0.4),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(stateIcon, color: iconColor, size: 22),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SET ${widget.setNumber.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                    if (widget.isCompleted) ...[
                      const SizedBox(height: 5),
                      Container(
                        height: 3,
                        width: 30,
                        decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
