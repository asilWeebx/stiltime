import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/booking_model.dart';
import '../../widgets/map/yandex_map_widget.dart';

final _bookingDetailProvider = FutureProvider.family<BookingModel, int>((ref, id) async {
  final res = await DioClient.instance.get('/bookings/$id/');
  return BookingModel.fromJson(Map<String, dynamic>.from(res.data));
});

class BookingDetailScreen extends ConsumerWidget {
  final int bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text('Yuklab bo\'lmadi', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextButton(onPressed: () => ref.invalidate(_bookingDetailProvider(bookingId)), child: const Text('Qayta urinish')),
          ]),
        ),
        data: (booking) => _BookingDetailBody(booking: booking, ref: ref),
      ),
    );
  }
}

class _BookingDetailBody extends StatelessWidget {
  final BookingModel booking;
  final WidgetRef ref;
  const _BookingDetailBody({required this.booking, required this.ref});

  @override
  Widget build(BuildContext context) {
    final coverUrl = booking.barberCover ?? booking.salonCover;
    final hasMap = booking.salonLatitude != null && booking.salonLongitude != null;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero header ──
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                coverUrl != null
                    ? Image.network(coverUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _coverFallback())
                    : _coverFallback(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20, left: 20, right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.barberName ?? booking.salonName,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1),
                            ),
                            if ((booking.barberSpecialization ?? '').isNotEmpty)
                              Text(
                                booking.barberSpecialization!,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            booking.barberRating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status badge ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _statusBg(booking.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: _statusColor(booking.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          booking.statusLabel,
                          style: TextStyle(color: _statusColor(booking.status), fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Text('#${booking.id}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Action buttons ──
              if (booking.canCancel || booking.isCompleted)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    if (booking.isCompleted && !booking.hasReview)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.pop(), // review handled on bookings list
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: const Text('Sharh qoldirish', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    if (booking.canCancel) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _cancel(context, ref),
                          icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                          label: const Text('Yozuvni bekor qilish', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),

              const SizedBox(height: 24),

              // ── Date & Time ──
              _sectionCard(
                context,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _formatDate(booking.date),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.access_time_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${booking.startTime}${booking.endTime != null ? " – ${booking.endTime}" : ""}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${booking.totalDuration} daq',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ]),
              ),

              const SizedBox(height: 12),

              // ── Services ──
              _sectionCard(
                context,
                label: 'Tanlangan xizmatlar',
                child: Column(children: [
                  ...booking.services.map((svc) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(svc.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text)),
                        Text('${svc.duration} daq', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ])),
                      Text(
                        '${_fmtPrice(svc.price)} so\'m',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text),
                      ),
                    ]),
                  )),
                  if (booking.services.length > 1) ...[
                    Divider(color: AppColors.border),
                    Row(children: [
                      const Text('Jami:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
                      const Spacer(),
                      Text('${_fmtPrice(booking.finalPrice)} so\'m',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
                    ]),
                  ],
                ]),
              ),

              const SizedBox(height: 12),

              // ── Notes ──
              if (booking.notes != null && booking.notes!.isNotEmpty)
                _sectionCard(
                  context,
                  label: 'Izoh',
                  child: Text(booking.notes!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
                ),

              if (booking.notes != null && booking.notes!.isNotEmpty) const SizedBox(height: 12),

              // ── Location ──
              if (booking.salonAddress != null || hasMap)
                _sectionCard(
                  context,
                  label: 'Manzil',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (booking.salonAddress != null && booking.salonAddress!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.salonAddress!,
                              style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                            ),
                          ),
                        ]),
                      ),
                    if (hasMap)
                      YandexMapWidget(
                        latitude: booking.salonLatitude!,
                        longitude: booking.salonLongitude!,
                        title: booking.salonName,
                        height: 200,
                      )
                    else if (booking.salonAddress != null)
                      MapPlaceholder(address: booking.salonAddress!),
                  ]),
                ),

              const SizedBox(height: 24),

              // ── Jami footer ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Jami:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.services.length} Xizmat${booking.services.length > 1 ? "lar" : ""} · ${booking.totalDuration} min',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ]),
                  const Spacer(),
                  Text(
                    '${_fmtPrice(booking.finalPrice)} so\'m',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text),
                  ),
                ]),
              ),

              const SizedBox(height: 40),
            ],
          ).animate().fadeIn().slideY(begin: 0.05),
        ),
      ],
    );
  }

  Widget _sectionCard(BuildContext context, {String? label, required Widget child}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (label != null) ...[
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 10),
        ],
        child,
      ]),
    ),
  );

  Widget _coverFallback() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1E3A6E), Color(0xFF4E6EF5)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: const Center(child: Icon(Icons.content_cut_rounded, size: 64, color: Colors.white24)),
  );

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      const days = ['Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan', 'Yak'];
      const months = ['', 'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', 'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr'];
      return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]}';
    } catch (_) {
      return date;
    }
  }

  String _fmtPrice(double price) {
    final p = price.toInt();
    if (p >= 1000) {
      final str = p.toString();
      final buf = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
        buf.write(str[i]);
      }
      return buf.toString();
    }
    return p.toString();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return const Color(0xFF10B981);
      case 'pending': return const Color(0xFFF59E0B);
      case 'in_progress': return AppColors.primary;
      case 'completed': return const Color(0xFF6B7280);
      case 'cancelled': return Colors.red;
      default: return AppColors.textSecondary;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'confirmed': return const Color(0xFFF0FDF4);
      case 'pending': return const Color(0xFFFFFBEB);
      case 'in_progress': return const Color(0xFFEFF6FF);
      case 'completed': return const Color(0xFFF9FAFB);
      case 'cancelled': return const Color(0xFFFEF2F2);
      default: return AppColors.background;
    }
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bron bekor qilindi'), backgroundColor: Color(0xFF10B981)),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
