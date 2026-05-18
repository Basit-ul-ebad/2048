import 'package:flutter/material.dart';

class Ranks {
  static const String bronze = "Bronze";
  static const String silver = "Silver";
  static const String gold = "Gold";
  static const String platinum = "Platinum";
  static const String diamond = "Diamond";

  static String getRankForExp(int exp) {
    if (exp >= 5000) return diamond;
    if (exp >= 2500) return platinum;
    if (exp >= 1000) return gold;
    if (exp >= 400) return silver;
    return bronze;
  }

  static Color getRankColor(String rank) {
    switch (rank) {
      case diamond:
        return Colors.cyanAccent;
      case platinum:
        return Colors.tealAccent;
      case gold:
        return Colors.amber;
      case silver:
        return Colors.grey.shade400;
      case bronze:
      default:
        return Colors.brown;
    }
  }

  // Formula to calculate Level based on total EXP
  static int getLevelForExp(int exp) {
    // Basic progression: level 1 = 0 exp, level 2 = 100, level 3 = 300, etc.
    return (exp / 100).floor() + 1;
  }
}
