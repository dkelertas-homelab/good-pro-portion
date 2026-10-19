import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import 'figure_frames.dart';

/// A stick figure for one move.
///
/// With [animate] on, it steps through the move's key poses (see
/// tool/figures.py). It holds the still pose when reduce-motion is on, when
/// the figure has no frames, or when tickers are muted (e.g. an off-screen
/// page).
class FigureView extends StatefulWidget {
  const FigureView({
    super.key,
    required this.figureKey,
    this.size = 180,
    this.padding = const EdgeInsets.all(12),
    this.mirror = false,
    this.animate = false,
  });

  final String figureKey;
  final double size;
  final EdgeInsets padding;

  /// Flip horizontally, used for the left side of one-sided moves.
  final bool mirror;

  /// Step through the move's frames on a timer.
  final bool animate;

  static String stillAsset(String key, {required bool dark}) =>
      dark ? 'assets/figures/${key}_dark.svg' : 'assets/figures/$key.svg';

  static String frameAsset(String key, int frame, {required bool dark}) =>
      'assets/figures/frames/${key}_$frame${dark ? '_dark' : ''}.svg';

  @override
  State<FigureView> createState() => _FigureViewState();
}

class _FigureViewState extends State<FigureView> {
  Timer? _timer;
  int _step = 0;
  bool _running = false;

  List<FigureFrame> get _frames =>
      figureFrames[widget.figureKey] ?? const <FigureFrame>[];

  bool _shouldRun(BuildContext context) =>
      widget.animate &&
      _frames.length > 1 &&
      TickerMode.valuesOf(context).enabled &&
      !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(FigureView old) {
    super.didUpdateWidget(old);
    if (old.figureKey != widget.figureKey) {
      _step = 0;
      _stop();
    }
    _sync();
  }

  void _sync() {
    final run = _shouldRun(context);
    if (run && !_running) {
      _running = true;
      _schedule();
    } else if (!run && _running) {
      _stop();
    }
  }

  void _schedule() {
    final frames = _frames;
    _timer = Timer(
      Duration(milliseconds: frames[_step % frames.length].ms),
      () {
        if (!mounted) return;
        setState(() => _step = (_step + 1) % frames.length);
        _schedule();
      },
    );
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.coralSoft : AppColors.tealSoft;
    final frames = _frames;
    final size = widget.size;
    Widget svg(String asset) => SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => SizedBox(width: size, height: size),
    );

    final Widget child;
    if (_running) {
      // Every frame stays built so they're all decoded up front: switching
      // frames never flashes an empty placeholder.
      final unique = {for (final f in frames) f.frame}.toList()..sort();
      final shown = frames[_step % frames.length].frame;
      child = IndexedStack(
        index: unique.indexOf(shown),
        sizing: StackFit.passthrough,
        children: [
          for (final f in unique)
            svg(FigureView.frameAsset(widget.figureKey, f, dark: dark)),
        ],
      );
    } else {
      child = svg(FigureView.stillAsset(widget.figureKey, dark: dark));
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: widget.padding,
      alignment: Alignment.center,
      child: Transform.flip(flipX: widget.mirror, child: child),
    );
  }
}
