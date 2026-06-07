// lib/features/solve_earn/solve_earn_screen.dart
//
// Weekly "Solve & Earn" challenge. ALL data comes from the admin panel via
// weekly_challenge.php (UserService.getWeeklyChallenge()). Nothing hardcoded.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart';
import '../question/question_screen.dart';
import 'solve_earn_leaderboard_screen.dart';

class SolveEarnScreen extends StatefulWidget {
  const SolveEarnScreen({super.key});

  @override
  State<SolveEarnScreen> createState() => _SolveEarnScreenState();
}

class _SolveEarnScreenState extends State<SolveEarnScreen>
    with TickerProviderStateMixin {

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Live challenge data (admin-driven) ────────────
  bool _isLoading = true;
  Map<String, dynamic>? _challenge;
  List<Map<String, dynamic>> _leaderboard = [];

  bool get _hasChallenge => _challenge != null;
  bool get _hasAttempted => _challenge?['is_attempted'] == true;
  Map<String, dynamic> get _myEntry =>
      (_challenge?['my_entry'] as Map?)?.cast<String, dynamic>() ?? {};

  int get _totalQuestions =>
      (_challenge?['total_questions'] as num?)?.toInt() ?? 0;
  double get _prizeAmount =>
      (_challenge?['prize_amount'] as num?)?.toDouble() ?? 0.0;
  int get _totalParticipants => _leaderboard.length;

  // Time remaining computed from end_date
  Duration get _timeLeft {
    final raw = (_challenge?['end_date'] ?? '').toString();
    if (raw.isEmpty) return Duration.zero;
    final end = DateTime.tryParse(raw);
    if (end == null) return Duration.zero;
    final diff = end.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  int get _daysLeft => _timeLeft.inDays;
  int get _hoursLeft => _timeLeft.inHours % 24;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _loadChallenge();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChallenge() async {
    setState(() => _isLoading = true);
    final res = await UserService.getWeeklyChallenge();
    if (!mounted) return;

    final ok = res['success'] == true || res['status'] == true;
    final challenge = res['challenge'];
    final lb = res['leaderboard'];

    setState(() {
      _challenge = (ok && challenge is Map)
          ? challenge.cast<String, dynamic>()
          : null;
      _leaderboard = (lb is List)
          ? lb
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList()
          : [];
      _isLoading = false;
    });
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
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.yellow))
                        : !_hasChallenge
                            ? _buildNoChallenge()
                            : RefreshIndicator(
                                color: AppColors.yellow,
                                backgroundColor: AppColors.darkCard,
                                onRefresh: _loadChallenge,
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 10),
                                      _buildHeroBanner(),
                                      const SizedBox(height: 16),
                                      _buildTimerCard(),
                                      const SizedBox(height: 16),
                                      _buildPrizeCard(),
                                      const SizedBox(height: 16),
                                      if (_hasAttempted) ...[
                                        _buildMyStatus(),
                                        const SizedBox(height: 16),
                                      ],
                                      _buildRules(),
                                      const SizedBox(height: 24),
                                      _buildActionButtons(),
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
      ),
    );
  }

  // ── NO ACTIVE CHALLENGE ───────────────────────────
  Widget _buildNoChallenge() {
    return RefreshIndicator(
      color: AppColors.yellow,
      backgroundColor: AppColors.darkCard,
      onRefresh: _loadChallenge,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Icon(Icons.emoji_events_outlined,
              color: AppColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Center(
            child: Text('No active challenge',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('Admin will launch the next weekly challenge soon!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
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
              color: AppColors.yellow,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOLVE & EARN',
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.yellow,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Solve. Compete. Win Rewards!',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_totalParticipants > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.yellow.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_rounded,
                      color: AppColors.yellow, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    '$_totalParticipants',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.yellow,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── HERO BANNER ───────────────────────────────────
  Widget _buildHeroBanner() {
    final title = (_challenge?['title'] ?? 'WEEKLY CHALLENGE').toString();
    final desc = (_challenge?['description'] ?? '').toString();
    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A1F00), Color(0xFF1A1400), Color(0xFF0F0F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.yellow.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow.withOpacity(0.12),
                border: Border.all(
                  color: AppColors.yellow.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.yellow,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.yellow,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc.isNotEmpty
                  ? desc
                  : 'Solve $_totalQuestions questions as fast as possible.\nTop performers win real rewards!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (_prizeAmount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.yellow.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_rupee_rounded,
                        color: AppColors.yellow, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Total Prize Pool: ₹${_prizeAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.yellow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── TIMER CARD ────────────────────────────────────
  Widget _buildTimerCard() {
    final ended = _timeLeft == Duration.zero;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.neonCyan.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonCyan.withOpacity(0.1),
              border: Border.all(
                color: AppColors.neonCyan.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(Icons.timer_rounded,
                color: AppColors.neonCyan, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ended ? 'Challenge Closed' : 'Challenge Ends In',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ended ? '—' : '$_daysLeft Days $_hoursLeft Hours',
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neonCyan,
                  ),
                ),
              ],
            ),
          ),
          if (!ended)
            Row(
              children: [
                _TimeBox(value: '$_daysLeft', label: 'DAYS'),
                const SizedBox(width: 6),
                Text(':',
                    style: GoogleFonts.orbitron(
                        fontSize: 18,
                        color: AppColors.neonCyan,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                _TimeBox(value: '$_hoursLeft', label: 'HRS'),
              ],
            ),
        ],
      ),
    );
  }

  // ── PRIZE CARD ────────────────────────────────────
  Widget _buildPrizeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.yellow.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded,
              color: AppColors.yellow, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prize Pool',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  _prizeAmount > 0
                      ? 'Top performers share ₹${_prizeAmount.toStringAsFixed(0)} — paid via UPI / vouchers'
                      : 'Compete to win rewards announced by admin',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── MY STATUS ─────────────────────────────────────
  Widget _buildMyStatus() {
    final score = (_myEntry['score'] as num?)?.toInt() ?? 0;
    final accuracy = (_myEntry['accuracy'] as num?)?.toDouble() ?? 0.0;
    final isWinner = _myEntry['is_winner'] == true;
    final prizeWon = (_myEntry['prize_won'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.neonCyan.withOpacity(0.08),
            AppColors.neonCyan.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.neonCyan.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWinner
                      ? 'You won ₹${prizeWon.toStringAsFixed(0)}! 🎉'
                      : 'You have attempted this challenge!',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Score: $score  •  Accuracy: ${accuracy.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SolveEarnLeaderboardScreen(),
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.neonCyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Leaderboard',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neonCyan,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── RULES ─────────────────────────────────────────
  Widget _buildRules() {
    final rules = [
      'Each question carries equal marks',
      'Faster completion = Higher rank (tie-breaker)',
      'Only ONE attempt allowed per challenge',
      'Results announced after the challenge ends',
      'Admin will contact winners for reward delivery',
    ];

    return Container(
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
          Row(
            children: [
              const Icon(Icons.rule_rounded,
                  color: AppColors.neonCyan, size: 16),
              const SizedBox(width: 6),
              Text(
                'RULES',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rules.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 1, right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonCyan.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── ACTION BUTTONS ────────────────────────────────
  Widget _buildActionButtons() {
    final ended = _timeLeft == Duration.zero;
    final disabled = _hasAttempted || ended || _totalQuestions <= 0;

    String label;
    if (_hasAttempted) {
      label = 'ALREADY ATTEMPTED';
    } else if (ended) {
      label = 'CHALLENGE CLOSED';
    } else if (_totalQuestions <= 0) {
      label = 'NO QUESTIONS YET';
    } else {
      label = 'START CHALLENGE';
    }

    return Column(
      children: [
        GestureDetector(
          onTap: disabled
              ? null
              : () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuestionScreen(
                        mode: 'solve_earn',
                        category: 'mcq',
                        setNumber: 1,
                        totalQuestions: _totalQuestions,
                      ),
                    ),
                  );
                  if (mounted) _loadChallenge();
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: disabled
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFFFD600), Color(0xFFFF8F00)],
                    ),
              color: disabled ? AppColors.darkCard : null,
              borderRadius: BorderRadius.circular(28),
              border: disabled
                  ? Border.all(
                      color: AppColors.textMuted.withOpacity(0.2), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  disabled
                      ? Icons.lock_clock_rounded
                      : Icons.play_arrow_rounded,
                  color: disabled ? AppColors.textMuted : AppColors.darkBg,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: disabled ? AppColors.textMuted : AppColors.darkBg,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SolveEarnLeaderboardScreen(),
              ),
            );
          },
          child: Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.neonCyan.withOpacity(0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.leaderboard_rounded,
                    color: AppColors.neonCyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  'VIEW LEADERBOARD',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neonCyan,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// TIME BOX WIDGET
// ─────────────────────────────────────────────────────
class _TimeBox extends StatelessWidget {
  final String value;
  final String label;

  const _TimeBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.neonCyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.neonCyan.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.neonCyan,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
