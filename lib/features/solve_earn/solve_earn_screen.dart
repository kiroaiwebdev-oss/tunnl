import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
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

  // Weekly challenge data — API se aayega
  final int _daysLeft = 3;
  final int _hoursLeft = 14;
  final int _totalQuestions = 20;
  final bool _hasAttempted = false;
  final int _myScore = 0;
  final int _myRank = 0;
  final int _totalParticipants = 1240;

  // Prize pool
  final List<Map<String, dynamic>> _prizes = [
    {'rank': '1st', 'icon': '🥇', 'prize': '₹500', 'color': const Color(0xFFFFD700)},
    {'rank': '2nd', 'icon': '🥈', 'prize': '₹300', 'color': const Color(0xFFC0C0C0)},
    {'rank': '3rd', 'icon': '🥉', 'prize': '₹200', 'color': const Color(0xFFCD7F32)},
    {'rank': '4th', 'icon': '🎖️', 'prize': '₹100', 'color': AppColors.neonCyan},
    {'rank': '5th', 'icon': '🎖️', 'prize': '₹50',  'color': AppColors.neonCyan},
  ];

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
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
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
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  // ── AppBar
                  _buildAppBar(),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          // ── Hero Banner
                          _buildHeroBanner(),

                          const SizedBox(height: 16),

                          // ── Timer Card
                          _buildTimerCard(),

                          const SizedBox(height: 16),

                          // ── Prize Pool
                          _buildPrizePool(),

                          const SizedBox(height: 16),

                          // ── My Status (if attempted)
                          if (_hasAttempted) ...[
                            _buildMyStatus(),
                            const SizedBox(height: 16),
                          ],

                          // ── How it works
                          _buildHowItWorks(),

                          const SizedBox(height: 16),

                          // ── Rules
                          _buildRules(),

                          const SizedBox(height: 24),

                          // ── Action buttons
                          _buildActionButtons(),

                          const SizedBox(height: 30),
                        ],
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
          // Participants
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
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
                const Icon(
                  Icons.people_rounded,
                  color: AppColors.yellow,
                  size: 13,
                ),
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
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Trophy icon
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.yellow,
                size: 36,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'WEEKLY CHALLENGE',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.yellow,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Solve $_totalQuestions questions as fast as possible\nTop 5 winners get REAL rewards!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            // Total prize chip
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
                  const Icon(
                    Icons.currency_rupee_rounded,
                    color: AppColors.yellow,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Total Prize Pool: ₹1150',
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
        ),
      ),
    );
  }

  // ── TIMER CARD ────────────────────────────────────
  Widget _buildTimerCard() {
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
          // Timer icon
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
            child: const Icon(
              Icons.timer_rounded,
              color: AppColors.neonCyan,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Time info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenge Ends In',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_daysLeft Days $_hoursLeft Hours',
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neonCyan,
                  ),
                ),
              ],
            ),
          ),

          // Time boxes
          Row(
            children: [
              _TimeBox(value: '$_daysLeft', label: 'DAYS'),
              const SizedBox(width: 6),
              Text(
                ':',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  color: AppColors.neonCyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              _TimeBox(value: '$_hoursLeft', label: 'HRS'),
            ],
          ),
        ],
      ),
    );
  }

  // ── PRIZE POOL ────────────────────────────────────
  Widget _buildPrizePool() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.yellow,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'PRIZE POOL',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.yellow,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: _prizes.map((prize) {
            final color = prize['color'] as Color;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      prize['icon'],
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      prize['prize'],
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prize['rank'],
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── MY STATUS ─────────────────────────────────────
  Widget _buildMyStatus() {
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
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have attempted this week!',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Score: $_myScore pts  •  Rank: #$_myRank',
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
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

  // ── HOW IT WORKS ──────────────────────────────────
  Widget _buildHowItWorks() {
    final steps = [
      {
        'num': '01',
        'title': 'Attempt Challenge',
        'desc': 'Solve 20 questions as fast as you can',
        'icon': Icons.play_arrow_rounded,
        'color': AppColors.neonCyan,
      },
      {
        'num': '02',
        'title': 'Score Submitted',
        'desc': 'Your score + time is saved automatically',
        'icon': Icons.upload_rounded,
        'color': AppColors.yellow,
      },
      {
        'num': '03',
        'title': 'Week Ends',
        'desc': 'Challenge closes after 7 days',
        'icon': Icons.timer_off_rounded,
        'color': AppColors.orange,
      },
      {
        'num': '04',
        'title': 'Winners Rewarded',
        'desc': 'Top 5 get prizes via UPI/Amazon/Flipkart',
        'icon': Icons.emoji_events_rounded,
        'color': AppColors.yellow,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW IT WORKS',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...steps.map((step) {
          final color = step['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      step['num'] as String,
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        step['desc'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  step['icon'] as IconData,
                  color: color.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── RULES ─────────────────────────────────────────
  Widget _buildRules() {
    final rules = [
      'Each question carries equal marks',
      'Faster completion = Higher rank (tie-breaker)',
      'Only ONE attempt allowed per week',
      'Results announced after challenge ends',
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
              const Icon(
                Icons.rule_rounded,
                color: AppColors.neonCyan,
                size: 16,
              ),
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
    return Column(
      children: [
        // START CHALLENGE button
        GestureDetector(
          onTap: _hasAttempted
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QuestionScreen(
                        mode: 'solve_earn',
                        category: 'mcq',
                        setNumber: 1,
                        totalQuestions: 20,
                      ),
                    ),
                  );
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _hasAttempted
                  ? null
                  : const LinearGradient(
                      colors: [
                        Color(0xFFFFD600),
                        Color(0xFFFF8F00),
                      ],
                    ),
              color: _hasAttempted
                  ? AppColors.darkCard
                  : null,
              borderRadius: BorderRadius.circular(28),
              border: _hasAttempted
                  ? Border.all(
                      color: AppColors.textMuted.withOpacity(0.2),
                      width: 1,
                    )
                  : null,
              boxShadow: _hasAttempted
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.yellow.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _hasAttempted
                      ? Icons.check_circle_rounded
                      : Icons.play_arrow_rounded,
                  color: _hasAttempted
                      ? AppColors.textMuted
                      : AppColors.darkBg,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _hasAttempted
                      ? 'ALREADY ATTEMPTED'
                      : 'START CHALLENGE',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _hasAttempted
                        ? AppColors.textMuted
                        : AppColors.darkBg,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // VIEW LEADERBOARD button
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
                const Icon(
                  Icons.leaderboard_rounded,
                  color: AppColors.neonCyan,
                  size: 18,
                ),
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