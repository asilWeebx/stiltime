import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api.dart';
import '../../../core/app_alert.dart';
import '../../../core/theme.dart';

// ---------------------------------------------------------------------------
// Main screen (Feature 5 redesign)
// ---------------------------------------------------------------------------

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  String _statusFilter = 'all';
  String _search = '';

  Timer? _pollTimer;
  bool _dialogOpen = false;

  static const _filters = [
    ('all', 'Barchasi'),
    ('pending', 'Kelayotgan'),
    ('in_progress', 'Jarayonda'),
    ('completed', 'Bajarildi'),
    ('cancelled', 'Bekor'),
  ];

  @override
  void initState() {
    super.initState();
    _load().then((_) => _checkPending());
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) _checkPending();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await BarberApi.instance.get('/bookings/barber/list/');
      final raw = res.data;
      final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : raw;
      final bookings = List<Map<String, dynamic>>.from(list);
      // Sort: active bookings first, then completed, then cancelled; newest date within each group
      const _statusOrder = {
        'pending': 0,
        'confirmed': 0,
        'in_progress': 0,
        'completed': 1,
        'cancelled': 2,
        'no_show': 2,
      };
      bookings.sort((a, b) {
        final aRank = _statusOrder[a['status'] ?? ''] ?? 0;
        final bRank = _statusOrder[b['status'] ?? ''] ?? 0;
        if (aRank != bRank) return aRank.compareTo(bRank);
        final aDate = '${a['date'] ?? ''}${a['start_time'] ?? ''}';
        final bDate = '${b['date'] ?? ''}${b['start_time'] ?? ''}';
        return bDate.compareTo(aDate);
      });
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _openDetail(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(booking: booking, onRefresh: _load),
    );
  }

  Future<void> _checkPending() async {
    if (_dialogOpen) return;
    try {
      final res = await BarberApi.instance.get('/bookings/barber/pending/');
      final raw = res.data;
      final list = raw is List ? raw : (raw is Map ? (raw['results'] ?? raw['data'] ?? []) : []);
      if (list.isNotEmpty && mounted) {
        final booking = Map<String, dynamic>.from(list[0] as Map);
        setState(() => _dialogOpen = true);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _PendingBookingDialog(
            booking: booking,
            onDone: () {
              setState(() => _dialogOpen = false);
              _load();
            },
          ),
        );
        setState(() => _dialogOpen = false);
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _bookings;
    if (_statusFilter != 'all') {
      list = list.where((b) => b['status'] == _statusFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((b) {
        final name = (b['customer_name']?.toString() ?? '').toLowerCase();
        final phone = (b['customer_phone']?.toString() ?? '').toLowerCase();
        return name.contains(q) || phone.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Mening bronlarim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (val, label) = _filters[i];
                final selected = _statusFilter == val;
                return GestureDetector(
                  onTap: () => setState(() => _statusFilter = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Mijoz ismi yoki telefon...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    child: _filtered.isEmpty
                        ? _empty()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () => _openDetail(_filtered[i]),
                              child: _BookingCard(
                                booking: _filtered[i],
                                onRefresh: _load,
                              ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.03),
                            ),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWalkInSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Walk-in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showWalkInSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalkInSheet(onCreated: _load),
    );
  }

  Widget _empty() => ListView(
    children: const [
      SizedBox(height: 80),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 56, color: AppColors.border),
            SizedBox(height: 16),
            Text('Bronlar topilmadi', style: TextStyle(color: AppColors.textHint, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Filterni o\'zgartiring yoki yangi walk-in qo\'shing', style: TextStyle(color: AppColors.textHint, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Booking card (Feature 5)
// ---------------------------------------------------------------------------

class _BookingCard extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onRefresh;
  const _BookingCard({required this.booking, required this.onRefresh});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _loading = false;

  bool get _isWalkIn => widget.booking['is_walk_in'] == true;
  String get _status => widget.booking['status']?.toString() ?? 'confirmed';

  Color get _statusColor {
    switch (_status) {
      case 'pending': return const Color(0xFFDDA74A);
      case 'in_progress': return AppColors.primary;
      case 'confirmed': return AppColors.success;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.textHint;
      default: return AppColors.textHint;
    }
  }

  String get _statusLabel {
    const m = {
      'pending': 'Kutilmoqda',
      'confirmed': 'Tasdiqlangan',
      'in_progress': 'Jarayonda',
      'completed': 'Bajarildi',
      'cancelled': 'Bekor',
      'no_show': 'Kelmadi',
    };
    return m[_status] ?? _status;
  }

  Future<void> _update(String s) async {
    setState(() => _loading = true);
    try {
      final id = widget.booking['id'];
      final url = _isWalkIn
          ? '/bookings/barber/walk-in/$id/update/'
          : '/bookings/barber/$id/update/';
      await BarberApi.instance.patch(url, data: {'status': s});
      widget.onRefresh();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openReschedule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RescheduleSheet(
        bookingId: widget.booking['id'] as int,
        onRescheduled: widget.onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.booking['customer_name']?.toString() ?? 'Noma\'lum mijoz';
    final customerPhone = widget.booking['customer_phone']?.toString();
    final salonName = widget.booking['salon_name']?.toString() ?? '';
    final dateStr = widget.booking['date']?.toString() ?? '';
    final startTime = (widget.booking['start_time']?.toString() ?? '').replaceAll(RegExp(r':\d\d$'), '');
    final initials = customerName.isNotEmpty
        ? customerName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    // Format date
    String formattedDate = dateStr;
    try {
      final d = DateTime.parse(dateStr);
      formattedDate = DateFormat('d MMM yyyy').format(d);
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
        border: Border(left: BorderSide(color: _statusColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + name/phone + status badge
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _statusColor.withOpacity(0.15),
                  child: Text(
                    initials,
                    style: TextStyle(color: _statusColor, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 15),
                      ),
                      if (customerPhone != null && customerPhone.isNotEmpty)
                        Text(customerPhone, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                    ],
                  ),
                ),
                if (_isWalkIn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF0EDFF), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Bevosita', style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.w700, fontSize: 11)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(color: _statusColor, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Info rows
            if (salonName.isNotEmpty)
              _infoRow(Icons.location_on_outlined, 'Joy: $salonName'),
            const SizedBox(height: 4),
            _infoRow(Icons.access_time_rounded, 'Vaqt: $formattedDate, $startTime'),
            // Action buttons
            if (_status == 'confirmed' || _status == 'in_progress' || (!_isWalkIn && _status == 'pending')) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (_status == 'pending') ...[
                    Expanded(child: _btn('Rad etish', AppColors.error, AppColors.errorLight, () => _update('cancelled'))),
                    const SizedBox(width: 8),
                    Expanded(child: _btn('Tasdiqlash', AppColors.success, AppColors.successLight, () => _update('confirmed'))),
                  ] else if (_status == 'confirmed') ...[
                    if (!_isWalkIn) ...[
                      Expanded(child: _btn('Ko\'chirish', AppColors.warning, AppColors.warningLight, _openReschedule)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(child: _btn('Boshlash', AppColors.primary, AppColors.primaryLight, () => _update('in_progress'))),
                  ] else if (_status == 'in_progress')
                    Expanded(child: _btn('Yakunlash ✓', AppColors.success, AppColors.successLight, () => _update('completed'))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 14, color: AppColors.textHint),
      const SizedBox(width: 5),
      Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
    ],
  );

  Widget _btn(String label, Color color, Color bg, VoidCallback onTap) => GestureDetector(
    onTap: _loading ? null : onTap,
    child: Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: _loading
          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          : Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    ),
  );
}

// ---------------------------------------------------------------------------
// Feature 1 — Walk-in bottom sheet
// ---------------------------------------------------------------------------

class _WalkInSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _WalkInSheet({required this.onCreated});

  @override
  State<_WalkInSheet> createState() => _WalkInSheetState();
}

class _WalkInSheetState extends State<_WalkInSheet> {
  List<Map<String, dynamic>> _services = [];
  final Set<int> _selectedServiceIds = {};
  List<Map<String, dynamic>> _slots = [];
  String? _selectedSlot;

  DateTime _selectedDate = DateTime.now();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _salonName;
  bool _loadingServices = true;
  bool _loadingSlots = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() => _loadingServices = true);
    try {
      // Load barber profile for salon name
      final meRes = await BarberApi.instance.get('/barbers/me/');
      final meData = meRes.data;
      if (meData is Map) {
        _salonName = meData['salon_name'] as String? ?? meData['salon']?['name'] as String?;
      }

      final res = await BarberApi.instance.get('/barbers/me/services/');
      final raw = res.data;
      final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : raw;
      setState(() {
        _services = List<Map<String, dynamic>>.from(list);
        _loadingServices = false;
      });
      // Load slots after services are ready
      await _loadSlots();
    } catch (_) {
      setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
    });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final serviceParams = _selectedServiceIds.map((id) => 'services=$id').join('&');
      final url = '/barbers/me/slots/?date=$dateStr${serviceParams.isNotEmpty ? '&$serviceParams' : ''}';
      final res = await BarberApi.instance.get(url);
      final raw = res.data;
      final list = raw is Map ? (raw['slots'] ?? []) : raw;
      setState(() {
        _slots = List<Map<String, dynamic>>.from(list);
        _loadingSlots = false;
      });
    } catch (_) {
      setState(() => _loadingSlots = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadSlots();
    }
  }

  Future<void> _submit() async {
    final now = DateTime.now();
    final fallbackTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    final slotToUse = _selectedSlot ?? fallbackTime;
    setState(() => _submitting = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await BarberApi.instance.post('/bookings/barber/walk-in/', data: {
        'date': dateStr,
        'start_time': slotToUse,
        'service_ids': _selectedServiceIds.toList(),
        'customer_name': _nameCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
      });
      widget.onCreated();
      if (mounted) {
        Navigator.pop(context);
        showAppAlert(context, 'Walk-in muvaffaqiyatli qo\'shildi', type: AlertType.success);
      }
    } catch (e) {
      if (mounted) showAppAlert(context, 'Xatolik: ${e.toString().replaceAll(RegExp(r'DioException.*?:'), '').trim().substring(0, e.toString().length.clamp(0, 80))}');
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
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
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
            child: Row(
              children: [
                const Text('Walk-in bron', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: AppColors.textHint)),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Salon (read-only)
                  _label('Salon'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _loadingServices ? 'Yuklanmoqda...' : (_salonName ?? 'Salon'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Services
                  _label('Xizmatlar'),
                  _loadingServices
                      ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
                      : _services.isEmpty
                          ? const Text('Xizmatlar topilmadi', style: TextStyle(color: AppColors.textHint, fontSize: 13))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _services.map((s) {
                                final id = s['id'] as int;
                                final selected = _selectedServiceIds.contains(id);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (selected) {
                                        _selectedServiceIds.remove(id);
                                      } else {
                                        _selectedServiceIds.add(id);
                                      }
                                    });
                                    _loadSlots();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected ? AppColors.primary : AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                                    ),
                                    child: Text(
                                      '${s['name']} · ${(s['price'] as num).toInt()} so\'m',
                                      style: TextStyle(
                                        color: selected ? Colors.white : AppColors.text,
                                        fontSize: 12,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                  const SizedBox(height: 16),

                  // Date
                  _label('Sana'),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('d MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time slot
                  _label('Vaqt sloti (ixtiyoriy — bo\'sh qolsa hozirgi vaqt ishlatiladi)'),
                  if (_loadingSlots)
                    const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
                  else if (_slots.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFE082))),
                      child: const Row(children: [
                        Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFB8860B)),
                        SizedBox(width: 8),
                        Expanded(child: Text('Bo\'sh slot topilmadi — hozirgi vaqt ishlatiladi', style: TextStyle(color: Color(0xFF8B6914), fontSize: 12))),
                      ]),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSlot,
                          isExpanded: true,
                          hint: const Text('Vaqtni tanlang', style: TextStyle(color: AppColors.textHint)),
                          items: _slots
                              .where((s) => s['is_available'] == true)
                              .map((s) {
                            final t = s['time'] as String? ?? s['start_time'] as String? ?? '';
                            return DropdownMenuItem(value: t, child: Text(t));
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedSlot = v),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Customer name
                  _label('Mijoz ismi (ixtiyoriy)'),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'Masalan: Alisher'),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  _label('Izoh (ixtiyoriy)'),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Qo\'shimcha ma\'lumotlar...'),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Walk-in qo\'shish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
  );
}

// ---------------------------------------------------------------------------
// Feature 2 — Pending booking dialog (matches reference design)
// ---------------------------------------------------------------------------

class _PendingBookingDialog extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onDone;
  const _PendingBookingDialog({required this.booking, required this.onDone});

  @override
  State<_PendingBookingDialog> createState() => _PendingBookingDialogState();
}

class _PendingBookingDialogState extends State<_PendingBookingDialog> {
  late int _secondsLeft;
  Timer? _timer;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = (widget.booking['seconds_remaining'] as num?)?.toInt() ?? 600;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _timer?.cancel();
          Navigator.of(context).pop();
          widget.onDone();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _respond(String status) async {
    setState(() => _acting = true);
    _timer?.cancel();
    try {
      await BarberApi.instance.patch(
        '/bookings/barber/${widget.booking['id']}/update/',
        data: {'status': status},
      );
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
      widget.onDone();
    }
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _fmtDuration(int mins) {
    if (mins < 60) return '$mins daqiqa';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '$h soat' : '$h soat $m daqiqa';
  }

  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const months = ['', 'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', 'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr'];
      const days = ['', 'Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];
      return '${days[d.weekday]}, ${d.day} ${months[d.month]}';
    } catch (_) {
      return raw;
    }
  }

  String _fmtPrice(num v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return "${buf.toString()} so'm";
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final services = (b['services'] as List? ?? []).cast<Map>();
    final notes = b['notes']?.toString() ?? '';
    final totalDuration = (b['total_duration'] as num?)?.toInt() ?? 0;
    final finalPrice = b['final_price'] ?? b['total_price'] ?? 0;
    final progress = _secondsLeft / 600.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Yangi bron keldi!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                      Text('Mijozdan yangi buyurtma', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('$_timerLabel ichida tasdiqlang', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
                    child: Text(_timerLabel, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
                  ),
                ]),
              ]),
            ),

            // ── Content ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Asosiy section
                  _sectionHeader('Asosiy'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(children: [
                      _infoRow('Salon', b['salon_name']?.toString() ?? '—'),
                      _divider(),
                      _infoRow(
                        'Sana va vaqt',
                        '${_fmtDate(b['date']?.toString() ?? '')}, '
                        '${(b['start_time']?.toString() ?? '').substring(0, 5)} – '
                        '${(b['end_time']?.toString() ?? '').substring(0, 5)}',
                      ),
                      _divider(),
                      _infoRow('Mijoz', b['customer_name']?.toString() ?? 'Noma\'lum'),
                      if ((b['customer_phone']?.toString() ?? '').isNotEmpty) ...[
                        _divider(),
                        _infoRow('Telefon', b['customer_phone']!.toString()),
                      ],
                      _divider(),
                      _infoRow('Davomiyligi', _fmtDuration(totalDuration)),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // Xizmatlar section
                  _sectionHeader('Xizmatlar'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      ...services.asMap().entries.map((e) {
                        final s = e.value;
                        final isLast = e.key == services.length - 1;
                        final price = s['price'] as num? ?? 0;
                        return Column(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s['name']?.toString() ?? '', style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
                                if ((s['duration'] as num?)?.toInt() != null && (s['duration'] as num).toInt() > 0)
                                  Text('${(s['duration'] as num).toInt()} daqiqa', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                              ])),
                              Text(_fmtPrice(price), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                            ]),
                          ),
                          if (!isLast) Divider(height: 1, color: AppColors.border.withOpacity(0.6), indent: 14, endIndent: 14),
                        ]);
                      }),
                      // Total row
                      if (services.isNotEmpty) ...[
                        Container(height: 1, color: AppColors.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Jami', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
                            Text(_fmtPrice(finalPrice as num? ?? 0), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                          ]),
                        ),
                      ],
                    ]),
                  ),

                  // Notes (izoh) section
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionHeader('Mijozning izohi'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFE082), width: 1),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.format_quote_rounded, color: Color(0xFFB8860B), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(notes, style: const TextStyle(color: AppColors.text, fontSize: 13, height: 1.5))),
                      ]),
                    ),
                  ],
                ]),
              ),
            ),

            // ── Buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _acting ? null : () => _respond('cancelled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Rad etish', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _acting ? null : () => _respond('confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _acting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Qabul qilish', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ]),
            ),

            // Auto-cancel warning
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                '10 daqiqa ichida tasdiqlanmasa, bron avtomatik bekor qilinadi',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
    title,
    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.end)),
    ]),
  );

  Widget _divider() => Divider(height: 1, color: AppColors.border.withOpacity(0.6), indent: 14, endIndent: 14);
}

