import 'package:flutter/material.dart';

import '../models/content.dart';
import '../widgets/insets.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key, required this.content});
  final AppContent content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal ideas')),
      body: ListView(
        padding: scrollPadding(
          context,
          const EdgeInsets.fromLTRB(20, 8, 20, 24),
        ),
        children: [
          Text(
            'Eat simple · portion control · not a diet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: 0.5),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No calorie counting. Just sensible hand portions.'),
            ),
          ),
          const SizedBox(height: 8),
          ...content.meals.map(
            (m) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(m.emoji, style: const TextStyle(fontSize: 26)),
                title: Text(
                  m.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(m.portionGuide),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
