import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api.dart';
import '../../../core/app_alert.dart';
import '../../../core/theme.dart';

// ── Pending approval screen ──────────────────────────────────────────────────

class BarberPendingScreen extends StatelessWidget {
  const BarberPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFDDA74A), size: 52),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 36),
              const Text(
                'Tasdiqlanish\nkutilmoqda',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.2, color: AppColors.text),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),
              const Text(
                'Sizning profilingiz administrator tomonidan ko\'rib chiqilmoqda. Tasdiqlangandan so\'ng ilova to\'liq ochiladi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 52),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text('Bosh sahifaga', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await clearTokens();
                  if (context.mounted) context.go('/auth');
                },
                child: const Text('Chiqish', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── UZB regions & districts ──────────────────────────────────────────────────

const Map<String, List<String>> _uzb = {
  'Toshkent shahar': [
    'Bektemir', 'Chilonzor', "Mirzo Ulug'bek", 'Mirobod', 'Olmazor',
    'Shayxontohur', 'Uchtepa', 'Yakkasaroy', 'Yunusobod',
  ],
  'Toshkent viloyati': [
    'Angren', 'Bekobod', "Bo'ka", "Bo'stonliq", 'Chinoz', "Oqqo'rg'on",
    'Ohangaron', 'Parkent', 'Piskent', 'Quyichirchiq', 'Toshkent tumani',
    'Urtachirchiq', 'Yangiyul', 'Zangiota',
  ],
  'Andijon': [
    'Andijon shahar', 'Asaka', 'Baliqchi', "Bo'z", 'Buloqboshi', 'Jalaquduq',
    'Izboskan', 'Marhamat', "Oltinko'l", 'Paxtaobod', "Qo'rg'ontepa",
    'Shahrixon', "Ulug'nor", "Xo'jaobod",
  ],
  "Farg'ona": [
    "Farg'ona shahar", "Bag'dod", 'Beshariq', 'Buvayda', "Dang'ara", 'Furqat',
    "Qo'shtepa", 'Quva', 'Rishton', "So'x", 'Toshloq', "Uchko'prik",
    "O'zbekiston", 'Yozyovon',
  ],
  'Namangan': [
    'Namangan shahar', 'Chortoq', 'Chust', 'Kosonsoy', 'Mingbuloq', 'Norin',
    'Pop', "To'raqo'rg'on", 'Uychi', "Ulug'nor", "Yangiqo'rg'on",
  ],
  'Samarqand': [
    'Samarqand shahar', "Bulung'ur", 'Ishtixon', 'Jomboy', "Kattaqo'rg'on",
    'Narpay', 'Nurobod', 'Oqdaryo', "Pastdarg'om", 'Payariq',
    "Qo'shrabot", 'Toyloq', 'Urgut',
  ],
  'Buxoro': [
    'Buxoro shahar', "G'ijduvon", 'Jondor', 'Kogon', 'Olot', 'Peshku',
    'Qorovulbozor', 'Romitan', 'Shofirkon', 'Vobkent',
  ],
  'Xorazm': [
    'Urganch shahar', "Bog'ot", 'Gurlan', 'Xiva', 'Xonqa', 'Hazorasp',
    "Qo'shko'pir", 'Shovot', "Tuproqqal'a", 'Yangiariq', 'Yangibozor',
  ],
  'Qashqadaryo': [
    'Qarshi shahar', 'Chiroqchi', 'Dehqonobod', "G'uzor", 'Kasbi', 'Kitob',
    'Koson', 'Mirishkor', 'Muborak', 'Nishon', 'Qamashi', 'Shahrisabz', "Yakkabog'",
  ],
  'Surxondaryo': [
    'Termiz shahar', 'Angor', 'Bandixon', 'Boysun', 'Denov', "Jarqo'rg'on",
    'Muzrabot', 'Oltinsoy', 'Qiziriq', "Qumqo'rg'on", 'Sariosiyo',
    'Sherobod', "Sho'rchi", 'Uzun',
  ],
  'Sirdaryo': [
    'Guliston shahar', 'Boyovut', 'Hovos', 'Mirzaobod', 'Oqoltin',
    'Sardoba', 'Sayxunobod', 'Sirdaryo', 'Xavast',
  ],
  'Jizzax': [
    'Jizzax shahar', 'Arnasoy', 'Baxmal', "Do'stlik", 'Forish', "G'allaorol",
    "Mirzacho'l", 'Paxtakor', 'Sharof Rashidov', 'Yangiobod', 'Zarbdor',
    'Zafarobod', 'Zomin',
  ],
  'Navoiy': [
    'Navoiy shahar', 'Karmana', 'Konimex', 'Navbahor', 'Nurota',
    'Qiziltepa', 'Tomdi', 'Uchquduq', 'Xatirchi',
  ],
  "Qoraqalpog'iston": [
    'Nukus shahar', 'Amudaryo', 'Beruniy', "Bo'zatov", 'Chimboy', "Ellikqal'a",
    'Kegeyli', "Mo'ynoq", "Qanliko'l", "Qo'ng'irot", "Qorao'zak",
    'Shumanay', "Taxtako'pir", "To'rtko'l", "Xo'jayli",
  ],
};

// ── Salon model ──────────────────────────────────────────────────────────────

class _Salon {
  final int id;
  final String name;
  final String? address;
  _Salon({required this.id, required this.name, this.address});
  factory _Salon.fromJson(Map<String, dynamic> j) =>
      _Salon(id: j['id'], name: j['name'] ?? '', address: j['address']);
}

// ── Welcome Screen ───────────────────────────────────────────────────────────

class BarberWelcomeScreen extends StatelessWidget {
  const BarberWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.content_cut, color: Colors.white, size: 36),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),
              const Text(
                'StilTime\nSartarosh',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: AppColors.text,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.15),

              const SizedBox(height: 10),
              const Text(
                'Ish jadvalingizni boshqaring',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ).animate().fadeIn(delay: 150.ms),

              const Spacer(flex: 3),

              // Kirish button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Kirish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: 12),

              // Zayavka berish button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => context.push('/register'),
                  child: const Text(
                    'Zayavka berish',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),

              const SizedBox(height: 28),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Akkauntingiz bormi? ',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => context.push('/login'),
                          child: const Text(
                            'Kirish',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Login Screen ─────────────────────────────────────────────────────────────

class BarberLoginScreen extends StatefulWidget {
  const BarberLoginScreen({super.key});

  @override
  State<BarberLoginScreen> createState() => _BarberLoginScreenState();
}

class _BarberLoginScreenState extends State<BarberLoginScreen> {
  final _phoneCtrl = TextEditingController(text: '+998');
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (phone.length < 13) {
      _snack('Telefon raqamni to\'liq kiriting');
      return;
    }
    if (pass.length < 6) {
      _snack('Parol kamida 6 ta belgidan iborat bo\'lishi kerak');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await BarberApi.instance.post('/auth/login/', data: {
        'phone': phone,
        'password': pass,
      });
      final data = res.data;
      final userStatus = data['user']?['status'] as String?;
      if (userStatus == 'pending') {
        if (mounted) context.go('/pending');
        return;
      }
      if (userStatus == 'rejected') {
        _snack('Arizangiz rad etildi. Qo\'shimcha ma\'lumot uchun murojaat qiling');
        return;
      }
      final tokens = data['tokens'] ?? data;
      await setTokens(
        tokens['access'] as String,
        tokens['refresh'] as String,
      );
      if (mounted) context.go('/');
    } catch (e) {
      _snack(_parseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final serverMsg = e.response?.data?['error'] as String?;
      if (serverMsg != null) return serverMsg;
      if (e.response?.statusCode == 401) return "Telefon raqam yoki parol noto'g'ri";
    }
    final msg = e.toString();
    if (msg.contains('connection')) return 'Internet aloqasini tekshiring';
    return 'Xatolik yuz berdi';
  }

  void _snack(String msg, {AlertType type = AlertType.error}) =>
      showAppAlert(context, msg, type: type);

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              const Text(
                'Kirish',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text),
              ),
              const SizedBox(height: 6),
              const Text(
                'Telefon raqam va parolingizni kiriting',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),

              const SizedBox(height: 36),

              // Phone
              _label('Telefon raqam'),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_android, color: AppColors.primary),
                  hintText: '+998901234567',
                ),
              ),

              const SizedBox(height: 20),

              // Password
              _label('Parol'),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(fontSize: 16, color: AppColors.text),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                  hintText: '••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Kirish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Akkauntingiz yo\'qmi? ',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => context.pushReplacement('/register'),
                          child: const Text(
                            'Zayavka berish',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
      );
}

