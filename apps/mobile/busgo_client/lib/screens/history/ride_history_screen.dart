import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_provider.dart';

const _blue = Color(0xFF1976D2);
const _navy = Color(0xFF0A2342);

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TripProvider>().loadTripHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TripModel> _filterTrips(List<TripModel> trips) {
    if (_searchQuery.isEmpty) return trips;
    final q = _searchQuery.toLowerCase();
    return trips
        .where((t) =>
            'bus ${t.routeNumber}'.toLowerCase().contains(q) ||
            t.displayRoute.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _onRefresh() async {
    await context.read<TripProvider>().loadTripHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        final filtered = _filterTrips(tripProvider.tripHistory);

        return Scaffold(
          backgroundColor: const Color(0xFFEEF2F8),
          body: Column(
            children: [
              _buildBlueHeader(),
              _buildStatsRow(tripProvider),
              Expanded(
                child: tripProvider.isLoading && tripProvider.tripHistory.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: _blue),
                      )
                    : tripProvider.errorMessage != null &&
                            tripProvider.tripHistory.isEmpty
                        ? _buildErrorState(tripProvider.errorMessage!)
                        : filtered.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                color: _blue,
                                onRefresh: _onRefresh,
                                child: ListView.builder(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filtered.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return _buildMonthHeader(filtered.length);
                                    }
                                    return _buildRideCard(filtered[index - 1]);
                                  },
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1A2E), Color(0xFF132F54), Color(0xFF1E5AA8)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Ride History',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'Search trips...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.white.withValues(alpha: 0.6)),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: Icon(Icons.close_rounded, size: 16, color: Colors.white.withValues(alpha: 0.6)),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 16, color: _blue),
                        SizedBox(width: 6),
                        Text('Filter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(TripProvider tripProvider) {
    final trips = tripProvider.totalTrips.toString();
    final spent = 'Rs ${tripProvider.totalSpent.toStringAsFixed(0)}';
    final rating = tripProvider.totalTrips == 0
        ? '—'
        : tripProvider.averageRating.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _statBox(trips, 'Trips', _blue, Icons.directions_bus_rounded),
          _statDivider(),
          _statBox(spent, 'Spent', const Color(0xFF0E7C61), Icons.account_balance_wallet_rounded),
          _statDivider(),
          _statBox(rating, 'Rating', AppColors.starFilled, Icons.star_rounded),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: _navy.withValues(alpha: 0.15),
    );
  }

  Widget _statBox(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: _blue.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(int tripCount) {
    final now = DateTime.now();
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final label = '${months[now.month - 1]} ${now.year}';

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month_rounded, size: 12, color: _blue.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _blue, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '$tripCount ${tripCount == 1 ? 'trip' : 'trips'}',
            style: TextStyle(fontSize: 11, color: _blue.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(TripModel trip) {
    final int rating = trip.rating.clamp(0, 5);
    const int maxRating = 5;
    final ride = {
      'bus': 'Bus ${trip.routeNumber}',
      'route': trip.from.isNotEmpty && trip.to.isNotEmpty
          ? '${trip.from} → ${trip.to}'
          : 'Route ${trip.routeNumber}',
      'date': trip.dateTime.isNotEmpty ? trip.dateTime : '—',
      'price': 'Rs ${trip.fare.toStringAsFixed(0)}',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _blue.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left blue accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _blue.withValues(alpha: 0.12),
                            _blue.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.directions_bus_rounded, size: 22, color: _blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride['bus'] as String,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.route_rounded, size: 12, color: _blue.withValues(alpha: 0.4)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  ride['route'] as String,
                                  style: TextStyle(fontSize: 12, color: _blue.withValues(alpha: 0.6)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ride['date'] as String,
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ride['price'] as String,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _navy),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...List.generate(maxRating, (i) {
                              return Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: i < rating ? AppColors.starFilled : AppColors.starEmpty,
                              );
                            }),
                            const SizedBox(width: 4),
                            Text(
                              '$rating/$maxRating',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.7)),
                            ),
                          ],
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_bus_outlined, size: 40, color: _blue),
          ),
          const SizedBox(height: 16),
          const Text(
            'No trips found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a different search term',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
