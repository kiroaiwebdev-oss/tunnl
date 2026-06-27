// lib/core/widgets/score_dialog.dart
//
// Shared "View Score" dialog. Reads the user's latest saved score for a set
// (persisted by ResultScreen in SharedPreferences under `set_score_<id>`) and
// shows it. Used by the set-list "View Score" option so a user can re-check
// their last score without reattempting.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/app_strings.dart';

Future<void> showSetScoreDialog(
  BuildContext context, {
  required int setId,
  required String title,
}) async {
  Map<String, dynamic>? data;
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('set_score_$setId');
    if (raw != null) data = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {}

  if (!context.mounted) return;

  final hasScore = data != null;
  final score = (data?['score'] as num?)?.toDouble() ?? 0;
  final accuracy = (data?['accuracy'] as num?)?.toDouble() ?? 0;
  final correct = (data?['correct'] as num?)?.toInt() ?? 0;
  final wrong = (data?['wrong'] as num?)?.toInt() ?? 0;
  final skipped = (data?['skipped'] as num?)?.toInt() ?? 0;
  final total = (data?['total'] as num?)?.toInt() ?? 0;

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.4)),
      ),
      title: Row(
        children: [
          const Icon(Icons.bar_chart_rounded,
              color: AppColors.neonCyan, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tr('Your Score'),
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
        ],
      ),
      content: hasScore
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty) ...[
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat(tr('SCORE'), '${score.toStringAsFixed(1)}/10',
                        AppColors.neonCyan),
                    _stat(tr('ACCURACY'), '${accuracy.toStringAsFixed(0)}%',
                        AppColors.yellow),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat(tr('Correct'), '$correct', AppColors.success),
                    _stat(tr('Wrong'), '$wrong', AppColors.error),
                    _stat(tr('Skipped'), '$skipped', AppColors.textMuted),
                  ],
                ),
                if (total > 0) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: Text('$correct / $total ${tr('correct')}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ],
              ],
            )
          : Text(tr('No score yet. Attempt this set to see your score.'),
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(tr('OK'),
              style: GoogleFonts.poppins(
                  color: AppColors.neonCyan, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

Widget _stat(String label, String value, Color color) {
  return Column(
    children: [
      Text(value,
          style: GoogleFonts.orbitron(
              fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1)),
    ],
  );
}
