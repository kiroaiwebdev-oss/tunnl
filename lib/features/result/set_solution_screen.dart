// lib/features/result/set_solution_screen.dart
//
// Standalone "View Solution" screen for a set the user has already attempted.
// Shows every question with the CORRECT option highlighted + the explanation,
// with an EN/हिं language toggle. Works for ANY set (PYQ, 5000 MCQ, daily, etc.)
// because it just loads the set's questions (which now carry Hindi + solution).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/content_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/app_strings.dart';
import '../../core/models/question_model.dart';

class SetSolutionScreen extends StatefulWidget {
  final int setId;
  final String title;
  final int setNumber;

  const SetSolutionScreen({
    super.key,
    required this.setId,
    this.title = '',
    this.setNumber = 0,
  });

  @override
  State<SetSolutionScreen> createState() => _SetSolutionScreenState();
}

class _SetSolutionScreenState extends State<SetSolutionScreen> {
  List<QuestionModel> _questions = [];
  bool _loading = true;
  bool _hindi = LanguageService.instance.isHindi;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final qs = await ContentService.getQuestions(widget.setId);
    if (!mounted) return;
    setState(() {
      _questions = qs;
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
              _buildAppBar(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonCyan))
                    : _questions.isEmpty
                        ? Center(
                            child: Text(tr('No review data available.'),
                                style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            itemCount: _questions.length,
                            itemBuilder: (_, i) =>
                                _buildCard(_questions[i], i),
                          ),
              ),
            ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Solution'),
                    style: GoogleFonts.orbitron(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neonCyan,
                        letterSpacing: 2)),
                if (widget.title.isNotEmpty)
                  Text(widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // EN / हिं toggle
          GestureDetector(
            onTap: () => setState(() => _hindi = !_hindi),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate_rounded,
                      color: AppColors.neonCyan, size: 14),
                  const SizedBox(width: 5),
                  Text(_hindi ? 'हिं' : 'EN',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonCyan)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(QuestionModel q, int i) {
    final options = q.optionsFor(_hindi);
    final correct = q.correctIndex;
    final explanation = q.explanationFor(_hindi);
    final labels = ['A', 'B', 'C', 'D'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.neonCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('Q${i + 1}',
                      style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonCyan)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(q.questionFor(_hindi),
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ],
            ),
          ),

          // Options (correct highlighted)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: List.generate(options.length, (oi) {
                final isC = oi == correct;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isC
                        ? AppColors.success.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isC
                            ? AppColors.success.withValues(alpha: 0.4)
                            : AppColors.textMuted.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Text(labels[oi],
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isC
                                  ? AppColors.success
                                  : AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(options[oi],
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isC
                                    ? AppColors.success
                                    : AppColors.textSecondary)),
                      ),
                      if (isC)
                        const Icon(Icons.check_rounded,
                            color: AppColors.success, size: 16),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Solution / explanation
          if (explanation.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded,
                          color: AppColors.neonCyan, size: 14),
                      const SizedBox(width: 6),
                      Text(tr('Solution'),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neonCyan)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(explanation,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
