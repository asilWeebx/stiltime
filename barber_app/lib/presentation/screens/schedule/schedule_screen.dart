import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api.dart';
import '../../../core/app_alert.dart';
import '../../../core/theme.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

class _DaySchedule {
  final String name;
  bool isWorking;
  String start;
  String end;
  String? breakStart;
  String? breakEnd;

  _DaySchedule(this.name, this.isWorking, this.start, this.end,
      {this.breakStart, this.breakEnd});

  Map<String, dynamic> toJson(int day) => {
        'day': day,
        'is_working': isWorking,
        'start': start,
        'end': end,
        'break_start': breakStart,
        'break_end': breakEnd,
      };
}

class _SlotInfo {
  final String time;
  final String endTime;
  final String status; // available / booked / blocked / break
  _SlotInfo(this.time, this.endTime, this.status);
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _slotsProvider = FutureProvider.family<List<_SlotInfo>, String>((ref, date) async {
  try {
    final res = await BarberApi.instance.get('/barbers/me/slots/?date=$date');
    final data = res.data as Map;
    final slots = (data['slots'] as List?) ?? [];
    return slots.map((s) {
      final m = s as Map;
      return _SlotInfo(
        m['time'] as String,
        m['end_time'] as String,
        m['status'] as String? ?? (m['is_available'] == true ? 'available' : 'booked'),
      );
    }).toList();
  } catch (_) {
    return [];
  }
});

// ─── Main screen ──────────────────────────────────────────────────────────────

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});
  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  bool _vacationMode = false;
  bool _savingSchedule = false;

  final List<_DaySchedule> _days = [
    _DaySchedule('Dushanba', true, '09:00', '19:00'),
    _DaySchedule('Seshanba', true, '09:00', '19:00'),
    _DaySchedule('Chorshanba', true, '09:00', '19:00'),
    _DaySchedule('Payshanba', true, '09:00', '19:00'),
    _DaySchedule('Juma', true, '09:00', '19:00'),
    _DaySchedule('Shanba', true, '10:00', '18:00'),
    _DaySchedule('Yakshanba', false, '10:00', '16:00'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    try {
      final res = await BarberApi.instance.get('/barbers/me/schedule/');
      // Use Map.from() — res.data is Map<dynamic,dynamic> after NumCoercionInterceptor
      final data = Map<String, dynamic>.from(res.data as Map);
      if (!mounted) return;
      setState(() {
        _vacationMode = data['vacation_mode'] == true;
        final schedule = data['schedule'] as List? ?? [];
        for (var i = 0; i < schedule.length && i < _days.length; i++) {
          final d = Map<String, dynamic>.from(schedule[i] as Map);
          _days[i]
            ..isWorking = d['is_working'] == true
            ..start = (d['start'] as Object?)?.toString() ?? '09:00'
            ..end = (d['end'] as Object?)?.toString() ?? '19:00'
            ..breakStart = d['break_start'] != null ? d['break_start'].toString() : null
            ..breakEnd = d['break_end'] != null ? d['break_end'].toString() : null;
        }
      });
    } catch (e) {
      debugPrint('_loadSchedule error: $e');
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _savingSchedule = true);
    try {
      await BarberApi.instance.patch('/barbers/me/schedule/', data: {
        'vacation_mode': _vacationMode,
        'schedule': _days
            .asMap()
            .entries
            .map((e) => e.value.toJson(e.key))
            .toList(),
      });
      if (mounted) showAppAlert(context, 'Jadval saqlandi', type: AlertType.success);
    } catch (_) {
      if (mounted) showAppAlert(context, 'Saqlashda xatolik');
    } finally {
      if (mounted) setState(() => _savingSchedule = false);
    }
  }

  void _switchToWeeklyTab() {
    _tabs.animateTo(0);
    setState(() {});
  }

  Future<void> _saveScheduleAndRefresh() async {
    await _saveSchedule();
    // Reload from backend to confirm what was actually saved
    if (mounted) await _loadSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Ish jadvali',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          actions: [
            if (_tabs.index == 0)
              TextButton(
                onPressed: _savingSchedule ? null : _saveScheduleAndRefresh,
                child: _savingSchedule
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary))
                    : const Text('Saqlash',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabs,
            onTap: (_) => setState(() {}),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            dividerColor: AppColors.border,
            tabs: const [
              Tab(text: 'Haftalik jadval'),
              Tab(text: 'Slot boshqaruvi'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _WeeklyTab(
              days: _days,
              vacationMode: _vacationMode,
              onVacationToggle: (v) => setState(() => _vacationMode = v),
              onDayChanged: () => setState(() {}),
            ),
            _SlotTab(onGoToWeeklyTab: _switchToWeeklyTab),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: Weekly schedule ───────────────────────────────────────────────────

class _WeeklyTab extends StatelessWidget {
  final List<_DaySchedule> days;
  final bool vacationMode;
  final ValueChanged<bool> onVacationToggle;
  final VoidCallback onDayChanged;

  const _WeeklyTab({
    required this.days,
    required this.vacationMode,
    required this.onVacationToggle,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        // Vacation card
        AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: vacationMode ? const Color(0xFFFFF8E1) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
            border: vacationMode
                ? Border.all(color: AppColors.warning.withOpacity(0.5))
                : null,
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: vacationMode
                    ? AppColors.warning.withOpacity(0.15)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                vacationMode ? Icons.beach_access_rounded : Icons.work_rounded,
                color: vacationMode ? AppColors.warning : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  vacationMode ? 'Ta\'til rejimi yoqilgan' : 'Ta\'til rejimi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: vacationMode ? AppColors.warning : AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vacationMode
                      ? 'Hech qanday bron qabul qilinmaydi'
                      : 'Yoqilganda barcha bronlar to\'xtatiladi',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ]),
            ),
            Switch(
              value: vacationMode,
              onChanged: onVacationToggle,
              activeColor: AppColors.warning,
            ),
          ]),
        ).animate().fadeIn(),

        const SizedBox(height: 24),
        const Text(
          'HAFTALIK JADVAL',
          style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1),
        ),
        const SizedBox(height: 12),

        ...days.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DayCard(
                day: e.value,
                onChanged: onDayChanged,
              ).animate(delay: Duration(milliseconds: e.key * 50)).fadeIn().slideX(begin: 0.04),
            )),
      ],
    );
  }
}

