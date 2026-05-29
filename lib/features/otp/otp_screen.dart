import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../hub/hub_screen.dart';
import '../auth/profile_setup_screen.dart';
class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with TickerProviderStateMixin {

  final List<TextEditingController> _otpCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool   _isLoading    = false;
  bool   _hasError     = false;
  String _errorText    = '';
  bool   _isVerified   = false;

  int    _resendSeconds = 30;
  Timer? _resendTimer;
  bool   _canResend    = false;

  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  late AnimationController _indicatorCtrl;
  late Animation<double>   _indicatorAnim;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _setupAnimations();
  }

  void _setupAnimations() {
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _indicatorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _indicatorAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _indicatorCtrl, curve: Curves.easeOut),
    );

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _indicatorCtrl.forward();
    });
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _canResend     = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    for (var c in _otpCtrl)    { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    _resendTimer?.cancel();
    _entryCtrl.dispose();
    _indicatorCtrl.dispose();
    super.dispose();
  }

  String get _otpValue => _otpCtrl.map((c) => c.text).join();

  // ── VERIFY OTP ──────────────────────────────────────
Future<void> _verifyOtp() async {
  final otp = _otpValue;

  if (otp.length < 6) {
    setState(() { _hasError = true; _errorText = 'Please enter complete 6-digit OTP'; });
    return;
  }

  if (_isLoading || _isVerified) return;

  setState(() { _hasError = false; _isLoading = true; });

  try {
    final res = await AuthService.verifyOtp(widget.phoneNumber, otp);
    if (!mounted) return;

    final bool isSuccess = res['success'] == true || res['status'] == true;

    if (isSuccess) {
      setState(() => _isVerified = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      // ✅ Name check karo — empty hai to ProfileSetup pe bhejo
      final name = res['data']?['user']?['name'] ?? '';
      final isProfileDone = name.toString().trim().isNotEmpty;

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => isProfileDone
              ? const HubScreen()
              : const ProfileSetupScreen(),  // ← naya screen
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    } else {
      for (var c in _otpCtrl) { c.clear(); }
      _focusNodes[0].requestFocus();
      setState(() {
        _hasError  = true;
        _errorText = res['message'] ?? 'Invalid OTP. Please try again.';
        _isLoading = false;
      });
    }
  } catch (e) {
    if (!mounted) return;
    debugPrint('VerifyOTP Error: $e');
    setState(() {
      _hasError  = true;
      _errorText = 'Network error. Check your connection.';
      _isLoading = false;
    });
  }
}

  // ── RESEND OTP ────────────────────────────────────
  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      for (var c in _otpCtrl) { c.clear(); }
      _hasError = false;
    });
    _focusNodes[0].requestFocus();

    try {
      final res = await AuthService.sendOtp(widget.phoneNumber);
      if (!mounted) return;

      // ✅ FIX: 'success' aur 'status' dono check karo
      final bool isSuccess = res['success'] == true || res['status'] == true;

      if (isSuccess) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OTP resent successfully!',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF0D2233),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppColors.neonCyan.withOpacity(0.3),
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _hasError  = true;
          _errorText = res['message'] ?? 'Failed to resend OTP.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError  = true;
        _errorText = 'Network error. Try again.';
      });
    }
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
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              _buildLogoBox(),
                              const SizedBox(height: 28),
                              _buildTitle(),
                              const SizedBox(height: 20),
                              _buildPhoneChip(),
                              const SizedBox(height: 40),
                              _buildOtpBoxes(),
                              const SizedBox(height: 20),

                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                child: _hasError
                                    ? Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.error_outline_rounded,
                                                color: AppColors.error,
                                                size: 14,
                                              ),
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

                              const SizedBox(height: 16),
                              _buildResendTimer(),
                              const SizedBox(height: 36),
                              _buildVerifyButton(),
                              const SizedBox(height: 20),
                              _buildWrongNumberRow(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildBottomIndicator(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
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
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.neonCyan,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Tunnl',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildLogoBox() {
    return Container(
      width: 88, height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isVerified
              ? AppColors.neonCyan.withOpacity(0.6)
              : AppColors.neonCyan.withOpacity(0.15),
          width: _isVerified ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withOpacity(_isVerified ? 0.2 : 0.08),
            blurRadius: 20, spreadRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: _isVerified
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.neonCyan, size: 36)
          : Image.asset(
              'assets/images/tunnel_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.all_inclusive_rounded,
                color: AppColors.neonCyan, size: 36,
              ),
            ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          _isVerified ? 'Verified!' : 'Verification',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _isVerified ? AppColors.neonCyan : Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isVerified
              ? 'Welcome to Tunnl!'
              : 'Enter the code sent to your mobile\nnumber',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneChip() {
    final phone  = widget.phoneNumber;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final masked = digits.length >= 4
        ? '+91 ••••• ••${digits.substring(digits.length - 4)}'
        : phone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.neonCyan.withOpacity(0.2), width: 1,
        ),
      ),
      child: Text(
        masked,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 46, height: 56,
          child: TextFormField(
            controller:  _otpCtrl[i],
            focusNode:   _focusNodes[i],
            keyboardType: TextInputType.number,
            textAlign:   TextAlign.center,
            maxLength:   1,
            enabled:     !_isVerified,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _isVerified ? AppColors.neonCyan : Colors.white,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled:    true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.neonCyan.withOpacity(0.15), width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isVerified
                      ? AppColors.neonCyan.withOpacity(0.5)
                      : _hasError
                          ? AppColors.error.withOpacity(0.5)
                          : AppColors.neonCyan.withOpacity(0.15),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.neonCyan, width: 1.5,
                ),
              ),
            ),
            onChanged: (val) {
              if (_hasError) setState(() => _hasError = false);
              if (val.isNotEmpty && i < 5) {
                _focusNodes[i + 1].requestFocus();
              }
              if (val.isEmpty && i > 0) {
                _focusNodes[i - 1].requestFocus();
              }
              if (_otpValue.length == 6) _verifyOtp();
            },
          ),
        );
      }),
    );
  }

  Widget _buildResendTimer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive OTP? ",
          style: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: _resendOtp,
          child: Text(
            _canResend ? 'Resend' : 'Resend in ${_resendSeconds}s',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _canResend ? AppColors.neonCyan : AppColors.textMuted,
              decoration: _canResend
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: AppColors.neonCyan,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return GestureDetector(
      onTap: (_isLoading || _isVerified) ? null : _verifyOtp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isVerified
                ? [AppColors.neonCyan, AppColors.neonCyan]
                : (_isLoading
                    ? [
                        AppColors.neonCyan.withOpacity(0.5),
                        const Color(0xFF00ACC1).withOpacity(0.5),
                      ]
                    : const [Color(0xFF00E5FF), Color(0xFF00ACC1)]),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan
                  .withOpacity(_isLoading ? 0.15 : 0.35),
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
                  Text(
                    _isVerified ? 'VERIFIED ✓' : 'VERIFY OTP',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBg,
                      letterSpacing: 2,
                    ),
                  ),
                  if (!_isVerified) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.darkBg, size: 20),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildWrongNumberRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Wrong number? ',
          style: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'Edit',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neonCyan,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.neonCyan,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomIndicator() {
    return AnimatedBuilder(
      animation: _indicatorAnim,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Row(
            children: [
              Container(
                height: 3,
                width: 60 * _indicatorAnim.value,
                decoration: BoxDecoration(
                  gradient: AppColors.neonGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                height: 3,
                width: 60 * _indicatorAnim.value,
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}