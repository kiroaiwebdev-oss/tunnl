import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../question/question_screen.dart';

class TestListScreen extends StatefulWidget {
  final String category; // ← ADDED

  const TestListScreen({
    super.key,
    this.category = 'mcq', // ← ADDED (default 'mcq')
  });

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _sets = List.generate(10, (i) => {
    'setNumber': i + 1,
    'title': 'Test ${i + 1}',
    'questionCount': 50,
    'isLocked': i >= 3,
    'isCompleted': i < 1,
    'score': i < 1 ? '42/50' : null,
    'accuracy': i < 1 ? '84%' : null,
  });

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                _buildHeader(),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _sets.length,
                    itemBuilder: (context, index) {
                      return _TestSetCard(
                        data: _sets[index],
                        onTap: () {
                          if (_sets[index]['isLocked'] == true) {
                            _showLockedDialog();
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuestionScreen(
                                mode: 'free_mcq',
                                category: widget.category, // ← NOW WORKS
                                setNumber: _sets[index]['setNumber'],
                                totalQuestions: 50,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.neonCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Text('500 FREE MCQs',
            style: GoogleFonts.orbitron(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.neonCyan, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('500 Free Practice',
            style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text('10 sets × 50 questions each',
            style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.neonCyan.withOpacity(0.15), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const _SummaryItem(label: 'TOTAL SETS', value: '10', color: Colors.white),
                _divider(),
                const _SummaryItem(label: 'COMPLETED', value: '1', color: AppColors.success),
                _divider(),
                const _SummaryItem(label: 'QUESTIONS', value: '500', color: AppColors.neonCyan),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1, height: 30,
    color: AppColors.textMuted.withOpacity(0.3));

  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.orange.withOpacity(0.4), width: 1)),
        title: Text('🔒 Set Locked',
          style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Complete previous sets to unlock this one.',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
              style: GoogleFonts.poppins(color: AppColors.neonCyan))),
        ],
      ),
    );
  }
}

class _TestSetCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _TestSetCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isLocked    = data['isLocked'] == true;
    final bool isCompleted = data['isCompleted'] == true;
    final int setNum       = data['setNumber'];

    Color borderColor = AppColors.neonCyan.withOpacity(0.2);
    Color accentColor = AppColors.neonCyan;

    if (isLocked) {
      borderColor = AppColors.textMuted.withOpacity(0.2);
      accentColor = AppColors.textMuted;
    } else if (isCompleted) {
      borderColor = AppColors.success.withOpacity(0.4);
      accentColor = AppColors.success;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2)),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.1),
                border: Border.all(
                  color: accentColor.withOpacity(0.4), width: 1.5)),
              child: isLocked
                  ? const Icon(Icons.lock_rounded,
                      color: AppColors.textMuted, size: 20)
                  : isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.success, size: 22)
                      : Center(child: Text('$setNum',
                          style: GoogleFonts.orbitron(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: accentColor))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test $setNum',
                    style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: isLocked ? AppColors.textMuted : Colors.white)),
                  const SizedBox(height: 3),
                  Text('50 Questions  •  Speed Math',
                    style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary)),
                  if (isCompleted && data['score'] != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      _MiniChip(label: 'Score: ${data['score']}',
                        color: AppColors.success),
                      const SizedBox(width: 6),
                      _MiniChip(label: data['accuracy'],
                        color: AppColors.neonCyan),
                    ]),
                  ],
                ],
              ),
            ),
            Icon(
              isLocked
                  ? Icons.lock_outline_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: isLocked ? AppColors.textMuted : accentColor,
              size: 16),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1)),
      child: Text(label,
        style: GoogleFonts.poppins(
          fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
        style: GoogleFonts.orbitron(
          fontSize: 20, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 3),
      Text(label,
        style: GoogleFonts.poppins(
          fontSize: 9, color: AppColors.textSecondary, letterSpacing: 1.2)),
    ]);
  }
}