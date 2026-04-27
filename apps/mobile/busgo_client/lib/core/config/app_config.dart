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
  static const String supabaseUrl = 'https://rxcvfsicxltsmmlakgws.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4Y3Zmc2ljeGx0c21tbGFrZ3dzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyMTYzOTgsImV4cCI6MjA5Mjc5MjM5OH0.RT59aWqE7cGg-5QxzrpdjgvYQ1MjWQNEoxfDMUDJOXI';

  // ── Realtime channel for live bus tracking ────────────────────────────────
  static const String busLocationChannel = 'bus-locations';
  static const String busLocationEvent   = 'location-update';

  // ── API timeouts ──────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ── Debug logging ─────────────────────────────────────────────────────────
  static bool get enableApiLogs => kDebugMode;
}
