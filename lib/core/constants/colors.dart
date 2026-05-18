import 'package:flutter/material.dart';

class AppColors {
  // Common Colors
  static const Color background = Color(0xFFFAF8EF);

  /// Default 2048 board background (classic skin).
  static const Color boardBackground = Color(0xFFBBADA0);
  
  static Color getBoardBackground(String skinId) {
    if (skinId == 'neon') return const Color(0xFF111111);
    if (skinId == 'dark') return const Color(0xFF222222);
    return const Color(0xFFBBADA0);
  }
  
  // Text Colors
  static const Color textDark = Color(0xFF776E65);
  static const Color textLight = Color(0xFFF9F6F2);
  
  // Dialog Colors
  static const Color dialogOverlay = Colors.black54;

  // Tile Colors Mapping
  static Color getTileColor(int value, {String skinId = 'default'}) {
    if (skinId == 'neon') {
      return _getNeonTileColor(value);
    } else if (skinId == 'dark') {
      return _getDarkTileColor(value);
    }

    switch (value) {
      case 0:
        return const Color(0xFFCDC1B4); // Empty slot color
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      case 2048:
        return const Color(0xFFEDC22E);
      default:
        // For values above 2048
        return const Color(0xFF3C3A32);
    }
  }

  static Color _getNeonTileColor(int value) {
    switch (value) {
      case 0: return const Color(0xFF222222);
      case 2: return const Color(0xFF00FFFF);
      case 4: return const Color(0xFF00FFCC);
      case 8: return const Color(0xFF00FF99);
      case 16: return const Color(0xFF00FF66);
      case 32: return const Color(0xFF00FF33);
      case 64: return const Color(0xFF00FF00);
      case 128: return const Color(0xFF33FF00);
      case 256: return const Color(0xFF66FF00);
      case 512: return const Color(0xFF99FF00);
      case 1024: return const Color(0xFFCCFF00);
      case 2048: return const Color(0xFFFFFF00);
      default: return const Color(0xFFFFFFFF);
    }
  }

  static Color _getDarkTileColor(int value) {
    switch (value) {
      case 0: return const Color(0xFF333333);
      case 2: return const Color(0xFF444444);
      case 4: return const Color(0xFF555555);
      case 8: return const Color(0xFF666666);
      case 16: return const Color(0xFF777777);
      case 32: return const Color(0xFF888888);
      case 64: return const Color(0xFF999999);
      case 128: return const Color(0xFFAAAAAA);
      case 256: return const Color(0xFFBBBBBB);
      case 512: return const Color(0xFFCCCCCC);
      case 1024: return const Color(0xFFDDDDDD);
      case 2048: return const Color(0xFFEEEEEE);
      default: return const Color(0xFFFFFFFF);
    }
  }

  // Tile Text Color Logic
  static Color getTileTextColor(int value, {String skinId = 'default'}) {
    if (skinId == 'neon') {
      return value == 0 ? Colors.transparent : Colors.black;
    } else if (skinId == 'dark') {
      return value == 0 ? Colors.transparent : (value > 128 ? Colors.black : Colors.white);
    }

    if (value <= 4) {
      return textDark;
    }
    return textLight;
  }
}
