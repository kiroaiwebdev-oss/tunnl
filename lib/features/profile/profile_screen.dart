// lib/features/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../hub/hub_screen.dart';
import '../history/history_screen.dart';
import '../premium/premium_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // ── User data ─────────────────────────────────────
  String _name        = '';
  String _phone       = '';
  String _standard    = '';
  String _memberSince = '';
  bool   _isPremium   = false;
  bool   _isLoading   = true;

  // ── Stats (from API) ──────────────────────────────
  int    _totalAttempted = 0;
  int    _correctAnswers = 0;
  int    _totalXP        = 0;
  int    _currentStreak  = 0;
  int    _rank           = 0;
  double _accuracy       = 0.0;

  // ── Notification prefs (local) ────────────────────
  bool _notifDaily     = true;
  bool _notifChallenge = true;
  bool _notifResults   = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAll();
  }

  void _setupAnimations() {
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim  = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
  }

  // ── Load everything ───────────────────────────────
  Future<void> _loadAll() async {
    await Future.wait([
      _loadFromApi(),
      _loadNotifPrefs(),
    ]);
  }

  // ── ✅ FIXED: 'success' check + correct data parsing ──
Future<void> _loadFromApi() async {
  try {
    final profileRes = await UserService.getProfile();

    if (!mounted) return;

    // ✅ PHP 'success' bhejta hai
    if (profileRes['success'] == true || profileRes['status'] == true) {
      final user  = profileRes['data']?['user']  as Map<String, dynamic>? ?? {};
      final stats = profileRes['data']?['stats'] as Map<String, dynamic>? ?? {};

      setState(() {
        _name        = user['name']        as String? ?? '';
        _phone       = user['phone']       as String? ?? '';
        _standard    = user['standard']    as String? ?? '';
        _memberSince = _formatDate(user['created_at'] as String? ?? '');
        _isPremium   = user['is_premium'] == true || user['is_premium'] == 1;

        _rank           = int.tryParse('${user['rank_position']}')  ?? 0;
        _currentStreak  = int.tryParse('${user['current_streak']}') ?? 0;
        _totalXP        = int.tryParse('${user['total_xp']}')       ?? 0;

        _totalAttempted = int.tryParse('${stats['total_tests']}')   ?? 0;
        _correctAnswers = int.tryParse('${stats['total_correct']}') ?? 0;
        _accuracy       = double.tryParse('${stats['avg_accuracy']}') ?? 0.0;
      });

      await AuthService.setPremium(_isPremium);

    } else {
      await _loadFromCache();
    }

  } catch (e) {
    await _loadFromCache();
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  // ── Cache fallback ────────────────────────────────
  Future<void> _loadFromCache() async {
    final name      = await AuthService.getCachedName();
    final phone     = await AuthService.getCachedPhone();
    final standard  = await AuthService.getCachedStandard();
    final isPremium = await AuthService.isPremium();
    if (mounted) {
      setState(() {
        _name      = name;
        _phone     = phone;
        _standard  = standard;
        _isPremium = isPremium;
        _isLoading = false;
      });
    }
  }

  // ── Notification prefs ────────────────────────────
  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifDaily     = prefs.getBool('notif_daily')     ?? true;
        _notifChallenge = prefs.getBool('notif_challenge') ?? true;
        _notifResults   = prefs.getBool('notif_results')   ?? false;
      });
    }
  }

  // ── Format date helper ────────────────────────────
  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '', 'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August', 'September',
        'October', 'November', 'December'
      ];
      return '${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  // ── Snackbar ──────────────────────────────────────
  void _showSnack(String msg, {Color color = AppColors.neonCyan}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.darkCard,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.4), width: 1),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Edit profile sheet (name + class/exam) ────────
  void _showNameChangeDialog() {
    _showEditProfileSheet();
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _name);
    String? selectedStandard = _standard.isNotEmpty ? _standard : null;
    bool isSaving = false;

    const standards = [
      'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
      'Class 11', 'Class 12',
      'SSC / Railway', 'Banking', 'UPSC', 'Other Competitive',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 20, 24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Edit Profile',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Update your name & class/exam',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  Text('Your Name',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: GoogleFonts.poppins(color: Colors.white),
                    cursorColor: AppColors.neonCyan,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: GoogleFonts.poppins(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.person_rounded,
                          color: AppColors.neonCyan, size: 18),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppColors.neonCyan.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.neonCyan, width: 1.5),
                      ),
                      filled: true,
                      fillColor: AppColors.darkBg,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Class / Exam',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: standards.map((s) {
                      final selected = selectedStandard == s;
                      return GestureDetector(
                        onTap: () => setS(() => selectedStandard = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.neonCyan.withOpacity(0.15)
                                : AppColors.darkBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.neonCyan
                                  : AppColors.neonCyan.withOpacity(0.1),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(s,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected
                                      ? AppColors.neonCyan
                                      : AppColors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.darkBg,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonCyan,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final newName = nameCtrl.text.trim();
                                  if (newName.isEmpty) {
                                    _showSnack('Please enter your name',
                                        color: AppColors.error);
                                    return;
                                  }
                                  setS(() => isSaving = true);

                                  final ok = await UserService.updateProfile(
                                    name: newName,
                                    standard: selectedStandard,
                                  );

                                  if (!mounted) return;
                                  Navigator.pop(ctx);

                                  if (ok) {
                                    setState(() {
                                      _name = newName;
                                      _standard = selectedStandard ?? '';
                                    });
                                    _showSnack('Profile updated!');
                                  } else {
                                    _showSnack(
                                        'Failed to update. Try again.',
                                        color: AppColors.error);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text('Save',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.darkBg,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Notification settings ─────────────────────────
  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Notification Settings',
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white)),
              const SizedBox(height: 6),
              Text('Manage your alerts & reminders',
                style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              _NotifTile(
                title: 'Daily Practice Reminder',
                subtitle: 'Remind me to practice every day',
                icon: Icons.today_rounded,
                color: AppColors.neonCyan,
                value: _notifDaily,
                onChanged: (v) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('notif_daily', v);
                  setS(() => _notifDaily = v);
                  setState(() => _notifDaily = v);
                },
              ),

              _NotifTile(
                title: 'Weekly Challenge Alert',
                subtitle: 'Notify when new challenge starts',
                icon: Icons.emoji_events_rounded,
                color: AppColors.yellow,
                value: _notifChallenge,
                onChanged: (v) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('notif_challenge', v);
                  setS(() => _notifChallenge = v);
                  setState(() => _notifChallenge = v);
                },
              ),

              _NotifTile(
                title: 'Result Announcements',
                subtitle: 'Solve & Earn winner results',
                icon: Icons.campaign_rounded,
                color: AppColors.orange,
                value: _notifResults,
                onChanged: (v) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('notif_results', v);
                  setS(() => _notifResults = v);
                  setState(() => _notifResults = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Privacy policy ────────────────────────────────
  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: ListView(
            controller: controller,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10)),
              )),
              const SizedBox(height: 20),
              Text('Privacy Policy',
                style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: Colors.white)),
              const SizedBox(height: 16),
              Text(
                'TUNNEL collects minimal user data including phone number and '
                'test performance to provide a personalized learning experience.\n\n'
                'Your data is never shared with third parties without your '
                'consent. All test history and scores are stored securely.\n\n'
                'We use your performance data only to improve your learning '
                'experience and show relevant content.\n\n'
                'You can request account deletion by contacting our support team.\n\n'
                'For any privacy concerns, contact: support@tunnel.app',
                style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Help & support ────────────────────────────────
  void _showHelpSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10)),
            )),
            const SizedBox(height: 20),
            Text('Help & Support',
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Colors.white)),
            const SizedBox(height: 20),

            _SupportTile(
              icon: Icons.email_rounded,
              color: AppColors.neonCyan,
              title: 'Email Us',
              subtitle: 'support@tunnel.app',
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'support@tunnel.app',
                  query: 'subject=TUNNEL App Support',
                );
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
            ),

            _SupportTile(
              icon: Icons.chat_bubble_rounded,
              color: AppColors.success,
              title: 'WhatsApp Support',
              subtitle: 'Chat with us on WhatsApp',
              onTap: () async {
                Navigator.pop(context);
                // Replace with your WhatsApp number
                final uri = Uri.parse('https://wa.me/919876543210');
                if (await canLaunchUrl(uri)) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),

            _SupportTile(
              icon: Icons.bug_report_rounded,
              color: AppColors.orange,
              title: 'Report a Bug',
              subtitle: 'Help us improve the app',
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'support@tunnel.app',
                  query: 'subject=Bug Report — TUNNEL App',
                );
                if (await canLaunchUrl(uri)) launchUrl(uri);
                _showSnack('Thank you! Bug reported.');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout ────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.error.withOpacity(0.4))),
        title: Text('Logout?',
          style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to logout?',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
              style: GoogleFonts.poppins(color: AppColors.neonCyan)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout',
              style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // ✅ AuthService.logout() — server call + prefs clear
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HubScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    }
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
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.neonCyan,
                      backgroundColor: const Color(0xFF0D2233),
                      onRefresh: _loadAll,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _buildProfileHero(),
                            const SizedBox(height: 16),
                            _buildStatsRow(),
                            const SizedBox(height: 16),
                            _buildPerformanceCard(),
                            const SizedBox(height: 16),
                            _buildPremiumCard(),
                            const SizedBox(height: 16),
                            _buildMenuItems(),
                            const SizedBox(height: 20),
                            _buildLogoutButton(),
                            const SizedBox(height: 30),
                          ],
                        ),
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

  // ── APP BAR ───────────────────────────────────────
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
          Text('PROFILE',
            style: GoogleFonts.orbitron(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.neonCyan, letterSpacing: 2)),
          const Spacer(),
          GestureDetector(
            onTap: _showNameChangeDialog,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.neonCyan.withOpacity(0.2)),
              ),
              child: const Icon(Icons.edit_rounded,
                color: AppColors.neonCyan, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ── PROFILE HERO ──────────────────────────────────
  Widget _buildProfileHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.neonCyan.withOpacity(0.15), width: 1.2),
      ),
      child: _isLoading
          ? _shimmerRow()
          : Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.neonCyan.withOpacity(0.3),
                            AppColors.neonCyan.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.neonCyan.withOpacity(0.5),
                          width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                          style: GoogleFonts.orbitron(
                            fontSize: 28, fontWeight: FontWeight.w700,
                            color: AppColors.neonCyan),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2, right: 2,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                          border: Border.all(
                            color: AppColors.darkCard, width: 2)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(_name.isNotEmpty ? _name : 'Loading...',
                              style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.w700,
                                color: Colors.white),
                              overflow: TextOverflow.ellipsis),
                          ),
                          if (_isPremium) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.yellow.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.yellow.withOpacity(0.4))),
                              child: Text('PRO',
                                style: GoogleFonts.poppins(
                                  fontSize: 9, fontWeight: FontWeight.w700,
                                  color: AppColors.yellow)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (_phone.isNotEmpty) Row(
                        children: [
                          const Icon(Icons.phone_rounded,
                            size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(_phone,
                            style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      if (_memberSince.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                              size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('Member since $_memberSince',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── STATS ROW ─────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      {
        'label': 'RANK',
        'value': _rank > 0 ? '#$_rank' : '—',
        'icon': Icons.emoji_events_rounded,
        'color': AppColors.yellow,
      },
      {
        'label': 'XP',
        'value': '$_totalXP',
        'icon': Icons.bolt_rounded,
        'color': AppColors.neonCyan,
      },
      {
        'label': 'STREAK',
        'value': '$_currentStreak🔥',
        'icon': Icons.local_fire_department_rounded,
        'color': AppColors.orange,
      },
      {
        'label': 'ACCURACY',
        'value': '${_accuracy.toInt()}%',
        'icon': Icons.track_changes_rounded,
        'color': AppColors.success,
      },
    ];

    return Row(
      children: stats.map((s) {
        final color = s['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: _isLoading
                ? Column(children: [
                    _shimmerBox(20, 20),
                    const SizedBox(height: 6),
                    _shimmerBox(30, 12),
                    const SizedBox(height: 4),
                    _shimmerBox(24, 8),
                  ])
                : Column(
                    children: [
                      Icon(s['icon'] as IconData, color: color, size: 18),
                      const SizedBox(height: 6),
                      Text(s['value'] as String,
                        style: GoogleFonts.orbitron(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: color)),
                      const SizedBox(height: 2),
                      Text(s['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 8, color: AppColors.textSecondary,
                          letterSpacing: 1)),
                    ],
                  ),
          ),
        );
      }).toList(),
    );
  }

  // ── PERFORMANCE CARD ──────────────────────────────
  Widget _buildPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PERFORMANCE',
            style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PerfItem(label: 'Attempted',
                value: '$_totalAttempted', color: AppColors.neonCyan),
              _VertDivider(),
              _PerfItem(label: 'Correct',
                value: '$_correctAnswers', color: AppColors.success),
              _VertDivider(),
              _PerfItem(
                label: 'Wrong',
                value: '${_totalAttempted - _correctAnswers}',
                color: AppColors.error),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _accuracy / 100,
              backgroundColor: AppColors.error.withOpacity(0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Accuracy',
                style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
              Text('${_accuracy.toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  // ── PREMIUM CARD ──────────────────────────────────
  Widget _buildPremiumCard() {
    return GestureDetector(
      onTap: _isPremium ? null : () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isPremium
                ? [const Color(0xFF1A1400), const Color(0xFF2A2000)]
                : [const Color(0xFF0F1923), const Color(0xFF0A1520)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isPremium
                ? AppColors.yellow.withOpacity(0.4)
                : AppColors.textMuted.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPremium
                    ? AppColors.yellow.withOpacity(0.15)
                    : AppColors.darkBg,
              ),
              child: Icon(
                _isPremium
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_outline_rounded,
                color: _isPremium ? AppColors.yellow : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPremium ? 'TUNNEL PREMIUM' : 'Unlock Premium',
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: _isPremium ? AppColors.yellow : Colors.white)),
                  Text(
                    _isPremium
                        ? 'Full access — Lifetime'
                        : 'Get complete access @ ₹50',
                    style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (!_isPremium)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD600), Color(0xFFFF8F00)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('₹50',
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.darkBg)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3)),
                ),
                child: Text('ACTIVE',
                  style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.success, letterSpacing: 1)),
              ),
          ],
        ),
      ),
    );
  }

  // ── MENU ITEMS ────────────────────────────────────
  Widget _buildMenuItems() {
    final items = [
      {
        'icon': Icons.history_rounded,
        'label': 'Test History',
        'subtitle': 'View all past tests',
        'color': AppColors.neonCyan,
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HistoryScreen())),
      },
      {
        'icon': Icons.notifications_rounded,
        'label': 'Notifications',
        'subtitle': 'Manage alerts & reminders',
        'color': AppColors.orange,
        'onTap': _showNotificationSettings,
      },
      {
        'icon': Icons.privacy_tip_rounded,
        'label': 'Privacy Policy',
        'subtitle': 'Read our privacy policy',
        'color': AppColors.textSecondary,
        'onTap': _showPrivacyPolicy,
      },
      {
        'icon': Icons.help_rounded,
        'label': 'Help & Support',
        'subtitle': 'Get help from our team',
        'color': AppColors.textSecondary,
        'onTap': _showHelpSupport,
      },
      {
        'icon': Icons.info_rounded,
        'label': 'App Version',
        'subtitle': '${AppConstants.appVersion} — Latest',
        'color': AppColors.textSecondary,
        'onTap': null,
      },
    ];

    return Column(
      children: items.map((item) {
        final color = item['color'] as Color;
        final onTap = item['onTap'] as VoidCallback?;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.textMuted.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                  child: Icon(item['icon'] as IconData,
                    color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: Colors.white)),
                      Text(item['subtitle'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.textSecondary, size: 14),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── LOGOUT BUTTON ─────────────────────────────────
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        height: 54, width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.error.withOpacity(0.4), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text('LOGOUT',
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.error, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  // ── SHIMMER HELPERS ───────────────────────────────
  Widget _shimmerRow() {
    return Row(
      children: [
        _shimmerBox(70, 70, radius: 35),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBox(120, 16),
            const SizedBox(height: 8),
            _shimmerBox(90, 12),
            const SizedBox(height: 6),
            _shimmerBox(110, 10),
          ],
        ),
      ],
    );
  }

  Widget _shimmerBox(double w, double h, {double radius = 8}) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── HELPER WIDGETS ────────────────────────────────────
class _PerfItem extends StatelessWidget {
  final String label, value;
  final Color  color;

  const _PerfItem({
    required this.label, required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
          style: GoogleFonts.orbitron(
            fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(label,
          style: GoogleFonts.poppins(
            fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 40,
      color: AppColors.textMuted.withOpacity(0.2),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color  color;
  final bool   value;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.title, required this.subtitle,
    required this.icon,  required this.color,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: color.withOpacity(0.1)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: Colors.white)),
                Text(subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.neonCyan,
            inactiveTrackColor: AppColors.textMuted.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title, subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,  required this.color,
    required this.title, required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: color.withOpacity(0.1)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.white)),
                  Text(subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.5), size: 14),
          ],
        ),
      ),
    );
  }
}