// ---------------------------------------------------------------------------
// Feature 4 — Reschedule bottom sheet
// ---------------------------------------------------------------------------

class _RescheduleSheet extends StatefulWidget {
  final int bookingId;
  final VoidCallback onRescheduled;
  const _RescheduleSheet({required this.bookingId, required this.onRescheduled});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  final _commentCtrl = TextEditingController();
  List<Map<String, dynamic>> _slots = [];
  bool _loadingSlots = false;
  bool _submitting = false;

  // Next 30 days
  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _days = List.generate(30, (i) => today.add(Duration(days: i)));
    _loadSlots();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
    });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final res = await BarberApi.instance.get('/barbers/me/slots/?date=$dateStr');
      final raw = res.data;
      final list = raw is Map ? (raw['slots'] ?? []) : raw;
      setState(() {
        _slots = List<Map<String, dynamic>>.from(list);
        _loadingSlots = false;
      });
    } catch (_) {
      setState(() => _loadingSlots = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedSlot == null) {
      showAppAlert(context, 'Iltimos vaqt slotini tanlang');
      return;
    }
    setState(() => _submitting = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await BarberApi.instance.patch(
        '/bookings/barber/${widget.bookingId}/reschedule/',
        data: {
          'date': dateStr,
          'start_time': _selectedSlot,
          'notes': _commentCtrl.text.trim(),
        },
      );
      widget.onRescheduled();
      if (mounted) {
        Navigator.pop(context);
        showAppAlert(context, 'Bron muvaffaqiyatli ko\'chirildi', type: AlertType.success);
      }
    } catch (e) {
      if (mounted) showAppAlert(context, 'Xatolik yuz berdi. Vaqt band bo\'lishi mumkin.');
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                const Text('Bronni ko\'chirish', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: AppColors.textHint)),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date chips — horizontal scrollable next 30 days
                  _sectionLabel('Sana tanlang'),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _days.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final d = _days[i];
                        final selected = isSameDay(d, _selectedDate);
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedDate = d);
                            _loadSlots();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 52,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('d').format(d),
                                  style: TextStyle(
                                    color: selected ? Colors.white : AppColors.text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat('EEE').format(d),
                                  style: TextStyle(
                                    color: selected ? Colors.white.withOpacity(0.8) : AppColors.textHint,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time slot
                  _sectionLabel('Vaqt sloti'),
                  if (_loadingSlots)
                    const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
                  else if (_slots.isEmpty)
                    const Text('Bu kunda bo\'sh vaqt yo\'q', style: TextStyle(color: AppColors.textHint, fontSize: 13))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSlot,
                          isExpanded: true,
                          hint: const Text('Vaqtni tanlang', style: TextStyle(color: AppColors.textHint)),
                          items: _slots
                              .where((s) => s['is_available'] == true)
                              .map((s) {
                            final t = s['time'] as String? ?? s['start_time'] as String? ?? '';
                            return DropdownMenuItem(value: t, child: Text(t));
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedSlot = v),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Comment
                  _sectionLabel('Izoh (ixtiyoriy)'),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Sabab yoki qo\'shimcha ma\'lumot...'),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Ko\'chirish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
  );
}

