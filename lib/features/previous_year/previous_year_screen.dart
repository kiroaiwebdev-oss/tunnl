// lib/features/previous_year/previous_year_screen.dart
//
// Loads exams + their year-wise records from admin/previous_year.php and lets
// the user pick one. Tapping an exam opens SetsScreen with category=previous_year
// and the real exam_id, so sets.php returns the right list.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/app_strings.dart';
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

  /// Filter chips are built dynamically from the exam categories that actually
  /// exist (so every exam shown below is reachable from a top chip).
  List<String> get _filters {
    final cats = <String>{};
    _exams.forEach((_, list) {
      final c = list.isNotEmpty
          ? (list.first['exam_category'] ?? '').toString().trim()
          : '';
      if (c.isNotEmpty) cats.add(_prettyCat(c));
    });
    final sorted = cats.toList()..sort();
    return ['All', ...sorted];
  }

  String _prettyCat(String c) {
    switch (c.toUpperCase()) {
      case 'SSC':
        return 'SSC';
      case 'RAILWAY':
        return 'Railway';
      case 'BANK':
        return 'Bank';
      case 'DEFENCE':
        return 'Defence';
      default:
        return 'Other';
    }
  }

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
    final filtered = <String, List<Map<String, dynamic>>>{};
    _exams.forEach((examName, list) {
      final n = examName.toLowerCase();
      final cat = list.isNotEmpty
          ? _prettyCat((list.first['exam_category'] ?? '').toString())
          : '';
      bool match = cat == _selectedFilter;
      // Fall back to name heuristics when the admin left the category blank.
      if (!match) {
        switch (_selectedFilter) {
          case 'SSC':
            match = n.contains('ssc');
            break;
          case 'Railway':
            match = n.contains('railway') || n.contains('rrb');
            break;
          case 'Bank':
            match = n.contains('bank') || n.contains('ibps') || n.contains('sbi');
            break;
          case 'Defence':
            match = n.contains('cds') || n.contains('nda') || n.contains('defence') || n.contains('airforce');
            break;
        }
      }
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
          questionsPerSet: 10,
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
              Text(tr('PREVIOUS YEAR'),
                  style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.yellow,
                      letterSpacing: 2)),
              Text(tr('Select exam to start practising'),
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
                '${tr('Free exams open. Premium ones need')} ₹${AppSettingsService.instance.getInt('premium_price', 50)} ${tr('upgrade.')}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(16)),
              child: Text('₹${AppSettingsService.instance.getInt('premium_price', 50)}',
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
              Text(tr('No exams yet'),
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Text(tr('Admin will publish previous-year papers soon.'),
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
                label: Text(tr('Retry'),
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

    // Flatten every exam paper into its own card → tapping opens its sets
    // directly (no intermediate year picker / bottom sheet).
    final flat = <Map<String, dynamic>>[];
    for (final list in filtered.values) {
      flat.addAll(list);
    }
    return RefreshIndicator(
      color: AppColors.yellow,
      backgroundColor: AppColors.darkCard,
      onRefresh: _loadExams,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        itemCount: flat.length,
        itemBuilder: (_, i) {
          final exam = flat[i];
          final name = (exam['exam_name'] ?? '').toString();
          final year = (exam['exam_year'] as num?)?.toInt() ?? 0;
          final color = _examColor(name);
          final icon = _resolveIcon(exam['icon']?.toString(), name);
          final locked = exam['can_access'] != true;
          final setCount = (exam['set_count'] as num?)?.toInt() ?? 0;
          return _ExamSquare(
            name: year > 0 ? '$name $year' : name,
            icon: icon,
            iconUrl: (exam['icon_url'] ?? '').toString(),
            color: color,
            subtitle: '$setCount ${setCount == 1 ? tr('set') : tr('sets')}',
            locked: locked,
            onTap: () => _openExam(exam),
          );
        },
      ),
    );
  }
}

// Square exam tile — 3 per line.
class _ExamSquare extends StatelessWidget {
  final String name;
  final IconData icon;
  final String iconUrl;
  final Color color;
  final String subtitle;
  final bool locked;
  final VoidCallback onTap;

  const _ExamSquare({
    required this.name,
    required this.icon,
    this.iconUrl = '',
    required this.color,
    required this.subtitle,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: iconUrl.isNotEmpty
                      ? Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(icon, color: color, size: 24),
                          loadingBuilder: (c, child, progress) =>
                              progress == null
                                  ? child
                                  : Icon(icon, color: color, size: 24),
                        )
                      : Icon(icon, color: color, size: 24),
                ),
                if (locked)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded,
                          size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
