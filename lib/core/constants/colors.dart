import 'package:flutter/material.dart';

class AppColors {
  // Common Colors
  static const Color background = Color(0xFFFAF8EF);
  static const Color boardBackground = Color(0xFFBBADA0);
  
  // Text Colors
  static const Color textDark = Color(0xFF776E65);
  static const Color textLight = Color(0xFFF9F6F2);
  
  // Dialog Colors
  static const Color dialogOverlay = Colors.black54;

  // Tile Colors Mapping
  static Color getTileColor(int value) {
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

  // Tile Text Color Logic
  static Color getTileTextColor(int value) {
    if (value <= 4) {
      return textDark;
    }
    return textLight;
  }
}
