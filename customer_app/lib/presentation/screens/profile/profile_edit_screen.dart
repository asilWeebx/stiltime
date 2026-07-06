import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _State();
}

class _State extends ConsumerState<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _gender;
  String? _dob;
  String? _avatarPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameCtrl.text = user.fullName;
      _emailCtrl.text = user.email ?? '';
      _gender = user.gender;
      _dob = user.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _avatarPath = img.path);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ism kiritilmagan'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _loading = true);
    try {
      Map<String, dynamic> data = {
        'full_name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        if (_gender != null) 'gender': _gender,
        if (_dob != null) 'date_of_birth': _dob,
      };

      if (_avatarPath != null) {
        final form = FormData.fromMap({
          ...data,
          'avatar': await MultipartFile.fromFile(_avatarPath!, filename: 'avatar.jpg'),
        });
        await ref.read(authProvider.notifier).updateProfile(form);
      } else {
        await ref.read(authProvider.notifier).updateProfile(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil yangilandi'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xatolik yuz berdi'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?.fullName ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        title: const Text('Profilni tahrirlash'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Text('Saqlash', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar picker
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.beige, border: Border.all(color: AppColors.primary, width: 2.5),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]),
                    child: ClipOval(
                      child: _avatarPath != null
                          ? Image.file(File(_avatarPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(name))
                          : (user?.avatar != null
                              ? Image.network(user!.avatar!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(name))
                              : _initials(name)),
                    ),
                  ),
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ).animate().scale(begin: const Offset(0.9, 0.9)),
          ),

          const SizedBox(height: 28),

          _label('TO\'LIQ ISM'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'Ism Familiya', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
          ),

          const SizedBox(height: 16),

          _label('ELEKTRON POCHTA'),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'email@example.com', prefixIcon: Icon(Icons.email_outlined, size: 20)),
          ),

          const SizedBox(height: 16),

          _label('JINSI'),
          const SizedBox(height: 8),
          Row(children: [
            _genderChip('Erkak', 'male'),
            const SizedBox(width: 10),
            _genderChip('Ayol', 'female'),
          ]),

          const SizedBox(height: 16),

          _label('TUG\'ILGAN SANA'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dob != null ? DateTime.tryParse(_dob!) ?? DateTime(1995) : DateTime(1995),
                firstDate: DateTime(1940),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 12)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _dob = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Text(_dob ?? 'Sanani tanlang', style: TextStyle(color: _dob != null ? AppColors.text : AppColors.textTertiary, fontSize: 15)),
              ]),
            ),
          ),

          const SizedBox(height: 32),

          // Phone (read-only)
          _label('TELEFON RAQAM (O\'ZGARTIRIB BO\'LMAYDI)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.warmGray, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.phone_android_rounded, color: AppColors.textTertiary, size: 18),
              const SizedBox(width: 10),
              Text(user?.phone ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              const Spacer(),
              const Icon(Icons.lock_outline_rounded, color: AppColors.textTertiary, size: 16),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _initials(String name) => Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 32)));

  Widget _label(String text) => Text(text, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1));

  Widget _genderChip(String label, String value) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
