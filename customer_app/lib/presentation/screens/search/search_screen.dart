import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/salon_model.dart';
import '../../widgets/common/salon_card.dart';
import '../../widgets/common/barber_card.dart';
import '../../../core/network/dio_client.dart';

enum SearchFilter { all, salons, barbers }

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchFilterProvider = StateProvider<SearchFilter>((ref) => SearchFilter.all);

final searchResultsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, query) async {
  if (query.isEmpty) return {'salons': [], 'barbers': []};
  final dio = DioClient.instance;
  final results = await Future.wait([
    dio.get('/salons/', queryParameters: {'search': query, 'page_size': 10}),
    dio.get('/barbers/', queryParameters: {'search': query, 'page_size': 10}),
  ]);
  return {
    'salons': (results[0].data['results'] as List? ?? []).map((e) => SalonModel.fromJson(e)).toList(),
    'barbers': results[1].data['results'] as List? ?? [],
  };
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  final List<String> _recentSearches = [
    'Soch kesish',
    'Soqol olish',
    'Boshqaruv',
    'Manikür',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final filter = ref.watch(searchFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          style: const TextStyle(color: AppColors.text, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Salon yoki sartarosh...',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
              onPressed: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: SearchFilter.values.map((f) {
                final labels = {
                  SearchFilter.all: "Hammasi",
                  SearchFilter.salons: "Salonlar",
                  SearchFilter.barbers: "Barberlar",
                };
                final isSelected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ref.read(searchFilterProvider.notifier).state = f,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.warmGray,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        labels[f]!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: query.isEmpty
                ? _buildRecentSearches()
                : ref.watch(searchResultsProvider(query)).when(
                    data: (data) => _buildResults(data, filter),
                    loading: () => const _SearchSkeleton(),
                    error: (e, _) => Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.border),
                        const SizedBox(height: 12),
                        Text('Xatolik yuz berdi', style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      ]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        const Text('Oxirgi qidiruvlar', style: TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        ..._recentSearches.asMap().entries.map((e) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warmGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history, size: 18, color: AppColors.textTertiary),
          ),
          title: Text(e.value, style: const TextStyle(color: AppColors.text, fontSize: 15)),
          trailing: const Icon(Icons.north_west, size: 16, color: AppColors.textTertiary),
          onTap: () {
            _controller.text = e.value;
            ref.read(searchQueryProvider.notifier).state = e.value;
          },
        ).animate(delay: Duration(milliseconds: e.key * 60)).fadeIn().slideX(begin: -0.1)),
      ],
    );
  }

  Widget _buildResults(Map<String, dynamic> data, SearchFilter filter) {
    final salons = data['salons'] as List<SalonModel>;
    final barbers = data['barbers'] as List;

    final showSalons = filter == SearchFilter.all || filter == SearchFilter.salons;
    final showBarbers = filter == SearchFilter.all || filter == SearchFilter.barbers;

    if (salons.isEmpty && barbers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.warmGray, shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded, size: 40, color: AppColors.border),
            ),
            const SizedBox(height: 16),
            const Text("Natija topilmadi", style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text("Boshqa kalit so'z bilan urinib ko'ring", style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showSalons && salons.isNotEmpty) ...[
          const Text('Salonlar', style: TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...salons.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SalonCard(salon: s),
          )),
          const SizedBox(height: 16),
        ],
        if (showBarbers && barbers.isNotEmpty) ...[
          const Text('Sartaroshlar', style: TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: barbers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => BarberCard(barber: barbers[i]),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Search skeleton ───────────────────────────────────────────────────────────

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _shimmer(80, 12, 6),
        const SizedBox(height: 12),
        ...List.generate(3, (_) => _salonSkeletonCard()),
        const SizedBox(height: 20),
        _shimmer(100, 12, 6),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => _barberSkeletonCard(),
          ),
        ),
      ],
    );
  }

  Widget _salonSkeletonCard() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(children: [
      _shimmer(60, 60, 14),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _shimmer(130, 14, 7),
        const SizedBox(height: 8),
        _shimmer(90, 11, 5),
        const SizedBox(height: 6),
        _shimmer(70, 11, 5),
      ])),
    ]),
  );

  Widget _barberSkeletonCard() => Container(
    width: 120,
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
    child: Column(children: [
      _shimmer(120, 110, 18),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(children: [
          _shimmer(80, 12, 6),
          const SizedBox(height: 6),
          _shimmer(50, 10, 5),
          const SizedBox(height: 10),
        ]),
      ),
    ]),
  );

  Widget _shimmer(double w, double h, double r) => Container(
    width: w, height: h,
    decoration: BoxDecoration(color: AppColors.warmGray, borderRadius: BorderRadius.circular(r)),
  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppColors.surface.withOpacity(0.7));
}

