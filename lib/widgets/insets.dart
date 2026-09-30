import 'package:flutter/material.dart';

/// Edge-to-edge is forced from targetSdk 35, so the system nav bar draws over
/// the app. Two rules keep content clear of it without double padding:
///
/// 1. Scrollables add the *remaining* bottom inset to their own padding.
///    MediaQuery.paddingOf is already zero when a Scaffold bottomNavigationBar
///    has taken the inset, so this never pads twice.
/// 2. Bottom bars go in Scaffold.bottomNavigationBar via [BottomBar], which
///    paints its background to the screen edge and puts the nav inset inside.
EdgeInsets scrollPadding(BuildContext context, EdgeInsets base) =>
    base.copyWith(bottom: base.bottom + MediaQuery.paddingOf(context).bottom);

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: scrollPadding(context, padding),
        child: child,
      ),
    );
  }
}
