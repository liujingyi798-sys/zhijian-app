import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class PersonalityPicker extends StatelessWidget {
  final String current;
  final void Function(String personality) onChanged;

  const PersonalityPicker({
    Key? key,
    required this.current,
    required this.onChanged,
  }) : super(key: key);

  static const List<Map<String, String>> _personalities = [
    {'key': 'strict_pro', 'name': '毒舌', 'emoji': '🗿'},
    {'key': 'gym_bro', 'name': '热血', 'emoji': '🔥'},
    {'key': 'cute_cheerleader', 'name': '萌系', 'emoji': '✨'},
    {'key': 'playful_tsundere', 'name': '傲娇', 'emoji': '😤'},
    {'key': 'innocent_rookie', 'name': '小白', 'emoji': '🌱'},
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ZhiJianTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ZhiJianTheme.primary.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentEmoji(),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 6),
            Text(
              '${_currentName()} · 教练',
              style: const TextStyle(
                fontSize: 13,
                color: ZhiJianTheme.text,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.swap_horiz,
              size: 16,
              color: ZhiJianTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  String _currentName() {
    final found = _personalities.firstWhere(
      (p) => p['key'] == current,
      orElse: () => _personalities[1],
    );
    return found['name']!;
  }

  String _currentEmoji() {
    final found = _personalities.firstWhere(
      (p) => p['key'] == current,
      orElse: () => _personalities[1],
    );
    return found['emoji']!;
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ZhiJianTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '切换 AI 教练人格',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ZhiJianTheme.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '同一份分析数据，不同的表达方式。选一个你喜欢的教练！',
                style: TextStyle(
                  fontSize: 13,
                  color: ZhiJianTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Personality list
              ..._personalities.map((p) {
                final selected = p['key'] == current;
                return GestureDetector(
                  onTap: () {
                    onChanged(p['key']!);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? ZhiJianTheme.primary.withOpacity(0.1)
                          : ZhiJianTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: selected
                          ? Border.all(color: ZhiJianTheme.primary, width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Text(p['emoji']!, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p['name']}教练',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? ZhiJianTheme.primary
                                      : ZhiJianTheme.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _description(p['key']!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ZhiJianTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle,
                              color: ZhiJianTheme.primary),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _description(String key) {
    const desc = {
      'strict_pro': '话少、客观、一针见血，用真实让你变强',
      'gym_bro': '极度亢奋、满口健身梗，每个进步都是史诗级',
      'cute_cheerleader': '崇拜式语气 + 颜文字攻击，治愈每一个训练日',
      'playful_tsundere': '嘴硬心软，表面嫌弃背地里超在意你',
      'innocent_rookie': '谦逊诚恳，做你一起进步的对等搭子',
    };
    return desc[key] ?? '';
  }
}