// ─── Day card with break time ─────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final _DaySchedule day;
  final VoidCallback onChanged;
  const _DayCard({required this.day, required this.onChanged});

  Future<String?> _pickTime(BuildContext context, String current) async {
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasBreak = day.breakStart != null && day.breakEnd != null;

    return AnimatedContainer(
      duration: 200.ms,
      decoration: BoxDecoration(
        color: day.isWorking ? AppColors.surface : AppColors.warmGray,
        borderRadius: BorderRadius.circular(18),
        boxShadow: day.isWorking ? AppColors.cardShadow : [],
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: day.isWorking ? AppColors.success : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: Text(
                  day.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: day.isWorking ? AppColors.text : AppColors.textHint,
                  ),
                ),
              ),
              Expanded(
                child: day.isWorking
                    ? Row(children: [
                        _timeChip(context, day.start, (t) {
                          day.start = t;
                          onChanged();
                        }),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('—',
                              style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w700)),
                        ),
                        _timeChip(context, day.end, (t) {
                          day.end = t;
                          onChanged();
                        }),
                      ])
                    : const Text('Dam olish',
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              ),
              Switch(
                value: day.isWorking,
                onChanged: (v) {
                  day.isWorking = v;
                  onChanged();
                },
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ]),
          ),

          // Break section (only when working)
          if (day.isWorking) ...[
            Container(height: 1, color: AppColors.border.withOpacity(0.5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(children: [
                const Icon(Icons.coffee_rounded, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                const Text(
                  'Dam olish vaqti',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (hasBreak) ...[
                  _timeChip(context, day.breakStart!, (t) {
                    day.breakStart = t;
                    onChanged();
                  }, small: true, color: const Color(0xFF5B9BD5)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('—', style: TextStyle(color: AppColors.textHint)),
                  ),
                  _timeChip(context, day.breakEnd!, (t) {
                    day.breakEnd = t;
                    onChanged();
                  }, small: true, color: const Color(0xFF5B9BD5)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      day.breakStart = null;
                      day.breakEnd = null;
                      onChanged();
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 13, color: AppColors.error),
                    ),
                  ),
                ] else
                  GestureDetector(
                    onTap: () async {
                      day.breakStart = '13:00';
                      day.breakEnd = '14:00';
                      onChanged();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B9BD5).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add, size: 13, color: Color(0xFF5B9BD5)),
                        SizedBox(width: 3),
                        Text('Qo\'shish',
                            style: TextStyle(
                                color: Color(0xFF5B9BD5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeChip(
    BuildContext context,
    String time,
    ValueChanged<String> onPick, {
    bool small = false,
    Color color = AppColors.primary,
  }) =>
      GestureDetector(
        onTap: () async {
          final t = await _pickTime(context, time);
          if (t != null) onPick(t);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: small ? 8 : 12, vertical: small ? 5 : 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            time,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: small ? 12 : 13),
          ),
        ),
      );
}

// ─── Tab 2: Slot grid for a specific date ─────────────────────────────────────

class _SlotTab extends ConsumerStatefulWidget {
  final VoidCallback onGoToWeeklyTab;
  const _SlotTab({required this.onGoToWeeklyTab});
  @override
  ConsumerState<_SlotTab> createState() => _SlotTabState();
}

class _SlotTabState extends ConsumerState<_SlotTab>
    with AutomaticKeepAliveClientMixin {
  late DateTime _selectedDate;
  bool _blocking = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String get _dateStr =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _toggleBlock(_SlotInfo slot) async {
    if (slot.status == 'booked') {
      showAppAlert(context, 'Bu slot allaqachon bron qilingan', type: AlertType.info);
      return;
    }
    if (slot.status == 'break') {
      showAppAlert(context, 'Dam olish vaqtini jadvaldan o\'zgartiring', type: AlertType.info);
      return;
    }

    setState(() => _blocking = true);
    try {
      final shouldBlock = slot.status == 'available';
      await BarberApi.instance.post('/barbers/me/blocks/', data: {
        'date': _dateStr,
        'time': slot.time,
        'block': shouldBlock,
      });
      ref.invalidate(_slotsProvider(_dateStr));
      if (mounted) {
        showAppAlert(
          context,
          shouldBlock ? '${slot.time} bloklandi' : '${slot.time} blok olib tashlandi',
          type: AlertType.success,
        );
      }
    } catch (_) {
      if (mounted) showAppAlert(context, 'Xatolik yuz berdi');
    } finally {
      if (mounted) setState(() => _blocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final slotsAsync = ref.watch(_slotsProvider(_dateStr));

    return Column(
      children: [
        // Date strip
        _DateStrip(
          selected: _selectedDate,
          onSelect: (d) => setState(() => _selectedDate = d),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              _legend('Bo\'sh', _slotColor('available')),
              const SizedBox(width: 12),
              _legend('Bloklangan', _slotColor('blocked')),
              const SizedBox(width: 12),
              _legend('Bron', _slotColor('booked')),
              const SizedBox(width: 12),
              _legend('Tanaffus', _slotColor('break')),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Slot grid
        Expanded(
          child: slotsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(_slotsProvider(_dateStr)),
                child: const Text('Qayta urinish'),
              ),
            ),
            data: (slots) {
              if (slots.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.edit_calendar_rounded,
                            color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bu kunda slot yo\'q',
                        style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dam olish kuni yoki haftalik jadval hali sozlanmagan',
                        style: TextStyle(
                            color: AppColors.textHint, fontSize: 13, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: widget.onGoToWeeklyTab,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.tune_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('Haftalik jadvalni sozlash',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                );
              }

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async => ref.invalidate(_slotsProvider(_dateStr)),
                    color: AppColors.primary,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.0,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (_, i) =>
                          _SlotChip(slot: slots[i], onTap: _toggleBlock),
                    ),
                  ),
                  if (_blocking)
                    Container(
                      color: Colors.black12,
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _legend(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      );
}

// ─── Date strip ───────────────────────────────────────────────────────────────

class _DateStrip extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _DateStrip({required this.selected, required this.onSelect});

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  late PageController _ctrl;
  late DateTime _startOfRange;
  static const _daysAhead = 30;

  final _dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  final _monthNames = [
    '', 'Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn',
    'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'
  ];

  @override
  void initState() {
    super.initState();
    _startOfRange = DateTime.now();
    final initialPage =
        widget.selected.difference(_startOfRange).inDays.clamp(0, _daysAhead);
    _ctrl = PageController(
        viewportFraction: 1 / 5, initialPage: initialPage.toInt());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final selectedDate =
        DateTime(widget.selected.year, widget.selected.month, widget.selected.day);

    // Month label
    final monthLabel =
        '${_monthNames[widget.selected.month]} ${widget.selected.year}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            Text(monthLabel,
                style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: widget.selected,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppColors.primary),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) widget.onSelect(picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 13, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Tanlash',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
        SizedBox(
          height: 70,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: _daysAhead + 1,
            itemBuilder: (_, i) {
              final d = _startOfRange.add(Duration(days: i));
              final date = DateTime(d.year, d.month, d.day);
              final isSelected = date == selectedDate;
              final isToday = date == DateTime(today.year, today.month, today.day);

              return GestureDetector(
                onTap: () {
                  widget.onSelect(date);
                  _ctrl.animateToPage(i,
                      duration: 200.ms, curve: Curves.easeInOut);
                },
                child: AnimatedContainer(
                  duration: 200.ms,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ] : AppColors.cardShadow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayNames[d.weekday - 1],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isToday ? AppColors.primary : AppColors.text),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isToday && !isSelected)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Slot chip ────────────────────────────────────────────────────────────────

Color _slotColor(String status) {
  switch (status) {
    case 'available': return const Color(0xFF34C759);
    case 'blocked':   return const Color(0xFF8E8E93);
    case 'booked':    return const Color(0xFFFF3B30);
    case 'break':     return const Color(0xFF5B9BD5);
    default:          return const Color(0xFF34C759);
  }
}

Color _slotBg(String status) {
  switch (status) {
    case 'available': return const Color(0xFFE8F8EE);
    case 'blocked':   return const Color(0xFFF2F2F7);
    case 'booked':    return const Color(0xFFFFEBEA);
    case 'break':     return const Color(0xFFE8F0FB);
    default:          return const Color(0xFFE8F8EE);
  }
}

class _SlotChip extends StatelessWidget {
  final _SlotInfo slot;
  final Future<void> Function(_SlotInfo) onTap;
  const _SlotChip({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _slotColor(slot.status);
    final bg = _slotBg(slot.status);
    final isInteractive = slot.status == 'available' || slot.status == 'blocked';

    return GestureDetector(
      onTap: isInteractive ? () => onTap(slot) : () => onTap(slot),
      child: AnimatedContainer(
        duration: 180.ms,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                slot.time,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
            ]),
            const SizedBox(height: 2),
            Text(
              _statusLabel(slot.status),
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available': return 'Bo\'sh';
      case 'blocked':   return 'Bloklangan';
      case 'booked':    return 'Bron';
      case 'break':     return 'Tanaffus';
      default:          return '';
    }
  }
}
