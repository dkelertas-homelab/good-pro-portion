import 'package:flutter/material.dart';

import '../models/content.dart';
import '../widgets/figure_view.dart';
import 'exercise_screen.dart';
import 'start_workout.dart';
import '../widgets/insets.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({
    super.key,
    required this.content,
    required this.routine,
  });
  final AppContent content;
  final Routine routine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routine.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Chip(
                label: const Text('No cool-down'),
                visualDensity: VisualDensity.compact,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: scrollPadding(
                context,
                const EdgeInsets.fromLTRB(20, 0, 20, 12),
              ),
              children: [
                Text(
                  routine.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '~${routine.approxMinutes} min · example',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _SectionHeader(
                  title: 'Warm-up · 2 min',
                  trailing: '${routine.warmupSeconds}s each',
                ),
                ...routine.warmup.map((s) {
                  final m = content.moveById(s.moveId);
                  return _MoveTile(
                    move: m,
                    label: s.label ?? m.name,
                    seconds: routine.warmupSeconds,
                    onTap: () => _openDetail(context, m),
                  );
                }),
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'Work · ${routine.work.length} moves',
                  trailing: '${routine.workSeconds}s / ${routine.restSeconds}s',
                ),
                ...routine.work.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  final m = content.moveById(s.moveId);
                  return _MoveTile(
                    move: m,
                    label: '${i + 1}. ${s.label ?? m.name}',
                    mirror: s.mirror,
                    seconds: s.workSeconds ?? routine.workSeconds,
                    onTap: () => _openDetail(context, m),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: FilledButton(
          onPressed: () => startWorkout(context, content, routine),
          child: Text('Start · ~${routine.approxMinutes} min'),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Move m) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ExerciseScreen(move: m)));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});
  final String title;
  final String trailing;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(trailing, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MoveTile extends StatelessWidget {
  const _MoveTile({
    required this.move,
    required this.label,
    required this.seconds,
    required this.onTap,
    this.mirror = false,
  });
  final Move move;
  final bool mirror;
  final String label;
  final int seconds;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 40,
        height: 40,
        child: FigureView(
          figureKey: move.figure,
          size: 34,
          padding: const EdgeInsets.all(2),
          mirror: mirror,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: move.textOnly ? const Text('Text-only step') : null,
      trailing: Text(
        '${seconds}s',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }
}
