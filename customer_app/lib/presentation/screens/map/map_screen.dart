import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/map/salon_map_pin.dart';

List<Map<String, dynamic>> _toList(dynamic raw) {
  final list = raw is Map ? (raw['results'] ?? raw['data'] ?? []) : raw;
  return List<Map<String, dynamic>>.from(list as List? ?? []);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  YandexMapController? _controller;
  List<PlacemarkMapObject> _markers = [];
  bool _loading = true;

  static const _tashkent = Point(latitude: 41.2995, longitude: 69.2401);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: _onMapCreated,
            mapObjects: _markers,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.text),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.map_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Salonlar xaritasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text)),
                  const Spacer(),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMapCreated(YandexMapController controller) async {
    _controller = controller;
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(const CameraPosition(target: _tashkent, zoom: 12)),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1.0),
    );
    await _loadSalons();
  }

  Future<void> _loadSalons() async {
    try {
      final res = await DioClient.instance.get('/salons/', queryParameters: {'limit': 50});
      final salons = _toList(res.data);

      final markers = <PlacemarkMapObject>[];
      for (final salon in salons) {
        final lat = (salon['latitude'] as num?)?.toDouble();
        final lon = (salon['longitude'] as num?)?.toDouble();
        if (lat == null || lon == null || lat == 0 || lon == 0) continue;

        final name = (salon['name'] as String?) ?? 'Salon';
        final pinBytes = await buildSalonPinBytes(
          imageUrl: salon['cover_image'] as String?,
          fallbackLetter: name.isNotEmpty ? name[0] : 'S',
          color: AppColors.primary,
        );

        final s = Map<String, dynamic>.from(salon);
        markers.add(PlacemarkMapObject(
          mapId: MapObjectId('salon_${salon['id']}'),
          point: Point(latitude: lat, longitude: lon),
          icon: PlacemarkIcon.single(PlacemarkIconStyle(
            image: BitmapDescriptor.fromBytes(pinBytes),
            scale: 0.9,
          )),
          onTap: (_, __) => _onSalonTap(s),
        ));
      }

      if (mounted) setState(() { _markers = markers; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSalonTap(Map<String, dynamic> salon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SalonSheet(salon: salon),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _SalonSheet extends StatelessWidget {
  final Map<String, dynamic> salon;
  const _SalonSheet({required this.salon});

  @override
  Widget build(BuildContext context) {
    final name = salon['name'] as String? ?? 'Salon';
    final address = salon['address'] as String? ?? '';
    final rating = (salon['rating'] as num?)?.toDouble() ?? 0.0;
    final cover = salon['cover_image'] as String?;
    final isOpen = salon['is_open'] == true;
    final id = salon['id'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 64, height: 64,
              child: cover != null
                  ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback(name))
                  : _fallback(name),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.text)),
            const SizedBox(height: 4),
            if (address.isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 3),
                Expanded(child: Text(address,
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
              ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.star_rounded, size: 13, color: AppColors.star),
              const SizedBox(width: 3),
              Text(rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.text)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.successLight : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOpen ? 'Ochiq' : 'Yopiq',
                  style: TextStyle(
                    color: isOpen ? AppColors.success : AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ]),
          ])),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.pop();
              if (id != null) context.push('/salon/$id');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text("Salonni ko'rish", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  Widget _fallback(String name) => Container(
    color: AppColors.beige,
    child: Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'S',
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 24, fontWeight: FontWeight.w800),
    )),
  );
}
