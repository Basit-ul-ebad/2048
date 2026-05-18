import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../providers/shop_provider.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ShopProvider>().fetchUserSkins(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<ProfileProvider>().userProfile;
    final shopProvider = context.watch<ShopProvider>();
    final authUser = context.read<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cosmetic Shop', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '${userProfile?.coins ?? 0}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: shopProvider.availableSkins.length,
        itemBuilder: (context, index) {
          final skin = shopProvider.availableSkins[index];
          final isOwned = shopProvider.ownedSkins.contains(skin['id']);
          final isSelected = shopProvider.selectedSkin == skin['id'];

          return Card(
            elevation: isSelected ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isSelected 
                  ? BorderSide(color: AppColors.getTileColor(2048), width: 3)
                  : BorderSide.none,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Preview boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildColorBox(skin['colors'][0]),
                    const SizedBox(width: 4),
                    _buildColorBox(skin['colors'][1]),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  skin['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                if (isSelected)
                  const Chip(
                    label: Text('Equipped', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green,
                  )
                else if (isOwned)
                  ElevatedButton(
                    onPressed: () {
                      if (authUser != null) {
                        shopProvider.equipSkin(authUser.uid, skin['id']);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.getTileColor(64)),
                    child: const Text('Equip', style: TextStyle(color: Colors.white)),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (authUser != null) {
                        final success = await shopProvider.buySkin(authUser.uid, skin['id'], skin['price']);
                        if (success) {
                          // Refresh profile to show new coin balance
                          context.read<ProfileProvider>().fetchProfile(authUser.uid);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase successful!')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins!')));
                        }
                      }
                    },
                    icon: const Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                    label: Text('${skin['price']}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorBox(String hexColor) {
    Color color = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
    );
  }
}
