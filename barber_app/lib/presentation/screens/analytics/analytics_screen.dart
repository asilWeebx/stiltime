import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api.dart';
import '../../../core/theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _State();
}

class _State extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await BarberApi.instance.get('/analytics/barber/');
      setState(() { _data = Map<String, dynamic>.from(res.data); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/')),
        title: const Text('Statistika'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          dividerColor: AppColors.border,
          tabs: const [Tab(text: 'Kunlik'), Tab(text: 'Haftalik'), Tab(text: 'Oylik')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: TabBarView(
                controller: _tabs,
                children: [
                  _PeriodView(data: _data, period: 'daily'),
                  _PeriodView(data: _data, period: 'weekly'),
                  _PeriodView(data: _data, period: 'monthly'),
                ],
              ),
            ),
    );
  }
}

class _PeriodView extends StatelessWidget {
  final Map<String, dynamic> data;
  final String period;
  const _PeriodView({required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    // Backend returns period data nested under 'daily'/'weekly'/'monthly'
    final periodData = data[period] is Map ? Map<String, dynamic>.from(data[period] as Map) : <String, dynamic>{};
    final revenue = (periodData['revenue'] as num? ?? 0).toDouble();
    final bookings = periodData['count'] as int? ?? 0;
    // Top-level fields shared across all periods
    final rating = (data['rating'] as num? ?? 0).toDouble();
    final totalReviews = data['total_reviews'] as int? ?? 0;
    final chartData = (data['daily_chart'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final topServices = (data['popular_services'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final paymentMethodsMap = data['payment_methods'] as Map? ?? {};
    // Build stats map for payment_methods section (mimic old stats structure)
    final stats = <String, dynamic>{...periodData, 'payment_methods': paymentMethodsMap};

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero revenue card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4E6EF5), Color(0xFF3451D1)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Daromad', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(_fmtRevenue(revenue.toInt()), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(_periodLabel(period), style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ).animate().fadeIn().slideY(begin: -0.05),

        const SizedBox(height: 16),

        // Stats grid
        Row(children: [
          _StatCard(label: 'Bronlar', value: '$bookings', icon: Icons.calendar_today_rounded, color: AppColors.success, bg: AppColors.successLight),
          const SizedBox(width: 10),
          _StatCard(label: 'Reyting', value: rating > 0 ? rating.toStringAsFixed(1) : '—', icon: Icons.star_rounded, color: AppColors.warning, bg: AppColors.warningLight),
          const SizedBox(width: 10),
          _StatCard(label: 'Sharhlar', value: '$totalReviews', icon: Icons.reviews_rounded, color: AppColors.primary, bg: AppColors.primaryLight),
        ]).animate().fadeIn(delay: 80.ms),

        // Revenue chart
        if (chartData.isNotEmpty) ...[
          const SizedBox(height: 28),
          _sectionLabel('Daromad grafigi'),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
            child: BarChart(
              BarChartData(
                barGroups: chartData.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [BarChartRodData(
                    toY: (e.value['revenue'] as num? ?? 0).toDouble() / 1000,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B8BF5), Color(0xFF4E6EF5)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    width: 16,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  )],
                )).toList(),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF0EDE8), strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}K', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i >= chartData.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text((chartData[i]['date'] as String? ?? '').split(' ').first, style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                      );
                    },
                  )),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${(rod.toY * 1000).toInt()}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 120.ms),
        ],

        // Top services
        if (topServices.isNotEmpty) ...[
          const SizedBox(height: 28),
          _sectionLabel('Eng ko\'p buyurtma'),
          const SizedBox(height: 12),
          ...topServices.asMap().entries.map((e) {
            final s = e.value;
            final name = s['services__name'] as String? ?? s['name'] as String? ?? '';
            final count = s['count'] as int? ?? 0;
            final sRev = (s['revenue'] as num? ?? 0).toInt();
            final maxCount = topServices.isNotEmpty ? ((topServices.first['count'] as int? ?? 1)) : 1;
            final pct = maxCount > 0 ? count / maxCount : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
              child: Column(children: [
                Row(children: [
                  Text('${e.key + 1}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14))),
                  Text('$count ta', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text(_fmtRevenue(sRev), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: AppColors.primaryLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ]),
            ).animate(delay: Duration(milliseconds: e.key * 60)).fadeIn().slideX(begin: 0.05);
          }),
        ],

        // Payment breakdown
        if (stats['payment_methods'] != null) ...[
          const SizedBox(height: 28),
          _sectionLabel("To'lov usullari"),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
            child: Column(
              children: ((stats['payment_methods'] as Map?) ?? {}).entries.map((e) {
                final amt = (e.value as num).toDouble();
                final pct = revenue > 0 ? (amt / revenue) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(e.key as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
                      Text(_fmtRevenue(amt.toInt()), style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                        child: Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: pct, minHeight: 4, backgroundColor: AppColors.primaryLight, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ]),
    );
  }

  String _fmtRevenue(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M so\'m';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K so\'m';
    return '$v so\'m';
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'daily': return 'Bugungi daromad';
      case 'weekly': return 'Shu haftaning daromadi';
      case 'monthly': return 'Shu oyning daromadi';
      default: return '';
    }
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 17)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 18)),
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
      ]),
    ),
  );
}
