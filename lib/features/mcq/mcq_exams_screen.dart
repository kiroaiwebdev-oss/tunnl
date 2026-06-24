// lib/features/mcq/mcq_exams_screen.dart
//
// Exam-wise entry for the "5000 Speed Math MCQs". Loads exams created by the
// admin (admin/api/mcq_exams.php) and shows them in a 3-per-line square grid.
// Tapping an exam opens SetsScreen filtered by that exam's name.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/content_service.dart';
import '../../core/services/app_strings.dart';
import '../premium/premium_screen.dart';
import '../sets/sets_screen.dart';

class McqExamsScreen extends StatefulWidget {
  final bool isPremium;
  const McqExamsScreen({super.key, this.isPremium = false});

  @override
  State<McqExamsScreen> createState() => _McqExamsScreenState();
}

class _McqExamsScreenState extends State<McqExamsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  List<Map<String, dynamic>> _exams = [];
  bool _isLoading = true;

  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _loadExams();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    final exams = await ContentService.getMcqExams();
    if (!mounted) return;
    setState(() {
      _exams = exams;
      _isLoading = false;
    });
  }

  // Dynamic filter chips built from the exam categories actually present.
  List<String> get _filters {
    final cats = <String>{};
    for (final e in _exams) {
      final c = (e['exam_category'] ?? '').toString().trim();
      if (c.isNotEmpty) cats.add(_prettyCat(c));
    }
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

  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == 'All') return _exams;
    return _exams
        .where((e) =>
            _prettyCat((e['exam_category'] ?? '').toString()) == _selectedFilter)
        .toList();
  }

  IconData _resolveIcon(String? iconName) {
    switch ((iconName ?? '').toLowerCase()) {
      case 'school':
        return Icons.school_rounded;
      case 'train':
        return Icons.train_rounded;
      case 'account_balance':
        return Icons.account_balance_rounded;
      case 'security':
        return Icons.security_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
    }
    return Icons.bolt_rounded;
  }

  Color _examColor(String cat) {
    switch (cat.toUpperCase()) {
      case 'SSC':
        return AppColors.yellow;
      case 'RAILWAY':
        return const Color(0xFF00E676);
      case 'BANK':
        return const Color(0xFFE040FB);
      case 'DEFENCE':
        return AppColors.orange;
      default:
        return AppColors.neonCyan;
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
    final name = (exam['exam_name'] ?? '').toString();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SetsScreen(
          title: '$name — Speed MCQs',
          category: 'mcq',
          examName: name,
          questionsPerSet: 10,
          showLeaderboard: true,
        ),
      ),
    );
  }

  void _openAll() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SetsScreen(
          title: '5000 Speed Math MCQs',
          category: 'mcq',
          questionsPerSet: 10,
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
                  if (!_isLoading && _filters.length > 1) _buildFilters(),
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
                color: AppColors.neonCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('5000 SPEED MCQS'),
                  style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonCyan,
                      letterSpacing: 2)),
              Text(tr('Pick an exam to start practising'),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = _filters;
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final f = filters[i];
          final isActive = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.neonCyan : AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isActive
                        ? AppColors.neonCyan
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.neonCyan));
    }

    final filtered = _filtered;

    return RefreshIndicator(
      color: AppColors.neonCyan,
      backgroundColor: AppColors.darkCard,
      onRefresh: _loadExams,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Quick "All MCQs" entry (always available)
          GestureDetector(
            onTap: _openAll,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.all_inclusive_rounded,
                      color: AppColors.neonCyan, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tr('All Speed MCQs'),
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.textMuted, size: 14),
                ],
              ),
            ),
          ),

          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(tr('No exams added yet'),
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(tr('Use the "All Speed MCQs" button above for now.'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final e = filtered[i];
                final cat = (e['exam_category'] ?? '').toString();
                final color = _examColor(cat);
                final canAccess = e['can_access'] == true;
                return _ExamSquare(
                  name: (e['exam_name'] ?? '').toString(),
                  icon: _resolveIcon(e['icon']?.toString()),
                  iconUrl: (e['icon_url'] ?? '').toString(),
                  color: color,
                  setCount: (e['set_count'] as num?)?.toInt() ?? 0,
                  locked: !canAccess,
                  onTap: () => _openExam(e),
                );
              },
            ),
        ],
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
  final int setCount;
  final bool locked;
  final VoidCallback onTap;

  const _ExamSquare({
    required this.name,
    required this.icon,
    this.iconUrl = '',
    required this.color,
    required this.setCount,
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
              '$setCount ${setCount == 1 ? tr('set') : tr('sets')}',
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
