import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api.dart';
import '../../../core/app_alert.dart';
import '../../../core/theme.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _toMapList(dynamic raw) {
  final list = raw is List ? raw : (raw is Map ? (raw['results'] ?? raw['data'] ?? <dynamic>[]) : <dynamic>[]);
  return (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

final _categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await BarberApi.instance.get('/salons/categories/');
    return _toMapList(res.data);
  } catch (e) {
    debugPrint('categories error: $e');
    return [];
  }
});

final _servicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await BarberApi.instance.get('/barbers/me/services/');
    return _toMapList(res.data);
  } catch (e) {
    debugPrint('services error: $e');
    return [];
  }
});

final _selectedCategoryProvider = StateProvider<int?>((ref) => null);
final _selectedGenderProvider = StateProvider<String?>((ref) => null);

// ─── Screen ───────────────────────────────────────────────────────────────────

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(_servicesProvider);
    final categoriesAsync = ref.watch(_categoriesProvider);
    final selectedCat = ref.watch(_selectedCategoryProvider);
    final selectedGender = ref.watch(_selectedGenderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Xizmatlar',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          GestureDetector(
            onTap: () => _showServiceSheet(context, ref, categories: categoriesAsync.value ?? []),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text('Qo\'shish',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ]),
            ),
          ),
        ],
      ),
      body: servicesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(_servicesProvider),
            child: const Text('Qayta urinish'),
          ),
        ),
        data: (allServices) {
          // Build category filter list from actual services
          final usedCatIds = allServices
              .map((s) => s['category'] as int?)
              .whereType<int>()
              .toSet();
          final allCats = categoriesAsync.value ?? [];
          // Filter categories by selected gender
          final filterCats = allCats
              .where((c) => usedCatIds.contains(c['id'] as int?))
              .where((c) => selectedGender == null || c['gender'] == selectedGender)
              .toList();

          // Filter services by category and gender
          var services = allServices;
          if (selectedGender != null) {
            final genderCatIds = allCats
                .where((c) => c['gender'] == selectedGender)
                .map((c) => c['id'] as int?)
                .toSet();
            services = services.where((s) => genderCatIds.contains(s['category'] as int?)).toList();
          }
          if (selectedCat != null) {
            services = services.where((s) => s['category'] == selectedCat).toList();
          }

          if (allServices.isEmpty) {
            return _EmptyState(
              categories: categoriesAsync.value ?? [],
              onAdd: () => _showServiceSheet(context, ref,
                  categories: categoriesAsync.value ?? []),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_servicesProvider);
              ref.invalidate(_categoriesProvider);
            },
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Category filter chips
                SliverToBoxAdapter(
                  child: _CategoryFilterBar(
                    categories: filterCats,
                    selected: selectedCat,
                    selectedGender: selectedGender,
                    onSelect: (id) =>
                        ref.read(_selectedCategoryProvider.notifier).state = id,
                    onGender: (g) {
                      ref.read(_selectedGenderProvider.notifier).state = g;
                      ref.read(_selectedCategoryProvider.notifier).state = null;
                    },
                  ),
                ),

                // Count
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      '${services.length} ta xizmat',
                      style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // List
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ServiceCard(
                          service: services[i],
                          onEdit: () => _showServiceSheet(context, ref,
                              service: services[i],
                              categories: categoriesAsync.value ?? []),
                          onDelete: () =>
                              _deleteService(context, ref, services[i]['id']),
                        ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.04),
                      ),
                      childCount: services.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteService(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("O'chirishni tasdiqlang",
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text("Bu xizmatni o'chirmoqchimisiz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bekor')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("O'chirish",
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await BarberApi.instance.delete('/barbers/me/services/$id/');
      ref.invalidate(_servicesProvider);
      if (context.mounted) {
        showAppAlert(context, 'Xizmat o\'chirildi', type: AlertType.success);
      }
    } catch (_) {
      if (context.mounted) showAppAlert(context, 'Xatolik yuz berdi');
    }
  }

  void _showServiceSheet(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? service,
    required List<Map<String, dynamic>> categories,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceSheet(
        service: service,
        categories: categories,
        onSaved: () => ref.invalidate(_servicesProvider),
      ),
    );
  }
}

// ─── Category filter bar ──────────────────────────────────────────────────────

class _CategoryFilterBar extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int? selected;
  final String? selectedGender;
  final ValueChanged<int?> onSelect;
  final ValueChanged<String?> onGender;
  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.selectedGender,
    required this.onSelect,
    required this.onGender,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gender pills
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(children: [
            _genderPill(null, 'Hammasi'),
            const SizedBox(width: 8),
            _genderPill('male', 'Erkaklar'),
            const SizedBox(width: 8),
            _genderPill('female', 'Ayollar'),
            const SizedBox(width: 8),
            _genderPill('unisex', 'Umumiy'),
          ]),
        ),
        // Category chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            children: [
              _chip(null, 'Barchasi', null),
              const SizedBox(width: 8),
              ...categories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _chip(c['id'] as int, c['name'] as String, c['icon'] as String?),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _genderPill(String? value, String label) {
    final active = selectedGender == value;
    return GestureDetector(
      onTap: () => onGender(value),
      child: AnimatedContainer(
        duration: 160.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            )),
      ),
    );
  }

  Widget _chip(int? id, String label, String? iconUrl) {
    final active = selected == id;
    return GestureDetector(
      onTap: () => onSelect(id),
      child: AnimatedContainer(
        duration: 180.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: active ? [] : AppColors.cardShadow,
          border: active ? null : Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (iconUrl != null && iconUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(iconUrl,
                  width: 16, height: 16, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox()),
            ),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              )),
        ]),
      ),
    );
  }
}

