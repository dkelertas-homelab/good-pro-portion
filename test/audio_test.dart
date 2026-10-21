import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/audio/sound.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/models/content.dart';
import 'package:good_pro_portion/screens/done_screen.dart';
import 'package:good_pro_portion/screens/exercise_screen.dart';
import 'package:good_pro_portion/screens/home_screen.dart';
import 'package:good_pro_portion/screens/meals_screen.dart';
import 'package:good_pro_portion/screens/routine_screen.dart';
import 'package:good_pro_portion/screens/settings_screen.dart';
import 'package:good_pro_portion/screens/timer_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:good_pro_portion/widgets/sound_button.dart';
import 'package:good_pro_portion/widgets/sound_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBackend implements SoundBackend {
  final events = <String>[];
  @override
  Future<void> load(Map<String, String> assets) async =>
      events.add('load ${assets.keys.join(',')}');
  @override
  Future<void> play(String name, double volume) async =>
      events.add('$name@$volume');
  @override
  Future<void> startMusic(String asset, double volume) async =>
      events.add('music@$volume');
  @override
  Future<void> musicVolume(double volume) async =>
      events.add('musicVolume@$volume');
  @override
  Future<void> pauseMusic() async => events.add('pauseMusic');
  @override
  Future<void> resumeMusic() async => events.add('resumeMusic');
  @override
  Future<void> stopMusic() async => events.add('stopMusic');

  List<String> get plays => events
      .where((e) => !e.startsWith('load') && !e.contains('usic'))
      .toList();
}

