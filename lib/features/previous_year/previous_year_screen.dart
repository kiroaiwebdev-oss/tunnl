import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../premium/premium_screen.dart';
import 'py_sets_screen.dart';

class PreviousYearScreen extends StatefulWidget {
  final bool isPremium;

  const PreviousYearScreen({
    super.key,
    this.isPremium = false,
  });

  @override
  State<PreviousYearScreen> createState() => _PreviousYearScreenState();
}

class _PreviousYearScreenState extends State<PreviousYearScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'SSC', 'Railway', 'Bank'];

  final List<Map<String, dynamic>> _exams = [
    {
      'id':         'ssc_cgl',
      'name':       'SSC CGL',
      'fullName':   'Combined Graduate Level',
      'sets':       30,
      'years':      '2018–2024',
      'icon':       Icons.workspace_premium_rounded,
      'color':      const Color(0xFFFFD600),
      'difficulty': 'Hard',
      'diffColor':  const Color(0xFFFF4757),
    },
    {
      'id':         'ssc_chsl',
      'name':       'SSC CHSL',
      'fullName':   'Combined Higher Secondary Level',
      'sets':       25,
      'years':      '2018–2024',
      'icon':       Icons.school_rounded,
      'color':      AppColors.neonCyan,
      'difficulty': 'Medium',
      'diffColor':  const Color(0xFFFFB300),
    },
    {
      'id':         'ssc_mts',
      'name':       'SSC MTS',
      'fullName':   'Multi Tasking Staff',
      'sets':       20,
      'years':      '2019–2024',
      'icon':       Icons.assignment_rounded,
      'color':      const Color(0xFF7C4DFF),
      'difficulty': 'Easy',
      'diffColor':  AppColors.success,
    },
    {
      'id':         'ssc_gd',
      'name':       'SSC GD',
      'fullName':   'General Duty Constable',
      'sets':       20,
      'years':      '2019–2024',
      'icon':       Icons.shield_rounded,
      'color':      const Color(0xFFFF6B35),
      'difficulty': 'Medium',
      'diffColor':  const Color(0xFFFFB300),
    },
    {
      'id':         'railway_ntpc',
      'name':       'Railway NTPC',
      'fullName':   'Non Technical Popular Categories',
      'sets':       25,
      'years':      '2019–2024',
      'icon':       Icons.train_rounded,
      'color':      const Color(0xFF00E676),
      'difficulty': 'Medium',
      'diffColor':  const Color(0xFFFFB300),
    },
    {
      'id':         'railway_group_d',
      'name':       'Railway Group D',
      'fullName':   'Level 1 Posts',
      'sets':       20,
      'years':      '2019–2024',
      'icon':       Icons.directions_railway_rounded,
      'color':      const Color(0xFF40C4FF),
      'difficulty': 'Easy',
      'diffColor':  AppColors.success,
    },
    {
      'id':         'bank_po',
      'name':       'Bank PO',
      'fullName':   'Probationary Officer (IBPS/SBI)',
      'sets':       20,
      'years':      '2020–2024',
      'icon':       Icons.account_balance_rounded,
      'color':      const Color(0xFFE040FB),
      'difficulty': 'Hard',
      'diffColor':  const Color(0xFFFF4757),
    },
    {
      'id':         'bank_clerk',
      'name':       'Bank Clerk',
      'fullName':   'IBPS/SBI Clerk',
      'sets':       15,
      'years':      '2020–2024',
      'icon':       Icons.account_balance_wallet_rounded,
      'color':      const Color(0xFFFF80AB),
      'difficulty': 'Medium',
      'diffColor':  const Color(0xFFFFB300),
    },
  ];

  // ✅ Koi lock nahi — sab exams open
  // 10% limit andar PYSetsScreen mein lagegi
  List<Map<String, dynamic>> get _filteredExams {
    if (_selectedFilter == 'All') return _exams;
    return _exams.where((e) {
      final name   = (e['name'] as String).toLowerCase();
      final filter = _selectedFilter.toLowerCase();
      if (filter == 'ssc')     return name.contains('ssc');
      if (filter == 'railway') return name.contains('railway');
      if (filter == 'bank')    return name.contains('bank');
      return true;
    }).toList();
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
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildFilters(),

                  // Free user banner
                  if (!widget.isPremium) _buildFreeBanner(),

                  Expanded(child: _buildExamList()),
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
                'PREVIOUS YEAR',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.yellow,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Select exam to start practising',
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
              // ✅ Sirf total exams — no lock count
              widget.isPremium
                  ? '${_exams.length} Exams'
                  : '10% Free',
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

  // ── FREE BANNER ───────────────────────────────────
  Widget _buildFreeBanner() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                      text: 'Each exam — 10% sets free ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: '— Upgrade for full access',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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

  // ── FILTER CHIPS ──────────────────────────────────
  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (_, index) {
          final filter     = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.yellow.withOpacity(0.15)
                    : AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.yellow.withOpacity(0.6)
                      : AppColors.textMuted.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                filter,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.yellow
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── EXAM LIST ─────────────────────────────────────
  Widget _buildExamList() {
    final filtered = _filteredExams;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      itemCount: filtered.length,
      itemBuilder: (_, index) {
        // ✅ Koi locked parameter nahi — seedha card
        return _buildExamCard(filtered[index]);
      },
    );
  }

  // ── EXAM CARD ─────────────────────────────────────
  // ✅ locked parameter completely remove
  Widget _buildExamCard(Map<String, dynamic> exam) {
    final Color color = exam['color'] as Color;

    return GestureDetector(
      onTap: () {
        // ✅ Seedha PYSetsScreen — koi lock check nahi
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PYSetsScreen(
              examName:  exam['name'],
              examId:    exam['id'],
              isPremium: widget.isPremium,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                exam['icon'] as IconData,
                color: color,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        exam['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (exam['diffColor'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (exam['diffColor'] as Color).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          exam['difficulty'],
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: exam['diffColor'] as Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exam['fullName'],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.layers_rounded,
                          size: 12, color: color.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${exam['sets']} Sets',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        exam['years'],
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      // ✅ Free badge — free users ko
                      if (!widget.isPremium) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '10% Free',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}