// ---------------------------------------------------------------------------
// Booking detail bottom sheet
// ---------------------------------------------------------------------------

class _BookingDetailSheet extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onRefresh;
  const _BookingDetailSheet({required this.booking, required this.onRefresh});

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  bool _loading = false;
  Timer? _timer;
  late int _secondsLeft;

  String get _status => widget.booking['status'] as String? ?? 'pending';
  bool get _isPending => _status == 'pending';
  bool get _isWalkIn => widget.booking['is_walk_in'] == true;

  @override
  void initState() {
    super.initState();
    _secondsLeft = (widget.booking['seconds_remaining'] as num?)?.toInt() ?? 600;
    if (_isPending) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
      });
    });
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _update(String s) async {
    _timer?.cancel();
    setState(() => _loading = true);
    try {
      final id = widget.booking['id'];
      final url = _isWalkIn
          ? '/bookings/barber/walk-in/$id/update/'
          : '/bookings/barber/$id/update/';
      await BarberApi.instance.patch(url, data: {'status': s});
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openReschedule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RescheduleSheet(
        bookingId: widget.booking['id'] as int,
        onRescheduled: () {
          widget.onRefresh();
          Navigator.pop(context);
        },
      ),
    );
  }

  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const months = ['', 'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', 'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr'];
      return '${d.day} ${months[d.month]}, ${(raw.length > 10 ? '' : '')}';
    } catch (_) { return raw; }
  }

  String _fmtDateTime(String dateRaw, String timeRaw) {
    try {
      final d = DateTime.parse(dateRaw);
      const months = ['', 'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', 'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr'];
      final t = timeRaw.replaceAll(RegExp(r':\d\d$'), '');
      return '${d.day} ${months[d.month]}, $t';
    } catch (_) { return '$dateRaw $timeRaw'; }
  }

  String _fmtDuration(int mins) {
    if (mins == 0) return '—';
    if (mins < 60) return '$mins daqiqa';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '$h soat' : '$h soat $m daqiqa';
  }

  String _fmtPrice(num v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return "${buf.toString()} so'm";
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final customerName = b['customer_name']?.toString() ?? 'Noma\'lum mijoz';
    final customerPhone = b['customer_phone']?.toString() ?? '';
    final dateStr = b['date']?.toString() ?? '';
    final startTime = (b['start_time']?.toString() ?? '').replaceAll(RegExp(r':\d\d$'), '');
    final salonName = b['salon_name']?.toString() ?? '';
    final services = (b['services'] as List? ?? []).cast<Map>();
    final finalPrice = b['final_price'] ?? b['total_price'] ?? 0;
    final totalDuration = (b['total_duration'] as num?)?.toInt() ?? 0;
    final notes = b['notes']?.toString() ?? '';
    final progress = (_secondsLeft / 600.0).clamp(0.0, 1.0);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F5F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
          )),

          // ── Header ──────────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _isPending ? 'Yangi bron keldi!' : _statusLabel,
                style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              if (_isPending) ...[
                const SizedBox(height: 4),
                Text(
                  '$_timerLabel ichida tasdiqlang',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _secondsLeft < 120 ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ]),
          ),

          // ── Scrollable content ───────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Asosiy section
                _sectionTitle('Asosiy'),
                const SizedBox(height: 8),
                _infoCard([
                  if (salonName.isNotEmpty) _infoRow('Salon (filial)', salonName),
                  if (salonName.isNotEmpty) _divider(),
                  _infoRow('Sana va vaqt', _fmtDateTime(dateStr, startTime)),
                  _divider(),
                  _infoRow('Mijoz', customerName),
                  if (customerPhone.isNotEmpty) ...[
                    _divider(),
                    _infoRow('Telefon raqami', customerPhone),
                  ],
                  if (totalDuration > 0) ...[
                    _divider(),
                    _infoRow('Davomiylik', _fmtDuration(totalDuration)),
                  ],
                ]),
                const SizedBox(height: 16),

                // Xizmatlar section
                if (services.isNotEmpty) ...[
                  _sectionTitle('Xizmatlar'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      ...services.asMap().entries.map((e) {
                        final s = e.value;
                        final isLast = e.key == services.length - 1;
                        return Column(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            child: Row(children: [
                              Expanded(child: Text(
                                s['name']?.toString() ?? '',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              )),
                              Text(
                                _fmtPrice((s['price'] as num?) ?? 0),
                                style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ]),
                          ),
                          if (!isLast) _divider(),
                        ]);
                      }),
                    ]),
                  ),
                ],

                // Notes
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.format_quote_rounded, color: Color(0xFFB45309), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(notes, style: const TextStyle(color: AppColors.text, fontSize: 13, height: 1.5))),
                    ]),
                  ),
                ],
                const SizedBox(height: 12),
              ]),
            ),
          ),

          // ── Action buttons ───────────────────────────────────────────────────
          if (_status == 'confirmed' || _status == 'in_progress' || (!_isWalkIn && _status == 'pending'))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _buildActions(),
            ),

          if (_isPending && !_isWalkIn)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                'Agar 10 daqiqa ichida qabul qilmasangiz, bron avtomatik bekor qilinadi',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error.withOpacity(0.85), fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.4),
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  String get _statusLabel {
    const m = {
      'pending': 'Yangi bron',
      'confirmed': 'Tasdiqlangan',
      'in_progress': 'Jarayonda',
      'completed': 'Bajarildi',
      'cancelled': 'Bekor qilingan',
      'no_show': 'Kelmadi',
    };
    return m[_status] ?? _status;
  }

  Widget _buildActions() {
    if (_status == 'pending') {
      return Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => _update('cancelled'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Rad etish', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(
          onPressed: () => _update('confirmed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A5F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Qabul qilish', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        )),
      ]);
    }
    if (_status == 'confirmed') {
      return Row(children: [
        if (!_isWalkIn) ...[
          Expanded(child: OutlinedButton(
            onPressed: _openReschedule,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Ko\'chirish', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          )),
          const SizedBox(width: 12),
        ],
        Expanded(child: ElevatedButton(
          onPressed: () => _update('in_progress'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Boshlash', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        )),
      ]);
    }
    if (_status == 'in_progress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _update('completed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Yakunlash ✓', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
  );

  Widget _infoCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(children: children),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 13.5))),
      Expanded(child: Text(value, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13.5), textAlign: TextAlign.end)),
    ]),
  );

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F5));
}

// Helper used in _RescheduleSheetState
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
