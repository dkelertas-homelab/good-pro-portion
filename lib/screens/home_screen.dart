import 'package:flutter/material.dart';

import '../models/content.dart';
import '../widgets/figure_view.dart';
import 'routine_screen.dart';
import 'meals_screen.dart';
import 'settings_screen.dart';
import '../widgets/insets.dart';
import '../widgets/version_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.content});
  final AppContent content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(content.appName),
        actions: [
          IconButton(
            tooltip: 'Meal ideas',
            icon: const Icon(Icons.restaurant_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MealsScreen(content: content)),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsScreen(content: content)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: scrollPadding(context, const EdgeInsets.fromLTRB(20, 8, 20, 24)),
        children: [
          Text("G'day — ready for a quick one?",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Short home sessions. No gear. No fuss.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const SizedBox(height: 20),
          Text('PICK A ROUTINE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const SizedBox(height: 8),
          ...content.routines.map((r) {
            final fig = content.moveById(r.work.first.moveId).figure;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: SizedBox(
                  width: 52,
                  height: 52,
                  child: FigureView(figureKey: fig, size: 44, padding: const EdgeInsets.all(4)),
                ),
                title: Text(r.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('~${r.approxMinutes} min · ${r.subtitle.split('·').last.trim()}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RoutineScreen(content: content, routine: r),
                  ),
                ),
              ),
            );
          }),
          Opacity(
            opacity: 0.45,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.more_horiz),
                title: const Text('More routines', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Coming soon'),
                trailing: Chip(
                  label: const Text('Soon'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(value: '—', label: 'day streak')),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(value: '—', label: 'sessions')),
            ],
          ),
          const SizedBox(height: 16),
          // TODO(Phase 6): AdMob banner — never on the timer screen.
          Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                style: BorderStyle.solid,
              ),
            ),
            child: Text('Ad placeholder',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ),
          const SizedBox(height: 16),
          const VersionText(prefix: 'v'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
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
