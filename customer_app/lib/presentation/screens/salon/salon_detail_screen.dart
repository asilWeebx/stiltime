import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/salon_model.dart';

final _barberServicesProvider = FutureProvider.family<List, int>((ref, barberId) async {
  final r = await DioClient.instance.get('/barbers/$barberId/services/');
  final raw = r.data;
  return raw is Map ? (raw['results'] ?? raw['data'] ?? []) as List : (raw as List? ?? []);
});

final _salonDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final dio = DioClient.instance;

  final salonRes = await dio.get('/salons/$id/');

  List reviews = [];
  List barbers = [];
  List services = [];

  try {
    final r = await dio.get('/salons/$id/reviews/');
    final raw = r.data;
    reviews = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
  } catch (_) {}

  try {
    final r = await dio.get('/barbers/', queryParameters: {'salon': id});
    final raw = r.data;
    barbers = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
  } catch (_) {}

  try {
    final r = await dio.get('/salons/$id/services/');
    final raw = r.data;
    services = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
  } catch (_) {}

  return {
    'salon': SalonModel.fromJson(Map<String, dynamic>.from(salonRes.data)),
    'reviews': reviews,
    'barbers': barbers,
    'services': services,
  };
});

class SalonDetailScreen extends ConsumerStatefulWidget {
  final int salonId;
  const SalonDetailScreen({super.key, required this.salonId});

  @override
  ConsumerState<SalonDetailScreen> createState() => _State();
}

