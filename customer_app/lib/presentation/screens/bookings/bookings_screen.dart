import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/booking_model.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final _tabProvider = StateProvider<int>((ref) => 0);

final _bookingsProvider = FutureProvider.family<List<BookingModel>, int>((ref, tab) async {
  final params = <String, dynamic>{};
  switch (tab) {
    case 0: params['status__in'] = 'pending,confirmed,in_progress'; break;
    case 1: params['status__in'] = 'completed,no_show'; break;
    case 2: params['status'] = 'cancelled'; break;
  }
  try {
    params['ordering'] = '-date,-start_time';
    final res = await DioClient.instance.get('/bookings/my/', queryParameters: params);
    final list = res.data is Map ? (res.data['results'] ?? res.data['data'] ?? []) : res.data;
    final bookings = (list as List).map((e) => BookingModel.fromJson(e)).toList();
    // Client-side sort as fallback: newest first
    bookings.sort((a, b) {
      final aKey = '${a.date}${a.startTime}';
      final bKey = '${b.date}${b.startTime}';
      return bKey.compareTo(aKey);
    });
    return bookings;
  } catch (_) {
    return [];
  }
});

// ── Screen ───────────────────────────────────────────────────────────────────

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  static const _tabs = ['Faol bronlar', 'Tarix', 'Bekor qilingan'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(tab: tab, ref: ref),
            Expanded(
              child: ref.watch(_bookingsProvider(tab)).when(
                data: (list) => list.isEmpty
                    ? _EmptyState(tab: tab)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async => ref.invalidate(_bookingsProvider(tab)),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _BookingCard(
                            booking: list[i],
                            index: i,
                            onCancelled: () => ref.invalidate(_bookingsProvider(tab)),
                          ),
                        ),
                      ),
                loading: () => _BookingSkeleton(),
                error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(_bookingsProvider(tab))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int tab;
  final WidgetRef ref;
  const _Header({required this.tab, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Mening bronlarim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tab bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: List.generate(BookingsScreen._tabs.length, (i) {
                final selected = i == tab;
                return GestureDetector(
                  onTap: () => ref.read(_tabProvider.notifier).state = i,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      BookingsScreen._tabs[i],
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

// ── Booking Card ─────────────────────────────────────────────────────────────

class _BookingCard extends ConsumerWidget {
  final BookingModel booking;
  final int index;
  final VoidCallback onCancelled;
  const _BookingCard({required this.booking, required this.index, required this.onCancelled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/booking-detail/${booking.id}').then((_) => onCancelled()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _statusBg(booking.status),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: _statusColor(booking.status), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(booking.statusLabel, style: TextStyle(color: _statusColor(booking.status), fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  Text('#${booking.id}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Salon image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: booking.salonImage != null
                        ? Image.network(booking.salonImage!, width: 64, height: 64, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imgPlaceholder())
                        : _imgPlaceholder(),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.salonName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                        const SizedBox(height: 3),
                        if (booking.barberName != null && booking.barberName!.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(booking.barberName!, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(booking.date, style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 10),
                          const Icon(Icons.access_time_rounded, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(booking.startTime, style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500)),
                        ]),
                        if (booking.serviceName != null && booking.serviceName!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(booking.serviceName!, style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPrice(booking.totalPrice),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
                      ),
                      Text("so'm", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            if (booking.canCancel || booking.isCompleted) ...[
              Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    if (booking.canCancel) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancel(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Bekor qilish', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.push('/salon/${booking.salonId}'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text("Yo'nalish", style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                    if (booking.isCompleted)
                      Expanded(
                        child: booking.hasReview
                            ? OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.check_circle_rounded, size: 16),
                                label: const Text('Siz sharh berdingiz', style: TextStyle(fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: () => _showReviewSheet(context, ref),
                                icon: const Icon(Icons.star_rounded, size: 16),
                                label: const Text('Sharh qoldirish', style: TextStyle(fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideY(begin: 0.06),
    );
  }

  String _formatPrice(dynamic price) {
    final p = int.tryParse(price.toString()) ?? 0;
    if (p >= 1000) {
      final str = p.toString();
      final buf = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
        buf.write(str[i]);
      }
      return buf.toString();
    }
    return price.toString();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return const Color(0xFF10B981);
      case 'pending':   return const Color(0xFFF59E0B);
      case 'in_progress': return AppColors.primary;
      case 'completed': return const Color(0xFF6B7280);
      case 'cancelled': return Colors.red;
      default: return AppColors.textSecondary;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'confirmed': return const Color(0xFFF0FDF4);
      case 'pending':   return const Color(0xFFFFFBEB);
      case 'in_progress': return const Color(0xFFEFF6FF);
      case 'completed': return const Color(0xFFF9FAFB);
      case 'cancelled': return const Color(0xFFFEF2F2);
      default: return AppColors.background;
    }
  }

  Widget _imgPlaceholder() => Container(
    width: 64, height: 64,
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
    child: const Icon(Icons.store_mall_directory_outlined, color: AppColors.textSecondary, size: 28),
  );

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Bron tafsilotlari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 20),
            _detailRow(Icons.store_outlined, 'Salon', booking.salonName),
            if (booking.barberName != null) _detailRow(Icons.person_outline_rounded, 'Barber', booking.barberName!),
            if (booking.serviceName != null) _detailRow(Icons.content_cut_rounded, 'Xizmat', booking.serviceName!),
            _detailRow(Icons.calendar_today_outlined, 'Sana', booking.date),
            _detailRow(Icons.access_time_rounded, 'Vaqt', '${booking.startTime}${booking.endTime != null ? " – ${booking.endTime}" : ""}'),
            _detailRow(Icons.payments_outlined, 'Narx', '${booking.totalPrice} so\'m'),
            _detailRow(Icons.info_outline_rounded, 'Status', booking.statusLabel),
            if (booking.notes != null && booking.notes!.isNotEmpty)
              _detailRow(Icons.note_outlined, 'Izoh', booking.notes!),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 12),
        SizedBox(width: 72, child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text))),
      ],
    ),
  );

  void _showReviewSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        bookingId: booking.id,
        barberId: booking.barber,
        barberName: booking.barberName ?? '',
        salonId: booking.salon,
        onDone: () => ref.invalidate(_bookingsProvider(1)),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Bekor qilish', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
        content: const Text('Bronni bekor qilmoqchimisiz?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Yo'q")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ha, bekor', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await DioClient.instance.post('/bookings/${booking.id}/cancel/');
        onCancelled();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bron bekor qilindi'), backgroundColor: Color(0xFF10B981)),
          );
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ── Empty & Error States ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int tab;
  const _EmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    final data = [
      (Icons.calendar_month_outlined, 'Faol bronlar yo\'q', 'Yangi xizmat band qilish uchun salonlarni ko\'ring'),
      (Icons.history_rounded, 'Tarix bo\'sh', 'Xizmatlardan foydalangandan so\'ng bu yerda ko\'rinadi'),
      (Icons.cancel_outlined, 'Bekor qilingan bronlar yo\'q', ''),
    ];
    final (icon, title, subtitle) = data[tab];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text), textAlign: TextAlign.center),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Salonlarni ko\'rish'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ],
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        const Text("Ma'lumot yuklanmadi", style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Qayta urinish')),
      ],
    ),
  );
}

