// lib/features/previous_year/previous_year_screen.dart
//
// Loads exams + their year-wise records from admin/previous_year.php and lets
// the user pick one. Tapping an exam opens SetsScreen with category=previous_year
// and the real exam_id, so sets.php returns the right list.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/content_service.dart';
import '../premium/premium_screen.dart';
import '../sets/sets_screen.dart';

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
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'SSC', 'Railway', 'Bank'];

  /// API: { ExamName: [ {id, exam_year, set_count, total_questions, is_premium, can_access, ...} ] }
  Map<String, List<Map<String, dynamic>>> _exams = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _loadExams();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    final exams = await ContentService.getPreviousYearExams();
    if (!mounted) return;
    setState(() {
      _exams = exams;
      _isLoading = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> get _filteredExams {
    if (_selectedFilter == 'All') return _exams;
    final keyFilter = _selectedFilter.toLowerCase();
    final filtered = <String, List<Map<String, dynamic>>>{};
    _exams.forEach((examName, list) {
      final n = examName.toLowerCase();
      final match = (keyFilter == 'ssc' && n.contains('ssc')) ||
          (keyFilter == 'railway' && (n.contains('railway') || n.contains('rrb'))) ||
          (keyFilter == 'bank' && (n.contains('bank') || n.contains('ibps') || n.contains('sbi')));
      if (match) filtered[examName] = list;
    });
    return filtered;
  }

  IconData _examIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('ssc')) return Icons.workspace_premium_rounded;
    if (n.contains('railway') || n.contains('rrb')) return Icons.train_rounded;
    if (n.contains('bank') || n.contains('ibps')) return Icons.account_balance_rounded;
    if (n.contains('upsc')) return Icons.gavel_rounded;
    return Icons.school_rounded;
  }

  IconData _resolveIcon(String? iconName, String examName) {
    switch ((iconName ?? '').toLowerCase()) {
      case 'school':            return Icons.school_rounded;
      case 'train':             return Icons.train_rounded;
      case 'account_balance':   return Icons.account_balance_rounded;
      case 'security':          return Icons.security_rounded;
      case 'flight':            return Icons.flight_rounded;
      case 'gavel':             return Icons.gavel_rounded;
      case 'medical_services':  return Icons.medical_services_rounded;
      case 'engineering':       return Icons.engineering_rounded;
      case 'science':           return Icons.science_rounded;
      case 'workspace_premium': return Icons.workspace_premium_rounded;
    }
    return _examIcon(examName);
  }

  Color _examColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('ssc')) return AppColors.yellow;
    if (n.contains('railway') || n.contains('rrb')) return const Color(0xFF00E676);
    if (n.contains('bank') || n.contains('ibps')) return const Color(0xFFE040FB);
    if (n.contains('upsc')) return AppColors.orange;
    return AppColors.neonCyan;
  }

  Color _diffColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return const Color(0xFFFFB300);
      case 'hard':
      default:
        return const Color(0xFFFF4757);
    }
  }

  void _openExam(Map<String, dynamic> exam) async {
    final canAccess = exam['can_access'] == true;
    if (!canAccess) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      if (mounted) _loadExams();
      return;
    }
    final examId = (exam['id'] as num?)?.toInt() ?? 0;
    final name = '${exam['exam_name']} ${exam['exam_year'] ?? ''}'.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SetsScreen(
          title: name,
          category: 'previous_year',
          examId: examId,
          questionsPerSet: 100,
          totalSets: (exam['set_count'] as num?)?.toInt() ?? 10,
          showLeaderboard: true,
        ),
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
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildFilters(),
                  if (!widget.isPremium) _buildFreeBanner(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.yellow, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PREVIOUS YEAR',
                  style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.yellow,
                      letterSpacing: 2)),
              Text('Select exam to start practising',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final isActive = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.yellow : AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isActive
                        ? AppColors.yellow
                        : AppColors.textMuted.withValues(alpha: 0.2),
                    width: 1),
              ),
              child: Text(f.toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.darkBg
                          : AppColors.textSecondary)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFreeBanner() {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
        if (mounted) _loadExams();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.3), width: 1)),
        child: Row(
          children: [
            const Icon(Icons.lock_open_rounded,
                color: AppColors.orange, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Free exams open. Premium ones need ₹50 upgrade.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(16)),
              child: Text('₹50',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.yellow));
    }
    final filtered = _filteredExams;
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_edu_rounded,
                  color: AppColors.textMuted, size: 56),
              const SizedBox(height: 16),
              Text('No exams yet',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Text('Admin will publish previous-year papers soon.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.darkBg),
                label: Text('Retry',
                    style: GoogleFonts.poppins(
                        color: AppColors.darkBg,
                        fontWeight: FontWeight.w700)),
                onPressed: _loadExams,
              ),
            ],
          ),
        ),
      );
    }

    final entries = filtered.entries.toList();
    return RefreshIndicator(
      color: AppColors.yellow,
      backgroundColor: AppColors.darkCard,
      onRefresh: _loadExams,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: entries.length,
        itemBuilder: (_, i) {
          final examName = entries[i].key;
          final years = entries[i].value;
          final color = _examColor(examName);
          // Prefer the admin-configured icon from the first year's entry,
          // fall back to name-based heuristic if the admin hasn't set one.
          final firstWithIcon = years.firstWhere(
            (e) => (e['icon'] ?? '').toString().isNotEmpty,
            orElse: () => years.isNotEmpty ? years.first : <String, dynamic>{},
          );
          final icon = _resolveIcon(
            firstWithIcon['icon']?.toString(),
            examName,
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(examName,
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text('${years.length} year${years.length == 1 ? '' : 's'} available',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: years.map((y) {
                    final yearLabel = '${y['exam_year'] ?? ''}';
                    final canAccess = y['can_access'] == true;
                    final difficulty = (y['difficulty'] ?? 'medium').toString();
                    return GestureDetector(
                      onTap: () => _openExam(y),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: canAccess
                              ? color.withValues(alpha: 0.08)
                              : AppColors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: canAccess
                                ? color.withValues(alpha: 0.3)
                                : AppColors.orange.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(yearLabel,
                                style: GoogleFonts.orbitron(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: canAccess
                                        ? Colors.white
                                        : AppColors.orange)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: _diffColor(difficulty).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(difficulty.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: _diffColor(difficulty))),
                            ),
                            const SizedBox(width: 4),
                            if (!canAccess)
                              const Icon(Icons.lock_rounded,
                                  size: 11, color: AppColors.orange),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