class _State extends ConsumerState<SalonDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late PageController _pageController;
  int _imageIndex = 0;
  bool? _isFavorite;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(_salonDetailProvider(widget.salonId)).when(
      data: _buildContent,
      loading: () => const _SalonDetailSkeleton(),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(leading: BackButton()),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(_salonDetailProvider(widget.salonId)),
              child: const Text('Qayta urinish'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final salon = data['salon'] as SalonModel;
    final reviews = data['reviews'] as List;
    final barbers = data['barbers'] as List;
    final services = data['services'] as List;
    _isFavorite ??= salon.isFavorite;

    final images = [
      if (salon.coverImage != null) salon.coverImage!,
      ...?salon.images,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      // Stack: scroll content underneath + fixed back/fav buttons on top
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Image carousel (plain SliverToBoxAdapter — no SliverAppBar,
              //    so PageView horizontal gestures work without conflicts)
              SliverToBoxAdapter(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    if (_pageController.hasClients) {
                      final newOffset = (_pageController.position.pixels - details.delta.dx)
                          .clamp(0.0, _pageController.position.maxScrollExtent);
                      _pageController.position.moveTo(newOffset);
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    if (!_pageController.hasClients) return;
                    final velocity = details.primaryVelocity ?? 0;
                    final page = _pageController.page ?? 0;
                    if (velocity < -300) {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    } else if (velocity > 300) {
                      _pageController.previousPage(
                          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    } else {
                      _pageController.animateToPage(
                          page.round(),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut);
                    }
                  },
                  child: SizedBox(
                    height: 310,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (images.isEmpty)
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1A1A2E), Color(0xFF2D3561)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Colors.white24, size: 80),
                          )
                        else
                          PageView.builder(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: images.length,
                            onPageChanged: (i) => setState(() => _imageIndex = i),
                            itemBuilder: (_, i) => Image.network(
                              images[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: AppColors.beige),
                            ),
                          ),
                        // gradient — IgnorePointer so it doesn't intercept swipes
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                                  begin: const Alignment(0, 0.3),
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // dots indicator
                        if (images.length > 1)
                          Positioned(
                            bottom: 14, left: 0, right: 0,
                            child: IgnorePointer(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(images.length, (i) => AnimatedContainer(
                                  duration: 200.ms,
                                  width: i == _imageIndex ? 20 : 6, height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: i == _imageIndex ? Colors.white : Colors.white38,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                )),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

          // Salon info
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Text(salon.name, style: const TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1)),
                    ),
                    if (salon.isOpen != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: salon.isOpen! ? AppColors.successLight : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(salon.isOpen! ? 'Ochiq' : 'Yopiq',
                            style: TextStyle(color: salon.isOpen! ? AppColors.success : AppColors.error, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                  ]).animate().fadeIn(delay: 80.ms),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(salon.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip(Icons.star_rounded, '${salon.rating.toStringAsFixed(1)}  (${reviews.length})', AppColors.star, AppColors.warningLight),
                    _chip(Icons.people_outline_rounded, '${barbers.length} sartarosh', AppColors.primary, AppColors.primaryLight),
                    _chip(Icons.design_services_outlined, '${services.length} xizmat', AppColors.success, AppColors.successLight),
                  ]).animate().fadeIn(delay: 120.ms),
                ],
              ),
            ),
          ),

          // Action buttons
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/salon/${salon.id}/book'),
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text('Bron qilish'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                if (salon.phone != null)
                  _iconActionBtn(Icons.phone_rounded, AppColors.success, AppColors.successLight, () async {
                    final uri = Uri(scheme: 'tel', path: salon.phone);
                    try { await launchUrl(uri); } catch (_) {}
                  }),
                const SizedBox(width: 8),
                _iconActionBtn(Icons.map_rounded, AppColors.primary, AppColors.primaryLight, () async {
                  final lat = salon.latitude;
                  final lon = salon.longitude;
                  if (lat == null || lon == null) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Manzil koordinatalari topilmadi')),
                    );
                    return;
                  }
                  final yandexApp = Uri.parse('yandexmaps://maps.yandex.ru/?ll=$lon,$lat&pt=$lon,$lat&z=16');
                  final yandexWeb = Uri.parse('https://yandex.com/maps/?ll=$lon,$lat&z=16&pt=$lon,$lat');
                  if (await canLaunchUrl(yandexApp)) {
                    await launchUrl(yandexApp);
                  } else {
                    await launchUrl(yandexWeb, mode: LaunchMode.externalApplication);
                  }
                }),
              ]),
            ),
          ),

          // Sticky tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBar(
              TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                dividerColor: AppColors.border,
                tabs: const [Tab(text: 'Xizmatlar'), Tab(text: 'Sartaroshlar'), Tab(text: 'Sharhlar')],
              ),
            ),
          ),

          SliverFillRemaining(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ServicesTab(barbers: barbers, salonId: salon.id),
                _BarbersTab(barbers: barbers, salonId: salon.id),
                _ReviewsTab(reviews: reviews),
              ],
            ),
          ),
              ],
            ),
            // back + favorite buttons float above scroll view
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final newVal = !(_isFavorite ?? false);
                        setState(() => _isFavorite = newVal);
                        try {
                          final r = await DioClient.instance.post('/salons/${salon.id}/favorite/');
                          final serverVal = r.data['is_favorite'] as bool?;
                          if (serverVal != null && mounted) setState(() => _isFavorite = serverVal);
                        } catch (_) {
                          if (mounted) setState(() => _isFavorite = !newVal);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                        child: Icon(_isFavorite == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isFavorite == true ? Colors.red : Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _chip(IconData icon, String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _iconActionBtn(IconData icon, Color color, Color bg, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: color, size: 22),
    ),
  );
}

// ── Services tab ──────────────────────────────────────────────────────────────

class _ServicesTab extends ConsumerStatefulWidget {
  final List barbers;
  final int salonId;
  const _ServicesTab({required this.barbers, required this.salonId});

