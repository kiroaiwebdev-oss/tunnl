// lib/features/tunnlity/tunnlity_leaderboard_screen.dart
//
// Leaderboard for the "Test Your Tunnlity" speed test. Best score per user,
// loaded from admin/api/tunnlity_leaderboard.php.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_strings.dart';
import '../../core/services/content_service.dart';

class TunnlityLeaderboardScreen extends StatefulWidget {
  const TunnlityLeaderboardScreen({super.key});

  @override
  State<TunnlityLeaderboardScreen> createState() =>
      _TunnlityLeaderboardScreenState();
}

class _TunnlityLeaderboardScreenState
    extends State<TunnlityLeaderboardScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _entries = [];
  int? _myRank;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ContentService.getTunnlityLeaderboard();
    if (!mounted) return;
    setState(() {
      _entries = (res['leaderboard'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      _myRank = (res['my_rank'] as num?)?.toInt();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashBg),
        child: SafeArea(
          child: Column(
            children: [
              _appBar(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonCyan))
                    : RefreshIndicator(
                        color: AppColors.neonCyan,
                        backgroundColor: AppColors.darkCard,
                        onRefresh: _load,
                        child: _entries.isEmpty
                            ? _emptyState()
                            : ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                    16, 8, 16, 24),
                                itemCount: _entries.length,
                                itemBuilder: (_, i) => _row(_entries[i]),
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
              Text(tr('TUNNLITY LEADERBOARD'),
                  style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonCyan,
                      letterSpacing: 2)),
              Text(
                  _myRank != null
                      ? '${tr('Your rank:')} #$_myRank'
                      : tr('Top speed-test scorers'),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.emoji_events_rounded,
            color: AppColors.textMuted, size: 56),
        const SizedBox(height: 16),
        Center(
          child: Text(tr('No scores yet'),
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(tr('Be the first — take the Tunnlity test!'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _row(Map<String, dynamic> e) {
    final rank = (e['rank'] as num?)?.toInt() ?? 0;
    final isMe = e['is_me'] == true;
    final medal = e['medal'] as String?;
    final name = '${e['name'] ?? 'Anonymous'}';
    final best = (e['best_score'] as num?)?.toInt() ?? 0;
    final acc = (e['best_accuracy'] as num?)?.toDouble() ?? 0.0;
    final attempts = (e['attempts'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.neonCyan.withValues(alpha: 0.1)
            : AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isMe
                ? AppColors.neonCyan.withValues(alpha: 0.5)
                : AppColors.textMuted.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 20))
                : Text('#$rank',
                    style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMe ? '$name (${tr('You')})' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text('$attempts ${attempts == 1 ? tr('attempt') : tr('attempts')} • '
                    '${acc.toStringAsFixed(0)}% ${tr('accuracy')}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$best',
                  style: GoogleFonts.orbitron(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonCyan)),
              Text(tr('pts'),
                  style: GoogleFonts.poppins(
                      fontSize: 9, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
