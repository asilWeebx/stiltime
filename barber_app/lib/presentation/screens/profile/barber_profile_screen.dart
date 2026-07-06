import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api.dart';
import '../../../core/theme.dart';

final _profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final res = await BarberApi.instance.get('/barbers/me/');
    return Map<String, dynamic>.from(res.data);
  } catch (_) { return {}; }
});

class BarberProfileScreen extends ConsumerStatefulWidget {
  const BarberProfileScreen({super.key});
  @override
  ConsumerState<BarberProfileScreen> createState() => _State();
}

class _State extends ConsumerState<BarberProfileScreen> {
  final _bioCtrl  = TextEditingController();
  final _expCtrl  = TextEditingController();
  final _instaCtrl = TextEditingController();
  final _tgCtrl   = TextEditingController();
  bool _editing = false;
  bool _saving  = false;
  String _gender = 'male';

  @override
  void dispose() {
    _bioCtrl.dispose(); _expCtrl.dispose();
    _instaCtrl.dispose(); _tgCtrl.dispose();
    super.dispose();
  }

  void _populate(Map<String, dynamic> p) {
    if (_editing) return;
    _bioCtrl.text   = p['bio']  as String? ?? '';
    _expCtrl.text   = '${p['experience_years'] ?? ''}';
    _instaCtrl.text = p['instagram'] as String? ?? '';
    _tgCtrl.text    = p['telegram']  as String? ?? '';
    _gender = p['gender'] as String? ?? 'male';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await BarberApi.instance.patch('/barbers/me/', data: {
        'bio': _bioCtrl.text.trim(),
        'experience_years': int.tryParse(_expCtrl.text) ?? 0,
        'instagram': _instaCtrl.text.trim(),
        'telegram': _tgCtrl.text.trim(),
        'gender': _gender,
      });
      ref.invalidate(_profileProvider);
      if (mounted) setState(() { _editing = false; _saving = false; });
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    try {
      await BarberApi.instance.patch('/users/me/',
          data: FormData.fromMap({'avatar': await MultipartFile.fromFile(img.path, filename: 'avatar.jpg')}));
      ref.invalidate(_profileProvider);
    } catch (_) {}
  }

