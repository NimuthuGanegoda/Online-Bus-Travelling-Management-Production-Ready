import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';
import '../../providers/user_provider.dart';

class QrCardScreen extends StatefulWidget {
  const QrCardScreen({super.key});

  @override
  State<QrCardScreen> createState() => _QrCardScreenState();
}

class _QrCardScreenState extends State<QrCardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh trip state from the backend so we always know whether there's
    // an ongoing trip — even if the local provider is stale (e.g. user
    // navigated to QR before the create-trip API call resolved).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TripProvider>().loadTripHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final user = userProvider.user;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            // Always BUSGO-<user.id>: matches the format expected by the
            // scanner backend (POST /api/scanner/scan parses out user.id).
            // The DB's `qr_token` is a separate concept and is not used
            // for boarding/alighting in the current scope.
            final qrData = 'BUSGO-${user.id}';
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.headerBg,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.arrow_back,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'My QR Card',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.download,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // QR Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.8, -0.6),
                        end: Alignment(0.8, 0.6),
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Card header
                        const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BUSGO',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  'PASSENGER CARD',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.lightBlue,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            Text('🚌',
                                style: TextStyle(fontSize: 24)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: 120,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle:
                                    const QrDataModuleStyle(
                                  dataModuleShape:
                                      QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                qrData,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF999999),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Passenger info
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PASSENGER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.lightBlue,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '@${user.username}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.lightBlue,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'VALID UNTIL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.lightBlue,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.validUntil,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.isActive
                                        ? 'ACTIVE'
                                        : 'INACTIVE',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scan to Exit — completes the current ongoing trip via
                  // PATCH /api/trips/:id/alight. If the local provider state
                  // is stale, we refresh from the backend first so a freshly
                  // boarded trip is always picked up.
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final tripProvider = context.read<TripProvider>();
                        final messenger = ScaffoldMessenger.of(context);
                        final router = GoRouter.of(context);

                        // Refresh from backend if no ongoing trip locally —
                        // handles the case where the user navigated here right
                        // after boarding, before the provider state updated.
                        if (tripProvider.ongoingTrip == null) {
                          await tripProvider.loadTripHistory();
                        }

                        if (tripProvider.ongoingTrip == null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 4),
                              content: Text(
                                'No active trip to exit. Board a bus from the '
                                'map first.',
                              ),
                            ),
                          );
                          return;
                        }

                        final completed = await tripProvider.alightTrip(
                          fareLkr: 70, // demo flat fare
                        );

                        if (completed == null) {
                          final reason = tripProvider.errorMessage
                              ?? 'Could not end trip';
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.danger,
                              duration: const Duration(seconds: 5),
                              content: Text(
                                'Failed to exit: $reason',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                          return;
                        }

                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 3),
                            content: Text(
                              'Trip completed — fare '
                              'Rs ${completed.fare.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        );

                        // Small delay so the success snackbar is visible
                        // before navigation.
                        await Future.delayed(
                            const Duration(milliseconds: 600));
                        if (router.canPop() ||
                            // ignore: use_build_context_synchronously
                            ModalRoute.of(context) != null) {
                          router.push('/rating');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E5AA8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Scan to Exit Bus',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Download button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QR Card saved!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E5AA8),
                        side: const BorderSide(
                          color: Color(0xFF1E5AA8),
                          width: 1.5,
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Download Card',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Instruction
                  const Text(
                    'Scan this QR when boarding and again when exiting.\nAfter exit scan, you\'ll be asked to rate your trip.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
