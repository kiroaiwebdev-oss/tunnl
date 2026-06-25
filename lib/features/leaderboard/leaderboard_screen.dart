// lib/features/leaderboard/leaderboard_screen.dart
//
// Loads leaderboard entries from admin/leaderboard.php

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_strings.dart';
import '../../core/services/user_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {

  int _selectedTab = 0; // 0=Weekly, 1=Monthly, 2=All Time

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late AnimationController _podiumCtrl;
  late Animation<double> _podiumAnim;

  // Live data per tab
  List<Map<String, dynamic>> _data = [];
  int? _myRank;
  int? _myXp;
  bool _isLoading = true;

  String get _currentType {
    switch (_selectedTab) {
      case 0:
        return 'weekly';
      case 1:
        return 'monthly';
      default:
        return 'all_time';
    }
  }

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
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _podiumCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    final res = await UserService.getLeaderboard(type: _currentType, limit: 50);
    if (!mounted) return;
    final entries = (res['entries'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    setState(() {
      _data = entries;
      _myRank = (res['my_rank'] as num?)?.toInt();
      _myXp = (res['my_xp'] as num?)?.toInt();
      _isLoading = false;
    });
    _podiumCtrl
      ..reset()
      ..forward();
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
                                color: AppColors.neonCyan))
                        : RefreshIndicator(
                            color: AppColors.neonCyan,
                            backgroundColor: AppColors.darkCard,
                            onRefresh: _loadLeaderboard,
                            child: SingleChildScrollView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  _buildLeadImage(),
                                  _buildTabSelector(),
                                  const SizedBox(height: 20),
                                  if (_data.isEmpty)
                                    _buildEmpty()
                                  else ...[
                                    _buildPodium(),
                                    const SizedBox(height: 20),
                                    if (_myRank != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: _buildMyRankCard(),
                                      ),
                                    const SizedBox(height: 16),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: _buildRankList(),
                                    ),
                                    const SizedBox(height: 30),
                                  ],
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

  // Leaderboard banner image (admin asset: assets/images/lead.png).
  // Falls back to nothing if the file isn't bundled yet.
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.neonCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Text(tr('LEADERBOARD'),
              style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan,
                  letterSpacing: 2)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.2), width: 1)),
            child: Row(
              children: [
                const Icon(Icons.people_rounded,
                    color: AppColors.neonCyan, size: 14),
                const SizedBox(width: 4),
                Text('${_data.length}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.neonCyan,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = [tr('WEEKLY'), tr('MONTHLY'), tr('ALL TIME')];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: AppColors.textMuted.withValues(alpha: 0.15), width: 1)),
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final i = entry.key;
            final isActive = _selectedTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = i);
                  _loadLeaderboard();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.neonCyan
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18)),
                  child: Center(
                    child: Text(entry.value,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppColors.darkBg
                                : AppColors.textSecondary,
                            letterSpacing: 1)),
                  ),
                ),
              ),
            );
          }).toList(),
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
          Text(tr('No rankings yet'),
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            tr('Solve some quizzes to climb the board!'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    if (_data.length < 3) {
      // Render whatever is available
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: _data
              .map((u) => _RankItem(data: _normalizeRow(u, _data.indexOf(u))))
              .toList(),
        ),
      );
    }
    final top3 = _data.take(3).toList();
    final podiumOrder = [top3[1], top3[0], top3[2]]; // 2nd, 1st, 3rd
    final heights = [90.0, 120.0, 70.0];
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
          height: 220,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final raw = podiumOrder[i];
              final user = _normalizeRow(raw, _data.indexOf(raw));
              final animOffset = _podiumAnim.value;
              return Expanded(
                child: Opacity(
                  opacity: animOffset,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(medals[i], style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Container(
                        width: i == 1 ? 58 : 48,
                        height: i == 1 ? 58 : 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[i].withValues(alpha: 0.15),
                          border: Border.all(
                              color: colors[i].withValues(alpha: 0.6), width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: colors[i].withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user['initial'],
                            style: GoogleFonts.orbitron(
                                fontSize: i == 1 ? 22 : 18,
                                fontWeight: FontWeight.w700,
                                color: colors[i]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(user['name'].toString().split(' ').first,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      Text('${user['xp']} XP',
                          style: GoogleFonts.orbitron(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors[i])),
                      const SizedBox(height: 6),
                      Transform.scale(
                        scaleY: _podiumAnim.value,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: heights[i],
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: colors[i].withValues(alpha: 0.12),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10)),
                            border: Border.all(
                                color: colors[i].withValues(alpha: 0.3), width: 1),
                          ),
                          child: Center(
                            child: Text(
                                i == 1
                                    ? '1st'
                                    : i == 0
                                        ? '2nd'
                                        : '3rd',
                                style: GoogleFonts.orbitron(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colors[i].withValues(alpha: 0.8))),
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

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> u, int index) {
    final name = (u['name'] ?? '').toString();
    final isMe = u['is_me'] == true;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return {
      'rank': u['rank'] ?? (index + 1),
      'name': name.isEmpty ? 'Anonymous' : name,
      'initial': initial,
      'xp': (u['total_xp'] as num?)?.toInt() ?? 0,
      'streak': (u['streak'] as num?)?.toInt() ?? 0,
      'isMe': isMe,
      'phone': (u['phone_masked'] ?? '').toString(),
    };
  }

  Widget _buildMyRankCard() {
    final me = _data.firstWhere(
      (u) => u['is_me'] == true,
      orElse: () => <String, dynamic>{},
    );
    final myXp = (_myXp ?? (me['total_xp'] as num?)?.toInt() ?? 0);
    final name = (me['name'] ?? 'You').toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.neonCyan.withValues(alpha: 0.12),
          AppColors.neonCyan.withValues(alpha: 0.05),
        ]),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.neonCyan,
                borderRadius: BorderRadius.circular(8)),
            child: Text(tr('YOU'),
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBg)),
          ),
          const SizedBox(width: 12),
          Text('#${_myRank ?? '—'}',
              style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? tr('You') : name,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text(tr('Total XP earned'),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            children: [
              Text('$myXp',
                  style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonCyan)),
              Text('XP',
                  style: GoogleFonts.poppins(
                      fontSize: 9, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankList() {
    final rest = _data.skip(3).toList();
    if (rest.isEmpty) return const SizedBox.shrink();
    return Column(
      children: rest.map((u) {
        final norm = _normalizeRow(u, _data.indexOf(u));
        return _RankItem(data: norm);
      }).toList(),
    );
  }
}

class _RankItem extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RankItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isMe = data['isMe'] == true;
    final rank = data['rank'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.neonCyan.withValues(alpha: 0.05)
            : AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AppColors.neonCyan.withValues(alpha: 0.3)
              : AppColors.textMuted.withValues(alpha: 0.1),
          width: isMe ? 1.3 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#$rank',
                style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppColors.neonCyan : AppColors.textSecondary)),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe
                  ? AppColors.neonCyan.withValues(alpha: 0.15)
                  : AppColors.darkSurface,
              border: Border.all(
                color: isMe
                    ? AppColors.neonCyan.withValues(alpha: 0.4)
                    : AppColors.textMuted.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(data['initial'],
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isMe
                          ? AppColors.neonCyan
                          : AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(data['name'],
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.neonCyan,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(tr('YOU'),
                            style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkBg)),
                      ),
                    ],
                  ],
                ),
                Text('${data['phone']}',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${data['xp']}',
                  style: GoogleFonts.orbitron(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isMe ? AppColors.neonCyan : Colors.white)),
              Text('XP',
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
