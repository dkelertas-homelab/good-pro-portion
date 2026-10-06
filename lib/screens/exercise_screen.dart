import 'package:flutter/material.dart';

import '../models/content.dart';
import '../widgets/figure_view.dart';
import '../widgets/insets.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key, required this.move});
  final Move move;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(move.name)),
      body: ListView(
        padding: scrollPadding(
          context,
          const EdgeInsets.fromLTRB(20, 8, 20, 24),
        ),
        children: [
          FigureView(figureKey: move.figure, size: 200),
          const SizedBox(height: 16),
          Text('HOW TO', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(move.howTo, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 14),
          Card(
            color: Theme.of(context).colorScheme.errorContainer
                .withValues(alpha: 0.45),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMMON MISTAKES',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 4),
                  Text(move.mistakes),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModCard(title: 'Easier', body: move.easier),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModCard(title: 'Harder', body: move.harder),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModCard extends StatelessWidget {
  const _ModCard({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(title),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 6),
            Text(body, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
