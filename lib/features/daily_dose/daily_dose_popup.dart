// lib/features/daily_dose/daily_dose_popup.dart
//
// Pulls today's "daily dose" content from admin/daily_dose.php and shows it once
// per day as a bottom sheet.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/content_service.dart';
import '../../core/services/app_strings.dart';
import '../../core/models/daily_dose_model.dart';

class DailyDosePopup {
  /// Call once on dashboard. Will only show if it hasn't been shown today.
  static Future<void> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey =
        'daily_dose_${today.year}_${today.month}_${today.day}';
    final alreadyShown = prefs.getBool(todayKey) ?? false;
    if (alreadyShown) return;

    DailyDoseModel? dose;
    try {
      dose = await ContentService.getDailyDose();
    } catch (_) {}

    if (!context.mounted || dose == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => _DailyDoseSheet(
        dose: dose!,
        onDismiss: () async {
          await prefs.setBool(todayKey, true);
        },
      ),
    );
  }
}

class _DailyDoseSheet extends StatefulWidget {
  final DailyDoseModel dose;
  final VoidCallback onDismiss;

  const _DailyDoseSheet({required this.dose, required this.onDismiss});

  @override
  State<_DailyDoseSheet> createState() => _DailyDoseSheetState();
}

class _DailyDoseSheetState extends State<_DailyDoseSheet>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _close() {
    widget.onDismiss();
    Navigator.of(context).pop();
  }

  Future<void> _openVideo() async {
    final uri = Uri.parse(widget.dose.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dose;
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1923),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.neonCyan.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withValues(alpha: 0.08),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(d),
                    const SizedBox(height: 16),
                    _buildContentCard(d),
                    if (d.example.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildExample(d),
                    ],
                    if (d.tip.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildTip(d),
                    ],
                    if (d.hasVideo && d.videoUrl.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildVideoButton(),
                    ],
                    const SizedBox(height: 16),
                    _buildBottomButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }

  Widget _buildHeader(DailyDoseModel d) {
    final months = [
      'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'
    ];
    String dateStr;
    try {
      final now = DateTime.parse(d.doseDate);
      dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
    } catch (_) {
      final now = DateTime.now();
      dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow.withValues(alpha: 0.12),
                border: Border.all(
                    color: AppColors.yellow.withValues(alpha: 0.3), width: 1),
              ),
              child: const Icon(Icons.wb_sunny_rounded,
                  color: AppColors.yellow, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('DAILY DOSE'),
                    style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neonCyan,
                        letterSpacing: 2)),
                Text(dateStr,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: _close,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close_rounded,
                color: AppColors.textSecondary, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(DailyDoseModel d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.1), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.type.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.neonCyan.withValues(alpha: 0.2), width: 1)),
              child: Text(d.type.toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neonCyan,
                      letterSpacing: 1.5)),
            ),
          if (d.title.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(d.title,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
          if (d.content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(d.content,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildExample(DailyDoseModel d) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 16),
            const SizedBox(width: 6),
            Text(tr('Example'),
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success)),
          ]),
          const SizedBox(height: 8),
          Text(d.example,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTip(DailyDoseModel d) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.yellow.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lightbulb_rounded,
                color: AppColors.yellow, size: 16),
            const SizedBox(width: 6),
            Text(tr('Pro Tip'),
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.yellow)),
          ]),
          const SizedBox(height: 8),
          Text(d.tip,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildVideoButton() {
    return GestureDetector(
      onTap: _openVideo,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
            color: const Color(0xFFFF0000).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFFFF0000).withValues(alpha: 0.3), width: 1)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_rounded,
                color: Color(0xFFFF0000), size: 20),
            const SizedBox(width: 8),
            Text(tr('WATCH VIDEO'),
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF0000),
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return GestureDetector(
      onTap: _close,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF00ACC1)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: AppColors.neonCyan.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Center(
          child: Text(tr('GOT IT ✓'),
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBg,
                  letterSpacing: 1.5)),
        ),
      ),
    );
  }
}
