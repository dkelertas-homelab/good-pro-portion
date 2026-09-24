import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

class FigureView extends StatelessWidget {
  const FigureView({
    super.key,
    required this.figureKey,
    this.size = 180,
    this.padding = const EdgeInsets.all(12),
  });

  final String figureKey;
  final double size;
  final EdgeInsets padding;

  String assetFor(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? 'assets/figures/${figureKey}_dark.svg'
        : 'assets/figures/$figureKey.svg';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.coralSoft : AppColors.tealSoft;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: padding,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        assetFor(context),
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => SizedBox(width: size, height: size),
      ),
    );
  }
}
