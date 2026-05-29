import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class SolveEarnLeaderboardScreen extends StatefulWidget {
  const SolveEarnLeaderboardScreen({super.key});

  @override
  State<SolveEarnLeaderboardScreen> createState() =>
      _SolveEarnLeaderboardScreenState();
}

class _SolveEarnLeaderboardScreenState
    extends State<SolveEarnLeaderboardScreen>
    with TickerProviderStateMixin {

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _podiumCtrl;
  late Animation<double> _podiumAnim;

  // Weekly Solve & Earn leaderboard data
  final List<Map<String, dynamic>> _leaderboard = [
    {'rank': 1, 'name': 'Rahul Sharma',  'score': 980, 'solved': 49, 'reward': '₹500 Amazon', 'isMe': false},
    {'rank': 2, 'name': 'Priya Singh',   'score': 950, 'solved': 47, 'reward': '₹300 Flipkart', 'isMe': false},
    {'rank': 3, 'name': 'Amit Kumar',    'score': 920, 'solved': 46, 'reward': '₹200 Paytm', 'isMe': false},
    {'rank': 4, 'name': 'You',           'score': 880, 'solved': 44, 'reward': '₹100 UPI', 'isMe': true},
    {'rank': 5, 'name': 'Neha Gupta',    'score': 850, 'solved': 42, 'reward': '₹50 UPI', 'isMe': false},
    {'rank': 6, 'name': 'Vikram Patil',  'score': 820, 'solved': 41, 'reward': '-', 'isMe': false},
    {'rank': 7, 'name': 'Sneha Rao',     'score': 790, 'solved': 39, 'reward': '-', 'isMe': false},
    {'rank': 8, 'name': 'Rohit Verma',   'score': 760, 'solved': 38, 'reward': '-', 'isMe': false},
    {'rank': 9, 'name': 'Kavya Nair',    'score': 730, 'solved': 36, 'reward': '-', 'isMe': false},
    {'rank': 10,'name': 'Arjun Mehta',   'score': 700, 'solved': 35, 'reward': '-', 'isMe': false},
  ];

  // Days left in week
  final int _daysLeft = 3;
  final int _totalParticipants = 1240;

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

    _podiumCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _podiumAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _podiumCtrl, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _podiumCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _podiumCtrl.dispose();
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
                // ── AppBar
                _buildAppBar(),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // ── Weekly banner
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          child: _buildWeeklyBanner(),
                        ),

                        const SizedBox(height: 16),

                        // ── Rewards info
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          child: _buildRewardsInfo(),
                        ),

                        const SizedBox(height: 20),

                        // ── Top 3 podium
                        _buildPodium(),

                        const SizedBox(height: 16),

                        // ── My rank
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          child: _buildMyRankCard(),
                        ),

                        const SizedBox(height: 12),

                        // ── Full list
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          child: _buildRankList(),
                        ),

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
          Text(
            'SOLVE & EARN',
            style: GoogleFonts.orbitron(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.yellow,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Participants chip
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

  // ── WEEKLY BANNER ─────────────────────────────────
  Widget _buildWeeklyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1400),
            Color(0xFF2A2000),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.yellow.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Trophy
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.yellow.withOpacity(0.1),
              border: Border.all(
                color: AppColors.yellow.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.yellow,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEEKLY CHALLENGE',
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.yellow,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Top 5 winners get real rewards!',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Days left
          Column(
            children: [
              Text(
                '$_daysLeft',
                style: GoogleFonts.orbitron(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.yellow,
                ),
              ),
              Text(
                'DAYS\nLEFT',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── REWARDS INFO ──────────────────────────────────
  Widget _buildRewardsInfo() {
    final rewards = [
      {'rank': '1st', 'prize': '₹500', 'icon': '🥇', 'color': AppColors.yellow},
      {'rank': '2nd', 'prize': '₹300', 'icon': '🥈', 'color': const Color(0xFFC0C0C0)},
      {'rank': '3rd', 'prize': '₹200', 'icon': '🥉', 'color': const Color(0xFFCD7F32)},
      {'rank': '4th', 'prize': '₹100', 'icon': '🎖️', 'color': AppColors.neonCyan},
      {'rank': '5th', 'prize': '₹50',  'icon': '🎖️', 'color': AppColors.neonCyan},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRIZE POOL',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: rewards.map((r) {
            final color = r['color'] as Color;
            return Container(
              width: (MediaQuery.of(context).size.width - 56) / 5,
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    r['icon'] as String,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r['prize'] as String,
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    r['rank'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── PODIUM ────────────────────────────────────────
  Widget _buildPodium() {
    final top3 = _leaderboard.take(3).toList();
    final podiumOrder = [top3[1], top3[0], top3[2]];
    final heights = [85.0, 115.0, 65.0];
    final medals = ['🥈', '🥇', '🥉'];
    final colors = [
      const Color(0xFFC0C0C0),
      AppColors.yellow,
      const Color(0xFFCD7F32),
    ];

    return AnimatedBuilder(
      animation: _podiumAnim,
      builder: (_, __) {
        return SizedBox(
          height: 210,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final user = podiumOrder[i];
              final color = colors[i];

              return Expanded(
                child: Opacity(
                  opacity: _podiumAnim.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(medals[i],
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Container(
                        width: i == 1 ? 54 : 44,
                        height: i == 1 ? 54 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.12),
                          border: Border.all(
                            color: color.withOpacity(0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.25),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user['name'][0].toUpperCase(),
                            style: GoogleFonts.orbitron(
                              fontSize: i == 1 ? 20 : 16,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['name'].toString().split(' ')[0],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${user['score']}pts',
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Transform.scale(
                        scaleY: _podiumAnim.value,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: heights[i],
                          margin: const EdgeInsets.symmetric(
                              horizontal: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            border: Border.all(
                              color: color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              i == 1 ? '1st' : i == 0 ? '2nd' : '3rd',
                              style: GoogleFonts.orbitron(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ── MY RANK ───────────────────────────────────────
  Widget _buildMyRankCard() {
    final me = _leaderboard.firstWhere(
      (u) => u['isMe'] == true,
      orElse: () => _leaderboard[3],
    );
    final isWinner = (me['rank'] as int) <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.neonCyan.withOpacity(0.1),
            AppColors.neonCyan.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonCyan.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neonCyan,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'YOU',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBg,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '#${me['rank']}',
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.neonCyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${me['score']} pts  •  ${me['solved']} solved',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Reward badge
          if (isWinner)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.yellow.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                me['reward'],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.yellow,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── RANK LIST ─────────────────────────────────────
  Widget _buildRankList() {
    return Column(
      children: _leaderboard.map((user) {
        final bool isMe = user['isMe'] == true;
        final int rank = user['rank'] as int;
        final bool isWinner = rank <= 5;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.neonCyan.withOpacity(0.05)
                : AppColors.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMe
                  ? AppColors.neonCyan.withOpacity(0.3)
                  : isWinner
                      ? AppColors.yellow.withOpacity(0.15)
                      : AppColors.textMuted.withOpacity(0.1),
              width: isMe ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 32,
                child: Text(
                  '#$rank',
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isMe
                        ? AppColors.neonCyan
                        : isWinner
                            ? AppColors.yellow
                            : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMe
                      ? AppColors.neonCyan.withOpacity(0.12)
                      : AppColors.darkSurface,
                  border: Border.all(
                    color: isMe
                        ? AppColors.neonCyan.withOpacity(0.4)
                        : AppColors.textMuted.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    user['name'][0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isMe
                          ? AppColors.neonCyan
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name + solved
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.neonCyan,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'YOU',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkBg,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${user['solved']} solved  •  ${user['score']} pts',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Reward
              if (isWinner && user['reward'] != '-')
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.yellow.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    user['reward'],
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.yellow,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}