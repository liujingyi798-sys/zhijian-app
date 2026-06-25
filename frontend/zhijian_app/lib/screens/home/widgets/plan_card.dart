import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/index.dart';

class PlanCard extends StatelessWidget {
  final PlanModel plan;

  const PlanCard({Key? key, required this.plan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ZhiJianTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ZhiJianTheme.secondary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '明日训练计划',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ZhiJianTheme.text,
                      ),
                    ),
                    if (plan.notes.isNotEmpty)
                      Text(
                        plan.notes,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ZhiJianTheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.fitness_center,
                  color: ZhiJianTheme.textSecondary),
            ],
          ),

          const SizedBox(height: 16),

          // Exercise list
          ...plan.exercises.map((ex) => _ExerciseTile(exercise: ex)),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('微调计划'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ZhiJianTheme.textSecondary,
                    side: const BorderSide(color: ZhiJianTheme.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('开始训练'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatefulWidget {
  final ExerciseModel exercise;
  const _ExerciseTile({required this.exercise});

  @override
  State<_ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<_ExerciseTile> {
  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final isPriority = ex.notes.contains('⭐');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPriority
            ? ZhiJianTheme.primary.withOpacity(0.08)
            : ZhiJianTheme.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: isPriority
            ? Border.all(color: ZhiJianTheme.primary.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => setState(() => ex.isCompleted = !ex.isCompleted),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ex.isCompleted
                    ? ZhiJianTheme.success
                    : Colors.transparent,
                border: Border.all(
                  color: ex.isCompleted
                      ? ZhiJianTheme.success
                      : ZhiJianTheme.textSecondary,
                  width: 2,
                ),
              ),
              child: ex.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ex.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ex.isCompleted
                            ? ZhiJianTheme.textSecondary
                            : ZhiJianTheme.text,
                        decoration: ex.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (isPriority) ...[
                      const SizedBox(width: 6),
                      const Text('⭐', style: TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ex.notes.replaceAll('⭐ 弱项优先！', ''),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ZhiJianTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Sets × reps
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ZhiJianTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${ex.sets}×${ex.reps}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ZhiJianTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
