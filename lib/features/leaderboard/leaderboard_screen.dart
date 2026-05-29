import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {

  int _selectedTab = 0; // 0=Daily, 1=Weekly, 2=All Time

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late AnimationController _podiumCtrl;
  late Animation<double> _podiumAnim;

  // Dummy leaderboard data — API se replace hoga
  final List<Map<String, dynamic>> _dailyData = [
    {'rank': 1, 'name': 'Rahul Sharma',   'score': 98, 'accuracy': '98%', 'speed': '4.2s', 'xp': 320, 'isMe': false},
    {'rank': 2, 'name': 'Priya Singh',    'score': 95, 'accuracy': '95%', 'speed': '4.8s', 'xp': 290, 'isMe': false},
    {'rank': 3, 'name': 'Amit Kumar',     'score': 92, 'accuracy': '92%', 'speed': '5.1s', 'xp': 260, 'isMe': false},
    {'rank': 4, 'name': 'You',            'score': 88, 'accuracy': '88%', 'speed': '5.8s', 'xp': 230, 'isMe': true},
    {'rank': 5, 'name': 'Neha Gupta',     'score': 85, 'accuracy': '85%', 'speed': '6.2s', 'xp': 210, 'isMe': false},
    {'rank': 6, 'name': 'Vikram Patil',   'score': 82, 'accuracy': '82%', 'speed': '6.5s', 'xp': 195, 'isMe': false},
    {'rank': 7, 'name': 'Sneha Rao',      'score': 79, 'accuracy': '79%', 'speed': '7.0s', 'xp': 180, 'isMe': false},
    {'rank': 8, 'name': 'Rohit Verma',    'score': 76, 'accuracy': '76%', 'speed': '7.3s', 'xp': 165, 'isMe': false},
    {'rank': 9, 'name': 'Kavya Nair',     'score': 73, 'accuracy': '73%', 'speed': '7.8s', 'xp': 150, 'isMe': false},
    {'rank': 10,'name': 'Arjun Mehta',    'score': 70, 'accuracy': '70%', 'speed': '8.1s', 'xp': 140, 'isMe': false},
  ];

  List<Map<String, dynamic>> get _currentData => _dailyData;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _podiumCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _podiumAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _podiumCtrl, curve: Curves.easeOutCubic),
    );

    _entryCtrl.forward();
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
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  // ── AppBar
                  _buildAppBar(),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          // ── Tab selector
                          _buildTabSelector(),

                          const SizedBox(height: 20),

                          // ── Top 3 Podium
                          _buildPodium(),

                          const SizedBox(height: 20),

                          // ── My Rank card
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            child: _buildMyRankCard(),
                          ),

                          const SizedBox(height: 16),

                          // ── Rank list (4 onwards)
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
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
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
            'LEADERBOARD',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.neonCyan,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Total users chip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.neonCyan.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.people_rounded,
                  color: AppColors.neonCyan,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '12,000+',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.neonCyan,
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

  // ── TAB SELECTOR ──────────────────────────────────
  Widget _buildTabSelector() {
    final tabs = ['DAILY', 'WEEKLY', 'ALL TIME'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.textMuted.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final i = entry.key;
            final isActive = _selectedTab == i;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.neonCyan
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? AppColors.darkBg
                            : AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── PODIUM (Top 3) ────────────────────────────────
  Widget _buildPodium() {
    final top3 = _currentData.take(3).toList();
    // Order: 2nd, 1st, 3rd
    final podiumOrder = [top3[1], top3[0], top3[2]];
    final heights = [90.0, 120.0, 70.0];
    final medals = ['🥈', '🥇', '🥉'];
    final colors = [
      const Color(0xFFC0C0C0), // Silver
      AppColors.yellow,         // Gold
      const Color(0xFFCD7F32), // Bronze
    ];

    return AnimatedBuilder(
      animation: _podiumAnim,
      builder: (_, __) {
        return SizedBox(
          height: 220,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final user = podiumOrder[i];
              final animOffset = _podiumAnim.value;

              return Expanded(
                child: Opacity(
                  opacity: animOffset,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Medal + Name
                      Text(
                        medals[i],
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      // Avatar circle
                      Container(
                        width: i == 1 ? 58 : 48,
                        height: i == 1 ? 58 : 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[i].withOpacity(0.15),
                          border: Border.all(
                            color: colors[i].withOpacity(0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors[i].withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user['name'][0].toUpperCase(),
                            style: GoogleFonts.orbitron(
                              fontSize: i == 1 ? 22 : 18,
                              fontWeight: FontWeight.w700,
                              color: colors[i],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Name
                      Text(
                        user['name'].toString().split(' ')[0],
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      // Score
                      Text(
                        '${user['score']}',
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors[i],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Podium bar
                      Transform.scale(
                        scaleY: _podiumAnim.value,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: heights[i],
                          margin: const EdgeInsets.symmetric(
                              horizontal: 6),
                          decoration: BoxDecoration(
                            color: colors[i].withOpacity(0.12),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            border: Border.all(
                              color: colors[i].withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              i == 1 ? '1st' : i == 0 ? '2nd' : '3rd',
                              style: GoogleFonts.orbitron(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colors[i].withOpacity(0.8),
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

  // ── MY RANK CARD ──────────────────────────────────
  Widget _buildMyRankCard() {
    final me = _currentData.firstWhere(
      (u) => u['isMe'] == true,
      orElse: () => _currentData[3],
    );

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.neonCyan.withOpacity(0.12),
            AppColors.neonCyan.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonCyan.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // MY badge
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

          // Rank number
          Text(
            '#${me['rank']}',
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.neonCyan,
            ),
          ),

          const SizedBox(width: 12),

          // Name + score
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
                  'Score: ${me['score']}  •  ${me['accuracy']}  •  ${me['speed']}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // XP
          Column(
            children: [
              Text(
                '+${me['xp']}',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan,
                ),
              ),
              Text(
                'XP',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── RANK LIST (4 onwards) ─────────────────────────
  Widget _buildRankList() {
    final rest = _currentData.skip(3).toList();

    return Column(
      children: rest.map((user) {
        return _RankItem(data: user);
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────
// RANK ITEM
// ─────────────────────────────────────────────────────
class _RankItem extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RankItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isMe = data['isMe'] == true;
    final int rank = data['rank'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.neonCyan.withOpacity(0.05)
            : AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AppColors.neonCyan.withOpacity(0.3)
              : AppColors.textMuted.withOpacity(0.1),
          width: isMe ? 1.3 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: GoogleFonts.orbitron(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isMe
                    ? AppColors.neonCyan
                    : AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe
                  ? AppColors.neonCyan.withOpacity(0.15)
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
                data['name'][0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isMe
                      ? AppColors.neonCyan
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Name + speed
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data['name'],
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
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan,
                          borderRadius: BorderRadius.circular(6),
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
                  '${data['accuracy']}  •  ${data['speed']}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data['score']}',
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isMe ? AppColors.neonCyan : Colors.white,
                ),
              ),
              Text(
                '+${data['xp']} XP',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}