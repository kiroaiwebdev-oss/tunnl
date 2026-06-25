// lib/features/solve_earn/solve_earn_leaderboard_screen.dart
//
// Weekly Solve & Earn leaderboard. All entries come from the admin panel via
// weekly_challenge.php (UserService.getWeeklyChallenge()). No hardcoded users.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/app_strings.dart';

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

  bool _isLoading = true;
  Map<String, dynamic>? _challenge;
  List<Map<String, dynamic>> _leaderboard = [];

  String get _title =>
      (_challenge?['title'] ?? 'Weekly Challenge').toString();
  double get _prizeAmount =>
      (_challenge?['prize_amount'] as num?)?.toDouble() ?? 0.0;
  int get _totalParticipants => _leaderboard.length;
  bool get _hasAttempted => _challenge?['is_attempted'] == true;
  Map<String, dynamic> get _myEntry =>
      (_challenge?['my_entry'] as Map?)?.cast<String, dynamic>() ?? {};

  int get _daysLeft {
    final raw = (_challenge?['end_date'] ?? '').toString();
    if (raw.isEmpty) return 0;
    final end = DateTime.tryParse(raw);
    if (end == null) return 0;
    final d = end.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

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

    _load();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _podiumCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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
          ? lb.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
          : [];
      _isLoading = false;
    });
    _podiumCtrl
      ..reset()
      ..forward();
  }

  String _initial(String name) =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  String _fmtTime(int seconds) {
    if (seconds <= 0) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // Leaderboard banner image (admin asset: assets/images/lead.png).
  Widget _buildLeadImage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/lead.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  // Admin-announced weekly winner banner (hidden when not set).
  Widget _buildWinnerBanner() {    final winner = AppSettingsService.instance.get('weekly_winner', '').trim();
    if (winner.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2E00), Color(0xFF1A1400)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: AppColors.yellow, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('WINNER ANNOUNCED'),
                    style: GoogleFonts.orbitron(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppColors.yellow, letterSpacing: 1.5)),
                const SizedBox(height: 3),
                Text(winner,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.yellow))
                      : RefreshIndicator(
                          color: AppColors.yellow,
                          backgroundColor: AppColors.darkCard,
                          onRefresh: _load,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                _buildLeadImage(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: _buildWeeklyBanner(),
                                ),
                                _buildWinnerBanner(),
                                const SizedBox(height: 16),
                                if (_leaderboard.isEmpty)
                                  _buildEmpty()
                                else ...[
                                  _buildPodium(),
                                  const SizedBox(height: 16),
                                  if (_hasAttempted)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: _buildMyRankCard(),
                                    ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: _buildRankList(),
                                  ),
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

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: AppColors.textMuted, size: 56),
          const SizedBox(height: 12),
          Text(tr('No entries yet'),
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(tr('Be the first to attempt this challenge!'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
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
              color: AppColors.neonCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            tr('SOLVE & EARN'),
            style: GoogleFonts.orbitron(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.yellow,
              letterSpacing: 2,
            ),
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
                  color: AppColors.yellow.withValues(alpha: 0.3),
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

  // ── WEEKLY BANNER ─────────────────────────────────
  Widget _buildWeeklyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1400), Color(0xFF2A2000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.yellow.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.yellow.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.yellow.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: AppColors.yellow, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.yellow,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _prizeAmount > 0
                      ? '${tr('Prize pool')} ₹${_prizeAmount.toStringAsFixed(0)} — ${tr('top performers win!')}'
                      : tr('Top performers win rewards!'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
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
                tr('DAYS\nLEFT'),
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

  // ── PODIUM ────────────────────────────────────────
  Widget _buildPodium() {
    if (_leaderboard.length < 3) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: _leaderboard.map(_buildRankTile).toList()),
      );
    }
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
              final name = (user['name'] ?? 'User').toString();
              final score = (user['score'] as num?)?.toInt() ?? 0;

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
                          color: color.withValues(alpha: 0.12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _initial(name),
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
                        name.split(' ').first,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$score pts',
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
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              i == 1 ? '1st' : i == 0 ? '2nd' : '3rd',
                              style: GoogleFonts.orbitron(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color.withValues(alpha: 0.8),
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
    final score = (_myEntry['score'] as num?)?.toInt() ?? 0;
    final accuracy = (_myEntry['accuracy'] as num?)?.toDouble() ?? 0.0;
    final timeTaken = (_myEntry['time_taken'] as num?)?.toInt() ?? 0;
    final isWinner = _myEntry['is_winner'] == true;
    final prizeWon = (_myEntry['prize_won'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.neonCyan.withValues(alpha: 0.1),
            AppColors.neonCyan.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonCyan.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neonCyan,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tr('YOU'),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBg,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Your attempt'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$score pts  •  ${accuracy.toStringAsFixed(0)}%  •  ${_fmtTime(timeTaken)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isWinner && prizeWon > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.yellow.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '₹${prizeWon.toStringAsFixed(0)}',
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
    final rest =
        _leaderboard.length > 3 ? _leaderboard.skip(3).toList() : <Map<String, dynamic>>[];
    if (rest.isEmpty) return const SizedBox.shrink();
    return Column(children: rest.map(_buildRankTile).toList());
  }

  Widget _buildRankTile(Map<String, dynamic> user) {
    final rank = (user['rank'] as num?)?.toInt() ?? 0;
    final name = (user['name'] ?? 'User').toString();
    final score = (user['score'] as num?)?.toInt() ?? 0;
    final accuracy = (user['accuracy'] as num?)?.toDouble() ?? 0.0;
    final timeTaken = (user['time_taken'] as num?)?.toInt() ?? 0;
    final isTop = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTop
              ? AppColors.yellow.withValues(alpha: 0.15)
              : AppColors.textMuted.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: GoogleFonts.orbitron(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isTop ? AppColors.yellow : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkSurface,
              border: Border.all(
                color: AppColors.textMuted.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                _initial(name),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$score pts  •  ${accuracy.toStringAsFixed(0)}%  •  ${_fmtTime(timeTaken)}',
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
}
