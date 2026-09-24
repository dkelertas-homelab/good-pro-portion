import 'dart:io';

import 'package:flutter/services.dart';

Future<void> loadAppFonts() async {
  final loader = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  await loader.load();

  // MaterialIcons ship with the Flutter SDK; load for goldens so Icons.* aren't boxes.
  final candidates = [
    '${Platform.environment['FLUTTER_ROOT'] ?? ''}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    '/workspace/tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ];
  for (final path in candidates) {
    final f = File(path);
    if (f.existsSync()) {
      final bytes = ByteData.view(f.readAsBytesSync().buffer);
      final icons = FontLoader('MaterialIcons')..addFont(Future.value(bytes));
      await icons.load();
      break;
    }
  }
}

Future<void> precacheSvgs(List<String> assets) async {
  for (final a in assets) {
    await rootBundle.load(a);
  }
}
