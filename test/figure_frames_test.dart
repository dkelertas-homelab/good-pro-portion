import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:good_pro_portion/widgets/figure_frames.dart';
import 'package:good_pro_portion/widgets/figure_view.dart';

import 'font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final content = ContentLoader.parse(
    File('assets/content.json').readAsStringSync(),
  );

  group('frame data', () {
    test('start, middle, end: no return frames', () {
      const holds = {'plank', 'sidePlank', 'wallSit'};
      for (final e in figureFrames.entries) {
        final seq = e.value;
        final frames = [for (final f in seq) f.frame];
        expect(
          frames.toSet().length,
          frames.length,
          reason: '${e.key} repeats a frame (a return frame)',
        );
        if (holds.contains(e.key)) {
          expect(seq.length, 2, reason: '${e.key} is a hold');
        } else if (e.key == 'armCircles') {
          expect(seq.length, 4, reason: 'four points round the circle');
        } else {
          expect(seq.length, 3, reason: '${e.key}: start, middle, end');
          expect(
            seq.last.ms,
            greaterThan(seq.first.ms),
            reason: '${e.key} holds the end position',
          );
        }
      }
    });

    test('every move has a 2-4 step animation', () {
      for (final m in content.moves) {
        final frames = figureFrames[m.figure];
        expect(frames, isNotNull, reason: '${m.id} has no frames');
        expect(frames!.length, inInclusiveRange(2, 4), reason: m.id);
        expect(
          {for (final f in frames) f.frame}.length,
          greaterThan(1),
          reason: '${m.id} needs at least two different poses',
        );
        for (final f in frames) {
          expect(f.ms, inInclusiveRange(200, 1500), reason: m.id);
        }
      }
    });

    test('split squat feet stay put; reverse lunge steps back', () {
      List<String> feet(String key, int frame) {
        final svg = File(FigureView.frameAsset(key, frame, dark: false))
            .readAsStringSync();
        // Planted-feet floor dashes only appear on the split squat.
        return RegExp(r'y1="186.0"[^>]*')
            .allMatches(svg)
            .map((m) => m.group(0)!)
            .toList();
      }

      final split0 = feet('splitSquat', 0);
      expect(split0, isNotEmpty, reason: 'split squat marks planted feet');
      expect(feet('splitSquat', 1), split0);
      expect(feet('splitSquat', 2), split0);
      for (var f = 0; f < 3; f++) {
        expect(feet('reverseLunge', f), isEmpty);
      }
      expect(
        File(FigureView.frameAsset('reverseLunge', 0, dark: false))
            .readAsStringSync(),
        isNot(
          File(FigureView.frameAsset('splitSquat', 0, dark: false))
              .readAsStringSync(),
        ),
      );
    });

    test('every frame and still exists in light and dark', () {
      for (final e in figureFrames.entries) {
        for (final dark in [false, true]) {
          expect(
            File(FigureView.stillAsset(e.key, dark: dark)).existsSync(),
            isTrue,
            reason: FigureView.stillAsset(e.key, dark: dark),
          );
          for (final f in e.value) {
            final path = FigureView.frameAsset(e.key, f.frame, dark: dark);
            expect(File(path).existsSync(), isTrue, reason: path);
          }
        }
      }
    });

    test('every figure wears the headband', () {
      for (final f in Directory('assets/figures/frames').listSync()) {
        final svg = File(f.path).readAsStringSync();
        expect(svg, contains('clip-path="url(#hb)"'), reason: f.path);
      }
    });
  });

  group('FigureView', () {
    String shownAsset(WidgetTester t) {
      final stack = t.widget<IndexedStack>(find.byType(IndexedStack));
      final child = stack.children[stack.index!] as SvgPicture;
      return (child.bytesLoader as SvgAssetLoader).assetName;
    }

    Widget host({bool animate = true, bool reduceMotion = false}) =>
        MaterialApp(
          theme: buildLightTheme(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Center(
              child: FigureView(figureKey: 'squat', animate: animate),
            ),
          ),
        );

    testWidgets('steps through the frames in order', (t) async {
      await t.pumpWidget(host());
      final seq = figureFrames['squat']!;
      for (var i = 0; i < seq.length * 2; i++) {
        final f = seq[i % seq.length];
        expect(
          shownAsset(t),
          FigureView.frameAsset('squat', f.frame, dark: false),
        );
        await t.pump(Duration(milliseconds: f.ms));
      }
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('holds the still pose with reduce-motion on', (t) async {
      await t.pumpWidget(host(reduceMotion: true));
      expect(find.byType(IndexedStack), findsNothing);
      final pic = t.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        (pic.bytesLoader as SvgAssetLoader).assetName,
        FigureView.stillAsset('squat', dark: false),
      );
      await t.pump(const Duration(seconds: 5));
      expect(find.byType(IndexedStack), findsNothing);
    });

    testWidgets('a still figure never starts a timer', (t) async {
      await t.pumpWidget(host(animate: false));
      expect(find.byType(IndexedStack), findsNothing);
      // pumpAndSettle would time out if anything kept scheduling frames.
      await t.pumpAndSettle();
    });
  });

  group('contact sheet', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    Future<void> sheet(WidgetTester t, {required bool dark}) async {
      const tile = 120.0;
      final keys = figureFrames.keys.toList();
      t.view.physicalSize = Size(4 * (tile + 8) + 16, keys.length * 164.0 + 16);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? buildDarkTheme() : buildLightTheme(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final k in keys) ...[
                    Text(
                      k,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (final f in figureFrames[k]!)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              color: dark
                                  ? AppColors.coralSoft
                                  : AppColors.tealSoft,
                              child: SvgPicture.asset(
                                FigureView.frameAsset(k, f.frame, dark: dark),
                                width: tile,
                                height: tile,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
      // Let flutter_svg decode every frame.
      for (var i = 0; i < 3; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pump();
      }
    }

    testWidgets('light', (t) async {
      await sheet(t, dark: false);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/figure-frames.png'),
      );
    });

    testWidgets('dark', (t) async {
      await sheet(t, dark: true);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/figure-frames-dark.png'),
      );
    });
  });
}
