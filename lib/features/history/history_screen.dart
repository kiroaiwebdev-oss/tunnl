// lib/features/history/history_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_strings.dart';
import '../../core/services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double>   _fadeAnim;

  // ── Filter ────────────────────────────────────────
  int _selectedFilter = 0;
  final List<String> _filters = ['ALL', 'SSC', 'RAILWAY', 'BANK', 'MOCK'];

  // ── Search ────────────────────────────────────────
  bool   _showSearch = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Data ──────────────────────────────────────────
  List<Map<String, dynamic>> _history     = [];
  bool   _isLoading   = true;
  bool   _hasError    = false;
  String _errorMsg    = '';
  bool   _isLoadingMore = false;
  bool   _hasMore       = true;
  int    _page          = 1;
  static const int _pageSize = 10;

  // ── Stats ─────────────────────────────────────────
  Map<String, dynamic> _stats = {};

  final ScrollController _scrollCtrl = ScrollController();

  // ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _scrollCtrl.addListener(_onScroll);
    _loadHistory(refresh: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────
  // Infinite scroll
  // ─────────────────────────────────────────────────
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  // ─────────────────────────────────────────────────
  // API — Load
  // ─────────────────────────────────────────────────
  Future<void> _loadHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _hasError  = false;
        _page      = 1;
        _hasMore   = true;
        _history   = [];
      });
    }

    try {
      final res = await HistoryService.getHistory(
        page:     _page,
        limit:    _pageSize,
        category: _selectedFilter == 0 ? null : _filters[_selectedFilter],
        search:   _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (res['status'] == true) {
        final list  = List<Map<String, dynamic>>.from(res['data'] ?? []);
        final total = (res['total'] ?? 0) as int;

        setState(() {
          _history   = refresh ? list : [..._history, ...list];
          _stats     = Map<String, dynamic>.from(res['stats'] ?? {});
          _hasMore   = _history.length < total;
          _isLoading = false;
        });
      } else {
        _setError(res['message'] ?? tr('Failed to load history'));
      }
    } catch (e) {
      _setError(tr('Network error. Check your connection.'));
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() { _isLoadingMore = true; _page++; });
    await _loadHistory();
    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _setError(String msg) {
    if (mounted) {
      setState(() {
      _isLoading = false;
      _hasError  = true;
      _errorMsg  = msg;
    });
    }
  }

  // ─────────────────────────────────────────────────
  // Computed stats (fallback to local if API doesn't send)
  // ─────────────────────────────────────────────────
  int    get _totalTests => (_stats['total_tests']  ?? _history.length) as int;
  double get _avgScore   => (_stats['avg_score']    ?? _calcLocalAvg()) as double;
  int    get _bestScore  => (_stats['best_score']   ?? _calcLocalBest()) as int;
  double get _avgSpeed   => (_stats['avg_speed']    ?? 0.0) as double;

  double _calcLocalAvg() {
    if (_history.isEmpty) return 0;
    final correct = _history.fold<int>(0, (s, e) => s + ((e['correct'] ?? 0) as int));
    final total   = _history.fold<int>(0, (s, e) => s + ((e['total_questions'] ?? 10) as int));
    return total == 0 ? 0 : (correct / total) * 10;
  }

  int _calcLocalBest() {
    if (_history.isEmpty) return 0;
    return _history
        .map((e) => (e['correct'] ?? 0) as int)
        .reduce((a, b) => a > b ? a : b);
  }

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
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
                if (_showSearch) _buildSearchBar(),
                Expanded(child: _buildBody()),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.neonCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Text(tr('HISTORY'),
            style: GoogleFonts.orbitron(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: AppColors.neonCyan, letterSpacing: 2)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _searchCtrl.clear();
                _loadHistory(refresh: true);
              }
            }),
            child: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
              color: _showSearch ? AppColors.neonCyan : AppColors.textSecondary,
              size: 22),
          ),
          const SizedBox(width: 14),
          // Sort menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
              color: AppColors.textSecondary, size: 22),
            color: AppColors.darkCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              // Future: sort by date/score
            },
            itemBuilder: (_) => [
              _menuItem(tr('Latest First'),  Icons.arrow_downward_rounded),
              _menuItem(tr('Highest Score'), Icons.star_rounded),
              _menuItem(tr('Lowest Score'),  Icons.star_border_rounded),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String text, IconData icon) {
    return PopupMenuItem(
      value: text,
      child: Row(children: [
        Icon(icon, color: AppColors.neonCyan, size: 16),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.poppins(
          fontSize: 12, color: Colors.white)),
      ]),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.neonCyan.withValues(alpha: 0.3)),
        ),
        child: TextField(
          controller:   _searchCtrl,
          autofocus:    true,
          style:        GoogleFonts.poppins(
            fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText:      tr('Search exam, category...'),
            hintStyle:     GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textMuted),
            prefixIcon:    const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 18),
            border:        InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (v) {
            _searchQuery = v;
            // Debounce: wait for user to stop typing
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchQuery == v) _loadHistory(refresh: true);
            });
          },
        ),
      ),
    );
  }

  // ── BODY ──────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.neonCyan));
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                color: AppColors.textMuted, size: 56),
              const SizedBox(height: 16),
              Text(tr('Failed to Load'),
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white)),
              const SizedBox(height: 8),
              Text(_errorMsg,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.darkBg),
                label: Text(tr('Retry'),
                  style: GoogleFonts.poppins(
                    color: AppColors.darkBg,
                    fontWeight: FontWeight.w700)),
                onPressed: () => _loadHistory(refresh: true),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color:       AppColors.neonCyan,
      backgroundColor: AppColors.darkCard,
      onRefresh:   () => _loadHistory(refresh: true),
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        physics:    const AlwaysScrollableScrollPhysics(),
        padding:    const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 20),
            _buildFilters(),
            const SizedBox(height: 16),
            _history.isEmpty
                ? _buildEmpty()
                : Column(
                    children: [
                      ..._history.map((h) => _buildHistoryCard(h)),
                      if (_isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(
                            color: AppColors.neonCyan, strokeWidth: 2),
                        ),
                      if (!_hasMore && _history.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(tr('All caught up!'),
                            style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textMuted)),
                        ),
                    ],
                  ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('History'),
          style: GoogleFonts.poppins(
            fontSize: 28, fontWeight: FontWeight.w800,
            color: Colors.white)),
        Text(tr('Track your performance over time'),
          style: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  // ── STATS GRID ────────────────────────────────────
  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _StatCard(
            label: tr('TOTAL TESTS'),
            value: '$_totalTests',
            sub: tr('attempts'),
            subColor: AppColors.neonCyan,
            highlighted: true,
          )),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(
            label: tr('AVERAGE SCORE'),
            value: _avgScore.toStringAsFixed(1),
            sub: '/10',
            subColor: AppColors.textMuted,
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard(
            label: tr('BEST SCORE'),
            value: '$_bestScore',
            sub: _bestScore == 10 ? tr('Perfect!') : '/10',
            subColor: _bestScore == 10
                ? AppColors.success : AppColors.textMuted,
          )),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(
            label: tr('AVG SPEED'),
            value: _avgSpeed.toStringAsFixed(1),
            sub: 's/q',
            subColor: AppColors.textMuted,
          )),
        ]),
      ],
    );
  }

  // ── FILTERS ───────────────────────────────────────
  Widget _buildFilters() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final isActive = _selectedFilter == i;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilter = i);
              _loadHistory(refresh: true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.neonCyan : AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.neonCyan
                      : AppColors.textMuted.withValues(alpha: 0.2)),
              ),
              child: Text(_filters[i],
                style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: isActive
                      ? AppColors.darkBg : AppColors.textSecondary)),
            ),
          );
        },
      ),
    );
  }

  // ── HISTORY CARD ──────────────────────────────────
  Widget _buildHistoryCard(Map<String, dynamic> h) {
    final int correct   = (h['correct']         ?? 0)  as int;
    final int total     = (h['total_questions']  ?? 10) as int;
    final double acc    = (h['accuracy']         ?? 0.0).toDouble();
    final double speed  = (h['avg_speed_seconds']?? 0.0).toDouble();
    final String exam   = h['exam_name']         ?? h['category'] ?? 'Quiz';
    final String set    = 'SET ${h['set_number'] ?? 1} • ${(h['category'] ?? '').toUpperCase()}';
    final String date   = h['created_at_label']  ?? h['date'] ?? '';
    final double progress = total == 0 ? 0 : correct / total;

    Color scoreColor = acc >= 80
        ? AppColors.success
        : acc >= 50 ? AppColors.yellow : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scoreColor.withValues(alpha: 0.2))),
                child: Center(
                  child: Text(
                    (h['category'] ?? 'Q').toString().substring(0, 1),
                    style: GoogleFonts.orbitron(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: scoreColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam,
                      style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                    Text(set,
                      style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textSecondary,
                        letterSpacing: 0.5)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 16),
                  const SizedBox(height: 2),
                  Text(date,
                    style: GoogleFonts.poppins(
                      fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stats row
          Row(children: [
            _MiniStat(
              label: tr('SCORE'),
              value: '$correct/$total',
              color: scoreColor,
            ),
            _MiniStat(
              label: tr('ACCURACY'),
              value: '${acc.toStringAsFixed(0)}%',
              color: Colors.white,
            ),
            _MiniStat(
              label: tr('AVG TIME'),
              value: '${speed.toStringAsFixed(1)}s',
              color: Colors.white,
            ),
          ]),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.textMuted.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ── EMPTY ─────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.history_rounded,
              color: AppColors.textMuted.withValues(alpha: 0.3), size: 60),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? '${tr('No results for')} "$_searchQuery"'
                  : tr('No history yet!\nStart solving to see results here.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textMuted, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color  subColor;
  final bool   highlighted;

  const _StatCard({
    required this.label, required this.value,
    required this.sub,   required this.subColor,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? AppColors.neonCyan.withValues(alpha: 0.4)
              : AppColors.textMuted.withValues(alpha: 0.1),
          width: highlighted ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
            style: GoogleFonts.poppins(
              fontSize: 9, color: AppColors.textMuted,
              letterSpacing: 1)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                style: GoogleFonts.orbitron(
                  fontSize: 26, fontWeight: FontWeight.w700,
                  color: highlighted
                      ? AppColors.neonCyan : Colors.white)),
              const SizedBox(width: 4),
              Text(sub,
                style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: subColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;

  const _MiniStat({
    required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
            style: GoogleFonts.poppins(
              fontSize: 9, color: AppColors.textMuted,
              letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(value,
            style: GoogleFonts.orbitron(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: color)),
        ],
      ),
    );
  }
}
