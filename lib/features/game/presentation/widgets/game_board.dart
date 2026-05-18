import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../shop/providers/shop_provider.dart';
import 'tile_widget.dart';

class GameBoard extends StatelessWidget {
  final List<int> tiles;
  
  const GameBoard({
    super.key,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    final skinId = context.watch<ShopProvider>().selectedSkin;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getBoardBackground(skinId),
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
