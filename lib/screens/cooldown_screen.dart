import 'dart:async';

import 'package:flutter/material.dart';

import '../models/content.dart';
import '../widgets/insets.dart';

enum CooldownStage { breathe, cue, prompt }

/// About two minutes after a workout: slow breathing with a growing and
/// shrinking circle, a short mindfulness cue, then a positive prompt.
/// Floor-readable (nothing under 16sp), silent, and Skip is always there.
class CooldownScreen extends StatefulWidget {
  const CooldownScreen({
    super.key,
    required this.set,
    required this.onFinished,
    this.cueSeconds = 30,
  });

  final CooldownSet set;

  /// Called once, by Skip, Finish, or when the user leaves the prompt.
  final VoidCallback onFinished;
  final int cueSeconds;

  @override
  State<CooldownScreen> createState() => _CooldownScreenState();
}

class _CooldownScreenState extends State<CooldownScreen>
    with SingleTickerProviderStateMixin {
  static const _small = 0.55;

  late final AnimationController _circle = AnimationController(
    vsync: this,
    value: _small,
    lowerBound: _small,
    upperBound: 1.0,
  );
  Timer? _timer;
  CooldownStage _stage = CooldownStage.breathe;
  int _round = 0;
  int _step = 0;
  int _left = 0;
  bool _done = false;

  CooldownSet get _set => widget.set;
  BreathStep get _current => _set.steps[_step];

  @override
  void initState() {
    super.initState();
    _startStep();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _startStep() {
    _left = _current.seconds;
    final d = Duration(seconds: _current.seconds);
    switch (_current.motion) {
      case BreathMotion.breatheIn:
        _circle.animateTo(1.0, duration: d, curve: Curves.easeInOut);
      case BreathMotion.breatheOut:
        _circle.animateTo(_small, duration: d, curve: Curves.easeInOut);
      case BreathMotion.hold:
        _circle.stop();
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _left--;
      if (_left > 0) return;
      switch (_stage) {
        case CooldownStage.breathe:
          if (_step < _set.steps.length - 1) {
            _step++;
            _startStep();
          } else if (_round < _set.rounds - 1) {
            _round++;
            _step = 0;
            _startStep();
          } else {
            _stage = CooldownStage.cue;
            _left = widget.cueSeconds;
            _circle.animateTo(0.75, duration: const Duration(seconds: 3));
          }
        case CooldownStage.cue:
          _stage = CooldownStage.prompt;
          _timer?.cancel();
        case CooldownStage.prompt:
          break;
      }
    });
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _timer?.cancel();
    widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final (String big, String small) = switch (_stage) {
      CooldownStage.breathe => (
        _current.label,
        '${_set.cue}\nBreath ${_round + 1} of ${_set.rounds}',
      ),
      CooldownStage.cue => (_set.cue, 'Stay here a moment.'),
      CooldownStage.prompt => (
        _set.prompt,
        'Have a think. No need to answer out loud.',
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooldown'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(
            children: [
              Text(
                _set.title,
                key: const ValueKey('cooldown-title'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final max = (c.biggest.shortestSide * 0.85).clamp(
                        120.0,
                        320.0,
                      );
                      return AnimatedBuilder(
                        animation: _circle,
                        builder: (context, _) {
                          final f = reduceMotion ? 0.8 : _circle.value;
                          return Container(
                            key: const ValueKey('breath-circle'),
                            width: max * f,
                            height: max * f,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primary.withValues(alpha: 0.22),
                              border: Border.all(
                                color: scheme.primary,
                                width: 4,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: _stage == CooldownStage.breathe
                                ? Text(
                                    '$_left',
                                    style: theme.textTheme.displaySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: scheme.primary,
                                        ),
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              Text(
                big,
                key: const ValueKey('cooldown-big'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                small,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: _stage == CooldownStage.prompt
            ? FilledButton(
                key: const ValueKey('cooldown-finish'),
                onPressed: _finish,
                child: const Text('Finish', style: TextStyle(fontSize: 18)),
              )
            : OutlinedButton(
                key: const ValueKey('cooldown-skip'),
                onPressed: _finish,
                child: const Text('Skip', style: TextStyle(fontSize: 18)),
              ),
      ),
    );
  }
}
