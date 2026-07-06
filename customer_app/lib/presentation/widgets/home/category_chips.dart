import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class CategoryChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const CategoryChips({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cats = [{'id': 0, 'name': 'Barchasi', 'icon': '🌟'}, ...AppConstants.categories];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cats.asMap().entries.map((e) {
          final i = e.key;
          final cat = e.value;
          final isSelected = selected == i;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.gradientPrimary : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: isSelected ? Colors.transparent : AppColors.border),
                boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat['icon']! as String, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    cat['name']! as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.text,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
