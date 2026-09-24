import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../models/content.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.content});
  final AppContent content;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsStore? _store;
  int _work = 40;
  int _rest = 20;

  @override
  void initState() {
    super.initState();
    SettingsStore.open().then((s) {
      setState(() {
        _store = s;
        _work = s.workSeconds;
        _rest = s.restSeconds;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('TIMER', style: Theme.of(context).textTheme.labelSmall),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Work length'),
                  subtitle: const Text('Used for work intervals'),
                  trailing: Text('${_work}s',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      )),
                  onTap: () => _pickSeconds(
                    title: 'Work length',
                    current: _work,
                    onSave: (v) async {
                      await _store?.setWorkSeconds(v);
                      setState(() => _work = v);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Rest length'),
                  trailing: Text('${_rest}s',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      )),
                  onTap: () => _pickSeconds(
                    title: 'Rest length',
                    current: _rest,
                    onSave: (v) async {
                      await _store?.setRestSeconds(v);
                      setState(() => _rest = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('REMINDERS', style: Theme.of(context).textTheme.labelSmall),
          Card(
            child: Column(
              children: [
                // TODO(Phase 3): local scheduled notifications.
                SwitchListTile(
                  title: const Text('Workout reminders'),
                  subtitle: const Text('Coming in a later build'),
                  value: false,
                  onChanged: null,
                ),
                const ListTile(
                  title: Text('Also add to my Clock app'),
                  subtitle: Text('Opens Clock with an alarm pre-filled — coming later'),
                  trailing: Icon(Icons.schedule),
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('UPGRADE', style: Theme.of(context).textTheme.labelSmall),
          // TODO(Phase 7): Play Billing one-off Remove ads IAP.
          Card(
            child: ListTile(
              leading: const Text('✨', style: TextStyle(fontSize: 22)),
              title: const Text('Remove ads'),
              subtitle: const Text('One-off purchase · no subscription (coming later)'),
              trailing: Text('A\$X.XX',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  )),
              enabled: false,
            ),
          ),
          const SizedBox(height: 14),
          Text('LEGAL', style: Theme.of(context).textTheme.labelSmall),
          Card(
            child: Column(
              children: [
                const ListTile(
                  title: Text('Privacy policy'),
                  subtitle: Text('Hosted page coming before Play release'),
                  trailing: Icon(Icons.chevron_right),
                  enabled: false,
                ),
                ListTile(
                  title: const Text('Health disclaimer'),
                  subtitle: Text(
                    'Check with a doctor before starting. Stop if you feel pain.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSeconds({
    required String title,
    required int current,
    required Future<void> Function(int) onSave,
  }) async {
    final options = [20, 30, 40, 45, 50, 60];
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...options.map(
              (s) => ListTile(
                title: Text('${s}s'),
                trailing: s == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen != null) await onSave(chosen);
  }
}
