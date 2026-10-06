import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// "Version 0.1.3 (4)", so testers can tell whether a Play update landed.
/// Shows nothing if the platform can't report it (e.g. in some tests).
class VersionText extends StatelessWidget {
  const VersionText({super.key, this.prefix = 'Version '});

  final String prefix;

  static Future<String?>? _cached;

  static Future<String?> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version} (${info.buildNumber})';
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static void resetCache() => _cached = null;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _cached ??= _load(),
      builder: (context, snap) {
        final v = snap.data;
        if (v == null) return const SizedBox.shrink();
        return Text(
          '$prefix$v',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}
