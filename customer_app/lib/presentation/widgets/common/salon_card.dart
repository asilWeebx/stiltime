import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/salon_model.dart';

class SalonCard extends StatelessWidget {
  final SalonModel? salon;
  final int index;
  final VoidCallback? onTap;

  const SalonCard({
    super.key,
    this.salon,
    this.index = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder data for home screen previews
    final placeholderNames = [
      'Elite Barbershop', 'Royal Beauty', "Gentleman's Club",
      'Luxury Spa', 'Urban Style',
    ];
    final placeholderAddresses = [
      'Chilonzor, 3-mavze', 'Yunusobod, 4-ko\'cha', 'Mirzo Ulugbek',
    ];

    final name = salon?.name ?? placeholderNames[index % placeholderNames.length];
    final rating = salon?.rating ?? (4.5 + index * 0.1);
    final reviewCount = salon?.reviewCount ?? salon?.totalReviews ?? (50 + index * 20);
    final address = salon?.address ?? placeholderAddresses[index % placeholderAddresses.length];
    final coverImage = salon?.coverImage;
    final isOpen = salon?.isOpen ?? true;
    final isFavorite = salon?.isFavorite ?? false;
    final categoryName = salon?.categoryName ?? salon?.categoryNames.firstOrNull;

    return GestureDetector(
      onTap: onTap ?? (salon != null ? () => context.push('/salon/${salon!.id}') : null),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverImage != null
                        ? Image.network(
                            coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _gradientPlaceholder(),
                          )
                        : _gradientPlaceholder(),
                    // Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                        ),
                      ),
                    ),
                    // Rating badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
                            const SizedBox(width: 2),
                            Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    // Open badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isOpen ? AppColors.success : Colors.red).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOpen ? 'Ochiq' : 'Yopiq',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16), overflow: TextOverflow.ellipsis),
                      ),
                      Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? Colors.red : AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                  if (categoryName != null) ...[
                    const SizedBox(height: 2),
                    Text(categoryName, style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 14),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(address, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.reviews_outlined, color: AppColors.textSecondary, size: 13),
                      const SizedBox(width: 4),
                      Text('$reviewCount ta sharh', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Bron', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientPlaceholder() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.6 + index * 0.05),
          AppColors.primaryDark.withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(Icons.store_mall_directory_rounded, color: Colors.white.withOpacity(0.3), size: 60),
    ),
  );
}
