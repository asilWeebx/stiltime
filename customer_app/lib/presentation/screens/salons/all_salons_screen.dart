import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _toList(dynamic raw) {
  final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : raw;
  return List<Map<String, dynamic>>.from(list as List? ?? []);
}

final _salonsListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, search) async {
  try {
    final q = <String, dynamic>{'limit': 50};
    if (search.isNotEmpty) q['search'] = search;
    final res = await DioClient.instance.get('/salons/', queryParameters: q);
    return _toList(res.data);
  } catch (_) { return []; }
});

final _barbersListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, search) async {
  try {
    final q = <String, dynamic>{'limit': 50, 'ordering': '-rating'};
    if (search.isNotEmpty) q['search'] = search;
    final res = await DioClient.instance.get('/barbers/', queryParameters: q);
    return _toList(res.data);
  } catch (_) { return []; }
});

// ── Salons List Screen ────────────────────────────────────────────────────────

class SalonsListScreen extends ConsumerStatefulWidget {
  const SalonsListScreen({super.key});

  @override
  ConsumerState<SalonsListScreen> createState() => _SalonsListScreenState();
}

class _SalonsListScreenState extends ConsumerState<SalonsListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_salonsListProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: const Text('Salonlar',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _SearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              onClear: () { _searchCtrl.clear(); setState(() => _query = ''); },
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => _errorWidget(() => ref.invalidate(_salonsListProvider(_query))),
        data: (list) {
          if (list.isEmpty) return _emptyWidget('Salon topilmadi', Icons.storefront_outlined);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_salonsListProvider(_query)),
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              itemCount: list.length,
              itemBuilder: (_, i) => _SalonCard(salon: list[i])
                  .animate(delay: Duration(milliseconds: i * 40))
                  .fadeIn()
                  .slideY(begin: 0.06),
            ),
          );
        },
      ),
    );
  }
}

// ── Barbers List Screen ───────────────────────────────────────────────────────

class BarbersListScreen extends ConsumerStatefulWidget {
  const BarbersListScreen({super.key});

  @override
  ConsumerState<BarbersListScreen> createState() => _BarbersListScreenState();
}

class _BarbersListScreenState extends ConsumerState<BarbersListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_barbersListProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: const Text('Sartaroshlar',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _SearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              onClear: () { _searchCtrl.clear(); setState(() => _query = ''); },
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => _errorWidget(() => ref.invalidate(_barbersListProvider(_query))),
        data: (list) {
          if (list.isEmpty) return _emptyWidget('Sartarosh topilmadi', Icons.content_cut_rounded);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_barbersListProvider(_query)),
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              itemCount: list.length,
              itemBuilder: (_, i) => _BarberListCard(barber: list[i])
                  .animate(delay: Duration(milliseconds: i * 40))
                  .fadeIn()
                  .slideY(begin: 0.06),
            ),
          );
        },
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({required this.controller, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        const Icon(Icons.search_rounded, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.text, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Qidiruv...',
              hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ),
        if (controller.text.isNotEmpty)
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
          ),
      ]),
    );
  }
}

// ── Salon Card (full-width) ───────────────────────────────────────────────────

class _SalonCard extends StatelessWidget {
  final Map<String, dynamic> salon;
  const _SalonCard({required this.salon});

  @override
  Widget build(BuildContext context) {
    final name = salon['name'] as String? ?? 'Salon';
    final cover = salon['cover_image'] as String?;
    final rating = (salon['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = salon['review_count'] ?? salon['total_reviews'] ?? 0;
    final address = salon['address'] as String? ?? '';
    final isOpen = salon['is_open'] == true;
    final openUntil = salon['open_until'] as String?;
    final id = salon['id'];

    return GestureDetector(
      onTap: () { if (id != null) context.push('/salon/$id'); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
                height: 190,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    cover != null
                        ? Image.network(cover, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imgFallback(name))
                        : _imgFallback(name),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.25)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isOpen ? AppColors.success : Colors.red.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOpen ? 'Ochiq' : 'Yopiq',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_rounded, size: 13, color: AppColors.star),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.text)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.text),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  if (openUntil != null && openUntil.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text('$openUntil gacha ochiq',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                    ])
                  else if (address.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(address,
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.text)),
                    const SizedBox(width: 6),
                    Text('($reviewCount Sharhlar)',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
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
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary.withOpacity(0.7), AppColors.primaryDark],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800)),
    ),
  );
}

// ── Barber List Card (full-width horizontal) ──────────────────────────────────

class _BarberListCard extends StatelessWidget {
  final Map<String, dynamic> barber;
  const _BarberListCard({required this.barber});

  @override
  Widget build(BuildContext context) {
    final name = barber['full_name'] as String? ?? 'Sartarosh';
    final avatar = barber['avatar'] as String?;
    final rating = (barber['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = barber['review_count'] ?? barber['total_reviews'] ?? 0;
    final specialty = barber['specialization'] as String? ?? barber['specialty'] as String? ?? 'Sartarosh';
    final isOnline = barber['is_online'] == true;
    final id = barber['id'];

    return GestureDetector(
      onTap: () { if (id != null) context.push('/barber/$id'); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 68, height: 68,
                child: avatar != null
                    ? Image.network(avatar, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(name))
                    : _avatarFallback(name),
              ),
            ),
            if (isOnline)
              Positioned(
                right: -2, bottom: -2,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(specialty,
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 13, color: AppColors.star),
                  const SizedBox(width: 3),
                  Text(rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.text)),
                  const SizedBox(width: 6),
                  Text('($reviewCount sharh)',
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () { if (id != null) context.push('/barber/$id'); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Bron',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _avatarFallback(String name) => Container(
    decoration: BoxDecoration(
      gradient: AppColors.gradientPrimary,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Center(
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'B',
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
    ),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _emptyWidget(String text, IconData icon) => Center(
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: 80, height: 80,
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(24)),
      child: Icon(icon, color: AppColors.primary, size: 40),
    ),
    const SizedBox(height: 16),
    Text(text, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
  ]),
);

Widget _errorWidget(VoidCallback onRetry) => Center(
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.border),
    const SizedBox(height: 12),
    const Text('Yuklashda xato', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    TextButton(onPressed: onRetry, child: const Text('Qayta urinish')),
  ]),
);
