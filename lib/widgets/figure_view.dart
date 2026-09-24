import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final asset = dark
        ? 'assets/figures/${figureKey}_dark.svg'
        : 'assets/figures/$figureKey.svg';
    final bg = dark ? AppColors.coralSoft : AppColors.tealSoft;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: padding,
      alignment: Alignment.center,
      child: FutureBuilder<String>(
        future: rootBundle.loadString(asset),
        builder: (context, snap) {
          if (!snap.hasData) {
            return SizedBox(width: size, height: size);
          }
          return SvgPicture.string(
            snap.data!,
            width: size,
            height: size,
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }
}
