import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

class DailyDosePopup {
  /// Yeh function call karo kisi bhi screen se
  /// Automatically check karega — aaj dikhaya ya nahi
  static Future<void> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey =
        'daily_dose_${today.year}_${today.month}_${today.day}';
    final alreadyShown = prefs.getBool(todayKey) ?? false;

    if (alreadyShown) return; // Aaj already dikhaya

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => _DailyDoseSheet(
        onDismiss: () async {
          await prefs.setBool(todayKey, true); // Mark as shown
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// DAILY DOSE BOTTOM SHEET
// ─────────────────────────────────────────────────────
class _DailyDoseSheet extends StatefulWidget {
  final VoidCallback onDismiss;

  const _DailyDoseSheet({required this.onDismiss});

  @override
  State<_DailyDoseSheet> createState() => _DailyDoseSheetState();
}

class _DailyDoseSheetState extends State<_DailyDoseSheet>
    with TickerProviderStateMixin {

  // Today's dummy question — API se replace hoga
  final Map<String, dynamic> _todayQuestion = {
    'date': 'TODAY\'S DOSE',
    'question': '(17² - 13²) ÷ 4 = ?',
    'options': ['30', '25', '15', '20'],
    'correct': 0,
    'explanation':
        '17² = 289, 13² = 169\n289 - 169 = 120\n120 ÷ 4 = 30 ✓',
  };

  int? _selectedOption;
  bool _isAnswered = false;
  bool _showExplanation = false;

  late AnimationController _entryCtrl;
  late Animation<double> _scaleAnim;

  late AnimationController _optionCtrl;
  late List<Animation<double>> _optionFadeAnims;

  late AnimationController _explanationCtrl;
  late Animation<double> _explanationFadeAnim;

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

    _optionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _optionFadeAnims = List.generate(4, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _optionCtrl,
          curve: Interval(i * 0.12, 0.6 + i * 0.12,
              curve: Curves.easeOut),
        ),
      );
    });

    _explanationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _explanationFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _explanationCtrl, curve: Curves.easeOut),
    );

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _optionCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _optionCtrl.dispose();
    _explanationCtrl.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    if (_isAnswered) return;
    setState(() {
      _selectedOption = index;
      _isAnswered = true;
    });

    // Show explanation after 600ms
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _showExplanation = true);
        _explanationCtrl.forward();
      }
    });
  }

  void _close() {
    widget.onDismiss();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final q = _todayQuestion;
    final options = List<String>.from(q['options']);
    final correctIndex = q['correct'] as int;
    final labels = ['A', 'B', 'C', 'D'];

    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1923),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.neonCyan.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withOpacity(0.08),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle
            _buildDragHandle(),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header
                  _buildHeader(),

                  const SizedBox(height: 16),

                  // ── Question box
                  _buildQuestionBox(q),

                  const SizedBox(height: 16),

                  // ── Options
                  ...List.generate(4, (i) {
                    return FadeTransition(
                      opacity: _optionFadeAnims[i],
                      child: _buildOptionTile(
                        index: i,
                        label: labels[i],
                        text: options[i],
                        correctIndex: correctIndex,
                      ),
                    );
                  }),

                  // ── Explanation
                  if (_showExplanation) ...[
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _explanationFadeAnim,
                      child: _buildExplanation(q),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Bottom Buttons
                  _buildBottomButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DRAG HANDLE ───────────────────────────────────
  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textMuted.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────
  Widget _buildHeader() {
    final now = DateTime.now();
    final months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    final dateStr =
        '${now.day} ${months[now.month - 1]} ${now.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left — title + date
        Row(
          children: [
            // Sun icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow.withOpacity(0.12),
                border: Border.all(
                  color: AppColors.yellow.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.wb_sunny_rounded,
                color: AppColors.yellow,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAILY DOSE',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neonCyan,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Close button
        GestureDetector(
          onTap: _close,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // ── QUESTION BOX ──────────────────────────────────
  Widget _buildQuestionBox(Map<String, dynamic> q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonCyan.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Question number chip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.neonCyan.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              "QUESTION OF THE DAY",
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.neonCyan,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            q['question'],
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── OPTION TILE ───────────────────────────────────
  Widget _buildOptionTile({
    required int index,
    required String label,
    required String text,
    required int correctIndex,
  }) {
    Color borderColor = AppColors.darkCard;
    Color bgColor = AppColors.darkCard;
    Color labelBg = const Color(0xFF1E2A3A);
    Color labelColor = AppColors.textSecondary;
    Widget? trailingIcon;

    if (_isAnswered) {
      if (index == correctIndex) {
        borderColor = AppColors.success;
        bgColor = AppColors.success.withOpacity(0.07);
        labelBg = AppColors.success;
        labelColor = Colors.white;
        trailingIcon = const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 20,
        );
      } else if (index == _selectedOption && index != correctIndex) {
        borderColor = AppColors.error;
        bgColor = AppColors.error.withOpacity(0.07);
        labelBg = AppColors.error;
        labelColor = Colors.white;
        trailingIcon = const Icon(
          Icons.cancel_rounded,
          color: AppColors.error,
          size: 20,
        );
      }
    } else if (index == _selectedOption) {
      borderColor = AppColors.neonCyan;
      bgColor = AppColors.neonCyan.withOpacity(0.07);
      labelBg = AppColors.neonCyan;
      labelColor = AppColors.darkBg;
    }

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor.withOpacity(
              _isAnswered || index == _selectedOption ? 0.7 : 0.15,
            ),
            width: 1.3,
          ),
        ),
        child: Row(
          children: [
            // Label
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }

  // ── EXPLANATION ───────────────────────────────────
  Widget _buildExplanation(Map<String, dynamic> q) {
    final isCorrect = _selectedOption == q['correct'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.success.withOpacity(0.07)
            : AppColors.error.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isCorrect ? 'Correct! 🎉' : 'Wrong! Correct Answer:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isCorrect
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q['explanation'],
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM BUTTONS ────────────────────────────────
  Widget _buildBottomButtons() {
    return Row(
      children: [
        // Share button
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Share functionality — baad mein
              Navigator.of(context).pop();
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.textMuted.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.share_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SHARE',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Done button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _close,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00ACC1)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _isAnswered ? 'DONE ✓' : 'SKIP TODAY',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBg,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}