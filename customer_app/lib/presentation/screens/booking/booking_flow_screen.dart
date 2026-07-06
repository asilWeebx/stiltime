import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final _salonServicesProvider = FutureProvider.family<List, int>((ref, salonId) async {
  final r = await DioClient.instance.get('/salons/$salonId/services/');
  final raw = r.data;
  return raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
});

final _salonBarbersProvider = FutureProvider.family<List, int>((ref, salonId) async {
  final r = await DioClient.instance.get('/salons/$salonId/barbers/');
  final raw = r.data;
  return raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
});

// Key format: "barberId|date|serviceId1,serviceId2"
final _timeSlotsProvider = FutureProvider.family<List, String>((ref, key) async {
  final parts = key.split('|');
  final barberId = parts[0];
  final date = parts[1];
  final svcPart = parts.length > 2 ? parts[2] : '';
  final queryParams = <String, dynamic>{'date': date};
  if (svcPart.isNotEmpty) {
    queryParams['services'] = svcPart; // comma-separated string, parsed on backend
  }
  final r = await DioClient.instance.get('/barbers/$barberId/slots/', queryParameters: queryParams);
  final raw = r.data;
  return raw is Map ? (raw['slots'] ?? raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
});

// Used when booking directly from a barber's profile page
final _barberServicesProvider = FutureProvider.family<List, int>((ref, barberId) async {
  final r = await DioClient.instance.get('/barbers/$barberId/services/');
  final raw = r.data;
  return raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
});

// ── Screen ───────────────────────────────────────────────────────────────────

// barber first so salon-flow order is natural: barber→service→date→time→confirm
enum _Step { barber, service, date, time, confirm }

class BookingFlowScreen extends ConsumerStatefulWidget {
  final int salonId;
  final int? preSelectedBarberId;
  final int? preSelectedServiceId;

  const BookingFlowScreen({
    super.key,
    required this.salonId,
    this.preSelectedBarberId,
    this.preSelectedServiceId,
  });

  @override
  ConsumerState<BookingFlowScreen> createState() => _State();
}

class _State extends ConsumerState<BookingFlowScreen> {
  late _Step _step;
  final List<Map<String, dynamic>> _selectedServices = [];
  Map<String, dynamic>? _selectedBarber;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedSlot;
  bool _submitting = false;
  final _noteCtrl = TextEditingController();

  bool get _barberPreSelected => widget.preSelectedBarberId != null;

  @override
  void initState() {
    super.initState();
    // Barber pre-selected (from barber profile or salon barber tap) → start at service
    // Coming from salon with no pre-selected barber → start at barber selection
    _step = _barberPreSelected ? _Step.service : _Step.barber;
    if (_barberPreSelected) _loadPreSelectedBarber();
  }

  Future<void> _loadPreSelectedBarber() async {
    try {
      final r = await DioClient.instance.get('/barbers/${widget.preSelectedBarberId}/');
      if (mounted) setState(() => _selectedBarber = Map<String, dynamic>.from(r.data));
    } catch (_) {
      if (mounted) setState(() => _selectedBarber = {'id': widget.preSelectedBarberId, 'full_name': 'Sartarosh'});
    }
  }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  int get _totalPrice => _selectedServices.fold(0, (s, e) => s + ((e['price'] as num?)?.toInt() ?? 0));
  int get _totalDuration => _selectedServices.fold(0, (s, e) => s + ((e['duration'] as num?)?.toInt() ?? (e['duration_minutes'] as num?)?.toInt() ?? 0));

  void _goBack() {
    // First step: pop back
    if (_step == _Step.barber || (_step == _Step.service && _barberPreSelected)) {
      context.pop();
      return;
    }
    // Going back from service → barber (salon flow)
    if (_step == _Step.service) {
      setState(() => _step = _Step.barber);
      return;
    }
    // All other steps: go to previous
    setState(() => _step = _Step.values[_step.index - 1]);
  }

  void _advance() {
    if (_step == _Step.confirm) { _submit(); return; }
    // When barber is selected and we advance, clear previous service selection
    if (_step == _Step.barber) {
      _selectedServices.clear();
      _selectedSlot = null;
    }
    setState(() => _step = _Step.values[_step.index + 1]);
  }

  bool get _canAdvance {
    switch (_step) {
      case _Step.barber: return _selectedBarber != null;
      case _Step.service: return _selectedServices.isNotEmpty;
      case _Step.date: return true;
      case _Step.time: return _selectedSlot != null;
      // barber may still be loading async; pre-selected ID is enough
      case _Step.confirm: return _barberPreSelected || _selectedBarber != null;
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final slotTime = (_selectedSlot!['time'] as String? ?? '').length > 5
          ? (_selectedSlot!['time'] as String).substring(0, 5)
          : _selectedSlot!['time'] as String? ?? '';
      final effectiveBarberId = widget.preSelectedBarberId ?? _selectedBarber?['id'] as int?;
      final payload = <String, dynamic>{
        'barber_id': effectiveBarberId,
        'service_ids': _selectedServices.map((s) => s['id']).toList(),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'start_time': slotTime,
        if (_noteCtrl.text.trim().isNotEmpty) 'notes': _noteCtrl.text.trim(),
      };
      await DioClient.instance.post('/bookings/', data: payload);
      if (mounted) _showSuccess();
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        String errorMsg = 'Xatolik yuz berdi. Qayta urinib ko\'ring.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) {
            final msgs = <String>[];
            for (final v in data.values) {
              if (v is List) msgs.addAll(v.map((x) => x.toString()));
              else msgs.add(v.toString());
            }
            if (msgs.isNotEmpty) errorMsg = msgs.join(' · ');
          } else if (data is String && data.isNotEmpty) {
            errorMsg = data;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(28)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 40),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            const Text('Bron qilindi!', style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Sartarosh tasdiqlashini kuting.\n${_selectedBarber?['full_name'] ?? '${_selectedBarber?['first_name'] ?? ''} ${_selectedBarber?['last_name'] ?? ''}'.trim()} siz bilan bog\'lanadi.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); context.go('/home'); },
                child: const Text('Bosh sahifaga'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () { Navigator.pop(context); context.go('/bookings'); },
              child: const Text('Bronlarim', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.text),
          onPressed: _goBack,
        ),
        title: const Text('Bron qilish'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _StepIndicator(current: _step.index, total: _Step.values.length, skipBarber: _barberPreSelected),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildStep()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.barber:
        return _BarberStep(
          salonId: widget.salonId,
          selected: _selectedBarber,
          onSelect: (b) => setState(() => _selectedBarber = b),
        );
      case _Step.service:
        // Always use the selected barber's services — never salon-level
        final effectiveBarberId = widget.preSelectedBarberId ?? (_selectedBarber?['id'] as int?);
        return _ServiceStep(
          salonId: widget.salonId,
          barberId: effectiveBarberId,
          selected: _selectedServices,
          onToggle: (s) => setState(() {
            final idx = _selectedServices.indexWhere((x) => x['id'] == s['id']);
            if (idx >= 0) { _selectedServices.removeAt(idx); } else { _selectedServices.add(s); }
          }),
        );
      case _Step.date:
        return _DateStep(
          selected: _selectedDate,
          onSelect: (d) => setState(() => _selectedDate = d),
        );
      case _Step.time:
        final effectiveTid = widget.preSelectedBarberId ?? (_selectedBarber?['id'] as int?) ?? 0;
        final svcKey = _selectedServices
            .map((s) => (s['id'] as num?)?.toInt() ?? 0)
            .where((id) => id > 0)
            .join(',');
        return _TimeStep(
          barberId: effectiveTid,
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          serviceKey: svcKey,
          selected: _selectedSlot,
          onSelect: (s) => setState(() => _selectedSlot = s),
        );
      case _Step.confirm:
        return _ConfirmStep(
          services: _selectedServices,
          barber: _selectedBarber!,
          date: _selectedDate,
          slot: _selectedSlot!,
          totalPrice: _totalPrice,
          totalDuration: _totalDuration,
          noteCtrl: _noteCtrl,
        );
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_selectedServices.isNotEmpty && _step != _Step.service)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_selectedServices.length} xizmat · $_totalDuration min', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text('${_fmt(_totalPrice)} so\'m', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
            ]),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canAdvance && !_submitting ? _advance : null,
            child: _submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(_step == _Step.confirm ? 'Bron qilish' : 'Davom etish'),
          ),
        ),
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

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  final bool skipBarber;
  const _StepIndicator({required this.current, required this.total, this.skipBarber = false});

  @override
  Widget build(BuildContext context) {
    // Enum order: barber(0) service(1) date(2) time(3) confirm(4)
    // Salon flow (skipBarber=false): show all 5 — Sartarosh,Xizmat,Sana,Vaqt,Tasdiq
    // Barber-pre-selected (skipBarber=true): show 4 — Xizmat,Sana,Vaqt,Tasdiq
    final labels = skipBarber
        ? ['Xizmat', 'Sana', 'Vaqt', 'Tasdiq']
        : ['Sartarosh', 'Xizmat', 'Sana', 'Vaqt', 'Tasdiq'];
    final displayTotal = skipBarber ? total - 1 : total;
    // When barber step is skipped, shift display index left by 1
    int displayCurrent = skipBarber ? current - 1 : current;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(children: List.generate(displayTotal, (i) {
        final active = i == displayCurrent;
        final done = i < displayCurrent;
        return Expanded(child: Row(children: [
          if (i > 0) Expanded(child: Container(height: 1.5, color: done ? AppColors.primary : AppColors.border)),
          Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primary : active ? AppColors.primaryLight : AppColors.surfaceWarm,
                border: active ? Border.all(color: AppColors.primary, width: 2) : null,
              ),
              child: done
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? AppColors.primary : AppColors.textTertiary))),
            ),
            const SizedBox(height: 2),
            Text(labels[i], style: TextStyle(fontSize: 9, color: active ? AppColors.primary : AppColors.textTertiary, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ]));
      })),
    );
  }
}

