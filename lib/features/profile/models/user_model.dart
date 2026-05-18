import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/nickname_utils.dart';

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

  final int totalGames;
  final int highestTile;
  final double winRate;
  final String favoriteSkin;
  final bool isOnline;

  final int aiWins;
  final int aiLosses;
  final int hardestAiBeaten;
  final int aiGamesPlayed;

  const UserModel({
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
    this.aiWins = 0,
    this.aiLosses = 0,
    this.hardestAiBeaten = -1,
    this.aiGamesPlayed = 0,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final w = data['wins'] as int? ?? 0;
    final tg = data['totalGames'] as int? ?? 0;
    final calculatedWinRate = tg > 0 ? (w / tg) * 100 : 0.0;

    return UserModel(
      uid: doc.id,
      nickname: NicknameUtils.displayName(
        data['nickname'] as String?,
        email: data['email'] as String?,
      ),
      email: data['email'] as String? ?? '',
      highestScore: data['highestScore'] as int? ?? 0,
      currentLevel: data['currentLevel'] as int? ?? 1,
      exp: data['exp'] as int? ?? 0,
      coins: data['coins'] as int? ?? 0,
      rank: data['rank'] as String? ?? 'Bronze',
      wins: w,
      losses: data['losses'] as int? ?? 0,
      friendsCount: data['friendsCount'] as int? ?? 0,
      totalGames: tg,
      highestTile: data['highestTile'] as int? ?? 0,
      winRate: calculatedWinRate,
      favoriteSkin: data['favoriteSkin'] as String? ?? 'default',
      isOnline: data['isOnline'] as bool? ?? false,
      aiWins: data['aiWins'] as int? ?? 0,
      aiLosses: data['aiLosses'] as int? ?? 0,
      hardestAiBeaten: (data['hardestAiBeaten'] as num?)?.toInt() ?? -1,
      aiGamesPlayed: data['aiGamesPlayed'] as int? ?? 0,
    );
  }
}
