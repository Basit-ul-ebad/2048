import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nickname;
  final String email;
  final int highestScore;
  final int currentLevel;
  final int exp;
  final int coins;
  final String rank;
  final int wins;
  final int losses;
  final int friendsCount;
  
  // Phase 2 New Fields
  final int totalGames;
  final int highestTile;
  final double winRate;
  final String favoriteSkin;
  final bool isOnline;

  UserModel({
    required this.uid,
    required this.nickname,
    required this.email,
    required this.highestScore,
    required this.currentLevel,
    required this.exp,
    required this.coins,
    required this.rank,
    required this.wins,
    required this.losses,
    required this.friendsCount,
    this.totalGames = 0,
    this.highestTile = 0,
    this.winRate = 0.0,
    this.favoriteSkin = 'default',
    this.isOnline = false,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Calculate Win Rate safely
    int w = data['wins'] ?? 0;
    int tg = data['totalGames'] ?? 0;
    double calculatedWinRate = tg > 0 ? (w / tg) * 100 : 0.0;

    return UserModel(
      uid: doc.id,
      nickname: data['nickname'] ?? '',
      email: data['email'] ?? '',
      highestScore: data['highestScore'] ?? 0,
      currentLevel: data['currentLevel'] ?? 1,
      exp: data['exp'] ?? 0,
      coins: data['coins'] ?? 0,
      rank: data['rank'] ?? 'Bronze',
      wins: w,
      losses: data['losses'] ?? 0,
      friendsCount: data['friendsCount'] ?? 0,
      totalGames: tg,
      highestTile: data['highestTile'] ?? 0,
      winRate: calculatedWinRate,
      favoriteSkin: data['favoriteSkin'] ?? 'default',
      isOnline: data['isOnline'] ?? false,
    );
  }
}