// ── Step 1: Service ───────────────────────────────────────────────────────────

class _ServiceStep extends ConsumerStatefulWidget {
  final int salonId;
  final int? barberId;
  final List<Map<String, dynamic>> selected;
  final ValueChanged<Map<String, dynamic>> onToggle;
  const _ServiceStep({required this.salonId, this.barberId, required this.selected, required this.onToggle});

  @override
  ConsumerState<_ServiceStep> createState() => _ServiceStepState();
}

class _ServiceStepState extends ConsumerState<_ServiceStep> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final provider = widget.barberId != null
        ? ref.watch(_barberServicesProvider(widget.barberId!))
        : ref.watch(_salonServicesProvider(widget.salonId));
    return provider.when(
      data: (rawServices) {
        if (rawServices.isEmpty) {
          return const Center(child: Text('Xizmatlar topilmadi', style: TextStyle(color: AppColors.textTertiary)));
        }
        final all = rawServices.map((s) => Map<String, dynamic>.from(s as Map)).toList();

        // Extract unique categories
        final cats = <String>[];
        for (final s in all) {
          final cat = s['category_name'] as String? ?? '';
          if (cat.isNotEmpty && !cats.contains(cat)) cats.add(cat);
        }
        final hasCats = cats.length > 1;

        // Filter by selected category
        final visible = (_selectedCategory == null || !hasCats)
            ? all
            : all.where((s) => (s['category_name'] as String? ?? '') == _selectedCategory).toList();

        return Column(
          children: [
            // Category filter strip
            if (hasCats)
              Container(
                height: 52,
                color: AppColors.surface,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: cats.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final isAll = i == 0;
                    final label = isAll ? 'Hammasi' : cats[i - 1];
                    final active = isAll ? _selectedCategory == null : _selectedCategory == label;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = isAll ? null : label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? AppColors.primary : AppColors.border),
                        ),
                        child: Center(child: Text(label,
                          style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                        )),
                      ),
                    );
                  },
                ),
              ),
            if (hasCats) const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final s = visible[i];
                  final isSelected = widget.selected.any((x) => x['id'] == s['id']);
                  final name = s['name'] as String? ?? '';
                  final price = (s['price'] as num? ?? 0).toInt();
                  final duration = (s['duration'] as num?)?.toInt() ?? (s['duration_minutes'] as num?)?.toInt() ?? 0;
                  final description = s['description'] as String? ?? '';

                  return GestureDetector(
                    onTap: () => widget.onToggle(s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 1.5),
                        boxShadow: isSelected ? [] : AppColors.cardShadow,
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.surfaceWarm, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.content_cut_rounded, color: isSelected ? Colors.white : AppColors.textSecondary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isSelected ? AppColors.primary : AppColors.text)),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          if (duration > 0) ...[
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.schedule_outlined, size: 11, color: AppColors.textTertiary),
                              const SizedBox(width: 3),
                              Text('$duration daqiqa', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                            ]),
                          ],
                        ])),
                        const SizedBox(width: 8),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(_fmtP(price), style: TextStyle(color: isSelected ? AppColors.primary : AppColors.text, fontWeight: FontWeight.w800, fontSize: 14)),
                          if (isSelected) ...[
                            const SizedBox(height: 2),
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                          ],
                        ]),
                      ]),
                    ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Xatolik', style: TextStyle(color: AppColors.error))),
    );
  }

  String _fmtP(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return "${buf.toString()} so'm";
  }
}

