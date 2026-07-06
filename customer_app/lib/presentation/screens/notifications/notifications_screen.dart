import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';

final notificationsProvider = FutureProvider<List>((ref) async {
  try {
    final res = await DioClient.instance.get('/notifications/');
    final data = res.data;
    if (data is Map) return data['results'] ?? data['data'] ?? [];
    if (data is List) return data;
    return [];
  } catch (_) { return []; }
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Bildirishnomalar',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 18)),
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await DioClient.instance.post('/notifications/mark-all-read/');
                ref.invalidate(notificationsProvider);
              } catch (_) {}
            },
            child: const Text("Barchasini o'qildi",
                style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ref.watch(notificationsProvider).when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(24)),
                  child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 16),
                const Text("Bildirishnomalar yo'q",
                    style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                const Text('Yangi bildirishnomalar bu yerda ko\'rinadi',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              ]).animate().fadeIn(),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              itemCount: list.length,
              itemBuilder: (_, i) =>
                  _Card(item: Map<String, dynamic>.from(list[i] as Map), index: i)
                      .animate(delay: Duration(milliseconds: i * 40))
                      .fadeIn()
                      .slideY(begin: 0.06),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.border),
            const SizedBox(height: 12),
            const Text("Yuklashda xato", style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(notificationsProvider),
              child: const Text("Qayta urinish"),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Single notification card ─────────────────────────────────────────────────

class _Card extends ConsumerWidget {
  final Map<String, dynamic> item;
  final int index;
  const _Card({required this.item, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = item['is_read'] as bool? ?? true;
    final type   = item['notification_type'] as String? ?? 'system';
    final title  = _title(item['title'] as String?, type);
    final body   = _body(item['body']  as String?, type);
    final time   = _time(item['created_at'] as String?);

    final color  = _color(type);
    final icon   = _icon(type);

    return GestureDetector(
      onTap: () async {
        if (isRead) return;
        try {
          await DioClient.instance.post('/notifications/${item['id']}/read/');
          ref.invalidate(notificationsProvider);
        } catch (_) {}
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isRead ? AppColors.surface : const Color(0xFF1E2A3A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppColors.border : color.withOpacity(0.4),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: isRead
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isRead ? color.withOpacity(0.12) : color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isRead ? AppColors.text : Colors.white,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 3),
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ]),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          color: isRead ? AppColors.textSecondary : Colors.white.withOpacity(0.65),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      time,
                      style: TextStyle(
                        color: isRead ? AppColors.textTertiary : Colors.white.withOpacity(0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Title: strip emojis; if empty use default ──────────────────────────────
  static final _re = RegExp(
    r'[\u{1F000}-\u{1FFFF}]|[\u{2600}-\u{27BF}]|[\u{FE00}-\u{FEFF}]|[\u{1F900}-\u{1F9FF}]',
    unicode: true,
  );

  String _title(String? raw, String type) {
    final cleaned = (raw ?? '').replaceAll(_re, '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isNotEmpty) return cleaned;
    switch (type) {
      case 'booking':   return 'Bron holati yangilandi';
      case 'reminder':  return 'Eslatma';
      case 'promotion': return 'Yangi taklif';
      case 'review':    return 'Sharh qoldiring';
      default:          return 'Bildirishnoma';
    }
  }

  String _body(String? raw, String type) {
    final cleaned = (raw ?? '').replaceAll(_re, '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isNotEmpty) return cleaned;
    switch (type) {
      case 'booking':   return 'Broningizda yangilik bor';
      case 'reminder':  return 'Tez kunda vaqtingiz';
      case 'promotion': return 'Yangi chegirma va aktsiyalar sizni kutmoqda';
      case 'review':    return 'Xizmatni baholang';
      default:          return '';
    }
  }

  String _time(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt   = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'Hozirgina';
      if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
      if (diff.inHours   < 24) return '${diff.inHours} soat oldin';
      if (diff.inDays    < 7)  return '${diff.inDays} kun oldin';
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) { return ''; }
  }

  Color _color(String type) {
    switch (type) {
      case 'booking':   return const Color(0xFF10B981);
      case 'reminder':  return const Color(0xFFF59E0B);
      case 'promotion': return AppColors.primary;
      case 'review':    return const Color(0xFFDDA74A);
      default:          return const Color(0xFF6366F1);
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'booking':   return Icons.calendar_month_rounded;
      case 'reminder':  return Icons.alarm_rounded;
      case 'promotion': return Icons.local_offer_rounded;
      case 'review':    return Icons.star_rounded;
      default:          return Icons.notifications_rounded;
    }
  }
}
