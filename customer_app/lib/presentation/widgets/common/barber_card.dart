import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class BarberCard extends StatelessWidget {
  /// Pass either [barber] (API map) or use [index] for placeholder rendering
  final Map<String, dynamic>? barber;
  final int index;
  final VoidCallback? onTap;

  const BarberCard({
    super.key,
    this.barber,
    this.index = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderNames = [
      'Alisher U.', 'Bobur K.', 'Sardor M.', 'Jasur T.',
      'Nodir A.', 'Ulugbek R.', 'Sherzod B.', 'Ravshan M.',
    ];

    final name = barber?['full_name'] ?? placeholderNames[index % placeholderNames.length];
    final rating = (barber?['rating'] as num?)?.toStringAsFixed(1) ?? (4.5 + index * 0.1).toStringAsFixed(1);
    final reviewCount = barber?['total_reviews'] ?? (30 + index * 15);
    final isOnline = barber?['is_online'] ?? (index % 3 != 0);
    final avatar = barber?['avatar'] as String?;
    final barberId = barber?['id'] as int?;

    return GestureDetector(
      onTap: onTap ?? (barberId != null ? () => context.push('/barber/$barberId') : null),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Stack(
                children: [
                  avatar != null
                      ? CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(avatar),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                  if (isOnline == true)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.star, size: 13),
                  Text(' $rating', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$reviewCount sharh',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 30,
                child: ElevatedButton(
                  onPressed: onTap ?? (barberId != null ? () => context.push('/barber/$barberId') : null),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Bron'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
