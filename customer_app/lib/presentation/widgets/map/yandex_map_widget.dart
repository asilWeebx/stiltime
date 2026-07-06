import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class YandexMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String title;
  final double height;

  const YandexMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.height = 220,
  });

  @override
  State<YandexMapWidget> createState() => _YandexMapWidgetState();
}

class _YandexMapWidgetState extends State<YandexMapWidget> {
  YandexMapController? _controller;

  Point get _point => Point(latitude: widget.latitude, longitude: widget.longitude);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            YandexMap(
              onMapCreated: (controller) async {
                _controller = controller;
                await controller.moveCamera(
                  CameraUpdate.newCameraPosition(CameraPosition(target: _point, zoom: 15)),
                  animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.5),
                );
              },
              mapObjects: [
                PlacemarkMapObject(
                  mapId: const MapObjectId('salon'),
                  point: _point,
                  icon: PlacemarkIcon.single(PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage('assets/icons/map_pin.png'),
                    scale: 0.15,
                  )),
                ),
              ],
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: _openInYandexMaps,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.open_in_new, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('Yandex Maps', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInYandexMaps() async {
    final appUri = Uri.parse('yandexmaps://maps.yandex.ru/?pt=${widget.longitude},${widget.latitude}&z=15');
    final webUri = Uri.parse('https://yandex.uz/maps/?pt=${widget.longitude},${widget.latitude}&z=15&text=${Uri.encodeComponent(widget.title)}');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class MapPlaceholder extends StatelessWidget {
  final String address;
  const MapPlaceholder({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('https://yandex.uz/maps/?text=${Uri.encodeComponent(address)}');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(address, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text("Yandex Maps'da ko'rish", style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
          Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}
