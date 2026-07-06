import 'package:flutter/material.dart';
import 'theme.dart';

enum AlertType { error, success, info }

void showAppAlert(
  BuildContext context,
  String message, {
  AlertType type = AlertType.error,
  String? title,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _AppAlertOverlay(
      message: message,
      title: title ?? _defaultTitle(type),
      type: type,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

String _defaultTitle(AlertType type) => switch (type) {
      AlertType.error => 'Xatolik',
      AlertType.success => 'Muvaffaqiyat',
      AlertType.info => 'Ma\'lumot',
    };

class _AppAlertOverlay extends StatefulWidget {
  final String message;
  final String title;
  final AlertType type;
  final VoidCallback onDismiss;

  const _AppAlertOverlay({
    required this.message,
    required this.title,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_AppAlertOverlay> createState() => _AppAlertOverlayState();
}

class _AppAlertOverlayState extends State<_AppAlertOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 3200), _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, iconBg, iconColor, icon) = switch (widget.type) {
      AlertType.error   => (AppColors.error, const Color(0xFFFEEEEE), AppColors.error, Icons.error_rounded),
      AlertType.success => (const Color(0xFF22C55E), const Color(0xFFEEFBF4), const Color(0xFF16A34A), Icons.check_circle_rounded),
      AlertType.info    => (AppColors.primary, AppColors.primaryLight, AppColors.primary, Icons.info_rounded),
    };

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: bg.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: bg.withOpacity(0.2), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: bg,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
