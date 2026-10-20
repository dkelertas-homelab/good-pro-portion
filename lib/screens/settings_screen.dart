import 'package:flutter/material.dart';

import '../widgets/sound_button.dart';
import '../widgets/sound_settings.dart';

import '../data/settings_store.dart';
import '../models/content.dart';
import '../monetisation/ads_config.dart';
import '../monetisation/ads_service.dart';
import '../monetisation/remove_ads_card.dart';
import '../widgets/version_text.dart';
import '../widgets/insets.dart';

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
  bool _startCard = true;
  bool _cooldown = false;

  @override
  void initState() {
    super.initState();
    SettingsStore.open().then((s) {
      setState(() {
        _store = s;
        _work = s.workSeconds;
        _rest = s.restSeconds;
        _startCard = s.showStartCard;
        _cooldown = s.cooldownEnabled;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [SoundButton()],
      ),
      body: ListView(
        padding: scrollPadding(
          context,
          const EdgeInsets.fromLTRB(20, 8, 20, 24),
        ),
        children: [
          Text('TIMER', style: Theme.of(context).textTheme.labelSmall),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Work length'),
                  subtitle: const Text('Used for work intervals'),
                  trailing: Text(
                    '${_work}s',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                  trailing: Text(
                    '${_rest}s',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
          Text('SOUND', style: Theme.of(context).textTheme.labelSmall),
          const Card(child: SoundSettings()),
          const SizedBox(height: 14),
          Text('TIPS', style: Theme.of(context).textTheme.labelSmall),
          Card(
            child: SwitchListTile(
              title: const Text('"Before you start" card'),
              subtitle: const Text('A short note when you tap Start'),
              value: _startCard,
              onChanged: _store == null
                  ? null
                  : (v) {
                      _store!.setShowStartCard(v);
                      setState(() => _startCard = v);
                    },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'AFTER A WORKOUT',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Card(
            child: SwitchListTile(
              key: const ValueKey('cooldown-switch'),
              title: const Text('Cooldown'),
              subtitle: const Text(
                'About 2 minutes of slow breathing after a workout',
              ),
              value: _cooldown,
              onChanged: _store == null
                  ? null
                  : (v) {
                      _store!.setCooldownEnabled(v);
                      setState(() => _cooldown = v);
                    },
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
                  subtitle: Text(
                    'Opens Clock with an alarm pre-filled — coming later',
                  ),
                  trailing: Icon(Icons.schedule),
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('UPGRADE', style: Theme.of(context).textTheme.labelSmall),
          const RemoveAdsCard(),
          if (adsEnabled)
            ValueListenableBuilder<bool>(
              valueListenable: AdsService.instance.privacyOptionsRequired,
              builder: (context, required, _) => !required
                  ? const SizedBox.shrink()
                  : Card(
                      child: ListTile(
                        title: const Text('Ad privacy options'),
                        subtitle: const Text('Change your ad consent choice'),
                        trailing: const Icon(Icons.privacy_tip_outlined),
                        onTap: AdsService.instance.showPrivacyOptions,
                      ),
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
          const SizedBox(height: 20),
          const VersionText(),
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
