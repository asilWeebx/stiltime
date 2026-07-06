import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api.dart';
import '../../../core/theme.dart';

class BarberSettingsScreen extends StatefulWidget {
  const BarberSettingsScreen({super.key});

  @override
  State<BarberSettingsScreen> createState() => _State();
}

class _State extends State<BarberSettingsScreen> {
  Map<String, dynamic> _profile = {};
  bool _loading = true;
  bool _notifBooking = true;
  bool _notifReminders = true;
  bool _notifMarketing = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await BarberApi.instance.get('/users/me/');
      setState(() {
        _profile = Map<String, dynamic>.from(res.data);
        _notifBooking = res.data['notification_booking'] as bool? ?? true;
        _notifReminders = res.data['notification_reminders'] as bool? ?? true;
        _notifMarketing = res.data['notification_marketing'] as bool? ?? false;
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _patchUser(Map<String, dynamic> data) async {
    try { await BarberApi.instance.patch('/users/me/', data: data); } catch (_) {}
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56, decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle), child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 26)),
            const SizedBox(height: 16),
            const Text('Chiqish', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Hisobdan chiqmoqchimisiz?\nQayta kirish uchun telefon va parol kerak bo\'ladi.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), side: const BorderSide(color: AppColors.border)),
                child: const Text('Bekor', style: TextStyle(color: AppColors.textSecondary)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 13)),
                child: const Text('Chiqish'),
              )),
            ]),
          ]),
        ),
      ),
    );
    if (ok == true && mounted) {
      try { await BarberApi.instance.post('/auth/logout/'); } catch (_) {}
      await clearTokens();
      if (mounted) context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (_profile['full_name'] ?? '${_profile['first_name'] ?? ''} ${_profile['last_name'] ?? ''}'.trim()).toString().trim();
    final phone = _profile['phone'] as String? ?? '';
    final salon = _profile['salon_name'] as String? ?? '';
    final avatar = _profile['avatar'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/')),
        title: const Text('Sozlamalar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Profile hero card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4E6EF5), Color(0xFF3451D1)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Row(children: [
                      ClipOval(
                        child: avatar != null
                            ? Image.network(avatar, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(name))
                            : _avatarFallback(name),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name.isEmpty ? 'Sartarosh' : name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                        if (salon.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(salon, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ])),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ]),
                  ).animate().fadeIn().slideY(begin: -0.05),

                  const SizedBox(height: 28),

                  // Quick actions
                  _label('TEZKOR HAVOLALAR'),
                  const SizedBox(height: 10),
                  _QuickRow(children: [
                    _QuickAction(icon: Icons.schedule_rounded, label: 'Jadval', onTap: () => context.go('/schedule')),
                    _QuickAction(icon: Icons.content_cut_rounded, label: 'Xizmatlar', onTap: () => context.go('/services')),
                    _QuickAction(icon: Icons.photo_library_rounded, label: 'Portfolio', onTap: () => context.go('/portfolio')),
                    _QuickAction(icon: Icons.bar_chart_rounded, label: 'Statistika', onTap: () => context.go('/analytics')),
                  ]).animate().fadeIn(delay: 60.ms),

                  const SizedBox(height: 24),

                  // Notifications
                  _label('BILDIRISHNOMALAR'),
                  const SizedBox(height: 10),
                  _card([
                    _toggle(
                      icon: Icons.calendar_today_rounded,
                      iconBg: AppColors.primaryLight,
                      iconColor: AppColors.primary,
                      title: 'Yangi bronlar',
                      subtitle: 'Yangi bron kelganda xabar',
                      value: _notifBooking,
                      onChanged: (v) { setState(() => _notifBooking = v); _patchUser({'notification_booking': v}); },
                    ),
                    _divider(),
                    _toggle(
                      icon: Icons.alarm_rounded,
                      iconBg: AppColors.successLight,
                      iconColor: AppColors.success,
                      title: 'Eslatmalar',
                      subtitle: 'Bron oldidan 30 daqiqa',
                      value: _notifReminders,
                      onChanged: (v) { setState(() => _notifReminders = v); _patchUser({'notification_reminders': v}); },
                    ),
                    _divider(),
                    _toggle(
                      icon: Icons.campaign_rounded,
                      iconBg: AppColors.warningLight,
                      iconColor: AppColors.warning,
                      title: 'Yangiliklar',
                      subtitle: 'Platforma yangiliklari va aksiyalar',
                      value: _notifMarketing,
                      onChanged: (v) { setState(() => _notifMarketing = v); _patchUser({'notification_marketing': v}); },
                    ),
                  ]).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 24),

                  // App
                  _label('ILOVA'),
                  const SizedBox(height: 10),
                  _card([
                    _row(icon: Icons.info_outline_rounded, iconBg: AppColors.primaryLight, iconColor: AppColors.primary, title: 'Ilova versiyasi', trailing: const Text('1.0.0', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)), onTap: () {}),
                    _divider(),
                    _row(icon: Icons.privacy_tip_outlined, iconBg: AppColors.primaryLight, iconColor: AppColors.primary, title: 'Maxfiylik siyosati', onTap: () {}),
                    _divider(),
                    _row(icon: Icons.description_outlined, iconBg: AppColors.primaryLight, iconColor: AppColors.primary, title: 'Foydalanish shartlari', onTap: () {}),
                    _divider(),
                    _row(icon: Icons.help_outline_rounded, iconBg: AppColors.successLight, iconColor: AppColors.success, title: 'Yordam', onTap: () {}),
                  ]).animate().fadeIn(delay: 130.ms),

                  const SizedBox(height: 28),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                      label: const Text('Hisobdan chiqish', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 160.ms),

                  const SizedBox(height: 12),
                  const Center(child: Text('Stiltime Barber © 2025', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))),
                ]),
              ),
            ),
    );
  }

  Widget _avatarFallback(String name) => Container(
    width: 64, height: 64, color: Colors.white.withOpacity(0.18),
    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800))),
  );

  Widget _label(String text) => Text(text, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1));

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
    child: Column(children: children),
  );

  Widget _divider() => const Divider(height: 0, thickness: 0.5, indent: 62, color: Color(0xFFF0EDE8));

  Widget _toggle({required IconData icon, required Color iconBg, required Color iconColor, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
        Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      ])),
      Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
    ]),
  );

  Widget _row({required IconData icon, required Color iconBg, required Color iconColor, required String title, Widget? trailing, required VoidCallback onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14))),
        trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textTertiary),
      ]),
    ),
  );
}

class _QuickRow extends StatelessWidget {
  final List<_QuickAction> children;
  const _QuickRow({required this.children});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: children,
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(
        width: 58, height: 58,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}
