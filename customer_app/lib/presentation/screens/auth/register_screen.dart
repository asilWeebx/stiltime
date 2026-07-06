import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String _gender = 'male';
  DateTime? _dob;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  String _apiDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).updateProfile({
        'full_name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'gender': _gender,
        if (_dob != null) 'date_of_birth': _apiDate(_dob!),
      });
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xato: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
                      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 20),
                      const Text(
                        'Profilni to\'ldiring',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Xizmatdan to\'liq foydalanish uchun\nma\'lumotlaringizni kiriting',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 36),

                // First name
                _label('Ism *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _firstNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ismingizni kiriting' : null,
                  decoration: _inputDecoration('Ismingiz', Icons.person_outline_rounded),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Last name
                _label('Familiya *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _lastNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Familiyangizni kiriting' : null,
                  decoration: _inputDecoration('Familiyangiz', Icons.person_outline_rounded),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Date of birth
                _label('Tug\'ilgan sana'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cake_outlined, color: _dob != null ? AppColors.primary : AppColors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _dob != null ? _formatDate(_dob!) : 'Tanlang (ixtiyoriy)',
                          style: TextStyle(
                            color: _dob != null ? AppColors.text : AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Gender
                _label('Jins'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _genderTile('male', 'Erkak', Icons.male_rounded),
                    const SizedBox(width: 12),
                    _genderTile('female', 'Ayol', Icons.female_rounded),
                  ],
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                const SizedBox(height: 36),

                // Save
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Davom etish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 2)),
  );

  Widget _genderTile(String value, String label, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }
}
