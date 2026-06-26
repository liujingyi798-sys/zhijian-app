import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../models/index.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'widgets/camera_view.dart';
import 'widgets/analysis_card.dart';
import 'widgets/plan_card.dart';
import 'widgets/personality_picker.dart';

enum HomeState { idle, capturing, uploading, analyzing, done }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  HomeState _state = HomeState.idle;
  Uint8List? _capturedBytes;
  String? _capturedFileName;
  String _photoType = 'front';
  String _personality = 'gym_bro';
  ReportModel? _report;
  PlanModel? _plan;
  double _uploadProgress = 0;

  int _streakDays = 0;
  int _totalDays = 0;

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _scanAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) return;
    try {
      final data = await _api.getMe(auth.token!);
      setState(() {
        _streakDays = data['streak_days'] ?? 0;
        _totalDays = data['total_days'] ?? 0;
      });
    } catch (_) {}
  }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _api.dispose();
    super.dispose();
  }

  void _onPhotoCaptured(Uint8List bytes, String fileName) {
    setState(() {
      _capturedBytes = bytes;
      _capturedFileName = fileName;
      _state = HomeState.uploading;
    });
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    setState(() => _uploadProgress = 0);

    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() {
        _uploadProgress = i / 100;
        if (i < 40) _state = HomeState.uploading;
        else if (i < 100) _state = HomeState.analyzing;
      });
    }

    try {
      if (_capturedBytes != null) {
        // Inject JWT token from auth service
        final auth = context.read<AuthService>();
        _api.authToken = auth.token;

        final response = await _api.uploadPhotoBytes(
          photoBytes: _capturedBytes!,
          fileName: _capturedFileName ?? 'photo.jpg',
          photoType: _photoType,
          personality: _personality,
        );

        setState(() {
          _report = ReportModel.fromJson(response['report'] ?? {});
          _plan = PlanModel.fromJson(response['plan'] ?? {});
          _state = HomeState.done;
        });
        _loadStreakData(); // Refresh streak after successful upload
      }
    } catch (e) {
      setState(() {
        _report = _demoReport();
        _plan = _demoPlan();
        _state = HomeState.done;
      });
    }

    _scanController.forward().then((_) => _scanController.reverse());
  }

  void _onRetake() {
    setState(() {
      _capturedBytes = null;
      _capturedFileName = null;
      _report = null;
      _plan = null;
      _state = HomeState.idle;
      _uploadProgress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildCameraArea(),
                  const SizedBox(height: 16),
                  if (_state == HomeState.idle) _buildAngleSelector(),
                  const SizedBox(height: 16),
                  if (_state == HomeState.uploading || _state == HomeState.analyzing)
                    _buildAnalysisProgress(),
                  if (_state == HomeState.done && _report != null) ...[
                    AnalysisCard(report: _report!),
                    const SizedBox(height: 16),
                  ],
                  if (_state == HomeState.done && _plan != null) ...[
                    PlanCard(plan: _plan!),
                    const SizedBox(height: 16),
                  ],
                  if (_state == HomeState.done)
                    TextButton.icon(
                      onPressed: _onRetake,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新拍摄'),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (_state == HomeState.done)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PersonalityPicker(
                current: _personality,
                onChanged: _onPersonalityChanged,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final today = DateTime.now();
    final dateStr = '${today.year}年${today.month}月${today.day}日';
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[today.weekday - 1];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📸 $dateStr',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ZhiJianTheme.text)),
              const SizedBox(height: 2),
              Text('$weekday · 已坚持 $_streakDays 天 🔥',
                  style: const TextStyle(fontSize: 13, color: ZhiJianTheme.textSecondary)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: ZhiJianTheme.surfaceLight, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.local_fire_department, color: ZhiJianTheme.primary, size: 18),
              const SizedBox(width: 4),
              Text('$_streakDays',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ZhiJianTheme.primary)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
    switch (_state) {
      case HomeState.idle:
        return CameraView(photoType: _photoType, onCapture: _onPhotoCaptured);
      case HomeState.capturing:
      case HomeState.uploading:
      case HomeState.analyzing:
      case HomeState.done:
        if (_capturedBytes != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.memory(_capturedBytes!, height: 320, width: double.infinity, fit: BoxFit.cover),
                if (_state == HomeState.analyzing) _buildScanOverlay(),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
    }
  }

  Widget _buildScanOverlay() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (_, child) {
        return Positioned(
          top: _scanAnimation.value * 300,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, ZhiJianTheme.primary, Colors.transparent]),
              boxShadow: [BoxShadow(color: ZhiJianTheme.primary, blurRadius: 8, spreadRadius: 2)],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAngleSelector() {
    final angles = [
      {'key': 'front', 'label': '正面'},
      {'key': 'side', 'label': '侧面'},
      {'key': 'back', 'label': '背面'},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: angles.map((a) {
        final selected = _photoType == a['key'];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(a['label']!),
            selected: selected,
            onSelected: (_) => setState(() => _photoType = a['key']!),
            selectedColor: ZhiJianTheme.primary.withOpacity(0.3),
            backgroundColor: ZhiJianTheme.surfaceLight,
            labelStyle: TextStyle(
                color: selected ? ZhiJianTheme.primary : ZhiJianTheme.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnalysisProgress() {
    final isAnalyzing = _state == HomeState.analyzing;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ZhiJianTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZhiJianTheme.primary.withOpacity(0.3)),
      ),
      child: Column(children: [
        Icon(isAnalyzing ? Icons.biotech : Icons.cloud_upload_outlined, size: 40, color: ZhiJianTheme.primary),
        const SizedBox(height: 16),
        Text(isAnalyzing ? 'AI 正在分析中...' : '正在上传照片...',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ZhiJianTheme.text)),
        const SizedBox(height: 4),
        Text(isAnalyzing ? '横向对比昨日数据，捕捉每一个微小进步' : '请稍候，照片正在安全传输',
            style: const TextStyle(fontSize: 13, color: ZhiJianTheme.textSecondary)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _uploadProgress, minHeight: 4,
            backgroundColor: ZhiJianTheme.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(ZhiJianTheme.primary),
          ),
        ),
      ]),
    );
  }

  void _onPersonalityChanged(String newPersonality) {
    setState(() => _personality = newPersonality);
    if (_report != null && _report!.altCache.containsKey(newPersonality)) {
      setState(() {
        _report = ReportModel(
          reportId: _report!.reportId, overallScore: _report!.overallScore,
          personality: newPersonality,
          reportText: _report!.altCache[newPersonality] ?? _report!.reportText,
          altCache: _report!.altCache, progressItems: _report!.progressItems,
          weaknessItems: _report!.weaknessItems, symmetryAlerts: _report!.symmetryAlerts,
          postureAlerts: _report!.postureAlerts,
        );
      });
    }
  }

  ReportModel _demoReport() => ReportModel(
    reportId: 'demo', overallScore: 76, personality: _personality,
    reportText: '🔥 家人们谁懂啊！！今天的肩膀分离度直接拉满了好吗！！\n\n✓ 三角肌分离度 +3.2%\n✓ 腹肌线条清晰度提升\n⚠ 后侧链需要加强\n\n💪 干就完了！',
    altCache: {
      'strict_pro': '肩部分离度改善3.2%。后侧链进展滞后，增加面拉容量。修正方案见明日计划。',
      'cute_cheerleader': '哥哥今天也超棒的呢！(๑•̀ㅂ•́)و✧ 肩膀线条比昨天更明显了！我们一起加油吧！',
    },
    progressItems: [
      AnalysisItem(bodyPart: 'shoulders', label: '三角肌', changePct: 3.2, confidence: 0.87, direction: 'improved'),
      AnalysisItem(bodyPart: 'abs', label: '腹肌', changePct: 1.8, confidence: 0.76, direction: 'improved'),
    ],
    weaknessItems: [
      AnalysisItem(bodyPart: 'posterior_chain', label: '后侧链', changePct: -1.1, confidence: 0.72, direction: 'declined'),
    ],
  );

  PlanModel _demoPlan() => PlanModel(
    planId: 'demo', planDate: DateTime.now().toIso8601String().split('T').first,
    exercises: [
      ExerciseModel(name: '面拉', targetMuscle: '后束/肩袖', sets: 4, reps: '15', sortOrder: 0, notes: '⭐ 弱项优先！外旋肩膀'),
      ExerciseModel(name: '杠铃深蹲', targetMuscle: '股四头肌', sets: 4, reps: '8-12', sortOrder: 1, notes: '核心收紧'),
      ExerciseModel(name: '上斜哑铃卧推', targetMuscle: '上胸', sets: 4, reps: '8-12', sortOrder: 2, notes: '30°斜板'),
      ExerciseModel(name: '引体向上', targetMuscle: '背阔', sets: 4, reps: '8-10', sortOrder: 3, notes: '控制下放'),
      ExerciseModel(name: '哑铃侧平举', targetMuscle: '中束', sets: 3, reps: '12-15', sortOrder: 4, notes: '控制离心'),
      ExerciseModel(name: '罗马尼亚硬拉', targetMuscle: '腘绳肌', sets: 3, reps: '10-12', sortOrder: 5, notes: '髋部主导'),
    ],
    notes: '干就完了！后侧链是今天的重点，面拉放在第一个做！',
  );
}
