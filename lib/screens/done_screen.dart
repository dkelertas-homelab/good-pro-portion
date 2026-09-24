import 'package:flutter/material.dart';

import '../models/content.dart';

class DoneScreen extends StatelessWidget {
  const DoneScreen({
    super.key,
    required this.content,
    required this.routine,
    required this.elapsed,
  });

  final AppContent content;
  final Routine routine;
  final Duration elapsed;

  String get _timeLabel {
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final meal = content.meals.first;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Done'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Icon(Icons.check_circle, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text('Nice one!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text('${routine.name} sorted.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Stat(value: _timeLabel, label: 'time')),
              const SizedBox(width: 10),
              const Expanded(child: _Stat(value: '—', label: 'day streak')),
            ],
          ),
          const SizedBox(height: 18),
          Text('MEAL IDEA · EAT SIMPLE', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${meal.emoji}  ${meal.title}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Grab-and-go friendly. Not a diet plan.',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PORTION GUIDE', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Text(meal.portionGuide),
                        const SizedBox(height: 6),
                        Text('✋ palm · ✊ fist · 🤲 cupped · 👍 thumb',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // TODO(Phase 6): optional post-workout ad slot.
          Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: const Text('Ad placeholder'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back home'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    )),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
