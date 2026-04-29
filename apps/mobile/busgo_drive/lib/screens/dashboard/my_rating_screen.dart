import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';

class MyRatingScreen extends StatefulWidget {
  const MyRatingScreen({super.key});

  @override
  State<MyRatingScreen> createState() => _MyRatingScreenState();
}

class _MyRatingScreenState extends State<MyRatingScreen> {
  double _rating = 0.0;
  bool _loading = true;
  List<_Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _fetchRating();
  }

  Future<void> _fetchRating() async {
    final api = ApiService();
    try {
      // Fetch driver score and recent passenger comments in parallel.
      final results = await Future.wait([
        api.getMe(),
        api.getMyRatings(),
      ]);
      if (!mounted) return;
      final me      = results[0];
      final ratings = results[1];
      final r = (me.data?['data']?['rating'] as num?)?.toDouble();
      final list = (ratings.data?['data'] as List?) ?? const [];

      setState(() {
        _rating = r ?? 0.0;
        _comments = list
            .map((row) => _commentFromApi(row as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _avatarPalette = <Color>[
    Color(0xFF1565C0), Color(0xFFE65100), Color(0xFF2E7D32),
    Color(0xFF7B1FA2), Color(0xFF00838F), Color(0xFFC2185B),
    Color(0xFF455A64),
  ];

  _Comment _commentFromApi(Map<String, dynamic> row) {
    final user = row['users'] as Map<String, dynamic>?;
    final trip = row['trips'] as Map<String, dynamic>?;
    final route = trip?['bus_routes'] as Map<String, dynamic>?;
    final fullName = (user?['full_name'] as String?) ?? 'Anonymous';
    final initials = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();
    final tagsRaw = row['tags'] as List?;
    final tags = (tagsRaw ?? const [])
        .whereType<String>()
        .toList(growable: false);
    final stars = (row['stars'] as num?)?.toInt() ?? 0;
    final created = row['created_at'] as String?;
    final dateLabel = created != null
        ? _formatDate(DateTime.parse(created).toLocal())
        : '—';
    final routeLabel = route?['route_number'] != null
        ? 'Route ${route!['route_number']}'
        : '—';
    return _Comment(
      name:        fullName,
      initials:    initials.isNotEmpty ? initials : '?',
      avatarColor: _avatarPalette[fullName.hashCode.abs() % _avatarPalette.length],
      stars:       stars,
      text:        (row['comment'] as String?) ?? '(No comment)',
      date:        dateLabel,
      route:       routeLabel,
      tags:        tags,
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Rating hero
          _buildRatingHero(context),
          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  _buildWeeklyTrend(),
                  const SizedBox(height: 14),
                  _buildRecentComments(),
                  const SizedBox(height: 14),
                  _buildDisputeButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingHero(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1A2E),
            Color(0xFF132F54),
            Color(0xFF1E5AA8),
          ],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      child: Column(
        children: [
          Text(
            'YOUR SCORE',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF90CAF9),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          // Score (FR-36 — real value from /api/driver/me)
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _loading ? '–' : _rating.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' / 10',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF90CAF9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              if (i < 4) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.star_rounded,
                      size: 26, color: Color(0xFFFFD700)),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.star_rounded,
                      size: 26,
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                );
              }
            }),
          ),
          const SizedBox(height: 6),
          Text(
            'Based on 142 passenger reviews',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF90CAF9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrend() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [3.9, 4.0, 3.7, 4.3, 4.0, 4.5, 4.2];
    final maxVal = 5.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY RATING TREND',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF757575),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 18),
          // Bar chart
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final barHeight = (values[i] / maxVal) * 70;
                Color barColor;
                if (values[i] >= 4.3) {
                  barColor = AppColors.success;
                } else if (i == 6) {
                  barColor = AppColors.warning;
                } else {
                  barColor = AppColors.primaryLight.withValues(alpha: 0.8);
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          values[i].toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          // Day labels
          Row(
            children: days
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentComments() {
    // FR-36 — real passenger ratings from /api/driver/ratings.
    final comments = _comments;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT PASSENGER COMMENTS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF757575),
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${comments.length} reviews',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  _loading
                      ? 'Loading recent comments…'
                      : 'No passenger ratings yet.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            )
          else
            ...comments.map((c) => _buildCommentItem(c)),
        ],
      ),
    );
  }

  Widget _buildCommentItem(_Comment comment) {
    // Sentiment color based on stars
    Color sentimentColor;
    String sentimentLabel;
    if (comment.stars >= 5) {
      sentimentColor = const Color(0xFF2E7D32);
      sentimentLabel = 'Excellent';
    } else if (comment.stars >= 4) {
      sentimentColor = const Color(0xFF1565C0);
      sentimentLabel = 'Good';
    } else if (comment.stars >= 3) {
      sentimentColor = const Color(0xFFE65100);
      sentimentLabel = 'Average';
    } else {
      sentimentColor = AppColors.danger;
      sentimentLabel = 'Poor';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar, name, sentiment, stars
          Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: comment.avatarColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    comment.initials,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name + route
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Icon(Icons.directions_bus_rounded,
                            size: 10, color: const Color(0xFF9E9E9E)),
                        const SizedBox(width: 3),
                        Text(
                          comment.route,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '\u2022',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: const Color(0xFFD0D7E0),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          comment.date,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Sentiment badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sentimentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sentimentLabel,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: sentimentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Stars
          Row(
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: i < comment.stars
                      ? const Color(0xFFFFB300)
                      : const Color(0xFFE0E0E0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Comment text
          Text(
            '\u201C${comment.text}\u201D',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF4A5568),
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          // Tags
          if (comment.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: comment.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDisputeButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.warning_amber_rounded, size: 18),
        label: Text(
          'Dispute a Rating',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _Comment {
  final String name;
  final String initials;
  final Color avatarColor;
  final int stars;
  final String text;
  final String date;
  final String route;
  final List<String> tags;

  const _Comment({
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.stars,
    required this.text,
    required this.date,
    required this.route,
    this.tags = const [],
  });
}
