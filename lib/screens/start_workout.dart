import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../models/content.dart';
import '../widgets/start_card.dart';
import 'timer_screen.dart';

/// Starts [routine]: shows the "Before you start" card if it's still on,
/// then opens the timer. [replace] swaps out the current screen (used from
/// the done screen so Back doesn't return to the finished workout).
Future<void> startWorkout(
  BuildContext context,
  AppContent content,
  Routine routine, {
  bool replace = false,
}) async {
  final store = await SettingsStore.open();
  if (!context.mounted) return;
  if (store.showStartCard) {
    final go = await showStartCard(context, store);
    if (!go || !context.mounted) return;
  }
  final route = MaterialPageRoute<void>(
    builder: (_) => TimerScreen(
      content: content,
      routine: routine,
      workSeconds: store.workSeconds,
      restSeconds: store.restSeconds,
    ),
  );
  final nav = Navigator.of(context);
  await (replace ? nav.pushReplacement(route) : nav.push(route));
}
