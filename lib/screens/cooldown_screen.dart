import 'dart:async';

import 'package:flutter/material.dart';

import '../models/content.dart';
import '../widgets/insets.dart';

enum CooldownStage {
  heading,
  headingMove,
  intro,
  slide,
  breathe,
  settle,
  prompt,
}

/// A slow, unhurried cooldown (about three minutes):
/// 0. the exercise heading sits centred, then glides up to the top;
/// 1. the mindfulness cue fades in centred and sits on screen for a few breaths' worth;
/// 2. it glides down to the bottom as the breathing circle fades in;
/// 3. slow breathing — the circle grows over each breath in and shrinks over
///    each breath out, exactly as long as that phase; holds keep its size;
/// 4. a positive prompt that stays until Finish.
/// Floor-readable (nothing under 16sp), silent, and Skip is always there.
class CooldownScreen extends StatefulWidget {
  const CooldownScreen({
    super.key,
    required this.set,
    required this.onFinished,
    this.headingSeconds = 4,
    this.headingMoveSeconds = 3,
    this.introSeconds = 8,
    this.slideSeconds = 4,
    this.settleSeconds = 4,
    this.testMode = false,
  });

  final CooldownSet set;

  /// Called once, by Skip or Finish.
  final VoidCallback onFinished;
  final int headingSeconds;
  final int headingMoveSeconds;
  final int introSeconds;
  final int slideSeconds;
  final int settleSeconds;

  /// Debug-only test mode: breathing starts with 5 s left (last breath).
  final bool testMode;

  /// Seconds before the prompt appears (the prompt then waits for Finish).
  static int secondsToPrompt(
    CooldownSet s, {
    int heading = 4,
    int headingMove = 3,
    int intro = 8,
    int slide = 4,
    int settle = 4,
  }) => heading + headingMove + intro + slide + s.breathingSeconds + settle;

  @override
  State<CooldownScreen> createState() => _CooldownScreenState();
}

