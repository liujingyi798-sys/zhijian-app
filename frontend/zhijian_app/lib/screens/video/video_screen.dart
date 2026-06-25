import 'package:flutter/material.dart';
import '../../config/theme.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key}) : super(key: key);

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedBgm = 'auto';
  bool _isGenerating = false;
  double _renderProgress = 0;

  final List<Map<String, String>> _bgmOptions = [
    {'id': 'auto', 'name': '🤖 AI 智能匹配', 'desc': '根据变化幅度自动选曲'},
    {'id': 'epic', 'name': '⚡️ 史诗高燃', 'desc': '气势磅礴，适合大变化'},
    {'id': 'warm', 'name': '🎵 温暖感性', 'desc': '走心路线，记录点滴'},
    {'id': 'minimal', 'name': '🎹 极简节奏', 'desc': '干净利落，纯粹记录'},
  ];

  // Demo videos
  final List<Map<String, String>> _demoVideos = [
    {
      'title': '30天蜕变',
      'date': '2026-05-25',
      'duration': '18秒',
      'badge': '🔄 稳定进步',
      'status': 'completed',
    },
    {
      'title': '第一个里程碑',
      'date': '2026-05-01',
      'duration': '24秒',
      'badge': '🏆 质变突破',
      'status': 'completed',
    },
    {
      'title': '90天全程回顾',
      'date': '2026-03-27',
      'duration': '42秒',
      'badge': '👑 蜕变之王',
      'status': 'completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎬 蜕变纪念视频',
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
                    '3 个纪念',
                    style: TextStyle(
                      fontSize: 13,
                      color: ZhiJianTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Create new video section
                  _buildCreateSection(),
                  const SizedBox(height: 28),

                  // Render in progress
                  if (_isGenerating) _buildRenderProgress(),

                  // History videos
                  const Text(
                    '历史纪念视频',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ZhiJianTheme.text,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._demoVideos.map((v) => _buildVideoCard(v)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ZhiJianTheme.primary.withOpacity(0.2),
            ZhiJianTheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ZhiJianTheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Text(
                '生成新视频',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ZhiJianTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '选择时间范围，AI 自动对齐每一帧，生成专属于你的蜕变穿梭视频。'
            '骨骼对齐 + 数据动效 + BGM + 荣誉勋章，仪式感拉满。',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: ZhiJianTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          // Date range picker
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: '起始日期',
                  date: _startDate,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: _endDate,
                    );
                    if (d != null) setState(() => _startDate = d);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    color: ZhiJianTheme.textSecondary, size: 20),
              ),
              Expanded(
                child: _DateField(
                  label: '结束日期',
                  date: _endDate,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: _startDate,
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _endDate = d);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Duration estimate
          Text(
            '预计时长：${_endDate.difference(_startDate).inDays} 帧 ≈ ${(_endDate.difference(_startDate).inDays * 0.15).toInt()} 秒',
            style: const TextStyle(
              fontSize: 13,
              color: ZhiJianTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // BGM selection
          const Text(
            '背景音乐',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ZhiJianTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bgmOptions.map((bgm) {
              final selected = _selectedBgm == bgm['id'];
              return ChoiceChip(
                label: Text(bgm['name']!),
                selected: selected,
                onSelected: (_) => setState(() => _selectedBgm = bgm['id']!),
                selectedColor: ZhiJianTheme.primary.withOpacity(0.3),
                backgroundColor: ZhiJianTheme.surfaceLight,
                labelStyle: TextStyle(
                  color: selected
                      ? ZhiJianTheme.primary
                      : ZhiJianTheme.textSecondary,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _startRender,
              icon: const Icon(Icons.auto_awesome, size: 22),
              label: Text(
                _isGenerating ? '渲染中...' : '生成蜕变视频',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    ZhiJianTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenderProgress() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ZhiJianTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZhiJianTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation(ZhiJianTheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI 正在渲染视频...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ZhiJianTheme.text,
                ),
              ),
              const Spacer(),
              Text(
                '${(_renderProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ZhiJianTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _renderProgress,
              minHeight: 6,
              backgroundColor: ZhiJianTheme.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(ZhiJianTheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '正在对齐骨骼关键点并合成渐变过渡... 完成后将推送通知',
            style: TextStyle(fontSize: 12, color: ZhiJianTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, String> video) {
    final completed = video['status'] == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZhiJianTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Thumbnail placeholder
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: ZhiJianTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ZhiJianTheme.primary.withOpacity(0.3),
                  ZhiJianTheme.secondary.withOpacity(0.2),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                completed ? Icons.play_circle_fill : Icons.hourglass_bottom,
                size: 32,
                color: completed
                    ? ZhiJianTheme.text
                    : ZhiJianTheme.textSecondary,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Video info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ZhiJianTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${video['date']} · ${video['duration']}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ZhiJianTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: completed
                        ? ZhiJianTheme.success.withOpacity(0.15)
                        : ZhiJianTheme.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    video['badge']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: completed
                          ? ZhiJianTheme.success
                          : ZhiJianTheme.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (completed)
            Column(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share,
                      color: ZhiJianTheme.primary, size: 22),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.download,
                      color: ZhiJianTheme.textSecondary, size: 22),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _startRender() async {
    setState(() {
      _isGenerating = true;
      _renderProgress = 0;
    });

    // Simulate rendering progress
    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _renderProgress = i / 100);
    }

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _renderProgress = 1.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎉 蜕变视频生成完毕！'),
        backgroundColor: ZhiJianTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ZhiJianTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ZhiJianTheme.textSecondary.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: ZhiJianTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.month}/${date.day}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ZhiJianTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
