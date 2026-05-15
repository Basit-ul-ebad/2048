import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/game_constants.dart';

class TileWidget extends StatelessWidget {
  final int value;

  const TileWidget({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.getTileColor(0),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: GameConstants.tileScaleDuration),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: GameConstants.tileMoveDuration),
            decoration: BoxDecoration(
              color: AppColors.getTileColor(value),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: value > 512 ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTileTextColor(value),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
