import 'package:flutter/material.dart';

import '../models/content.dart';
import '../widgets/figure_view.dart';
import '../widgets/insets.dart';
import '../widgets/swap_sides_badge.dart';

/// One page in the exercise pager: a move as it appears in a routine.
class ExerciseEntry {
  const ExerciseEntry({
    required this.move,
    String? label,
    this.swapSides = false,
  }) : label = label ?? '';

  final Move move;
  final String label;

  /// Second side of a one-sided move: show "Swap sides" (the figure is
  /// drawn for the right side only and is never mirrored).
  final bool swapSides;

  String get title => label.isEmpty ? move.name : label;
}

/// Exercise instructions. Swipe left and right (or use Previous / Next) to
/// move through [entries] without going back to the list (issue #25).
class ExerciseScreen extends StatefulWidget {
  ExerciseScreen({super.key, required Move move})
    : entries = [ExerciseEntry(move: move)],
      initialIndex = 0;

  const ExerciseScreen.pager({
    super.key,
    required this.entries,
    this.initialIndex = 0,
  });

  final List<ExerciseEntry> entries;
  final int initialIndex;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  late final PageController _pages;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.entries.length - 1);
    _pages = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _pages.jumpToPage(i);
    } else {
      _pages.animateToPage(
        i,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final many = entries.length > 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(entries[_index].title),
        actions: [
          if (many)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_index + 1} / ${entries.length}',
                  semanticsLabel: 'Move ${_index + 1} of ${entries.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: entries.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => _ExerciseDetail(entry: entries[i]),
      ),
      bottomNavigationBar: many
          ? BottomBar(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _index > 0 ? () => _go(_index - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Previous'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _index < entries.length - 1
                        ? () => _go(_index + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Next'),
                    iconAlignment: IconAlignment.end,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _ExerciseDetail extends StatelessWidget {
  const _ExerciseDetail({required this.entry});
  final ExerciseEntry entry;

  @override
  Widget build(BuildContext context) {
    final move = entry.move;
    return ListView(
      padding: scrollPadding(context, const EdgeInsets.fromLTRB(20, 8, 20, 24)),
      children: [
        FigureView(figureKey: move.figure, size: 200, animate: true),
        const SizedBox(height: 16),
        if (entry.swapSides)
          const Align(alignment: Alignment.centerLeft, child: SwapSidesBadge()),
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
