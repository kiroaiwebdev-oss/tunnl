// lib/features/result/result_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/result_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/app_strings.dart';
import '../../core/services/content_service.dart';
import '../question/question_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../premium/premium_screen.dart';

class ResultScreen extends StatefulWidget {
  final String mode;
  final String category;
  final int    totalQuestions;
  final int    correct;
  final int    wrong;
  final int    skipped;
  final double accuracy;
  final double avgSpeedSeconds;
  final List<Map<String, dynamic>> summary;
  final int setNumber;
  final int setId;
  final int totalTimeTaken;
  final List<Map<String, dynamic>> answersForApi;

  const ResultScreen({
    super.key,
    required this.mode,
    required this.category,
    required this.totalQuestions,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.accuracy,
    required this.avgSpeedSeconds,
    required this.summary,
    this.setNumber = 1,
    this.setId = 0,
    this.totalTimeTaken = 0,
    this.answersForApi = const [],
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {

  // ── Tab ───────────────────────────────────────────
  int _activeTab = 0; // 0 = Result, 1 = Review

  // ── Animations ─────────────────────────────────────
  late AnimationController        _entryCtrl;
  late Animation<double>          _fadeAnim;
  late Animation<Offset>          _slideAnim;
  late AnimationController        _scoreCtrl;
  late Animation<double>          _scoreAnim;
  late AnimationController        _statsCtrl;
  late List<Animation<double>>    _statsFadeAnims;
  late AnimationController        _xpCtrl;
  late Animation<double>          _xpScaleAnim;

  // ── Computed ───────────────────────────────────────
  late double _scoreOutOf10;
  late double _accuracyPct;
  late int    _xpEarned;
  late String _performanceMsg;
  late Color  _scoreColor;

  // ── State ──────────────────────────────────────────
  bool   _isSaving    = false;
  bool   _savedOk     = false;
  bool   _isPremium   = false;

  // ── Per-set ranking (shown on result page for real sets) ──
  List<Map<String, dynamic>> _setTop = [];
  int? _setRank;
  int  _setTotal = 0;

  // Same premium benefits shown on the Premium ("Ticket to Tunnl") screen,
  // kept in the same order so both screens match.
  List<String> get _premiumBenefits => [
    tr('Tunnl Tricks'),
    tr('5000 Practice MCQs'),
    tr('5000+ Previous Year MCQs'),
    tr('Daily Practice Set'),
    tr('Shorts'),
    tr('Solve & Earn'),
    tr('Leaderboard Access'),
  ];

  @override
  void initState() {
    super.initState();
    _computeResults();
    _setupAnimations();
    _saveResultAndCheckPremium();
  }

  // ─────────────────────────────────────────────────
  // Compute
  // ─────────────────────────────────────────────────
  void _computeResults() {
    _scoreOutOf10 = widget.totalQuestions > 0
        ? (widget.correct / widget.totalQuestions) * 10
        : 0;

    // Derive accuracy from correct/total so it ALWAYS shows correctly
    // (e.g. the Tunnlity speed test where a passed value may be missing).
    _accuracyPct = widget.totalQuestions > 0
        ? (widget.correct / widget.totalQuestions) * 100
        : (widget.accuracy.isFinite ? widget.accuracy : 0);

    _xpEarned = (widget.correct * 10) +
        (widget.accuracy > 80 ? 20 : 0) +
        (widget.avgSpeedSeconds < 5 ? 15 : 0);

    _scoreColor = _scoreOutOf10 >= 8
        ? AppColors.success
        : _scoreOutOf10 >= 5
            ? AppColors.yellow
            : AppColors.error;

    _performanceMsg = _accuracyPct >= 80
        ? tr('Excellent! You are in the top tier 🔥')
        : _accuracyPct >= 60
            ? tr('Good effort! Keep pushing!')
            : tr('Keep practicing to improve!');
  }

  // ─────────────────────────────────────────────────
  // Save result to API + check premium
  // ─────────────────────────────────────────────────
  Future<void> _saveResultAndCheckPremium() async {
    setState(() => _isSaving = true);

    // Save first so this attempt is included in the per-set ranking below.
    await _saveResult();

    await Future.wait([
      _checkPremium(),
      _saveTunnlityScore(),
      _loadSetRanking(),
    ]);

    if (mounted) setState(() => _isSaving = false);
  }

  // Per-set ranking (any real set: PYQ, 5000+ MCQ, etc.). Tunnlity has its own
  // dedicated leaderboard, so it is excluded here.
  Future<void> _loadSetRanking() async {
    if (widget.setId <= 0 || widget.mode == 'tunnelity') return;
    final res = await ContentService.getSetLeaderboard(widget.setId);
    if (!mounted) return;
    setState(() {
      _setTop = (res['top'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      _setRank  = (res['my_rank'] as num?)?.toInt();
      _setTotal = (res['total'] as num?)?.toInt() ?? 0;
    });
  }

  // Persist Tunnlity speed-test score locally so the Tunnlity screen can show
  // "View Score" + a personal best (its own mini leaderboard).
  Future<void> _saveTunnlityScore() async {
    if (widget.mode != 'tunnelity') return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final attempts = (prefs.getInt('tunnlity_attempts') ?? 0) + 1;
      await prefs.setInt('tunnlity_attempts', attempts);
      await prefs.setDouble('tunnlity_last_score', _scoreOutOf10);
      await prefs.setDouble('tunnlity_last_accuracy', _accuracyPct);
      await prefs.setInt('tunnlity_last_correct', widget.correct);
      await prefs.setInt('tunnlity_last_total', widget.totalQuestions);
      await prefs.setString(
          'tunnlity_last_date', DateTime.now().toIso8601String());
      final bestScore = prefs.getDouble('tunnlity_best_score') ?? 0;
      if (_scoreOutOf10 >= bestScore) {
        await prefs.setDouble('tunnlity_best_score', _scoreOutOf10);
        await prefs.setDouble('tunnlity_best_accuracy', _accuracyPct);
      }
    } catch (_) {}
  }

  Future<void> _saveResult() async {
    try {
      // If we don't have a real set_id, skip API save — EXCEPT the Tunnlity
      // speed test (set_id=0), which we DO save so it powers the Tunnlity
      // leaderboard.
      if (widget.setId <= 0 && widget.mode != 'tunnelity') {
        if (mounted) setState(() => _savedOk = false);
        return;
      }
      final ok = await ResultService.saveResult(
        category: widget.category,
        setId: widget.setId,
        correct: widget.correct,
        wrong: widget.wrong,
        skipped: widget.skipped,
        timeTaken: widget.totalTimeTaken > 0
            ? widget.totalTimeTaken
            : (widget.avgSpeedSeconds * widget.totalQuestions).round(),
        answers: widget.answersForApi,
      );
      if (mounted) setState(() => _savedOk = ok);
    } catch (_) {
      // Silent fail — result still shown to user
    }
  }

  Future<void> _checkPremium() async {
    final isPremium = await AuthService.isPremium();
    if (mounted) setState(() => _isPremium = isPremium);
  }

  // ─────────────────────────────────────────────────
  // Animations
  // ─────────────────────────────────────────────────
  void _setupAnimations() {
    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _scoreCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreAnim = Tween<double>(begin: 0.0, end: _scoreOutOf10).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic));

    _statsCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _statsFadeAnims = List.generate(3, (i) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _statsCtrl,
        curve: Interval(i * 0.15, 0.6 + i * 0.15, curve: Curves.easeOut),
      )));

    _xpCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _xpScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _xpCtrl, curve: Curves.elasticOut));

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) { _scoreCtrl.forward(); _statsCtrl.forward(); }
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _xpCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _scoreCtrl.dispose();
    _statsCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashBg),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildTabBar(),
                  Expanded(
                    child: _activeTab == 0
                        ? _buildResultTab()
                        : _buildReviewTab(),
                  ),
                ],
              ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (r) => false),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.neonCyan, size: 20),
          ),
          Text('Tunnl',
            style: GoogleFonts.orbitron(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.neonCyan, letterSpacing: 3)),
          // Save status indicator
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isSaving
                ? const SizedBox(
                    key: ValueKey('saving'),
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.neonCyan))
                : Icon(
                    key: const ValueKey('saved'),
                    _savedOk ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: _savedOk
                        ? AppColors.success
                        : AppColors.textMuted,
                    size: 22),
          ),
        ],
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          _TabChip(
            label: tr('RESULT'),
            icon: Icons.bar_chart_rounded,
            active: _activeTab == 0,
            onTap: () => setState(() => _activeTab = 0),
          ),
          const SizedBox(width: 10),
          _TabChip(
            label: '${tr('REVIEW')} (${widget.summary.length})',
            icon: Icons.rate_review_rounded,
            active: _activeTab == 1,
            onTap: () => setState(() => _activeTab = 1),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // RESULT TAB
  // ─────────────────────────────────────────────────
  Widget _buildResultTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildResultsHeading(),
          const SizedBox(height: 20),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildBreakdownRow(),
          const SizedBox(height: 16),
          _buildPerformanceCard(),
          const SizedBox(height: 24),
          if (_setTotal > 0) _buildRankingCard(),
          if (_setTotal > 0) const SizedBox(height: 16),
          _buildRetryButton(),
          const SizedBox(height: 12),
          _buildDashboardButton(),
          const SizedBox(height: 12),
          if (widget.mode != 'simplification') _buildLeaderboardButton(),
          if (widget.mode != 'simplification') const SizedBox(height: 12),
          if (widget.summary.isNotEmpty) _buildSolutionButton(),
          if (widget.summary.isNotEmpty) const SizedBox(height: 12),
          if (!_isPremium) _buildPremiumCard(),
          if (!_isPremium) const SizedBox(height: 30),
          if (_isPremium) const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResultsHeading() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.neonCyan, Color(0xFF0091EA)],
          ).createShader(b),
          child: Text(tr('RESULTS'),
            style: GoogleFonts.orbitron(
              fontSize: 42, fontWeight: FontWeight.w700,
              color: Colors.white, letterSpacing: 6)),
        ),
        const SizedBox(height: 6),
        Text('${tr('SET')} ${widget.setNumber.toString().padLeft(2, '0')} • ${widget.category.toUpperCase()}',
          style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: AppColors.textSecondary, letterSpacing: 2.5)),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FadeTransition(
            opacity: _statsFadeAnims[0],
            child: _StatItem(
              icon: Icons.star_rounded,
              label: tr('SCORE'),
              valueWidget: AnimatedBuilder(
                animation: _scoreAnim,
                builder: (_, __) => Text(
                  '${_scoreAnim.value.toStringAsFixed(1)}/10',
                  style: GoogleFonts.orbitron(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: _scoreColor)),
              ),
            ),
          ),
          Container(width: 1, height: 60,
            color: AppColors.textMuted.withValues(alpha: 0.3)),
          FadeTransition(
            opacity: _statsFadeAnims[1],
            child: _StatItem(
              icon: Icons.track_changes_rounded,
              label: tr('ACCURACY'),
              valueWidget: Text(
                '${_accuracyPct.toStringAsFixed(0)}%',
                style: GoogleFonts.orbitron(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan)),
            ),
          ),
          Container(width: 1, height: 60,
            color: AppColors.textMuted.withValues(alpha: 0.3)),
          FadeTransition(
            opacity: _statsFadeAnims[2],
            child: _StatItem(
              icon: Icons.timer_rounded,
              label: tr('AVG SPEED'),
              valueWidget: Text(
                '${widget.avgSpeedSeconds.toStringAsFixed(1)}s',
                style: GoogleFonts.orbitron(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Correct / Wrong / Skipped breakdown ───────────
  Widget _buildBreakdownRow() {
    return Row(
      children: [
        _BreakdownChip(
          value: widget.correct,
          label: tr('Correct'),
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 10),
        _BreakdownChip(
          value: widget.wrong,
          label: tr('Wrong'),
          color: AppColors.error,
          icon: Icons.cancel_rounded,
        ),
        const SizedBox(width: 10),
        _BreakdownChip(
          value: widget.skipped,
          label: tr('Skipped'),
          color: AppColors.textMuted,
          icon: Icons.remove_circle_rounded,
        ),
      ],
    );
  }

  Widget _buildPerformanceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.neonCyan.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [BoxShadow(
          color: AppColors.neonCyan.withValues(alpha: 0.05),
          blurRadius: 16, spreadRadius: 2)],
      ),
      child: Row(
        children: [
          Container(
            width: 3, height: 50,
            decoration: BoxDecoration(
              color: AppColors.neonCyan,
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 14),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonCyan.withValues(alpha: 0.1)),
            child: const Icon(Icons.emoji_events_rounded,
              color: AppColors.neonCyan, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_performanceMsg,
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.white)),
                const SizedBox(height: 3),
                Text('${widget.totalQuestions - widget.correct} ${tr('more correct → reach Top 20!')}',
                  style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ScaleTransition(
            scale: _xpScaleAnim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.3))),
              child: Column(
                children: [
                  Text('+$_xpEarned',
                    style: GoogleFonts.orbitron(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.neonCyan)),
                  Text('XP',
                    style: GoogleFonts.poppins(
                      fontSize: 9, color: AppColors.neonCyan,
                      letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Per-set ranking card (your rank + top 3) ──────
  Widget _buildRankingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard_rounded,
                  color: AppColors.yellow, size: 20),
              const SizedBox(width: 8),
              Text(tr('Your Ranking'),
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const Spacer(),
              if (_setRank != null)
                Text('#$_setRank ${tr('of')} $_setTotal',
                    style: GoogleFonts.orbitron(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.yellow)),
            ],
          ),
          const SizedBox(height: 4),
          Text('$_setTotal ${_setTotal == 1 ? tr('student') : tr('students')} ${tr('attempted this set')}',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          ..._setTop.map((e) {
            final medal = e['medal'] as String?;
            final isMe = e['is_me'] == true;
            final name = '${e['name'] ?? 'Anonymous'}';
            final score = (e['best_score'] as num?)?.toInt() ?? 0;
            final acc = (e['best_accuracy'] as num?)?.toDouble() ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(medal ?? '#${e['rank']}',
                        style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(isMe ? '$name (${tr('You')})' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight:
                                isMe ? FontWeight.w700 : FontWeight.w500,
                            color: isMe ? AppColors.yellow : Colors.white)),
                  ),
                  Text('$score ${tr('pts')} • ${acc.toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Buttons ───────────────────────────────────────
  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QuestionScreen(
          mode:           widget.mode,
          category:       widget.category,
          setId:          widget.setId,
          setNumber:      widget.setNumber,
          totalQuestions: widget.totalQuestions,
        )),
      ),
      child: Container(
        height: 56, width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF00ACC1)],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(
            color: AppColors.neonCyan.withValues(alpha: 0.35),
            blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 4))],
        ),
        child: Center(child: Text(tr('RETRY TEST'),
          style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: AppColors.darkBg, letterSpacing: 2))),
      ),
    );
  }

  Widget _buildDashboardButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (r) => false),
      child: Container(
        height: 56, width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3)),
        ),
        child: Center(child: Text(tr('DASHBOARD'),
          style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: Colors.white, letterSpacing: 2))),
      ),
    );
  }

  Widget _buildLeaderboardButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
      child: Container(
        height: 56, width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.35),
            blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded,
              color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(tr('LEADERBOARD'),
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionButton() {
    return GestureDetector(
      onTap: () => setState(() => _activeTab = 1),
      child: Container(
        height: 56, width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.yellow.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.yellow.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_rounded,
              color: AppColors.yellow, size: 20),
            const SizedBox(width: 10),
            Text(tr('VIEW SOLUTION'),
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.yellow, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('Unlock Premium\nContent'),
                style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: Colors.white, height: 1.3)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.3))),
                child: Text(tr('ELITE\nACCESS'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.neonCyan, letterSpacing: 1.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < _premiumBenefits.length; i++) ...[
            _PremiumFeature(text: _premiumBenefits[i]),
            if (i != _premiumBenefits.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PremiumScreen())),
            child: Container(
              height: 52, width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.4),
                  blurRadius: 20, spreadRadius: 2,
                  offset: const Offset(0, 4))],
              ),
              child: Center(child: Text(tr('UNLOCK NOW'),
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: 2))),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // REVIEW TAB
  // ─────────────────────────────────────────────────
  Widget _buildReviewTab() {
    if (widget.summary.isEmpty) {
      return Center(
        child: Text(tr('No review data available.'),
          style: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: widget.summary.length,
      itemBuilder: (_, i) {
        final item      = widget.summary[i];
        final isCorrect = item['isCorrect'] == true;
        final skipped   = (item['selected'] as int?) == -1;
        final options   = List<String>.from(item['options'] ?? []);
        final correct   = (item['correct'] as int?) ?? 0;
        final selected  = (item['selected'] as int?) ?? -1;

        Color headerColor = skipped
            ? AppColors.textMuted
            : isCorrect ? AppColors.success : AppColors.error;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: headerColor.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: headerColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: headerColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        'Q${i + 1}',
                        style: GoogleFonts.orbitron(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: headerColor)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item['question'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: Colors.white)),
                    ),
                    Icon(
                      skipped
                          ? Icons.remove_circle_rounded
                          : isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                      color: headerColor, size: 20),
                  ],
                ),
              ),

              // Options
              if (options.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: List.generate(options.length, (oi) {
                      final isC = oi == correct;
                      final isS = oi == selected;
                      Color bg        = Colors.transparent;
                      Color border    = AppColors.textMuted.withValues(alpha: 0.15);
                      Color textColor = AppColors.textSecondary;

                      if (isC) {
                        bg        = AppColors.success.withValues(alpha: 0.1);
                        border    = AppColors.success.withValues(alpha: 0.4);
                        textColor = AppColors.success;
                      } else if (isS && !isC) {
                        bg        = AppColors.error.withValues(alpha: 0.1);
                        border    = AppColors.error.withValues(alpha: 0.4);
                        textColor = AppColors.error;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              ['A', 'B', 'C', 'D'][oi],
                              style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: textColor)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(options[oi],
                                style: GoogleFonts.poppins(
                                  fontSize: 13, color: textColor))),
                            if (isC)
                              const Icon(Icons.check_rounded,
                                color: AppColors.success, size: 16),
                            if (isS && !isC)
                              const Icon(Icons.close_rounded,
                                color: AppColors.error, size: 16),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

              // Solution / explanation (from CSV `explanation` column)
              if ((item['explanation']?.toString() ?? '').trim().isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.neonCyan.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded,
                            color: AppColors.neonCyan, size: 14),
                          const SizedBox(width: 6),
                          Text(tr('Solution'),
                            style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppColors.neonCyan)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(item['explanation'].toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary,
                          height: 1.5)),
                    ],
                  ),
                ),

              // Time taken
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                      size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      skipped
                          ? tr('Timed out')
                          : '${tr('Answered in')} ${item['timeTaken']}s',
                      style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── ResultService — banao ─────────────────────────────
