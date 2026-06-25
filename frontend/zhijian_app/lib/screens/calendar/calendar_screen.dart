import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/index.dart';
import '../../services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _api = ApiService();

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  Map<String, CalendarDay> _calendarData = {};

  // Demo data
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateDemoData();
  }

  void _generateDemoData() {
    // Generate 90 days of demo calendar data
    final now = DateTime.now();
    final data = <String, CalendarDay>{};
    final random = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < 90; i++) {
      final d = now.subtract(Duration(days: i));
      final key = _dateKey(d);
      // Simulate ~70% check-in rate
      final hasPhoto = (random + i) % 10 < 7;
      data[key] = CalendarDay(
        date: key,
        hasPhoto: hasPhoto,
        mood: hasPhoto ? ['great', 'good', 'okay'][(random + i) % 3] : null,
        streakDay: i < 5, // last 5 days are streak
      );
    }
    setState(() => _calendarData = data);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon

    final monthStr = '$year年${month}月';
    final weekHeaders = ['一', '二', '三', '四', '五', '六', '日'];

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(monthStr),

          // Year heatmap (compact)
          _buildYearHeatmap(),

          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left, color: ZhiJianTheme.text),
                ),
                Text(
                  monthStr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ZhiJianTheme.text,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right, color: ZhiJianTheme.text),
                ),
              ],
            ),
          ),

          // Weekday headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: weekHeaders
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: d == '六' || d == '日'
                                  ? ZhiJianTheme.primary
                                  : ZhiJianTheme.textSecondary,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: firstWeekday - 1 + daysInMonth,
                itemBuilder: (_, index) {
                  final dayNum = index - (firstWeekday - 1) + 1;
                  if (dayNum < 1) return const SizedBox.shrink();

                  final date = DateTime(year, month, dayNum);
                  final key = _dateKey(date);
                  final dayData = _calendarData[key];
                  final hasPhoto = dayData?.hasPhoto ?? false;
                  final isToday = _isToday(date);
                  final isSelected = _selectedDay != null &&
                      _dateKey(_selectedDay!) == key;

                  return GestureDetector(
                    onTap: hasPhoto
                        ? () {
                            setState(() => _selectedDay = date);
                            _showDayDetail(context, date, key);
                          }
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ZhiJianTheme.primary.withOpacity(0.2)
                            : hasPhoto
                                ? ZhiJianTheme.surfaceLight
                                : ZhiJianTheme.surface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(
                                color: ZhiJianTheme.primary,
                                width: 2,
                              )
                            : isSelected
                                ? Border.all(
                                    color: ZhiJianTheme.primary.withOpacity(0.5),
                                    width: 1.5,
                                  )
                                : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Photo thumbnail or placeholder
                          if (hasPhoto)
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: ZhiJianTheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(
                                  child: Icon(Icons.person,
                                      size: 18,
                                      color: ZhiJianTheme.textSecondary),
                                ),
                              ),
                            )
                          else
                            const Expanded(
                              child: Center(
                                child: Icon(Icons.lock_outline,
                                    size: 12,
                                    color: ZhiJianTheme.textSecondary),
                              ),
                            ),

                          // Day number
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday
                                  ? ZhiJianTheme.primary
                                  : ZhiJianTheme.textSecondary,
                            ),
                          ),

                          // Streak dot
                          if (dayData?.streakDay == true)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: ZhiJianTheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Comparison button
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showComparison(context),
                icon: const Icon(Icons.compare),
                label: const Text('对比模式'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(String monthStr) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '📅 时光历程',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ZhiJianTheme.text,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ZhiJianTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '共记录 90 天',
              style: TextStyle(
                fontSize: 13,
                color: ZhiJianTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearHeatmap() {
    // Simplified version: color bars representing check-in density per month
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ZhiJianTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '年度打卡热力图',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ZhiJianTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(12, (i) {
              // Simulate monthly check-in density
              final densities = [0.8, 0.9, 0.6, 0.75, 0.95, 1.0, 0.7, 0.85, 0.5, 0.9, 0.65, 0.7];
              final density = densities[i];
              final color = Color.lerp(
                ZhiJianTheme.surfaceLight,
                ZhiJianTheme.primary,
                density,
              );

              return Tooltip(
                message: '${i + 1}月: ${(density * 100).toInt()}%',
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              12,
              (i) => Text(
                '${i + 1}',
                style: const TextStyle(
                    fontSize: 9, color: ZhiJianTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  void _showDayDetail(BuildContext context, DateTime date, String key) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ZhiJianTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ZhiJianTheme.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  key,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ZhiJianTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.weekday == DateTime.monday ? '周一' : date.weekday == DateTime.tuesday ? '周二' : date.weekday == DateTime.wednesday ? '周三' : date.weekday == DateTime.thursday ? '周四' : date.weekday == DateTime.friday ? '周五' : date.weekday == DateTime.saturday ? '周六' : '周日'} · 心情 😊',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ZhiJianTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Photo gallery placeholder
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ZhiJianTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 48, color: ZhiJianTheme.textSecondary),
                        SizedBox(height: 8),
                        Text('当日照片', style: TextStyle(color: ZhiJianTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // AI Report summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ZhiJianTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI 分析摘要',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ZhiJianTheme.text)),
                      SizedBox(height: 8),
                      Text('综合评分 76/100 · 肩部分离度 +3.2% · 腹肌可见度提升',
                          style: TextStyle(color: ZhiJianTheme.textSecondary)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Weight/BF input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: '体重 (kg)',
                          labelStyle: const TextStyle(color: ZhiJianTheme.textSecondary),
                          filled: true,
                          fillColor: ZhiJianTheme.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: '体脂 (%)',
                          labelStyle: const TextStyle(color: ZhiJianTheme.textSecondary),
                          filled: true,
                          fillColor: ZhiJianTheme.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComparison(BuildContext context) {
    if (_selectedDay == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZhiJianTheme.surface,
        title: const Text('选择对比日期',
            style: TextStyle(color: ZhiJianTheme.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '将 ${_dateKey(_selectedDay!)} 与以下日期对比：',
              style: const TextStyle(color: ZhiJianTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            // Quick selects
            Wrap(
              spacing: 8,
              children: ['第 1 天', '7 天前', '30 天前', '90 天前']
                  .map((label) => ActionChip(
                        label: Text(label),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('对比图生成中: $label'),
                              backgroundColor: ZhiJianTheme.primary,
                            ),
                          );
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
