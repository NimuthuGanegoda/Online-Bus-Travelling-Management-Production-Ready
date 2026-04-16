import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/route_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/emergency_provider.dart';
import 'routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const BusGoDriveApp());
}

class BusGoDriveApp extends StatefulWidget {
  const BusGoDriveApp({super.key});

  @override
  State<BusGoDriveApp> createState() => _BusGoDriveAppState();
}

class _BusGoDriveAppState extends State<BusGoDriveApp> {
  final _auth = AuthProvider();
  late final _router = buildRouter(_auth);

  @override
  void initState() {
    super.initState();
    // Restore saved token on startup so user stays logged in
    _auth.tryRestoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
      ],
      child: MaterialApp.router(
        title: 'BusGo Drive',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