// ─── Service card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ServiceCard(
      {required this.service, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name = service['name'] as String? ?? '';
    final description = service['description'] as String? ?? '';
    final price = (service['price'] as num? ?? 0).toInt();
    final duration = service['duration'] as int? ?? 0;
    final categoryName = service['category_name'] as String?;
    final icon = service['category_icon'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // Left color bar
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            ),
          ),
          const SizedBox(width: 14),
          // Icon circle
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 46,
              height: 46,
              color: AppColors.primaryLight,
              child: icon != null && icon.isNotEmpty
                  ? Image.network(icon, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.content_cut_rounded,
                          color: AppColors.primary, size: 22))
                  : const Icon(Icons.content_cut_rounded,
                      color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.text)),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textHint)),
                  ],
                  const SizedBox(height: 4),
                  Row(children: [
                    if (categoryName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(categoryName,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    const Icon(Icons.schedule_rounded,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text('$duration daq',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormat('#,###').format(price)} so\'m',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(children: [
                _btn(Icons.edit_rounded, AppColors.primary, AppColors.primaryLight,
                    onEdit),
                const SizedBox(width: 6),
                _btn(Icons.delete_outline_rounded, AppColors.error,
                    const Color(0xFFFFEBEA), onDelete),
              ]),
            ],
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, Color color, Color bg, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 15),
        ),
      );
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final VoidCallback onAdd;
  const _EmptyState({required this.categories, required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.content_cut_rounded,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Xizmatlar yo\'q',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Yangi xizmat qo\'shing',
              style: TextStyle(color: AppColors.textHint, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Xizmat qo\'shish'),
          ),
        ]),
      );
}

// ─── Service bottom sheet ─────────────────────────────────────────────────────

class _ServiceSheet extends StatefulWidget {
  final Map<String, dynamic>? service;
  final List<Map<String, dynamic>> categories;
  final VoidCallback onSaved;
  const _ServiceSheet(
      {this.service, required this.categories, required this.onSaved});

  @override
  State<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<_ServiceSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  int? _selectedCategoryId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      final s = widget.service!;
      _nameCtrl.text = s['name'] as String? ?? '';
      _descCtrl.text = s['description'] as String? ?? '';
      _priceCtrl.text = '${(s['price'] as num? ?? 0).toInt()}';
      _durationCtrl.text = '${s['duration'] as int? ?? 30}';
      _selectedCategoryId = s['category'] as int?;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      showAppAlert(context, 'Xizmat nomini kiriting');
      return;
    }
    if (_selectedCategoryId == null) {
      showAppAlert(context, 'Kategoriya tanlang');
      return;
    }
    setState(() => _loading = true);
    final data = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': int.tryParse(_priceCtrl.text) ?? 0,
      'duration': int.tryParse(_durationCtrl.text) ?? 30,
      'category': _selectedCategoryId,
    };
    try {
      if (widget.service != null) {
        await BarberApi.instance
            .patch('/barbers/me/services/${widget.service!['id']}/', data: data);
      } else {
        await BarberApi.instance.post('/barbers/me/services/', data: data);
      }
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        showAppAlert(context,
            widget.service != null ? 'Xizmat yangilandi' : 'Xizmat qo\'shildi',
            type: AlertType.success);
      }
    } catch (_) {
      if (mounted) showAppAlert(context, 'Xatolik yuz berdi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.service != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Xizmatni tahrirlash' : 'Yangi xizmat',
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 20),

                    // ── Category picker ──
                    _label('Kategoriya *'),
                    const SizedBox(height: 8),
                    if (widget.categories.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Admin hali kategoriya qo\'shmagan',
                          style: TextStyle(
                              color: AppColors.warning, fontSize: 13),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.categories.map((c) {
                          final id = c['id'] as int;
                          final name = c['name'] as String;
                          final icon = c['icon'] as String? ?? '';
                          final isUrl = icon.startsWith('http');
                          final active = _selectedCategoryId == id;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategoryId = id),
                            child: AnimatedContainer(
                              duration: 150.ms,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: active ? 1.5 : 1,
                                ),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                if (icon.isNotEmpty) ...[
                                  if (isUrl)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(icon, width: 18, height: 18, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const SizedBox()),
                                    )
                                  else
                                    Text(icon, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 18),

                    // ── Service name ──
                    _label('Xizmat nomi *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                          hintText: 'Masalan: Soch olish'),
                    ),

                    const SizedBox(height: 14),

                    // ── Description ──
                    _label('Tavsif (ixtiyoriy)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                          hintText: 'Xizmat haqida qisqacha...'),
                    ),

                    const SizedBox(height: 14),

                    // ── Price + Duration ──
                    Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Narxi (so\'m)'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _priceCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: const TextStyle(color: AppColors.text),
                                decoration:
                                    const InputDecoration(hintText: '50000'),
                              ),
                            ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Davomiylik (daqiqa)'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _durationCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: const TextStyle(color: AppColors.text),
                                decoration:
                                    const InputDecoration(hintText: '30'),
                              ),
                            ]),
                      ),
                    ]),

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : Text(
                                isEdit ? 'Saqlash' : 'Qo\'shish',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w600));
}
