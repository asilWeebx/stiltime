import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _verified = false;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      return _resendSeconds > 0;
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otp.length == 6) _verify();
  }

  Future<void> _verify() async {
    if (_loading || _verified || _otp.length < 6) return;
    setState(() => _loading = true);
    try {
      final isNew = await ref.read(authProvider.notifier).verifyOTP(widget.phone, _otp);
      _verified = true;
      if (mounted) context.go(isNew ? '/register' : '/home');
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('400') || e.toString().contains('noto')
            ? 'Noto\'g\'ri kod'
            : 'Xatolik yuz berdi. Qayta urinib ko\'ring.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
        for (var c in _controllers) c.clear();
        _focusNodes[0].requestFocus();
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

              const SizedBox(height: 32),
              Text('Tasdiqlash', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                '${widget.phone} ga yuborilgan kodni kiriting',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),

              const SizedBox(height: 40),
              // OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (v) => _onDigitEntered(i, v),
                    onBackspace: i > 0 ? () {
                      if (_controllers[i].text.isEmpty) {
                        _focusNodes[i - 1].requestFocus();
                        _controllers[i - 1].clear();
                      }
                    } : null,
                  ),
                )).animate(interval: 60.ms).slideX(begin: 0.3).fadeIn(),
              ),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Tasdiqlash', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ).animate().slideY(begin: 0.3).fadeIn(delay: 300.ms),

              const SizedBox(height: 24),
              if (_resendSeconds > 0)
                Text(
                  'Qayta yuborish: $_resendSeconds s',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                TextButton(
                  onPressed: () {
                    setState(() => _resendSeconds = 60);
                    _startCountdown();
                    ref.read(authProvider.notifier).sendOTP(widget.phone);
                  },
                  child: Text('Kodni qayta yuborish', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onBackspace;

  const _OtpBox({required this.controller, required this.focusNode, required this.onChanged, this.onBackspace});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
            if (controller.text.isEmpty) onBackspace?.call();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            filled: true,
            fillColor: focusNode.hasFocus ? AppColors.primary.withOpacity(0.08) : AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: focusNode.hasFocus ? AppColors.primary : AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
