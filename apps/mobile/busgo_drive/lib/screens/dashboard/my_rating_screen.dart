import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class MyRatingScreen extends StatelessWidget {
  const MyRatingScreen({super.key});

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
          // Score
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '4.2',
                  style: GoogleFonts.inter(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' / 5',
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
    final comments = [
      _Comment(
        name: 'Amira F.',
        initials: 'AF',
        avatarColor: const Color(0xFF1565C0),
        stars: 5,
        text: 'Very smooth driving, always on time. Made me feel safe throughout the journey.',
        date: 'March 17, 2026',
        route: 'Route 138',
        tags: ['Safe Driving', 'On Time'],
      ),
      _Comment(
        name: 'Rajith K.',
        initials: 'RK',
        avatarColor: const Color(0xFFE65100),
        stars: 4,
        text: 'Good driver but bus was slightly late at Fort station. Otherwise a pleasant ride.',
        date: 'March 16, 2026',
        route: 'Route 138',
        tags: ['Pleasant'],
      ),
      _Comment(
        name: 'Nimal S.',
        initials: 'NS',
        avatarColor: const Color(0xFF2E7D32),
        stars: 5,
        text: 'Polite and professional. Stopped exactly at the right spots. Would ride again!',
        date: 'March 15, 2026',
        route: 'Route 177',
        tags: ['Professional', 'Accurate Stops'],
      ),
      _Comment(
        name: 'Kumari D.',
        initials: 'KD',
        avatarColor: const Color(0xFF7B1FA2),
        stars: 5,
        text: 'Best bus experience I\'ve had. Clean bus, careful driving, and very courteous.',
        date: 'March 14, 2026',
        route: 'Route 138',
        tags: ['Clean', 'Courteous'],
      ),
      _Comment(
        name: 'Thilina P.',
        initials: 'TP',
        avatarColor: const Color(0xFF00838F),
        stars: 3,
        text: 'Driving was fine but the AC wasn\'t working properly. Got quite warm inside.',
        date: 'March 13, 2026',
        route: 'Route 177',
        tags: ['AC Issue'],
      ),
    ];

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