void main() {
  late FakeBackend fake;
  late AppContent content;

  Future<Sound> freshSound([Map<String, Object> saved = const {}]) async {
    SharedPreferences.setMockInitialValues(saved);
    fake = FakeBackend();
    final s = Sound(backend: fake, enabled: true);
    await s.init(prefs: await SharedPreferences.getInstance());
    Sound.instance = s;
    return s;
  }

  setUp(() {
    content = ContentLoader.parse(
      File('assets/content.json').readAsStringSync(),
    );
  });

  group('settings', () {
    test('default is Soft with music off', () async {
      final s = await freshSound();
      expect(s.level.value, SoundLevel.soft);
      expect(SoundLevel.soft.volume, 0.3);
      expect(s.music.value, isFalse);
      expect(fake.events.first, 'load blip,moveStart,restStart');
    });

    test('cycles On → Soft → Mute → On and saves it', () async {
      SharedPreferences.setMockInitialValues({'sound_level': 'on'});
      final prefs = await SharedPreferences.getInstance();
      final s = Sound(backend: FakeBackend(), enabled: true);
      await s.init(prefs: prefs);
      expect(s.level.value, SoundLevel.on);
      await s.cycleLevel();
      expect(s.level.value, SoundLevel.soft);
      await s.cycleLevel();
      expect(s.level.value, SoundLevel.mute);
      expect(prefs.getString('sound_level'), 'mute');
      await s.cycleLevel();
      expect(s.level.value, SoundLevel.on);

      final again = Sound(backend: FakeBackend(), enabled: true);
      await again.init(prefs: prefs);
      expect(again.level.value, SoundLevel.on);
    });

    test('music switch is saved', () async {
      final s = await freshSound();
      await s.setMusic(true);
      final again = Sound(backend: FakeBackend(), enabled: true);
      await again.init(prefs: await SharedPreferences.getInstance());
      expect(again.music.value, isTrue);
    });

    test('mute plays nothing', () async {
      final s = await freshSound({'sound_level': 'mute'});
      s.play(Cue.blip);
      s.play(Cue.moveStart);
      expect(fake.plays, isEmpty);
    });
  });

  Widget app(Widget home) => MaterialApp(theme: buildLightTheme(), home: home);

  testWidgets('every screen has the sound button', (t) async {
    await freshSound();
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final r = content.routines.first;
    final screens = <Widget>[
      HomeScreen(content: content),
      RoutineScreen(content: content, routine: r),
      ExerciseScreen(move: content.moves.first),
      TimerScreen(
        content: content,
        routine: r,
        workSeconds: 40,
        restSeconds: 20,
      ),
      DoneScreen(content: content, routine: r, elapsed: Duration.zero),
      SettingsScreen(content: content),
      MealsScreen(content: content),
    ];
    for (final s in screens) {
      await t.pumpWidget(app(s));
      await t.pump();
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(SoundButton),
        ),
        findsOneWidget,
        reason: '${s.runtimeType} needs the sound button',
      );
    }
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('sound button cycles and shows the level', (t) async {
    final s = await freshSound();
    await t.pumpWidget(
      app(Scaffold(appBar: AppBar(actions: const [SoundButton()]))),
    );
    expect(find.byIcon(Icons.volume_down), findsOneWidget);
    expect(find.byTooltip('Sound: Soft. Tap for Mute'), findsOneWidget);
    await t.tap(find.byType(SoundButton));
    await t.pump();
    expect(s.level.value, SoundLevel.mute);
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
    await t.tap(find.byType(SoundButton));
    await t.pump();
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
  });

  testWidgets('settings: music switch, off by default, 16sp+ text', (t) async {
    final s = await freshSound();
    await t.pumpWidget(app(Scaffold(body: SoundSettings(sound: s))));
    final sw = find.widgetWithText(SwitchListTile, 'Background music');
    expect(t.widget<SwitchListTile>(sw).value, isFalse);
    await t.tap(sw);
    await t.pump();
    expect(s.music.value, isTrue);
    await t.tap(find.text('On'));
    await t.pump();
    expect(s.level.value, SoundLevel.on);
    for (final e in find.byType(Text).evaluate()) {
      final style = DefaultTextStyle.of(e).style
          .merge((e.widget as Text).style);
      expect(
        style.fontSize,
        greaterThanOrEqualTo(16),
        reason: (e.widget as Text).data,
      );
    }
  });

  group('timer cues', () {
    Future<void> pumpTimer(WidgetTester t) async {
      t.view.physicalSize = const Size(412, 915);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final r = content.routines.firstWhere((r) => r.id == 'day_a');
      await t.pumpWidget(
        app(
          TimerScreen(
            content: content,
            routine: r,
            workSeconds: 10,
            restSeconds: 6,
          ),
        ),
      );
    }

    Future<void> skipToWork(WidgetTester t) async {
      for (var i = 0; i < 20 && find.text('Move 1/8').evaluate().isEmpty; i++) {
        await t.tap(find.text('Skip ›'));
        await t.pump();
      }
    }

    testWidgets('start tone, blips on 3-2-1, then a rest tone', (t) async {
      await freshSound();
      await pumpTimer(t);
      expect(fake.plays, isEmpty, reason: 'no tone after the Start press');
      await skipToWork(t);
      fake.events.clear();
      // 10 s move: nothing until 3 s are left, then three blips.
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(fake.plays, isEmpty);
      for (var i = 0; i < 3; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(fake.plays, ['blip@0.3', 'blip@0.3', 'blip@0.3']);
      await t.pump(const Duration(seconds: 1));
      expect(fake.plays.last, 'restStart@0.3');
      expect(find.text('Rest'), findsWidgets);
      // 6 s rest also counts down, then the next move's tone.
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(fake.plays.skip(4), [
        'blip@0.3',
        'blip@0.3',
        'blip@0.3',
        'moveStart@0.3',
      ]);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('Skip is silent, timer move change still cues', (t) async {
      await freshSound();
      await pumpTimer(t);
      fake.events.clear();
      for (var i = 0; i < 3; i++) {
        await t.tap(find.text('Skip ›'));
        await t.pump();
      }
      expect(fake.plays, isEmpty);
      // Let the current segment run out: its end still plays a tone.
      for (var i = 0; i < 90; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(
        fake.plays.where(
          (p) => p.startsWith('moveStart') || p.startsWith('restStart'),
        ),
        isNotEmpty,
      );
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('Back, Pause and Resume are silent, then and after', (t) async {
      await freshSound();
      await pumpTimer(t);
      await t.tap(find.text('Skip ›'));
      await t.pump();
      await t.tap(find.text('Skip ›'));
      await t.pump();
      fake.events.clear();
      await t.tap(find.text('‹ Prev'));
      await t.pump();
      await t.tap(find.text('Pause'));
      await t.pump();
      await t.tap(find.text('Resume'));
      await t.pump();
      // The moments right after the presses: still nothing (segments are
      // far longer than 2 s, so no timer cue is due yet).
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
      expect(fake.plays, isEmpty);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('buttons and tiles have touch click sounds off', (t) async {
      for (final th in [buildLightTheme(), buildDarkTheme()]) {
        expect(th.textButtonTheme.style!.enableFeedback, isFalse);
        expect(th.filledButtonTheme.style!.enableFeedback, isFalse);
        expect(th.elevatedButtonTheme.style!.enableFeedback, isFalse);
        expect(th.outlinedButtonTheme.style!.enableFeedback, isFalse);
        expect(th.iconButtonTheme.style!.enableFeedback, isFalse);
        expect(th.listTileTheme.enableFeedback, isFalse);
      }
    });

    testWidgets('no blips while paused', (t) async {
      await freshSound();
      await pumpTimer(t);
      await skipToWork(t);
      await t.tap(find.text('Pause'));
      await t.pump();
      fake.events.clear();
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(fake.plays, isEmpty);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('music off by default: none plays', (t) async {
      await freshSound();
      await pumpTimer(t);
      await t.pumpWidget(const SizedBox());
      expect(fake.events.where((e) => e.contains('usic')), isEmpty);
    });

    testWidgets('music on: starts quietly, pauses, stops on leaving', (
      t,
    ) async {
      final s = await freshSound({'background_music': true});
      await pumpTimer(t);
      expect(fake.events, contains('music@${0.3 * Sound.musicShare}'));
      await t.tap(find.text('Pause'));
      await t.pump();
      expect(fake.events.last, 'pauseMusic');
      await t.tap(find.text('Resume'));
      await t.pump();
      expect(fake.events.last, 'resumeMusic');
      await s.setLevel(SoundLevel.mute);
      expect(fake.events.last, 'musicVolume@0.0');
      await t.pumpWidget(const SizedBox());
      expect(fake.events.last, 'stopMusic');
    });
  });

  test('music switch flipped mid-workout starts and stops music', () async {
    final s = await freshSound();
    s.startWorkoutMusic();
    expect(fake.events.where((e) => e.startsWith('music@')), isEmpty);
    await s.setMusic(true);
    expect(fake.events.where((e) => e.startsWith('music@')), hasLength(1));
    await s.setMusic(false);
    expect(fake.events.last, 'stopMusic');
    s.stopWorkoutMusic();
    await s.setMusic(true);
    expect(fake.events.where((e) => e.startsWith('music@')), hasLength(1));
  });

  test('cues play on the media stream, not the system stream', () {
    final kt = File(
      'android/app/src/main/kotlin/space/d11s/niceproportions/AudioCues.kt',
    ).readAsStringSync();
    expect(kt.contains('USAGE_ASSISTANCE_SONIFICATION'), isFalse);
    expect(kt.contains('USAGE_MEDIA'), isTrue);
  });

  test('AUDIO_ENABLED off: silent, no controls', () async {
    final s = Sound(backend: FakeBackend(), enabled: false);
    s.play(Cue.blip);
    s.startWorkoutMusic();
    expect((s.backend as FakeBackend).events, isEmpty);
  });

  testWidgets('AUDIO_ENABLED off hides the sound button and settings', (
    tester,
  ) async {
    final s = Sound(backend: FakeBackend(), enabled: false);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [SoundButton(sound: s)]),
          body: SoundSettings(sound: s),
        ),
      ),
    );
    expect(find.byType(IconButton), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
  });
}
