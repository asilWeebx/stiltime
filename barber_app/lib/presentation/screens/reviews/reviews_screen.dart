import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api.dart';
import '../../../core/theme.dart';

final _reviewsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final meRes = await BarberApi.instance.get('/barbers/me/');
    final barberId = meRes.data['id'];
    final res = await BarberApi.instance.get('/reviews/', queryParameters: {'barber': barberId});
    final list = res.data is Map ? (res.data['results'] ?? res.data['data'] ?? []) : res.data;
    return (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
});

class BarberReviewsScreen extends ConsumerWidget {
  const BarberReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(_reviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/profile'),
        ),
        title: const Text('Sharhlar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(_reviewsProvider),
            child: const Text('Qayta urinish'),
          ),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: const Icon(Icons.star_outline_rounded, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('Hali sharh yo\'q', style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Mijozlar sharh qoldirganda bu yerda ko\'rinadi',
                      style: TextStyle(color: AppColors.textHint, fontSize: 14), textAlign: TextAlign.center),
                ],
              ),
            );
          }

          // Summary stats
          final totalRating = reviews.fold<double>(0, (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 0));
          final avg = reviews.isNotEmpty ? totalRating / reviews.length : 0.0;
          final starCounts = List.generate(5, (i) => reviews.where((r) => (r['rating'] as num?)?.toInt() == i + 1).length);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_reviewsProvider),
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Rating summary card
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        // Big average
                        Column(
                          children: [
                            Text(avg.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.text, height: 1)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (i) => Icon(
                                i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: const Color(0xFFF59E0B), size: 16,
                              )),
                            ),
                            const SizedBox(height: 4),
                            Text('${reviews.length} sharh', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Bar chart
                        Expanded(
                          child: Column(
                            children: List.generate(5, (i) {
                              final star = 5 - i;
                              final count = starCounts[star - 1];
                              final pct = reviews.isNotEmpty ? count / reviews.length : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(children: [
                                  Text('$star', style: const TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 11),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: AppColors.border,
                                        color: const Color(0xFFF59E0B),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(width: 20, child: Text('$count', style: const TextStyle(color: AppColors.textHint, fontSize: 11))),
                                ]),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.05),
                ),

                // Review list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ReviewCard(review: reviews[i], index: i, onReply: () => ref.invalidate(_reviewsProvider)),
                      childCount: reviews.length,
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
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final int index;
  final VoidCallback onReply;
  const _ReviewCard({required this.review, required this.index, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final customerName = review['customer_name'] as String? ?? 'Mijoz';
    final customerAvatar = review['customer_avatar'] as String?;
    final reply = review['reply'] as String? ?? '';
    final createdAt = review['created_at'] as String? ?? '';
    final dateStr = createdAt.isNotEmpty
        ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(createdAt) ?? DateTime.now())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + date + stars
          Row(
            children: [
              ClipOval(
                child: customerAvatar != null
                    ? Image.network(customerAvatar, width: 42, height: 42, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(customerName))
                    : _avatarFallback(customerName),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
                    if (dateStr.isNotEmpty)
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(
                  i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFF59E0B), size: 16,
                )),
              ),
            ],
          ),

          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(comment, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
          ],

          // Barber reply
          if (reply.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(reply, style: const TextStyle(color: AppColors.primary, fontSize: 13, height: 1.4))),
                ],
              ),
            ),
          ],

          // Reply button
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showReplyDialog(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.reply_rounded, color: AppColors.textHint, size: 14),
                const SizedBox(width: 4),
                Text(
                  reply.isNotEmpty ? 'Javobni tahrirlash' : 'Javob berish',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideY(begin: 0.05);
  }

  Widget _avatarFallback(String name) => Container(
    width: 42, height: 42,
    color: AppColors.primaryLight,
    child: Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'M',
      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16),
    )),
  );

  void _showReplyDialog(BuildContext context) {
    final ctrl = TextEditingController(text: review['reply'] as String? ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Javob berish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 3,
              autofocus: true,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Mijozga javob yozing...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await BarberApi.instance.patch('/reviews/${review['id']}/reply/', data: {'reply': ctrl.text.trim()});
                    if (context.mounted) {
                      Navigator.pop(context);
                      onReply();
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Xatolik yuz berdi'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Yuborish', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