// ── Step 2: Barber ────────────────────────────────────────────────────────────

class _BarberStep extends ConsumerWidget {
  final int salonId;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;
  const _BarberStep({required this.salonId, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(_salonBarbersProvider(salonId)).when(
      data: (barbers) {
        if (barbers.isEmpty) {
          return const Center(child: Text('Sartaroshlar topilmadi', style: TextStyle(color: AppColors.textTertiary)));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Sartarosh tanlang', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text('Har bir sartaroshning o\'z xizmatlari va narxlari bor', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: barbers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final b = Map<String, dynamic>.from(barbers[i]);
                  final isSelected = selected?['id'] == b['id'];
                  final name = b['full_name'] as String? ?? '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();
                  final specialty = b['specialization'] as String? ?? b['specialty'] as String? ?? '';
                  final rating = (b['rating'] as num?)?.toStringAsFixed(1) ?? '0.0';
                  final reviews = b['total_reviews'] as int? ?? 0;
                  final avatar = b['avatar'] as String?;

            return GestureDetector(
              onTap: () => onSelect(b),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 1.5),
                  boxShadow: isSelected ? [] : AppColors.cardShadow,
                ),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: avatar != null
                        ? Image.network(avatar, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(name))
                        : _avatarFallback(name),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isSelected ? AppColors.primary : AppColors.text)),
                    if (specialty.isNotEmpty) Text(specialty, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                  ])),
                  Column(children: [
                    Text('⭐ $rating', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.text)),
                    if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                  ]),
                ]),
              ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(),
            );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Xatolik', style: TextStyle(color: AppColors.error))),
    );
  }

  Widget _avatarFallback(String name) => Container(
    width: 50, height: 50, color: AppColors.beige,
    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'B',
        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 18))),
  );
}

