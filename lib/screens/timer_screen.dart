import 'dart:async';

import 'package:flutter/material.dart';

import '../models/content.dart';
import '../widgets/countdown_ring.dart';
import '../widgets/figure_view.dart';
import 'done_screen.dart';

enum _Phase { warmup, work, rest }

class _Segment {
  _Segment({
    required this.phase,
    required this.move,
    required this.seconds,
    this.label,
  });
  final _Phase phase;
  final Move move;
  final int seconds;
  final String? label;
  String get title => label ?? move.name;
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

class _TimerScreenState extends State<TimerScreen> {
  late final List<_Segment> _segments;
  late final DateTime _startedAt;
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
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  List<_Segment> _buildSegments() {
    final c = widget.content;
    final r = widget.routine;
    final out = <_Segment>[];
    for (final s in r.warmup) {
      out.add(_Segment(
        phase: _Phase.warmup,
        move: c.moveById(s.moveId),
        seconds: r.warmupSeconds,
        label: s.label,
      ));
    }
    for (var i = 0; i < r.work.length; i++) {
      final s = r.work[i];
      out.add(_Segment(
        phase: _Phase.work,
        move: c.moveById(s.moveId),
        seconds: s.workSeconds ?? widget.workSeconds,
        label: s.label,
      ));
      if (i < r.work.length - 1) {
        final next = r.work[i + 1];
        out.add(_Segment(
          phase: _Phase.rest,
          move: c.moveById(next.moveId),
          seconds: widget.restSeconds,
          label: 'Rest → ${next.label ?? c.moveById(next.moveId).name}',
        ));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seg = _segments[_index];
    final progress = _remaining / seg.seconds;
    final next = _index + 1 < _segments.length ? _segments[_index + 1] : null;
    final phaseLabel = switch (seg.phase) {
      _Phase.warmup => 'Warm-up',
      _Phase.work => 'Work',
      _Phase.rest => 'Rest',
    };
    final ringColor = seg.phase == _Phase.rest
        ? const Color(0xFFF59E0B)
        : Theme.of(context).colorScheme.primary;
    final canGoBack = _index > 0;
    final exerciseName =
        seg.phase == _Phase.rest ? 'Catch your breath' : seg.title;

    // No ads on the timer screen (by design).
    return Scaffold(
      appBar: AppBar(
        title: Text(phaseLabel),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'End workout',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                Chip(label: Text(phaseLabel), visualDensity: VisualDensity.compact),
                const Spacer(),
                Text(
                  seg.phase == _Phase.warmup
                      ? 'Warm-up ${_index + 1}/${widget.routine.warmup.length}'
                      : 'Move',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: FigureView(figureKey: seg.move.figure, size: 180)),
            Text(
              exerciseName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            CountdownRing(
              progress: progress,
              label: '$_remaining',
              sublabel: seg.phase == _Phase.rest ? 'rest' : 'seconds',
              color: ringColor,
            ),
            const SizedBox(height: 12),
            if (next != null)
              Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: FigureView(
                      figureKey: next.move.figure,
                      size: 34,
                      padding: const EdgeInsets.all(2),
                    ),
                  ),
                  title: Text(seg.phase == _Phase.rest ? 'Next' : 'Next up',
                      style: Theme.of(context).textTheme.bodySmall),
                  subtitle: Text(
                    next.phase == _Phase.rest
                        ? next.move.name
                        : (next.label ?? next.move.name),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 72,
                  child: canGoBack
                      ? Semantics(
                          label: 'Previous exercise',
                          button: true,
                          child: TextButton(
                            onPressed: _goBack,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: const Size(48, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('‹ Prev'),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Semantics(
                    label: _paused ? 'Resume workout' : 'Pause workout',
                    button: true,
                    child: FilledButton(
                      onPressed: () => setState(() => _paused = !_paused),
                      child: Text(_paused ? 'Resume' : 'Pause'),
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Semantics(
                    label: 'Skip to next exercise',
                    button: true,
                    child: TextButton(
                      onPressed: _advance,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(48, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      child: const Text('Skip ›'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('No ads during the timer',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
