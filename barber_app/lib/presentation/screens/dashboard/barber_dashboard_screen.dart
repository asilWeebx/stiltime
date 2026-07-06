import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api.dart';
import '../../../core/app_alert.dart';
import '../../../core/theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _dashProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final res = await BarberApi.instance.get('/barbers/me/dashboard/');
    return Map<String, dynamic>.from(res.data);
  } catch (_) { return {}; }
});

final _todayBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await BarberApi.instance.get('/bookings/barber/list/', queryParameters: {'date': today});
    final raw = res.data;
    final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : raw;
    return List<Map<String, dynamic>>.from(list);
  } catch (_) { return []; }
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class BarberDashboardScreen extends ConsumerStatefulWidget {
  const BarberDashboardScreen({super.key});

  @override
  ConsumerState<BarberDashboardScreen> createState() => _State();
}

class _State extends ConsumerState<BarberDashboardScreen> {
  bool _isOnline = true;
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(_dashProvider);
    final bookings = ref.watch(_todayBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(dash)),

            // Compact stats strip
            SliverToBoxAdapter(child: _buildCompactStats(dash)),

            // Quick actions row
            SliverToBoxAdapter(child: _buildQuickActions()),

            // Today's appointments
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Row(children: [
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('BUGUN', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      Text('Bronlar', style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                    ]),
                  ),
                  _QuickActionBtn(
                    icon: Icons.add_rounded,
                    label: "Walk-in",
                    onTap: () => _showWalkInSheet(context),
                  ),
                ]),
              ),
            ),

            // Bookings list
            bookings.when(
              data: (list) => list.isEmpty
                  ? SliverToBoxAdapter(child: _emptyToday())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _AppointmentCard(
                            booking: list[i],
                            onRefresh: () => ref.invalidate(_todayBookingsProvider),
                          ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideY(begin: 0.06),
                        ),
                        childCount: list.length,
                      ),
                    ),
              loading: () => SliverToBoxAdapter(child: _loadingShimmer()),
              error: (_, __) => SliverToBoxAdapter(child: _emptyToday()),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _BarberNav(current: _navIndex, onTap: (i) {
        setState(() => _navIndex = i);
        const routes = ['/', '/appointments', '/services', '/schedule', '/profile'];
        if (i > 0) context.go(routes[i]);
      }),
    );
  }

  Widget _buildHeader(AsyncValue<Map<String, dynamic>> dash) {
    final name = (dash.value?['full_name'] as String? ?? 'Sartarosh').split(' ').first;
    final now = DateTime.now();
    final dateStr = DateFormat('d MMMM, EEEE', 'uz').format(now);

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Salom, $name 👋', style: const TextStyle(color: AppColors.textHint, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(dateStr, style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          ]),
        ),
        GestureDetector(
          onTap: () => _toggleOnline(),
          child: AnimatedContainer(
            duration: 300.ms,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _isOnline ? AppColors.successLight : AppColors.warmGray,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isOnline ? AppColors.success.withOpacity(0.3) : AppColors.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: 200.ms,
                width: 8, height: 8,
                decoration: BoxDecoration(color: _isOnline ? AppColors.success : AppColors.textHint, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(_isOnline ? 'Online' : 'Offline', style: TextStyle(color: _isOnline ? AppColors.success : AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: const Icon(Icons.notifications_outlined, color: AppColors.text, size: 20),
          ),
        ),
      ]),
    ).animate().fadeIn();
  }

  Future<void> _toggleOnline() async {
    final prev = _isOnline;
    setState(() => _isOnline = !_isOnline);
    try {
      await BarberApi.instance.post('/barbers/me/status/', data: {'is_online': _isOnline});
    } catch (_) {
      setState(() => _isOnline = prev);
    }
  }

  Widget _buildCompactStats(AsyncValue<Map<String, dynamic>> dash) {
    final d = dash.value ?? {};
    final todayCount = d['today_bookings'] as int? ?? 0;
    final todayRev = (d['today_revenue'] as num? ?? 0).toInt();
    final rating = (d['rating'] as num?)?.toStringAsFixed(1) ?? '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        Expanded(child: _miniStat('$todayCount ta', 'Bugun', Icons.today_rounded, AppColors.primary, AppColors.primaryLight)),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: () => context.push('/analytics'),
          child: _miniStat(_formatMoney(todayRev), 'Daromad', Icons.payments_outlined, AppColors.success, AppColors.successLight),
        )),
        const SizedBox(width: 10),
        Expanded(child: _miniStat(rating, 'Reyting', Icons.star_rounded, const Color(0xFFDDA74A), const Color(0xFFFFF8E6))),
      ]).animate().fadeIn(delay: 100.ms),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (Icons.photo_library_rounded, 'Portfolio', const Color(0xFF6C5CE7), const Color(0xFFF0EDFF), '/portfolio'),
      (Icons.people_alt_rounded,    'Mijozlar',  AppColors.primary,        AppColors.primaryLight,   '/crm'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: actions.map((a) {
          return Expanded(
            child: GestureDetector(
              onTap: () => context.push(a.$5),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: a.$4, borderRadius: BorderRadius.circular(14)),
                  child: Icon(a.$1, color: a.$3, size: 22),
                ),
                const SizedBox(height: 6),
                Text(a.$2, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }).toList(),
      ).animate().fadeIn(delay: 120.ms),
    );
  }

  Widget _miniStat(String value, String label, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 10, fontWeight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  Widget _emptyToday() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 34),
        ),
        const SizedBox(height: 14),
        const Text('Bugun bronlar yo\'q', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Yangi mijozlarni kutmoqdasiz', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      ]),
    );
  }

  Widget _loadingShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(children: List.generate(3, (i) => Container(
        height: 88,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: AppColors.warmGray, borderRadius: BorderRadius.circular(20)),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppColors.surface.withOpacity(0.6)))),
    );
  }

  void _showWalkInSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _WalkInSheet(
        onSubmit: (name, notes) async {
          final now = DateTime.now();
          final dateStr = DateFormat('yyyy-MM-dd').format(now);
          final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
          await BarberApi.instance.post('/bookings/barber/walk-in/', data: {
            'customer_name': name,
            'date': dateStr,
            'start_time': timeStr,
            'service_ids': <int>[],
            if (notes.isNotEmpty) 'notes': notes,
          });
          if (context.mounted) {
            Navigator.pop(sheetCtx);
            ref.invalidate(_todayBookingsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Walk-in muvaffaqiyatli qo\'shildi ✓'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  String _formatMoney(int val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)}K';
    return '$val';
  }
}

// ── Appointment card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onRefresh;
  const _AppointmentCard({required this.booking, required this.onRefresh});

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard> {
  bool _loading = false;

  String get _status => widget.booking['status'] as String? ?? 'pending';
  String get _customerName => widget.booking['customer_name'] as String? ?? 'Mijoz';
  String get _serviceName => widget.booking['service_name'] as String? ?? '';
  String get _startTime => (widget.booking['start_time'] as String? ?? '').length >= 5
      ? (widget.booking['start_time'] as String).substring(0, 5) : '';
  int get _price => (widget.booking['final_price'] as num? ?? 0).toInt();

  Color get _statusColor {
    switch (_status) {
      case 'confirmed': return AppColors.success;
      case 'pending': return AppColors.warning;
      case 'in_progress': return AppColors.primary;
      case 'completed': return AppColors.textHint;
      default: return AppColors.textHint;
    }
  }

  String get _statusLabel {
    const m = {'confirmed': 'Tasdiqlangan', 'pending': 'Kutilmoqda', 'in_progress': 'Jarayonda', 'completed': 'Bajarildi', 'cancelled': 'Bekor'};
    return m[_status] ?? _status;
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _loading = true);
    try {
      await BarberApi.instance.patch('/bookings/barber/${widget.booking['id']}/update/', data: {'status': status});
      widget.onRefresh();
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(children: [
        // Time block
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(_startTime, style: TextStyle(color: _statusColor, fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Container(width: 20, height: 1.5, color: _statusColor.withOpacity(0.3)),
            const SizedBox(height: 3),
            Text(_statusLabel, style: TextStyle(color: _statusColor.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_customerName, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15)),
          if (_serviceName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(_serviceName, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
          ],
          const SizedBox(height: 6),
          Text('${NumberFormat('#,###').format(_price)} so\'m', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(width: 12),
        if (_loading)
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
        else
          _actionButtons(),
      ]),
    );
  }

  Widget _actionButtons() {
    if (_status == 'pending') {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        _ActionBtn(label: 'Rad', color: AppColors.error, bg: AppColors.errorLight, onTap: () => _updateStatus('cancelled')),
        const SizedBox(width: 6),
        _ActionBtn(label: 'Tasdiqlash', color: AppColors.success, bg: AppColors.successLight, onTap: () => _updateStatus('confirmed')),
      ]);
    }
    if (_status == 'confirmed') {
      return _ActionBtn(label: 'Boshlash', color: AppColors.primary, bg: AppColors.primaryLight, onTap: () => _updateStatus('in_progress'));
    }
    if (_status == 'in_progress') {
      return _ActionBtn(label: 'Yakunlash', color: AppColors.success, bg: AppColors.successLight, onTap: () => _updateStatus('completed'));
    }
    return const SizedBox();
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Quick action button ───────────────────────────────────────────────────────

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ── Walk-in bottom sheet ──────────────────────────────────────────────────────

class _WalkInSheet extends StatefulWidget {
  final Future<void> Function(String name, String notes) onSubmit;
  const _WalkInSheet({required this.onSubmit});

  @override
  State<_WalkInSheet> createState() => _WalkInSheetState();
}

class _WalkInSheetState extends State<_WalkInSheet> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSubmit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showAppAlert(context, 'Iltimos mijoz ismini kiriting');
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(name, _notesCtrl.text.trim());
    } catch (e) {
      if (mounted) {
        showAppAlert(context, 'Xatolik: ${e.toString().replaceAll(RegExp(r'DioException[^:]*:'), '').trim().substring(0, e.toString().length.clamp(0, 80))}');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const Text('Walk-in mijoz', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          const Text('Hozir kelgan mijozni qo\'lda qo\'shing', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
          const SizedBox(height: 24),
          const Text('Mijoz ismi *', style: TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'Ism yoki laqab (majburiy)'),
          ),
          const SizedBox(height: 16),
          const Text('Xizmat / Izoh (ixtiyoriy)', style: TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'Soch olish, soqol...'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submitting ? null : _doSubmit,
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Qo\'shish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _BarberNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BarberNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'Bosh'),
      (Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Bronlar'),
      (Icons.content_cut_rounded, Icons.content_cut_outlined, 'Xizmatlar'),
      (Icons.schedule_rounded, Icons.schedule_outlined, 'Jadval'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = i == current;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(sel ? items[i].$1 : items[i].$2, color: sel ? AppColors.primary : AppColors.textHint, size: 22),
                    ),
                    const SizedBox(height: 3),
                    Text(items[i].$3, style: TextStyle(fontSize: 9, color: sel ? AppColors.primary : AppColors.textHint, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
