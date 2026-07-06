import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardData(
      icon: Icons.content_cut_rounded,
      color: Color(0xFF3B82F6),
      title: 'Sartaroshxonani toping',
      subtitle: 'Yaqin atrofdagi eng yaxshi sartaroshxona va go\'zallik salonlarini bir joyda toping.',
    ),
    _OnboardData(
      icon: Icons.calendar_month_rounded,
      color: Color(0xFF8B5CF6),
      title: 'Oson band qiling',
      subtitle: 'Qulay vaqtni tanlang va bir necha soniyada band qiling — navbat kutishga hojat yo\'q.',
    ),
    _OnboardData(
      icon: Icons.star_rounded,
      color: Color(0xFFF59E0B),
      title: 'Bonus ballar yig\'ing',
      subtitle: 'Har bir tashrif uchun bonus ballar oling va keyingi xizmatlardan chegirma qozonib boring.',
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/phone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('O\'tkazib yuborish', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardPage(data: _pages[i], active: i == _page),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),

            const SizedBox(height: 32),

            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(
                    _page < _pages.length - 1 ? 'Keyingisi' : 'Boshlash',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _OnboardData({required this.icon, required this.color, required this.title, required this.subtitle});
}

class _OnboardPage extends StatelessWidget {
  final _OnboardData data;
  final bool active;
  const _OnboardPage({required this.data, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [data.color, data.color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: data.color.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Icon(data.icon, color: Colors.white, size: 44),
              ),
            ),
          ).animate(target: active ? 1 : 0).scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut),

          const SizedBox(height: 48),

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text, height: 1.2),
          ).animate(target: active ? 1 : 0).fadeIn(duration: 300.ms).slideY(begin: 0.15),

          const SizedBox(height: 16),

          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
          ).animate(target: active ? 1 : 0).fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}