// ── Register Screen (4-step) ─────────────────────────────────────────────────

class BarberRegisterScreen extends StatefulWidget {
  const BarberRegisterScreen({super.key});

  @override
  State<BarberRegisterScreen> createState() => _BarberRegisterScreenState();
}

class _BarberRegisterScreenState extends State<BarberRegisterScreen> {
  int _step = 0;
  bool _loading = false;

  // Step 1 fields
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+998');
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  String _gender = 'male';

  // Step 2 fields
  String? _region;
  String? _district;

  // Step 3 fields
  List<_Salon> _salons = [];
  int? _selectedSalonId;
  String _salonSearch = '';
  final _searchCtrl = TextEditingController();
  bool _unknownSalon = false;
  final _unknownSalonNameCtrl = TextEditingController();
  final _unknownSalonAddressCtrl = TextEditingController();

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    _searchCtrl.dispose();
    _unknownSalonNameCtrl.dispose();
    _unknownSalonAddressCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {AlertType type = AlertType.error}) =>
      showAppAlert(context, msg, type: type);

  bool _validateStep1() {
    if (_firstCtrl.text.trim().isEmpty) { _snack('Ismingizni kiriting'); return false; }
    if (_lastCtrl.text.trim().isEmpty) { _snack('Familiyangizni kiriting'); return false; }
    if (_phoneCtrl.text.trim().length < 13) { _snack('Telefon raqamni to\'liq kiriting'); return false; }
    if (_passCtrl.text.trim().length < 6) { _snack('Parol kamida 6 ta belgidan iborat bo\'lishi kerak'); return false; }
    if (_passCtrl.text != _pass2Ctrl.text) { _snack('Parollar mos emas'); return false; }
    return true;
  }

  bool _validateStep2() {
    if (_region == null) { _snack('Viloyatni tanlang'); return false; }
    if (_district == null) { _snack('Tumanni tanlang'); return false; }
    return true;
  }

  bool _validateStep3() {
    if (!_unknownSalon && _selectedSalonId == null) { _snack('Barbershopni tanlang yoki "Bu yerda yo\'q" tugmasini bosing'); return false; }
    if (_unknownSalon && _unknownSalonNameCtrl.text.trim().isEmpty) { _snack('Barbershop nomini kiriting'); return false; }
    return true;
  }

  Future<void> _loadSalons() async {
    setState(() => _loading = true);
    try {
      final res = await BarberApi.instance.get('/salons/');
      final raw = res.data;
      final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : raw;
      _salons = (list as List).map((e) => _Salon.fromJson(e)).toList();
    } catch (_) {
      _salons = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final payload = <String, dynamic>{
        'first_name': _firstCtrl.text.trim(),
        'last_name': _lastCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'password': _passCtrl.text.trim(),
        'gender': _gender,
        'region': _region,
        'district': _district,
      };
      if (_unknownSalon) {
        payload['salon_name_suggestion'] = _unknownSalonNameCtrl.text.trim();
        payload['salon_address_suggestion'] = _unknownSalonAddressCtrl.text.trim();
      } else {
        payload['salon'] = _selectedSalonId;
      }
      await BarberApi.instance.post('/barbers/apply/', data: payload);
      if (mounted) setState(() { _step = 3; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (e is DioException) {
        final serverMsg = e.response?.data?['error'] as String?;
        _snack(serverMsg ?? "Xatolik yuz berdi. Qaytadan urinib ko'ring");
      } else {
        _snack("Xatolik yuz berdi. Qaytadan urinib ko'ring");
      }
    }
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (!_validateStep1()) return;
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (!_validateStep2()) return;
      await _loadSalons();
      setState(() => _step = 2);
    } else if (_step == 2) {
      if (!_validateStep3()) return;
      await _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _step < 3
          ? AppBar(
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () {
                  if (_step == 0) {
                    context.pop();
                  } else {
                    setState(() => _step--);
                  }
                },
              ),
              title: Text(
                ['Shaxsiy ma\'lumotlar', 'Joylashuv', 'Barbershop', ''][_step],
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (_step < 3) _StepIndicator(current: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: 280.ms,
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _step1();
      case 1:
        return _step2();
      case 2:
        return _step3();
      case 3:
        return _step4();
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Personal info ────────────────────────────────────────────────

  Widget _step1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Ism'),
          const SizedBox(height: 8),
          TextField(
            controller: _firstCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
              hintText: 'Ismingiz',
            ),
          ),
          const SizedBox(height: 16),

          _label('Familiya'),
          const SizedBox(height: 8),
          TextField(
            controller: _lastCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
              hintText: 'Familiyangiz',
            ),
          ),
          const SizedBox(height: 16),

          _label('Telefon raqam'),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_android, color: AppColors.primary),
              hintText: '+998901234567',
            ),
          ),
          const SizedBox(height: 16),

          _label('Parol'),
          const SizedBox(height: 8),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure1,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
              hintText: 'Kamida 6 ta belgi',
              suffixIcon: IconButton(
                icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _label('Parolni tasdiqlang'),
          const SizedBox(height: 8),
          TextField(
            controller: _pass2Ctrl,
            obscureText: _obscure2,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
              hintText: 'Parolni qaytaring',
              suffixIcon: IconButton(
                icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _label('Kimlar uchun ishlaysiz?'),
          const SizedBox(height: 8),
          Row(children: [
            _genderBtn('male', 'Erkaklar', Icons.male_rounded),
            const SizedBox(width: 12),
            _genderBtn('female', 'Ayollar', Icons.female_rounded),
          ]),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _next,
              child: const Text('Keyingisi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Region / District ────────────────────────────────────────────

  Widget _step2() {
    final districts = _region != null ? (_uzb[_region!] ?? <String>[]) : <String>[];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Viloyat'),
          const SizedBox(height: 8),
          _dropdown<String>(
            value: _region,
            hint: 'Viloyatni tanlang',
            items: _uzb.keys.toList(),
            labelFor: (v) => v,
            onChanged: (v) => setState(() { _region = v; _district = null; }),
          ),
          const SizedBox(height: 20),

          _label('Tuman / Shahar'),
          const SizedBox(height: 8),
          _dropdown<String>(
            value: _district,
            hint: _region == null ? 'Avval viloyatni tanlang' : 'Tumanni tanlang',
            items: districts,
            labelFor: (v) => v,
            onChanged: _region != null ? (v) => setState(() => _district = v) : null,
          ),
          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _next,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Keyingisi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Barbershop selection ─────────────────────────────────────────

  Widget _step3() {
    final filtered = _salons.where((s) {
      if (_salonSearch.isEmpty) return true;
      return s.name.toLowerCase().contains(_salonSearch.toLowerCase()) ||
          (s.address?.toLowerCase().contains(_salonSearch.toLowerCase()) ?? false);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.text),
            onChanged: (v) => setState(() => _salonSearch = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              hintText: 'Barbershopni qidiring...',
              suffixIcon: _salonSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _salonSearch = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_mall_directory_outlined, size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          const Text('Barbershop topilmadi', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        final selected = _selectedSalonId == s.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedSalonId = s.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: selected ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.content_cut, color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
                                      if (s.address != null)
                                        Text(s.address!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(Icons.check_circle, color: AppColors.primary)
                                else
                                  const Icon(Icons.radio_button_unchecked, color: AppColors.textHint),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        // "Bu yerda yo'q" toggle
        if (!_unknownSalon)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: OutlinedButton.icon(
              onPressed: () => setState(() { _unknownSalon = true; _selectedSalonId = null; }),
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text("Bu yerda yo'q — yangi barbershop taklif qilish"),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        if (_unknownSalon)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.add_business_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Yangi barbershop taklif qilish', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 14))),
                    GestureDetector(
                      onTap: () => setState(() { _unknownSalon = false; _unknownSalonNameCtrl.clear(); _unknownSalonAddressCtrl.clear(); }),
                      child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _unknownSalonNameCtrl,
                    style: const TextStyle(color: AppColors.text),
                    decoration: const InputDecoration(hintText: 'Barbershop nomi *', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _unknownSalonAddressCtrl,
                    style: const TextStyle(color: AppColors.text),
                    decoration: const InputDecoration(hintText: 'Manzil (ixtiyoriy)', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Administrator ushbu barbershopni tekshirib, platformaga qo\'shadi.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _next,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Zayavka yuborish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 4: Pending approval ─────────────────────────────────────────────

  Widget _step4() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 56),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: 32),
          const Text(
            'Zayavka yuborildi!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 16),
          Text(
            'Hurmatli ${_firstCtrl.text.trim()}, ma\'lumotlaringiz ko\'rib chiqilmoqda.\n\n'
            'Administrator tekshirgandan so\'ng, telefon raqamingiz va parolingiz bilan kirishingiz mumkin bo\'ladi.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.go('/auth'),
              child: const Text('Bosh sahifaga qaytish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
      );

  Widget _genderBtn(String value, String label, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 52,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.text, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) labelFor,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      style: const TextStyle(color: AppColors.text, fontSize: 15),
      dropdownColor: Colors.white,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
      items: items
          .map((v) => DropdownMenuItem<T>(value: v, child: Text(labelFor(v))))
          .toList(),
    );
  }
}

// ── Step indicator widget ────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    const labels = ['Ma\'lumotlar', 'Joylashuv', 'Barbershop'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        children: List.generate(3, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: 300.ms,
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: done || active ? AppColors.primary : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: active ? Border.all(color: AppColors.primary, width: 2) : null,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: active ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: done ? AppColors.primary : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
