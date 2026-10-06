import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import 'figure_view.dart';

/// "Before you start" note shown when a workout is started, until the user
/// ticks "Don't show this again" (see docs/GUIDE.md, Tips and prompts).
/// Returns true to start the workout, false if dismissed.
Future<bool> showStartCard(BuildContext context, SettingsStore store) async {
  var hide = false;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        icon: const SizedBox(
          width: 72,
          height: 72,
          child: FigureView(
            figureKey: 'march',
            size: 56,
            padding: EdgeInsets.all(4),
          ),
        ),
        title: const Text(
          'Before you start',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Don't worry about getting everything right — you'll get "
              'familiar with the moves over time.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, height: 1.35),
            ),
            const SizedBox(height: 12),
            const Text(
              "It's just great you're doing this.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: hide,
              onChanged: (v) => setLocal(() => hide = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Don't show this again",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Let's go"),
            ),
          ),
        ],
      ),
    ),
  );
  if (go == true && hide) await store.setShowStartCard(false);
  return go == true;
}
