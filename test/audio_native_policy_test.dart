import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression: on David's S22, Do Not Disturb made AudioManager.ringerMode
/// report SILENT, and AudioCues.kt skipped every cue and the music because of
/// it, so the app was silent with media volume up. Sound must only follow
/// media volume and the in-app On/Soft/Mute button.
void main() {
  final src = File(
    'android/app/src/main/kotlin/space/d11s/niceproportions/AudioCues.kt',
  ).readAsStringSync();
  final code = src
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('*') && !l.trimLeft().startsWith('//'))
      .join('\n');

  test('native audio never gates on ringer mode / silent / DND', () {
    expect(code.contains('ringerMode'), isFalse);
    expect(code.contains('RINGER_MODE'), isFalse);
    expect(code.contains('isSilenced'), isFalse);
  });

  test('cues and music use the media stream', () {
    expect(code.contains('USAGE_ASSISTANCE_SONIFICATION'), isFalse);
    expect(RegExp('USAGE_MEDIA').allMatches(code).length, greaterThanOrEqualTo(2));
  });
}
