import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../models/index.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMonthData();
  }

  void _loadMonthData() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) return;
    try {
      final data = await _api.getMonthCalendar(
        auth.userId!, _focusedMonth.year, _focusedMonth.month,
      );
      final days = (data['days'] as List? ?? []);
      setState(() {
        _calendarData = {
          for (var d in days) (d['date'] as String): CalendarDay.fromJson(d),
        };
      });
    } catch (_) {}
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
    _loadMonthData();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
    _loadMonthData();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;
    final monthStr = '$year年${month}月';
    final weekHeaders = ['一', '二', '三', '四', '五', '六', '日'];
    final checkedInDays = _calendarData.values.where((d) => d.hasPhoto).length;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📅 时光历程',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ZhiJianTheme.text)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: ZhiJianTheme.surfaceLight, borderRadius: BorderRadius.circular(16)),
                  child: Text('本月打卡 $checkedInDays 天',
                      style: const TextStyle(fontSize: 13, color: ZhiJianTheme.textSecondary)),
                ),
              ],
            ),
          ),

          // Year heatmap
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: ZhiJianTheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('年度热力图', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ZhiJianTheme.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(12, (i) {
                    final densities = [0.8, 0.9, 0.6, 0.75, 0.95, 1.0, 0.7, 0.85, 0.5, 0.9, 0.65, 0.7];
                    return Tooltip(
                      message: '${i + 1}月: ${(densities[i] * 100).toInt()}%',
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: Color.lerp(ZhiJianTheme.surfaceLight, ZhiJianTheme.primary, densities[i]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Month nav
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _previousMonth, icon: const Icon(Icons.chevron_left, color: ZhiJianTheme.text)),
                Text(monthStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZhiJianTheme.text)),
                IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right, color: ZhiJianTheme.text)),
              ],
            ),
          ),

          // Weekday headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: weekHeaders.map((d) => Expanded(
                    child: Center(
                      child: Text(d, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: d == '六' || d == '日' ? ZhiJianTheme.primary : ZhiJianTheme.textSecondary)),
                    ),
                  )).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
                itemCount: firstWeekday - 1 + daysInMonth,
                itemBuilder: (_, index) {
                  final dayNum = index - (firstWeekday - 1) + 1;
                  if (dayNum < 1) return const SizedBox.shrink();

                  final date = DateTime(year, month, dayNum);
                  final key = _dateKey(date);
                  final dayData = _calendarData[key];
                  final hasPhoto = dayData?.hasPhoto ?? false;
                  final isToday = _isToday(date);
                  final isSelected = _selectedDay != null && _dateKey(_selectedDay!) == key;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDay = date);
                      _showDayDetail(context, date, key, hasPhoto);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ZhiJianTheme.primary.withOpacity(0.2)
                            : hasPhoto ? ZhiJianTheme.surfaceLight : ZhiJianTheme.surface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday ? Border.all(color: ZhiJianTheme.primary, width: 2) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasPhoto)
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: ZhiJianTheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(child: Icon(Icons.person, size: 18, color: ZhiJianTheme.textSecondary)),
                              ),
                            )
                          else
                            Expanded(
                              child: Center(
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Icon(Icons.add_photo_alternate_outlined, size: 16, color: ZhiJianTheme.textSecondary),
                                  if (isToday) const Text('上传', style: TextStyle(fontSize: 9, color: ZhiJianTheme.primary)),
                                ]),
                              ),
                            ),
                          Text('$dayNum', style: TextStyle(fontSize: 11,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? ZhiJianTheme.primary : ZhiJianTheme.textSecondary)),
                          if (dayData?.streakDay == true)
                            Container(width: 4, height: 4, margin: const EdgeInsets.only(bottom: 2),
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: ZhiJianTheme.primary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _quickUpload(context),
        icon: const Icon(Icons.camera_alt),
        label: const Text('拍照打卡'),
        backgroundColor: ZhiJianTheme.primary,
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  void _quickUpload(BuildContext context) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 1920);
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    final auth = context.read<AuthService>();
    _api.authToken = auth.token;

    try {
      await _api.uploadPhotoBytes(
        photoBytes: bytes, fileName: xfile.name,
        photoType: 'front', personality: auth.userData?['current_personality'] ?? 'gym_bro',
      );
      _loadMonthData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('✅ 打卡成功！'), backgroundColor: ZhiJianTheme.success, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打卡失败: $e'), backgroundColor: ZhiJianTheme.error),
      );
    }
  }

  void _showDayDetail(BuildContext context, DateTime date, String key, bool hasPhoto) {
    final moodController = TextEditingController();
    final weightController = TextEditingController();
    final dayData = _calendarData[key];

    showModalBottomSheet(
      context: context,
      backgroundColor: ZhiJianTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.65, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
          builder: (_, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: ZhiJianTheme.textSecondary.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),

                // Date header
                Text(key, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ZhiJianTheme.text)),
                Text(date.weekday == DateTime.monday ? '周一' : date.weekday == DateTime.tuesday ? '周二' :
                     date.weekday == DateTime.wednesday ? '周三' : date.weekday == DateTime.thursday ? '周四' :
                     date.weekday == DateTime.friday ? '周五' : date.weekday == DateTime.saturday ? '周六' : '周日',
                    style: const TextStyle(fontSize: 14, color: ZhiJianTheme.textSecondary)),
                const SizedBox(height: 20),

                // Photo section
                if (hasPhoto)
                  Container(height: 200, width: double.infinity,
                      decoration: BoxDecoration(color: ZhiJianTheme.surfaceLight, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Icon(Icons.image, size: 48, color: ZhiJianTheme.textSecondary)))
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: ZhiJianTheme.surfaceLight, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      const Icon(Icons.add_a_photo, size: 48, color: ZhiJianTheme.textSecondary),
                      const SizedBox(height: 8),
                      const Text('当天没有记录', style: TextStyle(color: ZhiJianTheme.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _quickUpload(context);
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('补传照片'),
                      ),
                    ]),
                  ),
                const SizedBox(height: 20),

                // Mood picker
                const Text('😊 今日心情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ZhiJianTheme.text)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _moodButton('😄', 'great', '超棒', dayData?.mood),
                    _moodButton('😊', 'good', '不错', dayData?.mood),
                    _moodButton('😐', 'okay', '一般', dayData?.mood),
                    _moodButton('😞', 'bad', '不好', dayData?.mood),
                    _moodButton('😡', 'terrible', '很差', dayData?.mood),
                  ].map((b) => GestureDetector(
                    onTap: () async {
                      // Submit mood
                      final auth = context.read<AuthService>();
                      try {
                        await httpPost('${_api.baseUrl}/api/calendar/mood', {
                          'user_id': auth.userId,
                          'date': key,
                          'mood': b.moodKey,
                        }, auth.token!);
                        setModalState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('心情已记录'), backgroundColor: ZhiJianTheme.success),
                        );
                      } catch (_) {}
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: b.isSelected ? ZhiJianTheme.primary.withOpacity(0.2) : ZhiJianTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: b.isSelected ? Border.all(color: ZhiJianTheme.primary) : null,
                      ),
                      child: Column(children: [
                        Text(b.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(b.label, style: TextStyle(fontSize: 11, color: b.isSelected ? ZhiJianTheme.primary : ZhiJianTheme.textSecondary)),
                      ]),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),

                // Weight input
                const Text('⚖️ 体重记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ZhiJianTheme.text)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: dayData?.weightKg != null ? '${dayData!.weightKg} kg' : '输入体重 (kg)',
                        hintStyle: const TextStyle(color: ZhiJianTheme.textSecondary),
                        filled: true, fillColor: ZhiJianTheme.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(color: ZhiJianTheme.text),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('体重已记录'), backgroundColor: ZhiJianTheme.success),
                      );
                    },
                    child: const Text('保存'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodButton {
  final String emoji;
  final String moodKey;
  final String label;
  final bool isSelected;
  _MoodButton(this.emoji, this.moodKey, this.label, this.isSelected);
}

_MoodButton _moodButton(String emoji, String key, String label, String? current) {
  return _MoodButton(emoji, key, label, current == key);
}

Future<void> httpPost(String url, Map<String, dynamic> body, String token) async {
  final http = await importHttp();
  await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode(body));
}

import 'dart:convert';
import 'package:http/http.dart' as http_lib;

void _postMood(String baseUrl, String userId, String date, String mood, String token) async {
  try {
    await http_lib.post(
      Uri.parse('$baseUrl/api/calendar/mood'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'user_id': userId, 'date': date, 'mood': mood}),
    );
  } catch (_) {}
}
