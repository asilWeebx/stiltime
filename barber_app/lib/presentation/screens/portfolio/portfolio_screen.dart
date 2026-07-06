import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api.dart';
import '../../../core/app_alert.dart';
import '../../../core/theme.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _State();
}

class _State extends State<PortfolioScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await BarberApi.instance.get('/barbers/me/portfolio/');
      final raw = res.data;
      final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : raw;
      setState(() {
        _items = List<Map<String, dynamic>>.from(list);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addItem() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPortfolioSheet(onAdded: _load),
    );
  }

  Future<void> _delete(int id) async {
    try {
      await BarberApi.instance.delete('/barbers/me/portfolio/$id/');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Portfolio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: _addItem,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _PortfolioCard(
                      item: _items[i],
                      onDelete: () => _delete(_items[i]['id'] as int),
                    ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().scale(begin: const Offset(0.95, 0.95)),
                  ),
                ),
    );
  }

  Widget _empty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 16),
        const Text('Portfolio bo\'sh', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Oldin va keyin rasmlarini qo\'shing', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text("Rasm qo'shish"),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Portfolio card
// ---------------------------------------------------------------------------

class _PortfolioCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;
  const _PortfolioCard({required this.item, required this.onDelete});

  @override
  @override
  Widget build(BuildContext context) {
    final before = item['before_image'] as String?;
    final after  = item['after_image']  as String?;
    final desc   = item['caption']      as String? ?? '';
    final status = item['status']       as String? ?? 'pending';
    final reason = item['rejection_reason'] as String? ?? '';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon  = Icons.check_circle_rounded;
        statusLabel = 'Tasdiqlandi';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon  = Icons.cancel_rounded;
        statusLabel = 'Rad etildi';
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon  = Icons.hourglass_top_rounded;
        statusLabel = 'Kutilmoqda';
    }

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
          border: status == 'rejected'
              ? Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 160,
                child: Row(children: [
                  Expanded(child: Stack(children: [
                    before != null
                        ? Image.network(before, height: 160, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                    Positioned(top: 6, left: 6, child: _badge('Oldin', Colors.black54)),
                  ])),
                  const VerticalDivider(width: 2, color: Colors.white),
                  Expanded(child: Stack(children: [
                    after != null
                        ? Image.network(after, height: 160, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                    Positioned(top: 6, left: 6, child: _badge('Keyin', AppColors.success)),
                  ])),
                ]),
              ),
            ),
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.08)),
              child: Row(children: [
                Icon(statusIcon, color: statusColor, size: 13),
                const SizedBox(width: 5),
                Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                if (status == 'rejected' && reason.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Expanded(child: Text('· $reason', style: TextStyle(color: statusColor.withOpacity(0.7), fontSize: 10), overflow: TextOverflow.ellipsis)),
                ],
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(children: [
                Expanded(
                  child: Text(
                    desc.isEmpty ? 'Transformatsiya' : desc,
                    style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 14),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.85), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
  );

  Widget _placeholder() => Container(
    color: AppColors.beige,
    child: const Center(child: Icon(Icons.image_rounded, color: AppColors.border, size: 32)),
  );

  void _showDetail(BuildContext context) {
    final before = item['before_image'] as String?;
    final after = item['after_image'] as String?;
    final desc = item['caption'] as String? ?? '';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Row(children: [
                  Expanded(child: before != null ? Image.network(before, height: 300, fit: BoxFit.cover) : Container(height: 300, color: AppColors.beige)),
                  Expanded(child: after != null ? Image.network(after, height: 300, fit: BoxFit.cover) : Container(height: 300, color: AppColors.beige)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('OLDIN', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      Text('KEYIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Yopish', style: TextStyle(color: Colors.white60)),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature 3 — Redesigned "Add portfolio" bottom sheet
// ---------------------------------------------------------------------------

class _AddPortfolioSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddPortfolioSheet({required this.onAdded});

  @override
  State<_AddPortfolioSheet> createState() => _AddPortfolioSheetState();
}

class _AddPortfolioSheetState extends State<_AddPortfolioSheet> {
  String? _beforePath;
  String? _afterPath;
  final _captionCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isBefore) async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      setState(() {
        if (isBefore) {
          _beforePath = img.path;
        } else {
          _afterPath = img.path;
        }
      });
    }
  }

  void _remove(bool isBefore) {
    setState(() {
      if (isBefore) {
        _beforePath = null;
      } else {
        _afterPath = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_beforePath == null || _afterPath == null) {
      showAppAlert(context, 'Ikkala rasmni ham tanlang');
      return;
    }
    setState(() => _loading = true);
    try {
      final form = FormData.fromMap({
        'before_image': await MultipartFile.fromFile(_beforePath!, filename: 'before.jpg'),
        'after_image': await MultipartFile.fromFile(_afterPath!, filename: 'after.jpg'),
        'caption': _captionCtrl.text.trim(),
      });
      await BarberApi.instance.post('/barbers/me/portfolio/', data: form);
      widget.onAdded();
      if (mounted) {
        Navigator.pop(context);
        showAppAlert(context, 'Portfolio yangilandi', type: AlertType.success);
      }
    } catch (_) {
      if (mounted) {
        showAppAlert(context, 'Xatolik yuz berdi. Qayta urining.');
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sheet header
                  const Text(
                    'Ishlaringizni portfoyliga qo\'shing',
                    style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 12),

                  // Supported formats info block
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Qo\'llab-quvvatlanadigan formatlar: Rasm — JPG, PNG. Talab: Nisbat 3:4, max 2MB',
                            style: TextStyle(color: AppColors.primary, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Two photo cards side by side
                  Row(
                    children: [
                      Expanded(child: _photoCard('Oldin', _beforePath, true)),
                      const SizedBox(width: 12),
                      Expanded(child: _photoCard('Keyin', _afterPath, false)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Caption field
                  const Text(
                    'Sarlavha (ixtiyoriy)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _captionCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.text),
                    decoration: const InputDecoration(hintText: 'Masalan: Klassik soch kesish, qirqish...'),
                  ),
                  const SizedBox(height: 24),

                  // Big submit button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Moderatsiyaga yuborish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoCard(String label, String? path, bool isBefore) {
    return GestureDetector(
      onTap: () => _pick(isBefore),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: path != null ? Colors.transparent : AppColors.warmGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: path != null ? AppColors.primary.withOpacity(0.4) : AppColors.border,
            width: 1.5,
          ),
        ),
        child: path != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.beige),
                    ),
                    // X button overlay
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => _remove(isBefore),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    // Label at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(color: AppColors.textHint, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Rasmni tanlang',
                    style: TextStyle(color: AppColors.textHint, fontSize: 10),
                  ),
                ],
              ),
      ),
    );
  }
}
