import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/content_service.dart';
import '../../core/services/payment_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../dashboard/dashboard_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with TickerProviderStateMixin {

  bool _isLoading = false;
  late final PaymentService _payment;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  late AnimationController _badgeCtrl;
  late Animation<double> _badgeScaleAnim;

  // Benefits list
  final List<Map<String, dynamic>> _guestBenefits = [
    {
      'icon': Icons.quiz_rounded,
      'title': '500 Free MCQs',
      'subtitle': '10 sets × 50 questions',
      'color': AppColors.neonCyan,
    },
    {
      'icon': Icons.bolt_rounded,
      'title': 'Test Your Tunnelity',
      'subtitle': '10 question speed test',
      'color': AppColors.neonCyan,
    },
    {
      'icon': Icons.wb_sunny_rounded,
      'title': 'Daily Dose',
      'subtitle': '1 question daily pop-up',
      'color': AppColors.neonCyan,
    },
  ];

  final List<Map<String, dynamic>> _premiumBenefits = [
    {
      'icon': Icons.quiz_rounded,
      'title': '5000 Speed Math MCQs',
      'subtitle': 'Unlimited practice questions',
      'color': AppColors.yellow,
    },
    {
      'icon': Icons.functions_rounded,
      'title': '500 Simplification Questions',
      'subtitle': 'Master simplification tricks',
      'color': AppColors.yellow,
    },
    {
      'icon': Icons.layers_rounded,
      'title': 'Tunnel Tricks',
      'subtitle': 'Powerful strategies & shortcuts',
      'color': AppColors.yellow,
    },
    {
      'icon': Icons.play_circle_rounded,
      'title': 'Shorts',
      'subtitle': 'Quick math tip videos',
      'color': AppColors.yellow,
    },
    {
      'icon': Icons.calendar_today_rounded,
      'title': 'Daily Practice Sets',
      'subtitle': "Today's set in dashboard",
      'color': AppColors.yellow,
    },
    {
      'icon': Icons.history_edu_rounded,
      'title': 'Previous Year Questions',
      'subtitle': 'Complete PYQ access',
      'color': AppColors.yellow,
    },
    {
      'icon': Icons.card_giftcard_rounded,
      'title': 'Solve & Earn',
      'subtitle': 'Earn rewards by solving',
      'color': AppColors.yellow,
    },
    {
      'icon': Icons.bar_chart_rounded,
      'title': 'Leaderboard Access',
      'subtitle': 'Compete with 12,000+ students',
      'color': AppColors.yellow,
    },
  ];

  // Live price (defaults to 50 then refreshes from app_settings)
  int _priceRupees = 50;

  // ── Coupon state ──────────────────────────────────
  final TextEditingController _couponCtrl = TextEditingController();
  bool   _couponLoading = false;
  bool   _couponApplied = false;
  String _appliedCode   = '';
  int    _discount      = 0;
  int    _finalPrice    = 0;
  String _couponMsg     = '';
  bool   _couponError   = false;

  /// Price the user will actually pay (after any coupon).
  int get _payablePrice => _couponApplied ? _finalPrice : _priceRupees;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupPayment();
    _loadPrice();
    AppSettingsService.instance.addListener(_loadPrice);
  }

  void _loadPrice() {
    if (!mounted) return;
    setState(() {
      _priceRupees = AppSettingsService.instance.getInt('premium_price', 50);
    });
  }

  void _setupPayment() {
    _payment = PaymentService()
      ..attach(
        onSuccess: _onPaymentSuccess,
        onError: _onPaymentError,
      );
  }

  void _setupAnimations() {
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

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _badgeScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut),
    );

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _badgeCtrl.forward();
    });
  }

  @override
  void dispose() {
    AppSettingsService.instance.removeListener(_loadPrice);
    _couponCtrl.dispose();
    _payment.dispose();
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  // ── Coupon: validate + apply ──────────────────────
  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) {
      setState(() {
        _couponError = true;
        _couponMsg = 'Enter a coupon code first.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _couponLoading = true;
      _couponMsg = '';
      _couponError = false;
    });

    final res = await ContentService.validateCoupon(code, plan: 'lifetime');
    if (!mounted) return;

    final valid = res['valid'] == true;
    setState(() {
      _couponLoading = false;
      if (valid) {
        _couponApplied = true;
        _appliedCode   = (res['code'] ?? code).toString().toUpperCase();
        _discount      = (res['discount'] as int?) ?? 0;
        _finalPrice    = (res['final_price'] as int?) ?? _priceRupees;
        _couponError   = false;
        _couponMsg     = res['message']?.toString() ?? 'Coupon applied!';
      } else {
        _couponApplied = false;
        _appliedCode   = '';
        _discount      = 0;
        _couponError   = true;
        _couponMsg     = res['message']?.toString() ?? 'Invalid coupon.';
      }
    });
  }

  void _removeCoupon() {
    setState(() {
      _couponApplied = false;
      _appliedCode   = '';
      _discount      = 0;
      _couponMsg     = '';
      _couponError   = false;
      _couponCtrl.clear();
    });
  }

  // ── Payment Handler ───────────────────────────────
  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    await _payment.startUpgrade(
      plan: 'lifetime',
      couponCode: _couponApplied ? _appliedCode : '',
    );
    // success/error callbacks toggle _isLoading off
  }

  void _onPaymentSuccess(Map<String, dynamic> premiumInfo) async {
    if (!mounted) return;

    // Refresh user profile so dashboard etc. reflect new premium status
    try {
      await UserService.getProfile();
    } catch (_) {}
    await AuthService.setPremium(true);

    if (!mounted) return;
    setState(() => _isLoading = false);
    _showPaymentSuccess(premiumInfo);
  }

  void _onPaymentError(String message) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                BorderSide(color: AppColors.error.withValues(alpha: 0.4), width: 1)),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentSuccess(Map<String, dynamic> premiumInfo) {
    final plan = (premiumInfo['plan'] ?? 'lifetime').toString();
    final expiry = (premiumInfo['expiry'] ?? 'Lifetime').toString();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.success.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Payment Successful!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome to Tunnl Premium!\nAll features unlocked 🎉',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    plan.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Valid: $expiry',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const DashboardScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                  (route) => false,
                );
              },
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF00ACC1)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    'EXPLORE DASHBOARD',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBg,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
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

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildHeroBadge(),
                          const SizedBox(height: 24),

                          _buildSectionHeader(
                            label: 'AS A GUEST',
                            sublabel: 'Free forever',
                            color: AppColors.neonCyan,
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          ..._guestBenefits.map((b) =>
                              _BenefitRow(data: b, isPremium: false)),

                          const SizedBox(height: 20),
                          _buildVsDivider(),
                          const SizedBox(height: 20),

                          _buildSectionHeader(
                            label: 'TICKET TO TUNNL',
                            sublabel: 'Premium — ₹$_priceRupees one time',
                            color: AppColors.yellow,
                            icon: Icons.workspace_premium_rounded,
                          ),
                          const SizedBox(height: 12),
                          ..._premiumBenefits.map((b) =>
                              _BenefitRow(data: b, isPremium: true)),

                          const SizedBox(height: 28),
                          _buildPriceCard(),
                          const SizedBox(height: 14),
                          _buildCouponCard(),
                          const SizedBox(height: 16),
                          _buildPayButton(),
                          const SizedBox(height: 10),
                          _buildSecureNote(),
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
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.neonCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'TICKET TO TUNNL',
            style: GoogleFonts.orbitron(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.neonCyan,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge() {
    return ScaleTransition(
      scale: _badgeScaleAnim,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1A1400),
                  Color(0xFF2A2000),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.yellow.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      AppColors.yellow.withValues(alpha: 0.1 * _glowAnim.value),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/pre.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.yellow.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.yellow.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.yellow,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'UNLOCK FULL ACCESS',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.yellow,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'One-time payment — Lifetime access',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PriceChip(
                      label: '₹$_priceRupees',
                      sublabel: 'ONE TIME',
                      color: AppColors.yellow,
                    ),
                    const SizedBox(width: 12),
                    const _PriceChip(
                      label: '∞',
                      sublabel: 'LIFETIME',
                      color: AppColors.neonCyan,
                    ),
                    const SizedBox(width: 12),
                    const _PriceChip(
                      label: '8+',
                      sublabel: 'FEATURES',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String label,
    required String sublabel,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              sublabel,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVsDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.orange.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Text(
            'UPGRADE',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.orange,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.yellow.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tunnel Premium',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'One-time • Lifetime access',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_couponApplied && _discount > 0)
                Text(
                  '₹$_priceRupees',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                '₹$_payablePrice',
                style: GoogleFonts.orbitron(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.yellow,
                ),
              ),
              Text(
                _couponApplied && _discount > 0 ? 'after discount' : 'only',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _couponApplied
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.neonCyan.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_rounded,
                  color: AppColors.neonCyan, size: 16),
              const SizedBox(width: 8),
              Text(
                'Have a coupon?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponCtrl,
                  enabled: !_couponApplied,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'ENTER CODE',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                    filled: true,
                    fillColor: AppColors.darkBg.withValues(alpha: 0.4),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.neonCyan.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.neonCyan.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _couponLoading
                    ? null
                    : (_couponApplied ? _removeCoupon : _applyCoupon),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: _couponApplied
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.neonCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _couponApplied
                          ? AppColors.error.withValues(alpha: 0.4)
                          : AppColors.neonCyan.withValues(alpha: 0.4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _couponLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.neonCyan,
                          ),
                        )
                      : Text(
                          _couponApplied ? 'REMOVE' : 'APPLY',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _couponApplied
                                ? AppColors.error
                                : AppColors.neonCyan,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (_couponMsg.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _couponError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_rounded,
                  size: 14,
                  color: _couponError ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _couponMsg,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _couponError ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handlePayment,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD600), Color(0xFFFF8F00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.darkBg,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_open_rounded,
                    color: AppColors.darkBg,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PAY ₹$_payablePrice & UNLOCK NOW',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBg,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecureNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_rounded,
          size: 12,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 5),
        Text(
          'Secured by Razorpay  •  One-time payment',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// BENEFIT ROW
// ─────────────────────────────────────────────────────
class _BenefitRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isPremium;

  const _BenefitRow({required this.data, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final Color color = data['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Icon(
              data['icon'] as IconData,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  data['subtitle'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isPremium
                ? Icons.check_circle_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// PRICE CHIP
// ─────────────────────────────────────────────────────
class _PriceChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;

  const _PriceChip({
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            sublabel,
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
