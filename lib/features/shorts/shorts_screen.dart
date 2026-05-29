import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';

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

  final List<String> _filters = [
    'ALL', 'YOUTUBE', 'INSTAGRAM', 'TELEGRAM'
  ];

  // Dummy shorts data — Admin panel se aayega
  final List<Map<String, dynamic>> _allShorts = [
    {
      'title': 'Multiply 2-digit numbers in 3 seconds!',
      'subtitle': 'Vedic Math Trick #1',
      'platform': 'YOUTUBE',
      'url': 'https://www.youtube.com/shorts/abc123',
      'duration': '0:58',
      'views': '12K',
      'isNew': true,
      'platformColor': const Color(0xFFFF0000),
      'platformIcon': Icons.play_circle_rounded,
    },
    {
      'title': 'Percentage karo 2 second mein!',
      'subtitle': 'Speed Math Trick #5',
      'platform': 'INSTAGRAM',
      'url': 'https://www.instagram.com/reel/abc123',
      'duration': '0:45',
      'views': '8.5K',
      'isNew': true,
      'platformColor': const Color(0xFFE1306C),
      'platformIcon': Icons.camera_alt_rounded,
    },
    {
      'title': 'Square root trick — No Calculator!',
      'subtitle': 'Vedic Math Trick #3',
      'platform': 'YOUTUBE',
      'url': 'https://www.youtube.com/shorts/xyz456',
      'duration': '1:02',
      'views': '25K',
      'isNew': false,
      'platformColor': const Color(0xFFFF0000),
      'platformIcon': Icons.play_circle_rounded,
    },
    {
      'title': 'Division shortcut for SSC!',
      'subtitle': 'SSC CGL Special',
      'platform': 'TELEGRAM',
      'url': 'https://t.me/tunnel_math',
      'duration': '1:15',
      'views': '5K',
      'isNew': false,
      'platformColor': const Color(0xFF0088CC),
      'platformIcon': Icons.send_rounded,
    },
    {
      'title': 'Simplification in 5 seconds!',
      'subtitle': 'Bank PO Special',
      'platform': 'YOUTUBE',
      'url': 'https://www.youtube.com/shorts/def789',
      'duration': '0:52',
      'views': '18K',
      'isNew': false,
      'platformColor': const Color(0xFFFF0000),
      'platformIcon': Icons.play_circle_rounded,
    },
    {
      'title': 'Cube root — Instant formula!',
      'subtitle': 'Railway RRB Special',
      'platform': 'INSTAGRAM',
      'url': 'https://www.instagram.com/reel/def789',
      'duration': '0:48',
      'views': '9.2K',
      'isNew': false,
      'platformColor': const Color(0xFFE1306C),
      'platformIcon': Icons.camera_alt_rounded,
    },
  ];

  List<Map<String, dynamic>> get _filteredShorts {
    if (_selectedFilter == 0) return _allShorts;
    final filter = _filters[_selectedFilter];
    return _allShorts
        .where((s) => s['platform'] == filter)
        .toList();
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
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.darkCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            'Could not open link!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
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
                // ── AppBar
                _buildAppBar(),

                const SizedBox(height: 8),

                // ── Filter tabs
                _buildFilterTabs(),

                const SizedBox(height: 10),

                // ── Stats row
                _buildStatsRow(),

                const SizedBox(height: 10),

                // ── Shorts list
                Expanded(
                  child: _filteredShorts.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: _filteredShorts.length,
                          itemBuilder: (_, i) {
                            return _ShortCard(
                              data: _filteredShorts[i],
                              index: i,
                              onTap: () => _openLink(
                                _filteredShorts[i]['url'],
                              ),
                            );
                          },
                        ),
                ),
              ],
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
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.neonCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SHORTS',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Quick Math Tips & Tricks',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Total count chip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.neonCyan.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.play_circle_rounded,
                  color: AppColors.neonCyan,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_allShorts.length} Videos',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.neonCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTER TABS ───────────────────────────────────
  Widget _buildFilterTabs() {
    final colors = [
      AppColors.neonCyan,
      const Color(0xFFFF0000),
      const Color(0xFFE1306C),
      const Color(0xFF0088CC),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withOpacity(0.15)
                    : AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? color
                      : AppColors.textMuted.withOpacity(0.2),
                  width: 1.2,
                ),
              ),
              child: Text(
                _filters[i],
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? color : AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── STATS ROW ─────────────────────────────────────
  Widget _buildStatsRow() {
    final ytCount = _allShorts
        .where((s) => s['platform'] == 'YOUTUBE')
        .length;
    final igCount = _allShorts
        .where((s) => s['platform'] == 'INSTAGRAM')
        .length;
    final tgCount = _allShorts
        .where((s) => s['platform'] == 'TELEGRAM')
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatChip(
            label: 'YouTube',
            count: ytCount,
            color: const Color(0xFFFF0000),
            icon: Icons.play_circle_rounded,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Instagram',
            count: igCount,
            color: const Color(0xFFE1306C),
            icon: Icons.camera_alt_rounded,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Telegram',
            count: tgCount,
            color: const Color(0xFF0088CC),
            icon: Icons.send_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.videocam_off_rounded,
            color: AppColors.textMuted,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No shorts available yet!',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            'Admin will add videos soon.',
            style: GoogleFonts.poppins(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// SHORT CARD
// ─────────────────────────────────────────────────────
class _ShortCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;
  final VoidCallback onTap;

  const _ShortCard({
    required this.data,
    required this.index,
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
    final Color platformColor = widget.data['platformColor'] as Color;
    final IconData platformIcon = widget.data['platformIcon'] as IconData;

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
              color: platformColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Thumbnail area
              Container(
                width: 90,
                height: 100,
                decoration: BoxDecoration(
                  color: platformColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(17),
                    bottomLeft: Radius.circular(17),
                  ),
                  border: Border(
                    right: BorderSide(
                      color: platformColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    // Play icon
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: platformColor,
                          boxShadow: [
                            BoxShadow(
                              color: platformColor.withOpacity(0.35),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          platformIcon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // Duration
                    Positioned(
                      bottom: 8,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.data['duration'],
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + NEW
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.data['title'],
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.data['isNew'] == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: AppColors.success
                                      .withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'NEW',
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        widget.data['subtitle'],
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Bottom row
                      Row(
                        children: [
                          // Platform badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: platformColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: platformColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  platformIcon,
                                  color: platformColor,
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.data['platform'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: platformColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Views
                          Row(
                            children: [
                              const Icon(
                                Icons.visibility_rounded,
                                color: AppColors.textMuted,
                                size: 11,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.data['views'],
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Open arrow
                          Icon(
                            Icons.open_in_new_rounded,
                            color: platformColor.withOpacity(0.6),
                            size: 16,
                          ),
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

// ─────────────────────────────────────────────────────
// STAT CHIP
// ─────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}