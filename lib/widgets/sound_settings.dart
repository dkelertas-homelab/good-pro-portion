import 'package:flutter/material.dart';

import '../audio/sound.dart';

/// Settings → Sound: cue volume (same as the app-bar button) and the
/// optional background music, off by default.
class SoundSettings extends StatelessWidget {
  const SoundSettings({super.key, this.sound});

  final Sound? sound;

  static const _big = TextStyle(fontSize: 16);

  @override
  Widget build(BuildContext context) {
    final s = sound ?? Sound.instance;
    return Column(
      children: [
        ListTile(
          title: const Text('Workout sounds', style: _big),
          subtitle: const Text(
            'Beeps for the last 3 seconds, a tone when each move and rest starts',
            style: _big,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ValueListenableBuilder<SoundLevel>(
            valueListenable: s.level,
            builder: (context, level, _) => SegmentedButton<SoundLevel>(
              segments: [
                for (final l in SoundLevel.values)
                  ButtonSegment(
                    value: l,
                    label: Text(l.label, style: _big),
                    icon: Icon(switch (l) {
                      SoundLevel.on => Icons.volume_up,
                      SoundLevel.soft => Icons.volume_down,
                      SoundLevel.mute => Icons.volume_off,
                    }),
                  ),
              ],
              selected: {level},
              onSelectionChanged: (v) => s.setLevel(v.first),
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: s.music,
          builder: (context, on, _) => SwitchListTile(
            title: const Text('Background music', style: _big),
            subtitle: const Text(
              'A simple gentle loop during workouts',
              style: _big,
            ),
            value: on,
            onChanged: s.setMusic,
          ),
        ),
      ],
    );
  }
}