// ── Step 3: Date ──────────────────────────────────────────────────────────────

class _DateStep extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _DateStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(30, (i) => today.add(Duration(days: i)));
    final monthNames = ['', 'Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn', 'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'];
    final dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Sana tanlang', style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text(DateFormat('MMMM yyyy', 'uz').format(selected).capitalize(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ]),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final d = dates[i];
              final isSelected = DateUtils.isSameDay(d, selected);
              return GestureDetector(
                onTap: () => onSelect(d),
                child: AnimatedContainer(
                  duration: 200.ms,
                  width: 62,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))] : AppColors.cardShadow,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(dayNames[d.weekday - 1], style: TextStyle(color: isSelected ? Colors.white70 : AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${d.day}', style: TextStyle(color: isSelected ? Colors.white : AppColors.text, fontSize: 22, fontWeight: FontWeight.w800)),
                    Text(monthNames[d.month], style: TextStyle(color: isSelected ? Colors.white70 : AppColors.textTertiary, fontSize: 10)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
            child: Row(children: [
              const Icon(Icons.event_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tanlangan sana', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                Text(
                  '${dayNames[selected.weekday - 1]}, ${selected.day} ${monthNames[selected.month]} ${selected.year}',
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ]),
            ]),
          ),
        ),
      ],
    );
  }
}

