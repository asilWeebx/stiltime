import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

// ── Data providers ────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _toList(dynamic raw) {
  final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : raw;
  return List<Map<String, dynamic>>.from(list as List? ?? []);
}

final _categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await DioClient.instance.get('/salons/categories/');
    return _toList(res.data);
  } catch (_) { return []; }
});

final _salonsProvider = FutureProvider.family<List<Map<String, dynamic>>, (String?, int?)>((ref, params) async {
  try {
    final (gender, categoryId) = params;
    final q = <String, dynamic>{'limit': 10};
    if (gender != null && gender.isNotEmpty) q['gender'] = gender;
    if (categoryId != null) q['category'] = categoryId;
    final res = await DioClient.instance.get('/salons/', queryParameters: q);
    return _toList(res.data);
  } catch (_) { return []; }
});

final _barbersProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, gender) async {
  try {
    final params = <String, dynamic>{'ordering': '-rating', 'limit': 10};
    if (gender != null && gender.isNotEmpty) params['gender'] = gender;
    final res = await DioClient.instance.get('/barbers/', queryParameters: params);
    return _toList(res.data);
  } catch (_) { return []; }
});

final _bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await DioClient.instance.get('/salons/banners/');
    return _toList(res.data);
  } catch (_) { return []; }
});

