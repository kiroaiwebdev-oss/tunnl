import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/app_strings.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../hub/hub_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {

  final TextEditingController _nameCtrl = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  String? _selectedStandard;
  bool _isLoading = false;
  bool _hasNameError = false;
  bool _hasStandardError = false;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<String> _standards = [
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
    'Class 11', 'Class 12',
    'SSC / Railway', 'Banking', 'UPSC', 'Other Competitive',
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();

    // Validation
    setState(() {
      _hasNameError     = name.isEmpty;
      _hasStandardError = _selectedStandard == null;
    });

    if (name.isEmpty || _selectedStandard == null) return;

    setState(() => _isLoading = true);

    try {
      // API call — user_profile.php POST
      final res = await ApiClient.post(
        ApiEndpoints.userProfile,
        {
          'name':     name,
          'standard': _selectedStandard,
        },
        auth: true,
      );

      if (!mounted) return;

      final bool isSuccess = res['success'] == true || res['status'] == true;

      if (isSuccess) {
        // Locally cache karo
        await AuthService.setCachedName(name);
        await AuthService.setCachedStandard(_selectedStandard!);

        if (!mounted) return;

        // HubScreen pe bhejo
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HubScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
      } else {
        _showError(res['message'] ?? tr('Failed to save. Try again.'));
      }
    } catch (e) {
      if (!mounted) return;
      _showError(tr('Network error. Check your connection.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.splashBg),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),

                      // ── Header ──────────────────────────────
                      Center(
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1A26),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.neonCyan.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonCyan.withValues(alpha: 0.15),
                                blurRadius: 20, spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.neonCyan, size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          tr('Setup Your Profile'),
                          style: GoogleFonts.poppins(
                            fontSize: 24, fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          tr('Help us personalise your Tunnl experience'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Name Input ──────────────────────────
                      Text(
                        tr('Your Name'),
                        style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary, letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2235),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _hasNameError
                                ? AppColors.error.withValues(alpha: 0.6)
                                : _nameFocus.hasFocus
                                    ? AppColors.neonCyan.withValues(alpha: 0.5)
                                    : AppColors.neonCyan.withValues(alpha: 0.1),
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) {
                            if (_hasNameError) setState(() => _hasNameError = false);
                          },
                          style: GoogleFonts.poppins(
                            fontSize: 15, color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: tr('Enter your full name'),
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14, color: AppColors.textMuted,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16,
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.neonCyan, size: 20,
                            ),
                          ),
                        ),
                      ),
                      if (_hasNameError) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              tr('Please enter your name'),
                              style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── Class/Standard Dropdown ─────────────
                      Text(
                        tr('Your Class / Exam'),
                        style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary, letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Grid chips — better UX than dropdown
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _standards.map((std) {
                          final isSelected = _selectedStandard == std;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedStandard = std;
                              _hasStandardError = false;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.neonCyan.withValues(alpha: 0.15)
                                    : const Color(0xFF1A2235),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.neonCyan
                                      : _hasStandardError
                                          ? AppColors.error.withValues(alpha: 0.4)
                                          : AppColors.neonCyan.withValues(alpha: 0.1),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                std,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.neonCyan
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (_hasStandardError) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              tr('Please select your class/exam'),
                              style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 40),

                      // ── Save Button ─────────────────────────
                      GestureDetector(
                        onTap: _isLoading ? null : _saveProfile,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 58,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isLoading
                                  ? [
                                      AppColors.neonCyan.withValues(alpha: 0.5),
                                      const Color(0xFF00ACC1).withValues(alpha: 0.5),
                                    ]
                                  : const [
                                      Color(0xFF00E5FF),
                                      Color(0xFF00ACC1),
                                    ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonCyan
                                    .withValues(alpha: _isLoading ? 0.1 : 0.35),
                                blurRadius: 20, spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.darkBg,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      tr('START MY JOURNEY'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkBg,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.rocket_launch_rounded,
                                      color: AppColors.darkBg, size: 20),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Profile completion is mandatory for new users — no skip.
                      Center(
                        child: Text(
                          tr('Complete your profile to continue'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}