import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api.dart';
import '../../../core/theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final barberNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await BarberApi.instance.get('/notifications/');
    final raw = res.data;
    final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : raw;
    return List<Map<String, dynamic>>.from(list);
  } catch (_) {
    return [];
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class BarberNotificationsScreen extends ConsumerWidget {
  const BarberNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text(
          'Bildirishnomalar',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(ref),
            child: const Text(
              'Barchasini o\'qildi',
              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ref.watch(barberNotificationsProvider).when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Bildirishnomalar yo\'q', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Yangi bildirishnomalar bu yerda ko\'rinadi', style: TextStyle(color: AppColors.textHint, fontSize: 13), textAlign: TextAlign.center),
                ],
              ).animate().fadeIn(),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(barberNotificationsProvider),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _NotificationCard(item: list[i], index: i, onTap: () => _markRead(ref, list[i])),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text('Xato: $e', style: const TextStyle(color: AppColors.textHint)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(barberNotificationsProvider),
                child: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAllRead(WidgetRef ref) async {
    try {
      await BarberApi.instance.post('/notifications/mark-all-read/');
      ref.invalidate(barberNotificationsProvider);
    } catch (_) {}
  }

  Future<void> _markRead(WidgetRef ref, Map<String, dynamic> item) async {
    if (item['is_read'] == true) return;
    try {
      await BarberApi.instance.post('/notifications/${item['id']}/read/');
      ref.invalidate(barberNotificationsProvider);
    } catch (_) {}
  }
}

// ── Notification Card ─────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final VoidCallback onTap;
  const _NotificationCard({required this.item, required this.index, required this.onTap});

  static final _emojiRe = RegExp(
    r'[\u{1F300}-\u{1FFFF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
    unicode: true,
  );

  String _cleanTitle(String? raw, String type) {
    final s = (raw ?? '').replaceAll(_emojiRe, '').trim();
    if (s.isEmpty) return _defaultTitle(type);
    return raw!.trim();
  }

  String _cleanBody(String? raw, String type) {
    final s = (raw ?? '').replaceAll(_emojiRe, '').trim();
    if (s.isEmpty) return _defaultBody(type);
    return raw!.trim();
  }

  String _defaultTitle(String type) {
    switch (type) {
      case 'booking': return 'Bron holati yangilandi';
      case 'new_booking': return 'Yangi bron keldi';
      case 'reminder': return 'Eslatma';
      case 'review': return 'Yangi sharh';
      case 'system': return 'Tizim xabari';
      default: return 'Bildirishnoma';
    }
  }

  String _defaultBody(String type) {
    switch (type) {
      case 'booking': return 'Bron ma\'lumotlari yangilandi';
      case 'new_booking': return 'Mijozdan yangi buyurtma keldi';
      case 'reminder': return 'Bugungi jadval haqida eslatma';
      case 'review': return 'Mijoz xizmatni baholadi';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = item['is_read'] as bool? ?? true;
    final type = item['notification_type'] as String? ?? 'system';
    final title = _cleanTitle(item['title'] as String?, type);
    final body = _cleanBody(item['body'] as String?, type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? AppColors.surface : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppColors.border : AppColors.primary.withOpacity(0.3),
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _typeColor(type).withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(_typeIcon(type), color: _typeColor(type), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                  ]),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(item['created_at'] as String?),
                    style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 40)).fadeIn().slideX(begin: 0.04),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'booking':
      case 'new_booking': return AppColors.success;
      case 'reminder': return const Color(0xFFF59E0B);
      case 'review': return const Color(0xFFDDA74A);
      case 'system': return AppColors.primary;
      default: return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'booking':
      case 'new_booking': return Icons.calendar_month_rounded;
      case 'reminder': return Icons.alarm_rounded;
      case 'review': return Icons.star_rounded;
      case 'system': return Icons.info_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Hozirgina';
      if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
      if (diff.inHours < 24) return '${diff.inHours} soat oldin';
      if (diff.inDays < 7) return '${diff.inDays} kun oldin';
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
