import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';

final barberDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final dio = DioClient.instance;
  final barberRes = await dio.get('/barbers/$id/');

  List reviews = [], portfolio = [], services = [];
  try {
    final r = await dio.get('/barbers/$id/reviews/');
    final raw = r.data;
    reviews = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
  } catch (_) {}
  try {
    final r = await dio.get('/barbers/$id/portfolio/');
    final raw = r.data;
    portfolio = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
  } catch (_) {}
  try {
    final r = await dio.get('/barbers/$id/services/');
    final raw = r.data;
    services = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
  } catch (_) {}

  return {
    'barber': Map<String, dynamic>.from(barberRes.data),
    'reviews': reviews,
    'portfolio': portfolio,
    'services': services,
  };
});

class BarberDetailScreen extends ConsumerStatefulWidget {
  final int barberId;
  const BarberDetailScreen({super.key, required this.barberId});

  @override
  ConsumerState<BarberDetailScreen> createState() => _State();
}

class _State extends ConsumerState<BarberDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool? _isFavorite;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ref.watch(barberDetailProvider(widget.barberId)).when(
      data: _buildContent,
      loading: () => const _BarberDetailSkeleton(),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(leading: BackButton()),
        body: Center(child: ElevatedButton(
          onPressed: () => ref.invalidate(barberDetailProvider(widget.barberId)),
          child: const Text('Qayta urinish'),
        )),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final b = data['barber'] as Map<String, dynamic>;
    final reviews  = data['reviews']   as List;
    final portfolio = data['portfolio'] as List;
    final services  = data['services']  as List;

    final name       = b['full_name'] as String? ?? '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();
    final avatar     = b['avatar'] as String?;
    final bio        = b['bio'] as String? ?? '';
    final rating     = (b['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (b['review_count'] as num?)?.toInt() ?? (b['total_reviews'] as num?)?.toInt() ?? reviews.length;
    final experience  = (b['experience_years'] as num?)?.toInt();
    final specialty   = b['specialization'] as String? ?? b['specialty'] as String? ?? '';
    final instagram   = b['instagram'] as String?;
    final telegram    = b['telegram'] as String?;
    final salonName   = b['salon_name'] as String? ?? '';
    final salonId     = b['salon_id'] as int?;
    final salonAddress = b['salon_address'] as String? ?? '';
    final acceptsWalkIn = b['accepts_walk_in'] as bool? ?? true;

    _isFavorite ??= b['is_favorite'] as bool? ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // ── Hero image
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320,
                  child: Stack(fit: StackFit.expand, children: [
                    if (avatar != null)
                      Image.network(avatar, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gradientBg())
                    else
                      _gradientBg(),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                            begin: const Alignment(0, 0.2), end: Alignment.bottomCenter,
                          ),
                        )),
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Info card
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name.isEmpty ? 'Sartarosh' : name,
                          style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                        if (specialty.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(specialty, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                        if (salonName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: salonId != null ? () => context.push('/salon/$salonId') : null,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.storefront_rounded, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(salonName, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ],
                      ])),
                      if (instagram != null)
                        _socialBtn(Icons.camera_alt_outlined, AppColors.primary, AppColors.primaryLight, () async {
                          final h = instagram.startsWith('@') ? instagram.substring(1) : instagram;
                          try { await launchUrl(Uri.parse('https://instagram.com/$h'), mode: LaunchMode.externalApplication); } catch (_) {}
                        }),
                      if (telegram != null) ...[
                        const SizedBox(width: 8),
                        _socialBtn(Icons.telegram, const Color(0xFF24A1DE), const Color(0xFFE8F6FE), () async {
                          final h = telegram.startsWith('@') ? telegram.substring(1) : telegram;
                          try { await launchUrl(Uri.parse('https://t.me/$h'), mode: LaunchMode.externalApplication); } catch (_) {}
                        }),
                      ],
                    ]).animate().fadeIn(delay: 40.ms),
                    const SizedBox(height: 16),
                    _buildStatsRow(rating, reviewCount, experience, acceptsWalkIn),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(bio, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
                    ],
                  ]),
                ),
              ),

              // ── Booking buttons
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/barber/${widget.barberId}/book'),
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: const Text('Bron qilish'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                      ),
                    ),
                    if (acceptsWalkIn) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showWalkInSheet(context, salonName, salonAddress, salonId),
                          icon: const Icon(Icons.directions_walk_rounded, size: 18),
                          label: const Text('Walk-in'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ]).animate().fadeIn(delay: 100.ms),
                ),
              ),

              // ── Tab bar (pinned)
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
                    tabs: const [Tab(text: 'Portfolio'), Tab(text: 'Xizmatlar'), Tab(text: 'Sharhlar')],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabs,
              children: [
                _PortfolioTab(portfolio: portfolio),
                _ServicesTab(services: services, barberId: widget.barberId),
                _ReviewsTab(reviews: reviews),
              ],
            ),
          ),

          // ── Floating back + heart buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                  // Favorite / heart
                  GestureDetector(
                    onTap: () async {
                      final newVal = !(_isFavorite ?? false);
                      setState(() => _isFavorite = newVal);
                      try {
                        final r = await DioClient.instance.post('/barbers/${widget.barberId}/favorite/');
                        final server = r.data['is_favorite'] as bool?;
                        if (server != null && mounted) setState(() => _isFavorite = server);
                      } catch (_) {
                        if (mounted) setState(() => _isFavorite = !newVal);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(12)),
                      child: Icon(
                        _isFavorite == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavorite == true ? Colors.red : Colors.white,
                        size: 20,
                      ),
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

  Widget _buildStatsRow(double rating, int reviewCount, int? experience, bool acceptsWalkIn) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statCell(Icons.star_rounded, const Color(0xFFFFD700),
                rating > 0 ? rating.toStringAsFixed(1) : '—', 'Reyting'),
            _vDiv(),
            _statCell(Icons.chat_bubble_outline_rounded, AppColors.primary,
                '$reviewCount', 'Sharh'),
            if (experience != null) ...[
              _vDiv(),
              _statCell(Icons.workspace_premium_outlined, AppColors.success,
                  '$experience yil', 'Tajriba'),
            ],
            if (acceptsWalkIn) ...[
              _vDiv(),
              _statCell(Icons.directions_walk_rounded, const Color(0xFF7C3AED),
                  'Mumkin', 'Walk-in'),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 70.ms);
  }

  Widget _statCell(IconData icon, Color color, String value, String label) => Expanded(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w800)),
      const SizedBox(height: 1),
      Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _vDiv() => VerticalDivider(color: AppColors.border, width: 1, thickness: 0.5);

  Widget _socialBtn(IconData icon, Color color, Color bg, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 18),
    ),
  );

  Widget _gradientBg() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1A2550), Color(0xFF3A4EBD), Color(0xFF4E3AAE)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: const Center(child: Icon(Icons.content_cut_rounded, size: 72, color: Colors.white24)),
  );

  Widget _avatarFallback(String name) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF3A4EBD), Color(0xFF4E3AAE)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'B',
      style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w800),
    )),
  );

  void _showWalkInSheet(BuildContext ctx, String salonName, String salonAddress, int? salonId) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.directions_walk_rounded, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Walk-in', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text(
            'Oldindan bron qilmasdan to\'g\'ridan-to\'g\'ri kelishingiz mumkin.\nBo\'sh joy bo\'lsa sartarosh qabul qiladi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          if (salonName.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(salonName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
                  if (salonAddress.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(salonAddress, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13), maxLines: 2),
                  ],
                ])),
                if (salonId != null)
                  GestureDetector(
                    onTap: () { Navigator.pop(ctx); ctx.push('/salon/$salonId'); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Ko\'rish', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
              child: const Text('Tushunarli'),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _BarberDetailSkeleton extends StatelessWidget {
  const _BarberDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _Sk(width: double.infinity, height: 320, radius: 0),
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Sk(width: 160, height: 22, radius: 8),
                const SizedBox(height: 6),
                _Sk(width: 100, height: 14, radius: 6),
              ])),
              _Sk(width: 38, height: 38, radius: 12),
            ]),
            const SizedBox(height: 16),
            _Sk(width: double.infinity, height: 68, radius: 16),
            const SizedBox(height: 16),
            _Sk(width: double.infinity, height: 52, radius: 14),
          ]),
        ),
      ]),
    );
  }
}

