import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFF0E1320),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _ProfileHeader(user: user, canPop: canPop)),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 6),
                _menuSection('Hisob', [
                  _MenuItem(Icons.person_outline_rounded, 'Profilni tahrirlash', () => context.push('/profile/edit')),
                  _MenuItem(Icons.receipt_long_outlined, 'Buyurtmalar tarixi', () => context.push('/bookings')),
                  _MenuItem(Icons.favorite_border_rounded, 'Sevimlilar', () => context.push('/favorites')),
                ]),
                _menuSection('Sozlamalar', [
                  _MenuItem(Icons.notifications_outlined, 'Bildirishnomalar', () => context.push('/settings')),
                  _MenuItem(Icons.tune_rounded, 'Sozlamalar', () => context.push('/settings')),
                  _MenuItem(Icons.language_rounded, 'Til', () => _showLanguageSheet(context, ref)),
                ]),
                _menuSection("Qo'llab-quvvatlash", [
                  _MenuItem(Icons.help_outline_rounded, 'Yordam', () {}),
                  _MenuItem(Icons.privacy_tip_outlined, 'Maxfiylik siyosati', () {}),
                  _MenuItem(Icons.info_outline_rounded, 'Ilova haqida', () => _showAbout(context)),
                ]),
                const SizedBox(height: 12),
                _LogoutButton(onTap: () => _logout(context, ref)),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.13), width: 0.5),
                ),
                child: Column(
                  children: items.asMap().entries.map((e) {
                    final item = e.value;
                    final isFirst = e.key == 0;
                    final isLast = e.key == items.length - 1;
                    return ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: isFirst ? const Radius.circular(20) : Radius.zero,
                        bottom: isLast ? const Radius.circular(20) : Radius.zero,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: item.onTap,
                          splashColor: Colors.white.withOpacity(0.08),
                          highlightColor: Colors.white.withOpacity(0.05),
                          child: Column(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(item.icon, color: Colors.white.withOpacity(0.9), size: 18),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                                ),
                                Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.35), size: 20),
                              ]),
                            ),
                            if (!isLast) Divider(height: 1, color: Colors.white.withOpacity(0.08), indent: 70),
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.04);
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Tilni tanlang', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...[("O'zbek", 'uz'), ('Русский', 'ru'), ('English', 'en')].map(
            (l) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(l.$2 == 'uz' ? '🇺🇿' : l.$2 == 'ru' ? '🇷🇺' : '🇬🇧', style: const TextStyle(fontSize: 18))),
              ),
              title: Text(l.$1, style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              onTap: () => Navigator.pop(context),
            ),
          ),
        ]),
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Temani tanlang', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...[("Qorong'i", Icons.dark_mode_rounded), ("Yorug'", Icons.light_mode_rounded), ('Tizim', Icons.settings_brightness_rounded)].map(
            (t) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: Icon(t.$2, color: AppColors.primary, size: 18),
              ),
              title: Text(t.$1, style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              onTap: () => Navigator.pop(context),
            ),
          ),
        ]),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'StilTime',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Chiqish', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('Hisobdan chiqmoqchimisiz?', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text("Yo'q", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Chiqish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/phone');
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final bool canPop;
  const _ProfileHeader({required this.user, required this.canPop});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Foydalanuvchi';
    final phone = user?.phone ?? '';
    final avatar = user?.avatar as String?;
    final points = user?.loyaltyPoints ?? 0;
    final referral = user?.referralCode as String?;
    final isVerified = user?.isVerified ?? false;

    return Stack(
      children: [
        // Background gradient with decorative blobs
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A4EBD), Color(0xFF5B2EB4)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(top: -30, right: -20, child: _Blob(size: 160, opacity: 0.08)),
              Positioned(top: 60, left: -40, child: _Blob(size: 120, opacity: 0.06)),
              Positioned(bottom: 30, right: 40, child: _Blob(size: 80, opacity: 0.07)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(children: [
                    // Top row: back button + settings
                    Row(children: [
                      if (canPop)
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
                          ),
                        )
                      else
                        const SizedBox(height: 40),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/profile/edit'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Avatar
                    GestureDetector(
                      onTap: () => context.push('/profile/edit'),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 96, height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4))],
                            ),
                            child: ClipOval(
                              child: avatar != null && avatar.isNotEmpty
                                  ? Image.network(
                                      avatar,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _InitialsAvatar(name: name, size: 96),
                                    )
                                  : _InitialsAvatar(name: name, size: 96),
                            ),
                          ),
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ).animate().scale(begin: const Offset(0.85, 0.85), duration: 400.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 14),

                    // Name + verified
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
                        ),
                      ],
                    ]).animate().fadeIn(delay: 80.ms),

                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 20),

                    // Loyalty card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0.08)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        // Bonus icon
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: const Icon(Icons.stars_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Bonus ballar', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Text(
                              '$points',
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            const SizedBox(width: 4),
                            Text('ball', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500)),
                          ]),
                        ])),
                        if (referral != null)
                          GestureDetector(
                            onTap: () => _showQRCode(context, referral),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withOpacity(0.25)),
                              ),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.qr_code_rounded, color: Colors.white, size: 16),
                                const SizedBox(height: 3),
                                Text('Referal', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                              ]),
                            ),
                          ),
                      ]),
                    ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.1),
                  ]),
                ),
              ),
            ],
          ),
        ),

        // Bottom curve — matches dark navy scaffold background
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF0E1320),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),
      ],
    );
  }

  void _showQRCode(BuildContext context, String code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Referal kod', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text("Do'stlaringizga ulashing va bonus ball oling", style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
            child: QrImageView(data: code, version: QrVersions.auto, size: 180),
          ),
          const SizedBox(height: 16),
          Text(code, style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4)),
        ]),
      ),
    );
  }
}

// ── Initials Avatar ───────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _InitialsAvatar({required this.name, required this.size});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF5B6EF5), Color(0xFF9B27B5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(color: Colors.white, fontSize: size * 0.3, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── Decorative blob ───────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final double opacity;
  const _Blob({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );
}

// ── Logout button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.logout_rounded, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Hisobdan chiqish', style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);
}
