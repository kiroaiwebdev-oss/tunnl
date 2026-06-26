// lib/features/shorts/shorts_screen.dart
//
// Renders shorts pulled from admin/shorts.php

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_strings.dart';
import '../../core/services/content_service.dart';
import '../../core/models/short_model.dart';
import '../../core/widgets/in_app_video_player.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen>
    with SingleTickerProviderStateMixin {

  int _selectedFilter = 0;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;

  final List<String> _filters = ['ALL', 'YOUTUBE', 'INSTAGRAM', 'FACEBOOK', 'LOCAL'];

  List<ShortModel> _allShorts = [];
  bool _isLoading = true;

  List<ShortModel> get _filteredShorts {
    if (_selectedFilter == 0) return _allShorts;
    final filter = _filters[_selectedFilter];
    return _allShorts.where((s) => s.platform == filter).toList();
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'INSTAGRAM':
        return Icons.camera_alt_rounded;
      case 'LOCAL':
        return Icons.video_file_rounded;
      case 'FACEBOOK':
        return Icons.facebook;
      case 'TELEGRAM':
        return Icons.send_rounded;
      case 'YOUTUBE':
      default:
        return Icons.play_circle_rounded;
    }
  }

  Color _platformColor(String platform) {
    switch (platform) {
      case 'INSTAGRAM':
        return const Color(0xFFE1306C);
      case 'FACEBOOK':
        return const Color(0xFF1877F2);
      case 'TELEGRAM':
        return const Color(0xFF0088CC);
      case 'LOCAL':
        return const Color(0xFF10B981);
      case 'YOUTUBE':
      default:
        return const Color(0xFFFF0000);
    }
  }

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
    _loadShorts();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadShorts() async {
    setState(() => _isLoading = true);
    final shorts = await ContentService.getShorts(perPage: 50);
    if (!mounted) return;
    setState(() {
      _allShorts = shorts;
      _isLoading = false;
    });
  }

  // Play the short. YouTube + uploaded videos play INSIDE the app on a
  // dedicated player screen. Instagram/Facebook pages (which can't be
  // embedded) open in the in-app browser so the user still stays in the app.
  void _openShort(ShortModel s) {
    if (InAppVideoPlayer.canPlayInline(s.url)) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ShortPlayerScreen(short: s),
      ));
    } else {
      _openLink(s.url);
    }
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    // Open INSIDE the app (in-app browser / custom tab) instead of jumping to
    // the external YouTube / Instagram app.
    if (await canLaunchUrl(uri)) {
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.darkCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(tr('Could not open link!'),
              style: GoogleFonts.poppins(color: Colors.white)),
        ),
      );
    }
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
            child: Column(
              children: [
                _buildAppBar(),
                const SizedBox(height: 8),
                _buildFilterTabs(),
                const SizedBox(height: 10),
                _buildStatsRow(),
                const SizedBox(height: 10),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.neonCyan));
    }
    if (_filteredShorts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              _allShorts.isEmpty
                  ? tr('No shorts available yet!')
                  : '${tr('No')} ${_filters[_selectedFilter]} ${tr('shorts.')}',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            Text(tr('Admin will add videos soon.'),
                style: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.neonCyan,
      backgroundColor: AppColors.darkCard,
      onRefresh: _loadShorts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _filteredShorts.length,
        itemBuilder: (_, i) {
          final s = _filteredShorts[i];
          return _ShortCard(
            short: s,
            platformIcon: _platformIcon(s.platform),
            platformColor: _platformColor(s.platform),
            onTap: () => _openShort(s),
          );
        },
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('SHORTS'),
                  style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonCyan,
                      letterSpacing: 2)),
              Text(tr('Quick Math Tips & Tricks'),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_rounded,
                    color: AppColors.neonCyan, size: 13),
                const SizedBox(width: 4),
                Text('${_allShorts.length} ${tr('Videos')}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.neonCyan,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final colors = [
      AppColors.neonCyan,
      const Color(0xFFFF0000),
      const Color(0xFFE1306C),
      const Color(0xFF1877F2),
      const Color(0xFF10B981), // LOCAL (green)
    ];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final isActive = _selectedFilter == i;
          final color = colors[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.15) : AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isActive
                        ? color
                        : AppColors.textMuted.withValues(alpha: 0.2),
                    width: 1.2),
              ),
              child: Text(
                _filters[i],
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? color : AppColors.textSecondary,
                    letterSpacing: 0.5),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    final ytCount = _allShorts.where((s) => s.platform == 'YOUTUBE').length;
    final igCount = _allShorts.where((s) => s.platform == 'INSTAGRAM').length;
    final fbCount = _allShorts.where((s) => s.platform == 'FACEBOOK').length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatChip(
              label: 'YouTube',
              count: ytCount,
              color: const Color(0xFFFF0000),
              icon: Icons.play_circle_rounded),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Instagram',
              count: igCount,
              color: const Color(0xFFE1306C),
              icon: Icons.camera_alt_rounded),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Facebook',
              count: fbCount,
              color: const Color(0xFF1877F2),
              icon: Icons.facebook),
        ],
      ),
    );
  }
}

class _ShortCard extends StatefulWidget {
  final ShortModel short;
  final IconData platformIcon;
  final Color platformColor;
  final VoidCallback onTap;

  const _ShortCard({
    required this.short,
    required this.platformIcon,
    required this.platformColor,
    required this.onTap,
  });

  @override
  State<_ShortCard> createState() => _ShortCardState();
}

class _ShortCardState extends State<_ShortCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.short;
    return GestureDetector(
      onTapDown: (_) => _tapCtrl.reverse(),
      onTapUp: (_) {
        _tapCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _tapCtrl.forward(),
      child: ScaleTransition(
        scale: _tapCtrl,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: widget.platformColor.withValues(alpha: 0.15), width: 1),
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 90,
                height: 100,
                decoration: BoxDecoration(
                  color: widget.platformColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(17),
                      bottomLeft: Radius.circular(17)),
                  image: s.thumbnailUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(s.thumbnailUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.3),
                              BlendMode.darken))
                      : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.platformColor,
                          boxShadow: [
                            BoxShadow(
                                color:
                                    widget.platformColor.withValues(alpha: 0.35),
                                blurRadius: 12,
                                spreadRadius: 2),
                          ],
                        ),
                        child: Icon(widget.platformIcon,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    if (s.durationLabel.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(s.durationLabel,
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      if (s.category.isNotEmpty)
                        Text(s.category,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.platformColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      widget.platformColor.withValues(alpha: 0.3),
                                  width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(widget.platformIcon,
                                    color: widget.platformColor, size: 11),
                                const SizedBox(width: 4),
                                Text(s.platform,
                                    style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: widget.platformColor)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.open_in_new_rounded,
                              color: widget.platformColor.withValues(alpha: 0.6),
                              size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatChip(
      {required this.label,
      required this.count,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text('$count $label',
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}


// Full-screen in-app player for a single short (YouTube embed or uploaded MP4).
class _ShortPlayerScreen extends StatelessWidget {
  final ShortModel short;
  const _ShortPlayerScreen({required this.short});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.neonCyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      short.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Center(
                  child: InAppVideoPlayer(
                    url: short.url,
                    autoPlay: true,
                    aspectRatio: 9 / 16,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            if (short.category.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  short.category,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
