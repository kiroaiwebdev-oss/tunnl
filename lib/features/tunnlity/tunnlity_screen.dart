// lib/features/tunnlity/tunnlity_screen.dart
//
// Landing screen for the "Test Your Tunnelity" speed test.
// - First time  → START TEST
// - After a try → REATTEMPT + VIEW SCORE, plus a personal-best card
//   (acts as the Tunnlity mini-leaderboard, stored locally).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../question/question_screen.dart';
import 'tunnlity_leaderboard_screen.dart';

class TunnlityScreen extends StatefulWidget {
  const TunnlityScreen({super.key});

  @override
  State<TunnlityScreen> createState() => _TunnlityScreenState();
}

class _TunnlityScreenState extends State<TunnlityScreen> {
  bool   _loading      = true;
  int    _attempts     = 0;
  double _bestScore    = 0;
  double _bestAccuracy = 0;
  double _lastScore    = 0;
  double _lastAccuracy = 0;
  int    _lastCorrect  = 0;
  int    _lastTotal    = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      setState(() {
        _attempts     = p.getInt('tunnlity_attempts')        ?? 0;
        _bestScore    = p.getDouble('tunnlity_best_score')    ?? 0;
        _bestAccuracy = p.getDouble('tunnlity_best_accuracy') ?? 0;
        _lastScore    = p.getDouble('tunnlity_last_score')    ?? 0;
        _lastAccuracy = p.getDouble('tunnlity_last_accuracy') ?? 0;
        _lastCorrect  = p.getInt('tunnlity_last_correct')     ?? 0;
        _lastTotal    = p.getInt('tunnlity_last_total')       ?? 0;
        _loading      = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startTest() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => const QuestionScreen(
            mode: 'tunnelity',
            category: 'tunnlity',
            setNumber: 1,
            totalQuestions: 10,
          ),
        ))
        .then((_) {
      if (mounted) _load();
    });
  }

  void _viewScore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 18),
            Text('Your Tunnelity Score',
              style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _scoreBox(
                  'LAST SCORE', '${_lastScore.toStringAsFixed(1)}/10',
                  '${_lastAccuracy.toStringAsFixed(0)}% accuracy',
                  AppColors.neonCyan)),
                const SizedBox(width: 12),
                Expanded(child: _scoreBox(
                  'PERSONAL BEST', '${_bestScore.toStringAsFixed(1)}/10',
                  '${_bestAccuracy.toStringAsFixed(0)}% accuracy',
                  AppColors.yellow)),
              ],
            ),
            const SizedBox(height: 14),
            Text('Last attempt: $_lastCorrect / $_lastTotal correct',
              style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
            style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value,
            style: GoogleFonts.orbitron(
              fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(sub,
            style: GoogleFonts.poppins(
              fontSize: 10, color: AppColors.textSecondary)),
        ],
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
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.neonCyan))
              : Column(
                  children: [
                    _appBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _heroCard(),
                            const SizedBox(height: 20),
                            if (_attempts > 0) _bestCard(),
                            if (_attempts > 0) const SizedBox(height: 20),
                            _buttons(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.neonCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TEST YOUR TUNNELITY',
                style: GoogleFonts.orbitron(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan, letterSpacing: 2)),
              Text('A quick 10-question speed test',
                style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.12),
              shape: BoxShape.circle),
            child: const Icon(Icons.bolt_rounded,
                color: AppColors.neonCyan, size: 34),
          ),
          const SizedBox(height: 14),
          Text('How fast can you solve?',
            style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            '10 timed questions. Answer quickly and accurately to boost your '
            'Tunnelity score. Beat your personal best!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _bestCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.yellow, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Personal Best',
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.white)),
                const SizedBox(height: 2),
                Text('$_attempts attempt${_attempts == 1 ? '' : 's'} • '
                    '${_bestAccuracy.toStringAsFixed(0)}% best accuracy',
                  style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('${_bestScore.toStringAsFixed(1)}/10',
            style: GoogleFonts.orbitron(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: AppColors.yellow)),
        ],
      ),
    );
  }

  Widget _buttons() {
    return Column(
      children: [
        GestureDetector(
          onTap: _startTest,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF00ACC1)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(
                color: AppColors.neonCyan.withValues(alpha: 0.35),
                blurRadius: 18, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: Text(_attempts > 0 ? 'REATTEMPT' : 'START TEST',
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.darkBg, letterSpacing: 2)),
            ),
          ),
        ),
        if (_attempts > 0) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _viewScore,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text('VIEW SCORE',
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.neonCyan, letterSpacing: 2)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const TunnlityLeaderboardScreen())),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: AppColors.yellow.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: AppColors.yellow, size: 20),
                const SizedBox(width: 10),
                Text('VIEW LEADERBOARD',
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.yellow, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
