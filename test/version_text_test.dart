import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/widgets/version_text.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('shows the installed version and build number', (t) async {
    PackageInfo.setMockInitialValues(
      appName: 'Nice Pro Portions',
      packageName: 'space.d11s.niceproportions',
      version: '0.1.3',
      buildNumber: '4',
      buildSignature: '',
    );
    VersionText.resetCache();
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: VersionText())));
    await t.pumpAndSettle();
    expect(find.text('Version 0.1.3 (4)'), findsOneWidget);
  });
}
