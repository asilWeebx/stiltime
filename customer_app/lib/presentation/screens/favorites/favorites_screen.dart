import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/salon_model.dart';
import '../../widgets/common/salon_card.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final favoriteSalonsProvider = FutureProvider<List<SalonModel>>((ref) async {
  final res = await DioClient.instance.get('/salons/favorites/');
  final raw = res.data;
  final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
  return (list as List).map((e) => SalonModel.fromJson(e as Map<String, dynamic>)).toList();
});

final favoriteBarbersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await DioClient.instance.get('/barbers/favorites/');
  final raw = res.data;
  final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
  return (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Sevimlilar', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          dividerColor: AppColors.border,
          tabs: const [
            Tab(text: 'Mutaxasislar'),
            Tab(text: 'Salonlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _FavoriteBarbersList(),
          _FavoriteSalonsList(),
        ],
      ),
    );
  }
}

// ── Barbers list ──────────────────────────────────────────────────────────────

class _FavoriteBarbersList extends ConsumerWidget {
  const _FavoriteBarbersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(favoriteBarbersProvider).when(
      data: (barbers) {
        if (barbers.isEmpty) {
          return _emptyState(
            Icons.person_search_rounded,
            'Sevimli mutaxasislar yo\'q',
            'Mutaxasislar sahifasida ♡ tugmasini bosing',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(favoriteBarbersProvider),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: barbers.length,
            itemBuilder: (_, i) {
              final b = barbers[i];
              return Dismissible(
                key: Key('barber_${b['id']}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.favorite_border_rounded, color: Colors.red),
                ),
                onDismissed: (_) async {
                  await DioClient.instance.post('/barbers/${b['id']}/favorite/');
                  ref.invalidate(favoriteBarbersProvider);
                },
                child: _BarberCard(b: b).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideX(begin: 0.06),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          const Text('Yuklab bo\'lmadi', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: () => ref.invalidate(favoriteBarbersProvider), child: const Text('Qayta urinish')),
        ]),
      ),
    );
  }
}

class _BarberCard extends StatelessWidget {
  final Map<String, dynamic> b;
  const _BarberCard({required this.b});

  @override
  Widget build(BuildContext context) {
    final name   = b['full_name'] as String? ?? '';
    final salon  = b['salon_name'] as String? ?? '';
    final avatar = b['avatar'] as String?;
    final rating = (b['rating'] as num?)?.toDouble() ?? 0.0;
    final online = b['is_online'] as bool? ?? false;
    final specialty = b['specialization'] as String? ?? b['specialty'] as String? ?? '';

    return GestureDetector(
      onTap: () => context.push('/barber/${b['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                child: ClipOval(
                  child: avatar != null && avatar.isNotEmpty
                      ? Image.network(avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(name))
                      : _initials(name),
                ),
              ),
              if (online)
                Container(
                  width: 13, height: 13,
                  decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 2)),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15)),
              if (specialty.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(specialty, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
              if (salon.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.storefront_rounded, size: 11, color: AppColors.textTertiary),
                  const SizedBox(width: 3),
                  Text(salon, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ]),
              ],
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (rating > 0) Row(children: [
              const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
              const SizedBox(width: 2),
              Text(rating.toStringAsFixed(1), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
          ]),
        ]),
      ),
    );
  }

  Widget _initials(String name) => Container(
    color: AppColors.primaryLight,
    child: Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'B',
      style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800),
    )),
  );
}

// ── Salons list ───────────────────────────────────────────────────────────────

class _FavoriteSalonsList extends ConsumerWidget {
  const _FavoriteSalonsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(favoriteSalonsProvider).when(
      data: (salons) {
        if (salons.isEmpty) {
          return _emptyState(
            Icons.storefront_rounded,
            'Sevimli salonlar yo\'q',
            'Salon sahifasida ♡ tugmasini bosing',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(favoriteSalonsProvider),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: salons.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: Key('salon_${salons[i].id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.favorite_border_rounded, color: Colors.red),
                ),
                onDismissed: (_) async {
                  await DioClient.instance.post('/salons/${salons[i].id}/favorite/');
                  ref.invalidate(favoriteSalonsProvider);
                },
                child: SalonCard(salon: salons[i])
                    .animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideX(begin: 0.06),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          const Text('Yuklab bo\'lmadi', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: () => ref.invalidate(favoriteSalonsProvider), child: const Text('Qayta urinish')),
        ]),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

Widget _emptyState(IconData icon, String title, String subtitle) {
  return Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
        child: Icon(icon, size: 38, color: AppColors.primary),
      ),
      const SizedBox(height: 20),
      Text(title, style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13), textAlign: TextAlign.center),
    ]).animate().fadeIn().scale(begin: const Offset(0.92, 0.92)),
  );
}
