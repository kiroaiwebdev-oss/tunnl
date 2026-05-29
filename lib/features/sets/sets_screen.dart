// lib/features/sets/sets_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart';
import '../question/question_screen.dart';

class SetsScreen extends StatefulWidget {
  final String title;
  final String category;
  final String? subtitle;
  final String? mode;
  final int questionsPerSet;
  final int totalSets;
  final bool showLeaderboard;

  const SetsScreen({
    super.key,
    required this.title,
    required this.category,
    this.subtitle,
    this.mode,
    this.questionsPerSet = 50,
    this.totalSets = 100,
    this.showLeaderboard = true,
  });

  @override
  State<SetsScreen> createState() => _SetsScreenState();
}

class _SetsScreenState extends State<SetsScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;

  List<bool>   _completed = [];
  List<double> _progress  = [];
  bool         _isLoading = true;

  // Prefs key unique per category
  String get _progressKey => 'set_progress_${widget.category.toLowerCase()}';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProgress();
  }

  void _setupAnimations() {
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
  }

  // ── Load progress: API first, then local cache ────
  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);

    bool loaded = false;

    // ✅ Try API first
    try {
      final res = await UserService.getSetProgress(widget.category);
      if (res['status'] == true) {
        final data = res['data'] as List<dynamic>? ?? [];
        _applyProgressData(data);
        // Cache locally
        await _saveToCache(data);
        loaded = true;
      }
    } catch (_) {}

    // Fallback to local cache
    if (!loaded) {
      await _loadFromCache();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _applyProgressData(List<dynamic> data) {
    final completed = List<bool>.filled(widget.totalSets, false);
    final progress  = List<double>.filled(widget.totalSets, 0.0);

    for (final item in data) {
      final idx = ((item['set_number'] as int? ?? 0) - 1);
      if (idx < 0 || idx >= widget.totalSets) continue;
      progress[idx]  = (item['progress'] as num? ?? 0).toDouble();
      completed[idx] = (item['is_completed'] == true || item['is_completed'] == 1);
    }

    _completed = completed;
    _progress  = progress;
  }

  // ── Local cache ───────────────────────────────────
  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_progressKey);

    final completed = List<bool>.filled(widget.totalSets, false);
    final progress  = List<double>.filled(widget.totalSets, 0.0);

    if (raw != null) {
      final data = jsonDecode(raw) as List<dynamic>;
      for (int i = 0; i < data.length && i < widget.totalSets; i++) {
        completed[i] = data[i]['completed'] == true;
        progress[i]  = (data[i]['progress'] as num? ?? 0).toDouble();
      }
    }

    _completed = completed;
    _progress  = progress;
  }

  Future<void> _saveToCache(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    // Normalise API data → local format
    final localList = List.generate(widget.totalSets, (i) {
      final match = data.firstWhere(
        (d) => (d['set_number'] as int? ?? 0) - 1 == i,
        orElse: () => null,
      );
      return {
        'completed': match != null &&
            (match['is_completed'] == true || match['is_completed'] == 1),
        'progress':
            match != null ? (match['progress'] as num? ?? 0).toDouble() : 0.0,
      };
    });
    await prefs.setString(_progressKey, jsonEncode(localList));
  }

  // ── Called by QuestionScreen when a set is done ───
  Future<void> _markSetCompleted(int setIndex) async {
    setState(() {
      _completed[setIndex] = true;
      _progress[setIndex]  = 1.0;
    });

    // Update cache
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_progressKey);
    final list  = raw != null
        ? jsonDecode(raw) as List<dynamic>
        : List.generate(widget.totalSets, (_) => {'completed': false, 'progress': 0.0});

    list[setIndex] = {'completed': true, 'progress': 1.0};
    await prefs.setString(_progressKey, jsonEncode(list));

    // ✅ API call (fire & forget)
    UserService.updateSetProgress(
      category: widget.category,
      setNumber: setIndex + 1,
      progress: 1.0,
      isCompleted: true,
    ).ignore();
  }

  int get _completedCount => _completed.where((c) => c).length;

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
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
                      : RefreshIndicator(
                          color: AppColors.neonCyan,
                          backgroundColor: const Color(0xFF0D2233),
                          onRefresh: _loadProgress,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildHeader(),
                                const SizedBox(height: 20),

                                _buildLevelSection(
                                  levelLabel: 'LEVEL 01',
                                  levelTitle: 'Beginner Sets',
                                  startIndex: 0,
                                  endIndex: widget.totalSets > 30 ? 30 : widget.totalSets,
                                  isLocked: false,
                                ),

                                if (widget.totalSets > 30) ...[
                                  const SizedBox(height: 20),
                                  _buildLevelSection(
                                    levelLabel: 'LEVEL 02',
                                    levelTitle: 'Intermediate',
                                    startIndex: 30,
                                    endIndex: widget.totalSets > 60 ? 60 : widget.totalSets,
                                    isLocked: _completedCount < 10,
                                  ),
                                ],

                                if (widget.totalSets > 60) ...[
                                  const SizedBox(height: 20),
                                  _buildLevelSection(
                                    levelLabel: 'LEVEL 03',
                                    levelTitle: 'Advanced',
                                    startIndex: 60,
                                    endIndex: widget.totalSets > 90 ? 90 : widget.totalSets,
                                    isLocked: _completedCount < 30,
                                  ),
                                ],

                                if (widget.totalSets > 90) ...[
                                  const SizedBox(height: 20),
                                  _buildExpertSection(),
                                ],

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

  // ── APP BAR ───────────────────────────────────────
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
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.neonCyan, letterSpacing: 2),
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
              _isLoading ? '— / ${widget.totalSets} Done' : '$_completedCount/${widget.totalSets} Done',
              style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.neonCyan,
                fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────
  Widget _buildHeader() {
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
            width: 52, height: 52,
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
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  '${widget.totalSets} Sets • ${widget.questionsPerSet} Questions each',
                  style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.totalSets > 0
                        ? _completedCount / widget.totalSets
                        : 0.0,
                    backgroundColor: AppColors.neonCyan.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.neonCyan),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_completedCount of ${widget.totalSets} sets completed',
                  style: GoogleFonts.poppins(
                    fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LEVEL SECTION ─────────────────────────────────
  Widget _buildLevelSection({
    required String levelLabel,
    required String levelTitle,
    required int startIndex,
    required int endIndex,
    required bool isLocked,
  }) {
    final setsInLevel      = endIndex - startIndex;
    final completedInLevel = _completed
        .sublist(startIndex, endIndex)
        .where((c) => c)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? AppColors.darkCard
                        : AppColors.neonCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLocked
                          ? AppColors.textMuted.withOpacity(0.3)
                          : AppColors.neonCyan.withOpacity(0.3)),
                  ),
                  child: Text(levelLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: isLocked
                          ? AppColors.textMuted : AppColors.neonCyan,
                      letterSpacing: 1)),
                ),
                const SizedBox(width: 10),
                Text(levelTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: isLocked ? AppColors.textMuted : Colors.white)),
              ],
            ),
            if (isLocked)
              const Icon(Icons.lock_rounded,
                color: AppColors.textMuted, size: 18)
            else
              Text(
                '$completedInLevel / $setsInLevel COMPLETED',
                style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.neonCyan,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ],
        ),

        const SizedBox(height: 14),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: setsInLevel,
          itemBuilder: (_, i) {
            final globalIndex  = startIndex + i;
            final setNumber    = globalIndex + 1;
            final isCompleted  = _completed[globalIndex];
            final progress     = _progress[globalIndex];
            final isInProgress = !isCompleted && progress > 0;
            final isAvailable  = !isLocked &&
                (globalIndex == 0 ||
                    _completed[globalIndex - 1] ||
                    isCompleted ||
                    isInProgress);

            return _SetCard(
              setNumber: setNumber,
              isCompleted: isCompleted,
              isInProgress: isInProgress,
              isLocked: isLocked || !isAvailable,
              progress: progress,
              onTap: () async {
                if (isLocked || !isAvailable) {
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

                // ✅ Push and wait — refresh on return
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuestionScreen(
                      mode: widget.showLeaderboard ? 'mcq' : 'simplification',
                      setNumber: setNumber,
                      category: widget.category,
                      totalQuestions: widget.questionsPerSet,
                      onSetCompleted: () => _markSetCompleted(globalIndex),
                    ),
                  ),
                );

                // Refresh progress after returning (in case partial progress saved)
                _loadProgress();
              },
            );
          },
        ),
      ],
    );
  }

  // ── EXPERT SECTION ────────────────────────────────
  Widget _buildExpertSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
            ),
            child: Text('LEVEL 04+',
              style: GoogleFonts.poppins(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.neonCyan, letterSpacing: 2)),
          ),
          const SizedBox(height: 14),
          Text('ADVANCED MULTIVARIABLE\nLOGIC',
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: Colors.white, height: 1.4)),
          const SizedBox(height: 8),
          Text(
            'The mathematical void expands.\nCalibrating high-dimensional challenge nodes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconBox(Icons.rocket_launch_rounded),
              const SizedBox(width: 12),
              _iconBox(Icons.hourglass_bottom_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
      ),
      child: Icon(icon, color: AppColors.neonCyan, size: 20),
    );
  }

  // ── LOADING SKELETON ──────────────────────────────
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Header skeleton
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const _Shimmer(),
          ),
          const SizedBox(height: 20),
          // Grid skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 10,
              mainAxisSpacing: 10, childAspectRatio: 1.0,
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
  late Animation<double>   _anim;

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
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
  final double progress;
  final VoidCallback onTap;

  const _SetCard({
    required this.setNumber,
    required this.isCompleted,
    required this.isInProgress,
    required this.isLocked,
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
  void dispose() { _tapCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    Color labelColor;
    IconData stateIcon;
    Color iconColor;

    if (widget.isCompleted) {
      borderColor = AppColors.success;
      bgColor     = AppColors.success.withOpacity(0.08);
      labelColor  = AppColors.success;
      stateIcon   = Icons.check_circle_rounded;
      iconColor   = AppColors.success;
    } else if (widget.isInProgress) {
      borderColor = AppColors.neonCyan;
      bgColor     = AppColors.neonCyan.withOpacity(0.06);
      labelColor  = AppColors.neonCyan;
      stateIcon   = Icons.play_circle_rounded;
      iconColor   = AppColors.neonCyan;
    } else if (widget.isLocked) {
      borderColor = AppColors.darkSurface;
      bgColor     = AppColors.darkCard;
      labelColor  = AppColors.textMuted;
      stateIcon   = Icons.lock_rounded;
      iconColor   = AppColors.textMuted;
    } else {
      borderColor = AppColors.darkSurface;
      bgColor     = AppColors.darkCard;
      labelColor  = Colors.white;
      stateIcon   = Icons.play_arrow_rounded;
      iconColor   = AppColors.neonCyan;
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
              color: borderColor.withOpacity(
                widget.isLocked ? 0.15 : 0.4),
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
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: labelColor),
                    ),

                    if (widget.isInProgress) ...[
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: widget.progress,
                          backgroundColor:
                              AppColors.neonCyan.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.neonCyan),
                          minHeight: 4,
                        ),
                      ),
                    ],

                    if (widget.isCompleted) ...[
                      const SizedBox(height: 5),
                      Container(
                        height: 3, width: 30,
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
