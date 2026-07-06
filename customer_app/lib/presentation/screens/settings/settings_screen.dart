import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../providers/auth_provider.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<String, bool> _switches = {
    'reminders': true,
    'booking': true,
    'promotions': true,
  };
  int _reminderMinutes = 30;
  bool _loaded = false;

  static const _reminderOptions = [
    (15, '15 daqiqa oldin'),
    (30, '30 daqiqa oldin'),
    (45, '45 daqiqa oldin'),
    (60, '1 soat oldin'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await DioClient.instance.get('/users/me/');
      setState(() {
        _switches = {
          'reminders': res.data['notification_reminders'] ?? true,
          'booking': res.data['notification_booking'] ?? true,
          'promotions': res.data['notification_promotions'] ?? true,
        };
        _reminderMinutes = (res.data['reminder_minutes'] as num?)?.toInt() ?? 30;
        _loaded = true;
      });
    } catch (_) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    setState(() => _switches[key] = value);
    final payload = <String, dynamic>{};
    if (key == 'reminders') payload['notification_reminders'] = value;
    if (key == 'booking') payload['notification_booking'] = value;
    if (key == 'promotions') payload['notification_promotions'] = value;
    try {
      await DioClient.instance.patch('/users/me/', data: payload);
    } catch (_) {
      setState(() => _switches[key] = !value);
    }
  }

  Future<void> _changeReminderTime(BuildContext context) async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eslatma vaqti', style: TextStyle(fontWeight: FontWeight.w700)),
        children: _reminderOptions.map((opt) {
          final (mins, label) = opt;
          return RadioListTile<int>(
            value: mins,
            groupValue: _reminderMinutes,
            activeColor: AppColors.primary,
            title: Text(label),
            onChanged: (v) => Navigator.pop(context, v),
          );
        }).toList(),
      ),
    );
    if (chosen != null && chosen != _reminderMinutes) {
      setState(() => _reminderMinutes = chosen);
      try {
        await DioClient.instance.patch('/users/me/', data: {'reminder_minutes': chosen});
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Sozlamalar', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Notifications section
                _sectionLabel('Eslatmalar'),
                _settingsCard([
                  _switchTile(
                    'reminders',
                    Icons.alarm,
                    'Eslatmalar',
                    'Buyurtma eslatmalarini olish',
                  ),
                  if (_switches['reminders'] == true)
                    ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 18),
                      ),
                      title: const Text('Eslatma vaqti', style: TextStyle(color: AppColors.text, fontSize: 14)),
                      subtitle: Text(
                        _reminderOptions.firstWhere((o) => o.$1 == _reminderMinutes, orElse: () => (30, '30 daqiqa oldin')).$2,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                      onTap: () => _changeReminderTime(context),
                    ),
                  _switchTile(
                    'booking',
                    Icons.calendar_today_outlined,
                    'Bron holati',
                    'Bron tasdiqlanganda bildirishnoma',
                  ),
                ]).animate().fadeIn().slideY(begin: 0.05),

                const SizedBox(height: 16),

                _sectionLabel('Marketing'),
                _settingsCard([
                  _switchTile(
                    'promotions',
                    Icons.local_offer_outlined,
                    'Aksiyalar va takliflar',
                    'Maxsus takliflar haqida bildirishnomalar',
                  ),
                ]).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05),

                const SizedBox(height: 16),

                _sectionLabel('Hisob'),
                _settingsCard([
                  _actionTile(Icons.phone_outlined, 'Telefon raqamni o\'zgartirish', () {}),
                  _actionTile(Icons.delete_outline, 'Hisobni o\'chirish', () => _deleteAccount(context), isDestructive: true),
                ]).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05),

                const SizedBox(height: 16),

                _sectionLabel('Ilova haqida'),
                _settingsCard([
                  _infoTile(Icons.info_outline, 'Versiya', '1.0.0'),
                  _infoTile(Icons.build_outlined, 'Muhit', 'Production'),
                  _actionTile(Icons.rate_review_outlined, 'Ilova haqida fikr bildiring', () {}),
                ]).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05),
              ],
            ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      label,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    ),
  );

  Widget _settingsCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: children.asMap().entries.map((e) {
        final isLast = e.key == children.length - 1;
        return Column(
          children: [
            e.value,
            if (!isLast) Divider(height: 1, color: AppColors.border, indent: 56),
          ],
        );
      }).toList(),
    ),
  );

  Widget _switchTile(String key, IconData icon, String title, String subtitle) {
    return SwitchListTile(
      value: _switches[key] ?? false,
      onChanged: (v) => _updateSetting(key, v),
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.text, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      activeColor: AppColors.primary,
    );
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isDestructive ? Colors.red : AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : AppColors.primary, size: 18),
      ),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : AppColors.text, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
      onTap: onTap,
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label, style: const TextStyle(color: AppColors.text, fontSize: 14)),
      trailing: Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hisobni o\'chirish', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu amalni qaytarib bo\'lmaydi. Barcha ma\'lumotlaringiz o\'chiriladi.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Bekor", style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("O'chirish", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await DioClient.instance.delete('/users/me/');
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/phone');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xato: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
