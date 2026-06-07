import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../otp/otp_screen.dart';

// Agar alag SignupScreen hai to uncomment karo:
// import '../auth/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  final TextEditingController _phoneCtrl = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorText = '';

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late AnimationController _rotationCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    _glowCtrl.dispose();
    _rotationCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── SEND OTP ──────────────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();

    if (phone.isEmpty) {
      setState(() { _hasError = true; _errorText = 'Please enter your mobile number'; });
      return;
    }
    if (phone.length != 10) {
      setState(() { _hasError = true; _errorText = 'Enter valid 10-digit mobile number'; });
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() { _hasError = true; _errorText = 'Enter valid Indian mobile number'; });
      return;
    }

    setState(() { _hasError = false; _isLoading = true; });

    try {
      final res = await AuthService.sendOtp(phone);
      if (!mounted) return;

      // ✅ FIX: 'success' aur 'status' dono check karo
      final bool isSuccess = res['success'] == true || res['status'] == true;

      if (isSuccess) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => OtpScreen(phoneNumber: phone),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        setState(() {
          _hasError  = true;
          _errorText = res['message'] ?? 'Failed to send OTP. Try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError  = true;
        _errorText = 'Network error. Check your connection.';
      });
      debugPrint('SendOTP Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ FIX: Create Account — ab kaam karega
  void _onCreateAccount() {
    FocusScope.of(context).unfocus();

    // Option A — Snackbar dikhao (account OTP se auto create hota hai)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Number daalo & OTP bhejo — account auto create ho jayega!',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D2233),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    // Option B — Alag SignupScreen pe bhejne ke liye ye uncomment karo:
    // Navigator.of(context).push(
    //   MaterialPageRoute(builder: (_) => const SignupScreen()),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.splashBg),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildFloatingSymbols(size),
                          _buildLogoSection(),
                          const SizedBox(height: 28),
                          _buildTitleSection(),
                          const SizedBox(height: 40),
                          _buildBottomCard(size),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingSymbols(Size size) {
    return SizedBox(
      height: 20,
      child: Stack(
        children: [
          Positioned(
            left: 28, top: 0,
            child: Text('+',
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: AppColors.textMuted.withValues(alpha: 0.5),
                fontWeight: FontWeight.w300,
              )),
          ),
          Positioned(
            right: 28, top: 0,
            child: Text('÷',
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: AppColors.textMuted.withValues(alpha: 0.5),
                fontWeight: FontWeight.w300,
              )),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowCtrl, _rotationCtrl]),
      builder: (_, __) {
        return SizedBox(
          width: 170, height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 170, height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.12 * _glowAnim.value),
                      blurRadius: 70, spreadRadius: 25,
                    ),
                  ],
                ),
              ),
              Container(
                width: 162, height: 162,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.5), width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.35), width: 1.2,
                  ),
                ),
              ),
              Transform.rotate(
                angle: _rotationCtrl.value * 2 * math.pi,
                child: SizedBox(
                  width: 145, height: 145,
                  child: CustomPaint(
                    painter: _DashedRingPainter(
                      color: AppColors.neonCyan.withValues(alpha: 0.2),
                      strokeWidth: 1.0,
                    ),
                  ),
                ),
              ),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B1520),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.15 * _glowAnim.value),
                      blurRadius: 25, spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1A26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Image.asset(
                  'assets/images/tunnel_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.all_inclusive_rounded,
                    color: AppColors.neonCyan, size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'Tunnl',
              style: GoogleFonts.orbitron(
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 8,
                shadows: [
                  Shadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Text('×',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w300,
                  )),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'SPEED MATH CALCULATION',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCard(Size size) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1923),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildFeatureIcons(),
          const SizedBox(height: 32),
          _buildPhoneInput(),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorText,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 20),
          _buildSendOtpButton(),
          const SizedBox(height: 24),
          _buildCreateAccountRow(),
        ],
      ),
    );
  }

  Widget _buildFeatureIcons() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _FeatureIcon(icon: Icons.bolt_rounded,
          label1: 'FAST', label2: 'CALCULATION'),
        _FeatureIcon(icon: Icons.bar_chart_rounded,
          label1: 'ACCURATE', label2: 'RESULTS'),
        _FeatureIcon(icon: Icons.emoji_events_rounded,
          label1: 'IMPROVE', label2: 'TUNNELITY'),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _hasError
              ? AppColors.error.withValues(alpha: 0.5)
              : _phoneFocus.hasFocus
                  ? AppColors.neonCyan.withValues(alpha: 0.4)
                  : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Row(
            children: [
              const Text('🇮🇳', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text('+91',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 1, height: 24,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          Expanded(
            child: TextField(
              controller: _phoneCtrl,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) {
                if (_hasError) setState(() => _hasError = false);
              },
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'What is your number?',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _sendOtp(),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildSendOtpButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _sendOtp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? LinearGradient(colors: [
                  AppColors.neonCyan.withValues(alpha: 0.5),
                  const Color(0xFF00ACC1).withValues(alpha: 0.5),
                ])
              : const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00ACC1)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withValues(alpha: _isLoading ? 0.15 : 0.35),
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
                    color: AppColors.darkBg, strokeWidth: 2.5,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SEND OTP',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBg,
                      letterSpacing: 2,
                    )),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.darkBg, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildCreateAccountRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('New to Tunnl?  ',
          style: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textSecondary,
          )),
        GestureDetector(
          onTap: _onCreateAccount,  // ✅ Fix: ab navigate/snackbar dikhayega
          child: Text('Create Account',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neonCyan,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.neonCyan,
            )),
        ),
      ],
    );
  }
}

// ── FEATURE ICON ──────────────────────────────────────
class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label1;
  final String label2;

  const _FeatureIcon({
    required this.icon,
    required this.label1,
    required this.label2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF0D2233),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.2), width: 1,
            ),
          ),
          child: Icon(icon, color: AppColors.neonCyan, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label1,
          style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w500,
            color: AppColors.textSecondary, letterSpacing: 1.2,
          )),
        Text(label2,
          style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w500,
            color: AppColors.textSecondary, letterSpacing: 1.2,
          )),
      ],
    );
  }
}

// ── DASHED RING PAINTER ───────────────────────────────
class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedRingPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    const int dashCount = 40;
    const double dash = 0.08;
    const double gap = 0.07;
    double angle = 0;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle, dash, false, paint,
      );
      angle += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}