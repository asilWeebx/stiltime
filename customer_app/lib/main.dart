import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'presentation/screens/auth/onboarding_screen.dart';
import 'presentation/screens/auth/otp_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/booking/booking_flow_screen.dart';
import 'presentation/screens/search/search_screen.dart';
import 'presentation/screens/salon/salon_detail_screen.dart';
import 'presentation/screens/barber/barber_detail_screen.dart';
import 'presentation/screens/favorites/favorites_screen.dart';
import 'presentation/screens/bookings/bookings_screen.dart';
import 'presentation/screens/notifications/notifications_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/profile/profile_edit_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/bookings/booking_detail_screen.dart';
import 'presentation/screens/map/map_screen.dart';
import 'presentation/screens/salons/all_salons_screen.dart'; // SalonsListScreen + BarbersListScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  // Pre-load auth state so initial route is correct without waiting for async _loadUser
  const storage = FlutterSecureStorage();
  final accessToken = await storage.read(key: AppConstants.accessTokenKey);
  final userJson = await storage.read(key: AppConstants.userKey);
  final hasAuth = accessToken != null && accessToken.isNotEmpty && userJson != null;

  runApp(ProviderScope(child: StilTimeApp(onboardingDone: onboardingDone, hasAuth: hasAuth)));
}

class StilTimeApp extends ConsumerStatefulWidget {
  final bool onboardingDone;
  final bool hasAuth;
  const StilTimeApp({super.key, required this.onboardingDone, required this.hasAuth});

  @override
  ConsumerState<StilTimeApp> createState() => _StilTimeAppState();
}

class _StilTimeAppState extends ConsumerState<StilTimeApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    String initial;
    if (!widget.onboardingDone) {
      initial = '/onboarding';
    } else if (widget.hasAuth) {
      initial = '/home';
    } else {
      initial = '/phone';
    }

    _router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/phone', builder: (_, __) => const _PhoneScreen()),
        GoRoute(path: '/otp/:phone', builder: (_, state) => OtpScreen(phone: state.pathParameters['phone']!)),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/booking/:salonId', builder: (_, state) => BookingFlowScreen(salonId: int.parse(state.pathParameters['salonId']!))),
        GoRoute(
          path: '/salon/:id/book',
          builder: (_, state) => BookingFlowScreen(
            salonId: int.parse(state.pathParameters['id']!),
            preSelectedBarberId: int.tryParse(state.uri.queryParameters['barber'] ?? ''),
          ),
        ),
        GoRoute(path: '/barber/:id/book', builder: (_, state) => BookingFlowScreen(salonId: 0, preSelectedBarberId: int.parse(state.pathParameters['id']!))),
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(path: '/salon/:id', builder: (_, state) => SalonDetailScreen(salonId: int.parse(state.pathParameters['id']!))),
        GoRoute(path: '/barber/:id', builder: (_, state) => BarberDetailScreen(barberId: int.parse(state.pathParameters['id']!))),
        GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
        GoRoute(path: '/bookings', builder: (_, __) => const BookingsScreen()),
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/profile/edit', builder: (_, __) => const ProfileEditScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/settings/notifications', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/booking-detail/:id', builder: (_, state) => BookingDetailScreen(bookingId: int.parse(state.pathParameters['id']!))),
        GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
        GoRoute(path: '/salons', builder: (_, __) => const SalonsListScreen()),
        GoRoute(path: '/barbers', builder: (_, __) => const BarbersListScreen()),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StilTime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      locale: const Locale('uz'),
    );
  }
}

class _PhoneScreen extends ConsumerStatefulWidget {
  const _PhoneScreen();

  @override
  ConsumerState<_PhoneScreen> createState() => __PhoneScreenState();
}

class __PhoneScreenState extends ConsumerState<_PhoneScreen> {
  final _phoneController = TextEditingController(text: '+998');
  bool _loading = false;

  Future<void> _next() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To\'g\'ri telefon raqam kiriting'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).sendOTP(phone);
      if (mounted) context.push('/otp/$phone');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              const Text('StilTime', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 8),
              Text(
                "Go'zallik va sartaroshlik platformasi",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Phone input
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Telefon raqam',
                  hintText: '+998 90 123 45 67',
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _next,
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Davom etish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              const Spacer(),

              Text(
                'Davom etish orqali foydalanish shartlari va\nmaxfiylik siyosatiga rozilik bildirasiz',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
