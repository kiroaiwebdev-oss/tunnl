// lib/features/question/question_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/content_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/app_strings.dart';
import '../../core/models/question_model.dart';
import '../result/result_screen.dart';

class QuestionScreen extends StatefulWidget {
  final String mode;
  final int setNumber;
  final int setId;
  final int totalQuestions;
  final String category;
  final int challengeId;
  final VoidCallback? onSetCompleted;

  /// Optional label shown above every question (e.g. the Previous-Year exam
  /// name like "SSC 2023") so the user always knows which exam the questions
  /// belong to. Empty = no badge.
  final String headerLabel;

  /// Pre-loaded questions (e.g. the Weekly Challenge's assigned day questions).
  /// When provided & non-empty, the screen uses these directly instead of
  /// fetching from the API.
  final List<QuestionModel>? presetQuestions;

  const QuestionScreen({
    super.key,
    required this.mode,
    required this.category,
    this.setId = 0,
    this.setNumber = 1,
    this.totalQuestions = 10,
    this.challengeId = 0,
    this.onSetCompleted,
    this.headerLabel = '',
    this.presetQuestions,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen>
    with TickerProviderStateMixin {

  // ── Question data ──────────────────────────────────
  List<QuestionModel> _questions = [];
  int  _currentIndex    = 0;
  bool _hindi           = LanguageService.instance.isHindi;
  int? _selectedOption;
  int? _confirmedOption;
  bool _isAnswered      = false;
  bool _isLoading       = true;
  bool _hasError        = false;
  String _errorMsg      = '';

  // ── Score ──────────────────────────────────────────
  int _correctCount = 0;
  int _wrongCount   = 0;
  final List<Map<String, dynamic>> _summary  = [];
  final List<int>                  _timeTaken = [];
  final List<Map<String, dynamic>> _answersForApi = [];

  // ── Timer (counts UP from 0; no auto-timeout) ──────
  int    _timerSeconds = 0;
  Timer? _questionTimer;

  // ── Animations ─────────────────────────────────────
  late AnimationController        _questionSlideCtrl;
  late Animation<Offset>          _questionSlideAnim;
  late Animation<double>          _questionFadeAnim;
  late AnimationController        _optionCtrl;
  late List<Animation<Offset>>    _optionAnims;
  late AnimationController        _answerCtrl;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadQuestionsFromApi();
  }

  // ─────────────────────────────────────────────────
  // API — Load Questions
  // ─────────────────────────────────────────────────
  Future<void> _loadQuestionsFromApi() async {
    setState(() { _isLoading = true; _hasError = false; });

    // Pre-loaded questions (e.g. Weekly Challenge day questions) → use directly.
    if (widget.presetQuestions != null && widget.presetQuestions!.isNotEmpty) {
      _applyQuestions(widget.presetQuestions!);
      return;
    }

    if (widget.setId == 0) {
      // No set_id provided (e.g. the "Tunnelity" speed test from hub) →
      // load the first available set of THIS screen's category. Falls back to
      // mcq only if the requested category has no sets yet.
      try {
        var sets = await ContentService.getSets(
          widget.category.isEmpty ? 'mcq' : widget.category,
          page: 1,
          perPage: 1,
        );
        if (sets.isEmpty && widget.category != 'mcq') {
          sets = await ContentService.getSets('mcq', page: 1, perPage: 1);
        }
        if (sets.isEmpty) {
          _showApiError(
              'No questions available yet. Admin will publish soon.');
          return;
        }
        final setId = sets.first.id;
        final qs = await ContentService.getQuestions(setId, shuffle: true);
        _applyQuestions(_maybeVariety(qs));
      } catch (e) {
        _showApiError('Failed to load. Check connection.');
      }
      return;
    }

    try {
      final qs = await ContentService.getQuestions(widget.setId, shuffle: true);
      _applyQuestions(qs);
    } catch (e) {
      _showApiError('Network error. Check your connection.');
    }
  }

  // ── Test Your Tunnlity: show one question of EACH type before repeating ──
  // The speed test should cover as many *types* of question as possible. We
  // classify each question by its operator + the digit-length of its operands
  // (so 23x23 and 123x3 count as DIFFERENT types) and pick round-robin: one of
  // every distinct type first, and only start repeating a type once all
  // distinct types have already appeared.
  List<QuestionModel> _maybeVariety(List<QuestionModel> qs) {
    final isTunnlity =
        widget.mode == 'tunnelity' || widget.category == 'tunnlity';
    if (!isTunnlity || qs.isEmpty) return qs;
    final count = widget.totalQuestions > 0 ? widget.totalQuestions : 10;
    return _pickByTypeVariety(qs, count);
  }

  List<QuestionModel> _pickByTypeVariety(List<QuestionModel> all, int count) {
    // Group questions by their type signature.
    final Map<String, List<QuestionModel>> groups = {};
    for (final q in all) {
      groups.putIfAbsent(_typeSignature(q.questionText), () => []).add(q);
    }
    // Randomise both the order of the types and the questions inside each type
    // so repeat attempts don't always show the same 10 questions.
    final keys = groups.keys.toList()..shuffle();
    for (final k in keys) {
      groups[k]!.shuffle();
    }

    // Round-robin: round 0 takes one question of every distinct type (all
    // unique). Only when every type has been used once do we move to round 1
    // (the first repeats), and so on.
    final result = <QuestionModel>[];
    int round = 0;
    while (result.length < count) {
      bool added = false;
      for (final k in keys) {
        final list = groups[k]!;
        if (round < list.length) {
          result.add(list[round]);
          added = true;
          if (result.length >= count) break;
        }
      }
      if (!added) break; // every question used — set is smaller than `count`
      round++;
    }
    return result;
  }

  // Build a coarse "type" key from the question text: operator + the digit
  // length of the first two numbers. e.g. "23 x 23" -> "mul_2x2",
  // "123 x 3" -> "mul_1x3", "234 + 234" -> "add_3x3". Falls back to a
  // digit-masked version of the text when no operator/operands are found.
  String _typeSignature(String raw) {
    final text = raw.toLowerCase();
    final compact = text.replaceAll(' ', '');

    String op = 'other';
    if (RegExp(r'\d\s*[×*]\s*\d').hasMatch(text) ||
        RegExp(r'\dx\d').hasMatch(compact)) {
      op = 'mul';
    } else if (RegExp(r'\d\s*[÷/]\s*\d').hasMatch(text)) {
      op = 'div';
    } else if (RegExp(r'\d\s*\+\s*\d').hasMatch(text)) {
      op = 'add';
    } else if (RegExp(r'\d\s*[-−]\s*\d').hasMatch(text)) {
      op = 'sub';
    }

    final nums =
        RegExp(r'\d+').allMatches(text).map((m) => m.group(0)!).toList();
    if (op != 'other' && nums.length >= 2) {
      final a = nums[0].length;
      final b = nums[1].length;
      // For commutative operators (x and +) treat NxM and MxN as the same type.
      final digits = (op == 'mul' || op == 'add')
          ? ([a, b]..sort()).join('x')
          : '${a}x$b';
      return '${op}_$digits';
    }
    // Fallback: collapse all numbers to '#' so structurally identical
    // questions group together, different ones stay distinct.
    return compact.replaceAll(RegExp(r'\d+'), '#');
  }

  void _applyQuestions(List<QuestionModel> qs) {
    if (qs.isEmpty) {
      _showApiError(
          'This set has no questions yet. Admin will publish soon.');
      return;
    }
    setState(() {
      _questions = qs;
      _isLoading = false;
    });
    _ensureTermsThenStart();
  }

  // ── Quiz Terms & Conditions (shown once, before the first quiz) ──
  Future<void> _ensureTermsThenStart() async {
    bool accepted = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      accepted = prefs.getBool('quiz_terms_accepted') ?? false;
    } catch (_) {}

    if (accepted) {
      _askLanguageThenStart();
      return;
    }
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.4))),
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded,
                color: AppColors.neonCyan, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(tr('Quiz Terms & Conditions'),
                style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w700,
                  fontSize: 16)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            '• A stopwatch counts up — solve each question as fast as you can.\n\n'
            '• Once you confirm an answer you cannot change it.\n\n'
            '• Answer every question to move ahead — your speed is recorded.\n\n'
            '• Do not close or leave the test — your progress will be lost.\n\n'
            '• Scores and XP are added to your profile and leaderboard.\n\n'
            'By tapping "I Agree" you accept these terms and play fairly.',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary, fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) Navigator.pop(context); // leave the quiz
            },
            child: Text(tr('Cancel'),
              style: GoogleFonts.poppins(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('quiz_terms_accepted', true);
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
              _askLanguageThenStart();
            },
            child: Text(tr('I Agree'),
              style: GoogleFonts.poppins(
                color: AppColors.neonCyan, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Language picker (shown at the start of every test) ──
  // F6: lets the user pick the test language before starting; they can still
  // flip a single question with the in-quiz EN/हिं toggle.
  Future<void> _askLanguageThenStart() async {
    if (!mounted) {
      _startTimer();
      return;
    }
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.4))),
        title: Row(
          children: [
            const Icon(Icons.translate_rounded,
                color: AppColors.neonCyan, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(tr('Select Language'),
                style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w700,
                  fontSize: 16)),
            ),
          ],
        ),
        content: Text(
          tr('Choose the language for this test'),
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          _langChoiceButton('English', false, ctx),
          _langChoiceButton('हिंदी', true, ctx),
        ],
      ),
    );
  }

  Widget _langChoiceButton(String label, bool hi, BuildContext ctx) {
    final selected = _hindi == hi;
    return TextButton(
      onPressed: () {
        setState(() => _hindi = hi);
        if (ctx.mounted) Navigator.pop(ctx);
        _startTimer();
      },
      style: TextButton.styleFrom(
        backgroundColor: selected
            ? AppColors.neonCyan.withValues(alpha: 0.15)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: AppColors.neonCyan.withValues(alpha: selected ? 0.6 : 0.2)),
        ),
      ),
      child: Text(label,
        style: GoogleFonts.poppins(
          color: AppColors.neonCyan,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
    );
  }

  void _showApiError(String msg) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError  = true;
        _errorMsg  = msg;
      });
    }
  }

  // ─────────────────────────────────────────────────
  // Animations Setup
  // ─────────────────────────────────────────────────
  void _setupAnimations() {
    _questionSlideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _questionSlideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionSlideCtrl, curve: Curves.easeOutCubic));
    _questionFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionSlideCtrl, curve: Curves.easeOut));

    _optionCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _optionAnims = List.generate(4, (i) {
      return Tween<Offset>(
        begin: const Offset(0, 0.4), end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _optionCtrl,
        curve: Interval(i * 0.1, 0.6 + i * 0.1, curve: Curves.easeOutCubic),
      ));
    });

    _answerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));

    _questionSlideCtrl.forward();
    _optionCtrl.forward();
  }

  // ─────────────────────────────────────────────────
  // Timer
  // ─────────────────────────────────────────────────
  void _startTimer() {
    // Count UP from 0 — no auto-timeout. The user solves at their own pace and
    // we record how many seconds each question took (used for speed/score).
    _timerSeconds = 0;
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _timerSeconds++);
    });
  }

  // ─────────────────────────────────────────────────
  // Answer Logic
  // ─────────────────────────────────────────────────
  void _selectOption(int index) {
    if (_isAnswered) return;
    setState(() => _selectedOption = index);
  }

  void _confirmAnswer() {
    if (_isAnswered || _selectedOption == null) return;

    _questionTimer?.cancel();

    final q = _questions[_currentIndex];
    final timeTaken = _timerSeconds; // elapsed seconds (count-up stopwatch)

    setState(() {
      _isAnswered      = true;
      _confirmedOption = _selectedOption;
    });

    _recordAnswer(_selectedOption!, timeTaken: timeTaken);
    Future.delayed(const Duration(milliseconds: 1200), _goNext);
  }

  void _recordAnswer(int selected, {int timeTaken = 0}) {
    final q = _questions[_currentIndex];
    final isCorrect = selected == q.correctIndex;

    if (selected >= 0) {
      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    }

    _timeTaken.add(timeTaken);
    _summary.add({
      'question': q.questionFor(_hindi),
      'options': q.optionsFor(_hindi),
      'selected': selected,
      'correct': q.correctIndex,
      'isCorrect': isCorrect,
      'timeTaken': timeTaken,
      'explanation': q.explanationFor(_hindi),
    });

    // For submit_result API
    const letters = ['a', 'b', 'c', 'd'];
    _answersForApi.add({
      'question_id': q.id,
      'selected': selected >= 0 && selected < 4 ? letters[selected] : null,
      'correct': letters[q.correctIndex.clamp(0, 3)],
      'is_correct': isCorrect,
    });
  }

  void _goNext() {
    if (!mounted) return;
    if (_currentIndex >= _questions.length - 1) {
      _navigateToResult();
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedOption  = null;
      _confirmedOption = null;
      _isAnswered      = false;
    });
    _questionSlideCtrl.reset();
    _optionCtrl.reset();
    _questionSlideCtrl.forward();
    _optionCtrl.forward();
    _startTimer();
  }

  void _navigateToResult() {
    widget.onSetCompleted?.call();

    final answeredCount = _correctCount + _wrongCount;
    final skipped = _questions.length - answeredCount;
    final avgTime = _timeTaken.isEmpty
        ? 0.0
        : _timeTaken.reduce((a, b) => a + b) / _timeTaken.length;
    final accuracy = _questions.isEmpty
        ? 0.0
        : (_correctCount / _questions.length) * 100;
    final totalTime = _timeTaken.fold<int>(0, (s, e) => s + e);

    // Solve & Earn: record the attempt so it shows on the leaderboard.
    // (Fire-and-forget — the server creates a challenge_entries row.)
    if (widget.mode == 'solve_earn' && widget.challengeId > 0) {
      UserService.submitWeeklyChallenge(
        challengeId: widget.challengeId,
        correct: _correctCount,
        wrong: _wrongCount,
        timeTaken: totalTime,
      );
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ResultScreen(
          mode: widget.mode,
          category: widget.category,
          totalQuestions: _questions.length,
          correct: _correctCount,
          wrong: _wrongCount,
          skipped: skipped,
          accuracy: accuracy,
          avgSpeedSeconds: avgTime,
          summary: _summary,
          setNumber: widget.setNumber,
          setId: widget.setId,
          totalTimeTaken: totalTime,
          answersForApi: _answersForApi,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ── Exit dialog ───────────────────────────────────
  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4))),
        title: Text(tr('Exit Test?'),
          style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          tr('Your progress will be lost.\nAre you sure?'),
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Continue'),
              style: GoogleFonts.poppins(color: AppColors.neonCyan)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Exit'),
              style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _questionSlideCtrl.dispose();
    _optionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.splashBg),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan),
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.splashBg),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                      color: AppColors.textMuted, size: 56),
                    const SizedBox(height: 16),
                    Text(tr('Failed to Load'),
                      style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(_errorMsg,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(tr('Go Back'),
                            style: GoogleFonts.poppins(
                              color: AppColors.textMuted)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonCyan,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _loadQuestionsFromApi,
                          child: Text(tr('Retry'),
                            style: GoogleFonts.poppins(
                              color: AppColors.darkBg,
                              fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final q = _questions[_currentIndex];
    final stage = '${tr('QUESTION')} ${(_currentIndex + 1).toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final exit = await _onWillPop();
        if (exit && mounted) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.splashBg),
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildQuestionCard(q, stage),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildOptions(q),
                  ),
                ),
                _buildContinueButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.2)),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/images/tunnel_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.all_inclusive_rounded,
                color: AppColors.neonCyan, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('TIME'),
                style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textSecondary,
                  letterSpacing: 1.5)),
              Text('PROGRESS',
                style: GoogleFonts.poppins(
                  fontSize: 9, color: AppColors.neonCyan,
                  letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              Text(
                '${(_currentIndex + 1).toString().padLeft(2, '0')} / ${_questions.length.toString().padLeft(2, '0')}',
                style: GoogleFonts.orbitron(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Colors.white)),
            ],
          ),

          const Spacer(),
          _buildLangToggle(),
          const SizedBox(width: 10),
          _buildTimerRing(),
          const SizedBox(width: 16),

          GestureDetector(
            onTap: () async {
              final exit = await _onWillPop();
              if (exit && mounted) Navigator.of(context).pop();
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close_rounded,
                color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── LANGUAGE TOGGLE (per-test EN/Hindi) ───────────
  Widget _buildLangToggle() {
    return GestureDetector(
      onTap: () => setState(() => _hindi = !_hindi),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.neonCyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate_rounded,
                color: AppColors.neonCyan, size: 14),
            const SizedBox(width: 5),
            Text(_hindi ? 'हिं' : 'EN',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.neonCyan)),
          ],
        ),
      ),
    );
  }

  // ── TIMER RING (counts up — green → yellow → red as time grows) ──
  Widget _buildTimerRing() {
    Color ringColor = AppColors.success;
    if (_timerSeconds > 10) ringColor = AppColors.yellow;
    if (_timerSeconds > 30) ringColor = AppColors.error;

    return SizedBox(
      width: 56, height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 56, height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              backgroundColor: AppColors.textMuted.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(ringColor.withValues(alpha: 0.9)),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text('${_timerSeconds}s',
            style: GoogleFonts.orbitron(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: ringColor)),
        ],
      ),
    );
  }

  // ── QUESTION CARD ─────────────────────────────────
  Widget _buildQuestionCard(QuestionModel q, String stage) {
    return SlideTransition(
      position: _questionSlideAnim,
      child: FadeTransition(
        opacity: _questionFadeAnim,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              if (widget.headerLabel.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.yellow.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_edu_rounded,
                          color: AppColors.yellow, size: 13),
                      const SizedBox(width: 6),
                      Text(widget.headerLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.yellow,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 40, height: 1,
                    color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(width: 10),
                  Text(stage,
                    style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary,
                      letterSpacing: 2, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 10),
                  Container(width: 40, height: 1,
                    color: AppColors.textMuted.withValues(alpha: 0.4)),
                ],
              ),
              const SizedBox(height: 20),
              Text(q.questionFor(_hindi),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w700,
                  color: Colors.white, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }

  // ── OPTIONS ───────────────────────────────────────
  Widget _buildOptions(QuestionModel q) {
    final options = q.optionsFor(_hindi);
    final correctIndex = q.correctIndex;
    final labels = ['A', 'B', 'C', 'D'];

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => SlideTransition(
        position: _optionAnims[i],
        child: _buildOptionTile(
          index: i,
          label: labels[i],
          text: options[i],
          correctIndex: correctIndex,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required int    index,
    required String label,
    required String text,
    required int    correctIndex,
  }) {
    Color    borderColor = AppColors.darkCard;
    Color    bgColor     = AppColors.darkCard;
    Color    labelBg     = const Color(0xFF1E2A3A);
    Color    labelColor  = AppColors.textSecondary;
    Widget?  trailingIcon;

    if (_isAnswered) {
      if (index == correctIndex) {
        borderColor  = AppColors.success;
        bgColor      = AppColors.success.withValues(alpha: 0.08);
        labelBg      = AppColors.success;
        labelColor   = Colors.white;
        trailingIcon = const Icon(Icons.check_circle_rounded,
          color: AppColors.success, size: 22);
      } else if (index == _confirmedOption && index != correctIndex) {
        borderColor  = AppColors.error;
        bgColor      = AppColors.error.withValues(alpha: 0.08);
        labelBg      = AppColors.error;
        labelColor   = Colors.white;
        trailingIcon = const Icon(Icons.cancel_rounded,
          color: AppColors.error, size: 22);
      }
    } else if (index == _selectedOption) {
      borderColor  = AppColors.neonCyan;
      bgColor      = AppColors.neonCyan.withValues(alpha: 0.08);
      labelBg      = AppColors.neonCyan;
      labelColor   = AppColors.darkBg;
      trailingIcon = const Icon(Icons.check_circle_outline_rounded,
        color: AppColors.neonCyan, size: 22);
    }

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor.withValues(alpha: 
              _isAnswered || index == _selectedOption ? 0.8 : 0.15),
            width: 1.5,
          ),
          boxShadow: (index == _selectedOption && !_isAnswered)
              ? [BoxShadow(
                  color: AppColors.neonCyan.withValues(alpha: 0.15),
                  blurRadius: 12, spreadRadius: 1)]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text(label,
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: labelColor)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(text,
                style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w500,
                  color: Colors.white)),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }

  // ── CONTINUE BUTTON ───────────────────────────────
  Widget _buildContinueButton() {
    final canContinue   = _selectedOption != null && !_isAnswered;
    final isLastQ       = _currentIndex == _questions.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: canContinue ? _confirmAnswer : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56, width: double.infinity,
          decoration: BoxDecoration(
            gradient: canContinue
                ? const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF00ACC1)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)
                : null,
            color: canContinue ? null : AppColors.darkCard,
            borderRadius: BorderRadius.circular(30),
            boxShadow: canContinue
                ? [BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.35),
                    blurRadius: 20, spreadRadius: 2,
                    offset: const Offset(0, 4))]
                : null,
          ),
          child: Center(
            child: Text(
              _isAnswered
                  ? (isLastQ ? 'VIEW RESULTS' : 'NEXT QUESTION...')
                  : 'CONTINUE TO NEXT',
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: canContinue ? AppColors.darkBg : AppColors.textMuted,
                letterSpacing: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
