import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class TileWidget extends StatelessWidget {
  final int value;

  const TileWidget({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.getTileColor(value),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: value == 0
            ? const SizedBox() // Show nothing for empty tiles
            : Text(
                '$value',
                style: TextStyle(
                  fontSize: value > 512 ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTileTextColor(value),
                ),
              ),
      ),
    );
  }
}