extension _StringX on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

// ── Step 4: Time ──────────────────────────────────────────────────────────────

class _TimeStep extends ConsumerWidget {
  final int barberId;
  final String date;
  final String serviceKey;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;
  const _TimeStep({required this.barberId, required this.date, required this.serviceKey, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(_timeSlotsProvider('$barberId|$date|$serviceKey')).when(
      data: (rawSlots) {
        final slots = rawSlots.map((s) => Map<String, dynamic>.from(s as Map)).toList();
        final availableCount = slots.where((s) => s['is_available'] as bool? ?? s['available'] as bool? ?? true).length;

        if (slots.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.event_busy_rounded, size: 56, color: AppColors.border),
            const SizedBox(height: 12),
            const Text('Dam olish kuni', style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Bu kunda ish yo\'q. Boshqa sana tanlang.', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          ]));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(children: [
                const Text('Vaqt tanlang', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                  child: Text('$availableCount ta bo\'sh', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Wrap(spacing: 12, runSpacing: 4, children: [
                _legendItem(AppColors.surface, AppColors.border, "Bo'sh"),
                _legendItem(AppColors.primary, AppColors.primary, 'Tanlangan'),
                _legendItem(const Color(0xFFFFF3F3), Colors.transparent, 'Band', textColor: AppColors.error),
                _legendItem(AppColors.warmGray, Colors.transparent, 'Bloklangan'),
              ]),
            ),
            Expanded(child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
              ),
              itemCount: slots.length,
              itemBuilder: (_, i) {
                final slot = slots[i];
                final time = slot['time'] as String? ?? slot['start_time'] as String? ?? '';
                final status = slot['status'] as String? ?? (slot['is_available'] as bool? ?? true ? 'available' : 'booked');
                final isAvailable = status == 'available';
                // Backend slots have no id — compare by time only; guard selected!=null to avoid null==null matching all
                final isSelected = selected != null && time.isNotEmpty && time == (selected!['time'] as String? ?? selected!['start_time'] as String? ?? '__none__');

                // Colors by status
                Color bgColor;
                Color textColor;
                Color borderColor;
                String? statusLabel;
                if (isSelected) {
                  bgColor = AppColors.primary;
                  textColor = Colors.white;
                  borderColor = AppColors.primary;
                } else if (status == 'available') {
                  bgColor = AppColors.surface;
                  textColor = AppColors.primary;
                  borderColor = AppColors.border;
                } else if (status == 'booked') {
                  bgColor = const Color(0xFFFFF3F3);
                  textColor = AppColors.error;
                  borderColor = Colors.transparent;
                  statusLabel = 'Band';
                } else if (status == 'blocked') {
                  bgColor = AppColors.warmGray;
                  textColor = AppColors.textTertiary;
                  borderColor = Colors.transparent;
                  statusLabel = 'Bloklangan';
                } else { // break
                  bgColor = const Color(0xFFFFF8E1);
                  textColor = const Color(0xFFB8860B);
                  borderColor = Colors.transparent;
                  statusLabel = 'Tanaffus';
                }

                return GestureDetector(
                  onTap: isAvailable ? () => onSelect(slot) : null,
                  child: AnimatedContainer(
                    duration: 200.ms,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                          : isAvailable ? AppColors.cardShadow : [],
                    ),
                    child: isSelected
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 13),
                            const SizedBox(height: 1),
                            Text(time.length > 5 ? time.substring(0, 5) : time,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          ])
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(time.length > 5 ? time.substring(0, 5) : time,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 13,
                                decoration: isAvailable ? null : TextDecoration.lineThrough)),
                            if (statusLabel != null) ...[
                              const SizedBox(height: 1),
                              Text(statusLabel, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600)),
                            ],
                          ]),
                  ).animate(delay: Duration(milliseconds: i * 20)).fadeIn(),
                );
              },
            )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Vaqtlarni yuklashda xatolik', style: TextStyle(color: AppColors.error))),
    );
  }

  Widget _legendItem(Color bg, Color border, String label, {Color? textColor}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: bg, shape: BoxShape.circle,
          border: border != Colors.transparent ? Border.all(color: border) : null,
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: textColor ?? AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w500)),
    ],
  );
}

