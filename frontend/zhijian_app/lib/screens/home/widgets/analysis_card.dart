import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/index.dart';

class AnalysisCard extends StatefulWidget {
  final ReportModel report;

  const AnalysisCard({Key? key, required this.report}) : super(key: key);

  @override
  State<AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<AnalysisCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final emoji = ZhiJianTheme.personalityEmojis[r.personality] ?? '🔥';

    return AnimatedBuilder(
      animation: _animController,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: Opacity(
          opacity: _fadeAnim.value,
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ZhiJianTheme.surface,
              ZhiJianTheme.surfaceLight,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ZhiJianTheme.primary.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: score + emoji
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '今日变化',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ZhiJianTheme.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '综合评分 ${r.overallScore}/100',
                        style: const TextStyle(
                          fontSize: 13,
                          color: ZhiJianTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _ScoreBadge(score: r.overallScore),
              ],
            ),

            const SizedBox(height: 20),

            // AI Report text
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ZhiJianTheme.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                r.reportText,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: ZhiJianTheme.text,
                ),
              ),
            ),

            // Progress items
            if (r.progressItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('✅ 进步项'),
              const SizedBox(height: 8),
              ...r.progressItems.map((p) => _detailRow(
                    p.label,
                    '+${p.changePct}%',
                    ZhiJianTheme.success,
                  )),
            ],

            // Weakness items
            if (r.weaknessItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('⚠️ 需要关注'),
              const SizedBox(height: 8),
              ...r.weaknessItems.map((w) => _detailRow(
                    w.label,
                    '${w.changePct}%',
                    ZhiJianTheme.warning,
                  )),
            ],

            // Symmetry alerts
            if (r.symmetryAlerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('📐 对称性'),
              const SizedBox(height: 8),
              ...r.symmetryAlerts.map((s) => _detailRow(
                    s.label,
                    '相差 ${s.diffCm}cm',
                    ZhiJianTheme.error,
                  )),
            ],

            // Posture alerts
            if (r.postureAlerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('🧘 体态'),
              const SizedBox(height: 8),
              ...r.postureAlerts.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16,
                            color: ZhiJianTheme.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${p.label}: ${p.recommendation}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: ZhiJianTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ZhiJianTheme.text,
      ),
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: ZhiJianTheme.text)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? ZhiJianTheme.success
        : score >= 60
            ? ZhiJianTheme.primary
            : ZhiJianTheme.error;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
