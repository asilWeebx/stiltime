import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api.dart';
import '../../../core/theme.dart';

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _State();
}

class _State extends State<CrmScreen> {
  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _q = '';
  String _filter = 'all'; // all | vip | new

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _q = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await BarberApi.instance.get('/barbers/me/customers/');
      final raw = res.data;
      final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : (raw as List? ?? []);
      setState(() { _customers = List<Map<String, dynamic>>.from(list); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _customers;
    if (_q.isNotEmpty) {
      list = list.where((c) =>
        (c['full_name'] ?? '').toString().toLowerCase().contains(_q) ||
        (c['phone'] ?? '').toString().contains(_q)
      ).toList();
    }
    switch (_filter) {
      case 'vip': return list.where((c) => c['is_vip'] == true || (c['total_bookings'] as int? ?? 0) >= 10).toList();
      case 'new': return list.where((c) => (c['total_bookings'] as int? ?? 0) <= 2).toList();
      default: return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/')),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mijozlar'),
          Text('${_customers.length} ta', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textTertiary)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(children: [
              // Search
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Ism yoki telefon raqami...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                  suffixIcon: _q.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textTertiary), onPressed: () { _searchCtrl.clear(); setState(() => _q = ''); })
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              // Filter chips
              Row(children: [
                _chip('Hammasi', 'all'),
                const SizedBox(width: 8),
                _chip('VIP', 'vip'),
                const SizedBox(width: 8),
                _chip('Yangi', 'new'),
              ]),
            ]),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _filtered.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.people_outline_rounded, size: 56, color: AppColors.border),
                      const SizedBox(height: 12),
                      Text(_q.isEmpty ? 'Mijozlar yo\'q' : 'Natija topilmadi', style: const TextStyle(color: AppColors.textTertiary, fontSize: 15)),
                    ]))
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _CustomerCard(
                        customer: _filtered[i],
                        onTap: () => _showDetail(_filtered[i]),
                      ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05),
                    ),
            ),
    );
  }

  Widget _chip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: active ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : AppColors.cardShadow,
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerDetail(customer: c, onNotesSaved: _load),
    );
  }
}

// ── Customer card ─────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onTap;
  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = customer['full_name']?.toString() ?? 'Noma\'lum';
    final phone = customer['phone']?.toString() ?? '';
    final bookings = (customer['total_bookings'] as num?)?.toInt() ?? 0;
    final spent = (customer['total_spent'] as num? ?? 0).toInt();
    final isVip = customer['is_vip'] == true || bookings >= 10;
    final lastVisit = customer['last_visit']?.toString() ?? '';
    final avatar = customer['avatar']?.toString();
    final hasNote = (customer['notes']?.toString() ?? '').isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.cardShadow,
          border: isVip ? Border.all(color: AppColors.warning.withOpacity(0.3), width: 1.5) : null,
        ),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            ClipOval(
              child: avatar != null
                  ? Image.network(avatar, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(name, isVip))
                  : _initials(name, isVip),
            ),
            if (isVip) Positioned(
              bottom: -2, right: -2,
              child: Container(
                width: 18, height: 18,
                decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded, size: 11, color: Colors.white),
              ),
            ),
            if (hasNote) Positioned(
              top: -2, right: -2,
              child: Container(
                width: 14, height: 14,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.edit_note_rounded, size: 9, color: Colors.white),
              ),
            ),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 14), overflow: TextOverflow.ellipsis)),
              if (isVip) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(5)),
                  child: const Text('VIP', style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            if (phone.isNotEmpty) Text(phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            if (lastVisit.isNotEmpty) Text('So\'nggi: $lastVisit', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$bookings', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 18)),
            const Text('bron', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
            const SizedBox(height: 4),
            Text(_fmtSpent(spent), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }

  Widget _initials(String name, bool isVip) => Container(
    width: 50, height: 50,
    color: isVip ? AppColors.warningLight : AppColors.primaryLight,
    child: Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(color: isVip ? AppColors.warning : AppColors.primary, fontWeight: FontWeight.w800, fontSize: 18),
    )),
  );

  String _fmtSpent(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v so\'m';
  }
}

// ── Customer detail bottom sheet ──────────────────────────────────────────────

class _CustomerDetail extends StatefulWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onNotesSaved;
  const _CustomerDetail({required this.customer, required this.onNotesSaved});

  @override
  State<_CustomerDetail> createState() => _CustomerDetailState();
}

