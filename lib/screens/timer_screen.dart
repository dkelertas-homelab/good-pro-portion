import 'dart:async';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../models/content.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_ring.dart';
import '../widgets/figure_view.dart';
import 'done_screen.dart';

enum _Phase { warmup, work, rest }

class _Segment {
  _Segment({
    required this.phase,
    required this.move,
    required this.seconds,
    required this.cue,
    this.label,
    this.mirror = false,
  });
  final _Phase phase;
  final Move move; // for rest: the move coming up next
  final int seconds;
  final String cue;
  final String? label;
  final bool mirror;
  String get moveTitle => label ?? move.name;
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({
    super.key,
    required this.content,
    required this.routine,
    required this.workSeconds,
    required this.restSeconds,
  });

  final AppContent content;
  final Routine routine;
  final int workSeconds;
  final int restSeconds;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  late final List<_Segment> _segments;
  late final DateTime _startedAt;
  late final AnimationController _blink;
  int _index = 0;
  int _remaining = 0;
  bool _paused = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _segments = _buildSegments();
    _remaining = _segments.first.seconds;
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  _Segment _stepSegment(_Phase phase, RoutineStep s, int seconds) {
    final m = widget.content.moveById(s.moveId);
    return _Segment(
      phase: phase,
      move: m,
      seconds: seconds,
      cue: s.cue ?? m.cue,
      label: s.label,
      mirror: s.mirror,
    );
  }

  List<_Segment> _buildSegments() {
    final r = widget.routine;
    final out = <_Segment>[];
    for (final s in r.warmup) {
      out.add(_stepSegment(_Phase.warmup, s, r.warmupSeconds));
    }
    for (var i = 0; i < r.work.length; i++) {
      final s = r.work[i];
      out.add(
        _stepSegment(_Phase.work, s, s.workSeconds ?? widget.workSeconds),
      );
      if (i < r.work.length - 1) {
        out.add(_stepSegment(_Phase.rest, r.work[i + 1], widget.restSeconds));
      }
    }
    return out;
  }

  void _onTick(Timer t) {
    if (_paused) return;
    if (_remaining <= 1) {
      _advance();
    } else {
      setState(() => _remaining -= 1);
    }
  }

