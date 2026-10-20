import 'package:flutter/material.dart';

import '../audio/sound.dart';

/// App-bar button that cycles the cue volume: On → Soft → Mute.
class SoundButton extends StatelessWidget {
  const SoundButton({super.key, this.sound});

  final Sound? sound;

  static IconData iconFor(SoundLevel l) => switch (l) {
    SoundLevel.on => Icons.volume_up,
    SoundLevel.soft => Icons.volume_down,
    SoundLevel.mute => Icons.volume_off,
  };

  @override
  Widget build(BuildContext context) {
    final s = sound ?? Sound.instance;
    if (!s.enabled) return const SizedBox.shrink();
    return ValueListenableBuilder<SoundLevel>(
      valueListenable: s.level,
      builder: (context, level, _) => IconButton(
        key: const ValueKey('sound-button'),
        tooltip: 'Sound: ${level.label}. Tap for ${level.next.label}',
        icon: Icon(iconFor(level)),
        onPressed: s.cycleLevel,
      ),
    );
  }
}