class _CooldownScreenState extends State<CooldownScreen>
    with TickerProviderStateMixin {
  static const small = 0.5;

  /// Circle size, 0.5–1.0, driven phase by phase.
  late final AnimationController _circle = AnimationController(
    vsync: this,
    value: small,
    lowerBound: small,
    upperBound: 1.0,
  );

  /// 0 = heading centred; 1 = heading at the top.
  late final AnimationController _heading = AnimationController(vsync: this);

  /// Cue fade-in once the heading has moved up.
  late final AnimationController _cueIn = AnimationController(vsync: this);

  /// 0 = cue centred, circle hidden; 1 = cue at bottom, circle shown.
  late final AnimationController _layout = AnimationController(vsync: this);

  /// 0 = breathing visible; 1 = prompt visible.
  late final AnimationController _outro = AnimationController(vsync: this);

  Timer? _timer;
  CooldownStage _stage = CooldownStage.heading;
  int _round = 0;
  int _step = 0;
  int _left = 0;
  bool _done = false;
  bool _reduceMotion = false;

  CooldownSet get _set => widget.set;
  BreathStep get _current => _set.steps[_step];

  Duration _d(int s) => _reduceMotion ? Duration.zero : Duration(seconds: s);

  @override
  void initState() {
    super.initState();
    _left = widget.headingSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  void _startStep() {
    _left = widget.testMode && _current.seconds > 5 ? 5 : _current.seconds;
    final d = Duration(seconds: _left);
    if (_reduceMotion) return;
    switch (_current.motion) {
      case BreathMotion.breatheIn:
        _circle.animateTo(1.0, duration: d, curve: Curves.easeInOut);
      case BreathMotion.breatheOut:
        _circle.animateTo(small, duration: d, curve: Curves.easeInOut);
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
        case CooldownStage.heading:
          _stage = CooldownStage.headingMove;
          _left = widget.headingMoveSeconds;
          _heading.animateTo(
            1,
            duration: _d(widget.headingMoveSeconds),
            curve: Curves.easeInOutCubic,
          );
        case CooldownStage.headingMove:
          _stage = CooldownStage.intro;
          _left = widget.introSeconds;
          _cueIn.animateTo(1, duration: _d(2), curve: Curves.easeInOut);
        case CooldownStage.intro:
          _stage = CooldownStage.slide;
          _left = widget.slideSeconds;
          _layout.animateTo(
            1,
            duration: _d(widget.slideSeconds),
            curve: Curves.easeInOutCubic,
          );
        case CooldownStage.slide:
          _stage = CooldownStage.breathe;
          if (widget.testMode) {
            // Jump to the final breath, trimmed to 5 s.
            _round = _set.rounds - 1;
            _step = _set.steps.length - 1;
          }
          _startStep();
        case CooldownStage.breathe:
          if (_step < _set.steps.length - 1) {
            _step++;
            _startStep();
          } else if (_round < _set.rounds - 1) {
            _round++;
            _step = 0;
            _startStep();
          } else {
            _stage = CooldownStage.settle;
            _left = widget.settleSeconds;
            _outro.animateTo(
              1,
              duration: _d(widget.settleSeconds),
              curve: Curves.easeInOut,
            );
          }
        case CooldownStage.settle:
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
    _layout.dispose();
    _heading.dispose();
    _cueIn.dispose();
    _outro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final breathing = _stage == CooldownStage.breathe;
    final atPrompt =
        _stage == CooldownStage.settle || _stage == CooldownStage.prompt;

    final cue = Text(
      _set.cue,
      key: const ValueKey('cooldown-cue'),
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooldown'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _layout,
                    _outro,
                    _circle,
                    _heading,
                    _cueIn,
                  ]),
                  builder: (context, _) {
                    final t = _layout.value;
                    final o = _outro.value;
                    return Stack(
                      children: [
                        // Heading: centred, then glides up to the top.
                        Align(
                          alignment: Alignment(0, -_heading.value),
                          child: Text(
                            _set.title,
                            key: const ValueKey('cooldown-title'),
                            textAlign: TextAlign.center,
                            style: TextStyle.lerp(
                              theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              theme.textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                              _heading.value,
                            ),
                          ),
                        ),
                        // Breathing circle + phase label, fading/growing in.
                        Positioned.fill(
                          top: 40,
                          bottom: 120,
                          child: Opacity(
                            opacity: (t * (1 - o)).clamp(0.0, 1.0),
                            child: _breathingPart(theme, breathing),
                          ),
                        ),
                        // The cue: centred, then glides to the bottom.
                        Align(
                          key: const ValueKey('cooldown-cue-align'),
                          alignment: Alignment(0, t),
                          child: Opacity(
                            opacity: (_cueIn.value * (1 - o)).clamp(0.0, 1.0),
                            child: cue,
                          ),
                        ),
                        if (o > 0)
                          Center(
                            child: Opacity(
                              opacity: o,
                              child: _promptPart(theme),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: atPrompt
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

  Widget _breathingPart(ThemeData theme, bool breathing) {
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, c) {
        // Leave room for the two labels under the circle.
        final max = [
          c.maxWidth * 0.8,
          c.maxHeight - 110,
          320.0,
        ].reduce((a, b) => a < b ? a : b).clamp(60.0, 320.0);
        final f = _reduceMotion ? 0.8 : _circle.value;
        // Grow in from slightly smaller while it fades in.
        final grow = 0.85 + 0.15 * _layout.value;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: max,
              height: max,
              child: Center(
                child: Container(
                  key: const ValueKey('breath-circle'),
                  width: max * f * grow,
                  height: max * f * grow,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.22),
                    border: Border.all(color: scheme.primary, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: breathing
                      ? Text(
                          '$_left',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              breathing ? _current.label : _set.steps.first.label,
              key: const ValueKey('cooldown-big'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Breath ${_round + 1} of ${_set.rounds}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
          ],
        );
      },
    );
  }

  Widget _promptPart(ThemeData theme) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        _set.prompt,
        key: const ValueKey('cooldown-prompt'),
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Have a think. No need to answer out loud.\nTake as long as you like.',
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
      ),
    ],
  );
}