// ── Step 5: Confirm ───────────────────────────────────────────────────────────

class _ConfirmStep extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final Map<String, dynamic> barber;
  final DateTime date;
  final Map<String, dynamic> slot;
  final int totalPrice;
  final int totalDuration;
  final TextEditingController noteCtrl;

  const _ConfirmStep({
    required this.services,
    required this.barber,
    required this.date,
    required this.slot,
    required this.totalPrice,
    required this.totalDuration,
    required this.noteCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    final monthNames = ['', 'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun', 'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'];
    final slotTime = (slot['time'] ?? slot['start_time'] ?? '') as String;
    final barberName = barber['full_name'] as String? ?? '${barber['first_name'] ?? ''} ${barber['last_name'] ?? ''}'.trim();
    final barberAvatar = barber['avatar'] as String?;
    final salonName = barber['salon_name'] as String? ?? '';
    final specialty = barber['specialization'] as String? ?? barber['specialty'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Buyurtmani tekshiring', style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        const SizedBox(height: 4),
        const Text('Tasdiqlashdan oldin ma\'lumotlarni ko\'rib chiqing', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),

        // Barber card
        _section('Sartarosh', Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: barberAvatar != null
                  ? Image.network(barberAvatar, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(barberName))
                  : _initials(barberName),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(barberName.isEmpty ? 'Sartarosh' : barberName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
              if (specialty.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(specialty, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
              if (salonName.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.storefront_outlined, size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(salonName, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ]),
              ],
            ])),
          ]),
        )),

        const SizedBox(height: 16),

        // Date & time
        _section('Sana va vaqt', Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${dayNames[date.weekday - 1]}, ${date.day} ${monthNames[date.month]}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
              Text(slotTime.length > 5 ? slotTime.substring(0, 5) : slotTime,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]),
          ]),
        )),

        const SizedBox(height: 16),

        // Services
        _section('Xizmatlar', Column(children: services.asMap().entries.map((e) {
          final s = e.value;
          final name = s['name'] as String? ?? '';
          final price = (s['price'] as num? ?? 0).toInt();
          final duration = (s['duration'] as num?)?.toInt() ?? (s['duration_minutes'] as num?)?.toInt() ?? 0;
          return Container(
            margin: EdgeInsets.only(bottom: e.key < services.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text)),
                if (duration > 0) Text('$duration daqiqa', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ])),
              Text(_fmtP(price), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          );
        }).toList())),

        const SizedBox(height: 16),

        // Note
        _section('Izoh (ixtiyoriy)', TextField(
          controller: noteCtrl,
          maxLines: 3,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(hintText: 'Sartaroshga xabar yozing...'),
        )),

        const SizedBox(height: 24),

        // Total
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4E6EF5), Color(0xFF3451D1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Jami to\'lov', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_fmtP(totalPrice), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            ]),
            if (totalDuration > 0) Text('$totalDuration daqiqa', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _section(String title, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title.toUpperCase(), style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
    const SizedBox(height: 8),
    child,
  ]);

  Widget _initials(String name) => Container(
    width: 48, height: 48, color: AppColors.beige,
    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'B',
        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 18))),
  );

  String _fmtP(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return "${buf.toString()} so'm";
  }
}
