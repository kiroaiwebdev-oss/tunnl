import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/services/app_settings_service.dart';
import '../hub/hub_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _progressCtrl;
  late Animation<double>   _progressAnim;

  late AnimationController _glowCtrl;
  late Animation<double>   _glowAnim;

  late AnimationController _scaleCtrl;
  late Animation<double>   _scaleAnim;

  late AnimationController _rotationCtrl;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  String _statusText = 'INITIALIZING';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.splashDurationMs),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );

    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
    );

    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _progressCtrl.forward();
        _fadeCtrl.forward();
      }
    });
  }

  // ── MAIN INIT — API calls + navigation ──────────────
  Future<void> _initializeApp() async {
    // Minimum splash time start
    final splashFuture = Future.delayed(
      const Duration(milliseconds: AppConstants.splashDurationMs),
    );

    // ── 1. App Settings fetch (maintenance + force update)
    _setStatus('LOADING CONFIG');
    try {
      // Initialise the settings singleton — this loads the disk cache
      // immediately and kicks off a background refresh.
      await AppSettingsService.instance.init();

      final settingsRes = await ApiClient.get(ApiEndpoints.appSettings)
          .timeout(const Duration(seconds: 8));

      if (settingsRes['success'] == true || settingsRes['status'] == true) {
        final settings = Map<String, dynamic>.from(settingsRes['data'] ?? {});
        // Push fresh values into the singleton too (covers offline init)
        AppSettingsService.instance.overrideLocal(settings);

        // Save important settings to prefs
        final prefs = await SharedPreferences.getInstance();

        // Force update check
        final minVersion = settings['min_app_version'] ?? '1.0.0';
        final forceUpdate = settings['force_update'] == '1';
        await prefs.setString('min_app_version', minVersion);
        await prefs.setBool('force_update', forceUpdate);

        // Maintenance mode check
        final maintenance = settings['maintenance_mode'] == '1';
        await prefs.setBool('maintenance_mode', maintenance);

        // Premium price
        final premiumPrice = settings['premium_price'] ?? '50';
        await prefs.setString('premium_price', premiumPrice);

        if (mounted) {
          // Show maintenance screen if active
          if (maintenance) {
            await splashFuture;
            if (mounted) _showMaintenanceScreen();
            return;
          }

          // Show force update dialog if needed
          if (forceUpdate && _isUpdateRequired(minVersion)) {
            await splashFuture;
            if (mounted) _showForceUpdateDialog();
            return;
          }
        }
      }
    } catch (_) {
      // Network error — proceed with cached data
      _setStatus('OFFLINE MODE');
    }

    // ── 2. Check login status
    _setStatus('CHECKING SESSION');
    await Future.delayed(const Duration(milliseconds: 300));

    final prefs      = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;

    // ── 3. If logged in, refresh premium/name from server (best-effort).
    //    IMPORTANT: never wipe the session here. The JWT is valid for 30 days;
    //    a transient error (network/5xx/401) must NOT force the user to log in
    //    again on every cold start. Real expiry is handled contextually.
    if (isLoggedIn) {
      _setStatus('VERIFYING USER');
      try {
        final profileRes = await ApiClient.get(
          ApiEndpoints.userProfile,
          auth: true,
        ).timeout(const Duration(seconds: 6));

        if (profileRes['success'] == true || profileRes['status'] == true) {
          final user = profileRes['data']?['user'];
          if (user != null) {
            await prefs.setBool(
              AppConstants.prefIsPremium,
              user['is_premium'] == true || user['is_premium'] == 1,
            );
            await prefs.setString(
              AppConstants.prefUserName,
              user['name'] ?? '',
            );
          }
        }
      } catch (_) {
        // Ignore — keep the cached session.
      }
    }

    _setStatus('READY');

    // Wait for minimum splash time
    await splashFuture;
    if (!mounted) return;

    _navigateTo(
      prefs.getBool(AppConstants.prefIsLoggedIn) ?? false
          ? const HubScreen()
          : const LoginScreen(),
    );
  }

  // ── Helpers ───────────────────────────────────────
  void _setStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  bool _isUpdateRequired(String minVersion) {
    try {
      final current = AppConstants.appVersion
          .replaceAll('V', '')
          .split('.')
          .map(int.parse)
          .toList();
      final minimum = minVersion.split('.').map(int.parse).toList();
      for (int i = 0; i < minimum.length; i++) {
        if ((current.length > i ? current[i] : 0) < minimum[i]) return true;
        if ((current.length > i ? current[i] : 0) > minimum[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _showMaintenanceScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _MaintenanceScreen()),
    );
  }

  void _showForceUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2233),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.neonCyan.withValues(alpha: 0.3),
          ),
        ),
        title: const Text(
          'Update Required',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontSize: 16,
          ),
        ),
        content: const Text(
          'A new version of Tunnl is available. Please update to continue.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Open Play Store URL
              // launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=...'));
            },
            child: const Text(
              'UPDATE NOW',
              style: TextStyle(
                color: AppColors.neonCyan,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _glowCtrl.dispose();
    _scaleCtrl.dispose();
    _rotationCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.splashBg),
        child: Stack(
          children: [
            const _CornerBracket(isTopLeft: true,  top: 56, left: 20),
            const _CornerBracket(isTopLeft: false, bottom: 56, right: 20),

            Column(
              children: [
                SizedBox(height: size.height * 0.27),
                _buildLogo(),
                SizedBox(height: size.height * 0.06),
                _buildTitle(),
                const SizedBox(height: 18),
                _buildDotSeparator(),
                const SizedBox(height: 18),
                _buildSubtitle(),
                const Spacer(),
                _buildProgressBar(),
                const SizedBox(height: 36),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowCtrl, _rotationCtrl]),
        builder: (_, __) {
          return SizedBox(
            width: 210,
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan
                            .withValues(alpha: 0.12 * _glowAnim.value),
                        blurRadius: 90,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
                Transform.rotate(
                  angle: _rotationCtrl.value * 2 * math.pi,
                  child: const _Ring(
                    diameter: 198,
                    strokeWidth: 1.0,
                    color: AppColors.ringOuter,
                    dashed: true,
                  ),
                ),
                Transform.rotate(
                  angle: -_rotationCtrl.value * 2 * math.pi * 0.6,
                  child: _Ring(
                    diameter: 160,
                    strokeWidth: 1.2,
                    color: AppColors.neonCyan.withValues(alpha: 0.25),
                    dashed: false,
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0B1A27),
                    border: Border.all(
                      color: AppColors.neonCyan.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan
                            .withValues(alpha: 0.2 * _glowAnim.value),
                        blurRadius: 35,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 68,
                  height: 68,
                  child: Image.asset(
                    'assets/images/tunnel_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.all_inclusive_rounded,
                      color: AppColors.neonCyan,
                      size: 34,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Text(
        'T U N N E L',
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 10,
          shadows: [
            Shadow(
              color: AppColors.neonCyan.withValues(alpha: 0.25),
              blurRadius: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotSeparator() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44, height: 1,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonCyan,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44, height: 1,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: const Text(
        'New Way to Math',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w300,
          color: AppColors.textSecondary,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: AnimatedBuilder(
          animation: _progressAnim,
          builder: (_, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 3,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _progressAnim.value,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: AppColors.neonGradient,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan.withValues(alpha: 0.7),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ← Dynamic status text
                    Text(
                      _statusText,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const Text(
                      AppConstants.appVersion,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── MAINTENANCE SCREEN ────────────────────────────────
class _MaintenanceScreen extends StatelessWidget {
  const _MaintenanceScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashBg),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction_rounded,
                  color: AppColors.neonCyan,
                  size: 64,
                ),
                SizedBox(height: 24),
                Text(
                  'Under Maintenance',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'We are improving Tunnl for you.\nPlease check back shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── RING ──────────────────────────────────────────────
class _Ring extends StatelessWidget {
  final double diameter;
  final double strokeWidth;
  final Color  color;
  final bool   dashed;

  const _Ring({
    required this.diameter,
    required this.strokeWidth,
    required this.color,
    required this.dashed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _RingPainter(
          color: color,
          strokeWidth: strokeWidth,
          dashed: dashed,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color  color;
  final double strokeWidth;
  final bool   dashed;

  _RingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    if (!dashed) {
      canvas.drawCircle(center, radius, paint);
      return;
    }

    const int    dashCount = 48;
    const double dash      = 0.07;
    const double gap       = 0.06;
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
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ── CORNER BRACKET ────────────────────────────────────
class _CornerBracket extends StatelessWidget {
  final bool    isTopLeft;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const _CornerBracket({
    required this.isTopLeft,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: SizedBox(
        width: 32,
        height: 32,
        child: CustomPaint(
          painter: _BracketPainter(isTopLeft: isTopLeft),
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final bool isTopLeft;
  _BracketPainter({required this.isTopLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final path = Path();
    if (isTopLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