// ── Review Sheet ──────────────────────────────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  final int bookingId;
  final int barberId;
  final String barberName;
  final int salonId;
  final VoidCallback onDone;
  const _ReviewSheet({
    required this.bookingId, required this.barberId,
    required this.barberName, required this.salonId, required this.onDone,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 0;
  bool _anonymous = false;
  bool _submitting = false;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, yulduz baholang'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await DioClient.instance.post('/reviews/', data: {
        'booking': widget.bookingId,
        'barber': widget.barberId,
        'salon': widget.salonId,
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
        'is_anonymous': _anonymous,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharhingiz uchun rahmat! ⭐'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        String msg = 'Xatolik yuz berdi';
        if (e is DioException) {
          final d = e.response?.data;
          if (d is Map && d['booking'] != null) msg = 'Bu bron uchun allaqachon sharh yozilgan';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
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
          Center(child: Container(
            width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Sharh qoldirish', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text(
                widget.barberName.isNotEmpty ? '${widget.barberName} xizmatini baholang' : 'Xizmatni baholang',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Star rating
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final filled = i < _rating;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          filled ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: filled ? const Color(0xFFF59E0B) : AppColors.border,
                          size: 44,
                        ).animate(target: filled ? 1 : 0).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 150.ms),
                      ),
                    );
                  }),
                ),
              ),
              if (_rating > 0) ...[
                const SizedBox(height: 6),
                Center(child: Text(
                  ['', 'Juda yomon 😞', 'Yomon 😕', 'O\'rtacha 😐', 'Yaxshi 😊', 'A\'lo! 🤩'][_rating],
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                )),
              ],
              const SizedBox(height: 20),

              // Comment
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                maxLength: 500,
                style: const TextStyle(color: AppColors.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Xizmat haqida yozing (ixtiyoriy)...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary)),
                  counterStyle: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),

              // Anonymous toggle
              GestureDetector(
                onTap: () => setState(() => _anonymous = !_anonymous),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: _anonymous ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: _anonymous ? AppColors.primary : AppColors.border, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _anonymous ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
                  ),
                  const SizedBox(width: 10),
                  const Text('Anonim tarzda sharh qoldirish', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Sharh yuborish', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────────────

class _BookingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Shimmer(width: 48, height: 48, radius: 14),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Shimmer(width: 140, height: 14, radius: 7),
              const SizedBox(height: 6),
              _Shimmer(width: 100, height: 11, radius: 5),
            ])),
            _Shimmer(width: 70, height: 26, radius: 13),
          ]),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Row(children: [
            _Shimmer(width: 120, height: 11, radius: 5),
            const Spacer(),
            _Shimmer(width: 80, height: 11, radius: 5),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _Shimmer(width: 90, height: 11, radius: 5),
            const Spacer(),
            _Shimmer(width: 60, height: 11, radius: 5),
          ]),
          const SizedBox(height: 14),
          _Shimmer(width: double.infinity, height: 40, radius: 12),
        ]),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _Shimmer({required this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.warmGray, borderRadius: BorderRadius.circular(radius)),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppColors.surface.withOpacity(0.7));
  }
}
