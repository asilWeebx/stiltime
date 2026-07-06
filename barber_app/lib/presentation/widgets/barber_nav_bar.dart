import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class BarberNavBar extends StatelessWidget {
  final int current;
  const BarberNavBar({super.key, required this.current});

  static const _items = [
    (icon: Icons.home_rounded, label: 'Bosh sahifa', route: '/'),
    (icon: Icons.people_rounded, label: 'Mijozlar', route: '/crm'),
    (icon: Icons.photo_library_rounded, label: 'Portfolio', route: '/portfolio'),
    (icon: Icons.bar_chart_rounded, label: 'Statistika', route: '/analytics'),
    (icon: Icons.settings_rounded, label: 'Sozlamalar', route: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: _items.asMap().entries.map((e) {
              final selected = e.key == current;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (!selected) context.go(_items[e.key].route);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primaryLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(e.value.icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(e.value.label, style: TextStyle(fontSize: 9, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? AppColors.primary : AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