  @override
  ConsumerState<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends ConsumerState<_ServicesTab> {
  int? _selectedBarberId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barber filter strip
        if (widget.barbers.isNotEmpty)
          Container(
            height: 60,
            color: AppColors.surface,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: widget.barbers.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  final isAll = _selectedBarberId == null;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBarberId = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isAll ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isAll ? AppColors.primary : AppColors.border),
                      ),
                      child: Center(child: Text('Hammasi',
                        style: TextStyle(color: isAll ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                      )),
                    ),
                  );
                }
                final b = widget.barbers[i - 1] as Map<String, dynamic>;
                final bid = b['id'] as int;
                final name = b['full_name'] as String? ?? '${b['first_name'] ?? ''}'.trim();
                final avatar = b['avatar'] as String?;
                final isSelected = _selectedBarberId == bid;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBarberId = bid),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLight : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      ClipOval(child: SizedBox(
                        width: 22, height: 22,
                        child: avatar != null
                            ? Image.network(avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _av(name))
                            : _av(name),
                      )),
                      const SizedBox(width: 6),
                      Text(name.split(' ').first,
                        style: TextStyle(color: isSelected ? AppColors.primary : AppColors.text, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 13),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _selectedBarberId != null
              ? _BarberServicesList(barberId: _selectedBarberId!, salonId: widget.salonId)
              : _AllBarbersServices(barbers: widget.barbers, salonId: widget.salonId),
        ),
      ],
    );
  }

  Widget _av(String name) => Container(
    color: AppColors.beige,
    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'B',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800))),
  );
}

