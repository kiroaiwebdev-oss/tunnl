// lib/features/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/content_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/app_strings.dart';
import '../hub/hub_screen.dart';
import '../history/history_screen.dart';
import '../premium/premium_screen.dart';
import 'edit_profile_screen.dart';

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
  String _profileImage = '';
  String _memberSince = '';
  bool   _isPremium   = false;
  bool   _isLoading   = true;

  // ── Stats (from API) ──────────────────────────────
  int    _totalAttempted = 0;
  int    _correctAnswers = 0;
  int    _wrongAnswers   = 0;
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
        _name         = user['name']         as String? ?? '';
        _phone        = user['phone']        as String? ?? '';
        _standard     = user['standard']     as String? ?? '';
        _profileImage = user['profile_image'] as String? ?? '';
        _memberSince  = _formatDate(user['created_at'] as String? ?? '');
        _isPremium    = user['is_premium'] == true || user['is_premium'] == 1;

        _rank           = int.tryParse('${user['rank_position']}')  ?? 0;
        _currentStreak  = int.tryParse('${user['current_streak']}') ?? 0;
        _totalXP        = int.tryParse('${user['total_xp']}')       ?? 0;

        _totalAttempted = int.tryParse('${stats['total_questions']}') ??
            (int.tryParse('${stats['total_tests']}') ?? 0);
        _correctAnswers = int.tryParse('${stats['total_correct']}') ?? 0;
        _wrongAnswers   = int.tryParse('${stats['total_wrong']}')   ?? 0;
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
          side: BorderSide(color: color.withValues(alpha: 0.4), width: 1),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Open full-page editor ─────────────────────────
  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName:     _name,
          initialStandard: _standard,
          initialImageUrl: _profileImage,
          phone:           _phone,
        ),
      ),
    );
    // EditProfileScreen pops `true` on a successful save.
    if (updated == true && mounted) {
      await _loadFromApi();
    }
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
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text(tr('Notification Settings'),
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white)),
              const SizedBox(height: 6),
              Text(tr('Manage your alerts & reminders'),
                style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              _NotifTile(
                title: tr('Daily Practice Reminder'),
                subtitle: tr('Remind me to practice every day'),
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
                title: tr('Weekly Challenge Alert'),
                subtitle: tr('Notify when new challenge starts'),
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
                title: tr('Result Announcements'),
                subtitle: tr('Solve & Earn winner results'),
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
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10)),
            )),
            const SizedBox(height: 20),
            Text(tr('Help & Support'),
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Colors.white)),
            const SizedBox(height: 20),

            _SupportTile(
              icon: Icons.email_rounded,
              color: AppColors.neonCyan,
              title: tr('Email Us'),
              subtitle: 'support@tunnel.app',
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'support@tunnel.app',
                  query: 'subject=Tunnl App Support',
                );
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
            ),

            _SupportTile(
              icon: Icons.chat_bubble_rounded,
              color: AppColors.success,
              title: tr('WhatsApp Support'),
              subtitle: tr('Chat with us on WhatsApp'),
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
              title: tr('Report a Technical Error'),
              subtitle: tr('Tell us about a technical issue'),
              onTap: () {
                Navigator.pop(context);
                _showReportError();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Language picker (English / Hindi) ─────────────
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10)),
            )),
            const SizedBox(height: 18),
            Text(tr('App Language'),
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(tr('Switch the whole app. Questions show in this language by default.'),
              style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            _langOption('English', false),
            const SizedBox(height: 10),
            _langOption('हिंदी (Hindi)', true),
          ],
        ),
      ),
    );
  }

  Widget _langOption(String label, bool hi) {
    final selected = LanguageService.instance.isHindi == hi;
    return GestureDetector(
      onTap: () async {
        await LanguageService.instance.setHindi(hi);
        if (!mounted) return;
        Navigator.pop(context);
        // Rebuild the whole app in the new language so every already-open
        // screen updates immediately (not just newly-pushed ones).
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HubScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => false,
        );
        _showSnack(hi ? 'भाषा हिंदी कर दी गई' : 'Language set to English');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.neonCyan.withValues(alpha: 0.12)
              : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.neonCyan.withValues(alpha: 0.5)
                : AppColors.textMuted.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.neonCyan : AppColors.textMuted,
              size: 20),
            const SizedBox(width: 12),
            Text(label,
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ── Report a technical error ──────────────────────
  void _showReportError() {
    final controller = TextEditingController();
    bool submitting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.orange.withValues(alpha: 0.4))),
          title: Text(tr('Report a Technical Error'),
            style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('Describe the problem you faced. Our team will look into it.'),
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 500,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: tr('e.g. App crashes when opening Previous Year...'),
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: Text(tr('Cancel'),
                style: GoogleFonts.poppins(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final msg = controller.text.trim();
                      if (msg.isEmpty) {
                        _showSnack(tr('Please describe the issue.'));
                        return;
                      }
                      setLocal(() => submitting = true);
                      final ok =
                          await ContentService.submitTechReport(msg);
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      _showSnack(ok
                          ? tr('Thank you! Your report was submitted.')
                          : tr('Could not submit. Please try again.'));
                    },
              child: Text(submitting ? tr('Sending...') : tr('Submit'),
                style: GoogleFonts.poppins(
                  color: AppColors.orange, fontWeight: FontWeight.w700)),
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
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4))),
        title: Text(tr('Logout?'),
          style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(tr('Are you sure you want to logout?'),
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Cancel'),
              style: GoogleFonts.poppins(color: AppColors.neonCyan)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Logout'),
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
          Text(tr('PROFILE'),
            style: GoogleFonts.orbitron(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.neonCyan, letterSpacing: 2)),
          const Spacer(),
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.2)),
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
          color: AppColors.neonCyan.withValues(alpha: 0.15), width: 1.2),
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
                            AppColors.neonCyan.withValues(alpha: 0.3),
                            AppColors.neonCyan.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.neonCyan.withValues(alpha: 0.5),
                          width: 2),
                      ),
                      child: ClipOval(
                        child: _profileImage.isNotEmpty
                            ? Image.network(
                                _profileImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    _name.isNotEmpty
                                        ? _name[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.orbitron(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.neonCyan),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  _name.isNotEmpty
                                      ? _name[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.orbitron(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.neonCyan),
                                ),
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
                            child: Text(_name.isNotEmpty ? _name : tr('Loading...'),
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
                                color: AppColors.yellow.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.yellow.withValues(alpha: 0.4))),
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
                            Text('${tr('Member since')} $_memberSince',
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
        'label': tr('RANK'),
        'value': _rank > 0 ? '#$_rank' : '—',
        'icon': Icons.emoji_events_rounded,
        'color': AppColors.yellow,
      },
      {
        'label': tr('XP'),
        'value': '$_totalXP',
        'icon': Icons.bolt_rounded,
        'color': AppColors.neonCyan,
      },
      {
        'label': tr('STREAK'),
        'value': '$_currentStreak🔥',
        'icon': Icons.local_fire_department_rounded,
        'color': AppColors.orange,
      },
      {
        'label': tr('ACCURACY'),
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
              border: Border.all(color: color.withValues(alpha: 0.15)),
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
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('PERFORMANCE'),
            style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PerfItem(label: tr('Attempted'),
                value: '$_totalAttempted', color: AppColors.neonCyan),
              _VertDivider(),
              _PerfItem(label: tr('Correct'),
                value: '$_correctAnswers', color: AppColors.success),
              _VertDivider(),
              _PerfItem(
                label: tr('Wrong'),
                value: '$_wrongAnswers',
                color: AppColors.error),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _accuracy / 100,
              backgroundColor: AppColors.error.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('Accuracy'),
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
      onTap: _isPremium ? null : () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
        // Came back from premium screen — refresh profile so the
        // "Unlock Premium" card flips to "TUNNL PREMIUM" if upgrade succeeded.
        if (mounted) await _loadFromApi();
      },
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
                ? AppColors.yellow.withValues(alpha: 0.4)
                : AppColors.textMuted.withValues(alpha: 0.2),
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
                    ? AppColors.yellow.withValues(alpha: 0.15)
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
                    _isPremium ? tr('TUNNL PREMIUM') : tr('Unlock Premium'),
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: _isPremium ? AppColors.yellow : Colors.white)),
                  Text(
                    _isPremium
                        ? tr('Full access — Lifetime')
                        : '${tr('Get complete access @')} ₹${AppSettingsService.instance.getInt('premium_price', 50)}',
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
                child: Text('₹${AppSettingsService.instance.getInt('premium_price', 50)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.darkBg)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Text(tr('ACTIVE'),
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
        'label': tr('Test History'),
        'subtitle': tr('View all past tests'),
        'color': AppColors.neonCyan,
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HistoryScreen())),
      },
      {
        'icon': Icons.notifications_rounded,
        'label': tr('Notifications'),
        'subtitle': tr('Manage alerts & reminders'),
        'color': AppColors.orange,
        'onTap': _showNotificationSettings,
      },
      {
        'icon': Icons.language_rounded,
        'label': tr('Language'),
        'subtitle': LanguageService.instance.isHindi ? 'हिंदी (Hindi)' : 'English',
        'color': AppColors.neonCyan,
        'onTap': _showLanguagePicker,
      },
      {
        'icon': Icons.bug_report_rounded,
        'label': tr('Report a Technical Error'),
        'subtitle': tr('Tell us about a technical issue'),
        'color': AppColors.orange,
        'onTap': _showReportError,
      },
      {
        'icon': Icons.help_rounded,
        'label': tr('Help & Support'),
        'subtitle': tr('Get help from our team'),
        'color': AppColors.textSecondary,
        'onTap': _showHelpSupport,
      },
      {
        'icon': Icons.info_rounded,
        'label': tr('App Version'),
        'subtitle': '${AppConstants.appVersion} — ${tr('Latest')}',
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
                color: AppColors.textMuted.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
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
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text(tr('LOGOUT'),
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
      color: AppColors.textMuted.withValues(alpha: 0.2),
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
              shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
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
            inactiveTrackColor: AppColors.textMuted.withValues(alpha: 0.2),
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
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
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
              color: color.withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }
}
