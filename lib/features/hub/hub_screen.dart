// lib/features/hub/hub_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/content_service.dart';
import '../../core/services/user_service.dart';
import '../../core/models/banner_model.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../shorts/shorts_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../testlist/test_list_screen.dart';
import '../question/question_screen.dart';
import '../premium/premium_screen.dart';
import '../previous_year/previous_year_screen.dart';
import '../profile/profile_screen.dart';
import '../tricks/tricks_screen.dart';
import '../solve_earn/solve_earn_screen.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> with TickerProviderStateMixin {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  final PageController _pageCtrl    = PageController();
  int                  _currentPage = 0;
  Timer?               _autoScrollTimer;

  bool   _isLoggedIn    = false;
  bool   _isPremium     = false;
  bool   _isLoadingUser = true;
  String _userName      = '';

  List<BannerModel> _apiBanners     = [];
  bool              _bannersLoading = true;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();
    _loadAll();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _autoScrollTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadUserStatus(), _loadBanners()]);
    if (mounted) _startAutoScroll();
  }

  Future<void> _loadUserStatus() async {
    try {
      final res = await UserService.getProfile();
      if (!mounted) return;
      if (res['success'] == true) {
        final user = res['data']?['user'] as Map<String, dynamic>?;
        if (user != null) {
          setState(() {
            _isLoggedIn    = true;
            _isPremium     = user['is_premium'] == true || user['is_premium'] == 1;
            _userName      = user['name'] as String? ?? '';
            _isLoadingUser = false;
          });
          return;
        }
      }
    } catch (_) {}

    final loggedIn  = await AuthService.isLoggedIn();
    final isPremium = await AuthService.isPremium();
    final name      = await AuthService.getCachedName();
    if (mounted) {
      setState(() {
        _isLoggedIn    = loggedIn;
        _isPremium     = isPremium;
        _userName      = name;
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await ContentService.getBanners();
      if (mounted) {
        setState(() {
          _apiBanners     = banners;
          _bannersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _bannersLoading = false);
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final total = _apiBanners.length;
      if (total <= 1) return;
      final next = (_currentPage + 1) % total;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onBannerTap(String actionValue) {
    switch (actionValue) {
      case 'previous_year':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PreviousYearScreen(isPremium: _isPremium)));
        break;
      case 'premium':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const PremiumScreen())).then((_) {
            if (mounted) _loadAll();
          });
        break;
      case 'mcq':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const TestListScreen()));
        break;
      case 'leaderboard':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const LeaderboardScreen()));
        break;
      case 'shorts':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ShortsScreen()));
        break;
      case 'tricks':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TricksScreen(isPremium: _isPremium)));
        break;
      case 'solve_earn':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const SolveEarnScreen()));
        break;
    }
  }

  Future<void> _onTicketTap() async {
    // Not logged in → login first.
    final loggedIn = _isLoadingUser ? await AuthService.isLoggedIn() : _isLoggedIn;
    if (!mounted) return;
    if (!loggedIn) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ));
      return;
    }
    // This card sells the ₹50 premium upgrade — send NON-premium users to the
    // Premium page. Already-premium users enter the full dashboard.
    final premium = _isLoadingUser ? await AuthService.isPremium() : _isPremium;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => premium ? const DashboardScreen() : const PremiumScreen(),
    ));
    if (mounted) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.darkBg,
      drawer: _buildDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.splashBg),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildTopBar(),
                  SizedBox(height: size.height * 0.03),
                  _buildCarousel(),
                  SizedBox(height: size.height * 0.035),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _HubCard(
                            title:       'Test Your Tunnelity',
                            subtitle:    'Take a quick 10-question speed test',
                            borderColor: AppColors.neonCyan,
                            iconBgColor: AppColors.neonCyan,
                            icon:        Icons.bolt_rounded,
                            iconColor:   AppColors.darkBg,
                            titleColor:  Colors.white,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const QuestionScreen(
                                  mode: 'tunnelity', category: 'mcq',
                                  setNumber: 1, totalQuestions: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _HubCard(
                            title:       'Ticket to Tunnl',
                            subtitle:    'Unlock full access & advanced features',
                            borderColor: AppColors.orange,
                            iconBgColor: AppColors.orange,
                            icon:        Icons.workspace_premium_rounded,
                            iconColor:   Colors.white,
                            titleColor:  AppColors.orange,
                            priceBadge:  '₹50',
                            onTap:       _onTicketTap,
                          ),
                          const SizedBox(height: 12),
                          _HubCard(
                            title:       '500 Free Practice MCQs',
                            subtitle:    'Practice unlimited questions for free',
                            borderColor: const Color(0xFF7C3AED),
                            iconBgColor: const Color(0xFF4A1A8A),
                            icon:        Icons.quiz_rounded,
                            iconColor:   Colors.white,
                            titleColor:  Colors.white,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TestListScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomTagline(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          ),
          Text(
            'Tunnl',
            style: GoogleFonts.orbitron(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.neonCyan, letterSpacing: 4,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _isLoggedIn
                  ? const ProfileScreen()
                  : const LoginScreen(),
            )),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _isLoggedIn
                    ? AppColors.neonCyan.withOpacity(0.1)
                    : AppColors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isLoggedIn
                      ? AppColors.neonCyan.withOpacity(0.35)
                      : AppColors.orange.withOpacity(0.4),
                ),
              ),
              child: _isLoadingUser
                  ? SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.neonCyan.withOpacity(0.6),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoggedIn && _userName.isNotEmpty)
                          Container(
                            width: 22, height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.neonCyan,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _userName[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: AppColors.darkBg,
                                ),
                              ),
                            ),
                          )
                        else
                          Icon(
                            _isLoggedIn ? Icons.person_rounded : Icons.login_rounded,
                            color: _isLoggedIn ? AppColors.neonCyan : AppColors.orange,
                            size: 15,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          _isLoggedIn
                              ? (_userName.isNotEmpty
                                  ? _userName.split(' ').first
                                  : 'Profile')
                              : 'Login',
                          style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: _isLoggedIn
                                ? AppColors.neonCyan
                                : AppColors.orange,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    final int total = _apiBanners.length;

    // Loading → show a placeholder shimmer box.
    if (_bannersLoading) {
      return SizedBox(
        height: 160,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1A26),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neonCyan.withOpacity(0.15)),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.neonCyan.withOpacity(0.6),
              ),
            ),
          ),
        ),
      );
    }

    // No admin banners → render nothing (no hardcoded fallback content).
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: total,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _buildApiBanner(_apiBanners[i]),
          ),
        ),
        const SizedBox(height: 10),
        if (total > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final isActive = _currentPage == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.neonCyan
                      : AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildApiBanner(BannerModel b) {
    return GestureDetector(
      onTap: () => _onBannerTap(b.actionValue),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: b.imageUrl.isEmpty
              ? const LinearGradient(
                  colors: [Color(0xFF0D2233), Color(0xFF1A3A4A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: b.imageUrl.isNotEmpty ? const Color(0xFF0D2233) : null,
          border: Border.all(
            color: AppColors.neonCyan.withOpacity(0.2)),
          image: b.imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(b.imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.neonCyan.withOpacity(0.3)),
              ),
              child: Text(
                _actionLabel(b.actionValue),
                style: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColors.neonCyan, letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(b.title,
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Colors.white, height: 1.2,
              ),
            ),
            if (b.subtitle.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(b.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.white70)),
            ],
          ],
        ),
      ),
    );
  }

  String _actionLabel(String action) {
    const labels = {
      'previous_year': 'PREV YEAR',
      'premium':       'PREMIUM',
      'mcq':           'MCQ',
      'leaderboard':   'LEADERBOARD',
      'shorts':        'SHORTS',
      'tricks':        'TRICKS',
      'solve_earn':    'CONTEST',
    };
    return labels[action] ?? action.toUpperCase();
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.darkBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: Text('Tunnl',
                style: GoogleFonts.orbitron(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan, letterSpacing: 4)),
            ),
            if (_userName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(_userName,
                  style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary)),
              ),
            if (_isPremium)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.orange.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                        color: AppColors.orange, size: 14),
                      const SizedBox(width: 6),
                      Text('Premium Member',
                        style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.orange)),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 16),

            Divider(color: AppColors.textMuted.withOpacity(0.15)),
            const SizedBox(height: 8),

            _drawerTile(Icons.home_rounded, 'Home',
              () => Navigator.pop(context)),
            _drawerTile(Icons.person_rounded, 'Profile', () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ProfileScreen()));
            }),
            _drawerTile(Icons.dashboard_rounded, 'Dashboard', () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DashboardScreen()));
            }),
            _drawerTile(Icons.play_circle_rounded, 'Shorts', () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ShortsScreen()));
            }),
            _drawerTile(Icons.bar_chart_rounded, 'Leaderboard', () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LeaderboardScreen()));
            }),
            if (!_isPremium)
              _drawerTile(
                Icons.workspace_premium_rounded, 'Upgrade to Premium',
                () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PremiumScreen())).then((_) {
                      if (mounted) _loadAll();
                    });
                },
                color: AppColors.orange,
              ),

            const Spacer(),
            Divider(color: AppColors.textMuted.withOpacity(0.15)),

            if (_isLoggedIn)
              _drawerTile(
                Icons.logout_rounded, 'Logout',
                () async {
                  Navigator.pop(context);
                  await AuthService.logout();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                },
                color: AppColors.error,
              )
            else
              _drawerTile(
                Icons.login_rounded, 'Login',
                () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LoginScreen()));
                },
                color: AppColors.neonCyan,
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Text(AppConstants.appVersion,
                style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(
    IconData icon, String label, VoidCallback onTap, {
    Color color = AppColors.neonCyan,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
        style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w500,
          color: color == AppColors.neonCyan ? Colors.white : color)),
      onTap: onTap,
      horizontalTitleGap: 8,
    );
  }

  Widget _buildBottomTagline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 30, height: 1,
            color: AppColors.neonCyan.withOpacity(0.3)),
          const SizedBox(width: 10),
          Text('Enter the Tunnel. Master Speed Math.',
            style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(width: 10),
          Container(width: 30, height: 1,
            color: AppColors.neonCyan.withOpacity(0.3)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// HUB CARD
// ─────────────────────────────────────────────────────
class _HubCard extends StatefulWidget {
  final String title, subtitle;
  final Color  borderColor, iconBgColor, iconColor, titleColor;
  final IconData icon;
  final String?  priceBadge;
  final VoidCallback onTap;

  const _HubCard({
    required this.title,    required this.subtitle,
    required this.borderColor, required this.iconBgColor,
    required this.icon,     required this.iconColor,
    required this.titleColor, required this.onTap,
    this.priceBadge,
  });

  @override
  State<_HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<_HubCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97, upperBound: 1.0, value: 1.0,
    );
  }

  @override
  void dispose() { _tapCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _tapCtrl.reverse(),
      onTapUp:     (_) { _tapCtrl.forward(); widget.onTap(); },
      onTapCancel: ()  => _tapCtrl.forward(),
      child: ScaleTransition(
        scale: _tapCtrl,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.borderColor.withOpacity(0.25), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: widget.iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: widget.titleColor)),
                    const SizedBox(height: 3),
                    Text(widget.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (widget.priceBadge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.orange.withOpacity(0.4)),
                  ),
                  child: Text(widget.priceBadge!,
                    style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.orange)),
                ),
              ] else
                const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}