// ── Home Screen ───────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// Approximate centers of Uzbekistan regions (lat, lon, name)
const _uzRegions = [
  (41.2995, 69.2401, 'Toshkent'),
  (39.6547, 66.9758, 'Samarqand'),
  (39.7681, 64.4556, 'Buxoro'),
  (41.0011, 71.6727, 'Namangan'),
  (40.3777, 71.7836, 'Farg\'ona'),
  (40.1074, 65.3792, 'Navoiy'),
  (41.5498, 60.6103, 'Xorazm'),
  (37.2342, 67.2142, 'Surxondaryo'),
  (38.8617, 65.7950, 'Qashqadaryo'),
  (40.9294, 68.7844, 'Sirdaryo'),
  (40.7921, 72.3442, 'Andijon'),
  (39.6270, 63.6142, 'Qoraqalpog\'iston'),
  (41.5569, 70.9057, 'Jizzax'),
];

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  int _selectedCategoryIdx = 0;
  int? _selectedCategoryId;
  String _regionName = 'Joylashuv...';

  @override
  void initState() {
    super.initState();
    _detectRegion();
  }

  Future<void> _detectRegion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _regionName = 'O\'zbekiston');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _regionName = 'O\'zbekiston');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 5)),
      );
      String nearest = 'O\'zbekiston';
      double minDist = double.infinity;
      for (final r in _uzRegions) {
        final d = math.sqrt(math.pow(pos.latitude - r.$1, 2) + math.pow(pos.longitude - r.$2, 2));
        if (d < minDist) { minDist = d; nearest = r.$3; }
      }
      if (mounted) setState(() => _regionName = nearest);
    } catch (_) {
      if (mounted) setState(() => _regionName = 'O\'zbekiston');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final gender = user?.gender;
    final salons = ref.watch(_salonsProvider((gender, _selectedCategoryId)));
    final barbers = ref.watch(_barbersProvider(gender));
    final categoriesAsync = ref.watch(_categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Header(userName: user?.fullName.split(' ').first ?? 'Mehmon', regionName: _regionName),
            ),

            // ── Search ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(children: [
                      const Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Sartarosh yoki salon...', style: TextStyle(color: AppColors.textTertiary, fontSize: 15)),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 16),
                      ),
                    ]),
                  ),
                ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
              ),
            ),

            // ── Categories ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (cats) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: cats.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final isSelected = i == _selectedCategoryIdx;
                      final String label;
                      final String? iconUrl;
                      if (i == 0) {
                        label = 'Hammasi';
                        iconUrl = null;
                      } else {
                        final cat = cats[i - 1];
                        label = cat['name_uz'] as String? ?? cat['name'] as String? ?? '';
                        final raw = cat['icon'] as String?;
                        iconUrl = (raw != null && (raw.startsWith('http') || raw.startsWith('/'))) ? raw : null;
                      }
                      return GestureDetector(
                        onTap: () {
                          final newCatId = i == 0 ? null : (cats[i - 1]['id'] as int?);
                          setState(() {
                            _selectedCategoryIdx = i;
                            _selectedCategoryId = newCatId;
                          });
                          ref.invalidate(_salonsProvider((gender, newCatId)));
                        },
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected ? [] : AppColors.cardShadow,
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (i == 0)
                              Icon(Icons.apps_rounded, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary)
                            else if (iconUrl != null)
                              Image.network(iconUrl, width: 14, height: 14, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.text,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── Banners ──────────────────────────────────────────────────
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: _BannerSection(),
            ),

            // ── Top Barbers ───────────────────────────────────────────────
            SliverToBoxAdapter(child: const SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Top Sartaroshlar',
                subtitle: 'Eng yaxshi ustalar',
                onSeeAll: () => context.push('/barbers'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: barbers.when(
                  data: (list) => list.isEmpty
                      ? _emptyRow('Hozircha sartarosh yo\'q', Icons.content_cut_rounded)
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                          itemCount: list.length > 8 ? 8 : list.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => _BarberCard(
                            barber: list[i],
                            onTap: () => context.push('/barber/${list[i]['id']}'),
                          ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideX(begin: 0.1),
                        ),
                  loading: () => _barberSkeletonRow(),
                  error: (_, __) => _emptyRow('Yuklab bo\'lmadi', Icons.wifi_off_rounded),
                ),
              ),
            ),

            // ── Nearby Salons ─────────────────────────────────────────────
            SliverToBoxAdapter(child: const SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Yaqin Salonlar',
                subtitle: 'Sizga yaqin joylar',
                onSeeAll: () => context.push('/salons'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 230,
                child: salons.when(
                  data: (list) => list.isEmpty
                      ? _emptyRow('Hozircha salon yo\'q', Icons.storefront_rounded)
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                          itemCount: list.length > 6 ? 6 : list.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (_, i) => _SalonCard(
                            salon: list[i],
                            onTap: () => context.push('/salon/${list[i]['id']}'),
                          ).animate(delay: Duration(milliseconds: i * 70)).fadeIn().slideX(begin: 0.1),
                        ),
                  loading: () => _salonSkeletonRow(),
                  error: (_, __) => _emptyRow('Yuklab bo\'lmadi', Icons.wifi_off_rounded),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        current: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          switch (i) {
            case 1: context.push('/search').then((_) => setState(() => _navIndex = 0)); break;
            case 2: context.push('/map').then((_) => setState(() => _navIndex = 0)); break;
            case 3: context.push('/bookings').then((_) => setState(() => _navIndex = 0)); break;
            case 4: context.push('/profile').then((_) => setState(() => _navIndex = 0)); break;
          }
        },
      ),
    );
  }

  Widget _barberSkeletonRow() => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => _SkeletonBox(width: 130, height: 200, radius: 20),
      );

  Widget _salonSkeletonRow() => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => _SkeletonBox(width: 200, height: 188, radius: 20),
      );

  Widget _emptyRow(String message, IconData icon) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.border, size: 32),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
      ],
    ),
  );
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String userName;
  final String regionName;
  const _Header({required this.userName, required this.regionName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(regionName, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Text(
                  'Salom, $userName',
                  style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                ),
              ],
            ).animate().fadeIn().slideY(begin: -0.1),
          ),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow,
              ),
              child: const Icon(Icons.notifications_outlined, color: AppColors.text, size: 22),
            ).animate().fadeIn(delay: 100.ms),
          ),
        ],
      ),
    );
  }
}

// ── Banner section ────────────────────────────────────────────────────────────

class _BannerSection extends ConsumerStatefulWidget {
  _BannerSection();