  void _advance() {
    if (_index >= _segments.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _index += 1;
      _remaining = _segments[_index].seconds;
    });
  }

  void _goBack() {
    if (_index <= 0) return;
    setState(() {
      _index -= 1;
      _remaining = _segments[_index].seconds;
    });
  }

  void _finish() {
    _ticker?.cancel();
    final elapsed = DateTime.now().difference(_startedAt);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DoneScreen(
          content: widget.content,
          routine: widget.routine,
          elapsed: elapsed,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _blink.dispose();
    super.dispose();
  }

  /// The move that follows the current segment (skipping over the rest,
  /// which already points at it).
  _Segment? get _upNext {
    final seg = _segments[_index];
    if (seg.phase == _Phase.rest) return seg;
    final i = _index + 1;
    return i < _segments.length ? _segments[i] : null;
  }

  @override
  Widget build(BuildContext context) {
    final seg = _segments[_index];
    final next = _upNext;
    final progress = _remaining / seg.seconds;
    // Warm-up has no rests: preview the next move for the last 25%.
    final preview =
        seg.phase == _Phase.warmup &&
        next != null &&
        _remaining * 4 <= seg.seconds;
    final showCard = seg.phase == _Phase.rest || preview;
    final blinking = showCard && _remaining <= 3 && !_paused;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (blinking && !reduceMotion) {
      if (!_blink.isAnimating) _blink.repeat(reverse: true);
    } else if (_blink.isAnimating || _blink.value != 0) {
      _blink.stop();
      _blink.value = 0;
    }

    final ringColor = seg.phase == _Phase.rest
        ? const Color(0xFFF59E0B)
        : Theme.of(context).colorScheme.primary;
    final warmupCount = widget.routine.warmup.length;
    final header = switch (seg.phase) {
      _Phase.warmup => 'Warm-up ${_index + 1}/$warmupCount',
      _Phase.work =>
        'Move ${(_index - warmupCount) ~/ 2 + 1}/${widget.routine.work.length}',
      _Phase.rest => 'Rest',
    };

    // No ads on the timer screen (by design).
    return Scaffold(
      appBar: AppBar(
        title: Text(
          header,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'End workout',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            children: [
              // One layout for work, rest and the warm-up preview: only the
              // area above changes. The countdown ring never moves.
              Expanded(
                child: showCard
                    ? AnimatedBuilder(
                        animation: _blink,
                        builder: (context, _) => _NextUpCard(
                          next: next!,
                          secondsLeft: _remaining,
                          grey: reduceMotion
                              ? (blinking ? 1 : 0)
                              : _blink.value,
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, c) => FigureView(
                                figureKey: seg.move.figure,
                                mirror: seg.mirror,
                                size: (c.biggest.shortestSide - 24)
                                    .clamp(60, 280)
                                    .toDouble(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _BigName(seg.moveTitle),
                          if (seg.cue.isNotEmpty) _Cue(seg.cue),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CountdownRing(
                    key: const ValueKey('countdown'),
                    size: 150,
                    progress: progress,
                    label: '$_remaining',
                    sublabel: seg.phase == _Phase.rest ? 'rest' : 'seconds',
                    color: ringColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: showCard
                        // The card above already shows what's next, so say
                        // what the ring is counting down.
                        ? Text(
                            seg.phase == _Phase.rest ? 'Rest' : seg.moveTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          )
                        : (next != null
                              ? _NextChip(next: next)
                              : const SizedBox.shrink()),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Controls(
                canGoBack: _index > 0,
                paused: _paused,
                onBack: _goBack,
                onPause: () => setState(() => _paused = !_paused),
                onSkip: _advance,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigName extends StatelessWidget {
  const _BigName(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      height: 1.1,
    ),
  );
}

class _Cue extends StatelessWidget {
  const _Cue(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// Small next-up hint during a work move. Coral outline so it never reads
/// as the current exercise.
class _NextChip extends StatelessWidget {
  const _NextChip({required this.next});
  final _Segment next;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Next up: ${next.moveTitle}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.coral, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'NEXT UP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              next.moveTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// NEXT UP · GET READY card for rests and the end of each warm-up move.
/// [grey] 0..1 blends the card to grey for the final-seconds blink.
class _NextUpCard extends StatelessWidget {
  const _NextUpCard({
    required this.next,
    required this.secondsLeft,
    required this.grey,
  });
  final _Segment next;
  final int secondsLeft;
  final double grey;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? AppColors.coralSoft : const Color(0xFFFFF1EC);
    final greyBg = dark ? const Color(0xFF3A3F47) : const Color(0xFFDADDE1);
    final bg = Color.lerp(base, greyBg, grey)!;
    final accent = Color.lerp(AppColors.coral, const Color(0xFF6B7280), grey)!;
    return Semantics(
      liveRegion: true,
      label: 'Next up: ${next.moveTitle}, in $secondsLeft seconds. ${next.cue}',
      excludeSemantics: true,
      child: CustomPaint(
        foregroundPainter: _DashedBorder(color: accent),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: accent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Text(
                  'NEXT UP · GET READY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Opacity(
                    opacity: 0.5,
                    child: LayoutBuilder(
                      builder: (context, c) => FigureView(
                        figureKey: next.move.figure,
                        mirror: next.mirror,
                        padding: const EdgeInsets.all(6),
                        size: (c.biggest.shortestSide - 12)
                            .clamp(40, 200)
                            .toDouble(),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Column(
                  children: [
                    Text(
                      next.moveTitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (next.cue.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          next.cue,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 22, height: 1.2),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'in ${secondsLeft}s',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1.5),
          const Radius.circular(22),
        ),
      );
    for (final PathMetric m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 18) {
        canvas.drawPath(m.extractPath(d, d + 10), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder old) => old.color != color;
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.canGoBack,
    required this.paused,
    required this.onBack,
    required this.onPause,
    required this.onSkip,
  });
  final bool canGoBack;
  final bool paused;
  final VoidCallback onBack;
  final VoidCallback onPause;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final small = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      minimumSize: const Size(48, 48),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: canGoBack
              ? Semantics(
                  label: 'Previous exercise',
                  button: true,
                  excludeSemantics: true,
                  child: TextButton(
                    onPressed: onBack,
                    style: small,
                    child: const Text('‹ Prev'),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: Semantics(
            label: paused ? 'Resume workout' : 'Pause workout',
            button: true,
            excludeSemantics: true,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: onPause,
              child: Text(paused ? 'Resume' : 'Pause'),
            ),
          ),
        ),
        SizedBox(
          width: 80,
          child: Semantics(
            label: 'Skip to next exercise',
            button: true,
            excludeSemantics: true,
            child: TextButton(
              onPressed: onSkip,
              style: small,
              child: const Text('Skip ›'),
            ),
          ),
        ),
      ],
    );
  }
}
