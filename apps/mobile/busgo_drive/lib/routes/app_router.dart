import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/main_shell.dart';
import '../screens/profile/profile_screen.dart';

GoRouter buildRouter(AuthProvider auth) => GoRouter(
  initialLocation: '/login',
  refreshListenable: auth,
  redirect: (context, state) {
    final loggedIn = auth.isLoggedIn;
    final onAuth  = state.matchedLocation == '/login' ||
                    state.matchedLocation == '/register' ||
                    state.matchedLocation == '/forgot-password';

    if (!loggedIn && !onAuth) return '/login';
    if (loggedIn  &&  onAuth) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainShell(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
