import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/api.dart';
import 'core/theme.dart';
import 'presentation/screens/auth/barber_auth_screen.dart';
import 'presentation/screens/dashboard/barber_dashboard_screen.dart';
import 'presentation/screens/appointments/appointments_screen.dart';
import 'presentation/screens/services/services_screen.dart';
import 'presentation/screens/profile/barber_profile_screen.dart';
import 'presentation/screens/portfolio/portfolio_screen.dart';
import 'presentation/screens/analytics/analytics_screen.dart';
import 'presentation/screens/schedule/schedule_screen.dart';
import 'presentation/screens/customers/crm_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/reviews/reviews_screen.dart';
import 'presentation/screens/notifications/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('uz');
  await loadTokens();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: StilTimeBarberApp()));
}

final _router = GoRouter(
  initialLocation: '/auth',
  redirect: (context, state) {
    final loggedIn = isLoggedIn;
    final loc = state.matchedLocation;
    const authPaths = ['/auth', '/login', '/register', '/pending'];
    final isAuthPath = authPaths.contains(loc);
    if (!loggedIn && !isAuthPath) return '/auth';
    if (loggedIn && (loc == '/auth' || loc == '/login' || loc == '/register')) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (_, __) => const BarberWelcomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const BarberLoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const BarberRegisterScreen()),
    GoRoute(path: '/pending', builder: (_, __) => const BarberPendingScreen()),
    GoRoute(path: '/', builder: (_, __) => const BarberDashboardScreen()),
    GoRoute(path: '/appointments', builder: (_, __) => const AppointmentsScreen()),
    GoRoute(path: '/services', builder: (_, __) => const ServicesScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const BarberProfileScreen()),
    GoRoute(path: '/portfolio', builder: (_, __) => const PortfolioScreen()),
    GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
    GoRoute(path: '/schedule', builder: (_, __) => const ScheduleScreen()),
    GoRoute(path: '/crm', builder: (_, __) => const CrmScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const BarberSettingsScreen()),
    GoRoute(path: '/reviews', builder: (_, __) => const BarberReviewsScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const BarberNotificationsScreen()),
  ],
);

class StilTimeBarberApp extends StatelessWidget {
  const StilTimeBarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StilTime Sartarosh',
      debugShowCheckedModeBanner: false,
      theme: barberTheme(),
      routerConfig: _router,
    );
  }
}
