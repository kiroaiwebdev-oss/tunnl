import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/content_service.dart';
import '../../core/services/user_service.dart';
import '../../core/models/banner_model.dart';
import '../hub/hub_screen.dart';
import '../daily_dose/daily_dose_popup.dart';
import '../solve_earn/solve_earn_leaderboard_screen.dart';
import '../solve_earn/solve_earn_screen.dart';
import '../profile/profile_screen.dart';
import '../sets/sets_screen.dart';
import '../tricks/tricks_screen.dart';
import '../shorts/shorts_screen.dart';
import '../previous_year/previous_year_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../history/history_screen.dart';
import '../premium/premium_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int  _selectedTab = 0;
  bool _isPremium   = false;
  bool _isLoadingUser = true;

  // ── User data ─────────────────────────────────────
  String _userName    = '';
  int    _totalXp     = 0;
  int    _streak      = 0;

  // ── Banners ───────────────────────────────────────
  List<BannerModel> _banners     = [];
  bool _bannersLoading = true;
  int  _currentBanner  = 0;

  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;

  final List<Map<String, dynamic>> _coreItems = [
    {
      'title':       'TUNNL TRICKS',
      'subtitle':    'Learn powerful strategies & tricks',
      'icon':        Icons.layers_rounded,
      'iconBg':      const Color(0xFF0D2233),
      'iconColor':   AppColors.neonCyan,
      'borderColor': AppColors.neonCyan,
      'titleColor':  Colors.white,
    },
    {
      'title':       '5000 SPEED MATH\nMCQS',
      'subtitle':    'Practice unlimited MCQs',
      'icon':        Icons.quiz_rounded,
      'iconBg':      const Color(0xFF1A1040),
      'iconColor':   const Color(0xFF9C6FFF),
      'borderColor': const Color(0xFF4A1A8A),
      'titleColor':  Colors.white,
    },
    {
      'title':       '500 FREQUENTLY\nASKED SIMPLIFICATION',
      'subtitle':    'Master simplification',
      'icon':        Icons.functions_rounded,
      'iconBg':      const Color(0xFF0D2233),
      'iconColor':   AppColors.neonCyan,
      'borderColor': AppColors.neonCyan,
      'titleColor':  Colors.white,
    },
    {
      'title':       'SHORTS',
      'subtitle':    'Watch quick math tips',
      'icon':        Icons.play_circle_rounded,
      'iconBg':      const Color(0xFF2A1515),
      'iconColor':   const Color(0xFFFF6B6B),
      'borderColor': const Color(0xFF3A1A1A),
      'titleColor':  Colors.white,
    },
    {
      'title':       'DAILY PRACTICE\nMCQS',
      'subtitle':    'Daily challenge sets',
      'icon':        Icons.calendar_today_rounded,
      'iconBg':      const Color(0xFF0D2233),
      'iconColor':   AppColors.neonCyan,
      'borderColor': AppColors.neonCyan,
      'titleColor':  Colors.white,
    },
    {
      'title':       'PREVIOUS YEAR\nQUESTIONS',
      'subtitle':    'Complete PYQ access',
      'icon':        Icons.history_edu_rounded,
      'iconBg':      const Color(0xFF1A1040),
      'iconColor':   const Color(0xFF9C6FFF),
      'borderColor': const Color(0xFF4A1A8A),
      'titleColor':  Colors.white,
    },
    {
      'title':       'SOLVE & EARN',
      'subtitle':    'Earn rewards by solving quizzes',
      'icon':        Icons.card_giftcard_rounded,
      'iconBg':      const Color(0xFF1A1A00),
      'iconColor':   AppColors.yellow,
      'borderColor': const Color(0xFF3A3A00),
      'titleColor':  AppColors.yellow,
    },
  ];

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

    _loadAll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      DailyDosePopup.show(context);
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Load everything in parallel ───────────────────
  Future<void> _loadAll() async {
    await Future.wait([
      _loadUserProfile(),
      _loadBanners(),
    ]);
  }

  // ── User profile from API ─────────────────────────
  Future<void> _loadUserProfile() async {
    try {
      final res = await UserService.getProfile();
      if (!mounted) return;

      if (res['success'] == true || res['status'] == true) {
        final user = res['data']?['user'];
        if (user != null) {
          setState(() {
            _isPremium  = user['is_premium'] == true || user['is_premium'] == 1;
            _userName   = user['name']           ?? '';
            _totalXp    = (user['total_xp']   as num?)?.toInt() ?? 0;
            _streak     = (user['current_streak'] as num?)?.toInt() ?? 0;
            _isLoadingUser = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback to cached prefs if API fails
    final isPremium = await AuthService.isPremium();
    if (mounted) {
      setState(() {
        _isPremium     = isPremium;
        _isLoadingUser = false;
      });
    }
  }

  // ── Banners from API ──────────────────────────────
  Future<void> _loadBanners() async {
    try {
      final banners = await ContentService.getBanners();
      if (mounted) {
        setState(() {
          _banners        = banners;
          _bannersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _bannersLoading = false);
    }
  }

  // ── Logout ────────────────────────────────────────
  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _goToPremium() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    );
    // User came back — refresh in case they upgraded.
    if (mounted) await _loadAll();
  }

  // ── Dashboard item tap ────────────────────────────
  void _onItemTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TricksScreen(isPremium: _isPremium),
        ));
        break;
      case 1:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SetsScreen(
            title: '5000 Speed Math MCQs',
            category: 'mcq',
            questionsPerSet: 20,
            totalSets: _isPremium ? 100 : 10,
            showLeaderboard: true,
          ),
        ));
        break;
      case 2:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SetsScreen(
            title: '500 Simplification',
            category: 'simplification',
            questionsPerSet: 20,
            totalSets: _isPremium ? 10 : 1,
            showLeaderboard: false,
          ),
        ));
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ShortsScreen(),
        ));
        break;
      case 4:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SetsScreen(
            title: 'Daily Practice MCQs',
            category: 'daily',
            questionsPerSet: 20,
            totalSets: _isPremium ? 30 : 1,
            showLeaderboard: false,
            subtitle: _isPremium ? 'All daily sets' : "Today's set — Free",
          ),
        ));
        break;
      case 5:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PreviousYearScreen(isPremium: _isPremium),
        ));
        break;
      case 6:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const SolveEarnScreen(),
        ));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.darkBg,
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashBg),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: RefreshIndicator(
                    // Pull-to-refresh
                    color: AppColors.neonCyan,
                    backgroundColor: const Color(0xFF0D2233),
                    onRefresh: _loadAll,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── User greeting ─────────────
                          if (!_isLoadingUser) _buildUserGreeting(),
                          if (_isLoadingUser)
                            _buildGreetingShimmer(),

                          const SizedBox(height: 20),

                          // ── Banners ───────────────────
                          if (_bannersLoading)
                            _buildBannerShimmer()
                          else if (_banners.isNotEmpty)
                            _buildBannerCarousel(),

                          if (_banners.isNotEmpty)
                            const SizedBox(height: 20),

                          // ── Heading ───────────────────
                          _buildHeading(),
                          const SizedBox(height: 6),
                          _buildSubHeading(),
                          const SizedBox(height: 24),

                          // ── Dashboard items ───────────
                          ..._coreItems.asMap().entries.map((entry) {
                            return _DashboardItem(
                              data:  entry.value,
                              onTap: () => _onItemTap(entry.key),
                            );
                          }),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── USER GREETING ─────────────────────────────────
  Widget _buildUserGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' :
                     hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final firstName = _userName.isNotEmpty
        ? _userName.split(' ').first
        : 'Mathletes';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                firstName,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // XP + streak row
        Row(
          children: [
            if (_streak > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${_streak}d',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                    color: AppColors.neonCyan, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '$_totalXp XP',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neonCyan,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── SHIMMER GREETING ──────────────────────────────
  Widget _buildGreetingShimmer() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBox(80, 12),
            const SizedBox(height: 6),
            _shimmerBox(140, 18),
          ],
        ),
      ],
    );
  }

  // ── BANNER CAROUSEL ───────────────────────────────
  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _currentBanner = i),
            itemBuilder: (_, i) {
              final b = _banners[i];
              return Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF0D2233),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.15),
                  ),
                  image: b.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(b.imageUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.35),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      b.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (b.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        b.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        if (_banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width:  _currentBanner == i ? 16 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: _currentBanner == i
                      ? AppColors.neonCyan
                      : AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  // ── BANNER SHIMMER ────────────────────────────────
  Widget _buildBannerShimmer() {
    return _shimmerBox(double.infinity, 130, radius: 16);
  }

  // ── SHIMMER HELPER ────────────────────────────────
  Widget _shimmerBox(double w, double h, {double radius = 8}) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu_rounded,
              color: Colors.white, size: 26),
          ),
          Text(
            'Tunnl',
            style: GoogleFonts.orbitron(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.neonCyan, letterSpacing: 3,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkCard,
                border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              // Show first letter of name
              child: _userName.isNotEmpty
                  ? Center(
                      child: Text(
                        _userName[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonCyan,
                        ),
                      ),
                    )
                  : const Icon(Icons.person_rounded,
                      color: AppColors.textSecondary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── DRAWER ────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.darkBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: Text(
                'Tunnl',
                style: GoogleFonts.orbitron(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan, letterSpacing: 4,
                ),
              ),
            ),

            // User name + XP in drawer
            if (_userName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _userName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

            if (_isPremium)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                        color: AppColors.orange, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Premium Member',
                        style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 16),

            Divider(color: AppColors.textMuted.withValues(alpha: 0.15)),
            const SizedBox(height: 8),

            _drawerTile(Icons.home_rounded, 'Home', () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HubScreen()),
                (route) => false,
              );
            }),
            _drawerTile(Icons.play_circle_rounded, 'Shorts', () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ShortsScreen()));
            }),
            _drawerTile(Icons.bar_chart_rounded, 'Leaderboard', () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
            }),
            _drawerTile(Icons.history_rounded, 'History', () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()));
            }),
            _drawerTile(Icons.person_rounded, 'Profile', () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),

            if (!_isPremium)
              _drawerTile(
                Icons.workspace_premium_rounded,
                'Upgrade to Premium',
                () { Navigator.pop(context); _goToPremium(); },
                color: AppColors.orange,
              ),

            const Spacer(),

            Divider(color: AppColors.textMuted.withValues(alpha: 0.15)),
            _drawerTile(
              Icons.logout_rounded, 'Logout',
              () { Navigator.pop(context); _logout(); },
              color: AppColors.error,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Text(
                AppConstants.appVersion,
                style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textMuted,
                ),
              ),
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
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w500,
          color: color == AppColors.neonCyan ? Colors.white : color,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
    );
  }

  Widget _buildHeading() {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white,
        ),
        children: [
          const TextSpan(text: 'What to '),
          TextSpan(
            text: 'Explore?',
            style: GoogleFonts.poppins(
              fontSize: 28, fontWeight: FontWeight.w700,
              color: AppColors.neonCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 130, height: 2.5,
          decoration: BoxDecoration(
            color: AppColors.neonCyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Dive into the high-dimensional logic of the\nmathematical void. Select a node to begin.',
          style: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textSecondary, height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final tabs = [
      {'icon': Icons.menu_book_rounded, 'label': 'LEARN'},
      {'icon': Icons.calculate_rounded, 'label': 'PRACTICE'},
      {'icon': Icons.bar_chart_rounded, 'label': 'RANK'},
      {'icon': Icons.person_rounded,    'label': 'PROFILE'},
    ];

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        border: Border(
          top: BorderSide(
            color: AppColors.textMuted.withValues(alpha: 0.15), width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.asMap().entries.map((entry) {
          final i        = entry.key;
          final tab      = entry.value;
          final isActive = _selectedTab == i;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedTab = i);
              switch (i) {
                case 0: break;
                case 1:
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SetsScreen(
                      title: '5000 Speed Math MCQs',
                      category: 'mcq',
                      subtitle: 'Practice for Speed & Accuracy',
                      totalSets: _isPremium ? 100 : 10,
                      questionsPerSet: 20,
                      showLeaderboard: true,
                    ),
                  ));
                  break;
                case 2:
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SolveEarnLeaderboardScreen(),
                  ));
                  break;
                case 3:
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ));
                  break;
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  i == 1
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.neonCyan
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [BoxShadow(
                                    color: AppColors.neonCyan.withValues(alpha: 0.4),
                                    blurRadius: 14, spreadRadius: 2,
                                  )]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Σ',
                              style: GoogleFonts.poppins(
                                fontSize: 20, fontWeight: FontWeight.w700,
                                color: isActive
                                    ? AppColors.darkBg
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          tab['icon'] as IconData,
                          color: isActive
                              ? AppColors.neonCyan
                              : AppColors.textMuted,
                          size: 22,
                        ),
                  const SizedBox(height: 3),
                  Text(
                    tab['label'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive
                          ? AppColors.neonCyan
                          : AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── DASHBOARD ITEM ────────────────────────────────────
class _DashboardItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback         onTap;

  const _DashboardItem({required this.data, required this.onTap});

  @override
  State<_DashboardItem> createState() => _DashboardItemState();
}

class _DashboardItemState extends State<_DashboardItem>
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
    final data        = widget.data;
    final borderColor = data['borderColor'] as Color;
    final iconBg      = data['iconBg']      as Color;
    final iconColor   = data['iconColor']   as Color;
    final titleColor  = data['titleColor']  as Color;

    return GestureDetector(
      onTapDown:   (_) => _tapCtrl.reverse(),
      onTapUp:     (_) { _tapCtrl.forward(); widget.onTap(); },
      onTapCancel: ()  => _tapCtrl.forward(),
      child: ScaleTransition(
        scale: _tapCtrl,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.2), width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data['icon'] as IconData,
                  color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: titleColor, height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data['subtitle'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
