import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/content.dart';

class ContentLoader {
  static Future<AppContent> load() async {
    final raw = await rootBundle.loadString('assets/content.json');
    return AppContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// For unit tests that pass a JSON string.
  static AppContent parse(String raw) =>
      AppContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