class _Sk extends StatelessWidget {
  final double width, height, radius;
  const _Sk({required this.width, required this.height, required this.radius});
  @override
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(color: AppColors.warmGray, borderRadius: BorderRadius.circular(radius)),
  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppColors.surface.withOpacity(0.7));
}

// ── Portfolio tab ─────────────────────────────────────────────────────────────

class _PortfolioTab extends StatelessWidget {
  final List portfolio;
  const _PortfolioTab({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    if (portfolio.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.photo_library_outlined, size: 48, color: AppColors.border),
        SizedBox(height: 10),
        Text('Portfolio mavjud emas', style: TextStyle(color: AppColors.textTertiary, fontSize: 15)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: portfolio.length,
      itemBuilder: (_, i) {
        final item  = portfolio[i] as Map<String, dynamic>;
        final before = item['before_image'] as String?;
        final after  = item['after_image']  as String?;
        final desc   = item['caption']      as String? ?? '';

        return GestureDetector(
          onTap: () => _showDetail(context, before, after, desc),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Before / After images — full width, side by side
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 210,
                  child: Row(children: [
                    Expanded(child: Stack(fit: StackFit.expand, children: [
                      before != null
                          ? Image.network(before, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: AppColors.beige))
                          : Container(color: AppColors.beige),
                      _label('Oldin', dark: true),
                    ])),
                    Container(width: 2, color: Colors.white),
                    Expanded(child: Stack(fit: StackFit.expand, children: [
                      after != null
                          ? Image.network(after, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: AppColors.warmGray))
                          : Container(color: AppColors.warmGray),
                      _label('Keyin', dark: false),
                    ])),
                  ]),
                ),
              ),
              // Caption
              if (desc.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Text(
                    desc,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13,
                        fontWeight: FontWeight.w500, height: 1.45),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const SizedBox(height: 4),
            ]),
          ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideY(begin: 0.05),
        );
      },
    );
  }

  Widget _label(String text, {required bool dark}) => Positioned(
    top: 8, left: 8,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withOpacity(0.55) : AppColors.success.withOpacity(0.88),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    ),
  );

  void _showDetail(BuildContext context, String? before, String? after, String desc) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Row(children: [
                Expanded(child: before != null ? Image.network(before, height: 280, fit: BoxFit.cover) : Container(height: 280, color: AppColors.beige)),
                Expanded(child: after  != null ? Image.network(after,  height: 280, fit: BoxFit.cover) : Container(height: 280, color: AppColors.warmGray)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  Text('OLDIN', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  Text('KEYIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                ]),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 14),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Yopish', style: TextStyle(color: Colors.white60))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Services tab ──────────────────────────────────────────────────────────────

class _ServicesTab extends StatelessWidget {
  final List services;
  final int barberId;
  const _ServicesTab({required this.services, required this.barberId});

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const Center(child: Text('Xizmatlar mavjud emas', style: TextStyle(color: AppColors.textTertiary)));
    }

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in services) {
      final s = item as Map<String, dynamic>;
      final cat = (s['category_name'] as String?) ?? (s['category'] as String?) ?? 'Boshqa';
      grouped.putIfAbsent(cat, () => []).add(s);
    }
    final categories = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: categories.length,
      itemBuilder: (_, ci) {
        final cat   = categories[ci];
        final items = grouped[cat]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ci > 0) const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(cat.toUpperCase(), style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ),
            ...items.asMap().entries.map((e) {
              final s = e.value;
              final sName = s['name'] as String? ?? '';
              final price = (s['price'] as num? ?? 0).toInt();
              final dur   = (s['duration'] as num?)?.toInt() ?? (s['duration_minutes'] as num?)?.toInt() ?? 0;
              final desc  = s['description'] as String? ?? '';

              return Container(
                margin: EdgeInsets.only(bottom: e.key < items.length - 1 ? 10 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.content_cut_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(sName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    if (dur > 0) ...[
                      const SizedBox(height: 2),
                      Text('$dur daqiqa', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                    ],
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${_fmt(price)} so\'m', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                    GestureDetector(
                      onTap: () => context.push('/barber/$barberId/book?service=${s['id']}'),
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Bron', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ]),
              );
            }),
          ],
        );
      },
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
        final author  = (r['customer_name'] ?? r['user_name'] ?? 'Anonim') as String;
        final rating  = (r['rating'] as num?)?.toDouble() ?? 5.0;
        final comment = r['comment'] as String? ?? '';
        final date    = (r['created_at'] as String? ?? '').replaceAll(RegExp(r'T.*'), '');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 18, backgroundColor: AppColors.beige,
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
                itemCount: 5, itemSize: 15,
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

// ── Sticky tab bar ────────────────────────────────────────────────────────────

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
