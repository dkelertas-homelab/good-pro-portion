import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/main.dart';

void main() {
  testWidgets('home lists Day A and Day B', (tester) async {
    final content = ContentLoader.parse(File('assets/content.json').readAsStringSync());
    await tester.pumpWidget(GoodProPortionApp(content: content));
    await tester.pumpAndSettle();

    expect(find.textContaining("G'day"), findsOneWidget);
    expect(find.textContaining('Day A'), findsOneWidget);
    expect(find.textContaining('Day B'), findsOneWidget);
  });
}
