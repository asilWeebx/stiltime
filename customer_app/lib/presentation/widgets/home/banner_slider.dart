import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_theme.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final _controller = PageController();
  final _banners = [
    _BannerData('30% chegirma', 'Barcha sartarosh xizmatlarida', 'Dushanba va Seshanba kunlari', const Color(0xFF6B21A8)),
    _BannerData('Yangi sartaroshlar', 'Top sartaroshlar ro\'yxatiga qo\'shildi', 'Hoziroq bron qiling', const Color(0xFF065F46)),
    _BannerData('Referral bonus', 'Do\'stingizni taklif qiling', '50 000 so\'m bonus oling', const Color(0xFF7C2D12)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            itemBuilder: (context, i) {
              final banner = _banners[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [banner.color, banner.color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned(right: -20, top: -20, child: CircleAvatar(radius: 70, backgroundColor: Colors.white.withOpacity(0.08))),
                    Positioned(right: 30, bottom: -30, child: CircleAvatar(radius: 50, backgroundColor: Colors.white.withOpacity(0.06))),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: Text(banner.subtitle, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 8),
                          Text(banner.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(banner.description, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SmoothPageIndicator(
          controller: _controller,
          count: _banners.length,
          effect: WormEffect(
            dotWidth: 6,
            dotHeight: 6,
            activeDotColor: AppColors.primary,
            dotColor: AppColors.border,
          ),
        ),
      ],
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  const _BannerData(this.title, this.subtitle, this.description, this.color);
}
