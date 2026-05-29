import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../premium/premium_screen.dart';
import '../question/question_screen.dart';

class PYSetsScreen extends StatefulWidget {
  final String examName;
  final String examId;
  final bool   isPremium;

  const PYSetsScreen({
    super.key,
    required this.examName,
    required this.examId,
    this.isPremium = false,
  });

  @override
  State<PYSetsScreen> createState() => _PYSetsScreenState();
}

class _PYSetsScreenState extends State<PYSetsScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double>   _fadeAnim;

  final List<Map<String, dynamic>> _levels = [
    {
      'level':         '01',
      'title':         'Beginner Level',
      'totalSets':     10,
      'completedSets': 2,
      'sets': List.generate(10, (i) => {
        'setNum':   i + 1,
        'label':    'SET ${(i + 1).toString().padLeft(2, '0')}',
        'status':   i < 2 ? 'completed' : i == 2 ? 'playing' : 'available',
        'progress': i < 2 ? 1.0 : i == 2 ? 0.4 : 0.0,
        'totalQ':   20,
        'doneQ':    i < 2 ? 20 : i == 2 ? 8 : 0,
      }),
    },
    {
      'level':         '02',
      'title':         'Intermediate',
      'totalSets':     10,
      'completedSets': 0,
      'sets': List.generate(10, (i) => {
        'setNum':   i + 11,
        'label':    'SET ${(i + 11).toString().padLeft(2, '0')}',
        'status':   'available',
        'progress': 0.0,
        'totalQ':   20,
        'doneQ':    0,
      }),
    },
    {
      'level':         '03',
      'title':         'Advanced',
      'totalSets':     10,
      'completedSets': 0,
      'sets': List.generate(10, (i) => {
        'setNum':   i + 21,
        'label':    'SET ${(i + 21).toString().padLeft(2, '0')}',
        'status':   'available',
        'progress': 0.0,
        'totalQ':   20,
        'doneQ':    0,
      }),
    },
  ];

  // ── Har exam ka apna 10% dynamically ─────────────
  int get _totalSets => _levels.fold<int>(
    0, (sum, level) => sum + (level['totalSets'] as int),
  );

  int get _freeSets =>
      (_totalSets * 0.1).ceil().clamp(1, _totalSets);

  // Free user = sirf pehle _freeSets sets open
  // Premium = sab open
  bool _isSetLocked(int setNum) {
    if (widget.isPremium) return false;
    return setNum > _freeSets;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildHeader(),
                        const SizedBox(height: 12),

                        // Free user banner
                        if (!widget.isPremium) _buildFreeBanner(),

                        const SizedBox(height: 12),

                        ..._levels.map((level) => _buildLevelSection(level)),

                        _buildAdvancedBanner(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
                widget.examName.toUpperCase(),
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.yellow,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Previous Year Papers',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.yellow.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.isPremium
                  ? '$_totalSets Sets'
                  : '$_freeSets/$_totalSets Free',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: widget.isPremium
                    ? AppColors.yellow
                    : AppColors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.neonCyan,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.examName} Practice Sets',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Complete previous levels to unlock advanced logic.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── FREE BANNER ───────────────────────────────────
  Widget _buildFreeBanner() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_open_rounded,
              color: AppColors.orange,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: '$_freeSets sets free ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(text: '— Upgrade for all '),
                    TextSpan(
                      text: '$_totalSets sets',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '₹50',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LEVEL SECTION ─────────────────────────────────
  Widget _buildLevelSection(Map<String, dynamic> level) {
    final List<Map<String, dynamic>> sets =
        List<Map<String, dynamic>>.from(level['sets']);
    final int completedSets = level['completedSets'];
    final int totalSets     = level['totalSets'];

    // Free user ke liye level 02, 03 — premium only
    final bool levelPremiumLocked =
        !widget.isPremium && level['level'] != '01';

    return Column(
      children: [
        // Level header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: levelPremiumLocked
                      ? AppColors.textMuted.withOpacity(0.3)
                      : AppColors.neonCyan.withOpacity(0.6),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'LEVEL ${level['level']}',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: levelPremiumLocked
                      ? AppColors.textMuted
                      : AppColors.neonCyan,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              level['title'],
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: levelPremiumLocked
                    ? AppColors.textMuted.withOpacity(0.5)
                    : Colors.white,
              ),
            ),
            const Spacer(),
            if (!levelPremiumLocked)
              Text(
                '$completedSets / $totalSets COMPLETED',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.neonCyan,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PremiumScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.orange,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 14),

        // Sets Grid — 3 per row
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   3,
            crossAxisSpacing: 10,
            mainAxisSpacing:  10,
            childAspectRatio: 0.85,
          ),
          itemCount: sets.length,
          itemBuilder: (_, index) {
            final set    = sets[index];
            final setNum = set['setNum'] as int;

            // Set lock — level locked ya 10% exceeded
            final bool setLocked =
                levelPremiumLocked || _isSetLocked(setNum);

            return _buildSetCard(set, setLocked);
          },
        ),

        const SizedBox(height: 28),
      ],
    );
  }

  // ── SET CARD ──────────────────────────────────────
  Widget _buildSetCard(Map<String, dynamic> set, bool locked) {
    final String status   = locked ? 'locked' : set['status'];
    final double progress = locked ? 0.0 : set['progress'];

    Color  borderColor;
    Color  textColor;
    Widget iconWidget;

    switch (status) {
      case 'completed':
        borderColor = AppColors.success.withOpacity(0.5);
        textColor   = AppColors.success;
        iconWidget  = const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 28,
        );
        break;
      case 'playing':
        borderColor = AppColors.neonCyan.withOpacity(0.6);
        textColor   = AppColors.neonCyan;
        iconWidget  = const Icon(
          Icons.play_circle_rounded,
          color: AppColors.neonCyan,
          size: 28,
        );
        break;
      case 'locked':
        borderColor = AppColors.textMuted.withOpacity(0.15);
        textColor   = AppColors.textMuted;
        iconWidget  = const Icon(
          Icons.lock_rounded,
          color: AppColors.textMuted,
          size: 24,
        );
        break;
      default: // available
        borderColor = AppColors.neonCyan.withOpacity(0.2);
        textColor   = AppColors.textSecondary;
        iconWidget  = const Icon(
          Icons.calculate_rounded,
          color: AppColors.textSecondary,
          size: 26,
        );
    }

    return GestureDetector(
      onTap: () {
        if (locked) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PremiumScreen()),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuestionScreen(
                mode:           'previous_year',
                category: 'previous_year',
                setNumber:      set['setNum'],
                totalQuestions: set['totalQ'],
              ),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: status == 'playing'
              ? AppColors.neonCyan.withOpacity(0.05)
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 8),
            Text(
              set['label'],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.textMuted.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    status == 'completed'
                        ? AppColors.success
                        : status == 'playing'
                            ? AppColors.neonCyan
                            : Colors.transparent,
                  ),
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADVANCED PROMO BANNER ─────────────────────────
  Widget _buildAdvancedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.neonCyan.withOpacity(0.08),
            AppColors.darkCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.neonCyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.neonCyan.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              'LEVEL 04+',
              style: GoogleFonts.orbitron(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.neonCyan,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'ADVANCED MULTIVARIABLE\nLOGIC',
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'The mathematical void expands.\nCalibrating high-dimensional challenge nodes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _PromoChip(
                icon:  Icons.rocket_launch_rounded,
                label: 'Coming Soon',
                color: AppColors.neonCyan,
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PremiumScreen()),
                ),
                child: const _PromoChip(
                  icon:  Icons.workspace_premium_rounded,
                  label: 'Unlock All Levels',
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// PROMO CHIP WIDGET
// ─────────────────────────────────────────────────────
class _PromoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;

  const _PromoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}