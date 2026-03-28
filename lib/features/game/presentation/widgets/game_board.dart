import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import 'tile_widget.dart';

class GameBoard extends StatelessWidget {
  final List<int> tiles;
  
  const GameBoard({
    super.key,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.boardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: 16,
        itemBuilder: (context, index) {
          return TileWidget(value: tiles[index]);
        },
      ),
    );
  }
}