// lib/core/services/result_service.dart
//
// class ResultService {
//   static Future<bool> saveResult({...}) async {
//     final token = await AuthService.getToken();
//     final res = await http.post(
//       Uri.parse('${AppConstants.baseUrl}/user/save-result'),
//       headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
//       body: jsonEncode({...}),
//     );
//     return jsonDecode(res.body)['status'] == true;
//   }
// }

// ─────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────
class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    required this.label, required this.icon,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.neonCyan.withValues(alpha: 0.15)
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.neonCyan.withValues(alpha: 0.5)
                : AppColors.textMuted.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon,
              color: active ? AppColors.neonCyan : AppColors.textMuted,
              size: 14),
            const SizedBox(width: 6),
            Text(label,
              style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: active ? AppColors.neonCyan : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final IconData icon;

  const _BreakdownChip({
    required this.value, required this.label,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text('$value',
              style: GoogleFonts.orbitron(
                fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label,
              style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Widget   valueWidget;

  const _StatItem({
    required this.icon, required this.label, required this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonCyan.withValues(alpha: 0.1)),
          child: Icon(icon, color: AppColors.neonCyan, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label,
          style: GoogleFonts.poppins(
            fontSize: 10, color: AppColors.textSecondary,
            letterSpacing: 1.5)),
        const SizedBox(height: 4),
        valueWidget,
      ],
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  final String text;
  const _PremiumFeature({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22, height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle, color: AppColors.neonCyan),
          child: const Icon(Icons.check_rounded,
            color: AppColors.darkBg, size: 14),
        ),
        const SizedBox(width: 12),
        Text(text,
          style: GoogleFonts.poppins(
            fontSize: 13, color: Colors.white,
            fontWeight: FontWeight.w400)),
      ],
    );
  }
}
