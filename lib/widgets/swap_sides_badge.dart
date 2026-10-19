import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Swap sides" pill for the second side of a one-sided move. Figures are
/// drawn for the right side only, so this is the cue to switch. Large enough
/// to read with the phone on the floor.
class SwapSidesBadge extends StatelessWidget {
  const SwapSidesBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.coral,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, color: Colors.white, size: 24),
            SizedBox(width: 6),
            Text(
              'SWAP SIDES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