class _BarberServicesList extends ConsumerWidget {
  final int barberId;
  final int salonId;
  const _BarberServicesList({required this.barberId, required this.salonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(_barberServicesProvider(barberId)).when(
      data: (services) {
        if (services.isEmpty) {
          return const Center(child: Text('Xizmatlar mavjud emas', style: TextStyle(color: AppColors.textTertiary)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ServiceCard(s: services[i] as Map<String, dynamic>, salonId: salonId, barberId: barberId),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Xatolik', style: TextStyle(color: AppColors.error))),
    );
  }
}

class _AllBarbersServices extends ConsumerWidget {
  final List barbers;
  final int salonId;
  const _AllBarbersServices({required this.barbers, required this.salonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (barbers.isEmpty) {
      return const Center(child: Text('Sartaroshlar topilmadi', style: TextStyle(color: AppColors.textTertiary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: barbers.length,
      itemBuilder: (_, i) {
        final b = barbers[i] as Map<String, dynamic>;
        return _BarberServicesSection(
          barberId: b['id'] as int,
          barberName: b['full_name'] as String? ?? 'Sartarosh',
          salonId: salonId,
        );
      },
    );
  }
}

class _BarberServicesSection extends ConsumerWidget {
  final int barberId;
  final String barberName;
  final int salonId;
  const _BarberServicesSection({required this.barberId, required this.barberName, required this.salonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(_barberServicesProvider(barberId)).when(
      data: (services) {
        if (services.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Row(children: [
                Container(
                  width: 3, height: 16,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                Text(barberName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
              ]),
            ),
            ...List.generate(services.length, (i) => Padding(
              padding: EdgeInsets.only(bottom: i < services.length - 1 ? 10 : 0),
              child: _ServiceCard(s: services[i] as Map<String, dynamic>, salonId: salonId, barberId: barberId),
            )),
            const SizedBox(height: 20),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> s;
  final int salonId;
  final int barberId;
  const _ServiceCard({required this.s, required this.salonId, required this.barberId});

  @override
  Widget build(BuildContext context) {
    final name = s['name'] as String? ?? '';
    final price = (s['price'] as num? ?? 0).toInt();
    final duration = (s['duration'] as num?)?.toInt() ?? (s['duration_minutes'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.content_cut_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
          const SizedBox(height: 3),
          if (duration > 0)
            Row(children: [
              const Icon(Icons.schedule_outlined, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('$duration daqiqa', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${_fmt(price)} so\'m', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => context.push('/salon/$salonId/book?barber=$barberId'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: const Text('Bron', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Barbers tab ───────────────────────────────────────────────────────────────

class _BarbersTab extends StatelessWidget {
  final List barbers;
  final int salonId;
  const _BarbersTab({required this.barbers, required this.salonId});

  @override
  Widget build(BuildContext context) {
    if (barbers.isEmpty) {
      return const Center(child: Text('Sartaroshlar topilmadi', style: TextStyle(color: AppColors.textTertiary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: barbers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final b = barbers[i] as Map<String, dynamic>;
        final name = b['full_name'] as String? ?? 'Sartarosh';
        final avatar = b['avatar'] as String?;
        final rating = (b['rating'] as num?)?.toStringAsFixed(1) ?? '—';
        final specialty = b['specialization'] as String? ?? b['specialty'] as String? ?? '';

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final id = b['id'];
            if (id != null) context.push('/barber/$id');
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(children: [
              ClipOval(
                child: SizedBox(
                  width: 56, height: 56,
                  child: avatar != null
                      ? Image.network(avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _av(name))
                      : _av(name),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
                if (specialty.isNotEmpty) Text(specialty, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 13, color: AppColors.star),
                  const SizedBox(width: 3),
                  Text(rating, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.text)),
                ]),
              ])),
              GestureDetector(
                onTap: () => context.push('/salon/$salonId/book?barber=${b['id']}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Bron', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _av(String name) => Container(
    color: AppColors.beige,
    child: Center(child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 20, fontWeight: FontWeight.w800))),
  );
}

// ── Reviews tab ───────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  final List reviews;
  const _ReviewsTab({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.star_border_rounded, size: 48, color: AppColors.border),
        SizedBox(height: 10),
        Text('Hali sharhlar yo\'q', style: TextStyle(color: AppColors.textTertiary, fontSize: 15)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = reviews[i] as Map<String, dynamic>;
        final author = (r['customer_name'] ?? r['user_name'] ?? 'Anonim') as String;
        final rating = (r['rating'] as num?)?.toDouble() ?? 5.0;
        final comment = r['comment'] as String? ?? '';
        final date = (r['created_at'] as String? ?? '').replaceAll(RegExp(r'T.*'), '');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.beige,
                child: Text(author[0].toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
                if (date.isNotEmpty) Text(date, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ])),
              RatingBarIndicator(
                rating: rating,
                itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColors.star),
                itemCount: 5,
                itemSize: 16,
                unratedColor: AppColors.border,
              ),
            ]),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(comment, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
            ],
          ]),
        );
      },
    );
  }
}

// ── Salon detail skeleton ─────────────────────────────────────────────────────

class _SalonDetailSkeleton extends StatelessWidget {
  const _SalonDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Hero image placeholder
        _Shimmer(width: double.infinity, height: 310, radius: 0),
        // Info card
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Shimmer(width: 200, height: 24, radius: 8),
            const SizedBox(height: 10),
            _Shimmer(width: 150, height: 14, radius: 6),
            const SizedBox(height: 16),
            Row(children: [
              _Shimmer(width: 80, height: 26, radius: 13),
              const SizedBox(width: 8),
              _Shimmer(width: 100, height: 26, radius: 13),
              const SizedBox(width: 8),
              _Shimmer(width: 90, height: 26, radius: 13),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _Shimmer(width: double.infinity, height: 48, radius: 14)),
              const SizedBox(width: 10),
              _Shimmer(width: 48, height: 48, radius: 14),
              const SizedBox(width: 8),
              _Shimmer(width: 48, height: 48, radius: 14),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _Shimmer({required this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(color: AppColors.warmGray, borderRadius: BorderRadius.circular(radius)),
  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppColors.surface.withOpacity(0.7));
}

// ── Sticky tab bar delegate ───────────────────────────────────────────────────

class _StickyTabBar extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBar(this.tabBar);

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: AppColors.surface, child: tabBar);

  @override
  bool shouldRebuild(covariant _StickyTabBar old) => false;
}