  @override
  ConsumerState<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends ConsumerState<_BannerSection> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(_bannersProvider);
    return bannersAsync.when(
      loading: () => const SizedBox(
        height: 184,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        final items = banners;
        return Column(
          children: [
            SizedBox(
              height: 184,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: items.length,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 20 : 8, right: i == items.length - 1 ? 20 : 8),
                  child: _ApiBannerCard(banner: items[i]),
                ),
              ),
            ),
            if (items.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (i) => AnimatedContainer(
                  duration: 300.ms,
                  width: i == _current ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i == _current ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ApiBannerCard extends StatelessWidget {
  final Map<String, dynamic> banner;
  const _ApiBannerCard({required this.banner});

  Future<void> _handleTap(BuildContext context) async {
    final link = banner['link'] as String?;
    final salonId = banner['salon'] as int?;

    if (link != null && link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri != null) {
        try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
      }
    } else if (salonId != null) {
      context.push('/salon/$salonId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = banner['image'] as String?;
    final title = banner['title'] as String? ?? '';
    final description = banner['description'] as String? ?? '';
    final hasLink = (banner['link'] as String? ?? '').isNotEmpty || banner['salon'] != null;

    return GestureDetector(
      onTap: hasLink ? () => _handleTap(context) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
            else
              _fallback(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (title.isNotEmpty) Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (hasLink) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Batafsil →', style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF2D3561)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
  );
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.subtitle, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4)),
            Text(title, style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          ]),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Hammasi', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// ── Barber card ───────────────────────────────────────────────────────────────

class _BarberCard extends StatelessWidget {
  final Map<String, dynamic> barber;
  final VoidCallback onTap;
  const _BarberCard({required this.barber, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = barber['full_name'] as String? ?? 'Sartarosh';
    final avatar = barber['avatar'] as String?;
    final rating = (barber['rating'] as num?)?.toDouble() ?? 0.0;
    final specialty = barber['specialization'] as String? ?? barber['specialty'] as String? ?? 'Sartarosh';
    final reviewCount = barber['review_count'] as int? ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 130,
                width: 130,
                child: avatar != null
                    ? Image.network(avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(name))
                    : _avatarFallback(name),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.split(' ').first, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(specialty, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 13, color: AppColors.star),
                    const SizedBox(width: 3),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.text)),
                    const SizedBox(width: 3),
                    Text('($reviewCount)', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) => Container(
    color: AppColors.beige,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'B',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 36, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

// ── Salon card ────────────────────────────────────────────────────────────────

class _SalonCard extends StatelessWidget {
  final Map<String, dynamic> salon;
  final VoidCallback onTap;
  const _SalonCard({required this.salon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = salon['name'] as String? ?? 'Salon';
    final cover = salon['cover_image'] as String?;
    final rating = (salon['rating'] as num?)?.toDouble() ?? 0.0;
    final isOpen = salon['is_open'] == true;
    final address = salon['address'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 120,
                width: 210,
                child: Stack(
                  children: [
                    cover != null
                        ? Image.network(cover, width: 210, height: 120, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgFallback(name))
                        : _imgFallback(name),
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOpen ? AppColors.success : AppColors.textTertiary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(isOpen ? 'Ochiq' : 'Yopiq', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(address, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 13, color: AppColors.star),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.text)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 16),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgFallback(String name) => Container(
    color: AppColors.beige,
    child: Center(child: Icon(Icons.storefront_rounded, color: AppColors.textTertiary, size: 36)),
  );
}

// ── Before/After transform card ───────────────────────────────────────────────

// ── Skeleton box ──────────────────────────────────────────────────────────────

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBox({required this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.warmGray, borderRadius: BorderRadius.circular(radius)),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppColors.surface.withOpacity(0.6));
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'Bosh sahifa'),
      (Icons.search_rounded, Icons.search_rounded, 'Qidiruv'),
      (Icons.map_rounded, Icons.map_outlined, 'Xarita'),
      (Icons.calendar_today_rounded, Icons.calendar_today_outlined, 'Bronlar'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == current;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primaryLight : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            selected ? items[i].$1 : items[i].$2,
                            color: selected ? AppColors.primary : AppColors.textTertiary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$3,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected ? AppColors.primary : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
