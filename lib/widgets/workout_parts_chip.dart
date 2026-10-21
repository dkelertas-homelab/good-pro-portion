import 'package:flutter/material.dart';

import '../data/settings_store.dart';

/// The four warm-up / cool-down combos, in tap order.
enum WorkoutParts {
  both('Warm-up + cool-down', Icons.check_circle_outline),
  noWarmup('No warm-up', Icons.skip_next),
  noCooldown('No cool-down', Icons.last_page),
  neither('Both off', Icons.block);

  const WorkoutParts(this.label, this.icon);
  final String label;
  final IconData icon;

  bool get warmup => this == both || this == noCooldown;
  bool get cooldown => this == both || this == noWarmup;

  static WorkoutParts of({required bool warmup, required bool cooldown}) =>
      warmup ? (cooldown ? both : noCooldown) : (cooldown ? noWarmup : neither);

  WorkoutParts get next => values[(index + 1) % values.length];
}

/// Tap to cycle warm-up / cool-down. Saved, and shares the cooldown switch
/// with Settings. Silent (no sound on presses).
class WorkoutPartsChip extends StatefulWidget {
  const WorkoutPartsChip({super.key});

  @override
  State<WorkoutPartsChip> createState() => _WorkoutPartsChipState();
}

class _WorkoutPartsChipState extends State<WorkoutPartsChip> {
  SettingsStore? _store;

  @override
  void initState() {
    super.initState();
    SettingsStore.open().then((s) {
      if (mounted) setState(() => _store = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([
        SettingsStore.warmup,
        SettingsStore.cooldown,
      ]),
      builder: (context, _) {
        final parts = WorkoutParts.of(
          warmup: SettingsStore.warmup.value,
          cooldown: SettingsStore.cooldown.value,
        );
        return Semantics(
          button: true,
          label: '${parts.label}. Tap to change',
          excludeSemantics: true,
          child: TextButton.icon(
            key: const ValueKey('workout-parts-chip'),
            onPressed: _store == null
                ? null
                : () {
                    final n = parts.next;
                    _store!.setWarmupEnabled(n.warmup);
                    _store!.setCooldownEnabled(n.cooldown);
                  },
            icon: Icon(parts.icon, size: 20),
            label: Text(parts.label, style: const TextStyle(fontSize: 16)),
            style: TextButton.styleFrom(
              enableFeedback: false,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const StadiumBorder(),
            ),
          ),
        );
      },
    );
  }
}
