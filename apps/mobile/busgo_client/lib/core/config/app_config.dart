import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

/// Environment enum
enum AppEnvironment { development, production }

/// Central app configuration.
/// Set [environment] to [AppEnvironment.production] before a release build.
class AppConfig {
  AppConfig._();

  // ── Toggle this for production releases ───────────────────────────────────
  static const AppEnvironment environment = AppEnvironment.development;

  // ── Derived base URL ──────────────────────────────────────────────────────
  static String get baseUrl =>
      environment == AppEnvironment.production ? kBaseUrlProd : kBaseUrlDev;

  // ── Supabase credentials (used for Realtime subscriptions only) ───────────
  // Replace these with your actual Supabase project values.
  // These are the ANON (public) keys — safe to include in client code.
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // ── Realtime channel for live bus tracking ────────────────────────────────
  static const String busLocationChannel = 'bus-locations';
  static const String busLocationEvent   = 'location-update';

  // ── API timeouts ──────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ── Debug logging ─────────────────────────────────────────────────────────
  static bool get enableApiLogs => kDebugMode;
}
