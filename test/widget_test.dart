import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('app smoke', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Good Pro Portion'))));
    expect(find.text('Good Pro Portion'), findsOneWidget);
  });
}