class _CustomerDetailState extends State<_CustomerDetail> {
  late TextEditingController _noteCtrl;
  bool _editingNote = false;
  bool _savingNote = false;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.customer['notes']?.toString() ?? '');
  }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  Future<void> _saveNote() async {
    setState(() => _savingNote = true);
    final customerId = widget.customer['id'];
    try {
      await BarberApi.instance.patch('/barbers/me/customers/$customerId/', data: {'notes': _noteCtrl.text.trim()});
      widget.onNotesSaved();
      setState(() { _editingNote = false; _savingNote = false; });
    } catch (_) { setState(() => _savingNote = false); }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final name = c['full_name']?.toString() ?? 'Noma\'lum';
    final phone = c['phone']?.toString() ?? '';
    final bookings = (c['total_bookings'] as num?)?.toInt() ?? 0;
    final spent = (c['total_spent'] as num? ?? 0).toInt();
    final avgSpent = bookings > 0 ? spent ~/ bookings : 0;
    final isVip = c['is_vip'] == true || bookings >= 10;
    final history = (c['booking_history'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final favServices = (c['favorite_services'] as List?)?.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() ?? [];
    final avatar = c['avatar']?.toString();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        // Handle
        Container(width: 44, height: 4, margin: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipOval(
                child: avatar != null
                    ? Image.network(avatar, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(name, isVip))
                    : _avatarFallback(name, isVip),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(name, style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800))),
                  if (isVip) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(8)),
                      child: const Text('⭐ VIP', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ])),
              IconButton(
                icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.call_rounded, color: AppColors.success, size: 20)),
                onPressed: () {},
              ),
            ]),

            const SizedBox(height: 20),

            // Stats
            Row(children: [
              _statPill('$bookings', 'Bron', AppColors.primary, AppColors.primaryLight),
              const SizedBox(width: 10),
              _statPill(_fmtMoney(spent), 'Jami', AppColors.success, AppColors.successLight),
              const SizedBox(width: 10),
              _statPill(_fmtMoney(avgSpent), "O'rtacha", AppColors.warning, AppColors.warningLight),
            ]),

            // Favorite services
            if (favServices.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionLabel('Sevimli xizmatlar'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: favServices.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: Text(s, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              )).toList()),
            ],

            // Notes
            const SizedBox(height: 20),
            Row(children: [
              _sectionLabel('Shaxsiy eslatma'),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _editingNote = !_editingNote),
                child: Text(_editingNote ? 'Bekor qilish' : 'Tahrirlash', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              duration: 200.ms,
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeOut,
              crossFadeState: _editingNote ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: _noteCtrl.text.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.warmGray, borderRadius: BorderRadius.circular(14)),
                      child: const Text('Eslatma qo\'shish uchun tahrirlang', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.warning.withOpacity(0.25))),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.sticky_note_2_outlined, color: AppColors.warning, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_noteCtrl.text, style: const TextStyle(color: AppColors.text, fontSize: 13, height: 1.5))),
                      ]),
                    ),
              secondChild: Column(children: [
                TextField(
                  controller: _noteCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.text, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Masalan: yengilroq soch yoqadi, allergiya bor...'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingNote ? null : _saveNote,
                    child: _savingNote
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Saqlash'),
                  ),
                ),
              ]),
            ),

            // Visit history
            if (history.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionLabel('Bron tarixi'),
              const SizedBox(height: 10),
              ...history.take(6).toList().asMap().entries.map((e) {
                final h = e.value;
                final service = h['service']?.toString() ?? 'Xizmat';
                final date = h['date']?.toString() ?? '';
                final amount = (h['amount'] as num? ?? 0).toInt();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
                  child: Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.content_cut_rounded, color: AppColors.primary, size: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(service, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
                      if (date.isNotEmpty) Text(date, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    ])),
                    if (amount > 0) Text(_fmtMoney(amount), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                );
              }),
            ],
          ]),
        )),
      ]),
    );
  }

  Widget _avatarFallback(String name, bool isVip) => Container(
    width: 60, height: 60,
    color: isVip ? AppColors.warningLight : AppColors.primaryLight,
    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: isVip ? AppColors.warning : AppColors.primary, fontWeight: FontWeight.w800, fontSize: 22))),
  );

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
  );

  Widget _statPill(String value, String label, Color color, Color bg) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
      ]),
    ),
  );

  String _fmtMoney(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v';
  }
}