  Future<void> _pickCover() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    try {
      await BarberApi.instance.patch('/barbers/me/',
          data: FormData.fromMap({'cover_photo': await MultipartFile.fromFile(img.path, filename: 'cover.jpg')}));
      ref.invalidate(_profileProvider);
    } catch (_) {}
  }

  Future<void> _logout() async {
    await clearTokens();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(_profileProvider);
    return profile.when(
      data: _buildContent,
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (_, __) => Scaffold(body: Center(child: TextButton(
        onPressed: () => ref.invalidate(_profileProvider),
        child: const Text('Qayta urinish'),
      ))),
    );
  }

  Widget _buildContent(Map<String, dynamic> p) {
    _populate(p);
    final name    = (p['full_name'] as String?)?.trim()
        ?? (p['user'] is Map ? (p['user']['full_name'] as String?)?.trim() : null) ?? '';
    final avatar  = p['avatar']      as String?;
    final cover   = p['cover_photo'] as String?;
    final rating  = (p['rating'] as num?)?.toStringAsFixed(1) ?? '—';
    final bookings = p['total_bookings'] as int? ?? 0;
    final salon   = p['salon_name']  as String? ?? '—';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: _floatBtn(Icons.arrow_back_ios_new, size: 16),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                if (_editing) {
                  _save();
                } else {
                  setState(() => _editing = true);
                }
              },
              child: _saving
                  ? Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                      child: const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    )
                  : _floatBtn(_editing ? Icons.check_rounded : Icons.edit_rounded, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cover + avatar ─────────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover
                GestureDetector(
                  onTap: _editing ? _pickCover : null,
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        cover != null
                            ? Image.network(cover, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _gradientBox())
                            : _gradientBox(),
                        CustomPaint(painter: _DotPainter()),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.45, 1.0],
                            ),
                          ),
                        ),
                        if (_editing)
                          Container(
                            color: Colors.black.withOpacity(0.45),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 40),
                                Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 28),
                                SizedBox(height: 6),
                                Text("Muqovani o'zgartirish",
                                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Avatar — overlaps 44px into white area below
                Positioned(
                  bottom: -44,
                  left: 20,
                  child: GestureDetector(
                    onTap: _editing ? _pickAvatar : null,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: avatar != null
                              ? Image.network(avatar, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _avatarFallback(name))
                              : _avatarFallback(name),
                        ),
                      ),
                      if (_editing)
                        Positioned.fill(
                          child: ClipOval(
                            child: Container(
                              color: Colors.black45,
                              child: const Icon(Icons.camera_alt_outlined,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ],
            ),

            // ── White content ──────────────────────────────────────────────
            Container(
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row — starts right after cover (avatar straddles above)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 90 + 14), // space beside avatar
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? 'Sartarosh' : name,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.storefront_outlined,
                                    size: 12, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(salon,
                                    style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Gap to clear the avatar bottom (44px overflow − name row height ~50px + 16 margin)
                  const SizedBox(height: 48),

                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(children: [
                          _stat(Icons.star_rounded, const Color(0xFFDDA74A), rating, 'Reyting'),
                          VerticalDivider(color: AppColors.border, width: 1, thickness: 1),
                          _stat(Icons.calendar_today_rounded, AppColors.primary, '$bookings', 'Bronlar'),
                          VerticalDivider(color: AppColors.border, width: 1, thickness: 1),
                          _stat(Icons.chat_bubble_outline_rounded, const Color(0xFF2AA771),
                              "Ko'rish", 'Sharhlar',
                              onTap: () => context.push('/reviews'), isLink: true),
                        ]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // BIO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _card(label: 'BIO', children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: _editing
                            ? TextField(
                                controller: _bioCtrl,
                                maxLines: 4,
                                style: const TextStyle(color: AppColors.text, fontSize: 15, height: 1.5),
                                decoration: const InputDecoration(hintText: "O'zingiz haqingizda..."),
                              )
                            : Text(
                                _bioCtrl.text.isEmpty ? "Bio qo'shilmagan..." : _bioCtrl.text,
                                style: TextStyle(
                                  color: _bioCtrl.text.isEmpty
                                      ? AppColors.textTertiary
                                      : AppColors.textSecondary,
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                              ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 10),

                  // Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _card(label: 'TAJRIBA VA IJTIMOIY', children: _editing
                        ? [
                            Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                              _field('Tajriba (yil)', _expCtrl, Icons.workspace_premium_outlined, isNum: true),
                              const SizedBox(height: 10),
                              _field('Instagram', _instaCtrl, Icons.camera_alt_outlined, prefix: '@'),
                              const SizedBox(height: 10),
                              _field('Telegram', _tgCtrl, Icons.telegram, prefix: '@'),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Kimlar uchun ishlaysiz?',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(height: 8),
                              Row(children: [
                                _genderBtn('male', 'Erkaklar', Icons.male_rounded),
                                const SizedBox(width: 10),
                                _genderBtn('female', 'Ayollar', Icons.female_rounded),
                              ]),
                            ])),
                          ]
                        : [
                            _row(Icons.workspace_premium_outlined, const Color(0xFF7C3AED), const Color(0xFFF5F3FF),
                                'Tajriba', _expCtrl.text.isEmpty ? '—' : '${_expCtrl.text} yil'),
                            const Divider(indent: 66, height: 1, color: Color(0xFFF0EDE8)),
                            _row(_gender == 'female' ? Icons.female_rounded : Icons.male_rounded,
                                AppColors.primary, AppColors.primaryLight,
                                'Mijozlar', _gender == 'female' ? 'Ayollar' : 'Erkaklar'),
                            const Divider(indent: 66, height: 1, color: Color(0xFFF0EDE8)),
                            _row(Icons.camera_alt_outlined, const Color(0xFFE4405F), const Color(0xFFFCE4EC),
                                'Instagram',
                                _instaCtrl.text.isEmpty ? '—' : '@${_instaCtrl.text.replaceAll("@", "")}'),
                            const Divider(indent: 66, height: 1, color: Color(0xFFF0EDE8)),
                            _row(Icons.telegram, const Color(0xFF0088CC), const Color(0xFFE1F5FE),
                                'Telegram',
                                _tgCtrl.text.isEmpty ? '—' : '@${_tgCtrl.text.replaceAll("@", "")}'),
                          ]),
                  ),

                  const SizedBox(height: 10),

                  // Logout
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _logout,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                              ),
                              const SizedBox(width: 14),
                              const Text('Chiqish', style: TextStyle(color: AppColors.error, fontSize: 15, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _floatBtn(IconData icon, {double size = 18}) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
    child: Icon(icon, color: Colors.white, size: size),
  );

  Widget _gradientBox() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1A1A2E), Color(0xFF2D3561)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
  );

  Widget _avatarFallback(String name) => Container(
    color: AppColors.beige,
    child: Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'B',
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 32, fontWeight: FontWeight.w800),
    )),
  );

  Widget _stat(IconData icon, Color color, String value, String label,
      {VoidCallback? onTap, bool isLink = false}) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(
                color: isLink ? AppColors.primary : AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.3,
              )),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
            ]),
          ),
        ),
      );

  Widget _card({String? label, required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(label, style: const TextStyle(
              color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
      ...children,
    ]),
  );

  Widget _row(IconData icon, Color ic, Color bg, String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: ic, size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.text, fontSize: 15))),
      Text(val, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
    ]),
  );

  Widget _field(String hint, TextEditingController ctrl, IconData icon,
      {bool isNum = false, String? prefix}) =>
      TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          prefixText: prefix,
          prefixStyle: const TextStyle(color: AppColors.textHint),
          hintText: hint,
        ),
      );

  Widget _genderBtn(String value, String label, IconData icon) {
    final sel = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            color: sel ? AppColors.primary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 2 : 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: sel ? AppColors.primary : AppColors.textSecondary, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: sel ? AppColors.primary : AppColors.text,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.fill;
    const s = 22.0;
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1.4, p);
      }
    }
  }
  @override bool shouldRepaint(_DotPainter _) => false;
}
